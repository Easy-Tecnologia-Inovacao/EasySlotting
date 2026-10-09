require 'test_helper'

class CustomerMultipleSessionsTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)
  PASSWORD = 'TesteSeguro#2026'.freeze

  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    @owner = User.create!(name: 'Proprietario', email: "multi-owner-#{suffix}@example.test", password: PASSWORD, role: 'owner')
    @company = Establishment.create!(name: 'Empresa', slug: "multi-#{suffix}", owner: @owner)
    @customer = Customer.create!(name: 'Cliente', email: "multi-customer-#{suffix}@example.test", password: PASSWORD, establishment: @company)
    @login = "/api/customer_auth/#{@company.slug}/sign_in"
    @logout = "/api/customer_auth/#{@company.slug}/sign_out"
    @refresh = "/api/customer_auth/#{@company.slug}/refresh"
  end

  teardown { Rack::Attack.enabled = @attack }

  test 'more than five customer logins remain valid simultaneously with independent hashed secrets' do
    logins = 7.times.map { login }
    assert_equal 7, @customer.customer_sessions.count
    logins.each do |browser, data|
      browser.get '/api/customer/profile', headers: auth(data)
      assert_equal 200, browser.response.status
      session = @customer.customer_sessions.find_by!(session_id: sid(data))
      assert_equal 64, session.refresh_token_digest.size
      assert_equal Digest::SHA256.hexdigest(data['csrf_token']), session.csrf_token_digest
      assert_not_equal data['csrf_token'], session.csrf_token_digest
      assert_not session.as_json.key?(:refresh_token_digest)
    end
  end

  test 'logout and replay on one device never revoke another device' do
    first, second = login, login
    first[0].delete @logout, headers: auth(first[1])
    assert_equal 200, first[0].response.status
    first[0].get '/api/customer/profile', headers: auth(first[1])
    assert_equal 401, first[0].response.status
    second[0].get '/api/customer/profile', headers: auth(second[1])
    assert_equal 200, second[0].response.status
    first[0].delete @logout, headers: auth(first[1])
    assert_equal 200, first[0].response.status
    assert_equal 1, @customer.customer_sessions.count
  end

  test 'cookie-only logout after access expiry revokes only that session and needs CSRF' do
    first, second = login, login
    travel 16.minutes
    first[0].delete @logout
    assert_equal 403, first[0].response.status
    first[0].delete @logout, headers: { 'X-CSRF-Token' => first[1]['csrf_token'] }
    assert_equal 200, first[0].response.status
    assert_not @customer.valid_auth_session?(sid(first[1]))
    assert @customer.valid_auth_session?(sid(second[1]))
  end

  test 'rotating refresh is isolated and replay cannot restore old credentials or revoke other sessions' do
    first, second = login, login
    previous_cookies = first[0].cookies.to_hash
    csrf = first[1]['csrf_token']
    other_hash = @customer.customer_sessions.find_by!(session_id: sid(second[1])).refresh_token_digest
    first[0].post @refresh, headers: { 'X-CSRF-Token' => csrf }, as: :json
    assert_equal 200, first[0].response.status
    current = first[0].response.parsed_body
    current_hash = @customer.customer_sessions.find_by!(session_id: sid(first[1])).refresh_token_digest
    assert_not current.key?('refresh_token')
    previous_cookies.each { |name, value| first[0].cookies[name] = value }
    first[0].post @refresh, headers: { 'X-CSRF-Token' => csrf }, as: :json
    assert_equal 401, first[0].response.status
    first[0].delete @logout, headers: { 'X-CSRF-Token' => csrf }
    assert_equal 200, first[0].response.status
    assert_equal current_hash, @customer.customer_sessions.find_by!(session_id: sid(first[1])).refresh_token_digest
    assert_equal other_hash, @customer.customer_sessions.find_by!(session_id: sid(second[1])).refresh_token_digest
    first[0].get '/api/customer/profile', headers: auth(current)
    assert_equal 200, first[0].response.status
  end

  test 'expired access logout cannot revoke a newer cookie session shared by another tab' do
    first, second = login, login
    travel 16.minutes
    second[0].cookies.to_hash.each { |name, value| first[0].cookies[name] = value }
    first[0].delete @logout, headers: auth(first[1]).merge('X-CSRF-Token' => second[1]['csrf_token'])
    assert_equal 401, first[0].response.status
    assert @customer.valid_auth_session?(sid(first[1]))
    assert @customer.valid_auth_session?(sid(second[1]))
    second[0].delete @logout, headers: auth(second[1]).merge('X-CSRF-Token' => second[1]['csrf_token'])
    assert_equal 200, second[0].response.status
    assert_not @customer.valid_auth_session?(sid(second[1]))
    assert @customer.valid_auth_session?(sid(first[1]))
  end

  test 'CSRF header and cookie from a different session cannot rotate a session' do
    first, second = login, login
    second[0].cookies['csrf_token'] = first[0].cookies['csrf_token']
    second[0].post @refresh, headers: { 'X-CSRF-Token' => first[1]['csrf_token'] }, as: :json
    assert_equal 401, second[0].response.status
    assert_equal 2, @customer.customer_sessions.count
  end

  test 'session expiry is absolute and refreshing never extends seven days' do
    browser, data = login
    session = @customer.customer_sessions.sole
    original_expiry = session.expires_at
    travel 6.days
    browser.post @refresh, headers: { 'X-CSRF-Token' => data['csrf_token'] }, as: :json
    assert_equal 200, browser.response.status
    assert_equal original_expiry, session.reload.expires_at
    renewed = browser.response.parsed_body
    renewed_cookies = browser.cookies.to_hash
    travel 2.days
    # Cookies copiados continuam expirados também no jar criptografado do servidor.
    renewed_cookies.each { |name, value| browser.cookies[name] = value }
    browser.post @refresh, headers: { 'X-CSRF-Token' => renewed['csrf_token'] }, as: :json
    assert_equal 403, browser.response.status
    assert_not @customer.valid_auth_session?(session.session_id)
    PurgeExpiredCustomerSessionsJob.perform_now
    assert_empty @customer.customer_sessions
  end

  test 'password changes revoke every session and older legacy slots do not authenticate' do
    first, second = login, login
    @customer.update!(password: 'OutraSegura#2027', password_confirmation: 'OutraSegura#2027')
    assert_empty @customer.customer_sessions
    [first, second].each do |browser, data|
      browser.get '/api/customer/profile', headers: auth(data)
      assert_equal 401, browser.response.status
    end
    old_sid = SecureRandom.uuid
    @customer.update_columns(auth_session_id: old_sid, refresh_token: 'legacy', refresh_token_expires_at: 7.days.from_now)
    assert_not @customer.valid_auth_session?(old_sid)
  end

  test 'deactivation revokes all stored sessions and inactive company denies access' do
    browser, data = login
    @company.update!(active: false)
    browser.get '/api/customer/sessions', headers: auth(data)
    assert_equal 401, browser.response.status
    @company.update!(active: true)
    @customer.update!(active: false)
    assert_empty @customer.customer_sessions
  end

  test 'listing is paginated contains no token hashes and revocation is restricted to the authenticated customer' do
    browser, data = login
    customer_session = @customer.customer_sessions.sole
    foreign = Customer.create!(name: 'Outro Cliente', email: 'foreign@example.test', password: PASSWORD, establishment: @company)
    foreign_session = foreign.customer_sessions.create!(session_id: SecureRandom.uuid, expires_at: 7.days.from_now,
      refresh_token_digest: 'a' * 64, csrf_token_digest: 'b' * 64)
    browser.get '/api/customer/sessions', headers: auth(data)
    assert_equal 200, browser.response.status
    listing = browser.response.parsed_body
    assert_nil listing['limit']
    assert listing['sessions'].sole['is_current']
    assert_not listing.to_s.include?(customer_session.refresh_token_digest)
    assert_not listing.to_s.include?(customer_session.csrf_token_digest)
    browser.delete "/api/customer/sessions/#{foreign_session.session_id}", headers: auth(data)
    assert_equal 404, browser.response.status
    assert foreign_session.reload.present?
    browser.delete '/api/customer/sessions/not-a-uuid', headers: auth(data)
    assert_equal 404, browser.response.status
    browser.get '/api/customer/sessions', params: { page: '1 OR 1=1' }, headers: auth(data)
    assert_equal 422, browser.response.status
    browser.get '/api/customer/sessions'
    assert_equal 401, browser.response.status
  end

  test 'session lists use bounded pages without limiting how many sessions a customer can create' do
    browser, data = login
    20.times do
      @customer.customer_sessions.create!(session_id: SecureRandom.uuid, expires_at: 7.days.from_now,
        refresh_token_digest: SecureRandom.hex(32), csrf_token_digest: SecureRandom.hex(32))
    end
    browser.get '/api/customer/sessions', headers: auth(data)
    assert_equal 200, browser.response.status
    assert_equal 20, browser.response.parsed_body['sessions'].size
    assert browser.response.parsed_body['has_more']
    browser.get '/api/customer/sessions', params: { page: 2 }, headers: auth(data)
    assert_equal 200, browser.response.status
    assert_equal 1, browser.response.parsed_body['sessions'].size
    assert_not browser.response.parsed_body['has_more']
  end

  test 'revoke other sessions preserves current access and does not affect another customer' do
    browser, data = login
    other = login
    browser.delete '/api/customer/sessions/destroy_others', headers: auth(data)
    assert_equal 200, browser.response.status
    assert @customer.valid_auth_session?(sid(data))
    assert_not @customer.valid_auth_session?(sid(other[1]))
    browser.delete "/api/customer/sessions/#{sid(data)}", headers: auth(data)
    assert_equal 200, browser.response.status
    browser.get '/api/customer/profile', headers: auth(data)
    assert_equal 401, browser.response.status
  end

  test 'account deletion invalidates every device and all refresh credentials' do
    first, second = login, login
    first[0].delete '/api/customer/profile', params: { confirmation: @customer.email, current_password: PASSWORD },
      headers: auth(first[1]), as: :json
    assert_equal 200, first[0].response.status
    assert_empty @customer.customer_sessions
    second[0].get '/api/customer/profile', headers: auth(second[1])
    assert_equal 401, second[0].response.status
    second[0].post @refresh, headers: { 'X-CSRF-Token' => second[1]['csrf_token'] }, as: :json
    assert_equal 401, second[0].response.status
  end

  private

  def login
    browser = ActionDispatch::Integration::Session.new(Rails.application)
    browser.post @login, params: { email: @customer.email, password: PASSWORD, device_token: 'a' * 64 }, as: :json
    assert_equal 200, browser.response.status
    data = browser.response.parsed_body
    assert data['access_token'].present?
    [browser, data]
  end

  def auth(data)
    { 'Authorization' => "Bearer #{data.fetch('access_token')}" }
  end

  def sid(data)
    # Apenas lê a identidade já emitida, inclusive nos testes de expiração.
    JWT.decode(data.fetch('access_token'), nil, false).first.fetch('sid')
  end
end
