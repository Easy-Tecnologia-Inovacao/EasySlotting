require 'test_helper'

class OwnerConcurrentSessionsTest < ActiveSupport::TestCase
  parallelize(workers: 1)
  self.use_transactional_tests = false

  test 'two concurrent logins competing for the last slot cannot exceed four sessions' do
    suffix = SecureRandom.hex(5)
    user = User.create!(name: 'Dono Concorrencia', email: "concurrent-#{suffix}@example.test", password: 'TesteSeguro#2026', role: 'owner')
    establishment = Establishment.create!(name: 'Empresa Concorrencia', slug: "concurrent-#{suffix}", owner: user)
    plan = Plan.create!(name: 'Plano Concorrencia', code: "concurrent_#{suffix}", price: 100, duration_months: 1, max_owner_sessions: 4)
    establishment.subscriptions.create!(plan: plan, status: 'active', start_date: Date.current,
      end_date: 1.month.from_now.to_date, billing_cycle: 'monthly')
    3.times { user.create_new_auth_token }
    previous_clients = user.reload.tokens.keys
    ready, start, results = Queue.new, Queue.new, Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          contender = User.find(user.id)
          ready << true
          start.pop
          begin
            contender.create_new_auth_token
            results << :created
          rescue OwnerSessionPolicy::LimitReached
            results << :limited
          end
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:value)
    assert_equal [:created, :limited], 2.times.map { results.pop }.sort
    assert_equal 4, user.reload.tokens.size
    assert_empty previous_clients - user.tokens.keys
  ensure
    establishment&.destroy!
    plan&.destroy!
    user&.destroy!
  end
end
