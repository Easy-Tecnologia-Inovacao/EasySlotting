require 'test_helper'

class SuperAdminDashboardTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)

  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    @admin = User.create!(name: 'Admin teste', email: "dashboard-admin-#{suffix}@example.test", password: 'TesteSeguro#2026', role: 'super_admin')
    @headers = @admin.create_new_auth_token
    @owner = User.create!(name: 'Owner teste', email: "dashboard-owner-#{suffix}@example.test", password: 'TesteSeguro#2026', role: 'owner')
    @company = company
    @plan = Plan.create!(name: 'Plano teste', code: "dashboard_#{suffix}", price: 50, duration_months: 1, max_owner_sessions: 1)
  end
  teardown { Rack::Attack.enabled = @attack }

  test 'server authorization ignores spoofed roles and customer credentials' do
    get '/api/super_admin/dashboard', as: :json
    assert_response :unauthorized
    %w[owner employee].each do |role|
      user = role == 'owner' ? @owner : User.create!(name: 'Staff teste', email: "dashboard-employee-#{SecureRandom.hex(5)}@example.test", password: 'TesteSeguro#2026', role: role)
      get '/api/super_admin/dashboard', headers: user.create_new_auth_token, params: { role: 'super_admin', user_id: @admin.id }, as: :json
      assert_response :forbidden
      assert_not response.parsed_body.key?('summary')
    end
    customer = Customer.create!(name: 'Cliente', email: "dashboard-customer-#{SecureRandom.hex(5)}@example.test", password: 'TesteSeguro#2026', establishment: @company)
    session = customer.customer_sessions.create!(session_id: SecureRandom.uuid, expires_at: 1.day.from_now,
      refresh_token_digest: SecureRandom.hex(32), csrf_token_digest: SecureRandom.hex(32))
    token = CustomerJsonWebToken.encode_access_token({ customer_id: customer.id, establishment_id: @company.id, sid: session.session_id })
    get '/api/super_admin/dashboard', headers: { 'Authorization' => "Bearer #{token}" }, as: :json
    assert_response :unauthorized
    dashboard
    assert_response :ok
    assert_equal 'no-store', response.headers['Cache-Control']
  end

  test 'current contracts match started latest and validity rules without reviving replaced contracts' do
    contract(status: 'active', end_date: Date.yesterday)
    contract(establishment: company, start_date: Date.tomorrow)
    canceled_company = company
    contract(establishment: canceled_company, status: 'canceled', end_date: Date.current)
    replaced_company = company
    contract(establishment: replaced_company, created_at: 2.days.ago)
    contract(establishment: replaced_company, status: 'overdue', created_at: 1.day.ago)
    active_company = company
    contract(establishment: active_company, created_at: 2.days.ago)
    contract(establishment: active_company, status: 'pending', created_at: 1.day.ago)
    contract(establishment: company(active: false))
    dashboard
    assert_response :ok
    assert_equal 2, response.parsed_body.dig('summary', 'active_subscriptions_count')
    assert_equal 2, response.parsed_body.dig('charts', 'subscriptions_by_plan').sum { |item| item['total'] }
  end

  test 'contract values use one local monthly boundary exclude pending and retain historical statuses' do
    travel_to Time.zone.local(2026, 10, 1, 0, 0, 0) do
      contract(created_at: Time.zone.local(2026, 9, 30, 23, 59, 59), price_paid: 10)
      historical = contract(created_at: Time.current, price_paid: 20)
      contract(created_at: Time.current, status: 'pending', price_paid: 90)
      contract(created_at: Time.zone.local(2026, 11, 1), price_paid: 70)
      @company.update!(created_at: Time.zone.local(2026, 9, 30, 23, 59, 59))
      expected_new = Establishment.where(created_at: Time.current.beginning_of_month...Time.current.beginning_of_month.next_month).count
      dashboard
      assert_response :ok
      assert_equal Time.current.iso8601, response.parsed_body['generated_at']
      assert_equal 20.0, response.parsed_body.dig('summary', 'monthly_contracted_value')
      assert_equal expected_new, response.parsed_body.dig('summary', 'new_establishments_this_month')
      trend = response.parsed_body.dig('charts', 'contracted_value_trend')
      assert_equal 6, trend.length
      assert_equal %w[05/2026 06/2026 07/2026 08/2026 09/2026 10/2026], trend.map { |item| item['month'] }
      assert_equal [0, 0, 0, 0, 10.0, 20.0], trend.map { |item| item['value'] }
      historical.update!(status: 'expired')
      dashboard
      assert_equal 20.0, response.parsed_body.dig('summary', 'monthly_contracted_value')
    end
  end

  test 'response minimizes cancellation properties and excludes establishment list' do
    subscription = contract(status: 'canceled')
    SubscriptionCancellation.create!(subscription: subscription, reason: 'outro', details: 'Contato pessoal privado de teste', canceled_by_role: 'owner')
    dashboard
    assert_response :ok
    assert_not response.parsed_body.key?('establishments')
    item = response.parsed_body['recent_cancellations'].first
    assert_equal %w[canceled_by_role created_at id plan_name reason], item.keys.sort
    assert_not_includes response.body, 'Contato pessoal privado'
  end

  test 'dashboard rate limit uses verified user id and returns retry guidance' do
    store = SuperAdmin::DashboardController.cache_store
    original = store.method(:increment)
    own_method = store.singleton_class.instance_methods(false).include?(:increment)
    memory = ActiveSupport::Cache::MemoryStore.new
    keys = []
    store.define_singleton_method(:increment) do |key, amount, **options|
      keys << key
      memory.increment(key, amount, **options)
    end
    30.times { dashboard; assert_response :ok }
    get '/api/super_admin/dashboard', headers: @headers.merge('X-Forwarded-For' => '203.0.113.7'), as: :json
    assert_response :too_many_requests
    assert_equal '60', response.headers['Retry-After']
    assert_equal ["rate-limit:super_admin/dashboard:dashboard:#{@admin.id}"], keys.uniq
    assert_not response.parsed_body.key?('summary')
  ensure
    if original
      own_method ? store.define_singleton_method(:increment, original) : store.singleton_class.remove_method(:increment)
    end
  end

  test 'cancellation audit does not duplicate free text' do
    subscription = contract
    patch "/api/subscriptions/#{subscription.id}/cancel", headers: @owner.create_new_auth_token.merge('X-Establishment-ID' => @company.id.to_s),
      params: { reason: 'outro', details: 'Texto privado de teste' }, as: :json
    assert_response :ok
    log = AuditLog.find_by!(action: 'subscription_canceled', auditable_id: subscription.id)
    assert_not log.details.key?('details')
    assert_equal 'Texto privado de teste', subscription.reload.subscription_cancellation.details
  end

  private
  def company(active: true)
    Establishment.create!(name: 'Empresa teste', slug: "dashboard-#{SecureRandom.hex(5)}", owner: @owner, active: active)
  end
  def dashboard
    get '/api/super_admin/dashboard', headers: @headers, as: :json
    @headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
  end
  def contract(establishment: @company, start_date: Date.current, end_date: 1.month.from_now.to_date, status: 'active', created_at: Time.current, price_paid: 50)
    establishment.subscriptions.create!(plan: @plan, status: status, start_date: start_date, end_date: end_date, price_paid: price_paid, billing_cycle: 'monthly', created_at: created_at)
  end
end
