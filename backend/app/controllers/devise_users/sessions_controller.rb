# app/controllers/devise_users/sessions_controller.rb
# Login de staff (owners/employees/super_admin).
# Usa Devise Token Auth com token rotation.
# Audit log registra todas as tentativas de login.

class DeviseUsers::SessionsController < DeviseTokenAuth::SessionsController
  wrap_parameters false
  include LoginInput
  include StaffRecoveryCookie
  class LoginStateChanged < StandardError; end

  rescue_from OwnerSessionPolicy::LimitReached do |error|
    role = @resource&.role
    AuditLogger.log(action: 'staff_session_limit_reached', user: @resource,
      ip: request.remote_ip, user_agent: request.user_agent, details: { limit: error.limit })
    @resource = nil
    @token.clear!
    sessions_label = error.limit == 1 ? 'sessão simultânea' : 'sessões simultâneas'
    render json: {
      code: role == 'owner' ? 'OWNER_SESSION_LIMIT_REACHED' : 'STAFF_SESSION_LIMIT_REACHED',
      limit: error.limit,
      errors: ["Sua conta permite até #{error.limit} #{sessions_label}. Em outro aparelho, abra Dispositivos conectados e encerre um acesso para entrar."]
    }, status: :conflict
  end

  rescue_from LoginStateChanged, StaffSessionRecovery::InvalidSession do
    @resource = nil
    @token.clear!
    render json: { errors: ['Não foi possível concluir o login. Tente novamente.'] }, status: :unauthorized
  end

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

    device_token = sanitized_device_token

    # 2. Verificação de role, primeiro acesso e IP (ANTES de criar token Devise)
    if user&.active_for_authentication? && user.valid_password?(params[:password].to_s)
      unless %w[owner employee super_admin].include?(user.role)
        render json: {
          errors: ['Acesso exclusivo para empresas. Clientes devem acessar pela página do estabelecimento.']
        }, status: :forbidden
        return
      end

      if is_otp_attempt
        # Usuário está enviando o código OTP → verifica
        unless user.verify_login_otp(raw_otp, ip: request.remote_ip, device_token: device_token)
          render json: { errors: ['Código de verificação inválido ou expirado.'] }, status: :unauthorized
          return
        end
      elsif user.login_otp_required?(ip: request.remote_ip)
        # Primeiro acesso ou IP desconhecido exige e-mail antes de criar sessão.
        code = user.generate_login_otp!(ip: request.remote_ip, device_token: device_token)
        if code
          SecurityAlertMailer.login_verification_code(
            user: user, otp_code: code, ip: request.remote_ip,
            user_agent: request.user_agent, location: AuditLogger.geolocate(request.remote_ip)
          ).deliver_later
        end

        render json: {
          requires_verification: true,
          email_masked: mask_email(user.email),
          methods: [{ id: 'email', name: 'Código via E-mail', active: true }]
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
    user = @resource
    client = @token.client
    payload = staff_recovery_payload
    if !user && payload
      begin
        user = StaffSessionRecovery.new(payload, client: request.headers['client'],
          uid: request.headers['uid'], csrf: request.headers['X-CSRF-Token']).revoke!
        client = payload['client']
      rescue StaffSessionRecovery::InvalidSession
        # Não apaga o cookie de outra identidade/aba nem restaura credenciais.
        return render json: { success: true }, status: :ok
      rescue StaffSessionRecovery::InvalidCsrf
        return render json: { error: 'Não foi possível validar a saída.' }, status: :forbidden
      end
    end
    if user && client
      user.with_lock do
        user.tokens.delete(client)
        user.save!
      end
      AuditLogger.log_logout(user: user, ip: request.remote_ip, user_agent: request.user_agent)
      if payload && payload['user_id'] == user.id && payload['client'] == client
        delete_staff_recovery_cookie
      end
    end
    @resource = nil
    @token.clear!
    render json: { success: true }, status: :ok
  end

  protected

  def render_create_success
    # OTP e verificação de novo IP já foram resolvidos no método create (antes do super).
    # Aqui chegamos apenas quando o login está 100% autorizado.

    # Só confirma o IP depois de concluir a autenticação e criar a sessão.
    @resource.add_trusted_ip!(ip: request.remote_ip)

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

    payload, csrf = StaffSessionRecovery.issue!(@resource, @token.client)
    write_staff_recovery_cookie(payload)
    render json: { data: user_data, staff_csrf_token: csrf }
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

  # Revalida sob lock para não emitir sessão se a senha/conta mudar durante o login.
  def create_and_assign_token
    @resource.with_lock do
      unless @resource.active_for_authentication? && %w[owner employee super_admin].include?(@resource.role) &&
             @resource.valid_password?(params[:password])
        raise LoginStateChanged
      end
      device = sanitized_device_token
      metadata = device.present? ? { device_digest: Digest::SHA256.hexdigest(device) } : {}
      @token = @resource.create_token(**metadata)
      @resource.save!
    end
  end

  def login_params
    params.permit(:email, :password, :otp_code, :device_token)
  end

  # Registra metadata da sessão (IP, User Agent, device)
  def stamp_session_metadata
    return unless @resource && @token&.client && response.successful?

    @resource.with_lock do
      entry = @resource.tokens[@token.client]
      return unless entry
      entry['ua'] = request.user_agent.to_s[0, 200]
      entry['ip'] = request.remote_ip
      entry['name'] ||= device_friendly_name(request.user_agent)
      entry['last_seen_at'] = Time.current.to_i
      @resource.update_columns(tokens: @resource.tokens, updated_at: Time.current)
    end
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
