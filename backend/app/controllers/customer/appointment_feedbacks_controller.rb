# app/controllers/customer/appointment_feedbacks_controller.rb
# Controller para feedbacks anônimos de agendamentos concluídos.
# Autenticado via JWT do customer (authenticate_customer!).
# Um agendamento pode ter no máximo 1 feedback.
# LGPD: o feedback é anônimo — nome do cliente não é exposto nos emails.

class Customer::AppointmentFeedbacksController < ApplicationController
  before_action :authenticate_customer!
  before_action :set_appointment

  RATE_LIMIT_WINDOW = 1.hour
  MAX_FEEDBACKS_PER_WINDOW = 20

  # POST /api/customer/appointments/:appointment_id/feedback
  def create
    # Idempotência: se já existe, retorna o existente sem erro
    if @appointment.appointment_feedback.present?
      return render json: {
        message: 'Feedback já registrado.',
        feedback: serialize_feedback(@appointment.appointment_feedback)
      }, status: :ok
    end

    # Rate limiting
    recent_feedbacks = AuditLog.where(
      establishment_id: current_customer.establishment_id,
      action: 'feedback_created',
      created_at: RATE_LIMIT_WINDOW.ago..
    ).where(
      '(auditable_type = ? AND auditable_id = ?) OR user_id = ?',
      'Customer', current_customer.id, current_customer.id
    ).count

    if recent_feedbacks >= MAX_FEEDBACKS_PER_WINDOW
      return render json: {
        error: 'Muitos feedbacks. Aguarde antes de enviar novamente.'
      }, status: :too_many_requests
    end

    # Validação de rating
    rating = feedback_params[:rating].to_i
    unless rating >= 1 && rating <= 5
      return render json: { errors: ['Avaliação deve ser entre 1 e 5.'] }, status: :unprocessable_entity
    end

    # Validação e sanitização de comentário (opcional, mas se presente, máxima 1000 chars)
    # SECURITY: sanitize remove todas as tags HTML para prevenir XSS stored (Falha 5a).
    comment = ActionController::Base.helpers.sanitize(
      feedback_params[:comment].to_s.strip, tags: []
    ).truncate(1000, omission: '')

    if comment.length > 1000
      return render json: { errors: ['Comentário muito longo. Máximo de 1000 caracteres.'] }, status: :unprocessable_entity
    end

    feedback = AppointmentFeedback.new(
      appointment: @appointment,
      customer:    current_customer,
      rating:      rating,
      comment:     comment,
      anonymous:   true
    )

    if feedback.save
      # Auditoria do feedback
      AuditLogger.log(
        action: 'feedback_created',
        user: current_customer,
        establishment: @appointment.establishment,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        details: {
          event: 'feedback_created',
          appointment_id: @appointment.id,
          rating: rating,
          has_comment: comment.present?,
          comment_length: comment.length
        }
      )

      send_feedback_emails(feedback)

      render json: {
        message: 'Feedback enviado com sucesso!',
        feedback: serialize_feedback(feedback)
      }, status: :created
    else
      render json: { errors: feedback.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_appointment
    @appointment = current_customer.appointments.find_by(id: params[:appointment_id])

    # SEGURANÇA (2.3): Valida no servidor que o agendamento pertence ao cliente
    # autenticado e foi concluído — a proteção no frontend (ocultar botão) é apenas UX.
    # Sem esta verificação, o cliente poderia forjar a requisição para avaliar agendamentos
    # em qualquer estado (pending, confirmed, canceled), gerando feedbacks ilegítimos.
    unless @appointment
      render json: { error: 'Agendamento não encontrado.' }, status: :not_found
      return
    end

    unless @appointment.status == 'completed'
      render json: { error: 'Apenas agendamentos concluídos podem ser avaliados.' }, status: :unprocessable_entity
    end
  end

  def feedback_params
    params.require(:feedback).permit(:rating, :comment)
  end

  def serialize_feedback(fb)
    {
      id:         fb.id,
      rating:     fb.rating,
      comment:    fb.comment,
      anonymous:  fb.anonymous,
      created_at: fb.created_at
    }
  end

  def send_feedback_emails(feedback)
    appointment = @appointment

    # Email de confirmação para o cliente
    if appointment.customer&.email.present?
      FeedbackMailer.customer_confirmation(feedback, appointment).deliver_later
    end

    # Email para o profissional (sem dados do cliente — anônimo)
    if appointment.employee&.email.present?
      FeedbackMailer.employee_notification(feedback, appointment).deliver_later
    end

    # Email para o proprietário
    owner = appointment.establishment&.owner
    if owner&.email.present?
      FeedbackMailer.owner_notification(feedback, appointment).deliver_later
    end
  rescue => e
    Rails.logger.error("[AppointmentFeedbacksController] Falha ao enviar emails de feedback: #{e.message}")
  end
end
