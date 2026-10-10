require 'test_helper'

class StaffSessionManagementTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)
  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @admin = User.create!(name: 'Admin teste', email: "management-#{SecureRandom.hex(5)}@example.test", password: 'TesteSeguro#2026', role: 'super_admin')
    @headers = @admin.create_new_auth_token
  end
  teardown { Rack::Attack.enabled = @attack }

  test 'account rate limit counts only verified identities and survives IP changes' do
    store = Account::UsersController.cache_store
    original = store.method(:increment)
    own_method = store.singleton_class.instance_methods(false).include?(:increment)
    memory, keys = ActiveSupport::Cache::MemoryStore.new, []
    store.define_singleton_method(:increment) do |key, amount, **options|
      keys << key
      memory.increment(key, amount, **options)
    end
    old_attack_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
    freeze_time do
      31.times do
        get '/api/me/sessions', headers: { 'uid' => @admin.uid, 'REMOTE_ADDR' => '198.51.100.12' }
        assert_response :unauthorized
      end
      assert_empty keys
      30.times { list; assert_response :ok }
      get '/api/me/sessions', headers: @headers.merge('REMOTE_ADDR' => '198.51.100.13')
      assert_response :too_many_requests
      assert_equal '60', response.headers['Retry-After']
      assert_equal ["rate-limit:account/users:account:#{@admin.id}"], keys.uniq
      assert_not response.parsed_body.key?('sessions')
      # A quota de uma conta não bloqueia outra identidade autenticada.
      other = owner
      get '/api/me/sessions', headers: other.create_new_auth_token
      assert_response :ok
      assert_equal "rate-limit:account/users:account:#{other.id}", keys.last
    end
  ensure
    Rack::Attack.cache.store = old_attack_store if old_attack_store
    if original
      own_method ? store.define_singleton_method(:increment, original) : store.singleton_class.remove_method(:increment)
    end
  end

  test 'listing exposes only the required session fields and ignores forged account scope' do
    other = owner
    foreign = other.create_new_auth_token
    get '/api/me/sessions', headers: @headers, params: { user_id: other.id, establishment_id: 999, role: 'owner' }
    assert_response :ok
    assert_equal 'no-store', response.headers['Cache-Control']
    assert_equal 5, response.parsed_body['limit']
    assert_equal 1, response.parsed_body['active_count']
    row = response.parsed_body['sessions'].sole
    assert_equal %w[client_id device expires_at ip is_current last_seen_at], row.keys.sort
    assert_equal @headers['client'], row['client_id']
    assert_not_equal foreign['client'], row['client_id']
  end

  test 'revocation cannot affect another account and audits only a digest of its identifier' do
    other = owner
    foreign = other.create_new_auth_token
    delete "/api/me/sessions/#{foreign['client']}", headers: @headers
    assert_response :not_found
    assert other.reload.valid_token?(foreign['access-token'], foreign['client'])
    target = @admin.reload.create_new_auth_token
    payload, csrf = StaffSessionRecovery.issue!(@admin, target['client'])
    delete "/api/me/sessions/#{target['client']}", headers: @headers
    assert_response :ok
    assert_not @admin.reload.valid_token?(target['access-token'], target['client'])
    log = AuditLog.where(user: @admin, action: 'session_revoked').sole
    assert_equal Digest::SHA256.hexdigest("staff-session:#{target['client']}"), log.details['revoked_client_digest']
    assert_not log.details.key?('revoked_client_id')
    assert_not_includes log.details.to_json, target['client']
    assert_raises(StaffSessionRecovery::InvalidSession) do
      StaffSessionRecovery.new(payload, client: target['client'], uid: @admin.uid, csrf: csrf).restore!
    end
  end

  test 'revoke others preserves only the caller and cannot be redirected by payload' do
    others = 2.times.map { @admin.reload.create_new_auth_token }
    delete '/api/me/sessions', headers: @headers, params: { current_client: others.first['client'], user_id: 999 }, as: :json
    assert_response :ok
    assert_equal [@headers['client']], @admin.reload.tokens.keys
    others.each { |header| assert_not @admin.valid_token?(header['access-token'], header['client']) }
    list
    assert_response :ok
    assert_equal 1, response.parsed_body['active_count']
  end

  test 'direct self revocation does not rotate or resurrect the removed session' do
    delete "/api/me/sessions/#{@headers['client']}", headers: @headers
    assert_response :ok
    assert_empty @admin.reload.tokens
    assert response.headers['access-token'].blank?
    list
    assert_response :unauthorized
  end

  test 'invalid client identifiers and missing credentials never revoke sessions' do
    delete '/api/me/sessions', as: :json
    assert_response :unauthorized
    ['invalid!', 'a' * 129].each do |id|
      delete "/api/me/sessions/#{id}", headers: @headers
      assert_response :not_found
    end
    assert_equal [@headers['client']], @admin.reload.tokens.keys
  end

  private
  def list
    get '/api/me/sessions', headers: @headers
    @headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
  end
  def owner
    User.create!(name: 'Owner teste', email: "management-owner-#{SecureRandom.hex(5)}@example.test", password: 'TesteSeguro#2026', role: 'owner')
  end
end
