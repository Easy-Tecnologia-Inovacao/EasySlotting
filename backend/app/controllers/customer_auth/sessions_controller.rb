# app/controllers/customer_auth/sessions_controller.rb
# Login de customers por estabelecimento (slug).
# Refresh token é armazenado em httpOnly cookie (proteção contra XSS).
# Access token é retornado no body (curta duração, menos risco).
# Audit log registra todas as tentativas de login.

class CustomerAuth::SessionsController < ApplicationController
  wrap_parameters false
  include LoginInput

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
                      BCrypt::Password.new(Customer::DUMMY_PASSWORD_DIGEST) == params[:password]
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

    device_token = sanitized_device_token
    raw_otp = params[:otp_code]
    if raw_otp.present?
      unless customer.verify_login_otp(raw_otp, ip: request.remote_ip, device_token: device_token)
        return render json: { error: 'Código de verificação inválido ou expirado.' }, status: :unauthorized
      end
    elsif !customer.first_successful_login? && !customer.trusted_device?(ip: request.remote_ip, device_token: device_token)
      code = customer.generate_login_otp!(ip: request.remote_ip, device_token: device_token)
      if code
        SecurityAlertMailer.login_verification_code(
          user: customer, otp_code: code, ip: request.remote_ip,
          user_agent: request.user_agent, location: AuditLogger.geolocate(request.remote_ip)
        ).deliver_later
      end
      return render json: { requires_verification: true, email_masked: mask_email(customer.email),
                            methods: [{ id: 'email', name: 'Código via E-mail', active: true }] }
    end

    tokens = customer.with_lock do
      unless customer.active? && customer.authenticate(params[:password])
        raise CustomerAuthenticatable::TokenInvalidError
      end
      customer.add_trusted_device!(ip: request.remote_ip, device_token: device_token)
      customer.customer_sessions.where('expires_at <= ?', Time.current).delete_all
      session = customer.customer_sessions.build(session_id: SecureRandom.uuid,
        expires_at: CustomerJwt::REFRESH_TOKEN_EXPIRATION.seconds.from_now)
      issue_tokens(customer, establishment, session: session)
    end
    write_auth_cookies(tokens)
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
      access_token: tokens.fetch(:access_token),
      token_type:   'Bearer',
      expires_in:   tokens.fetch(:expires_in),
      csrf_token:   tokens.fetch(:csrf_token),
      customer:     customer_data
    }, status: :ok
  end

  # POST /api/customer_auth/:slug/refresh
  def refresh
    establishment = find_establishment
    return unless establishment
    return render_csrf_error unless valid_csrf_token?

    raw_token = cookies.encrypted[:refresh_token]
    payload = CustomerJsonWebToken.decode_refresh_token(raw_token)
    customer = establishment.customers.find_by(id: payload[:customer_id], active: true)
    tokens = nil
    if customer && payload[:establishment_id] == establishment.id
      customer.with_lock do
        session = customer.customer_sessions.active.find_by(session_id: payload[:sid])
        if customer.valid_auth_session?(payload[:sid]) && session&.refresh_matches?(raw_token) &&
           session.csrf_matches?(request.headers['X-CSRF-Token'])
          tokens = issue_tokens(customer, establishment, session: session)
        end
      end
    end
    # Uma requisição obsoleta nunca revoga uma sessão mais recente.
    return render_session_error unless tokens

    write_auth_cookies(tokens)
    expired = customer.password_changed_at.nil? || customer.password_changed_at < 90.days.ago
    render json: tokens.except(:refresh_token).merge(token_type: 'Bearer',
      expires_in: tokens.fetch(:expires_in),
      customer: customer.as_safe_json.merge(password_expired: expired))
  rescue CustomerAuthenticatable::TokenExpiredError, CustomerAuthenticatable::TokenInvalidError
    render_session_error
  end

  # DELETE /api/customer_auth/:slug/sign_out
  def destroy
    establishment = find_establishment
    return unless establishment

    customer = begin
      resolve_customer_from_token
    rescue CustomerAuthenticatable::TokenExpiredError, CustomerAuthenticatable::TokenInvalidError
      nil
    end
    if customer
      return render_session_error unless customer.establishment_id == establishment.id
      session_id = current_customer_session.session_id
    elsif cookies.encrypted[:refresh_token].present?
      return render_csrf_error unless valid_csrf_token?
      payload = CustomerJsonWebToken.decode_refresh_token(cookies.encrypted[:refresh_token])
      return render_session_error unless payload[:establishment_id] == establishment.id
      if request.headers['Authorization'].present?
        # Uma aba antiga pode enviar Bearer A e cookie B compartilhado. Mesmo
        # com A expirado, não permitir que esse logout revogue outra sessão.
        match = request.headers['Authorization'].match(/\ABearer ([^\s]+)\z/i)
        return render_session_error unless match
        begin
          expected = CustomerJsonWebToken.decode_access_token(match[1], allow_expired: true)
        rescue CustomerAuthenticatable::TokenExpiredError, CustomerAuthenticatable::TokenInvalidError
          return render_session_error
        end
        return render_session_error unless %i[customer_id establishment_id sid].all? { |key| expected[key] == payload[key] }
      end
      customer = establishment.customers.find_by(id: payload[:customer_id])
      session_id = payload[:sid]
      cookie_auth = true
    end

    if customer
      customer.with_lock do
        session = customer.customer_sessions.active.find_by(session_id: session_id)
        if session && (!cookie_auth || (session.refresh_matches?(cookies.encrypted[:refresh_token]) &&
                                       session.csrf_matches?(request.headers['X-CSRF-Token'])))
          session.destroy!
        end
      end
      AuditLogger.log_logout(user: customer, ip: request.remote_ip, user_agent: request.user_agent)
    end
    clear_auth_cookies
    render json: { message: 'Logout realizado com sucesso.' }
  rescue CustomerAuthenticatable::TokenExpiredError, CustomerAuthenticatable::TokenInvalidError
    # Token expirado: logout por cookie exige ainda a proteção CSRF.
    return render_csrf_error unless valid_csrf_token?
    clear_auth_cookies
    render json: { message: 'Logout realizado com sucesso.' }
  end

  private

  def issue_tokens(customer, establishment, session:)
    claims = { customer_id: customer.id, establishment_id: establishment.id, sid: session.session_id }
    refresh_token = CustomerJsonWebToken.encode_refresh_token(claims, exp: session.expires_at)
    csrf_token = SecureRandom.hex(32)
    session.update!(refresh_token_digest: Digest::SHA256.hexdigest(refresh_token),
                    csrf_token_digest: Digest::SHA256.hexdigest(csrf_token))
    access_expiry = [CustomerJwt::ACCESS_TOKEN_EXPIRATION.seconds.from_now, session.expires_at].min
    { access_token: CustomerJsonWebToken.encode_access_token(claims, exp: access_expiry),
      refresh_token: refresh_token, csrf_token: csrf_token,
      expires_in: [access_expiry.to_i - Time.current.to_i, 0].max, refresh_expires_at: session.expires_at }
  end

  def write_auth_cookies(tokens)
    attributes = { httponly: true, secure: request.ssl? || Rails.env.production?, same_site: :strict,
                   expires: tokens.fetch(:refresh_expires_at), path: '/api/customer_auth' }
    cookies.encrypted[:refresh_token] = attributes.merge(value: tokens.fetch(:refresh_token))
    cookies.encrypted[:csrf_token] = attributes.merge(value: tokens.fetch(:csrf_token))
  end

  def valid_csrf_token?
    supplied = request.headers['X-CSRF-Token']
    stored = cookies.encrypted[:csrf_token]
    supplied.present? && stored.present? && ActiveSupport::SecurityUtils.secure_compare(supplied, stored)
  end

  def render_csrf_error
    render json: { error: 'Não foi possível validar a requisição.' }, status: :forbidden
  end

  def render_session_error
    render json: { error: 'Sessão inválida ou expirada. Faça login novamente.' }, status: :unauthorized
  end

  def find_establishment
    est = Establishment.find_by(slug: params[:slug], active: true)
    render json: { error: 'Estabelecimento não encontrado.' }, status: :not_found unless est
    est
  end

  def clear_auth_cookies
    cookies.delete(:refresh_token, path: '/api/customer_auth')
    cookies.delete(:csrf_token, path: '/api/customer_auth')
    cookies.delete(:csrf_token, path: '/')
  end

  def mask_email(email)
    name, domain = email.split('@', 2)
    "#{name[0]}***@#{domain}"
  end
end
