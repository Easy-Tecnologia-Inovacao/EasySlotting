# config/initializers/rack_attack.rb

class Rack::Attack
  # Rack não interpreta JSON em req.params; o login Vue envia application/json.
  def self.login_email(request)
    body = request.body
    raw = body.read(4097)
    body.rewind
    return if raw.bytesize > 4096
    data = JSON.parse(raw)
    email = data.is_a?(Hash) ? data['email'] : nil
    Digest::SHA256.hexdigest(email.strip.downcase) if email.is_a?(String) && email.bytesize <= 254
  rescue JSON::ParserError, IOError
    nil
  end

  # 1. Throttle por IP para qualquer requisição (Evita DoS genérico)
  # 100 requisições a cada 1 minuto por IP
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end

  # 2. Proteção de Login de Staff (Devise)
  # Bloqueia se houver mais de 5 tentativas de POST /api/devise_users/sign_in em 1 minuto
  throttle('logins/staff', limit: 5, period: 1.minute) do |req|
    if req.path.include?('/devise_users/') && req.path.include?('sign_in') && req.post?
      req.ip
    end
  end

  throttle('logins/staff/email', limit: 5, period: 1.minute) do |req|
    Rack::Attack.login_email(req) if req.path == '/api/devise_users/sign_in' && req.post?
  end

  # 3. Proteção de Login de Cliente (JWT Custom) por IP
  throttle('staff_recovery/ip', limit: 20, period: 1.minute) do |req|
    req.ip if req.path == '/api/devise_users/restore_session' && req.post?
  end

  throttle('logins/customer/ip', limit: 5, period: 1.minute) do |req|
    if req.path.include?('/customer_auth/') && req.path.include?('/sign_in') && req.post?
      req.ip
    end
  end

  # 3b. Proteção de Login de Cliente por E-mail (evita brute-force distribuído com IPs rotativos)
  throttle('logins/customer/email', limit: 5, period: 1.minute) do |req|
    if req.path.include?('/customer_auth/') && req.path.include?('/sign_in') && req.post?
      email = Rack::Attack.login_email(req)
      "#{req.path}:#{email}" if email
    end
  end

  # 4. Proteção contra Email Flooding (Password Reset)
  # 3 solicitações a cada 5 minutos por IP
  throttle('password_resets/ip', limit: 3, period: 5.minutes) do |req|
    if req.path.include?('password') && req.post?
      req.ip
    end
  end

  # 5. Proteção de Uploads (Evitar DoS por upload massivo - logos, banners e avatares de clientes)
  # Limita uploads a 5 por minuto por IP
  throttle('uploads/ip', limit: 5, period: 1.minute) do |req|
    if (req.path.include?('/upload_logo') || req.path.include?('/upload_banner') || req.path.include?('/upload_image')) && req.post?
      req.ip
    end
  end

  # 5b. Proteção de Troca de Senha (evita brute force da senha atual em contas de clientes e usuários)
  # Limita a 5 tentativas a cada 10 minutos por IP
  throttle('change_password/ip', limit: 5, period: 10.minutes) do |req|
    if req.path.include?('/change_password') && (req.post? || req.patch?)
      req.ip
    end
  end

  # Exclusão requer reautenticação; limita tentativas de senha nesta ação.
  throttle('customer_account_delete/ip', limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == '/api/customer/profile' && req.delete?
  end

  # 6. Proteção de Endpoints Administrativos
  # Limita requisições administrativas a 45 por minuto por IP
  throttle('admin/ip', limit: 45, period: 1.minute) do |req|
    if req.path.start_with?('/api/admin/', '/api/super_admin/') || req.path.include?('/admin/')
      req.ip
    end
  end

  # 6b. Throttle por user autenticado (protege contra proxy rotativo)
  throttle('admin/user', limit: 60, period: 1.minute) do |req|
    if req.path.start_with?('/api/admin/') && req.env['HTTP_UID']
      req.env['HTTP_UID']
    end
  end

  # 6c. Throttle por user para endpoints de account
  throttle('account/user', limit: 30, period: 1.minute) do |req|
    if req.path.start_with?('/api/me/') && req.env['HTTP_UID']
      req.env['HTTP_UID']
    end
  end

  # 7. Proteção para modificações de Serviços e Pacotes (POST, PUT, DELETE)
  # Limita escritas a 15 por minuto por IP para evitar cadastros automatizados massivos
  throttle('services_write/ip', limit: 15, period: 1.minute) do |req|
    if (req.post? || req.put? || req.patch? || req.delete?) &&
       (req.path.include?('/services') || req.path.include?('/service_packages'))
      req.ip
    end
  end

  # 8. Proteção para Agendamentos (POST /appointments)
  # Limita criação de agendamentos a 10 por minuto por IP para evitar spam/flooding de reservas
  throttle('appointments_create/ip', limit: 10, period: 1.minute) do |req|
    if req.path.include?('/appointments') && req.post?
      req.ip
    end
  end

  # 8b. Proteção para Cancelamento/Reagendamento de Agendamentos (PATCH)
  # Limita cancelamentos e reagendamentos a 10 por minuto por IP
  throttle('appointments_write/ip', limit: 10, period: 1.minute) do |req|
    if req.path.include?('/appointments') && (req.patch? || req.delete?) && req.ip
    end
  end

  # 9. Proteção para Assinaturas (POST /subscriptions e cancelamentos)
  # Limita a 5 requisições por minuto por IP para evitar automações maliciosas em planos
  throttle('subscriptions_write/ip', limit: 5, period: 1.minute) do |req|
    if (req.path.include?('/subscriptions') || req.path.include?('/cancel')) && (req.post? || req.patch?)
      req.ip
    end
  end

  # 9b. Proteção para Cancelamento de Pacotes por Token JWT
  # Mesmo que o atacante rotacione IPs, o token permanece fixo.
  # Limita a 5 cancelamentos por hora por token (alinha com o rate limit do controller via AuditLog).
  throttle('service_packages_cancel/token', limit: 5, period: 1.hour) do |req|
    if req.path.match?(%r{/api/customer/service_packages/\d+/cancel}) && req.patch?
      auth_header = req.env['HTTP_AUTHORIZATION'].to_s
      token = auth_header.sub(/\ABearer\s+/i, '').strip.presence
      token
    end
  end

  # 10. Proteção para Onboarding de Empresas (POST /owner_onboarding)
  # Endpoint público sem autenticação — limitar a 3 cadastros por hora por IP
  # para bloquear bots de criar contas de proprietário em massa.
  throttle('onboarding/ip', limit: 3, period: 1.hour) do |req|
    if req.path.include?('/owner_onboarding') && req.post?
      req.ip
    end
  end

  # 11. Proteção para Cadastro de Clientes (POST /customer_auth/:slug/sign_up)
  # Limita a 5 cadastros a cada 10 minutos por IP para bloquear bots
  throttle('customer_signup/ip', limit: 5, period: 10.minutes) do |req|
    if req.path.include?('/customer_auth/') && req.path.include?('/sign_up') && req.post?
      req.ip
    end
  end

  # 12. Proteção para Refresh Token (POST /customer_auth/:slug/refresh)
  # Limita a 10 refreshes por minuto por IP para evitar abuso
  throttle('customer_refresh/ip', limit: 10, period: 1.minute) do |req|
    if req.path.include?('/customer_auth/') && req.path.include?('/refresh') && req.post?
      req.ip
    end
  end

  # 13. Proteção para Escrita de Horários (PATCH /admin/team/:id/schedule e /admin/team/bulk_schedule)
  # Limita modificações de agenda a 10 por minuto por IP para evitar DoS por transações pesadas
  throttle('schedule_write/ip', limit: 10, period: 1.minute) do |req|
    if req.patch? && req.path.include?('/team/') && req.path.include?('/schedule')
      req.ip
    end
  end

  # 14. Proteção para Leitura de Todas as Agendas (GET /admin/team/all_schedules)
  # Limita leitura de dados sensíveis a 20 por minuto por IP para evitar scraping
  throttle('schedule_read/ip', limit: 20, period: 1.minute) do |req|
    if req.get? && req.path.include?('/team/all_schedules')
      req.ip
    end
  end

  # 15. Proteção para Ações de Agendamento do Cliente (POST/PATCH/DELETE /customer/appointments)
  # Limita a 30 ações por minuto por IP para evitar spam de agendamento, cancelamento ou reagendamento
  throttle('customer_appointments_actions/ip', limit: 30, period: 1.minute) do |req|
    if req.path.start_with?('/api/customer/appointments') && (req.post? || req.patch? || req.delete?)
      req.ip
    end
  end

  # 16. Proteção para Leitura do Histórico de Agendamentos por Token JWT (Falha 5b)
  # O throttle genérico por IP (regra 1) não impede scraping com token válido via IPs rotativos.
  # Limita leituras do histórico a 30 por minuto por Bearer token — mesmo token, mesmo limite.
  throttle('customer_history_read/token', limit: 30, period: 1.minute) do |req|
    if req.get? && req.path.end_with?('/customer/appointments/history')
      auth_header = req.env['HTTP_AUTHORIZATION'].to_s
      token = auth_header.sub(/\ABearer\s+/i, '').strip.presence
      token
    end
  end

  # Resposta customizada ao ser bloqueado (inclui Retry-After para bots bem comportados)
  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data']
    # O Rack Attack 6.8 pode fornecer um Request em match_data, não um Hash.
    # Nunca deixe o responder de rate limit gerar um 500 secundário.
    retry_after = if match_data.respond_to?(:[])
                    (match_data[:period] || match_data['period']).to_s
                  elsif match_data.respond_to?(:period)
                    match_data.period.to_s
                  else
                    '60'
                  end
    retry_after = '60' if retry_after.blank? || retry_after == '0'

    [ 429,  # Too Many Requests
      { 'Content-Type' => 'application/json', 'Retry-After' => retry_after },
      [{ error: "Muitas requisições. Por favor, aguarde antes de tentar novamente." }.to_json]
    ]
  end
end
