require 'test_helper'
require_relative '../support/email_login_test_helper'

class StaffSessionRecoveryTest < ActionDispatch::IntegrationTest
  include EmailLoginTestHelper
  parallelize(workers: 1)
  PASSWORD = 'TesteSeguro#2026'.freeze
  RESTORE = '/api/devise_users/restore_session'.freeze
  COOKIE = StaffSessionRecovery::COOKIE_NAME

  setup do
    @attack_enabled = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @user = User.create!(name: 'Conta Teste', email: "recovery-#{SecureRandom.hex(6)}@example.test",
      password: PASSWORD, role: 'owner')
  end

  teardown { Rack::Attack.enabled = @attack_enabled }

  test 'every staff role restores the same session without consuming another slot' do
    %w[owner employee super_admin].each do |role|
      @user.update_columns(role: role, tokens: {})
      login
      old_cookie = cookies[COOKIE]
      issued_at = @user.reload.tokens.fetch(@headers['client']).fetch('issued_at')
      assert old_cookie.present?
      assert_match(/HttpOnly/i, response.headers['Set-Cookie'].to_s)
      assert_match(/SameSite=Strict/i, response.headers['Set-Cookie'].to_s)
      assert_not response.parsed_body.key?('secret')
      post RESTORE, headers: @recovery_headers, as: :json
      assert_response :success
      assert_equal @headers['client'], response.headers['client']
      assert_equal role, response.parsed_body.fetch('data').fetch('role')
      assert_equal 1, @user.reload.tokens.size
      assert @user.valid_token?(response.headers['access-token'], @headers['client'])
      assert_equal 'no-store', response.headers['Cache-Control']
      assert_equal old_cookie, cookies[COOKIE]
      assert_equal issued_at, @user.reload.tokens.fetch(@headers['client']).fetch('issued_at')
    end
  end

  test 'cookie alone does not authenticate protected APIs or restore without CSRF' do
    login
    get '/api/me/sessions'
    assert_response :unauthorized
    post RESTORE, headers: @recovery_headers.except('X-CSRF-Token'), as: :json
    assert_response :forbidden
    post RESTORE, headers: @recovery_headers.merge('X-CSRF-Token' => 'a' * 64), as: :json
    assert_response :forbidden
    assert_equal 1, @user.reload.tokens.size
  end

  test 'missing corrupted cookie and mismatched identity fail closed without changing the cookie' do
    login
    original_cookie = cookies[COOKIE]
    %w[X-Staff-Uid X-Staff-Client].each do |key|
      post RESTORE, headers: @recovery_headers.merge(key => 'outra-conta'), as: :json
      assert_response :unauthorized
      assert_equal original_cookie, cookies[COOKIE]
    end
    cookies[COOKIE] = 'tampered'
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
    cookies.delete(COOKIE)
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
    assert_equal 1, @user.reload.tokens.size
  end

  test 'recovery credential survives normal DTA rotation but is never listed in session metadata' do
    login
    entry = @user.reload.tokens.fetch(@headers['client'])
    recovery_digest = entry.fetch('recovery_digest')
    travel 6.seconds
    get '/api/me/sessions', headers: @headers
    assert_response :success
    assert_not_includes response.body, recovery_digest
    assert_equal recovery_digest, @user.reload.tokens.fetch(@headers['client']).fetch('recovery_digest')
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :success
    assert_equal 1, @user.reload.tokens.size
  end

  test 'logout revokes restoration even if an old cookie is replayed' do
    login
    old_cookie = cookies[COOKIE]
    delete '/api/devise_users/sign_out', headers: @headers
    assert_response :success
    assert cookies[COOKIE].blank?
    cookies[COOKIE] = old_cookie
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
    assert_empty @user.reload.tokens
  end

  test 'logout without memory access token can revoke only the matching cookie session using CSRF' do
    login
    headers = @headers.except('access-token').merge('X-CSRF-Token' => @recovery_headers['X-CSRF-Token'])
    delete '/api/devise_users/sign_out', headers: headers.except('X-CSRF-Token')
    assert_response :forbidden
    assert_equal 1, @user.reload.tokens.size
    delete '/api/devise_users/sign_out', headers: headers
    assert_response :success
    assert_empty @user.reload.tokens
    assert cookies[COOKIE].blank?
  end

  test 'an old tab cannot restore or log out the new identity sharing its cookie' do
    login
    old_headers = @headers
    old_recovery = @recovery_headers
    other = User.create!(name: 'Outra Conta', email: "other-#{SecureRandom.hex(6)}@example.test",
      password: PASSWORD, role: 'owner')
    login(other)
    current_cookie = cookies[COOKIE]
    post RESTORE, headers: old_recovery, as: :json
    assert_response :unauthorized
    delete '/api/devise_users/sign_out', headers: old_headers
    assert_response :success
    assert_equal current_cookie, cookies[COOKIE]
    assert_equal 1, other.reload.tokens.size
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :success
    assert_equal other.email, response.headers['uid']
  end

  test 'expired revoked disabled and non staff sessions cannot be recovered' do
    login
    @user.with_lock do
      @user.tokens[@headers['client']]['expiry'] = 1.minute.ago.to_i
      @user.save!
    end
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
    assert_empty @user.reload.tokens
    login
    @user.update_columns(active: false)
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
    @user.update_columns(active: true, role: 'customer')
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
    @user.update_columns(role: 'owner', tokens: {})
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
  end

  test 'password change and explicit session revocation prevent subsequent recovery' do
    login
    patch '/api/me/change_password', headers: @headers, params: {
      current_password: PASSWORD, password: 'OutraSegura#2027', password_confirmation: 'OutraSegura#2027'
    }, as: :json
    assert_response :success
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
    login(password: 'OutraSegura#2027')
    delete "/api/me/sessions/#{@headers['client']}", headers: @headers
    assert_response :success
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :unauthorized
  end

  test 'downgrade during recovery permanently prunes the older session' do
    @user.update!(role: 'super_admin')
    login
    old_recovery = @recovery_headers
    old_cookie = cookies[COOKIE]
    # Simula outra sessão previamente autenticada ocupando a vaga mais recente.
    travel 1.second
    newer = @user.reload.create_new_auth_token
    @user.update_columns(role: 'owner')
    cookies[COOKIE] = old_cookie
    post RESTORE, headers: old_recovery, as: :json
    assert_response :unauthorized
    assert_equal [newer['client']], @user.reload.tokens.keys
    @user.update_columns(role: 'super_admin')
    post RESTORE, headers: old_recovery, as: :json
    assert_response :unauthorized
  end

  test 'OTP challenge never creates a recovery cookie or CSRF credential' do
    login
    cookies.delete(COOKIE)
    post '/api/devise_users/sign_in', params: {
      email: @user.email, password: PASSWORD, device_token: 'b' * 64
    }, headers: { 'REMOTE_ADDR' => '192.168.1.99' }, as: :json
    assert_response :success
    assert response.parsed_body['requires_verification']
    assert_not response.parsed_body.key?('staff_csrf_token')
    assert cookies[COOKIE].blank?
  end

  test 'HTTPS uses a host only Secure cookie restricted to authentication routes' do
    https!
    login
    header = response.headers['Set-Cookie'].to_s
    assert_match(/secure/i, header)
    assert_match(%r{path=/api/devise_users}i, header)
    assert_no_match(/domain=/i, header)
  end

  test 'recovery has a dedicated rate limit' do
    login
    old_cache = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    20.times do
      post RESTORE, headers: @recovery_headers, as: :json
      assert_response :success
    end
    post RESTORE, headers: @recovery_headers, as: :json
    assert_response :too_many_requests
  ensure
    Rack::Attack.cache.store = old_cache
  end

  private

  def login(user = @user, password: PASSWORD)
    login_with_email_verification('/api/devise_users/sign_in', params: {
      email: user.email, password: password, device_token: 'a' * 64
    })
    assert_response :success
    @headers = response.headers.slice('access-token', 'client', 'uid')
    @recovery_headers = { 'X-Staff-Client' => @headers['client'], 'X-Staff-Uid' => @headers['uid'],
                          'X-CSRF-Token' => response.parsed_body.fetch('staff_csrf_token') }
  end
end
