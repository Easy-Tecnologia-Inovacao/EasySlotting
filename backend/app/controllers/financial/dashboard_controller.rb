module Financial
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    before_action :set_establishment
    before_action :require_financial_access!

    def index
      date_from = params[:start_date].presence || params[:date_from].presence
      date_to   = params[:end_date].presence   || params[:date_to].presence

      date_range = if date_from.present? && date_to.present?
                     begin
                       d_from = Date.parse(date_from)
                       d_to   = Date.parse(date_to)

                       if d_from > d_to
                         render json: { error: 'Data inicial não pode ser posterior à data final.' },
                                status: :unprocessable_entity and return
                       end

                       d_from..d_to
                     rescue ArgumentError
                       render json: { error: 'Formato de data inválido. Use YYYY-MM-DD.' },
                              status: :unprocessable_entity and return
                     end
                   end

      # ── Sanitização de employee_id (IDOR): valida que pertence ao estabelecimento ──
      safe_params = params.permit(:start_date, :end_date, :date_from, :date_to, :period, :reference_month)
      if params[:employee_id].present?
        employee_id = params[:employee_id].to_i
        member_exists = @establishment.establishment_memberships
                                      .exists?(user_id: employee_id, active: true)
        safe_params = safe_params.merge(employee_id: employee_id) if member_exists
      end

      transactions      = @establishment.financial_transactions
      commissions_table = @establishment.commissions

      if date_range
        transactions      = transactions.where(occurred_on: date_range)
        commissions_table = commissions_table.where(
          created_at: date_range.first.beginning_of_day..date_range.last.end_of_day
        )
      end

      gross_revenue      = transactions.where(kind: 'income',  status: 'paid').sum(:amount)
      expenses           = transactions.where(kind: 'expense', status: 'paid').sum(:amount)
      pending_commissions = commissions_table.where(status: 'pending').sum(:amount)
      paid_commissions    = commissions_table.where(status: 'paid').sum(:amount)

      # Caso receita das transações manuais seja 0, calcula com base nos agendamentos concluídos
      if gross_revenue == 0
        apts = @establishment.appointments.where(status: 'completed')
        apts = apts.where(appointment_date: date_range) if date_range
        gross_revenue = apts.sum(:price_snapshot)
      end

      # Caso comissões pagas/pendentes na tabela estejam 0, calcula com base nas regras ativas da equipe
      if pending_commissions == 0 && paid_commissions == 0
        report = Financial::CommissionReport.new(establishment: @establishment, params: safe_params).call
        pending_commissions = report.dig(:summary, :comissao_total) || 0
      end

      net_revenue = gross_revenue.to_f - expenses.to_f - paid_commissions.to_f

      render json: {
        summary: {
          gross_revenue:       gross_revenue.to_f,
          expenses:            expenses.to_f,
          net_revenue:         net_revenue.to_f,
          pending_commissions: pending_commissions.to_f,
          paid_commissions:    paid_commissions.to_f
        }
      }, status: :ok
    end
  end
end