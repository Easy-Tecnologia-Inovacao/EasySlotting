class CustomerAuth::PasswordsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :require_login, raise: false
  skip_before_action :set_user_by_token, raise: false
  skip_before_action :validate_password_expiration!, raise: false

  RESET_TOKEN_EXPIRATION = 30.minutes
  COOLDOWN_SECONDS = 60

  # POST /customer_auth/:slug/forgot_password
  def create
    establishment = find_establishment
    return unless establishment

    email = params[:email].to_s.downcase.strip
    customer = establishment.customers.find_by(email: email)

    if customer.present?
      # Rate limiting: cooldown entre solicitações
      if customer.reset_password_sent_at.present? && customer.reset_password_sent_at > COOLDOWN_SECONDS.ago
        remaining = (customer.reset_password_sent_at + COOLDOWN_SECONDS - Time.current).to_i
        return render json: {
          message: 'Se o e-mail estiver cadastrado, você receberá um link para redefinir sua senha.',
          cooldown: remaining
        }, status: :ok
      end

      raw_token = SecureRandom.urlsafe_base64(32)
      customer.update!(
        reset_password_token: Digest::SHA256.hexdigest(raw_token),
        reset_password_sent_at: Time.current
      )

      frontend_url = Rails.configuration.x.frontend_url.to_s.chomp('/')
      reset_url = "#{frontend_url}/empresa/#{params[:slug]}/redefinir-senha?reset_password_token=#{raw_token}"

      CustomerMailer.password_reset(customer, reset_url).deliver_later

      AuditLogger.log(
        action: 'password_reset_request',
        user: customer,
        establishment: establishment,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        details: { event: 'password_reset_request', email: customer.email }
      )
    end

    # Resposta genérica sempre (não revela se o email existe — LGPD)
    render json: {
      message: 'Se o e-mail estiver cadastrado, você receberá um link para redefinir sua senha.'
    }, status: :ok
  end

  # PUT /customer_auth/:slug/reset_password
  def update
    establishment = find_establishment
    return unless establishment

    raw_token = params[:reset_password_token].to_s.strip
    if raw_token.blank?
      return render json: { errors: ['Token de redefinição é obrigatório.'] }, status: :unprocessable_entity
    end

    token_hash = Digest::SHA256.hexdigest(raw_token)
    customer = establishment.customers.find_by(
      reset_password_token: token_hash,
      active: true
    )

    unless customer
      return render json: { errors: ['Link de redefinição inválido ou expirado. Solicite um novo link.'] }, status: :unprocessable_entity
    end

    if customer.reset_password_sent_at.present? && customer.reset_password_sent_at < RESET_TOKEN_EXPIRATION.ago
      customer.update!(reset_password_token: nil, reset_password_sent_at: nil)
      return render json: { errors: ['Link de redefinição expirado. Solicite um novo link.'] }, status: :unprocessable_entity
    end

    password = params[:password].to_s
    password_confirmation = params[:password_confirmation].to_s

    if password.blank? || password_confirmation.blank?
      return render json: { errors: ['Preencha a nova senha e a confirmação.'] }, status: :unprocessable_entity
    end

    if password != password_confirmation
      return render json: { errors: ['As senhas não coincidem.'] }, status: :unprocessable_entity
    end

    customer.password = password
    customer.password_confirmation = password_confirmation
    customer.reset_password_token = nil
    customer.reset_password_sent_at = nil
    customer.refresh_token = nil
    customer.refresh_token_expires_at = nil

    if customer.save
      AuditLogger.log_password_reset(
        user: customer,
        ip: request.remote_ip,
        user_agent: request.user_agent
      )

      render json: { success: true, message: 'Senha redefinida com sucesso.' }, status: :ok
    else
      render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_establishment
    est = Establishment.find_by(slug: params[:slug], active: true)
    render json: { error: 'Estabelecimento não encontrado.' }, status: :not_found unless est
    est
  end
end
