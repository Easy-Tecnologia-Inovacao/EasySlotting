# app/controllers/customer_auth/registrations_controller.rb
# Cadastro de customers por estabelecimento (slug).
# Boas práticas:
#  - Parâmetros sanitizados via strong parameters (incluindo phone e cellphone)
#  - Validação estrita de consentimento LGPD (Termos de Uso e Política de Privacidade)
#  - Sanitização e vinculação de device_token (trusted device)
#  - Operações atômicas com ActiveRecord::Base.transaction
#  - Resposta imediata com token e sessão segura

class CustomerAuth::RegistrationsController < ApplicationController
  wrap_parameters false

  def create
    establishment = find_establishment
    return unless establishment

    unless params[:consent_terms] == true
      return render json: { errors: ['Você precisa aceitar os Termos de Uso para se cadastrar.'] }, status: :unprocessable_entity
    end

    unless params[:consent_privacy] == true
      return render json: { errors: ['Você precisa aceitar a Política de Privacidade para se cadastrar.'] }, status: :unprocessable_entity
    end

    # Sanitização e validação estrita do device_token (proteção contra payload DoS / injeção)
    raw_device_token = request.headers['X-Device-Token'].presence || params[:device_token].presence
    device_token = if raw_device_token.is_a?(String) && raw_device_token.strip.match?(/\A[a-zA-Z0-9_\-]{8,64}\z/)
                     raw_device_token.strip
                   else
                     nil
                   end

    customer = establishment.customers.new(customer_params)
    customer.consent_terms_at = Time.current
    customer.consent_privacy_at = Time.current

    created = false
    access_token = nil
    csrf_token = nil
    customer_data = nil

    ActiveRecord::Base.transaction do
      if customer.save
        # Gera access token (curta duração — 15 minutos)
        access_token = CustomerJsonWebToken.encode_access_token(
          { customer_id: customer.id, establishment_id: establishment.id }
        )

        # Gera refresh token (longa duração — 7 dias)
        refresh_token = CustomerJsonWebToken.encode_refresh_token(
          { customer_id: customer.id, establishment_id: establishment.id }
        )

        # Adiciona IP e device_token confiáveis
        customer.add_trusted_device!(ip: request.remote_ip, device_token: device_token)

        # Salva hash do refresh token no banco
        customer.update!(
          refresh_token: Digest::SHA256.hexdigest(refresh_token),
          refresh_token_expires_at: CustomerJwt::REFRESH_TOKEN_EXPIRATION.seconds.from_now
        )

        # Gera CSRF token
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
        created = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if created
      AuditLogger.log_login_success(
        user: customer,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        establishment: establishment
      )

      render json: {
        message:      'Conta criada com sucesso!',
        access_token: access_token,
        token_type:   'Bearer',
        expires_in:   CustomerJwt::ACCESS_TOKEN_EXPIRATION,
        csrf_token:   csrf_token,
        customer:     customer_data
      }, status: :created
    else
      render json: {
        errors: customer.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def find_establishment
    est = Establishment.find_by(slug: params[:slug], active: true)
    render json: { error: 'Estabelecimento não encontrado.' }, status: :not_found unless est
    est
  end

  def customer_params
    params.permit(:name, :email, :password, :password_confirmation, :phone, :cellphone)
  end
end
