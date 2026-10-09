module Financial
  class CommissionClosingService
    def initialize(establishment:, user:, params:)
      @establishment = establishment
      @user = user
      @params = params
    end

    def call
      employee_id = @params[:employee_id]
      raise 'Profissional não informado.' if employee_id.blank?

      @employee = User.find_by(id: employee_id)
      raise 'Profissional não encontrado.' if @employee.blank?

      membership = EstablishmentMembership.find_by(
        establishment_id: @establishment.id,
        user_id: @employee.id,
        active: true
      ) || EstablishmentMembership.find_by(
        establishment_id: @establishment.id,
        user_id: @employee.id
      )
      raise 'Profissional não pertence a este estabelecimento.' if membership.blank?

      ref_month = @params[:reference_month].presence || Date.current.strftime('%Y-%m')
      start_d = parse_date(@params[:period_start]) || Date.parse("#{ref_month}-01")
      end_d = parse_date(@params[:period_end]) || start_d.end_of_month

      existing = CommissionClosing.find_by(
        establishment_id: @establishment.id,
        employee_id: @employee.id,
        reference_month: ref_month
      )

      if existing.present? && existing.closed?
        raise "Já existe um fechamento concluído para #{@employee.name} referente a #{ref_month}."
      end

      # Assegura que atendimentos concluídos no período geraram comissão se ainda não tinham
      ensure_commissions_calculated(start_d, end_d)

      # Busca comissões pendentes no período
      commissions_scope = Commission.where(
        establishment_id: @establishment.id,
        employee_id: @employee.id,
        status: 'pending'
      ).joins(:appointment).where(
        appointments: { appointment_date: start_d..end_d }
      )

      commissions = commissions_scope.to_a
      if commissions.empty?
        raise "Nenhuma comissão pendente encontrada para #{@employee.name} no período selecionado (#{start_d.strftime('%d/%m/%Y')} a #{end_d.strftime('%d/%m/%Y')})."
      end

      rule_applied_desc = build_rule_description(membership)
      services_count = commissions.size
      gross_revenue = commissions.sum { |c| c.calculated_from_amount.to_d }.round(2)
      gross_commission = commissions.sum { |c| c.amount.to_d }.round(2)

      closing = nil

      ActiveRecord::Base.transaction do
        # Lock commissions to avoid race conditions
        commissions = Commission.where(id: commissions.map(&:id)).lock('FOR UPDATE').to_a

        if commissions.any? { |c| c.status != 'pending' }
          raise 'Uma ou mais comissões já foram fechadas em outro processo.'
        end

        closing = existing || CommissionClosing.new(
          establishment: @establishment,
          employee: @employee
        )

        closing.assign_attributes(
          membership: membership,
          reference_month: ref_month,
          period_start: start_d,
          period_end: end_d,
          services_count: services_count,
          gross_revenue: gross_revenue,
          financial_model_snapshot: membership&.financial_model,
          financial_value_snapshot: membership&.financial_value,
          commission_bonus_snapshot: membership&.commission_bonus_percentage,
          gross_commission_amount: gross_commission,
          status: 'closed',
          closed_at: Time.current,
          closed_by: @user,
          notes: ActionController::Base.helpers.sanitize(@params[:notes].to_s.strip, tags: []).truncate(500).presence
        )
        closing.save!

        # Limpar itens anteriores caso estivesse reaberto
        closing.commission_closing_items.destroy_all

        commissions.each do |commission|
          closing.commission_closing_items.create!(
            commission: commission,
            appointment: commission.appointment,
            service_amount: commission.calculated_from_amount,
            commission_rule_applied: rule_applied_desc,
            commission_amount: commission.amount
          )

          commission.update!(
            status: 'closed',
            commission_closing_id: closing.id
          )
        end

        closing.commission_closing_histories.create!(
          user: @user,
          action: 'closed',
          description: "Fechamento de comissão concluído para #{@employee.name} referente a #{ref_month} (#{services_count} serviços, Total Bruto: R$ #{gross_commission}).",
          changes_snapshot: {
            status: { from: 'open', to: 'closed' },
            gross_commission_amount: gross_commission.to_f,
            services_count: services_count
          }
        )

        AuditLog.create!(
          user: @user,
          establishment: @establishment,
          action: 'close_commission',
          auditable: closing,
          details: {
            employee_id: @employee.id,
            employee_name: @employee.name,
            reference_month: ref_month,
            gross_commission_amount: gross_commission.to_f,
            services_count: services_count
          }
        )
      end

      {
        message: 'Fechamento de comissão realizado com sucesso.',
        closing: closing
      }
    end

    private

    def ensure_commissions_calculated(start_d, end_d)
      appointments = Appointment.where(
        establishment_id: @establishment.id,
        employee_id: @employee.id,
        status: 'completed',
        appointment_date: start_d..end_d
      ).left_joins(:commission).where(commissions: { id: nil })

      appointments.find_each do |appointment|
        CommissionCalculator.call(appointment)
      end
    end

    def parse_date(value)
      return nil if value.blank?
      Date.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def build_rule_description(membership)
      return 'Sem regra configurada' if membership.blank? || membership.financial_model.blank?

      bonus = membership.commission_bonus_percentage.to_d
      case membership.financial_model
      when 'porcentagem'
        "#{membership.financial_value}% sobre faturamento"
      when 'fixo_servico'
        desc = "R$ #{membership.financial_value} fixo por atendimento"
        desc += " + #{bonus}% bônus" if bonus > 0
        desc
      when 'diaria'
        desc = "Diária R$ #{membership.financial_value}"
        desc += " + #{bonus}% bônus comissão" if bonus > 0
        desc
      else
        membership.financial_model.to_s
      end
    end
  end
end
