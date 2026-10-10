class Appointment < ApplicationRecord
  # customer agora é um Customer (tabela própria, isolado por estabelecimento)
  belongs_to :customer, class_name: 'Customer'
  belongs_to :employee, class_name: 'User'
  belongs_to :establishment
  belongs_to :service
  belongs_to :service_package, class_name: 'ServicePackage', optional: true

  has_one :commission, dependent: :destroy
  has_many :financial_transactions, dependent: :nullify
  has_many :service_package_usages, dependent: :nullify
  has_one  :appointment_feedback,   dependent: :destroy

  STATUSES = %w[pending confirmed completed canceled].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :appointment_date, :start_time, :end_time, presence: true
  validates :customer, :employee, :establishment, :service, presence: true

  before_validation :sanitize_data
  before_validation :fill_snapshots
  validate -> { PlanQuotaPolicy.validate(self, :appointments) }

  after_commit :send_booking_notifications, on: :create
  after_save :send_reschedule_notifications, if: :saved_change_to_appointment_date?

  validates :notes, length: { maximum: 500 }, allow_blank: true
  validates :cancellation_reason, length: { maximum: 250 }, allow_blank: true

  scope :active_for_schedule, -> { where.not(status: 'canceled') }
  scope :for_date, ->(date) { where(appointment_date: date) }
  scope :for_employee, ->(employee_id) { where(employee_id: employee_id) }

  # =======================================================
  # PROCESSOS AUTOMATIZADOS (BACKGROUND / LAZY EVALUATION)
  # =======================================================

  # Cancela automaticamente agendamentos de dias passados onde o cliente não compareceu (no-show)
  def self.auto_cancel_no_shows!(establishment_id = nil)
    # Busca agendamentos de ontem ou antes que ainda estão pendentes/confirmados (não foram concluídos)
    query = where("appointment_date < ?", Time.current.to_date)
            .where(status: %w[pending confirmed])
            
    query = query.where(establishment_id: establishment_id) if establishment_id.present?
    
    query.find_each do |appt|
      ActiveRecord::Base.transaction do
        appt.update!(
          status: 'canceled', 
          canceled_at: Time.current,
          cancellation_reason: 'Cancelado automaticamente por falta de comparecimento.'
        )

        # Envia email de cancelamento por no-show para o cliente
        if appt.customer&.email.present?
          CancellationMailer.no_show_customer(appt).deliver_later
        end
        
        # Se for um pacote e o cliente faltou na PRIMEIRA sessão (quando ocorreria o pagamento)
        if appt.service_package_id.present?
          # Buscar a venda ativa desse pacote para esse cliente
          sale = ServicePackageSale.find_by(
            service_package_id: appt.service_package_id, 
            customer_id: appt.customer_id, 
            status: 'active'
          )
          
          # Se a venda existe e ela não tem NENHUM uso concluído, cancela a venda inteira
          if sale && sale.service_package_usages.count == 0
            sale.update!(
              status: 'canceled',
              cancellation_reason: 'Cancelado automaticamente por falta de comparecimento na primeira sessão.'
            )
            # Cancela também outros agendamentos pendentes amarrados a esse pacote (se houver)
            Appointment.where(
              customer_id: sale.customer_id,
              service_package_id: sale.service_package_id,
               status: %w[pending confirmed]
            ).update_all(status: 'canceled', canceled_at: Time.current)

            # Email de cancelamento do pacote
            if sale.customer&.email.present?
              CancellationMailer.no_show_package(sale, appt.customer).deliver_later
            end
          end
        end

        AuditLogger.log(
          action: 'auto_cancel_no_show',
          user: appt.customer,
          establishment: appt.establishment,
          details: {
            event: 'auto_cancel_no_show',
            appointment_id: appt.id,
            service_name: appt.service&.name,
            appointment_date: appt.appointment_date,
            start_time: appt.start_time
          }
        )
      end
    end
  end

  # TODO: Esquematizado para a futura funcionalidade de confirmação por email
  # O sistema enviará um email 1 hora antes; se não confirmar, cancela automático.
  # def self.auto_cancel_unconfirmed!(establishment_id = nil)
  #   # 1. Encontrar o fuso horário correto do estabelecimento
  #   # 2. Buscar agendamentos do dia atual onde (horário de início - 1 hora) já passou
  #   # 3. E que o status continue sendo 'pending' (significando que não clicou em "Confirmar" no email)
  #   # 4. Alterar o status para 'canceled' e enviar notificação de cancelamento.
  # end

  def cycle_appointments
    return Appointment.none if service_package_id.blank?

    sale = nil
    # Se já tem uso registrado (completado)
    usage = service_package_usages.first
    if usage.present?
      sale = usage.service_package_sale
    else
      # Caso contrário, pega o plano ativo para este pacote
      sale = ServicePackageSale.where(
        customer_id: customer_id,
        service_package_id: service_package_id,
        status: 'active'
      ).order(created_at: :asc).first
    end

    # Se ainda assim não achou, pega o mais recente como fallback
    if sale.blank?
      sale = ServicePackageSale.where(
        customer_id: customer_id,
        service_package_id: service_package_id
      ).order(created_at: :desc).first
    end

    return Appointment.none if sale.blank?

    # Agendamentos concluídos deste ciclo
    completed_ids = ServicePackageUsage.where(service_package_sale_id: sale.id).pluck(:appointment_id)
    
    # Agendamentos pendentes/confirmados deste ciclo para o cliente e pacote
    active_ids = Appointment.where(
      customer_id: customer_id,
      service_package_id: service_package_id,
      status: ['pending', 'confirmed']
    ).pluck(:id)

    Appointment.where(id: completed_ids + active_ids)
  end

  private

  def sanitize_data
    self.notes = ActionView::Base.full_sanitizer.sanitize(notes).to_s.strip if notes.present?
    self.cancellation_reason = ActionView::Base.full_sanitizer.sanitize(cancellation_reason).to_s.strip if cancellation_reason.present?
  end

  def fill_snapshots
    self.customer_name_snapshot = customer&.name if has_attribute?(:customer_name_snapshot) && customer_name_snapshot.blank?
    self.service_name_snapshot = service&.name if has_attribute?(:service_name_snapshot) && service_name_snapshot.blank?
    self.price_snapshot = service&.price if has_attribute?(:price_snapshot) && price_snapshot.blank?
    self.employee_name_snapshot = employee&.name if has_attribute?(:employee_name_snapshot) && employee_name_snapshot.blank?
    self.duration_minutes = service&.duration_minutes if has_attribute?(:duration_minutes) && duration_minutes.blank?
  end

  def send_booking_notifications
    formatted_date = appointment_date.strftime('%d/%m/%Y')
    cust_name = customer_name_snapshot.presence || customer&.name
    serv_name = service_name_snapshot.presence || service&.name
    emp_name = employee_name_snapshot.presence || employee&.name

    # 1. Notificação para o Funcionário
    if employee_id.present?
      Notification.create!(
        user_id: employee_id,
        establishment_id: establishment_id,
        title: '📅 Novo Agendamento!',
        content: "O cliente #{cust_name} agendou o serviço #{serv_name} para o dia #{formatted_date} às #{start_time}."
      )
    end

    # 2. Notificação para o Proprietário (Dono do Estabelecimento)
    owner_id = establishment.owner_id
    if owner_id.present? && owner_id != employee_id
      Notification.create!(
        user_id: owner_id,
        establishment_id: establishment_id,
        title: '📅 Novo Agendamento!',
        content: "Um novo agendamento foi realizado: #{cust_name} agendou #{serv_name} com o profissional #{emp_name} para o dia #{formatted_date} às #{start_time}."
      )
    end

    # 3. Disparar E-mail para o Cliente
    # Para pacotes: envia email apenas na primeira sessão (evita spam de múltiplos emails)
    send_customer_email = if service_package_id.present?
      # dentro da mesma transação, todos os appointments já foram salvos
      # então pegamos o de menor ID como o "primeiro"
      first_id = Appointment.where(
        customer_id: customer_id,
        service_package_id: service_package_id
      ).where.not(status: 'canceled').minimum(:id)
      id == first_id
    else
      true
    end

    if send_customer_email && customer&.email.present? && !customer.email.include?('@easysloting.internal')
      AppointmentMailer.customer_notification(self).deliver_now
    end

    # 4. Disparar E-mail para o Funcionário (se e-mail for real e válido)
    if employee&.email.present? && !employee.email.include?('@easysloting.internal')
      AppointmentMailer.employee_notification(self).deliver_now
    end

    # 5. Disparar E-mail para o Proprietário (se e-mail for real e válido)
    owner_email = establishment.owner&.email
    if owner_email.present? && !owner_email.include?('@easysloting.internal')
      AppointmentMailer.owner_notification(self).deliver_now
    end
  end

  def send_reschedule_notifications
    return if status == 'canceled'

    old_date = appointment_date_before_last_save
    new_date = appointment_date
    return if old_date.blank? || new_date.blank? || old_date == new_date

    old_time = saved_changes['start_time']&.first
    old_time_str = old_time.respond_to?(:strftime) ? old_time.strftime('%H:%M') : old_time.to_s[0, 5] rescue nil

    # Email para o Cliente
    if customer&.email.present? && !customer.email.include?('@easysloting.internal')
      AppointmentMailer.customer_reschedule_notification(self, old_date, old_time_str).deliver_now
    end

    # Email para o Funcionário
    if employee&.email.present? && !employee.email.include?('@easysloting.internal')
      AppointmentMailer.employee_reschedule_notification(self, old_date, old_time_str).deliver_now
    end

    # Email para o Proprietário
    owner_email = establishment.owner&.email
    if owner_email.present? && !owner_email.include?('@easysloting.internal')
      AppointmentMailer.owner_reschedule_notification(self, old_date, old_time_str).deliver_now
    end
  end
end
