require 'test_helper'

class PlanConcurrentCatalogTest < ActiveSupport::TestCase
  parallelize(workers: 1)
  self.use_transactional_tests = false

  test 'concurrent new tiers cannot invert the price and session sequence' do
    codes = 3.times.map { "concurrent_order_#{SecureRandom.hex(5)}" }
    Plan.create!(name: 'Primeiro', code: codes.first, price: 50, duration_months: 1, max_owner_sessions: 1)
    candidates = [
      { name: 'Segundo', code: codes.second, price: 200, duration_months: 1, max_owner_sessions: 2 },
      { name: 'Terceiro', code: codes.last, price: 100, duration_months: 1, max_owner_sessions: 3 }
    ]
    results = compete(candidates.map { |attributes| -> { Plan.create!(attributes) } })
    assert_equal [:invalid, :saved], results.sort
    assert_equal 2, Plan.where(code: codes, active: true).count
    rows = Plan.where(code: codes, active: true).order(:id).pluck(:price, :max_owner_sessions)
    assert rows.each_cons(2).all? { |previous, following| previous[0] < following[0] && previous[1] < following[1] }
  ensure
    Plan.where(code: codes).delete_all if codes
  end

  test 'concurrent edits cannot cross the neighboring prices' do
    codes = 2.times.map { "concurrent_edit_#{SecureRandom.hex(5)}" }
    first = Plan.create!(name: 'Primeiro', code: codes.first, price: 50, duration_months: 1, max_owner_sessions: 1)
    second = Plan.create!(name: 'Segundo', code: codes.last, price: 100, duration_months: 1, max_owner_sessions: 2)
    results = compete([
      -> { Plan.find(first.id).update!(price: 90) },
      -> { Plan.find(second.id).update!(price: 80) }
    ])
    assert_equal [:invalid, :saved], results.sort
    assert first.reload.price < second.reload.price
  ensure
    Plan.where(code: codes).delete_all if codes
  end

  test 'two concurrent plan inserts cannot reserve the same active session tier' do
    codes = 2.times.map { "concurrent_tier_#{SecureRandom.hex(5)}" }
    ready, start, results = Queue.new, Queue.new, Queue.new
    threads = codes.map do |code|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          plan = Plan.new(name: 'Plus Concorrente', code: code, price: 100, duration_months: 1, max_owner_sessions: 2)
          ready << true
          start.pop
          begin
            # Simula os dois cadastros que já passaram pela validação Ruby.
            plan.save!(validate: false)
            results << :created
          rescue ActiveRecord::RecordNotUnique
            results << :conflict
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:value)
    assert_equal [:conflict, :created], 2.times.map { results.pop }.sort
    assert_equal 1, Plan.where(code: codes, active: true).count
  ensure
    Plan.where(code: codes).delete_all if codes
  end

  private

  def compete(actions)
    ready, start, results = Queue.new, Queue.new, Queue.new
    threads = actions.map do |action|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          begin
            action.call
            results << :saved
          rescue ActiveRecord::RecordInvalid
            results << :invalid
          end
        end
      end
    end
    actions.size.times { ready.pop }
    actions.size.times { start << true }
    threads.each(&:value)
    actions.size.times.map { results.pop }
  end
end
