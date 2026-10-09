module Financial
  class CommissionClosingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_establishment
    before_action :require_financial_access!

    def index
      closings = @establishment.commission_closings
                               .includes(:employee, :closed_by, :membership)
                               .recent_first

      closings = closings.for_month(params[:reference_month]) if params[:reference_month].present?
      closings = closings.for_employee(params[:employee_id]) if params[:employee_id].present?
      closings = closings.for_status(params[:status]) if params[:status].present?

      render json: closings.map { |c| serialize_closing_summary(c) }, status: :ok
    end

    def show
      closing = @establishment.commission_closings
                              .includes(:employee, :closed_by, :membership,
                                        commission_closing_items: [:appointment, :commission],
                                        commission_closing_histories: [:user])
                              .find(params[:id])

      render json: serialize_closing_detail(closing), status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Fechamento não encontrado.' }, status: :not_found
    end

    def preview
      employee_id = params[:employee_id]
      membership = @establishment.establishment_memberships
                                 .where(active: true)
                                 .find_by(user_id: employee_id)
      return render json: { error: 'Profissional não encontrado ou não vinculado ao estabelecimento' }, status: :not_found unless membership

      employee = membership.user
      return render json: { error: 'Profissional não encontrado' }, status: :not_found unless employee

      start_d = parse_date(params[:date_from]) || Date.current.beginning_of_month
      end_d = parse_date(params[:date_to]) || Date.current.end_of_month

      # Gera comissões pendentes para agendamentos concluídos que ainda não possuem
      Appointment.where(
        establishment_id: @establishment.id,
        employee_id: employee.id,
        status: 'completed',
        appointment_date: start_d..end_d
      ).left_joins(:commission).where(commissions: { id: nil }).find_each do |apt|
        CommissionCalculator.call(apt)
      end

      commissions = Commission.where(
        establishment_id: @establishment.id,
        employee_id: employee.id,
        status: 'pending'
      ).joins(:appointment).where(
        appointments: { appointment_date: start_d..end_d }
      ).includes(:appointment).order('appointments.appointment_date ASC, appointments.start_time ASC')

      # membership já foi obtido e validado no escopo do estabelecimento acima

      items = commissions.map do |c|
        apt = c.appointment
        {
          id: c.id,
          appointment_id: apt.id,
          date: apt.appointment_date.strftime('%d/%m/%Y'),
          time: apt.start_time.strftime('%H:%M'),
          service_name: apt.service_name_snapshot || 'Atendimento',
          customer_name: apt.customer_name_snapshot || 'Cliente',
          service_amount: c.calculated_from_amount.to_f,
          commission_amount: c.amount.to_f
        }
      end

      render json: {
        employee_id: employee.id,
        employee_name: employee.name,
        tipo_vinculo: membership&.tipo_vinculo || 'autonomo',
        financial_model: membership&.financial_model,
        financial_value: membership&.financial_value.to_f,
        commission_bonus_percentage: membership&.commission_bonus_percentage.to_f,
        services_count: items.size,
        gross_revenue: items.sum { |i| i[:service_amount] }.round(2),
        gross_commission: items.sum { |i| i[:commission_amount] }.round(2),
        items: items
      }, status: :ok
    end

    def create
      sanitized_notes = ActionController::Base.helpers.sanitize(
        closing_params[:notes].to_s.strip, tags: []
      ).truncate(500).presence

      result = Financial::CommissionClosingService.new(
        establishment: @establishment,
        user: current_user,
        params: closing_params.merge(notes: sanitized_notes)
      ).call

      render json: {
        message: result[:message],
        closing: serialize_closing_detail(result[:closing])
      }, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def reopen
      sanitized_reason = ActionController::Base.helpers.sanitize(
        params[:reason].to_s.strip, tags: []
      ).truncate(500).presence

      result = Financial::CommissionClosingReopenService.new(
        establishment: @establishment,
        user: current_user,
        closing_id: params[:id],
        reason: sanitized_reason
      ).call

      render json: {
        message: result[:message],
        closing: serialize_closing_detail(result[:closing])
      }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def report
      ref_month = params[:reference_month].presence || Date.current.strftime('%Y-%m')

      closings = @establishment.commission_closings
                               .includes(:employee, :closed_by, :membership, commission_closing_items: :appointment)
                               .where(reference_month: ref_month)
                               .recent_first

      disclaimer = 'Os valores apresentados correspondem aos valores brutos calculados pelo sistema com base nos serviços registrados e nas regras de comissão configuradas. O EasySloting não realiza pagamentos nem determina tributos, retenções ou encargos aplicáveis.'

      render json: {
        establishment_name: @establishment.name,
        establishment_cnpj: @establishment.cnpj_masked,
        reference_month: ref_month,
        generated_at: Time.current.strftime('%d/%m/%Y %H:%M'),
        generated_by: current_user.name,
        disclaimer: disclaimer,
        closings_count: closings.size,
        total_gross_commission: closings.sum(&:gross_commission_amount).to_f,
        total_gross_revenue: closings.sum(&:gross_revenue).to_f,
        total_services: closings.sum(&:services_count),
        closings: closings.map { |c| serialize_closing_detail(c) }
      }, status: :ok
    end

    private

    def closing_params
      params.require(:closing).permit(
        :employee_id,
        :reference_month,
        :period_start,
        :period_end,
        :notes
      )
    end

    def parse_date(value)
      return nil if value.blank?
      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def serialize_closing_summary(c)
      {
        id: c.id,
        reference_month: c.reference_month,
        period_start: c.period_start.strftime('%d/%m/%Y'),
        period_end: c.period_end.strftime('%d/%m/%Y'),
        employee_id: c.employee_id,
        employee_name: c.employee.name,
        tipo_vinculo: c.membership&.tipo_vinculo || 'autonomo',
        services_count: c.services_count,
        gross_revenue: c.gross_revenue.to_f,
        financial_model: c.financial_model_snapshot,
        financial_value: c.financial_value_snapshot.to_f,
        commission_bonus: c.commission_bonus_snapshot.to_f,
        gross_commission_amount: c.gross_commission_amount.to_f,
        status: c.status,
        closed_at: c.closed_at&.strftime('%d/%m/%Y %H:%M'),
        closed_by_name: c.closed_by&.name,
        notes: c.notes
      }
    end

    def serialize_closing_detail(c)
      data = serialize_closing_summary(c)
      data[:items] = c.commission_closing_items.map do |item|
        apt = item.appointment
        {
          id: item.id,
          appointment_id: item.appointment_id,
          date: apt&.appointment_date&.strftime('%d/%m/%Y'),
          time: apt&.start_time&.strftime('%H:%M'),
          service_name: apt&.service_name_snapshot || 'Atendimento',
          customer_name: apt&.customer_name_snapshot || 'Cliente',
          service_amount: item.service_amount.to_f,
          commission_rule_applied: item.commission_rule_applied,
          commission_amount: item.commission_amount.to_f
        }
      end

      data[:histories] = c.commission_closing_histories.order(created_at: :desc).map do |h|
        {
          id: h.id,
          action: h.action,
          description: h.description,
          user_name: h.user.name,
          created_at: h.created_at.strftime('%d/%m/%Y %H:%M'),
          changes: h.changes_snapshot
        }
      end

      data
    end
  end
end
