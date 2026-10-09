# app/controllers/customer/appointments_controller.rb
# Controller para agendamentos do cliente logado via JWT.
# Migrado de Devise (authenticate_user! / current_user) para
# autenticação própria de customers (authenticate_customer! / current_customer).

class Customer::AppointmentsController < ApplicationController
  before_action :authenticate_customer!

  RATE_LIMIT_WINDOW = 1.hour
  MAX_CANCELS_PER_WINDOW = 10
  MAX_RESCHEDULES_PER_WINDOW = 15

  # GET /api/customer/appointments
  # Lista todos os agendamentos (exceto cancelados) do customer
  def index
    AutoCancelNoShowsJob.perform_later

    appointments = current_customer.appointments
                                   .includes(:service, :employee, :establishment, :appointment_feedback)
                                   .where(service_package_id: nil)
                                   .where(status: %w[pending confirmed])
                                   .order(appointment_date: :desc, start_time: :desc)

    render json: appointments.map { |a| serialize_appointment(a) }
  end

  # GET /api/customer/appointments/history
  # Retorna apenas agendamentos concluídos (para a página Histórico)
  def history
    AutoCancelNoShowsJob.perform_later

    appointments = current_customer.appointments
                                   .includes(:service, :employee, :establishment, :appointment_feedback)
                                   .where(status: 'completed')
                                   .order(appointment_date: :desc, start_time: :desc)

    render json: appointments.map { |a| serialize_appointment(a) }
  end

  # POST /api/customer/appointments
  def create
    base_params = params[:appointment].presence || params
    appointments_data = params[:appointments].present? ? params[:appointments] : [base_params]
    
    is_package = base_params[:service_package_id].present?
    service = Service.find_by!(id: base_params[:service_id], establishment_id: current_customer.establishment_id)
    establishment = current_customer.establishment

    package = nil
    sessions_total = 1

    if is_package
      package = ServicePackage.find_by!(id: base_params[:service_package_id], establishment_id: establishment.id)
      sessions_total = [package.sessions_total.to_i, 1].max

      is_new_purchase = params[:appointments].present?
      validate_service_package_creation!(package, is_new_purchase, sessions_total)
      return if performed?
    end

    appointments_to_save = []
    
    today_in_tz = Time.current.in_time_zone(establishment.timezone.presence || 'America/Sao_Paulo').to_date
    now_minutes = current_minutes_in_establishment_timezone(establishment)

    appointments_data.each do |appt_data|
      appointment = Appointment.new(
        service_id: service.id,
        employee_id: base_params[:employee_id],
        appointment_date: appt_data[:appointment_date],
        start_time: appt_data[:start_time],
        service_package_id: package&.id,
        establishment_id: establishment.id,
        customer_id: current_customer.id,
        status: 'pending'
      )

      appointment_date = begin
        Date.parse(appointment.appointment_date.to_s)
      rescue Date::Error
        return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
      end
      
      if appointment_date < today_in_tz
        return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
      end

      if establishment.booking_mode == 'day'
        appointment.start_time = '00:00'
        appointment.end_time   = '23:59'
        start_time_str = '00:00'
      else
        # 🔒 SEGURANÇA (F-3): Valida formato HH:MM antes de usar em cálculos
        raw_time = appt_data[:start_time].to_s.strip
        unless raw_time.match?(/\A([01]\d|2[0-3]):[0-5]\d\z/)
          return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
        end
        start_time_str     = normalize_time_string(appointment.start_time)
        start_time_minutes = hhmm_to_minutes(start_time_str)
      end

      if appointment.employee_id.to_i == 0
        found_id = find_available_employee(service, appointment.appointment_date, start_time_str)
        if found_id
          appointment.employee_id = found_id
          appointment.employee_name_snapshot = User.find(found_id).name
        else
          return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
        end
      else
        unless valid_employee_for_service?(appointment.employee_id, service.id, appointment.establishment_id)
          return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
        end
      end

      if establishment.booking_mode == 'day'
        unless EmployeeWorkingHour.exists?(user_id: appointment.employee_id, weekday: appointment_date.wday, is_available: true)
          return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
        end

        if conflict_exists?(appointment) || appointments_to_save.any? { |a| a.appointment_date == appointment.appointment_date && a.employee_id == appointment.employee_id }
          return render json: { error: 'Horário indisponível.' }, status: :unprocessable_entity
        end
      else
        if appointment_date == today_in_tz && start_time_minutes < now_minutes
          return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
        end

        available_result = Scheduling::Appointments::AvailableSlotsService.call(
          establishment_id: appointment.establishment_id,
          employee_id:      appointment.employee_id,
          service_id:       appointment.service_id,
          appointment_date: appointment.appointment_date
        )

        available_slots = available_result[:available_slots] || []

        unless available_slots.include?(start_time_str)
          return render json: { error: 'Horário indisponível.' }, status: :unprocessable_entity
        end

        duration_minutes = service.duration_minutes.to_i
        end_time_str = begin
          parsed_start_t = Time.zone.parse("2000-01-01 #{start_time_str}")
          (parsed_start_t + duration_minutes.minutes).strftime('%H:%M')
        rescue
          nil
        end
        appointment.end_time = end_time_str

        if conflict_exists?(appointment)
          return render json: { error: 'Horário indisponível.' }, status: :unprocessable_entity
        end
        
        new_start = hhmm_to_minutes(start_time_str)
        new_end   = hhmm_to_minutes(end_time_str)
        has_internal_conflict = appointments_to_save.any? do |a|
          a.appointment_date == appointment.appointment_date &&
          a.employee_id == appointment.employee_id &&
          hhmm_to_minutes(normalize_time_string(a.start_time)) < new_end &&
          hhmm_to_minutes(normalize_time_string(a.end_time)) > new_start
        end

        if has_internal_conflict
          return render json: { error: 'Horários conflitantes selecionados.' }, status: :unprocessable_entity
        end
      end
      
      appointments_to_save << appointment
    end

    if is_package
      existing_package_appointments = Appointment.where(
        customer_id: current_customer.id,
        establishment_id: establishment.id,
        service_package_id: package.id
      ).where.not(status: %w[canceled completed])
      
      existing_sundays = existing_package_appointments.map do |a|
        d = Date.parse(a.appointment_date.to_s)
        d - d.wday.days
      end
      
      new_sundays = appointments_to_save.map do |a|
        d = Date.parse(a.appointment_date.to_s)
        d - d.wday.days
      end

      if new_sundays.uniq.length != new_sundays.length
        return render json: { error: 'Você selecionou mais de uma sessão na mesma semana.' }, status: :unprocessable_entity
      end

      if (new_sundays & existing_sundays).any?
        return render json: { error: 'Você já possui uma sessão deste pacote agendada para uma das semanas escolhidas.' }, status: :unprocessable_entity
      end
    end

    ActiveRecord::Base.transaction do
      if is_package
        existing_active_sale = current_customer.service_package_sales
                                               .where(
                                                 establishment_id:    current_customer.establishment_id,
                                                 service_package_id:  package.id,
                                                 status:              'active'
                                               )
                                               .where('sessions_used < sessions_total')
                                               .order(created_at: :asc)
                                               .first

        unless existing_active_sale
          current_customer.service_package_sales.create!(
            establishment_id:   current_customer.establishment_id,
            service_package_id: package.id,
            sessions_total:     sessions_total,
            sessions_used:      0,
            total_price:        package.price,
            status:             'active',
            sold_at:            Time.current
          )
        end
      end

      appointments_to_save.each(&:save!)
    end

    # Auditoria da criação
    AuditLogger.log(
      action: 'appointment_created',
      user: current_customer,
      establishment: establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'appointment_created',
        appointment_ids: appointments_to_save.map(&:id),
        service_name: service.name,
        employee_name: User.find_by(id: base_params[:employee_id])&.name,
        dates: appointments_to_save.map { |a| a.appointment_date },
        is_package: is_package,
        package_name: package&.name
      }
    )

    render json: {
      appointment_id: appointments_to_save.first.id,
      type: is_package ? 'plan' : 'single'
    }, status: :created

  rescue StandardError => e
    Rails.logger.error("[Customer::Appointments#create] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao criar agendamento.' }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Serviço ou Pacote não encontrado.' }, status: :unprocessable_entity
  end

  # PATCH /api/customer/appointments/:id/cancel
  def cancel
    appointment = current_customer.appointments.find(params[:id])

    # Bloqueia cancelamento de agendamentos já finalizados ou cancelados
    if %w[canceled completed].include?(appointment.status)
      return render json: {
        error: "Este agendamento já está #{appointment.status == 'canceled' ? 'cancelado' : 'concluído'} e não pode ser cancelado."
      }, status: :unprocessable_entity
    end

    cancellation_reason = if params[:cancellation_reason].present?
                            ActionController::Base.helpers.sanitize(
                              params[:cancellation_reason].to_s.strip, tags: []
                            ).truncate(250).presence
                          end

    # Rate limiting
    recent_cancels = AuditLog.where(
      establishment_id: current_customer.establishment_id,
      action: 'appointment_canceled',
      created_at: RATE_LIMIT_WINDOW.ago..
    ).where(
      '(auditable_type = ? AND auditable_id = ?) OR user_id = ?',
      'Customer', current_customer.id, current_customer.id
    ).count

    if recent_cancels >= MAX_CANCELS_PER_WINDOW
      return render json: {
        error: 'Muitos cancelamentos. Aguarde antes de cancelar novamente.'
      }, status: :too_many_requests
    end

    tz          = appointment.establishment.timezone.presence || 'America/Sao_Paulo'
    today_in_tz = Time.current.in_time_zone(tz).to_date

    # Retirada a validação de data passada para permitir limpeza de histórico pelo cliente

    ActiveRecord::Base.transaction do
      appointment.update!(
        status: 'canceled',
        canceled_at: Time.current,
        cancellation_reason: cancellation_reason
      )
      
      if appointment.service_package_id.present?
        usage = ServicePackageUsage.find_by(appointment_id: appointment.id)
        if usage
          sale = usage.service_package_sale
          usage.destroy!
          sale.update!(sessions_used: [sale.sessions_used - 1, 0].max)
        end
      end
    end

    # Auditoria do cancelamento (LGPD / rastreabilidade)
    AuditLogger.log(
      action: 'appointment_canceled',
      user: current_customer,
      establishment: appointment.establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'appointment_canceled',
        appointment_id: appointment.id,
        service_name: appointment.service_name_snapshot || appointment.service&.name,
        employee_name: appointment.employee_name_snapshot || appointment.employee&.name,
        appointment_date: appointment.appointment_date,
        start_time: appointment.start_time,
        cancellation_reason: cancellation_reason,
        is_package: appointment.service_package_id.present?
      }
    )

    # Envia emails de notificação de cancelamento
    send_cancel_appointment_emails(appointment, cancellation_reason)

    render json: { success: true }
  end

  # PATCH /api/customer/appointments/:id/confirm
  def confirm
    appointment = current_customer.appointments.find(params[:id])

    if appointment.status != 'pending'
      return render json: { error: "Este agendamento não pode ser confirmado. Status atual: #{appointment.status}" }, status: :unprocessable_entity
    end

    appointment.update!(status: 'confirmed')

    AuditLogger.log(
      action: 'appointment_confirmed',
      user: current_customer,
      establishment: appointment.establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'appointment_confirmed',
        appointment_id: appointment.id,
        service_name: appointment.service_name_snapshot || appointment.service&.name,
        employee_name: appointment.employee_name_snapshot || appointment.employee&.name,
        appointment_date: appointment.appointment_date,
        start_time: appointment.start_time.respond_to?(:strftime) ? appointment.start_time.strftime('%H:%M') : appointment.start_time.to_s[0, 5]
      }
    )

    render json: { success: true, status: 'confirmed' }
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[Customer::AppointmentsController#confirm] Agendamento não encontrado: id=#{params[:id]}, customer_id=#{current_customer&.id}")
    render json: { error: 'Agendamento não encontrado.' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[Customer::AppointmentsController#confirm] Erro de validação: #{e.message}")
    render json: { error: 'Não foi possível confirmar o agendamento.' }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error("[Customer::AppointmentsController#confirm] Erro inesperado: #{e.class}: #{e.message}")
    render json: { error: 'Erro interno ao confirmar agendamento.' }, status: :internal_server_error
  end

  # PATCH /api/customer/appointments/:id/reschedule
  def reschedule
    appointment = current_customer.appointments.find(params[:id])

    if %w[canceled completed].include?(appointment.status)
      return render json: { error: 'Não é possível reagendar este agendamento.' }, status: :unprocessable_entity
    end

    # Rate limiting
    recent_reschedules = AuditLog.where(
      establishment_id: current_customer.establishment_id,
      action: 'appointment_rescheduled',
      created_at: RATE_LIMIT_WINDOW.ago..
    ).where(
      '(auditable_type = ? AND auditable_id = ?) OR user_id = ?',
      'Customer', current_customer.id, current_customer.id
    ).count

    if recent_reschedules >= MAX_RESCHEDULES_PER_WINDOW
      return render json: {
        error: 'Muitos reagendamentos. Aguarde antes de reagendar novamente.'
      }, status: :too_many_requests
    end

    old_date = appointment.appointment_date
    old_time = appointment.start_time.respond_to?(:strftime) ? appointment.start_time.strftime('%H:%M') : appointment.start_time.to_s[0, 5]

    new_date    = Date.parse(params[:appointment_date].to_s)
    tz          = appointment.establishment.timezone.presence || 'America/Sao_Paulo'
    today_in_tz = Time.current.in_time_zone(tz).to_date

    # Validação de data retroativa aplicada para todos os modos (time e day)
    if new_date < today_in_tz
      return render json: { error: 'Não é possível reagendar para uma data passada.' }, status: :unprocessable_entity
    end

    new_service_id  = params[:service_id].presence  || appointment.service_id
    new_employee_id = params[:employee_id].presence || appointment.employee_id
    
    unless appointment.establishment.services.exists?(id: new_service_id)
      return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
    end

    unless valid_employee_for_service?(new_employee_id, new_service_id, appointment.establishment_id)
      return render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
    end

    if appointment.establishment.booking_mode == 'day'
      appointment.service_id       = new_service_id
      appointment.employee_id      = new_employee_id
      appointment.appointment_date = new_date
      appointment.start_time       = '00:00'
      appointment.end_time         = '23:59'

      unless EmployeeWorkingHour.exists?(user_id: appointment.employee_id, weekday: new_date.wday, is_available: true)
        return render json: { error: 'Profissional indisponível nesta data.' }, status: :unprocessable_entity
      end

      if conflict_exists?(appointment)
        return render json: { error: 'Data indisponível para este profissional.' }, status: :unprocessable_entity
      end
    else
      new_start_time_str     = normalize_time_string(params[:start_time])
      new_start_time_minutes = hhmm_to_minutes(new_start_time_str)

      if new_date == today_in_tz
        now_minutes = current_minutes_in_establishment_timezone(appointment.establishment)
        if new_start_time_minutes < now_minutes
          return render json: { error: 'Não é possível reagendar para um horário que já passou.' }, status: :unprocessable_entity
        end
      end

      available_result = Scheduling::Appointments::AvailableSlotsService.call(
        establishment_id: appointment.establishment_id,
        employee_id:      new_employee_id,
        service_id:       new_service_id,
        appointment_date: new_date
      )

      available_slots = available_result[:available_slots] || []

      unless available_slots.include?(new_start_time_str)
        return render json: { error: 'Horário indisponível.' }, status: :unprocessable_entity
      end

      new_service = appointment.establishment.services.find(new_service_id)
      duration_minutes = new_service.duration_minutes.to_i
      
      appointment.service_id       = new_service_id
      appointment.employee_id      = new_employee_id
      appointment.appointment_date = new_date
      appointment.start_time       = new_start_time_str
      appointment.end_time         = (Time.zone.parse("2000-01-01 #{new_start_time_str}") + duration_minutes.minutes).strftime('%H:%M')

      if conflict_exists?(appointment)
        return render json: { error: 'Horário indisponível.' }, status: :unprocessable_entity
      end
    end

    if appointment.service_package_id.present?
      new_sunday = new_date - new_date.wday.days
      existing_package_appointments = Appointment.where(
        customer_id: current_customer.id,
        establishment_id: appointment.establishment_id,
        service_package_id: appointment.service_package_id
      ).where.not(id: appointment.id).where.not(status: %w[canceled completed])

      existing_sundays = existing_package_appointments.map do |a|
        d = Date.parse(a.appointment_date.to_s)
        d - d.wday.days
      end

      if existing_sundays.include?(new_sunday)
        return render json: { error: 'Já existe uma sessão agendada para esta semana.' }, status: :unprocessable_entity
      end
    end

    if appointment.save
      # Auditoria do reagendamento
      AuditLogger.log(
        action: 'appointment_rescheduled',
        user: current_customer,
        establishment: appointment.establishment,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        details: {
          event: 'appointment_rescheduled',
          appointment_id: appointment.id,
          old_date: old_date,
          old_time: old_time,
          new_date: appointment.appointment_date,
          new_time: appointment.start_time,
          service_name: appointment.service_name_snapshot || appointment.service&.name,
          employee_name: appointment.employee_name_snapshot || appointment.employee&.name
        }
      )

      send_reschedule_emails(appointment, old_date, old_time)
      render json: { success: true, appointment: appointment }
    else
      render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
    end
  rescue Date::Error
    render json: { error: 'Dados inválidos.' }, status: :unprocessable_entity
  end

  private

  def appointment_params
    params.require(:appointment).permit(
      :establishment_id,
      :service_id,
      :employee_id,
      :appointment_date,
      :start_time,
      :notes
      # NOTA: service_package_id é tratado manualmente em #create
      # para garantir validação de segurança antes de atribuir ao registro
    )
  end

  # ─── Validação de segurança para agendamentos de pacote ───────────────
  # Garante multitenancy, status ativo e disponibilidade de sessões antes de gravar.
  def validate_service_package_creation!(package, is_new_purchase, sessions_total)
    unless package.active?
      render json: { error: 'Este pacote não está ativo.' }, status: :unprocessable_entity
      return
    end

    sale = current_customer.service_package_sales.find_by(service_package_id: package.id, status: 'active')
    
    if is_new_purchase
      if sale
        render json: { error: 'Você já possui uma assinatura ativa deste pacote.' }, status: :forbidden
        return
      end

      # Exige o agendamento completo de todas as sessões iniciais ao comprar (opcional dependendo da lógica do frontend, mas o frontend envia tudo)
      if params[:appointments].present? && params[:appointments].size != sessions_total
        render json: { error: "Este pacote requer o agendamento de #{sessions_total} sessões simultâneas." }, status: :unprocessable_entity
        return
      end
    else
      unless sale
        render json: { error: 'Você não possui uma assinatura ativa deste pacote.' }, status: :forbidden
        return
      end

      # Conta quantas sessões o cliente já utilizou + quantas já estão agendadas
      pending_appointments_count = Appointment.where(
        customer_id: current_customer.id,
        establishment_id: package.establishment_id,
        service_package_id: package.id
      ).where(status: %w[pending confirmed]).count

      if (sale.sessions_used + pending_appointments_count) >= sale.sessions_total
        render json: { error: 'Este plano não possui sessões disponíveis para agendamento.' }, status: :unprocessable_entity
        return
      end
    end
  end

  def serialize_appointment(a)
    fb = a.appointment_feedback
    {
      id:               a.id,
      status:           a.status,
      appointment_date: a.appointment_date,
      start_time:       a.start_time.respond_to?(:strftime) ? a.start_time.strftime('%H:%M') : a.start_time.to_s[0, 5],
      end_time:         a.end_time.respond_to?(:strftime) ? a.end_time.strftime('%H:%M') : a.end_time.to_s[0, 5],
      notes:            a.notes,
      # IDs necessários para o frontend chamar a API de disponibilidade no reagendamento
      service_id:       a.service_id,
      employee_id:      a.employee_id,
      # Indica se o agendamento pertence a um pacote mensal
      from_plan:        a.service_package_id.present?,
      service: {
        name:             a.service&.name || a.service_name_snapshot,
        price:            a.service&.price,
        duration_minutes: a.service&.duration_minutes
      },
      employee: {
        name: a.employee&.name || a.employee_name_snapshot
      },
      establishment: {
        name: a.establishment&.name,
        slug: a.establishment&.slug
      },
      feedback: fb ? {
        id:         fb.id,
        rating:     fb.rating,
        comment:    fb.comment,
        created_at: fb.created_at
      } : nil
    }
  end

  def valid_employee_for_service?(employee_id, service_id, establishment_id)
    return false if employee_id.blank?

    EstablishmentMembership.exists?(
      establishment_id: establishment_id,
      user_id:          employee_id,
      active:           true
    ) && EmployeeService.exists?(
      user_id:    employee_id,
      service_id: service_id
    )
  end

  def conflict_exists?(appointment)
    new_start = hhmm_to_minutes(normalize_time_string(appointment.start_time))
    new_end   = hhmm_to_minutes(normalize_time_string(appointment.end_time))

    conflicts = Appointment
      .where(
        establishment_id: appointment.establishment_id,
        employee_id:      appointment.employee_id,
        appointment_date: appointment.appointment_date
      )
      .where.not(status: 'canceled')
      .where.not(id: appointment.id)

    conflicts.any? do |existing|
      existing_start = hhmm_to_minutes(normalize_time_string(existing.start_time))
      existing_end   = hhmm_to_minutes(normalize_time_string(existing.end_time))
      
      has_conflict = new_start < existing_end && new_end > existing_start
      
      if has_conflict
        Rails.logger.debug "[AppointmentsController] Conflict detected with appointment ##{existing.id}: #{existing_start}-#{existing_end} vs new #{new_start}-#{new_end}"
      end
      
      has_conflict
    end
  end

  def normalize_time_string(value)
    if value.respond_to?(:strftime)
      # IMPORTANTE: Time objects de colunas PostgreSQL `time` chegam como UTC 
      # mantendo o HH:MM local. Não usar `in_time_zone` aqui.
      value.strftime('%H:%M')
    else
      value.to_s[0, 5]
    end
  end

  def hhmm_to_minutes(hhmm)
    hour, minute = hhmm.split(':').map(&:to_i)
    (hour * 60) + minute
  end

  def hhmm_to_time(hhmm)
    Time.zone.parse("2000-01-01 #{hhmm}")
  end

  def current_minutes_in_establishment_timezone(establishment)
    timezone = establishment.timezone.presence || 'America/Sao_Paulo'
    now = Time.current.in_time_zone(timezone)
    (now.hour * 60) + now.min
  end

  def send_reschedule_emails(appointment, old_date, old_time)
    establishment = appointment.establishment

    if appointment.customer&.email.present?
      AppointmentMailer.customer_reschedule_notification(appointment, old_date, old_time).deliver_later
    end

    if appointment.employee&.email.present?
      AppointmentMailer.employee_reschedule_notification(appointment, old_date, old_time).deliver_later
    end

    owner = establishment.owner
    if owner&.email.present?
      AppointmentMailer.owner_reschedule_notification(appointment, old_date, old_time).deliver_later
    end
  rescue => e
    Rails.logger.error("[Customer::AppointmentsController] Falha ao enviar emails de reagendamento: #{e.message}")
  end

  def send_cancel_appointment_emails(appointment, reason)
    # Email para o cliente
    if appointment.customer&.email.present?
      CancellationMailer.appointment_customer(appointment, reason).deliver_later
    end

    # Email para o profissional
    if appointment.employee&.email.present?
      CancellationMailer.appointment_employee(appointment, reason).deliver_later
    end

    # Email para o proprietário
    owner = appointment.establishment&.owner
    if owner&.email.present?
      CancellationMailer.appointment_owner(appointment, reason).deliver_later
    end
  rescue => e
    Rails.logger.error("[Customer::AppointmentsController] Falha ao enviar emails de cancelamento: #{e.message}")
  end

  private

  def find_available_employee(service, date, start_time_str)
    employee_ids = allowed_employee_ids_for_service(service)
    
    employee_ids.each do |emp_id|
      res = Scheduling::Appointments::AvailableSlotsService.call(
        establishment_id: service.establishment_id,
        employee_id:      emp_id,
        service_id:       service.id,
        appointment_date: date
      )
      return emp_id if res[:available_slots]&.include?(start_time_str)
    end
    nil
  end

  def allowed_employee_ids_for_service(service)
    memberships = service.establishment.establishment_memberships
                        .where(active: true)
                        .pluck(:user_id)

    EmployeeService
      .where(user_id: memberships, service_id: service.id)
      .pluck(:user_id)
      .uniq
  end
end