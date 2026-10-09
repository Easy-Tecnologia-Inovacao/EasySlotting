class ApplicationController < ActionController::API
  include ActionController::Cookies
  include DeviseTokenAuth::Concerns::SetUserByToken
  include CustomerAuthenticatable

  before_action :validate_password_expiration!
  prepend_before_action :reject_session_credentials_in_url
  after_action :prevent_sensitive_response_caching

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  rescue_from OwnerSessionPolicy::SessionUnavailable do
    @resource = nil
    @token&.clear!
    render json: { error: 'Sua sessão foi encerrada. Entre novamente.' }, status: :unauthorized
  end

  private

  def reject_session_credentials_in_url
    # Tokens na URL podem vazar por histórico, Referer e logs de proxy.
    if %w[access-token access_token refresh_token client uid].any? { |key| request.query_parameters.key?(key) }
      render json: { error: 'Envie as credenciais de sessão apenas nos cabeçalhos.' }, status: :bad_request
    end
  end

  def prevent_sensitive_response_caching
    if request.headers['Authorization'].present? || request.headers['access-token'].present? ||
       params[:controller].to_s.match?(/\A(?:devise_users|customer_auth|account|customer)\//)
      response.headers['Cache-Control'] = 'no-store'
      response.headers['Pragma'] = 'no-cache'
    end
  end

  # ─── Validação de expiração de senha (NIST SP 800-63B + LGPD Art. 46) ───
  # Política: Senhas expiram após 90 dias. Leitura (GET) é permitida para
  # carregar dados. Escrita (POST/PUT/PATCH/DELETE) é bloqueada até a troca.
  # Exceções: endpoints de autenticação e troca de senha.
  def validate_password_expiration!
    return if auth_or_password_controller?
    # ── Staff (User / Devise Token Auth) ──
    if current_user
      unless password_valid_for?(current_user)
        if request.get?
          # Leitura permitida — adiciona header informativo para o frontend
          response.headers['X-Password-Expired'] = 'true'
          return
        end

        # Escrita bloqueada — registra tentativa e rejeita
        AuditLogger.log(
          action: 'write_blocked_password_expired',
          user: current_user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          details: { method: request.method, path: request.path }
        )
        render json: {
          error: 'Sua senha expirou. Altere-a para realizar esta ação.',
          password_expired: true,
          code: 'PASSWORD_EXPIRED'
        }, status: :forbidden
        return
      end
    end

    # ── Clientes (Customer) ──
    if respond_to?(:resolve_customer_from_token, true)
      customer = current_customer || resolve_customer_from_token
      if customer.present?
        return if params[:controller] == 'customer/profile'

        unless password_valid_for_customer?(customer)
          if request.get?
            response.headers['X-Password-Expired'] = 'true'
            return
          end

          AuditLogger.log(
            action: 'write_blocked_password_expired',
            user: customer,
            ip: request.remote_ip,
            user_agent: request.user_agent,
            details: { method: request.method, path: request.path }
          )
          render json: {
            error: 'Sua senha expirou. Altere-a para realizar esta ação.',
            password_expired: true,
            code: 'PASSWORD_EXPIRED'
          }, status: :forbidden
          return
        end
      end
    end
  end

  def current_establishment
    return nil unless current_user

    @current_establishment ||= begin
      est_id = request.headers['X-Establishment-ID'] || params[:establishment_id]

      if current_user.role == 'super_admin'
        # Super Admin pode acessar qualquer estabelecimento
        est_id.present? ? Establishment.find_by(id: est_id) : Establishment.first
      else
        # Usuário comum só acessa estabelecimentos aos quais pertence ou é dono
        owned = current_user.owned_establishments.where(active: true)
        shared = current_user.establishments.where(active: true, establishment_memberships: { active: true })
        if est_id.present?
          owned.find_by(id: est_id) || shared.find_by(id: est_id)
        else
          owned.first || shared.first
        end
      end
    end
  end

  def set_establishment
    @establishment = current_establishment
    unless @establishment
      render json: { error: 'Estabelecimento não encontrado ou acesso negado' }, status: :forbidden and return
    end
  end

  def render_not_found
    render json: { error: 'Recurso não encontrado' }, status: :not_found
  end

  def require_super_admin!
    unless current_user&.super_admin?
      render json: { error: 'Acesso negado: Requer privilégios de Super Admin' }, status: :forbidden and return
    end
  end

  def require_owner!
    return if current_user&.super_admin?
    est = @establishment || current_establishment
    return if est&.owner_id == current_user&.id

    render json: { error: 'Acesso negado: Requer privilégios de proprietário' }, status: :forbidden and return
  end

  def require_employee_or_owner!
    return if current_user&.super_admin?
    est = @establishment || current_establishment
    return if est&.owner_id == current_user&.id
    return if current_membership.present?

    render json: { error: 'Acesso negado' }, status: :forbidden and return
  end

  def current_membership
    est = @establishment || current_establishment
    return nil unless est
    @current_membership ||= current_user.establishment_memberships.find_by(establishment_id: est.id, active: true)
  end

  def require_financial_access!
    return if current_user&.super_admin?
    est = @establishment || current_establishment
    return if est&.owner_id == current_user&.id

    unless current_membership&.can_manage_financial?
      render json: { error: 'Acesso negado: Você não tem permissão para acessar o financeiro' }, status: :forbidden and return
    end
  end

  def require_schedule_management!
    return if current_user&.super_admin?
    est = @establishment || current_establishment
    return if est&.owner_id == current_user&.id

    unless current_membership&.can_manage_schedule?
      render json: { error: 'Acesso negado: Você não tem permissão para gerenciar a agenda' }, status: :forbidden and return
    end
  end

  def require_services_management!
    return if current_user&.super_admin?
    est = @establishment || current_establishment
    return if est&.owner_id == current_user&.id

    unless current_membership&.can_manage_services?
      render json: { error: 'Acesso negado: Você não tem permissão para gerenciar os serviços e planos' }, status: :forbidden and return
    end
  end

  def require_team_management!
    return if current_user&.super_admin?
    est = @establishment || current_establishment
    return if est&.owner_id == current_user&.id

    unless current_membership&.can_manage_team?
      render json: { error: 'Acesso negado: Você não tem permissão para gerenciar a equipe' }, status: :forbidden and return
    end
  end

  def require_establishment_management!
    return if current_user&.super_admin?
    est = @establishment || current_establishment
    return if est&.owner_id == current_user&.id

    unless current_membership&.can_manage_establishment?
      render json: { error: 'Acesso negado: Você não tem permissão para configurar a empresa' }, status: :forbidden and return
    end
  end

  def require_stock_management!
    return if current_user&.super_admin?
    est = @establishment || current_establishment
    return if est&.owner_id == current_user&.id

    unless current_membership&.can_manage_stock?
      render json: { error: 'Acesso negado: Você não tem permissão para gerenciar o estoque' }, status: :forbidden and return
    end
  end

  def require_customer!
    unless current_user&.customer?
      render json: { error: 'Acesso negado' }, status: :forbidden and return
    end
  end

  # ── Helpers para validação de expiração de senha ──

  PASSWORD_EXPIRY_DAYS = 90

  def password_valid_for?(user)
    return true if user.password_changed_at.nil?
    user.password_changed_at >= PASSWORD_EXPIRY_DAYS.days.ago
  end

  def password_valid_for_customer?(customer)
    return true if customer.password_changed_at.nil?
    customer.password_changed_at >= PASSWORD_EXPIRY_DAYS.days.ago
  end

  # Controllers que devem ignorar a validação de expiração de senha
  # (autenticação, troca de senha, recuperação de senha)
  AUTH_CONTROLLERS = %w[
    devise_users/sessions
    devise_users/passwords
    devise_users/confirmations
    customer_auth/sessions
    customer_auth/registrations
    customer_auth/passwords
    account/users
  ].freeze

  def auth_or_password_controller?
    AUTH_CONTROLLERS.include?(params[:controller])
  end
end
