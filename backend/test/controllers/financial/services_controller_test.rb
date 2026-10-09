require 'test_helper'

class Financial::ServicesControllerTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    suffix = SecureRandom.hex(4)

    @owner = User.create!(
      name: 'Proprietário Serviços',
      email: "owner_serv_#{suffix}@test.com",
      role: 'owner',
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy',
      confirmed_at: Time.current,
      uid: "owner_serv_#{suffix}@test.com",
      provider: 'email'
    )

    @establishment = Establishment.create!(
      name: "Salão Serviços #{suffix}",
      slug: "salao-serv-#{suffix}",
      owner: @owner
    )
    EstablishmentMembership.create!(establishment: @establishment, user: @owner, role: 'owner')

    @employee_user = User.create!(
      name: 'Especialista',
      email: "esp_#{suffix}@test.com",
      role: 'employee',
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy',
      confirmed_at: Time.current,
      uid: "esp_#{suffix}@test.com",
      provider: 'email'
    )

    EstablishmentMembership.create!(
      establishment: @establishment,
      user: @employee_user,
      role: 'employee'
    )

    @customer = Customer.create!(
      name: 'Cliente Serv',
      email: "cliente_serv_#{suffix}@test.com",
      establishment: @establishment,
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy'
    )

    @service1 = Service.create!(
      name: 'Corte Degradê',
      price: 60.00,
      duration_minutes: 30,
      service_type: 'cabelo',
      establishment: @establishment,
      active: true
    )

    @service2 = Service.create!(
      name: 'Barba Terapia',
      price: 40.00,
      duration_minutes: 25,
      service_type: 'barba',
      establishment: @establishment,
      active: true
    )

    @service3 = Service.create!(
      name: 'Coloração Completa',
      price: 150.00,
      duration_minutes: 90,
      service_type: 'quimica',
      establishment: @establishment,
      active: false
    )

    EmployeeService.create!(user: @employee_user, service: @service1)

    @apt = Appointment.create!(
      establishment: @establishment,
      employee: @employee_user,
      customer: @customer,
      service: @service1,
      appointment_date: Date.current,
      start_time: '10:00',
      end_time: '10:30',
      price_snapshot: 60.00,
      status: 'completed'
    )

    @auth_headers = @owner.create_new_auth_token.merge(
      'X-Establishment-Id' => @establishment.id.to_s
    )
  end

  test 'GET /api/financial/services returns summary, highlights, ranking and services catalog' do
    get '/api/financial/services', headers: @auth_headers
    assert_response :ok

    json = JSON.parse(response.body)
    assert_includes json.keys, 'summary'
    assert_includes json.keys, 'highlights'
    assert_includes json.keys, 'ranking'
    assert_includes json.keys, 'services'

    # Summary
    summary = json['summary']
    assert_equal 3, summary['total_servicos']
    assert_equal 2, summary['ativos']
    assert_equal 1, summary['inativos']
    assert_equal 1, summary['total_agendamentos']
    assert_equal 60.0, summary['faturamento_total'].to_f
    # Ticket médio: (60 + 40 + 150) / 3 = 83.33
    assert_in_delta 83.33, summary['ticket_medio'].to_f, 0.05

    # Highlights
    highlights = json['highlights']
    assert_equal 'Coloração Completa', highlights['servico_mais_caro']['name']
    assert_equal 'Barba Terapia', highlights['servico_mais_barato']['name']
    assert_equal 'Coloração Completa', highlights['maior_duracao']['name']
    assert_equal 'Corte Degradê', highlights['mais_agendado']['name']
    assert_equal 'Corte Degradê', highlights['maior_faturamento']['name']

    # Ranking
    ranking = json['ranking']
    assert_equal 3, ranking.size
    assert_equal 'Coloração Completa', ranking.first['name']

    # Catalog
    services = json['services']
    assert_equal 3, services.size
    corte = services.find { |s| s['id'] == @service1.id }
    assert_equal 1, corte['appointments_count']
    assert_equal 60.0, corte['revenue'].to_f
    assert_equal 1, corte['employees_count']
  end
end
