class CancellationMailer < ApplicationMailer

  # ─── CANCELAMENTO AUTOMÁTICO POR FALTA (NO-SHOW) ──────────────────────

  # Email para o cliente quando o agendamento é cancelado automaticamente por falta
  def no_show_customer(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @is_package = appointment.service_package_id.present?

    mail(
      to: @customer.email,
      subject: "Agendamento cancelado por falta - #{@establishment.name}"
    )
  end

  # Email para o cliente quando o pacote é cancelado por falta na primeira sessão
  def no_show_package(sale, customer)
    @sale = sale
    @customer = customer
    @establishment = sale.establishment
    @package = sale.service_package

    mail(
      to: @customer.email,
      subject: "Pacote cancelado por falta - #{@establishment.name}"
    )
  end

  # ─── CANCELAMENTO DE AGENDAMENTO ──────────────────────────────────────

  # Email para o cliente
  def appointment_customer(appointment, reason)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @reason = reason
    @is_package = appointment.service_package_id.present?

    mail(
      to: @customer.email,
      subject: "Agendamento Cancelado - #{@establishment.name}"
    )
  end

  # Email para o profissional
  def appointment_employee(appointment, reason)
    @appointment = appointment
    @customer_name = 'Cliente'  # LGPD: anonimato
    @employee = appointment.employee
    @establishment = appointment.establishment
    @service = appointment.service
    @reason = reason
    @is_package = appointment.service_package_id.present?

    mail(
      to: @employee.email,
      subject: "Agendamento Cancelado - #{@establishment.name}"
    )
  end

  # Email para o proprietário
  def appointment_owner(appointment, reason)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @reason = reason
    @is_package = appointment.service_package_id.present?

    mail(
      to: @establishment.owner.email,
      subject: "Agendamento Cancelado - #{@establishment.name}"
    )
  end

  # ─── CANCELAMENTO DE PACOTE MENSAL ────────────────────────────────────

  # Email para o cliente
  def package_customer(sale, reason, sessions_canceled, customer)
    @sale = sale
    @customer = customer
    @establishment = sale.establishment
    @package = sale.service_package
    @reason = reason
    @sessions_canceled = sessions_canceled

    mail(
      to: @customer.email,
      subject: "Pacote Mensal Cancelado - #{@establishment.name}"
    )
  end

  # Email para o profissional (se houver profissional associado)
  def package_employee(sale, reason, sessions_canceled, employee)
    @sale = sale
    @customer_name = 'Cliente'  # LGPD: anonimato
    @establishment = sale.establishment
    @package = sale.service_package
    @reason = reason
    @sessions_canceled = sessions_canceled
    @employee = employee

    return if @employee&.email.blank?

    mail(
      to: @employee.email,
      subject: "Pacote Mensal Cancelado - #{@establishment.name}"
    )
  end

  # Email para o proprietário
  def package_owner(sale, reason, sessions_canceled)
    @sale = sale
    @customer = sale.customer
    @establishment = sale.establishment
    @package = sale.service_package
    @reason = reason
    @sessions_canceled = sessions_canceled

    mail(
      to: @establishment.owner.email,
      subject: "Pacote Mensal Cancelado - #{@establishment.name}"
    )
  end
end
