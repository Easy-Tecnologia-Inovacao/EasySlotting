require 'test_helper'

class PlanDeletionTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)

  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    @admin = User.create!(name: 'Administrador', email: "delete-admin-#{suffix}@example.test",
      password: 'TesteSeguro#2026', role: 'super_admin')
    @headers = @admin.create_new_auth_token
    @plan = Plan.create!(name: 'Plano removivel', code: "delete_#{suffix}", price: 50,
      duration_months: 1, max_owner_sessions: 1)
    @owner = User.create!(name: 'Proprietario', email: "delete-owner-#{suffix}@example.test",
      password: 'TesteSeguro#2026', role: 'owner')
    @company = Establishment.create!(name: 'Empresa', slug: "delete-#{suffix}", owner: @owner)
  end

  teardown { Rack::Attack.enabled = @attack }

  test 'super admin deletes an unused plan and records the actor and plan in the audit log' do
    assert_difference('Plan.count', -1) do
      assert_difference("AuditLog.where(action: 'super_admin_delete_plan').count", 1) do
        delete_plan
        assert_response :no_content
      end
    end
    assert_not Plan.exists?(@plan.id)
    log = AuditLog.find_by!(action: 'super_admin_delete_plan', auditable_id: @plan.id, auditable_type: 'Plan')
    assert_equal @admin.id, log.user_id
    assert_equal @plan.id, log.details['plan_id']
    assert_equal @plan.code, log.details['plan_code']
    assert_equal '', response.body
  end

  test 'unauthenticated owner employee and customer credentials cannot delete plans or spoof the admin role' do
    delete_plan(headers: {})
    assert_response :unauthorized
    %w[owner employee customer].each do |role|
      user = role == 'owner' ? @owner : User.create!(name: 'Sem Permissao',
        email: "delete-#{role}-#{SecureRandom.hex(4)}@example.test", password: 'TesteSeguro#2026', role: role)
      delete_plan(headers: user.create_new_auth_token, params: { role: 'super_admin', user_id: @admin.id })
      assert_response role == 'customer' ? :unauthorized : :forbidden
      assert Plan.exists?(@plan.id)
    end
    assert_equal 0, AuditLog.where(action: 'super_admin_delete_plan').count

    customer = Customer.create!(name: 'Cliente', email: "delete-customer-#{SecureRandom.hex(4)}@example.test",
      password: 'TesteSeguro#2026', establishment: @company)
    session = customer.customer_sessions.create!(session_id: SecureRandom.uuid, expires_at: 7.days.from_now,
      refresh_token_digest: SecureRandom.hex(32), csrf_token_digest: SecureRandom.hex(32))
    token = CustomerJsonWebToken.encode_access_token({ customer_id: customer.id, establishment_id: @company.id, sid: session.session_id })
    delete_plan(headers: { 'Authorization' => "Bearer #{token}" })
    assert_response :unauthorized
    assert Plan.exists?(@plan.id)
  end

  test 'every subscription status preserves the plan and contract even if the plan is inactive' do
    @plan.update!(active: false)
    Subscription::STATUSES.each do |status|
      subscription = create_subscription(status: status)
      assert_no_difference(['Plan.count', 'Subscription.count', 'AuditLog.count']) do
        delete_plan
        assert_response :conflict
        rotate_headers
      end
      assert_equal 'PLAN_HAS_SUBSCRIPTIONS', response.parsed_body['code']
      assert_includes response.parsed_body['error'], 'desative'
      assert_not_includes response.body, 'PG::'
      assert_equal @plan.id, subscription.reload.plan_id
      assert_equal status, subscription.status
      assert Plan.exists?(@plan.id)
      subscription.destroy!
    end
  end

  test 'unknown and malformed IDs return a safe not found response for super admin' do
    [Plan.maximum(:id) + 1, 'invalid'].each do |id|
      delete "/api/super_admin/plans/#{id}", headers: @headers, as: :json
      assert_response :not_found
      rotate_headers
      assert_equal 'Recurso não encontrado', response.parsed_body['error']
    end
  end

  test 'foreign key protects a subscription arriving after an empty association was loaded' do
    @plan.subscriptions.load
    subscription = create_subscription
    original_find = Plan.method(:find)
    own_find = Plan.singleton_class.instance_methods(false).include?(:find)
    stale_plan = @plan
    Plan.define_singleton_method(:find) { |id| id.to_s == stale_plan.id.to_s ? stale_plan : original_find.call(id) }
    delete_plan
    assert_response :conflict
    assert_equal 'PLAN_HAS_SUBSCRIPTIONS', response.parsed_body['code']
    assert Plan.exists?(@plan.id)
    assert Subscription.exists?(subscription.id)
    assert_equal 0, AuditLog.where(action: 'super_admin_delete_plan').count
  ensure
    if original_find
      own_find ? Plan.define_singleton_method(:find, original_find) : Plan.singleton_class.remove_method(:find)
    end
  end

  test 'deleting an unused highest tier frees its session limit while preserving the lower plan' do
    upper = Plan.create!(name: 'Plano superior', code: "upper_#{SecureRandom.hex(4)}", price: 100,
      duration_months: 1, max_owner_sessions: 4)
    delete "/api/super_admin/plans/#{upper.id}", headers: @headers, as: :json
    assert_response :no_content
    rotate_headers
    post '/api/super_admin/plans', params: { plan: { name: 'Novo superior', code: "new_#{SecureRandom.hex(4)}",
      price: 150, duration_months: 1, max_owner_sessions: 4 } }, headers: @headers, as: :json
    assert_response :created
    assert Plan.exists?(@plan.id)
    assert_equal [1, 4], Plan.in_catalog_order.pluck(:max_owner_sessions)
  end

  private

  def delete_plan(headers: @headers, params: {})
    delete "/api/super_admin/plans/#{@plan.id}", headers: headers, params: params, as: :json
  end

  def create_subscription(status: 'active')
    @company.subscriptions.create!(plan: Plan.find(@plan.id), status: status, start_date: 2.months.ago.to_date,
      end_date: Date.yesterday, billing_cycle: 'monthly', price_paid: 50)
  end

  def rotate_headers
    @headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
  end
end
