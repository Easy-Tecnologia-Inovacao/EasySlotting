class AppointmentReminderJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current

    Appointment
      .where(status: 'pending')
      .where.not(customer_id: nil)
      .includes(:customer, :employee, :establishment, :service, :service_package)
      .find_each do |appointment|
        tz_name = appointment.establishment&.timezone.presence || 'America/Sao_Paulo'
        tz = ActiveSupport::TimeZone[tz_name] || ActiveSupport::TimeZone['America/Sao_Paulo']
        appt_time = appointment.start_time.respond_to?(:strftime) ? appointment.start_time.strftime('%H:%M') : appointment.start_time.to_s[0, 5]
        hour, min = appt_time.split(':').map(&:to_i)

        appt_datetime = tz.local(
          appointment.appointment_date.year,
          appointment.appointment_date.month,
          appointment.appointment_date.day,
          hour, min, 0
        )

        reminder_time = appt_datetime - 1.hour
        window_start = reminder_time - 5.minutes
        window_end   = reminder_time + 5.minutes

        # Verifica se o email já foi enviado nas últimas 2 horas
        already_sent = AuditLog.where(
          action: 'confirmation_reminder_sent',
          details: { appointment_id: appointment.id }
        ).where('created_at >= ?', 2.hours.ago).exists?

        next if already_sent

        should_send = false

        # Caso 1: Agendamento dentro da janela normal (1h antes ± 5min)
        if now >= window_start && now <= window_end
          should_send = true
        end

        # Caso 2: Agendamento criado com menos de 1h de antecedência
        # Envia imediatamente se o agendamento ainda está pendente e é no futuro
        if !should_send && appt_datetime > now && appt_datetime <= 1.hour.from_now
          should_send = true
        end

        next unless should_send

        AppointmentMailer.confirmation_reminder(appointment).deliver_now

        AuditLogger.log(
          action: 'confirmation_reminder_sent',
          user: appointment.customer,
          establishment: appointment.establishment,
          details: {
            event: 'confirmation_reminder_sent',
            appointment_id: appointment.id,
            customer_email: appointment.customer.email,
            appointment_date: appointment.appointment_date,
            start_time: appt_time
          }
        )
      end
  end
end
