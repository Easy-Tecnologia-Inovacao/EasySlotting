require 'test_helper'

class StaffPlanSessionsTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)
  PASSWORD = 'TesteSeguro#2026'.freeze

  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    @owner = User.create!(name: 'Proprietario', email: "staff-owner-#{suffix}@example.test", password: PASSWORD, role: 'owner')
    @employee = User.create!(name: 'Funcionario', email: "staff-employee-#{suffix}@example.test", password: PASSWORD, role: 'employee')
    @establishment = Establishment.create!(name: 'Empresa', slug: "staff-#{suffix}", owner: @owner)
    @membership = EstablishmentMembership.create!(user: @employee, establishment: @establishment, role: 'employee', active: true)
    @plans = (1..4).map { |limit| Plan.create!(name: "Faixa #{limit}", code: "staff_#{suffix}_#{limit}", price: limit * 50, duration_months: 1, max_owner_sessions: limit) }
    @subscription = @establishment.subscriptions.create!(plan: @plans.second, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
  end

  teardown { Rack::Attack.enabled = @attack }

  test 'employee inherits all plan tiers without consuming owner slots' do
    @plans.each_with_index do |plan, index|
      @subscription.update!(plan: plan)
      @employee.update_columns(tokens: {})
      assert_equal index + 1, OwnerSessionPolicy.new(@employee).limit
      (index + 1).times { @employee.create_new_auth_token }
      assert_raises(OwnerSessionPolicy::LimitReached) { @employee.create_new_auth_token }
      assert @owner.reload.tokens.empty?
    end
  end

  test 'employee downgrade revokes surplus tokens permanently and upgrade grants new slots' do
    first = @employee.create_new_auth_token
    travel 1.second
    last = @employee.create_new_auth_token
    @subscription.update!(plan: @plans.first)
    assert_not @employee.valid_token?(first['access-token'], first['client'])
    assert @employee.valid_token?(last['access-token'], last['client'])
    @subscription.update!(plan: @plans.last)
    assert_not @employee.valid_token?(first['access-token'], first['client'])
    3.times { @employee.create_new_auth_token }
    assert_equal 4, @employee.reload.tokens.size
  end

  test 'inactive links company owner and expired subscriptions cannot grant larger quotas' do
    @membership.update!(active: false)
    assert_equal 1, OwnerSessionPolicy.new(@employee).limit
    @membership.update!(active: true)
    @establishment.update!(active: false)
    assert_equal 1, OwnerSessionPolicy.new(@employee).limit
    @establishment.update!(active: true)
    @owner.update!(active: false)
    assert_equal 1, OwnerSessionPolicy.new(@employee).limit
    @owner.update!(active: true)
    @subscription.update!(end_date: Date.yesterday)
    assert_equal 1, OwnerSessionPolicy.new(@employee).limit
  end

  test 'multiple owners grant their largest valid allowance without summing or authorizing foreign companies' do
    another = User.create!(name: 'Outro Dono', email: "foreign-owner-#{SecureRandom.hex(5)}@example.test", password: PASSWORD, role: 'owner')
    company = Establishment.create!(name: 'Outra Empresa', slug: "foreign-staff-#{SecureRandom.hex(5)}", owner: another)
    company.subscriptions.create!(plan: @plans.last, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    assert_equal 2, OwnerSessionPolicy.new(@employee).limit
    link = EstablishmentMembership.create!(user: @employee, establishment: company, role: 'employee', active: true)
    assert_equal 4, OwnerSessionPolicy.new(@employee).limit
    link.update!(active: false)
    assert_equal 2, OwnerSessionPolicy.new(@employee).limit
  end

  test 'employee inherits the owners global allowance across owned companies' do
    company = Establishment.create!(name: 'Segunda Empresa', slug: "second-staff-#{SecureRandom.hex(5)}", owner: @owner)
    company.subscriptions.create!(plan: @plans.last, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    assert_equal 4, OwnerSessionPolicy.new(@employee).limit
  end

  test 'employee quota rejection is 409 and ignores client supplied benefits' do
    device = 'a' * 64
    @employee.add_trusted_ip!(ip: '127.0.0.1')
    2.times { @employee.create_new_auth_token }
    post '/api/devise_users/sign_in', params: { email: @employee.email, password: PASSWORD, device_token: device,
      max_owner_sessions: 99, owner_id: @owner.id, role: 'super_admin' }, as: :json
    assert_response :conflict
    assert_equal 'STAFF_SESSION_LIMIT_REACHED', response.parsed_body['code']
    assert_equal 2, response.parsed_body['limit']
    assert_equal 0, @employee.reload.failed_attempts
    assert_equal 2, @employee.tokens.size
    assert response.headers['access-token'].blank?
  end

  test 'employee sessions listing and revocation can only affect the current account' do
    employee_headers = @employee.create_new_auth_token
    owner_headers = @owner.create_new_auth_token
    get '/api/me/sessions', headers: employee_headers
    assert_response :success
    assert_equal 2, response.parsed_body['limit']
    delete "/api/me/sessions/#{owner_headers['client']}", headers: employee_headers
    assert_response :not_found
    assert @owner.reload.valid_token?(owner_headers['access-token'], owner_headers['client'])
  end

  test 'single super admin allows exactly five sessions and never silently evicts one' do
    admin = User.create!(name: 'Administrador', email: "single-admin-#{SecureRandom.hex(5)}@example.test", password: PASSWORD, role: 'super_admin')
    device = 'b' * 64
    admin.add_trusted_ip!(ip: '127.0.0.1')
    headers = 5.times.map { admin.create_new_auth_token }
    post '/api/devise_users/sign_in', params: { email: admin.email, password: PASSWORD, device_token: device }, as: :json
    assert_response :conflict
    assert_equal 5, response.parsed_body['limit']
    headers.each { |h| assert admin.reload.valid_token?(h['access-token'], h['client']) }
    get '/api/me/sessions', headers: headers.first
    assert_response :success
    assert_equal 5, response.parsed_body['limit']
    delete "/api/me/sessions/#{headers.last['client']}", headers: headers.first
    assert_response :success
    assert admin.reload.create_new_auth_token.present?
  end
end
