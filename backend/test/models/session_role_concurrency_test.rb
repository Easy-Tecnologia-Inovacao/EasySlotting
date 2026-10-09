require 'test_helper'

class SessionRoleConcurrencyTest < ActiveSupport::TestCase
  parallelize(workers: 1)
  self.use_transactional_tests = false
  PASSWORD = 'TesteSeguro#2026'.freeze

  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    suffix = SecureRandom.hex(5)
    @owner = User.create!(name: 'Proprietario', email: "race-owner-#{suffix}@example.test", password: PASSWORD, role: 'owner')
    @company = Establishment.create!(name: 'Empresa', slug: "race-#{suffix}", owner: @owner)
    @employee = User.create!(name: 'Funcionario', email: "race-employee-#{suffix}@example.test", password: PASSWORD, role: 'employee')
    EstablishmentMembership.create!(user: @employee, establishment: @company, role: 'employee', active: true)
    @customer = Customer.create!(name: 'Cliente', email: "race-customer-#{suffix}@example.test", password: PASSWORD, establishment: @company)
    @customer.add_trusted_device!(ip: '127.0.0.1', device_token: 'a' * 64)
  end

  teardown do
    Rack::Attack.enabled = @attack
    @company&.destroy!
    @employee&.destroy!
    @owner&.destroy!
  end

  test 'two employee logins competing for the only slot create just one session' do
    results = compete do
      begin
        User.find(@employee.id).create_new_auth_token
        :created
      rescue OwnerSessionPolicy::LimitReached
        :limited
      end
    end
    assert_equal [:created, :limited], results.sort
    assert_equal 1, @employee.reload.tokens.size
  end

  test 'concurrent customer logins preserve both sessions and refresh replay accepts only one rotation' do
    logins = compete do
      browser = ActionDispatch::Integration::Session.new(Rails.application)
      browser.post "/api/customer_auth/#{@company.slug}/sign_in", params: {
        email: @customer.email, password: PASSWORD, device_token: 'a' * 64 }, as: :json
      raise "Unexpected login status #{browser.response.status}" unless browser.response.status == 200
      [browser.cookies.to_hash, browser.response.parsed_body]
    end
    assert_equal 2, @customer.customer_sessions.count
    cookie_values, data = logins.first
    results = compete do
      browser = ActionDispatch::Integration::Session.new(Rails.application)
      cookie_values.each { |name, value| browser.cookies[name] = value }
      browser.post "/api/customer_auth/#{@company.slug}/refresh", headers: { 'X-CSRF-Token' => data['csrf_token'] }, as: :json
      browser.response.status
    end
    assert_equal [200, 401], results.sort
    assert_equal 2, @customer.customer_sessions.count
  end

  private

  def compete
    ready, start, results = Queue.new, Queue.new, Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << true
          start.pop
          results << yield
        end
      end
    end
    2.times { ready.pop }
    2.times { start << true }
    threads.each(&:value)
    2.times.map { results.pop }
  end
end
