require 'test_helper'

class Financial::CommissionClosingsControllerTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    suffix = SecureRandom.hex(4)

    @owner = User.create!(
      name: 'Proprietário Financeiro',
      email: "owner_fin_#{suffix}@test.com",
      role: 'owner',
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy',
      confirmed_at: Time.current,
      uid: "owner_fin_#{suffix}@test.com",
      provider: 'email'
    )

    @establishment = Establishment.create!(
      name: "Salão Financeiro #{suffix}",
      slug: "salao-fin-#{suffix}",
      owner: @owner
    )
    EstablishmentMembership.create!(establishment: @establishment, user: @owner, role: 'owner')

    @employee_user = User.create!(
      name: 'Barbeiro Fin',
      email: "barbeiro_fin_#{suffix}@test.com",
      role: 'employee',
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy',
      confirmed_at: Time.current,
      uid: "barbeiro_fin_#{suffix}@test.com",
      provider: 'email'
    )

    @membership = EstablishmentMembership.create!(
      establishment: @establishment,
      user: @employee_user,
      role: 'employee',
      financial_model: 'porcentagem',
      financial_value: 50,
      tipo_vinculo: 'mei'
    )

    @customer = Customer.create!(
      name: 'Cliente Fin',
      email: "cliente_fin_#{suffix}@test.com",
      establishment: @establishment,
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy'
    )

    @service = Service.create!(
      name: 'Corte Especial',
      price: 120.00,
      duration_minutes: 40,
      service_type: 'cabelo',
      establishment: @establishment
    )

    @apt = Appointment.create!(
      establishment: @establishment,
      employee: @employee_user,
      customer: @customer,
      service: @service,
      appointment_date: Date.current,
      start_time: '14:00',
      end_time: '14:40',
      price_snapshot: 120.00,
      status: 'completed'
    )

    Financial::CommissionCalculator.call(@apt)

    @auth_headers = @owner.create_new_auth_token.merge(
      'X-Establishment-Id' => @establishment.id.to_s
    )
  end

  test 'GET /api/financial/commissions returns report with summary and professionals' do
    get '/api/financial/commissions', headers: @auth_headers
    assert_response :ok

    json = JSON.parse(response.body)
    assert json['summary'].present?
    assert json['professionals'].present?
    assert_equal 60.00, json['summary']['comissao_total'].to_f # 50% de 120
    assert_equal 1, json['professionals'].size
    assert_equal 'mei', json['professionals'].first['tipo_vinculo']
  end

  test 'GET /api/financial/commission_closings/preview returns detailed services' do
    get '/api/financial/commission_closings/preview',
        params: { employee_id: @employee_user.id },
        headers: @auth_headers

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal @employee_user.id, json['employee_id']
    assert_equal 1, json['services_count']
    assert_equal 120.00, json['gross_revenue'].to_f
    assert_equal 60.00, json['gross_commission'].to_f
    assert_equal 1, json['items'].size
  end

  test 'POST, GET, and REOPEN commission closing lifecycle' do
    ref_month = Date.current.strftime('%Y-%m')

    # 1. Create closing
    post '/api/financial/commission_closings',
         params: {
           closing: {
             employee_id: @employee_user.id,
             reference_month: ref_month,
             period_start: Date.current.beginning_of_month.to_s,
             period_end: Date.current.end_of_month.to_s,
             notes: 'Fechamento de teste'
           }
         },
         headers: @auth_headers

    assert_response :created
    created_json = JSON.parse(response.body)
    closing_id = created_json['closing']['id']
    assert_equal 'closed', created_json['closing']['status']
    assert_equal 60.00, created_json['closing']['gross_commission_amount'].to_f

    # 2. Show closing
    get "/api/financial/commission_closings/#{closing_id}", headers: @auth_headers
    assert_response :ok
    show_json = JSON.parse(response.body)
    assert_equal closing_id, show_json['id']
    assert_equal 1, show_json['items'].size
    assert_equal 1, show_json['histories'].size

    # 3. List closings
    get '/api/financial/commission_closings',
        params: { reference_month: ref_month },
        headers: @auth_headers
    assert_response :ok
    list_json = JSON.parse(response.body)
    assert_equal 1, list_json.size

    # 4. Report for month
    get '/api/financial/commission_closings/report',
        params: { reference_month: ref_month },
        headers: @auth_headers
    assert_response :ok
    report_json = JSON.parse(response.body)
    assert report_json['disclaimer'].present?
    assert_equal 60.00, report_json['total_gross_commission'].to_f

    # 5. Reopen closing
    post "/api/financial/commission_closings/#{closing_id}/reopen",
         params: { reason: 'Correção de valor acordado' },
         headers: @auth_headers
    assert_response :ok
    reopened_json = JSON.parse(response.body)
    assert_equal 'reopened', reopened_json['closing']['status']
  end

  test 'unauthenticated request is rejected' do
    get '/api/financial/commissions'
    assert_response :unauthorized
  end

  test 'employee without financial permission is forbidden' do
    emp_headers = @employee_user.create_new_auth_token.merge(
      'X-Establishment-Id' => @establishment.id.to_s
    )
    get '/api/financial/commissions', headers: emp_headers
    assert_response :forbidden
  end
end
