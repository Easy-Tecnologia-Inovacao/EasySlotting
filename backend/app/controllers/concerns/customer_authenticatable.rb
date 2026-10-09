# app/controllers/concerns/customer_authenticatable.rb
# Concern responsável por autenticar customers via Bearer token JWT.
# Inclua este concern nos controllers que servem a área do cliente.
#
# Boas práticas aplicadas:
#  - Lança exceções tipadas (não genéricas)
#  - Verifica active? antes de liberar acesso
#  - Não expõe detalhes internos nos erros para o cliente

module CustomerAuthenticatable
  extend ActiveSupport::Concern

  # Erros tipados para distinguir problemas de autenticação
  class TokenExpiredError < StandardError; end
  class TokenInvalidError < StandardError; end

  included do
    # Captura globalmente qualquer falha de token JWT
    rescue_from TokenExpiredError, with: :render_token_expired
    rescue_from TokenInvalidError, with: :render_token_invalid
  end

  # Antes de ação: garante que o customer está autenticado
  def authenticate_customer!
    @current_customer = resolve_customer_from_token
    render_unauthorized unless @current_customer&.active?
  end

  def current_customer
    @current_customer
  end

  def current_customer_session
    @current_customer_session
  end

  private

  def resolve_customer_from_token
    return nil if defined?(current_user) && current_user.present?
    return nil if request.headers['access-token'].present? || request.headers['Access-Token'].present?

    header = request.headers['Authorization']
    return nil if header.blank?

    match = header.match(/\ABearer ([^\s]+)\z/i)
    return nil unless match
    token = match[1]

    payload = CustomerJsonWebToken.decode_access_token(token)

    customer_id      = payload[:customer_id]
    establishment_id = payload[:establishment_id]

    return nil if customer_id.blank? || establishment_id.blank?

    customer = Customer.find_by(id: customer_id, establishment_id: establishment_id, active: true)
    if customer&.valid_auth_session?(payload[:sid])
      @current_customer_session = customer.customer_sessions.active.find_by(session_id: payload[:sid])
      customer if @current_customer_session
    end
  end

  def render_unauthorized
    render json: { error: 'Acesso não autorizado.' }, status: :unauthorized
  end

  def render_token_expired
    render json: { error: 'Sessão expirada. Faça login novamente.' }, status: :unauthorized
  end

  def render_token_invalid
    render json: { error: 'Token inválido.' }, status: :unauthorized
  end
end
