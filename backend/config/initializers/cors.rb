Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.development?
      # Em desenvolvimento: aceita qualquer IP local automaticamente.
      # Cobre localhost, 127.0.0.1, 192.168.x.x, 172.x.x.x e 10.x.x.x
      # assim o CORS não quebra quando o IP da máquina muda.
      origins do |source, _env|
        source =~ /\Ahttp:\/\/(localhost|127\.0\.0\.1|192\.168\.\d+\.\d+|172\.\d+\.\d+\.\d+|10\.\d+\.\d+\.\d+)(:\d+)?\z/
      end
    else
      # Em produção: usa lista explícita da variável de ambiente.
      allowed_origins = ENV.fetch('ALLOWED_ORIGINS', '').split(',').map(&:strip).reject(&:empty?)
      origins(*allowed_origins)
    end

    resource '/api/*',
      headers: :any,
      expose: ['access-token', 'expiry', 'token-type', 'uid', 'client', 'X-Device-Token'],
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 86400
  end
end