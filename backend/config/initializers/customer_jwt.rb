# config/initializers/customer_jwt.rb
# Configuração centralizada do JWT para autenticação de customers
# Suporta access tokens e refresh tokens com secrets separados

module CustomerJwt
  SECRET_KEY = ENV.fetch('CUSTOMER_JWT_SECRET') do
    if Rails.env.production?
      raise 'CUSTOMER_JWT_SECRET não está definida. Configure esta variável de ambiente em produção.'
    end
    Rails.application.secret_key_base
  end

  REFRESH_SECRET_KEY = ENV.fetch('CUSTOMER_JWT_REFRESH_SECRET') do
    if Rails.env.production?
      raise 'CUSTOMER_JWT_REFRESH_SECRET não está definida. Configure esta variável de ambiente em produção.'
    end
    OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, 'customer_refresh_token')
  end

  ACCESS_TOKEN_EXPIRATION = 15.minutes.to_i  # 15 minutos
  REFRESH_TOKEN_EXPIRATION = 7.days.to_i     # 7 dias
end
