require 'test_helper'

class PlanPromotionSecurityTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)
  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @admin = User.create!(name: 'Admin teste', email: "promotion-#{SecureRandom.hex(5)}@example.test", password: 'TesteSeguro#2026', role: 'super_admin')
    @headers = @admin.create_new_auth_token
  end
  teardown { Rack::Attack.enabled = @attack }

  test 'invalid booleans quotas and incomplete promotions return safe validation errors' do
    [{ active: nil }, { highlight: nil }, { promotion_active: nil }, { max_employees: 2_147_483_648 },
     { max_services: 2.5 }, { promotion_active: true },
     { promotion_active: true, promotion_starts_at: Time.current.iso8601, promotion_duration_days: 2_147_483_648, promotional_price: 80 }].each do |invalid|
      assert_no_difference('Plan.count') do
        post '/api/super_admin/plans', params: { plan: attrs.merge(invalid) }, headers: @headers, as: :json
        assert_response :unprocessable_entity
        rotate
      end
      assert_not_includes response.body, 'PG::'
    end
  end

  test 'percentage editing changes price and conflicting sources are rejected' do
    plan = Plan.create!(attrs.merge(promo))
    patch "/api/super_admin/plans/#{plan.id}", headers: @headers, params: { plan: { promotion_mode: 'percentage', discount_percentage: 50, promotional_price: nil } }, as: :json
    assert_response :ok
    rotate
    assert_equal 50, plan.reload.promotional_price
    assert_equal 50, plan.discount_percentage
    patch "/api/super_admin/plans/#{plan.id}", headers: @headers, params: { plan: { promotion_mode: 'price', discount_percentage: 40, promotional_price: 70 } }, as: :json
    assert_response :unprocessable_entity
    rotate
    assert_equal 50, plan.reload.promotional_price
    patch "/api/super_admin/plans/#{plan.id}", headers: @headers, params: { plan: { promotion_active: false } }, as: :json
    assert_response :ok
    assert_nil plan.reload.promotional_price
    assert_nil plan.promotion_ends_at
  end

  test 'public announcement and actual price agree before during and after promotion including free price' do
    start = Time.zone.local(2026, 10, 10, 12)
    plan = Plan.create!(attrs.merge(promo).merge(promotion_starts_at: start, promotion_duration_days: 1, promotional_price: 0))
    [start - 1.second, start, start + 1.day - 1.second, start + 1.day].each_with_index do |time, index|
      travel_to time do
        get '/api/plans', as: :json
        assert_response :ok
        item = response.parsed_body.find { |row| row['id'] == plan.id }
        running = [1, 2].include?(index)
        assert_equal running, item['promotion_active']
        assert_equal running ? 0 : 100, item['effective_price']
        assert_equal plan.current_price.to_f, item['effective_price']
      end
    end
  end

  test 'explicit timezone survives API round trip and derived ends cannot be overwritten' do
    start = '2026-10-10T12:00:00+02:00'
    post '/api/super_admin/plans', headers: @headers, params: { plan: attrs.merge(promo).merge(
      promotion_starts_at: start, promotion_ends_at: '2099-01-01T00:00:00Z', role: 'owner', id: 999_999) }, as: :json
    assert_response :created
    plan = Plan.find(response.parsed_body['id'])
    assert_equal Time.iso8601(start), plan.promotion_starts_at
    assert_equal Time.iso8601(start) + 10.days, plan.promotion_ends_at
    assert_not_equal 999_999, plan.id
  end

  private
  def attrs
    { name: 'Plano teste', code: "promotion_#{SecureRandom.hex(5)}", price: 100, duration_months: 1, max_owner_sessions: 1 }
  end
  def promo
    { promotion_active: true, promotional_price: 80, promotion_starts_at: Time.current, promotion_duration_days: 10 }
  end
  def rotate
    @headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
  end
end
