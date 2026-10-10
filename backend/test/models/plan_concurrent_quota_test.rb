require 'test_helper'

class PlanConcurrentQuotaTest < ActiveSupport::TestCase
  parallelize(workers: 1)
  self.use_transactional_tests = false

  test 'concurrent service registrations cannot consume the same final vacancy' do
    owner = User.create!(name: 'Quota concorrente', email: "concurrent-quota-#{SecureRandom.hex(6)}@example.test", password: 'TesteSeguro#2026', role: 'owner')
    company = Establishment.create!(name: 'Quota concorrente', slug: "concurrent-quota-#{SecureRandom.hex(6)}", owner: owner)
    plan = Plan.create!(name: 'Quota concorrente', code: "concurrent_quota_#{SecureRandom.hex(6)}", price: 100, duration_months: 1, max_services: 1)
    subscription = company.subscriptions.create!(plan: plan, status: 'active', start_date: Date.current, end_date: Date.current.next_month, billing_cycle: 'monthly')
    ready, start = Queue.new, Queue.new
    threads = 2.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          service = Service.new(establishment_id: company.id, name: "Servico #{index}", service_type: 'cabelo', duration_minutes: 30, price: 50, active: true)
          service.save ? :saved : :invalid
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    assert_equal [:invalid, :saved], threads.map(&:value).sort
    assert_equal 1, company.services.count
  ensure
    Service.unscoped.where(establishment_id: company.id).delete_all if company
    subscription&.destroy!
    company&.destroy!
    plan&.destroy!
    owner&.destroy!
  end
end
