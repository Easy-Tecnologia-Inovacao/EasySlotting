class FeedbackMailer < ApplicationMailer

  # Email solicitando feedback ao cliente após conclusão do atendimento
  def feedback_request(appointment)
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service
    @slug = @establishment.slug
    @is_package = appointment.service_package_id.present?
    @timezone = @establishment.timezone.presence || 'America/Sao_Paulo'

    mail(
      to: @customer.email,
      subject: "Como foi seu atendimento? - #{@establishment.name}"
    )
  end

  # Email de confirmação para o cliente (feedback é anônimo)
  def customer_confirmation(feedback, appointment)
    @feedback = feedback
    @appointment = appointment
    @customer = appointment.customer
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service

    mail(
      to: @customer.email,
      subject: "Feedback recebido - #{@establishment.name}"
    )
  end

  # Email para o profissional (sem dados do cliente — anônimo)
  def employee_notification(feedback, appointment)
    @feedback = feedback
    @appointment = appointment
    @employee = appointment.employee
    @establishment = appointment.establishment
    @service = appointment.service

    mail(
      to: @employee.email,
      subject: "Novo feedback recebido - #{@establishment.name}"
    )
  end

  # Email para o proprietário (resumo do feedback)
  def owner_notification(feedback, appointment)
    @feedback = feedback
    @appointment = appointment
    @owner = appointment.establishment.owner
    @establishment = appointment.establishment
    @employee = appointment.employee
    @service = appointment.service

    mail(
      to: @owner.email,
      subject: "Novo feedback de cliente - #{@establishment.name}"
    )
  end
end
