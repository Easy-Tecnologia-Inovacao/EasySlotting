require 'test_helper'

class EmailLoginVerificationTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper
  parallelize(workers: 1)
  PASSWORD = 'TesteSeguro#2026'.freeze
  DEVICE = 'a' * 64
  OTHER_DEVICE = 'b' * 64
  NEW_IP = '192.168.1.99'.freeze

  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    owner = User.create!(name: 'Proprietario', email: "otp-owner-#{suffix}@example.test", password: PASSWORD, role: 'owner')
    @company = Establishment.create!(name: 'Empresa OTP', slug: "email-otp-#{suffix}", owner: owner)
    plan = Plan.create!(name: 'Quatro sessoes', code: "email_otp_#{suffix}", price: 100, duration_months: 1, max_owner_sessions: 4)
    @company.subscriptions.create!(plan: plan, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    employee = User.create!(name: 'Funcionario', email: "otp-employee-#{suffix}@example.test", password: PASSWORD, role: 'employee')
    EstablishmentMembership.create!(user: employee, establishment: @company, role: 'employee', active: true)
    admin = User.create!(name: 'Administrador', email: "otp-admin-#{suffix}@example.test", password: PASSWORD, role: 'super_admin')
    customer = Customer.create!(name: 'Cliente', email: "otp-customer-#{suffix}@example.test", password: PASSWORD, establishment: @company)
    @accounts = [owner, employee, admin, customer]
  end

  teardown { Rack::Attack.enabled = @attack }

  test 'all four profiles require an emailed code on first login without issuing any session' do
    @accounts.each do |account|
      reset!
      code = challenge(account)
      assert_equal 0, session_count(account)
      assert_nil account.reload.first_login_at
      assert_empty account.trusted_ips
      assert_not_equal code, account.login_otp_code
      assert_no_match(/staff_session_recovery|refresh_token/, response.headers['Set-Cookie'].to_s)
      submit(account, otp: code)
      assert_response :success
      assert credential_present?(account)
      assert_equal 1, session_count(account)
      assert_equal ['127.0.0.1'], account.reload.trusted_ips
      assert account.first_login_at.present?
      submit(account, otp: code)
      assert_response :unauthorized
      assert_equal 1, session_count(account)
    end
  end

  test 'known IP accepts a different browser while new IP requires confirmation before trusting it' do
    @accounts.each do |account|
      reset!
      submit(account, otp: challenge(account))
      submit(account, device: OTHER_DEVICE)
      assert_response :success
      assert credential_present?(account)
      assert_not response.parsed_body['requires_verification']
      assert_equal ['127.0.0.1'], account.reload.trusted_ips
      count = session_count(account)
      travel 61.seconds
      code = challenge(account, ip: NEW_IP)
      assert_equal count, session_count(account)
      assert_not_includes account.reload.trusted_ips, NEW_IP
      # Nem o IP conhecido no payload nem outro contexto autorizam o desafio.
      submit(account, otp: code, ip: NEW_IP, device: OTHER_DEVICE)
      assert_response :unauthorized
      submit(account, otp: code, ip: NEW_IP)
      assert_response :success
      assert_includes account.reload.trusted_ips, NEW_IP
      # Staff substitui o acesso do mesmo navegador; clientes mantêm sessões independentes.
      expected_count = account.is_a?(Customer) ? count + 1 : count
      assert_equal expected_count, session_count(account)
    end
  end

  test 'resend is limited and wrong expired or exhausted codes never create a session' do
    @accounts.each do |account|
      reset!
      code = challenge(account)
      initial_sent_at = account.reload.login_otp_sent_at
      wrong = code == '000000' ? '999999' : '000000'
      submit(account, otp: wrong)
      assert_response :unauthorized
      assert_no_enqueued_emails { submit(account) }
      assert response.parsed_body['requires_verification']
      assert_equal initial_sent_at, account.reload.login_otp_sent_at
      assert_equal 1, account.login_otp_attempts
      4.times { submit(account, otp: wrong); assert_response :unauthorized }
      submit(account, otp: code)
      assert_response :unauthorized
      assert_equal 0, session_count(account)
      travel 61.seconds
      code = challenge(account)
      travel 10.minutes + 1.second
      submit(account, otp: code)
      assert_response :unauthorized
      assert_equal 0, session_count(account)
      assert_empty account.reload.trusted_ips
    end
  end

  test 'customer email verification is scoped to its establishment even when the email matches' do
    customer = @accounts.last
    other_company = Establishment.create!(name: 'Outra Empresa', slug: "other-otp-#{SecureRandom.hex(5)}", owner: @company.owner)
    foreign = Customer.create!(name: 'Outro Cliente', email: customer.email, password: PASSWORD, establishment: other_company)
    code = challenge(customer)
    foreign_code = challenge(foreign)
    while foreign_code == code
      travel 61.seconds
      foreign_code = challenge(foreign)
    end
    submit(foreign, otp: code)
    assert_response :unauthorized
    assert_equal 0, session_count(foreign)
    submit(customer, otp: code)
    assert_response :success
    assert_equal 1, session_count(customer)
  end

  test 'wrong credentials and inactive accounts cannot request a verification code or trust an IP' do
    @accounts.each do |account|
      reset!
      submit(account, password: 'SenhaErrada#2026')
      assert_response :unauthorized
      assert_nil account.reload.login_otp_code
      assert_empty account.trusted_ips
      account.update!(active: false)
      submit(account)
      assert_response :unauthorized
      assert_nil account.reload.login_otp_code
      assert_equal 0, session_count(account)
    end
  end

  private

  def submit(account, otp: nil, ip: '127.0.0.1', device: DEVICE, password: PASSWORD)
    path = account.is_a?(Customer) ? "/api/customer_auth/#{account.establishment.slug}/sign_in" : '/api/devise_users/sign_in'
    params = { email: account.email, password: password, device_token: device,
      ip: '127.0.0.1', trusted_ips: [ip], verified: true }
    params[:otp_code] = otp if otp
    post path, params: params, headers: { 'REMOTE_ADDR' => ip }, as: :json
  end

  def challenge(account, ip: '127.0.0.1')
    before = ActionMailer::Base.deliveries.size
    perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { submit(account, ip: ip) }
    assert_response :success
    assert response.parsed_body['requires_verification']
    assert_equal ['email'], response.parsed_body.fetch('methods').pluck('id')
    assert_not credential_present?(account)
    assert_equal before + 1, ActionMailer::Base.deliveries.size
    mail = ActionMailer::Base.deliveries.last
    assert_equal [account.email], mail.to
    assert_no_match(/\d{6}/, mail.subject)
    code = (mail.html_part || mail).body.decoded[/class="otp-code">(\d{6})/, 1]
    assert_match(/\A\d{6}\z/, code)
    code
  end

  def credential_present?(account)
    account.is_a?(Customer) ? response.parsed_body['access_token'].present? : response.headers['access-token'].present?
  end

  def session_count(account)
    account.is_a?(Customer) ? account.customer_sessions.count : account.reload.tokens.size
  end
end
