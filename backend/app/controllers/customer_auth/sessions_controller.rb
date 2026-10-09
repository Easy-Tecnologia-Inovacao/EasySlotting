# app/controllers/customer_auth/sessions_controller.rb
# Login de customers por estabelecimento (slug).
# Refresh token é armazenado em httpOnly cookie (proteção contra XSS).
# Access token é retornado no body (curta duração, menos risco).
# Audit log registra todas as tentativas de login.

class CustomerAuth::SessionsController < ApplicationController
  wrap_parameters false

  def create
    establishment = find_establishment
    return unless establishment

    email = params[:email].to_s.downcase.strip
    customer = establishment.customers.find_by(email: email)

    # Verifica se a conta está bloqueada
    if customer&.access_locked?
      AuditLogger.log_login_failure(
        email: email,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        reason: 'account_locked'
      )
      return render json: { error: 'Conta bloqueada devido a múltiplas tentativas. Aguarde 30 minutos.' }, status: :forbidden
    end

    # Proteção contra timing attack / enumeração de contas:
    # Se o cliente não existir, executa o cálculo de hash BCrypt simulado para ter o mesmo tempo de resposta
    authenticated = if customer
                      customer.authenticate(params[:password].to_s)
                    else
                      # Executa BCrypt equivalente para equiparar o tempo de resposta
                      Customer.new(password: 'dummy_timing_protection_pwd').authenticate(params[:password].to_s)
                      false
                    end

    unless authenticated
      # Incrementa tentativas falhas e bloqueia se necessário
      customer&.increment_failed_attempts!

      AuditLogger.log_login_failure(
        email: email,
        ip: request.remote_ip,
        user_agent: request.user_agent
      )

      # Envia alerta de email se a conta acabou de ser bloqueada
      if customer&.access_locked?
        SecurityAlertMailer.account_locked(
          user: customer,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          locked_at: Time.current
        ).deliver_later
      end

      return render json: { error: 'E-mail ou senha inválidos.' }, status: :unauthorized
    end

    # Login bem-sucedido: reseta tentativas falhas
    customer.reset_failed_attempts!

    unless customer.active?
      AuditLogger.log_login_failure(
        email: email,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        reason: 'account_inactive'
      )
      return render json: { error: 'Sua conta está inativa. Entre em contato com o estabelecimento.' },
                    status: :unauthorized
    end

    raw_otp = params[:otp_code].to_s.strip
    is_otp_attempt = raw_otp.match?(/\A\d{6}\z/)

    # Validação e sanitização estrita do device_token (prevenção contra payload DoS / injeção)
    raw_device_token = request.headers['X-Device-Token'].presence || params[:device_token].presence
    device_token = if raw_device_token.is_a?(String) && raw_device_token.strip.match?(/\A[a-zA-Z0-9_\-]{8,64}\z/)
                     raw_device_token.strip
                   else
                     nil
                   end

    if is_otp_attempt
      unless customer.verify_login_otp(raw_otp)
        return render json: { error: 'Código de verificação inválido ou expirado.' }, status: :unauthorized
      end
      customer.add_trusted_device!(ip: request.remote_ip, device_token: device_token)
    else
      is_new_device = AuditLogger.new_device?(user: customer, ip: request.remote_ip, user_agent: request.user_agent)
      if is_new_device && !customer.trusted_device?(ip: request.remote_ip, device_token: device_token)
        # Cooldown de 60 segundos antes de reenviar e gerar novo código
        should_generate_new = customer.login_otp_code.blank? ||
                              customer.login_otp_sent_at.blank? ||
                              customer.login_otp_sent_at < 60.seconds.ago

        if should_generate_new
          code = customer.generate_login_otp!
          SecurityAlertMailer.login_verification_code(
            user: customer,
            otp_code: code,
            ip: request.remote_ip,
            user_agent: request.user_agent,
            location: AuditLogger.geolocate(request.remote_ip)
          ).deliver_later

          Rails.logger.info "[OTP] Código enviado para #{mask_email(customer.email)}: #{code}" if Rails.env.development?
        end

        return render json: {
          requires_verification: true,
          email_masked: mask_email(customer.email),
          methods: [
            { id: 'email', name: 'Código via E-mail', active: true },
            { id: 'totp', name: 'Aplicativo Autenticador (2FA)', active: false, badge: 'Em breve' }
          ]
        }, status: :ok
      else
        customer.add_trusted_device!(ip: request.remote_ip, device_token: device_token)
      end
    end

    # Gera access token (curta duração — 15 minutos)
    access_token = CustomerJsonWebToken.encode_access_token(
      { customer_id: customer.id, establishment_id: establishment.id }
    )

    # Gera refresh token (longa duração — 7 dias)
    refresh_token = CustomerJsonWebToken.encode_refresh_token(
      { customer_id: customer.id, establishment_id: establishment.id }
    )

    # Salva hash do refresh token no banco
    customer.update!(
      refresh_token: Digest::SHA256.hexdigest(refresh_token),
      refresh_token_expires_at: CustomerJwt::REFRESH_TOKEN_EXPIRATION.seconds.from_now
    )

    # Gera CSRF token para proteção adicional
    csrf_token = SecureRandom.hex(32)
    cookies.encrypted[:csrf_token] = {
      value: csrf_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict,
      expires: CustomerJwt::REFRESH_TOKEN_EXPIRATION.seconds.from_now
    }

    # Seta refresh token como httpOnly cookie
    cookies.encrypted[:refresh_token] = {
      value: refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict,
      expires: CustomerJwt::REFRESH_TOKEN_EXPIRATION.seconds.from_now,
      path: '/api/customer_auth'
    }

    is_expired = customer.password_changed_at.nil? || customer.password_changed_at < 90.days.ago
    customer_data = customer.as_safe_json.merge(password_expired: is_expired)

    # Registra login bem-sucedido
    AuditLogger.log_login_success(
      user: customer,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      establishment: establishment
    )

    # Verifica se é novo dispositivo e envia alerta
    if AuditLogger.new_device_alert?(user: customer, ip: request.remote_ip)
      SecurityAlertMailer.new_device_login(
        user: customer,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        device_info: AuditLogger.send(:device_info, request.user_agent),
        location: AuditLogger.geolocate(request.remote_ip),
        login_time: Time.current
      ).deliver_later
    end

    render json: {
      access_token: access_token,
      token_type:   'Bearer',
      expires_in:   CustomerJwt::ACCESS_TOKEN_EXPIRATION,
      csrf_token:   csrf_token,
      customer:     customer_data
    }, status: :ok
  end

  # POST /customer_auth/:slug/refresh
  def refresh
    establishment = find_establishment
    return unless establishment

    # Lê refresh token do httpOnly cookie
    refresh_token = cookies.encrypted[:refresh_token]
    return render json: { error: 'Refresh token não encontrado.' }, status: :unauthorized if refresh_token.blank?

    # Valida CSRF token (comparação segura contra timing attacks)
    csrf_token = request.headers['X-CSRF-Token']
    stored_csrf = cookies.encrypted[:csrf_token]
    if csrf_token.blank? || stored_csrf.blank? || !ActiveSupport::SecurityUtils.secure_compare(csrf_token, stored_csrf)
      return render json: { error: 'CSRF token inválido.' }, status: :forbidden
    end

    # Decodifica o refresh token
    begin
      payload = CustomerJsonWebToken.decode_refresh_token(refresh_token)
    rescue CustomerAuthenticatable::TokenExpiredError
      clear_auth_cookies
      return render json: { error: 'Refresh token expirado. Faça login novamente.' }, status: :unauthorized
    rescue CustomerAuthenticatable::TokenInvalidError
      clear_auth_cookies
      return render json: { error: 'Refresh token inválido.' }, status: :unauthorized
    end

    # Verifica se pertence a este estabelecimento
    if payload[:establishment_id] != establishment.id
      clear_auth_cookies
      return render json: { error: 'Refresh token inválido para este estabelecimento.' }, status: :unauthorized
    end

    # Busca o customer
    customer = Customer.find_by(
      id: payload[:customer_id],
      establishment_id: establishment.id,
      active: true
    )

    unless customer
      clear_auth_cookies
      return render json: { error: 'Cliente não encontrado ou inativo.' }, status: :unauthorized
    end

    # Verifica se o refresh token está no banco (comparação segura contra timing attacks)
    token_hash = Digest::SHA256.hexdigest(refresh_token)
    if customer.refresh_token.blank? || !ActiveSupport::SecurityUtils.secure_compare(customer.refresh_token, token_hash)
      # Possível uso de token roubado — invalida todos os tokens
      customer.update!(refresh_token: nil, refresh_token_expires_at: nil)
      clear_auth_cookies
      return render json: { error: 'Refresh token inválido. Faça login novamente.' }, status: :unauthorized
    end

    # Verifica se não expirou
    if customer.refresh_token_expires_at.present? && customer.refresh_token_expires_at < Time.current
      customer.update!(refresh_token: nil, refresh_token_expires_at: nil)
      clear_auth_cookies
      return render json: { error: 'Refresh token expirado. Faça login novamente.' }, status: :unauthorized
    end

    # Gera novos tokens (rotação)
    new_access_token = CustomerJsonWebToken.encode_access_token(
      { customer_id: customer.id, establishment_id: establishment.id }
    )

    new_refresh_token = CustomerJsonWebToken.encode_refresh_token(
      { customer_id: customer.id, establishment_id: establishment.id }
    )

    # Atualiza o refresh token no banco
    customer.update!(
      refresh_token: Digest::SHA256.hexdigest(new_refresh_token),
      refresh_token_expires_at: CustomerJwt::REFRESH_TOKEN_EXPIRATION.seconds.from_now
    )

    # Novo CSRF token
    new_csrf_token = SecureRandom.hex(32)
    cookies.encrypted[:csrf_token] = {
      value: new_csrf_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict,
      expires: CustomerJwt::REFRESH_TOKEN_EXPIRATION.seconds.from_now
    }

    # Seta novo refresh token como httpOnly cookie
    cookies.encrypted[:refresh_token] = {
      value: new_refresh_token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :strict,
      expires: CustomerJwt::REFRESH_TOKEN_EXPIRATION.seconds.from_now,
      path: '/api/customer_auth'
    }

    is_expired = customer.password_changed_at.nil? || customer.password_changed_at < 90.days.ago
    customer_data = customer.as_safe_json.merge(password_expired: is_expired)

    render json: {
      access_token: new_access_token,
      token_type:   'Bearer',
      expires_in:   CustomerJwt::ACCESS_TOKEN_EXPIRATION,
      csrf_token:   new_csrf_token,
      customer:     customer_data
    }, status: :ok
  end

  # DELETE /customer_auth/:slug/sign_out
  def destroy
    # Invalida o refresh token no banco
    refresh_token = cookies.encrypted[:refresh_token]
    if refresh_token.present?
      token_hash = Digest::SHA256.hexdigest(refresh_token)
      customer = Customer.find_by(refresh_token: token_hash)
      if customer
        customer.update!(refresh_token: nil, refresh_token_expires_at: nil)
        # Registra logout
        AuditLogger.log_logout(
          user: customer,
          ip: request.remote_ip,
          user_agent: request.user_agent
        )
      end
    end

    clear_auth_cookies

    render json: { message: 'Logout realizado com sucesso.' }, status: :ok
  end

  private

  def find_establishment
    est = Establishment.find_by(slug: params[:slug], active: true)
    render json: { error: 'Estabelecimento não encontrado.' }, status: :not_found unless est
    est
  end

  def clear_auth_cookies
    cookies.delete(:refresh_token, path: '/api/customer_auth')
    cookies.delete(:csrf_token)
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
