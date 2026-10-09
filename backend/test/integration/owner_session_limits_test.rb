require 'test_helper'

class OwnerSessionLimitsTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)
  PASSWORD = 'TesteSeguro#2026'.freeze
  DEVICES = (1..5).map { |number| number.to_s * 64 }.freeze

  setup do
    @previous_attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    @owner = User.create!(name: 'Proprietario', email: "limits-#{suffix}@example.test", password: PASSWORD, role: 'owner')
    @establishment = Establishment.create!(name: 'Empresa Limites', slug: "limits-#{suffix}", owner: @owner)
    @tiers = (1..4).to_h do |limit|
      [limit, Plan.create!(name: "Faixa #{limit}", code: "limits_#{limit}_#{suffix}", price: limit * 50,
        duration_months: 1, max_owner_sessions: limit)]
    end
    @plan = @tiers.fetch(4)
    @subscription = @establishment.subscriptions.create!(plan: @plan, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    DEVICES.each { |device| @owner.add_trusted_device!(ip: '127.0.0.1', device_token: device) }
  end

  teardown do
    Rack::Attack.enabled = @previous_attack
  end

  test 'four independent owner sessions work and the fifth login cannot evict them or increase the limit' do
    headers = DEVICES.first(4).map { |device| login(device) }
    snapshot = @owner.reload.tokens.deep_dup
    post '/api/devise_users/sign_in', params: { email: @owner.email, password: PASSWORD,
      device_token: DEVICES.last, max_owner_sessions: 100, role: 'super_admin', plan_id: @plan.id }, as: :json
    assert_response :conflict
    assert_equal 'OWNER_SESSION_LIMIT_REACHED', response.parsed_body['code']
    assert_equal 4, response.parsed_body['limit']
    assert response.headers['access-token'].blank?
    assert_equal snapshot, @owner.reload.tokens
    headers.each { |header| assert @owner.valid_token?(header['access-token'], header['client']) }
    assert_equal 0, @owner.failed_attempts
  end

  test 'a new login on the same browser replaces only that session even at the limit' do
    headers = DEVICES.first(4).map { |device| login(device) }
    replaced = login(DEVICES.first)
    assert_equal 4, @owner.reload.tokens.size
    assert_not_equal headers.first['client'], replaced['client']
    assert_not @owner.valid_token?(headers.first['access-token'], headers.first['client'])
    assert @owner.valid_token?(replaced['access-token'], replaced['client'])
    headers.drop(1).each { |header| assert @owner.valid_token?(header['access-token'], header['client']) }
  end

  test 'logout and expiry free slots and rotation preserves the device and creation metadata' do
    headers = DEVICES.first(4).map { |device| login(device) }
    first_id = headers.first['client']
    before = @owner.reload.tokens.fetch(first_id).slice('issued_at', 'device_digest', 'name', 'ip')
    travel 6.seconds
    get '/api/me/sessions', headers: headers.first
    assert_response :success
    assert_equal 4, response.parsed_body['active_count']
    assert_equal 4, response.parsed_body['limit']
    assert_equal before, @owner.reload.tokens.fetch(first_id).slice(*before.keys)
    assert_equal 4, @owner.tokens.size
    delete '/api/devise_users/sign_out', headers: headers.last
    assert_response :success
    login(DEVICES.last)
    assert_equal 4, @owner.reload.tokens.size

    tokens = @owner.tokens.deep_dup
    tokens.fetch(first_id)['expiry'] = 1.minute.ago.to_i
    @owner.update_columns(tokens: tokens)
    login(DEVICES.first)
    assert_equal 4, @owner.reload.tokens.size
    assert_not @owner.tokens.key?(first_id)
  end

  test 'the plan limit is enforced and downgrade rejects older sessions on their next request' do
    headers = DEVICES.first(4).map { |device| login(device) }
    @subscription.update!(plan: @tiers.fetch(2))
    get '/api/me/sessions', headers: headers.first
    assert_response :unauthorized
    get '/api/me/sessions', headers: headers.last
    assert_response :success
    assert_equal 2, response.parsed_body['limit']
    assert_equal 2, response.parsed_body['sessions'].size
    login(DEVICES.first, expected: :conflict)
    @subscription.update!(plan: @plan)
    get '/api/me/sessions', headers: headers.first
    assert_response :unauthorized
  end

  test 'plan expiry falls back to one and foreign memberships or establishments do not grant owner slots' do
    @subscription.update!(end_date: Date.yesterday)
    other = User.create!(name: 'Outro Dono', email: "foreign-#{SecureRandom.hex(4)}@example.test", password: PASSWORD, role: 'owner')
    foreign_establishment = Establishment.create!(name: 'Outra Empresa', slug: "foreign-#{SecureRandom.hex(4)}", owner: other)
    foreign_establishment.subscriptions.create!(plan: @plan, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    EstablishmentMembership.create!(user: @owner, establishment: foreign_establishment, role: 'employee', active: true)
    login(DEVICES.first)
    login(DEVICES.second, expected: :conflict)
    assert_equal 1, response.parsed_body['limit']
    assert_equal 1, @owner.reload.tokens.size
  end

  test 'replacement subscription controls the entitlement instead of an older canceled plan' do
    @subscription.update!(status: 'canceled')
    reduced = @tiers.fetch(1)
    @establishment.subscriptions.create!(plan: reduced, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    assert_equal 1, OwnerSessionPolicy.new(@owner).limit
    @establishment.subscriptions.order(:id).last.update!(status: 'canceled')
    assert_equal 1, OwnerSessionPolicy.new(@owner).limit
  end

  test 'upgrading through the four tiers replaces the previous allowance and downgrading revokes excess sessions' do
    tiers = @tiers
    @subscription.update!(plan: tiers.fetch(1))
    first_headers = login(DEVICES.first)
    headers = first_headers.dup
    (2..4).each do |limit|
      post '/api/subscriptions', params: { plan_id: tiers.fetch(limit).id, max_owner_sessions: 100 }, headers: headers, as: :json
      assert_response :created
      assert_equal limit, response.parsed_body['plan']['max_owner_sessions']
      assert_equal limit, OwnerSessionPolicy.new(@owner).limit
      assert_equal 'canceled', @subscription.reload.status
      headers = login(DEVICES.fetch(limit - 1))
      assert_equal limit, @owner.reload.tokens.size
    end
    post '/api/subscriptions', params: { plan_id: tiers.fetch(2).id }, headers: headers, as: :json
    assert_response :created
    headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
    assert_equal 2, OwnerSessionPolicy.new(@owner).limit
    get '/api/me/sessions', headers: first_headers
    assert_response :unauthorized
    get '/api/me/subscription', headers: headers
    assert_response :success
    assert_equal 2, response.parsed_body['plan']['max_owner_sessions']
    assert_equal 2, @owner.reload.tokens.size
  end

  test 'owned companies use the highest current allowance without adding their sessions' do
    @subscription.update!(plan: @tiers.fetch(3))
    plus = @tiers.fetch(2)
    second_establishment = Establishment.create!(name: 'Segunda Empresa', slug: "second-#{SecureRandom.hex(4)}", owner: @owner)
    second = second_establishment.subscriptions.create!(plan: plus, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    assert_equal 3, OwnerSessionPolicy.new(@owner).limit
    @establishment.update!(active: false)
    assert_equal 2, OwnerSessionPolicy.new(@owner).limit
    plus.update!(active: false)
    assert_equal 2, OwnerSessionPolicy.new(@owner).limit
    second.update!(end_date: Date.yesterday)
    assert_equal 1, OwnerSessionPolicy.new(@owner).limit
  end

  test 'pending or future subscriptions do not grant a tier and superseded subscriptions cannot return after expiry' do
    @subscription.update!(status: 'canceled', end_date: 6.months.from_now.to_date)
    reduced = @tiers.fetch(1)
    replacement = @establishment.subscriptions.create!(plan: reduced, status: 'pending', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    assert_equal 4, OwnerSessionPolicy.new(@owner).limit
    replacement.update!(status: 'active', start_date: Date.tomorrow)
    assert_equal 4, OwnerSessionPolicy.new(@owner).limit
    replacement.update!(start_date: Date.current)
    assert_equal 1, OwnerSessionPolicy.new(@owner).limit
    %w[overdue expired canceled].each do |status|
      replacement.update!(status: status, end_date: Date.yesterday)
      assert_equal 1, OwnerSessionPolicy.new(@owner).limit
      assert_nil @establishment.subscriptions.current_for_use
    end
    headers = login(DEVICES.first)
    get '/api/me/subscription', headers: headers
    assert_response :success
    assert_nil response.parsed_body
  end

  test 'OTP challenge and invalid passwords do not reveal the limit or issue a session' do
    DEVICES.first(4).each { |device| login(device) }
    post '/api/devise_users/sign_in', params: { email: @owner.email, password: PASSWORD, device_token: 'f' * 64 }, as: :json
    assert_response :success
    assert response.parsed_body['requires_verification']
    assert response.headers['access-token'].blank?
    assert_not response.parsed_body.key?('limit')
    post '/api/devise_users/sign_in', params: { email: @owner.email, password: 'Errada#2026', device_token: DEVICES.last }, as: :json
    assert_response :unauthorized
    assert_not_equal 'OWNER_SESSION_LIMIT_REACHED', response.parsed_body['code']
    assert_equal 4, @owner.reload.tokens.size
  end

  test 'session listing hides credentials and revocation is scoped to the authenticated account' do
    headers = DEVICES.first(2).map { |device| login(device) }
    foreign = User.create!(name: 'Outro Dono', email: "sessions-#{SecureRandom.hex(4)}@example.test", password: PASSWORD, role: 'owner')
    foreign_headers = foreign.create_new_auth_token
    delete "/api/me/sessions/#{foreign_headers['client']}", headers: headers.first
    assert_response :not_found
    assert foreign.reload.valid_token?(foreign_headers['access-token'], foreign_headers['client'])
    get '/api/me/sessions', headers: headers.first
    assert_response :success
    response.parsed_body['sessions'].each do |session|
      %w[token previous_token last_token access-token device_digest].each { |secret| assert_not session.key?(secret) }
      assert session['expires_at'].present?
    end
    delete "/api/me/sessions/#{headers.last['client']}", headers: headers.first
    assert_response :success
    assert_not @owner.reload.valid_token?(headers.last['access-token'], headers.last['client'])
    assert_equal 1, @owner.tokens.size
  end

  test 'only super admin can configure owner slots and the plan APIs expose the benefit' do
    owner_headers = login(DEVICES.first)
    patch "/api/super_admin/plans/#{@plan.id}", params: { plan: { max_owner_sessions: 1 } }, headers: owner_headers, as: :json
    assert_response :forbidden
    assert_equal 4, @plan.reload.max_owner_sessions
    admin = User.create!(name: 'Administrador', email: "admin-#{SecureRandom.hex(4)}@example.test", password: PASSWORD, role: 'super_admin')
    admin_headers = admin.create_new_auth_token
    [0, 5, 2.5, nil, '4invalid'].each do |invalid|
      patch "/api/super_admin/plans/#{@plan.id}", params: { plan: { max_owner_sessions: invalid } }, headers: admin_headers, as: :json
      assert_response :unprocessable_entity
      if response.headers['access-token'].present?
        admin_headers.merge!(response.headers.slice('access-token', 'client', 'uid'))
      end
      assert_equal 4, @plan.reload.max_owner_sessions
    end
    @tiers.fetch(3).update!(active: false)
    patch "/api/super_admin/plans/#{@plan.id}", params: { plan: { max_owner_sessions: 3 } }, headers: admin_headers, as: :json
    assert_response :success
    assert_equal 3, @plan.reload.max_owner_sessions
    get '/api/plans'
    assert_response :success
    assert_equal 3, response.parsed_body.find { |plan| plan['id'] == @plan.id }['max_owner_sessions']
    get '/api/me/subscription', headers: owner_headers
    assert_response :success
    assert_equal 3, response.parsed_body['plan']['max_owner_sessions']
  end

  test 'staff sessions use independent quotas from the owners sessions' do
    %w[employee super_admin].each do |role|
      user = User.create!(name: 'Equipe Teste', email: "#{role}-#{SecureRandom.hex(4)}@example.test", password: PASSWORD, role: role)
      if role == 'employee'
        EstablishmentMembership.create!(user: user, establishment: @establishment, role: 'employee', active: true)
      end
      limit = role == 'super_admin' ? 5 : 4
      limit.times { user.create_new_auth_token }
      assert_equal limit, user.reload.tokens.size
    end
    assert @owner.reload.tokens.empty?
  end

  private

  def login(device, expected: :success)
    post '/api/devise_users/sign_in', params: { email: @owner.email, password: PASSWORD, device_token: device }, as: :json
    assert_response expected
    response.headers.slice('access-token', 'client', 'uid')
  end
end
