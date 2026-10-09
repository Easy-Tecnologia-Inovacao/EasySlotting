# app/services/customer_json_web_token.rb
# Serviço para codificação e decodificação de tokens JWT de customers.
# Suporta access tokens (curta duração) e refresh tokens (longa duração).

class CustomerJsonWebToken
  ALGORITHM = 'HS256'.freeze
  ISSUER = 'easyslotting'.freeze
  AUDIENCE = 'customer'.freeze

  class << self
    # Gera um access token JWT com expiração curta (15 minutos por padrão)
    def encode_access_token(payload, exp: 15.minutes.from_now)
      payload = payload.dup
      payload[:exp] = exp.to_i
      payload[:type] = 'access'
      payload[:iss] = ISSUER
      payload[:aud] = AUDIENCE
      JWT.encode(payload, secret, ALGORITHM)
    end

    # Gera um refresh token JWT com expiração longa (7 dias)
    def encode_refresh_token(payload, exp: 7.days.from_now)
      payload = payload.dup
      payload[:exp] = exp.to_i
      payload[:type] = 'refresh'
      payload[:iss] = ISSUER
      payload[:aud] = AUDIENCE
      payload[:jti] = SecureRandom.uuid # Identificador único do token
      JWT.encode(payload, refresh_secret, ALGORITHM)
    end

    # Decodifica access token
    def decode_access_token(token, allow_expired: false)
      # allow_expired é exclusivo para comparar a identidade no fallback de
      # logout. Nunca autoriza acesso; esse caminho ainda exige refresh/CSRF.
      decoded = JWT.decode(token, secret, true, decode_options.merge(verify_expiration: !allow_expired))
      payload = HashWithIndifferentAccess.new(decoded.first)
      raise CustomerAuthenticatable::TokenInvalidError, 'Token inválido: tipo incorreto' if payload[:type] != 'access'
      payload
    rescue JWT::ExpiredSignature
      raise CustomerAuthenticatable::TokenExpiredError
    rescue JWT::DecodeError
      raise CustomerAuthenticatable::TokenInvalidError
    end

    # Decodifica refresh token
    def decode_refresh_token(token)
      decoded = JWT.decode(token, refresh_secret, true, decode_options)
      payload = HashWithIndifferentAccess.new(decoded.first)
      raise CustomerAuthenticatable::TokenInvalidError, 'Token inválido: tipo incorreto' if payload[:type] != 'refresh'
      payload
    rescue JWT::ExpiredSignature
      raise CustomerAuthenticatable::TokenExpiredError
    rescue JWT::DecodeError
      raise CustomerAuthenticatable::TokenInvalidError
    end

    private

    def decode_options
      { algorithm: ALGORITHM, verify_iss: true, iss: ISSUER, verify_aud: true, aud: AUDIENCE,
        required_claims: %w[exp iss aud type customer_id establishment_id sid] }
    end

    def secret
      CustomerJwt::SECRET_KEY
    end

    def refresh_secret
      CustomerJwt::REFRESH_SECRET_KEY
    end
  end
end
