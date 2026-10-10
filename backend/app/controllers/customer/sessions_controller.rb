class Customer::SessionsController < ApplicationController
  before_action :authenticate_customer!

  def index
    # Paginar impede respostas ilimitadas mesmo com muitos aparelhos.
    page = params[:page].to_s
    unless page.blank? || page.match?(/\A[1-9]\d{0,5}\z/)
      return render json: { error: 'Página inválida.' }, status: :unprocessable_entity
    end
    sessions = current_customer.customer_sessions.active.order(created_at: :desc, id: :desc)
      .offset(([page.to_i, 1].max - 1) * 20).limit(21).to_a
    render json: { sessions: sessions.first(20).map { |session|
      session.as_json.merge(is_current: session.id == current_customer_session.id)
    }, has_more: sessions.size > 20, limit: nil }
  end

  def destroy
    unless params[:id].is_a?(String) && CustomerSession::SESSION_ID_PATTERN.match?(params[:id])
      return render json: { error: 'Acesso não encontrado.' }, status: :not_found
    end
    current_customer.with_lock do
      raise CustomerAuthenticatable::TokenInvalidError unless current_customer.valid_auth_session?(current_customer_session.session_id)
      current_customer.customer_sessions.find_by!(session_id: params[:id]).destroy!
    end
    audit('customer_session_revoked')
    render json: { message: 'Acesso encerrado.' }
  end

  def destroy_others
    current_customer.with_lock do
      raise CustomerAuthenticatable::TokenInvalidError unless current_customer.valid_auth_session?(current_customer_session.session_id)
      current_customer.customer_sessions.where.not(id: current_customer_session.id).delete_all
    end
    audit('customer_other_sessions_revoked')
    render json: { message: 'Os outros acessos foram encerrados.' }
  end

  private

  def audit(action)
    AuditLogger.log(action: action, user: current_customer, establishment: current_customer.establishment,
      ip: request.remote_ip, user_agent: request.user_agent)
  end
end
