require 'test_helper'

class PlanSessionCatalogTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)

  setup do
    @previous_attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @admin = User.create!(name: 'Administrador', email: "catalog-#{SecureRandom.hex(5)}@example.test",
      password: 'TesteSeguro#2026', role: 'super_admin')
    @headers = @admin.create_new_auth_token
    @plans = %w[Standard Plus Pro Ultra].each_with_index.map do |name, index|
      Plan.create!(name: name, code: "catalog_#{SecureRandom.hex(5)}", price: (index + 1) * 50,
        duration_months: 1, max_owner_sessions: index + 1, active: true)
    end
  end

  teardown do
    Rack::Attack.enabled = @previous_attack
  end

  test 'a full catalog rejects a fifth active plan at every tier and rejects limits above four' do
    [1, 2, 3, 4, 5].each do |limit|
      post '/api/super_admin/plans', params: { plan: new_plan_attributes.merge(max_owner_sessions: limit) },
        headers: @headers, as: :json
      assert_response :unprocessable_entity
      rotate_headers
      assert_equal 4, Plan.where(active: true).count
    end
    assert_equal [1, 2, 3, 4], Plan.where(active: true).order(:max_owner_sessions).pluck(:max_owner_sessions)
  end

  test 'editing the current tier works while moving into an occupied tier is rejected' do
    patch "/api/super_admin/plans/#{@plans.first.id}", params: { plan: { price: 75, max_owner_sessions: 1 } },
      headers: @headers, as: :json
    assert_response :success
    rotate_headers
    assert_equal 75, @plans.first.reload.price
    patch "/api/super_admin/plans/#{@plans.first.id}", params: { plan: { max_owner_sessions: 4 } },
      headers: @headers, as: :json
    assert_response :unprocessable_entity
    assert_equal 1, @plans.first.reload.max_owner_sessions
  end

  test 'partial catalogs do not require four plans or a four session tier but still reject duplicates' do
    @plans.last.destroy!
    get '/api/super_admin/plans', headers: @headers
    assert_response :success
    rotate_headers
    assert_equal [1, 2, 3], response.parsed_body.map { |plan| plan['max_owner_sessions'] }.sort

    post '/api/super_admin/plans', params: { plan: new_plan_attributes.merge(max_owner_sessions: 2) }, headers: @headers, as: :json
    assert_response :unprocessable_entity
    rotate_headers
    assert_equal 3, Plan.where(active: true).count

    @plans.fetch(2).destroy!
    post '/api/super_admin/plans', params: { plan: new_plan_attributes.merge(name: 'Nome livre', price: 200, max_owner_sessions: 4) },
      headers: @headers, as: :json
    assert_response :created
    assert_equal 'Nome livre', response.parsed_body['name']
    assert_equal [1, 2, 4], Plan.where(active: true).order(:max_owner_sessions).pluck(:max_owner_sessions)
  end

  test 'inactivation frees a tier without deleting the old plan and reactivation cannot collide' do
    patch "/api/super_admin/plans/#{@plans.last.id}", params: { plan: { active: false } }, headers: @headers, as: :json
    assert_response :success
    rotate_headers
    post '/api/super_admin/plans', params: { plan: new_plan_attributes.merge(price: 250, max_owner_sessions: 4) }, headers: @headers, as: :json
    assert_response :created
    rotate_headers
    assert_equal 4, Plan.where(active: true).count
    assert_not @plans.last.reload.active?
    patch "/api/super_admin/plans/#{@plans.last.id}", params: { plan: { active: true } }, headers: @headers, as: :json
    assert_response :unprocessable_entity
    assert_not @plans.last.reload.active?
  end

  test 'database conflicts from simultaneous saves produce a safe validation response' do
    conflict = Plan.new(new_plan_attributes)
    conflict.define_singleton_method(:save) { raise ActiveRecord::RecordNotUnique, 'internal database details' }
    original_new = Plan.method(:new)
    own_new = Plan.singleton_class.instance_methods(false).include?(:new)
    Plan.define_singleton_method(:new) { |*_args| conflict }
    post '/api/super_admin/plans', params: { plan: new_plan_attributes }, headers: @headers, as: :json
    assert_response :unprocessable_entity
    assert_not_includes response.body, 'internal database details'
  ensure
    if own_new
      Plan.define_singleton_method(:new, original_new)
    else
      Plan.singleton_class.remove_method(:new)
    end
  end

  test 'only super admin can read or change the session tiers' do
    get '/api/super_admin/plans'
    assert_response :unauthorized
    %w[owner employee].each do |role|
      user = User.create!(name: 'Sem Permissao', email: "#{role}-catalog-#{SecureRandom.hex(5)}@example.test",
        password: 'TesteSeguro#2026', role: role)
      headers = user.create_new_auth_token
      get '/api/super_admin/plans', headers: headers
      assert_response :forbidden
      post '/api/super_admin/plans', params: { plan: new_plan_attributes }, headers: headers, as: :json
      assert_response :forbidden
      patch "/api/super_admin/plans/#{@plans.first.id}", params: { plan: { active: false } }, headers: headers, as: :json
      assert_response :forbidden
    end
    assert_equal 4, Plan.where(active: true).count
  end

  private

  def new_plan_attributes
    { name: 'Novo plano', code: "new_#{SecureRandom.hex(5)}", price: 100, duration_months: 1, active: true }
  end

  def rotate_headers
    @headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
  end
end
