require 'test_helper'

class CommissionClosingTest < ActiveSupport::TestCase
  fixtures []
  setup do
    @owner = User.create!(
      name: 'Proprietário Teste',
      email: "owner_#{SecureRandom.hex(4)}@test.com",
      role: 'owner',
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy'
    )

    @establishment = Establishment.create!(
      name: 'Salão Teste Comissões',
      slug: "salao-teste-#{SecureRandom.hex(4)}",
      owner: @owner
    )

    @employee_user = User.create!(
      name: 'Barbeiro Teste',
      email: "barbeiro_#{SecureRandom.hex(4)}@test.com",
      role: 'employee',
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy'
    )

    @customer = Customer.create!(
      name: 'Cliente Teste',
      email: "cliente_#{SecureRandom.hex(4)}@test.com",
      establishment: @establishment,
      password: 'Secret#987!Xy',
      password_confirmation: 'Secret#987!Xy'
    )

    @service = Service.create!(
      name: 'Corte e Barba',
      price: 100.00,
      duration_minutes: 45,
      service_type: 'cabelo',
      establishment: @establishment
    )
  end

  test 'membership validates tipo_vinculo and commission_bonus_percentage' do
    membership = EstablishmentMembership.new(
      establishment: @establishment,
      user: @employee_user,
      role: 'employee',
      financial_model: 'fixo_servico',
      financial_value: 50,
      tipo_vinculo: 'mei',
      commission_bonus_percentage: 15
    )
    assert membership.valid?

    # Invalid tipo_vinculo
    membership.tipo_vinculo = 'invalido'
    assert_not membership.valid?

    # Invalid commission_bonus_percentage (> 100)
    membership.tipo_vinculo = 'clt'
    membership.commission_bonus_percentage = 150
    assert_not membership.valid?
  end

  test 'commission calculator computes porcentagem correctly' do
    membership = EstablishmentMembership.create!(
      establishment: @establishment,
      user: @employee_user,
      role: 'employee',
      financial_model: 'porcentagem',
      financial_value: 40,
      tipo_vinculo: 'autonomo'
    )

    apt = Appointment.create!(
      establishment: @establishment,
      employee: @employee_user,
      customer: @customer,
      service: @service,
      appointment_date: Date.current,
      start_time: '10:00',
      end_time: '10:45',
      price_snapshot: 100.00,
      status: 'completed'
    )

    commission = Financial::CommissionCalculator.call(apt)
    assert_not_nil commission
    assert_equal 40.00, commission.amount.to_f
    assert_equal 'pending', commission.status
  end

  test 'commission calculator computes fixo_servico with bonus percentage' do
    membership = EstablishmentMembership.create!(
      establishment: @establishment,
      user: @employee_user,
      role: 'employee',
      financial_model: 'fixo_servico',
      financial_value: 30.00,
      commission_bonus_percentage: 10.00,
      tipo_vinculo: 'mei'
    )

    apt = Appointment.create!(
      establishment: @establishment,
      employee: @employee_user,
      customer: @customer,
      service: @service,
      appointment_date: Date.current,
      start_time: '11:00',
      end_time: '11:45',
      price_snapshot: 200.00,
      status: 'completed'
    )

    # 30 fixo + 10% de 200 (20) = 50.00
    commission = Financial::CommissionCalculator.call(apt)
    assert_not_nil commission
    assert_equal 50.00, commission.amount.to_f
  end

  test 'commission calculator computes diaria with bonus percentage' do
    membership = EstablishmentMembership.create!(
      establishment: @establishment,
      user: @employee_user,
      role: 'employee',
      financial_model: 'diaria',
      financial_value: 120.00,
      commission_bonus_percentage: 20.00,
      tipo_vinculo: 'parceiro'
    )

    apt = Appointment.create!(
      establishment: @establishment,
      employee: @employee_user,
      customer: @customer,
      service: @service,
      appointment_date: Date.current,
      start_time: '14:00',
      end_time: '14:45',
      price_snapshot: 150.00,
      status: 'completed'
    )

    # diaria = 0 comissão base + 20% de 150 (30) = 30.00
    commission = Financial::CommissionCalculator.call(apt)
    assert_not_nil commission
    assert_equal 30.00, commission.amount.to_f
  end

  test 'commission closing service and reopen service flow' do
    membership = EstablishmentMembership.create!(
      establishment: @establishment,
      user: @employee_user,
      role: 'employee',
      financial_model: 'porcentagem',
      financial_value: 50,
      tipo_vinculo: 'clt'
    )

    apt1 = Appointment.create!(
      establishment: @establishment,
      employee: @employee_user,
      customer: @customer,
      service: @service,
      appointment_date: Date.current,
      start_time: '15:00',
      end_time: '15:45',
      price_snapshot: 100.00,
      status: 'completed'
    )

    apt2 = Appointment.create!(
      establishment: @establishment,
      employee: @employee_user,
      customer: @customer,
      service: @service,
      appointment_date: Date.current,
      start_time: '16:00',
      end_time: '16:45',
      price_snapshot: 80.00,
      status: 'completed'
    )

    com1 = Financial::CommissionCalculator.call(apt1)
    com2 = Financial::CommissionCalculator.call(apt2)

    ref_month = Date.current.strftime('%Y-%m')

    # Executa o Fechamento
    result = Financial::CommissionClosingService.new(
      establishment: @establishment,
      user: @owner,
      params: {
        employee_id: @employee_user.id,
        reference_month: ref_month,
        period_start: Date.current.beginning_of_month.to_s,
        period_end: Date.current.end_of_month.to_s,
        notes: 'Fechamento aprovado pelo gestor'
      }
    ).call

    closing = result[:closing]
    assert_not_nil closing
    assert_equal 'closed', closing.status
    assert_equal 2, closing.services_count
    assert_equal 180.00, closing.gross_revenue.to_f
    assert_equal 90.00, closing.gross_commission_amount.to_f # 50% de 180
    assert_equal 2, closing.commission_closing_items.count

    # Comissões foram marcadas como closed
    assert_equal 'closed', com1.reload.status
    assert_equal 'closed', com2.reload.status
    assert_equal closing.id, com1.commission_closing_id

    # Histórico registrado
    assert_equal 1, closing.commission_closing_histories.count
    assert_equal 'closed', closing.commission_closing_histories.first.action

    # Não permite fechar novamente o mesmo mês
    assert_raises(StandardError) do
      Financial::CommissionClosingService.new(
        establishment: @establishment,
        user: @owner,
        params: {
          employee_id: @employee_user.id,
          reference_month: ref_month
        }
      ).call
    end

    # Teste de Reabertura
    reopen_result = Financial::CommissionClosingReopenService.new(
      establishment: @establishment,
      user: @owner,
      closing_id: closing.id,
      reason: 'Ajuste de agendamento que faltou lançar'
    ).call

    reopened_closing = reopen_result[:closing]
    assert_equal 'reopened', reopened_closing.status

    # Comissões voltaram para pending
    assert_equal 'pending', com1.reload.status
    assert_nil com1.commission_closing_id
    assert_equal 'pending', com2.reload.status

    # Histórico de reabertura registrado
    assert_equal 2, reopened_closing.commission_closing_histories.count
    assert_equal 'reopened', reopened_closing.commission_closing_histories.last.action
  end

  test 'pay action does not exist on Financial::CommissionsController' do
    assert_not Financial::CommissionsController.action_methods.include?('pay')
  end
end
