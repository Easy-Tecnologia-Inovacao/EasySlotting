# app/controllers/devise_users/sessions_controller.rb
# Login de staff (owners/employees/super_admin).
# Usa Devise Token Auth com token rotation.
# Audit log registra todas as tentativas de login.

class DeviseUsers::SessionsController < DeviseTokenAuth::SessionsController
  wrap_parameters false

  after_action :stamp_session_metadata, only: :create

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    # 1. Conta bloqueada
    if user&.access_locked?
      render json: {
        errors: ['Sua conta foi bloqueada devido a um número excessivo de tentativas. Aguarde 30 minutos.']
      }, status: :too_many_requests
      return
    end

    # OTP só é considerado válido se for exatamente 6 dígitos numéricos
    raw_otp = params[:otp_code].to_s.strip
    is_otp_attempt = raw_otp.match?(/\A\d{6}\z/)

    Rails.logger.debug "[OTP] raw=#{raw_otp.inspect} is_attempt=#{is_otp_attempt}" if Rails.env.development?

    device_token = sanitized_device_token

    # 2. Verificação de role e novo IP/dispositivo (ANTES de criar token Devise)
    if user && user.valid_password?(params[:password].to_s)
      unless %w[owner employee super_admin].include?(user.role)
        render json: {
          errors: ['Acesso exclusivo para empresas. Clientes devem acessar pela página do estabelecimento.']
        }, status: :forbidden
        return
      end

      # O primeiro login confirma o dispositivo inicial; novos IPs/dispositivos
      # só exigem OTP depois que já existe um login bem-sucedido.
      first_successful_login = !AuditLog.where(action: 'login', user_id: user.id).exists?

      if is_otp_attempt
        # Usuário está enviando o código OTP → verifica
        unless user.verify_login_otp(raw_otp)
          render json: { errors: ['Código de verificação inválido ou expirado.'] }, status: :unauthorized
          return
        end
        # OTP correto → adiciona IP e dispositivo confiável e deixa o super continuar normalmente
        user.add_trusted_device!(ip: request.remote_ip, device_token: device_token)
      elsif !first_successful_login &&
            AuditLogger.new_device?(user: user, ip: request.remote_ip, user_agent: request.user_agent) &&
            !user.trusted_device?(ip: request.remote_ip, device_token: device_token)
        # Novo dispositivo/IP sem OTP → exige verificação
        code = user.generate_login_otp!
        begin
          SecurityAlertMailer.login_verification_code(
            user: user,
            otp_code: code,
            ip: request.remote_ip,
            user_agent: request.user_agent,
            location: AuditLogger.geolocate(request.remote_ip)
          ).deliver_now
        rescue => e
          Rails.logger.error "[OTP] Erro ao enviar email de verificação: #{e.message}"
        end

        Rails.logger.info "[OTP] ✉️  Código para #{mask_email(user.email)}: #{code}" if Rails.env.development?

        render json: {
          requires_verification: true,
          email_masked: mask_email(user.email),
          methods: [
            { id: 'email', name: 'Código via E-mail', active: true },
            { id: 'totp', name: 'Aplicativo Autenticador (2FA)', active: false, badge: 'Em breve' }
          ]
        }, status: :ok
        return
      end
    end

    # 3. Fluxo normal do Devise Token Auth (cria token, autentica, etc.)
    super
  end


  # DELETE /devise_users/sign_out
  # Invalida o token do cliente e registra o evento no audit log
  def destroy
    if current_user
      AuditLogger.log_logout(
        user: current_user,
        ip: request.remote_ip,
        user_agent: request.user_agent
      )
    end

    super
  end

  protected

  def render_create_success
    # OTP e verificação de novo IP já foram resolvidos no método create (antes do super).
    # Aqui chegamos apenas quando o login está 100% autorizado.

    # Adiciona IP e dispositivo à lista confiável (caso seja IP novo que passou OTP ou primeiro login)
    device_token = sanitized_device_token
    @resource.add_trusted_device!(ip: request.remote_ip, device_token: device_token)

    # Reseta tentativas falhas
    @resource.reset_failed_attempts!

    # Registra login bem-sucedido no audit log
    AuditLogger.log_login_success(
      user: @resource,
      ip: request.remote_ip,
      user_agent: request.user_agent
    )

    # Envia alerta de novo dispositivo (primeira vez neste IP nas últimas 24h)
    if AuditLogger.new_device_alert?(user: @resource, ip: request.remote_ip)
      SecurityAlertMailer.new_device_login(
        user: @resource,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        device_info: AuditLogger.send(:device_info, request.user_agent),
        location: AuditLogger.geolocate(request.remote_ip),
        login_time: Time.current
      ).deliver_later
    end

    user_data = resource_data(resource_json: @resource.token_validation_response)

    # Indica ao frontend se a senha expirou (90 dias)
    is_expired = @resource.password_changed_at.nil? || @resource.password_changed_at < 90.days.ago
    user_data = user_data.merge(password_expired: is_expired)

    render json: { data: user_data }
  end

  # Sobrescreve erro de logout para retornar 200 OK (se o token já tiver sido revogado)
  def render_destroy_error
    render json: { success: true, message: 'Sessão encerrada com sucesso.' }, status: :ok
  end

  # Sobrescreve para mensagem de conta bloqueada
  def render_create_error_account_locked
    render json: {
      errors: ['Sua conta foi bloqueada devido a múltiplas tentativas. Aguarde 30 minutos para desbloqueio.']
    }, status: :too_many_requests
  end

  # Sobrescreve para registrar login falho e incrementar tentativas
  def render_create_error_bad_credentials
    AuditLogger.log_login_failure(
      email: params[:email].to_s.downcase.strip,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      reason: 'invalid_credentials'
    )

    # Incrementa tentativas falhas no usuário
    user = User.find_by(email: params[:email]&.downcase&.strip)
    if user
      user.increment_failed_attempts!

      # Envia alerta de tentativa falhada
      SecurityAlertMailer.failed_login_attempt(
        user: user,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        attempt_time: Time.current
      ).deliver_later

      # Envia alerta se a conta acabou de ser bloqueada
      if user.access_locked?
        SecurityAlertMailer.account_locked(
          user: user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          locked_at: Time.current
        ).deliver_later
      end
    end

    super
  end

  private

  def sanitized_device_token
    raw = request.headers['X-Device-Token'].to_s.strip.presence || params[:device_token].to_s.strip.presence
    raw&.slice(0, 100)&.gsub(/[^a-zA-Z0-9_-]/, '').presence
  end

  def login_params
    params.permit(:email, :password, :otp_code, :device_token)
  end

  # Remove o token gerado pelo Devise quando o login ainda não está completo
  # (ex: aguardando verificação OTP). Isso garante que o after_action
  # update_auth_header do DeviseTokenAuth não reponha os headers de auth.
  def revoke_session_token!
    return unless @resource && @token&.client
    tokens = @resource.tokens || {}
    tokens.delete(@token.client)
    @resource.update_columns(tokens: tokens)
    @token.client = nil
  end

  # Registra metadata da sessão (IP, User Agent, device)
  def stamp_session_metadata
    return unless current_user

    client_id = response.headers['client']
    return if client_id.blank?

    tokens = current_user.tokens || {}
    entry  = (tokens[client_id] || {}).dup
    entry['ua'] = request.user_agent.to_s[0, 200]
    entry['ip'] = request.remote_ip
    entry['name'] ||= device_friendly_name(request.user_agent)
    entry['last_seen_at'] = Time.current.to_i
    tokens[client_id] = entry

    current_user.update_columns(tokens: tokens, updated_at: Time.current)
  end

  # (log_staff_login removido: o log agora acontece dentro de render_create_success
  #  para garantir que só registra DEPOIS de toda verificação de OTP/IP passar.)

  def device_friendly_name(ua)
    u = ua.to_s

    os =
      if u.include?('Windows')
        'Windows'
      elsif u.include?('Mac OS X') || u.include?('Macintosh')
        'macOS'
      elsif u.include?('Android')
        'Android'
      elsif u.include?('iPhone') || u.include?('iPad')
        'iOS'
      elsif u.include?('Linux')
        'Linux'
      else
        'Desconhecido'
      end

    browser =
      if u.include?('Edg')
        'Edge'
      elsif u.include?('Chrome')
        'Chrome'
      elsif u.include?('Safari') && !u.include?('Chrome')
        'Safari'
      elsif u.include?('Firefox')
        'Firefox'
      else
        'Navegador'
      end

    "#{os} · #{browser}"
  end

  def mask_email(email)
    return '' if email.blank?
    parts = email.split('@')
    name = parts.first
    domain = parts.last
    masked_name = if name.length <= 2
                    name[0] + '*'
                  else
                    name[0] + ('*' * (name.length - 2)) + name[-1]
                  end
    "#{masked_name}@#{domain}"
  end
end
