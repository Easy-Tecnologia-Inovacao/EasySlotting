module Financial
  class CommissionReport
    def initialize(establishment:, params:)
      @establishment = establishment
      @params = params
    end

    def call
      range = period_range
      ref_month = reference_month_from_range(range)

      memberships = filtered_memberships
      appointments = filtered_appointments(range)

      # Busca fechamentos existentes no período/mês
      existing_closings = @establishment.commission_closings
                                       .where(reference_month: ref_month)
                                       .to_a

      professionals = memberships.map do |membership|
        employee = membership.user
        employee_appointments = appointments.select { |a| a.employee_id == employee.id }

        atendimentos = employee_appointments.count
        producao = employee_appointments.sum { |a| a.price_snapshot.to_d }
        comissao = calculate_commission(membership, atendimentos, producao)

        # Checa status de fechamento
        closing = existing_closings.find { |c| c.employee_id == employee.id }
        fechamento_status = closing&.status || (comissao > 0 ? 'aguardando' : 'sem_movimento')

        # Comissões pendentes
        pending_commissions_count = Commission.where(
          establishment_id: @establishment.id,
          employee_id: employee.id,
          status: 'pending'
        ).joins(:appointment).where(appointments: { appointment_date: range }).count

        {
          id: employee.id,
          nome: employee.name,
          especialidade: membership.specialty.presence || 'Sem especialidade',
          tipo_vinculo: membership.tipo_vinculo || 'autonomo',
          financial_model: membership.financial_model,
          financial_value: membership.financial_value.to_d.to_f,
          commission_bonus_percentage: membership.commission_bonus_percentage.to_d.to_f,
          atendimentos: atendimentos,
          producao: producao.to_f,
          comissao: comissao.to_f,
          tem_regra: membership.financial_model.present? && membership.financial_value.present?,
          fechamento_status: fechamento_status,
          closing_id: closing&.id,
          pending_count: pending_commissions_count
        }
      end

      ordered = professionals.sort_by { |prof| -prof[:producao] }

      # Fechamentos concluídos para a aba "Fechados"
      closings_scope = @establishment.commission_closings
                                     .includes(:employee, :closed_by)
                                     .where(reference_month: ref_month)
                                     .recent_first

      closings_scope = closings_scope.where(employee_id: @params[:employee_id]) if @params[:employee_id].present?

      closed_list = closings_scope.map do |c|
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

      # Aguardando Fechamento: profissionais com produção/comissão e sem fechamento concluído
      aguardando_list = ordered.select do |p|
        p[:tem_regra] && p[:comissao] > 0 && p[:fechamento_status] != 'closed'
      end

      {
        summary: {
          comissao_total: ordered.sum { |prof| prof[:comissao] },
          producao_total: ordered.sum { |prof| prof[:producao] },
          atendimentos_total: ordered.sum { |prof| prof[:atendimentos] },
          profissionais_sem_regra: ordered.count { |prof| !prof[:tem_regra] },
          aguardando_fechamento_total: aguardando_list.size,
          fechados_total: closed_list.count { |c| c[:status] == 'closed' }
        },
        reference_month: ref_month,
        period_start: range.begin.strftime('%d/%m/%Y'),
        period_end: range.end.strftime('%d/%m/%Y'),
        top_professional: ordered.first,
        professionals: ordered,
        aguardando_fechamento: aguardando_list,
        closed_closings: closed_list
      }
    end

    private

    def filtered_memberships
      scope = @establishment.establishment_memberships
                            .includes(:user)
                            .where(role: 'employee', active: true)

      scope = scope.where(user_id: @params[:employee_id]) if @params[:employee_id].present?
      scope
    end

    def filtered_appointments(range)
      scope = Appointment.where(
        establishment_id: @establishment.id,
        status: 'completed',
        appointment_date: range
      )

      scope = scope.where(employee_id: @params[:employee_id]) if @params[:employee_id].present?
      scope.to_a
    end

    def calculate_commission(membership, atendimentos, producao)
      return 0.to_d if membership.financial_model.blank? || membership.financial_value.blank?

      val = membership.financial_value.to_d
      bonus = membership.commission_bonus_percentage.to_d

      base = case membership.financial_model
             when 'porcentagem'
               producao * val / 100
             when 'fixo_servico'
               atendimentos * val
             when 'diaria'
               0.to_d
             else
               0.to_d
             end

      if membership.financial_model != 'porcentagem' && bonus > 0
        base += producao * bonus / 100
      end

      base.round(2)
    end

    def period_range
      if @params[:date_from].present? && @params[:date_to].present?
        begin
          d_from = Date.parse(@params[:date_from])
          d_to   = Date.parse(@params[:date_to])
          # Intervalo invertido → retorna mês atual como fallback seguro
          return d_from <= d_to ? d_from..d_to : Date.current.beginning_of_month..Date.current.end_of_month
        rescue ArgumentError
          return Date.current.beginning_of_month..Date.current.end_of_month
        end
      end

      case @params[:period]
      when 'hoje'
        Date.current..Date.current
      when '7dias'
        6.days.ago.to_date..Date.current
      when '30dias'
        29.days.ago.to_date..Date.current
      when '6meses'
        6.months.ago.to_date..Date.current
      when '1ano'
        1.year.ago.to_date..Date.current
      else
        Date.current.beginning_of_month..Date.current.end_of_month
      end
    rescue ArgumentError
      Date.current.beginning_of_month..Date.current.end_of_month
    end

    def reference_month_from_range(range)
      if @params[:reference_month].present?
        @params[:reference_month]
      else
        range.end.strftime('%Y-%m')
      end
    end
  end
end