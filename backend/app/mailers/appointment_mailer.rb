class AppointmentMailer < ApplicationMailer

  def customer_notification(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @is_package = appointment.service_package_id.present?
    @timezone = @establishment.timezone.presence || 'America/Sao_Paulo'

    if @is_package
      @package = appointment.service_package
      @package_price = @package.price
      @package_appointments = Appointment.where(
        customer_id: @customer.id,
        service_package_id: @package.id
      ).where.not(status: 'canceled').order(:appointment_date, :start_time)
    end

    mail(
      to: @customer.email,
      subject: "Agendamento Confirmado - #{@establishment.name}"
    )
  end

  def employee_notification(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @is_package = appointment.service_package_id.present?

    if @is_package
      @package = appointment.service_package
      @package_price = @package.price
      @package_appointments = Appointment.where(
        customer_id: @customer.id,
        service_package_id: @package.id
      ).where.not(status: 'canceled').order(:appointment_date, :start_time)
    end

    mail(
      to: @employee.email,
      subject: "Novo agendamento na sua agenda - #{@establishment.name}"
    )
  end

  def owner_notification(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @owner = @establishment.owner
    @employee = appointment.employee
    @service = appointment.service
    @is_package = appointment.service_package_id.present?

    if @is_package
      @package = appointment.service_package
      @package_price = @package.price
      @package_appointments = Appointment.where(
        customer_id: @customer.id,
        service_package_id: @package.id
      ).where.not(status: 'canceled').order(:appointment_date, :start_time)
    end

    mail(
      to: @owner.email,
      subject: "Novo agendamento realizado - #{@establishment.name}"
    )
  end

  # ─── NOTIFICAÇÕES DE REAGENDAMENTO ──────────────────────────────────────

  def customer_reschedule_notification(appointment, old_date, old_time = nil)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @old_date = old_date
    @old_time = old_time
    @is_package = appointment.service_package_id.present?

    if @is_package
      @package = appointment.service_package
      @package_price = @package.price
      @package_appointments = Appointment.where(
        customer_id: @customer.id,
        service_package_id: @package.id
      ).where.not(status: 'canceled').order(:appointment_date, :start_time)
      @session_number = @package_appointments.index { |a| a.id == appointment.id }&.+(1)
    end

    mail(
      to: @customer.email,
      subject: "Horário Reagendado - #{@establishment.name}"
    )
  end

  def employee_reschedule_notification(appointment, old_date, old_time = nil)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @old_date = old_date
    @old_time = old_time
    @is_package = appointment.service_package_id.present?

    if @is_package
      @package = appointment.service_package
      @package_price = @package.price
      @package_appointments = Appointment.where(
        customer_id: @customer.id,
        service_package_id: @package.id
      ).where.not(status: 'canceled').order(:appointment_date, :start_time)
      @session_number = @package_appointments.index { |a| a.id == appointment.id }&.+(1)
    end

    mail(
      to: @employee.email,
      subject: "Agendamento reagendado na sua agenda - #{@establishment.name}"
    )
  end

  def owner_reschedule_notification(appointment, old_date, old_time = nil)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @owner = @establishment.owner
    @employee = appointment.employee
    @service = appointment.service
    @old_date = old_date
    @old_time = old_time
    @is_package = appointment.service_package_id.present?

    if @is_package
      @package = appointment.service_package
      @package_price = @package.price
      @package_appointments = Appointment.where(
        customer_id: @customer.id,
        service_package_id: @package.id
      ).where.not(status: 'canceled').order(:appointment_date, :start_time)
      @session_number = @package_appointments.index { |a| a.id == appointment.id }&.+(1)
    end

    mail(
      to: @owner.email,
      subject: "Agendamento reagendado - #{@establishment.name}"
    )
  end

  # ─── LEMBRETE DE CONFIRMAÇÃO (1H ANTES) ──────────────────────────────────

  def confirmation_reminder(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @is_package = appointment.service_package_id.present?
    @timezone = @establishment.timezone.presence || 'America/Sao_Paulo'
    @slug = @establishment.slug

    if @is_package
      @package = appointment.service_package
    end

    mail(
      to: @customer.email,
      subject: "Confirme seu agendamento - #{@establishment.name}"
    )
  end
end
