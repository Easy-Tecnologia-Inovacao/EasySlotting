require 'test_helper'

class PlanQuotaTest < ActionDispatch::IntegrationTest
  parallelize(workers: 1)
  setup do
    @attack = Rack::Attack.enabled
    Rack::Attack.enabled = false
    @owner = User.create!(name: 'Owner teste', email: "quota-#{SecureRandom.hex(5)}@example.test", password: 'TesteSeguro#2026', role: 'owner')
    @company = Establishment.create!(name: 'Empresa teste', slug: "quota-#{SecureRandom.hex(5)}", owner: @owner)
    @plan = Plan.create!(name: 'Quota teste', code: "quota_#{SecureRandom.hex(5)}", price: 100, duration_months: 1, max_services: 1, max_employees: 1, max_appointments_per_month: 1)
    @subscription = @company.subscriptions.create!(plan: @plan, status: 'active', start_date: Date.current, end_date: 1.month.from_now.to_date, price_paid: 100, billing_cycle: 'monthly')
  end
  teardown { Rack::Attack.enabled = @attack }

  test 'API service quota cannot be bypassed by forged limits and excludes soft deleted services' do
    headers = @owner.create_new_auth_token.merge('X-Establishment-ID' => @company.id.to_s)
    2.times do |index|
      post '/api/services', headers: headers, params: { service: service_attrs.merge(name: "Servico #{index}"), max_services: nil, plan_id: 0 }, as: :json
      assert_response index.zero? ? :created : :unprocessable_entity
      headers.merge!(response.headers.slice('access-token', 'client', 'uid')) if response.headers['access-token'].present?
    end
    assert_equal 1, @company.services.count
    first = @company.services.first
    first.discard
    assert @company.services.create(service_attrs).persisted?
    assert_not first.update(deleted_at: nil)
  end

  test 'active employee memberships consume independent tenant quotas and reactivation checks capacity' do
    first = employee
    assert @company.establishment_memberships.create(user: first, role: 'employee', active: true).persisted?
    second = employee
    blocked = @company.establishment_memberships.new(user: second, role: 'employee', active: true)
    assert_not blocked.save
    @company.establishment_memberships.find_by!(user: first).update!(active: false)
    assert blocked.save
    assert_not @company.establishment_memberships.find_by!(user: first).update(active: true)
    other = Establishment.create!(name: 'Outra empresa', slug: "quota-other-#{SecureRandom.hex(5)}", owner: @owner)
    assert other.establishment_memberships.create(user: first, role: 'employee', active: true).persisted?
  end

  test 'appointments reserve quota per scheduled month cancellation releases and edits remain possible after downgrade' do
    service = @company.services.create!(service_attrs)
    staff = employee
    @company.establishment_memberships.create!(user: staff, role: 'employee', active: true)
    customer = Customer.create!(name: 'Cliente teste', email: "quota-customer-#{SecureRandom.hex(5)}@example.test", password: 'TesteSeguro#2026', establishment: @company)
    attrs = { establishment: @company, employee: staff, customer: customer, service: service,
      appointment_date: Date.current, start_time: '10:00', end_time: '10:30', status: 'pending' }
    first = Appointment.create!(attrs)
    second = Appointment.new(attrs.merge(start_time: '11:00', end_time: '11:30', status: 'confirmed'))
    assert_not second.save
    assert first.update(status: 'confirmed')
    assert first.update(status: 'completed')
    future = Appointment.create!(attrs.merge(appointment_date: Date.current.next_month, start_time: '12:00', end_time: '12:30'))
    assert_not future.update(appointment_date: Date.current)
    first.update!(status: 'canceled')
    assert second.save
    assert_not first.update(status: 'confirmed')
    @plan.update!(max_appointments_per_month: 0)
    assert second.update(notes: 'Correção permitida após downgrade')
    assert_not Appointment.new(attrs.merge(appointment_date: Date.current + 2.months)).save
  end

  test 'zero blocks new records null is unlimited and expired replacement does not resurrect old quota' do
    @plan.update!(max_services: 0)
    assert_not @company.services.new(service_attrs).save
    @plan.update!(max_services: nil)
    2.times { assert @company.services.create(service_attrs).persisted? }
    @plan.update!(max_services: 1)
    assert @company.services.first.update(name: 'Edição existente permitida')
    assert_not @company.services.new(service_attrs).save
    @company.subscriptions.create!(plan: @plan, status: 'expired', start_date: Date.yesterday, end_date: Date.yesterday, billing_cycle: 'monthly', price_paid: 100, created_at: 1.second.from_now)
    assert @company.services.create(service_attrs).persisted?
  end

  private
  def service_attrs
    { name: 'Servico teste', service_type: 'cabelo', duration_minutes: 30, price: 50, active: true }
  end
  def employee
    User.create!(name: 'Funcionario teste', email: "quota-staff-#{SecureRandom.hex(5)}@example.test", password: 'TesteSeguro#2026', role: 'employee')
  end
end
