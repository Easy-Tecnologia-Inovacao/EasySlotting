require "test_helper"

class SecurityHardeningTest < ActionDispatch::IntegrationTest
  setup do
    suffix = SecureRandom.hex(6)
    @owner = User.create!(name: 'Dono Teste', email: "owner-#{suffix}@example.test",
                          password: 'Seguranca#2026', role: 'owner', confirmed_at: Time.current)
    @employee = User.create!(name: 'Funcionario Teste', email: "employee-#{suffix}@example.test",
                             password: 'Seguranca#2026', role: 'employee', confirmed_at: Time.current)
    @establishment = Establishment.create!(name: 'Empresa A', slug: "empresa-a-#{suffix}", owner: @owner)
    foreign_owner = User.create!(name: 'Outro Dono', email: "other-#{suffix}@example.test",
                                 password: 'Seguranca#2026', role: 'owner')
    @foreign = Establishment.create!(name: 'Empresa B', slug: "empresa-b-#{suffix}", owner: foreign_owner)
    EstablishmentMembership.create!(establishment: @establishment, user: @owner, role: 'owner')
    @membership = EstablishmentMembership.create!(establishment: @establishment, user: @employee,
                                                   role: 'employee', can_manage_financial: false)
    @customer = Customer.create!(establishment: @establishment, name: 'Cliente Local',
                                 email: "local-#{suffix}@example.test", password: 'Seguranca#2026')
    @foreign_customer = Customer.create!(establishment: @foreign, name: 'Cliente Externo',
                                         email: "foreign-#{suffix}@example.test", password: 'Seguranca#2026')
    @service = Service.create!(establishment: @establishment, name: 'Corte', price: 50,
                               duration_minutes: 30, service_type: 'normal')
  end

  test 'customer listing excludes customers from another establishment' do
    get '/api/admin/customers', headers: auth_headers(@owner)
    assert_response :success
    ids = response.parsed_body.map { |customer| customer.fetch('id') }
    assert_includes ids, @customer.id
    assert_not_includes ids, @foreign_customer.id

    get '/api/admin/customers', headers: auth_headers(@employee).merge('X-Establishment-ID' => @foreign.id.to_s)
    assert_response :forbidden
  end

  test 'employee without financial permission is forbidden' do
    get '/api/financial/dashboard', headers: auth_headers(@employee)
    assert_response :forbidden
  end

  test 'employee with financial permission can access dashboard' do
    @membership.update!(can_manage_financial: true)
    get '/api/financial/dashboard', headers: auth_headers(@employee)
    assert_response :success
    assert response.parsed_body.key?('summary')
  end

  test 'duplicate booking is rejected without creating a second appointment' do
    date = Date.current + 1.day
    EmployeeService.create!(user: @employee, service: @service)
    BusinessHour.find_or_initialize_by(establishment: @establishment, weekday: date.wday)
                .update!(is_open: true, start_time: '09:00', end_time: '18:00')
    EmployeeWorkingHour.find_or_initialize_by(user: @employee, weekday: date.wday)
                       .update!(is_available: true, start_time: '09:00', end_time: '18:00')
    params = { customer_id: @customer.id, service_id: @service.id, employee_id: @employee.id,
               appointment_date: date.to_s, start_time: '10:00' }

    assert_difference('Appointment.count', 1) do
      post '/api/appointments', params: params, headers: auth_headers(@owner), as: :json
      assert_response :created
    end
    assert_no_difference('Appointment.count') do
      post '/api/appointments', params: params, headers: auth_headers(@owner), as: :json
      assert_response :unprocessable_entity
    end
  end

  private

  def auth_headers(user)
    @auth_clients ||= {}
    headers = user.reload.create_new_auth_token(@auth_clients[user.id])
    @auth_clients[user.id] = headers['client']
    headers.merge('X-Establishment-ID' => @establishment.id.to_s)
  end
end
