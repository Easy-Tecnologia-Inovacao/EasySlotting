require 'test_helper'

class PlanCatalogOrderingTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)

  setup do
    @previous_attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    admin = User.create!(name: 'Administrador', email: "order-#{SecureRandom.hex(5)}@example.test",
      password: 'TesteSeguro#2026', role: 'super_admin')
    @headers = admin.create_new_auth_token
  end

  teardown do
    Rack::Attack.enabled = @previous_attack
  end

  test 'new active plans grow in price and sessions and both APIs return the same order' do
    [[50, 1], [100, 2], [200, 4]].each { |price, sessions| create_plan(price: price, sessions: sessions) }
    ['/api/super_admin/plans', '/api/plans'].each do |endpoint|
      get endpoint, headers: @headers
      assert_response :success
      rotate_headers
      assert_equal [1, 2, 4], response.parsed_body.map { |plan| plan['max_owner_sessions'] }
      assert_equal [50, 100, 200], response.parsed_body.map { |plan| plan['price'].to_f }
    end
    create_plan(price: 150, sessions: 3, expected: :unprocessable_entity)
    assert_equal 3, Plan.where(active: true).count
  end

  test 'new plans reject equal or lower prices and cannot add a lower session tier later' do
    create_plan(price: 50, sessions: 2)
    [40, 50, 50.001].each do |price|
      create_plan(price: price, sessions: 3, expected: :unprocessable_entity)
    end
    create_plan(price: 100, sessions: 1, expected: :unprocessable_entity,
      extra: { id: 1, created_at: 1.year.ago.iso8601 })
    assert_equal 1, Plan.where(active: true).count
    create_plan(price: 100, sessions: 3)
    assert_equal [2, 3], Plan.where(active: true).order(:id).pluck(:max_owner_sessions)
  end

  test 'editing must preserve the positions between the earlier and later active plans' do
    first = create_plan(price: 50, sessions: 1)
    middle = create_plan(price: 100, sessions: 2)
    last = create_plan(price: 200, sessions: 4)
    update_plan(middle, { price: 50 }, expected: :unprocessable_entity)
    update_plan(middle, { price: 200 }, expected: :unprocessable_entity)
    update_plan(first, { max_owner_sessions: 3, price: 150 }, expected: :unprocessable_entity)
    update_plan(last, { max_owner_sessions: 1, price: 25 }, expected: :unprocessable_entity)
    update_plan(middle, { price: 150, max_owner_sessions: 3 })
    assert_equal [1, 3, 4], Plan.where(active: true).order(:id).pluck(:max_owner_sessions)
    assert_equal [50, 150, 200], Plan.where(active: true).order(:id).pluck(:price).map(&:to_i)
  end

  test 'reactivation keeps the original position and an inactive draft cannot bypass increasing creation' do
    first = create_plan(price: 50, sessions: 1)
    update_plan(first, { active: false })
    create_plan(price: 100, sessions: 2)
    create_plan(price: 200, sessions: 4)
    update_plan(first, { active: true })
    update_plan(first, { active: false, price: 150 })
    update_plan(first, { active: true }, expected: :unprocessable_entity)
    assert_not first.reload.active?
    draft = create_plan(price: 25, sessions: 1, extra: { active: false })
    update_plan(draft, { active: true }, expected: :unprocessable_entity)
    assert_not draft.reload.active?
  end

  test 'promotions do not change the normal price order of the session tiers' do
    create_plan(price: 50, sessions: 1)
    create_plan(price: 100, sessions: 2, extra: { promotion_active: true,
      promotional_price: 10, promotion_starts_at: Time.current.iso8601, promotion_duration_days: 30 })
    get '/api/plans'
    assert_response :success
    assert_equal [1, 2], response.parsed_body.map { |plan| plan['max_owner_sessions'] }
    assert_equal [50, 10], response.parsed_body.map { |plan| plan['effective_price'] }
  end

  test 'a stale inactive plan is reloaded before reactivation instead of validating an outdated price' do
    first = create_plan(price: 50, sessions: 1, extra: { active: false })
    create_plan(price: 100, sessions: 2)
    stale = Plan.find(first.id)
    first.update!(price: 150)
    assert_not stale.update(active: true)
    assert stale.errors[:price].present?
    assert_not first.reload.active?
    assert_equal 150, first.price
  end

  private

  def create_plan(price:, sessions:, expected: :created, extra: {})
    post '/api/super_admin/plans', params: { plan: { name: 'Nome definido no painel', code: "order_#{SecureRandom.hex(5)}",
      price: price, duration_months: 1, max_owner_sessions: sessions, active: true }.merge(extra) }, headers: @headers, as: :json
    assert_response expected
    rotate_headers
    Plan.find(response.parsed_body['id']) if response.status == 201
  end

  def update_plan(plan, attributes, expected: :success)
    patch "/api/super_admin/plans/#{plan.id}", params: { plan: attributes }, headers: @headers, as: :json
    assert_response expected
    rotate_headers
  end

  def rotate_headers
    @headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
  end
end
