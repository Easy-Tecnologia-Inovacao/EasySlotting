require 'test_helper'
require_relative '../support/email_login_test_helper'

class CustomerAccountDeletionTest < ActionDispatch::IntegrationTest
  include EmailLoginTestHelper
  include ActiveJob::TestHelper
  parallelize(workers: 1)
  PASSWORD = 'TesteSeguro#2026'.freeze

  setup do
    @previous_attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    @owner = User.create!(name: 'Proprietario', email: "owner-#{suffix}@example.test", password: PASSWORD, role: 'owner')
    @establishment = Establishment.create!(name: 'Empresa', slug: "delete-#{suffix}", owner: @owner)
    @customer = Customer.create!(name: 'Cliente Seguro', email: "customer-#{suffix}@example.test",
                                 password: PASSWORD, establishment: @establishment)
    @email = @customer.email
    login_with_email_verification("/api/customer_auth/#{@establishment.slug}/sign_in",
         params: { email: @email, password: PASSWORD, device_token: 'a' * 64 })
    assert_response :success
    @token = response.parsed_body.fetch('access_token')
    @csrf = response.parsed_body.fetch('csrf_token')
    @headers = { 'Authorization' => "Bearer #{@token}" }
  end

  teardown do
    Rack::Attack.enabled = @previous_attack
  end

  test 'deletion requires authenticated customer current password and typed confirmation' do
    delete '/api/customer/profile', params: deletion_params, as: :json
    assert_response :unauthorized
    delete '/api/customer/profile', params: deletion_params, headers: @owner.create_new_auth_token, as: :json
    assert_response :unauthorized

    [ { confirmation: @email },
      { confirmation: [@email], current_password: PASSWORD },
      { confirmation: @email, current_password: { value: PASSWORD } },
      { confirmation: @email, current_password: 'a' * 129 } ].each do |payload|
      delete '/api/customer/profile', params: payload, headers: @headers, as: :json
      assert_response :unprocessable_entity
      assert @customer.reload.active?
    end
    assert_equal 0, deleted_logs.count
  end

  test 'password failures are counted and lock the destructive action' do
    5.times do
      delete '/api/customer/profile', params: deletion_params.merge(current_password: 'Errada#2026'),
             headers: @headers, as: :json
      assert_response :unprocessable_entity
    end
    assert @customer.reload.access_locked?
    delete '/api/customer/profile', params: deletion_params, headers: @headers, as: :json
    assert_response :too_many_requests
    assert @customer.reload.active?
    assert_equal 0, deleted_logs.count
  end

  test 'another customer or establishment cannot be selected through the payload' do
    other = Customer.create!(name: 'Outra Pessoa', email: 'outra@example.test', password: PASSWORD,
                             establishment: @establishment)
    delete '/api/customer/profile', params: deletion_params.merge(confirmation: other.email, customer_id: other.id),
           headers: @headers, as: :json
    assert_response :unprocessable_entity
    assert @customer.reload.active?
    assert other.reload.active?

    foreign_establishment = Establishment.create!(name: 'Outra Empresa', slug: "foreign-#{SecureRandom.hex(4)}", owner: @owner)
    foreign = Customer.create!(name: 'Cliente Remoto', email: @email, password: PASSWORD, establishment: foreign_establishment)
    delete '/api/customer/profile', params: deletion_params.merge(customer_id: foreign.id, establishment_id: foreign_establishment.id),
           headers: @headers, as: :json
    assert_response :success
    assert_not @customer.reload.active?
    assert foreign.reload.active?
    assert other.reload.active?
  end

  test 'deletion anonymizes profile revokes credentials cancels open records and preserves history' do
    open, completed, other_booking, active_sale, completed_sale = business_records
    previous_digest = @customer.reload.password_digest
    @customer.update_columns(reset_password_token: 'old-reset', reset_password_sent_at: Time.current,
                             login_otp_code: 'old-otp', login_otp_sent_at: Time.current,
                             consent_terms_at: Time.current, consent_privacy_at: Time.current)

    delete '/api/customer/profile', params: deletion_params.merge(confirmation: "  #{@email.upcase}  "),
           headers: @headers, as: :json
    assert_response :success
    @customer.reload
    assert_not @customer.active?
    assert_equal 'Conta Excluída', @customer.name
    assert_not_equal @email, @customer.email
    assert_not_equal previous_digest, @customer.password_digest
    assert_not @customer.authenticate(PASSWORD)
    %w[auth_session_id refresh_token refresh_token_expires_at reset_password_token reset_password_sent_at
       login_otp_code login_otp_sent_at first_login_at consent_terms_at consent_privacy_at image phone cellphone].each do |field|
      assert_nil @customer.public_send(field), field
    end
    assert_empty @customer.trusted_ips
    assert_equal 'canceled', open.reload.status
    assert open.canceled_at.present?
    assert_equal 'Conta Excluída', open.customer_name_snapshot
    assert_equal 'completed', completed.reload.status
    assert_equal 'Conta Excluída', completed.customer_name_snapshot
    assert_equal 'confirmed', other_booking.reload.status
    assert_equal 'canceled', active_sale.reload.status
    assert_equal 'completed', completed_sale.reload.status
    assert cookies['refresh_token'].blank?
    assert cookies['csrf_token'].blank?
    assert_includes response.headers['Set-Cookie'].to_s, 'max-age=0'
    assert_includes response.headers['Set-Cookie'].to_s, 'path=/api/customer_auth'
    log = deleted_logs.sole
    assert_not_includes log.details.to_json, @email
    assert_not_includes log.details.to_json, 'Cliente Seguro'
    get '/api/customer/profile', headers: @headers
    assert_response :unauthorized
    post "/api/customer_auth/#{@establishment.slug}/refresh", headers: { 'X-CSRF-Token' => @csrf }, as: :json
    assert_response :forbidden
  end

  test 'failed audit rolls back anonymization cancellations and session revocation' do
    open, = business_records
    reject_deletion = ->(log) { log.errors.add(:base, 'Audit storage unavailable') if log.action == 'account_deleted' }
    AuditLog.validate(reject_deletion)
    begin
      delete '/api/customer/profile', params: deletion_params, headers: @headers, as: :json
      assert_response :internal_server_error
    ensure
      AuditLog.skip_callback(:validate, :before, reject_deletion)
    end
    assert @customer.reload.active?
    assert_equal @email, @customer.email
    assert_equal 'confirmed', open.reload.status
    assert_equal 0, deleted_logs.count
    assert @customer.customer_sessions.exists?
  end

  test 'avatar removal is queued only after a successful deletion' do
    avatar = "/uploads/customers/avatar_customer_#{@customer.id}_123_abcdef12.png"
    @customer.update_columns(image: avatar)
    assert_enqueued_with(job: PurgeCustomerAvatarJob, args: [@customer.id, avatar]) do
      delete '/api/customer/profile', params: deletion_params, headers: @headers, as: :json
      assert_response :success
    end
  end

  test 'a revoked session cannot delete an account under lock' do
    previous_sid = @customer.customer_sessions.sole.session_id
    @customer.customer_sessions.delete_all
    assert_raises(CustomerAccountDeletion::InvalidSession) do
      CustomerAccountDeletion.call(customer: @customer, session_id: previous_sid, confirmation: @email,
                                   password: PASSWORD, ip: '127.0.0.1', user_agent: 'Test')
    end
    assert @customer.reload.active?
  end

  test 'IP rate limit protects account deletion without a server error' do
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    6.times do
      delete '/api/customer/profile', params: { confirmation: @email }, headers: @headers, as: :json
    end
    assert_response :too_many_requests
    assert response.headers['Retry-After'].present?
    assert @customer.reload.active?
  ensure
    Rack::Attack.cache.store = original_store
  end

  private

  def deletion_params
    { confirmation: @email, current_password: PASSWORD }
  end

  def deleted_logs
    AuditLog.where(action: 'account_deleted', auditable: @customer)
  end

  def business_records
    service = Service.create!(name: 'Servico', service_type: 'geral', establishment: @establishment,
                              duration_minutes: 30, price: 40, active: true)
    other = Customer.create!(name: 'Outra Pessoa', email: "other-#{SecureRandom.hex(4)}@example.test",
                             password: PASSWORD, establishment: @establishment)
    # Os testes da exclusão não devem disparar e-mails/notificações de criação.
    now = Time.current
    bookings = [ [@customer, 'confirmed', '09:00', '09:30'],
                 [@customer, 'completed', '10:00', '10:30'],
                 [other, 'confirmed', '11:00', '11:30'] ].map do |customer, status, start_time, end_time|
      id = Appointment.insert_all!([{ customer_id: customer.id, establishment_id: @establishment.id,
                                      employee_id: @owner.id, service_id: service.id, status: status,
                                      appointment_date: Date.tomorrow, start_time: start_time, end_time: end_time,
                                      customer_name_snapshot: customer.name, created_at: now, updated_at: now }]).rows.first.first
      Appointment.find(id)
    end
    package = ServicePackage.create!(name: 'Pacote', establishment: @establishment, service: service,
                                      duration_minutes: 30, price: 80, sessions_total: 2, active: true)
    sales = %w[active completed].map do |status|
      ServicePackageSale.create!(establishment: @establishment, service_package: package, customer: @customer,
                                 sold_at: now, status: status, total_price: 80, sessions_total: 2,
                                 sessions_used: status == 'completed' ? 2 : 0)
    end
    [*bookings, *sales]
  end
end
