require 'test_helper'

class AuthenticationSessionsTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)
  PASSWORD = 'TesteSeguro#2026'.freeze
  DEVICE = 'a' * 64
  OTHER_DEVICE = 'b' * 64

  setup do
    @previous_attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    @owner = User.create!(name: 'Proprietario', email: "owner-#{suffix}@example.test", password: PASSWORD, role: 'owner')
    @establishment = Establishment.create!(name: 'Empresa Teste', slug: "auth-#{suffix}", owner: @owner)
    plan = Plan.create!(name: 'Quatro aparelhos', code: "auth_four_#{suffix}", price: 100, duration_months: 1, max_owner_sessions: 4)
    @establishment.subscriptions.create!(plan: plan, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    @customer = Customer.create!(name: 'Cliente Seguro', email: "customer-#{suffix}@example.test",
                                 password: PASSWORD, establishment: @establishment)
    @login = "/api/customer_auth/#{@establishment.slug}/sign_in"
    @refresh = "/api/customer_auth/#{@establishment.slug}/refresh"
    @logout = "/api/customer_auth/#{@establishment.slug}/sign_out"
  end

  teardown do
    Rack::Attack.enabled = @previous_attack
  end

  test 'staff first login works and a new device on the same IP requires OTP without auth headers' do
    staff_login
    assert_response :success
    assert response.headers['access-token'].present?
    assert @owner.reload.first_login_at.present?
    assert_not_includes @owner.trusted_ips, "device:#{DEVICE}"
    staff_login(device: OTHER_DEVICE)
    assert_response :success
    assert response.parsed_body['requires_verification']
    assert response.headers['access-token'].blank?
    assert_equal 1, @owner.reload.tokens.size
  end

  test 'staff logout revokes the token and is idempotent' do
    staff_login
    headers = response.headers.slice('access-token', 'client', 'uid')
    delete '/api/devise_users/sign_out', headers: headers
    assert_response :success
    assert_not @owner.reload.valid_token?(headers['access-token'], headers['client'])
    get '/api/me/sessions', headers: headers
    assert_response :unauthorized
    delete '/api/devise_users/sign_out', headers: headers
    assert_response :success
  end

  test 'staff OTP completes authentication only for the challenged device' do
    staff_login
    staff_login(device: OTHER_DEVICE)
    travel 61.seconds
    code = @owner.reload.generate_login_otp!(ip: '127.0.0.1', device_token: OTHER_DEVICE)
    post '/api/devise_users/sign_in', params: login_payload(@owner, device: OTHER_DEVICE).merge(otp_code: code), as: :json
    assert_response :success
    assert response.headers['access-token'].present?
    assert_nil @owner.reload.login_otp_code
  end

  test 'employee and super admin use the same protected staff authentication' do
    %w[employee super_admin].each do |role|
      @owner.update_columns(role: role)
      staff_login
      assert_response :success
      assert_equal role, response.parsed_body.fetch('data').fetch('role')
    end
  end

  test 'inactive staff cannot log in or use a previously valid token' do
    token = @owner.create_new_auth_token
    @owner.update_columns(active: false)
    staff_login
    assert_response :unauthorized
    get '/api/me/sessions', headers: token
    assert_response :unauthorized
  end

  test 'staff credentials with customer role are rejected by server' do
    @owner.update_columns(role: 'customer')
    staff_login
    assert_response :forbidden
    assert @owner.reload.tokens.empty?
  end

  test 'malformed and oversized login inputs are rejected without exception' do
    [ { email: { value: @owner.email }, password: PASSWORD },
      { email: @owner.email, password: 'a' * 129 },
      { email: @owner.email, password: PASSWORD, device_token: ['device'] } ].each do |payload|
      post '/api/devise_users/sign_in', params: payload, as: :json
      assert_response :unprocessable_entity
    end
  end

  test 'customer first login works and device or IP changes require OTP' do
    customer_login
    assert_response :success
    assert response.parsed_body['access_token'].present?
    customer_login(device: OTHER_DEVICE)
    assert response.parsed_body['requires_verification']
    assert_not response.parsed_body.key?('access_token')
    post @login, params: login_payload(@customer), headers: { 'REMOTE_ADDR' => '192.168.1.99' }, as: :json
    assert response.parsed_body['requires_verification']
  end

  test 'customer logout immediately invalidates the access token' do
    customer_login
    token = response.parsed_body.fetch('access_token')
    delete @logout, headers: { 'Authorization' => "Bearer #{token}" }
    assert_response :success
    get '/api/customer/profile', headers: { 'Authorization' => "Bearer #{token}" }
    assert_response :unauthorized
    assert_empty @customer.customer_sessions
  end

  test 'customer OTP completes authentication and is single-use' do
    customer_login
    customer_login(device: OTHER_DEVICE)
    travel 61.seconds
    code = @customer.reload.generate_login_otp!(ip: '127.0.0.1', device_token: OTHER_DEVICE)
    post @login, params: login_payload(@customer, device: OTHER_DEVICE).merge(otp_code: code), as: :json
    assert_response :success
    assert response.parsed_body['access_token'].present?
    post @login, params: login_payload(@customer, device: OTHER_DEVICE).merge(otp_code: code), as: :json
    assert_response :unauthorized
  end

  test 'customer refresh token replay does not revoke a newer session' do
    customer_login
    old_cookies = cookies.to_hash
    csrf = response.parsed_body.fetch('csrf_token')
    post @refresh, headers: { 'X-CSRF-Token' => csrf }, as: :json
    assert_response :success
    current_id = @customer.customer_sessions.sole.session_id
    current_hash = @customer.customer_sessions.sole.refresh_token_digest
    old_cookies.each { |name, value| cookies[name] = value }
    post @refresh, headers: { 'X-CSRF-Token' => csrf }, as: :json
    assert_response :unauthorized
    assert_equal current_id, @customer.customer_sessions.sole.session_id
    assert_equal current_hash, @customer.customer_sessions.sole.refresh_token_digest
  end

  test 'customer password change and account deactivation invalidate access tokens' do
    customer_login
    token = response.parsed_body.fetch('access_token')
    @customer.reload.update!(password: 'OutraSegura#2027', password_confirmation: 'OutraSegura#2027')
    get '/api/customer/profile', headers: { 'Authorization' => "Bearer #{token}" }
    assert_response :unauthorized
    customer_login(password: 'OutraSegura#2027')
    token = response.parsed_body.fetch('access_token')
    @customer.update_columns(active: false)
    get '/api/customer/profile', headers: { 'Authorization' => "Bearer #{token}" }
    assert_response :unauthorized
  end

  test 'refresh needs CSRF and rotates tokens without invalidating the active session' do
    customer_login
    original = response.parsed_body
    post @refresh, as: :json
    assert_response :forbidden
    post @refresh, headers: { 'X-CSRF-Token' => original.fetch('csrf_token') }, as: :json
    assert_response :success
    assert_not_equal original['csrf_token'], response.parsed_body['csrf_token']
    get '/api/customer/profile', headers: { 'Authorization' => "Bearer #{original.fetch('access_token')}" }
    assert_response :success
    assert_equal 'no-store', response.headers['Cache-Control']
  end

  test 'cookie-only logout requires CSRF' do
    customer_login
    csrf = response.parsed_body.fetch('csrf_token')
    delete @logout
    assert_response :forbidden
    assert @customer.customer_sessions.exists?
    delete @logout, headers: { 'X-CSRF-Token' => csrf }
    assert_response :success
    assert_empty @customer.customer_sessions
  end

  test 'logout and refresh do not affect another establishment' do
    customer_login
    data = response.parsed_body
    foreign = Establishment.create!(name: 'Outra Empresa', slug: "other-#{SecureRandom.hex(5)}", owner: @owner)
    delete "/api/customer_auth/#{foreign.slug}/sign_out", headers: { 'Authorization' => "Bearer #{data.fetch('access_token')}" }
    assert_response :unauthorized
    assert @customer.customer_sessions.exists?
    post "/api/customer_auth/#{foreign.slug}/refresh", headers: { 'X-CSRF-Token' => data.fetch('csrf_token') }, as: :json
    assert_response :unauthorized
    assert @customer.customer_sessions.exists?
  end

  test 'JWT with invalid audience issuer missing expiry or a refresh token cannot authorize access' do
    customer_login
    valid = CustomerJsonWebToken.decode_access_token(response.parsed_body.fetch('access_token')).to_h
    [{ 'aud' => 'staff' }, { 'iss' => 'other' }, { 'exp' => nil }, { 'type' => 'refresh' }].each do |change|
      payload = valid.merge(change).compact
      token = JWT.encode(payload, CustomerJwt::SECRET_KEY, 'HS256')
      get '/api/customer/profile', headers: { 'Authorization' => "Bearer #{token}" }
      assert_response :unauthorized
    end
  end

  test 'customer registration does not issue an authenticated session' do
    post "/api/customer_auth/#{@establishment.slug}/sign_up", params: {
      name: 'Novo Cliente', email: "new-#{SecureRandom.hex(4)}@example.test", password: PASSWORD,
      password_confirmation: PASSWORD, consent_terms: true, consent_privacy: true
    }, as: :json
    assert_response :created
    assert_not response.parsed_body.key?('access_token')
  end

  test 'staff registration cannot select a privileged role or issue session headers' do
    email = "signup-#{SecureRandom.hex(4)}@example.test"
    post '/api/register', params: { name: 'Novo Dono', email: email, password: PASSWORD,
      password_confirmation: PASSWORD, role: 'super_admin', consent_terms: true, consent_privacy: true }, as: :json
    assert_response :success
    user = User.find_by!(email: email)
    assert_equal 'owner', user.role
    assert user.tokens.empty?
    assert response.headers['access-token'].blank?
    assert_nil user.first_login_at
  end

  test 'session revocation cannot target another staff user' do
    outsider = User.create!(name: 'Outro Usuario', email: "other-#{SecureRandom.hex(5)}@example.test", password: PASSWORD, role: 'owner')
    foreign = outsider.create_new_auth_token
    delete "/api/me/sessions/#{foreign.fetch('client')}", headers: @owner.create_new_auth_token
    assert_response :not_found
    assert outsider.reload.valid_token?(foreign['access-token'], foreign['client'])
  end

  test 'inactive establishment membership cannot authorize an existing staff session' do
    employee = User.create!(name: 'Funcionario', email: "employee-#{SecureRandom.hex(5)}@example.test", password: PASSWORD, role: 'employee')
    membership = EstablishmentMembership.create!(user: employee, establishment: @establishment,
      role: 'employee', active: true, can_manage_financial: true)
    headers = employee.create_new_auth_token.merge('X-Establishment-ID' => @establishment.id.to_s)
    get '/api/financial/dashboard', headers: headers
    assert_response :success
    membership.update!(active: false)
    get '/api/financial/dashboard', headers: headers
    assert_response :forbidden
  end

  test 'credentials in query parameters cannot authenticate a session' do
    headers = @owner.create_new_auth_token
    get '/api/me/sessions', params: headers
    assert_response :bad_request
  end

  test 'rack attack reads JSON email and returns 429 rather than 500' do
    request = Rack::Request.new(Rack::MockRequest.env_for('/api/devise_users/sign_in',
      method: 'POST', input: { email: ' USER@EXAMPLE.TEST ' }.to_json, 'CONTENT_TYPE' => 'application/json'))
    assert_equal Digest::SHA256.hexdigest('user@example.test'), Rack::Attack.login_email(request)
    assert_equal ' USER@EXAMPLE.TEST ', JSON.parse(request.body.read)['email']
    request.env['rack.attack.match_data'] = { period: 60 }
    status, headers, = Rack::Attack.throttled_responder.call(request)
    assert_equal 429, status
    assert_equal '60', headers['Retry-After']
  end

  test 'distributed staff password attacks are limited by the normalized JSON email' do
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    6.times do |attempt|
      post '/api/devise_users/sign_in', params: { email: 'missing@example.test', password: PASSWORD },
        headers: { 'REMOTE_ADDR' => "192.168.2.#{attempt + 1}" }, as: :json
    end
    assert_response :too_many_requests
    assert response.headers['Retry-After'].present?
    assert_match 'Muitas requisições', response.parsed_body['error']
  ensure
    Rack::Attack.cache.store = original_store
  end

  test 'authentication cookies are HttpOnly Secure and SameSite Strict on HTTPS' do
    https!
    customer_login
    assert_response :success
    cookie_headers = response.headers['Set-Cookie'].to_s.downcase
    assert_match 'httponly', cookie_headers
    assert_match 'secure', cookie_headers
    assert_match 'samesite=strict', cookie_headers
    data = response.parsed_body.fetch('customer')
    %w[auth_session_id refresh_token password_digest login_otp_code trusted_ips].each do |key|
      assert_not data.key?(key)
    end
  end

  test 'mail jobs do not log OTP or reset token arguments' do
    assert_not ActionMailer::MailDeliveryJob.log_arguments
  end

  test 'staff password changes revoke all existing session tokens' do
    first = @owner.create_new_auth_token
    second = @owner.create_new_auth_token
    patch '/api/me/change_password', params: { current_password: PASSWORD, password: 'OutraSegura#2027',
      password_confirmation: 'OutraSegura#2027' }, headers: first, as: :json
    assert_response :success
    assert @owner.reload.tokens.empty?
    get '/api/me/sessions', headers: second
    assert_response :unauthorized
  end

  test 'all staff roles revoke their session through the shared logout' do
    %w[owner employee super_admin].each do |role|
      @owner.update_columns(role: role)
      staff_login
      assert_response :success
      headers = response.headers.slice('access-token', 'client', 'uid')
      get '/api/me/sessions', headers: headers
      assert_response :success
      delete '/api/devise_users/sign_out', headers: headers
      assert_response :success
      get '/api/me/sessions', headers: headers
      assert_response :unauthorized
    end
  end

  test 'every protected API controller rejects anonymous access' do
    %w[
      /api/admin/establishment /api/admin/team /api/admin/team/123/schedule
      /api/admin/customers /api/admin/feedbacks /api/admin/notifications
      /api/services /api/service_packages /api/stock_items /api/appointments
      /api/financial/dashboard /api/financial/reports /api/financial/packages
      /api/financial/services /api/financial/commissions /api/financial/commission_closings
      /api/me/sessions /api/me/subscription /api/super_admin/dashboard /api/super_admin/plans
      /api/super_admin/audit_logs /api/customer/profile /api/customer/appointments
      /api/customer/service_packages /api/customer/notifications
    ].each do |path|
      get path, headers: { 'Accept' => 'application/json' }
      assert_response :unauthorized, path
    end
  end

  private

  def login_payload(account, device: DEVICE, password: PASSWORD)
    { email: account.email, password: password, device_token: device }
  end

  def staff_login(device: DEVICE)
    post '/api/devise_users/sign_in', params: login_payload(@owner, device: device), as: :json
  end

  def customer_login(device: DEVICE, password: PASSWORD)
    post @login, params: login_payload(@customer, device: device, password: password), as: :json
  end
end
