# Quotas por estabelecimento, verificadas no save sob lock transacional comum.
# null = ilimitado; zero = nenhuma nova vaga. Não remove dados em downgrade.
class PlanQuotaPolicy
  def self.validate(record, kind)
    return unless record.establishment_id

    increasing = case kind
    when :services
      record.deleted_at.nil? && (record.new_record? || record.will_save_change_to_establishment_id? || record.will_save_change_to_deleted_at?)
    when :employees
      record.active? && record.role == 'employee' && (record.new_record? || record.will_save_change_to_active? || record.will_save_change_to_role? || record.will_save_change_to_establishment_id?)
    when :appointments
      record.status != 'canceled' && record.appointment_date.present? && (record.new_record? || record.will_save_change_to_establishment_id? || record.will_save_change_to_appointment_date? || (record.will_save_change_to_status? && record.status_in_database == 'canceled'))
    end
    return unless increasing

    key = Digest::SHA256.hexdigest("plan-quota:#{record.establishment_id}")[0, 15].to_i(16)
    record.class.connection.execute("SELECT pg_advisory_xact_lock(#{key})")
    plan = Subscription.where(establishment_id: record.establishment_id).current_for_use&.plan
    return unless plan

    scope, limit, label = case kind
    when :services
      [Service.where(establishment_id: record.establishment_id), plan.max_services, 'serviços cadastrados']
    when :employees
      [EstablishmentMembership.where(establishment_id: record.establishment_id, active: true, role: 'employee'), plan.max_employees, 'funcionários ativos']
    when :appointments
      first = record.appointment_date.beginning_of_month
      [Appointment.where(establishment_id: record.establishment_id, appointment_date: first...first.next_month).where.not(status: 'canceled'), plan.max_appointments_per_month, 'agendamentos no mês selecionado']
    end
    return if limit.nil?
    if scope.where.not(id: record.id).count >= limit
      record.errors.add(:base, "O plano permite até #{limit} #{label}. Libere uma vaga ou altere o plano.")
    end
  end
end
