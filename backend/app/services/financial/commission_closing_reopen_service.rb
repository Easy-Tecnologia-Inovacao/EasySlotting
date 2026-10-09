module Financial
  class CommissionClosingReopenService
    def initialize(establishment:, user:, closing_id:, reason:)
      @establishment = establishment
      @user = user
      @closing_id = closing_id
      @reason = reason.to_s.strip
    end

    def call
      raise 'Motivo da reabertura é obrigatório.' if @reason.blank?
      raise 'Motivo deve ter no mínimo 5 caracteres.' if @reason.length < 5

      closing = @establishment.commission_closings.find_by(id: @closing_id)
      raise 'Fechamento não encontrado.' if closing.blank?

      unless closing.closed?
        raise 'Apenas fechamentos concluídos podem ser reabertos.'
      end

      ActiveRecord::Base.transaction do
        # Reabrir comissões vinculadas
        commissions = Commission.where(commission_closing_id: closing.id)
        commissions.update_all(
          status: 'pending',
          commission_closing_id: nil,
          updated_at: Time.current
        )

        closing.update!(
          status: 'reopened',
          closed_at: nil,
          notes: [closing.notes, "[Reaberto em #{Time.current.strftime('%d/%m/%Y %H:%M')}] Motivo: #{@reason}"].compact.reject(&:blank?).join("\n")
        )

        closing.commission_closing_histories.create!(
          user: @user,
          action: 'reopened',
          description: "Fechamento reaberto. Motivo: #{@reason}",
          changes_snapshot: {
            status: { from: 'closed', to: 'reopened' },
            reason: @reason
          }
        )

        AuditLog.create!(
          user: @user,
          establishment: @establishment,
          action: 'reopen_commission_closing',
          auditable: closing,
          details: {
            reason: @reason,
            employee_id: closing.employee_id,
            employee_name: closing.employee.name,
            reference_month: closing.reference_month
          }
        )
      end

      {
        message: 'Fechamento reaberto com sucesso. As comissões voltaram para aguardando fechamento.',
        closing: closing.reload
      }
    end
  end
end
