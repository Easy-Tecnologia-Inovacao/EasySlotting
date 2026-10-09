# app/services/audit_logger.rb
# Service para registrar eventos de auditoria no banco.
# Uso: AuditLogger.log(action: 'login', user: user, ip: request.remote_ip, details: { ... })

require 'net/http'
require 'json'

class AuditLogger
  # Registra um evento de auditoria
  # @param action [String] Ação realizada (ex: 'login', 'logout', 'password_change')
  # @param user [User, Customer, nil] Usuário que realizou a ação
  # @param establishment [Establishment, nil] Estabelecimento relacionado
  # @param ip [String] Endereço IP do cliente
  # @param user_agent [String] User-Agent do navegador
  # @param details [Hash] Detalhes adicionais (device, browser, etc.)
  # @param auditable [ApplicationRecord, nil] Objeto relacionado (polymorphic)
  def self.log(action:, user: nil, establishment: nil, ip: nil, user_agent: nil, details: {}, auditable: nil)
    user_record = user.is_a?(User) ? user : nil
    auditable_record = auditable || (user.is_a?(Customer) ? user : nil)

    AuditLog.create!(
      action: action,
      user: user_record,
      establishment: establishment,
      ip_address: ip,
      details: details.merge(
        user_agent: user_agent.to_s[0, 500],
        timestamp: Time.current.iso8601
      ),
      auditable: auditable_record
    )
  rescue => e
    # Nunca falha a request principal por erro de audit log
    Rails.logger.error("[AuditLogger] Falha ao registrar audit log: #{e.message}")
    nil
  end

  # Registra tentativa de login bem-sucedida
  def self.log_login_success(user:, ip:, user_agent:, establishment: nil)
    details = {
      event: 'login_success',
      device: device_info(user_agent),
      location: geolocate(ip)
    }

    log(
      action: 'login',
      user: user,
      establishment: establishment,
      ip: ip,
      user_agent: user_agent,
      details: details
    )
  end

  # Registra tentativa de login falha
  def self.log_login_failure(email:, ip:, user_agent:, reason: 'invalid_credentials')
    details = {
      event: 'login_failure',
      email_attempted: email,
      reason: reason,
      device: device_info(user_agent),
      location: geolocate(ip)
    }

    log(
      action: 'login_failed',
      ip: ip,
      user_agent: user_agent,
      details: details
    )
  end

  # Registra logout
  def self.log_logout(user:, ip:, user_agent:)
    details = {
      event: 'logout',
      device: device_info(user_agent),
      location: geolocate(ip)
    }

    log(
      action: 'logout',
      user: user,
      ip: ip,
      user_agent: user_agent,
      details: details
    )
  end

  # Registra mudança de senha
  def self.log_password_change(user:, ip:, user_agent:)
    details = {
      event: 'password_change',
      device: device_info(user_agent),
      location: geolocate(ip)
    }

    log(
      action: 'password_change',
      user: user,
      ip: ip,
      user_agent: user_agent,
      details: details
    )
  end

  # Registra reset de senha
  def self.log_password_reset(user:, ip:, user_agent:)
    details = {
      event: 'password_reset',
      device: device_info(user_agent),
      location: geolocate(ip)
    }

    log(
      action: 'password_reset',
      user: user,
      ip: ip,
      user_agent: user_agent,
      details: details
    )
  end

  # Verifica se é um novo dispositivo ANTES do login ser registrado.
  # Chamado no início do fluxo de autenticação, antes de inserir o audit_log.
  # Retorna true se o IP não foi visto nas últimas 24h para este usuário.
  def self.new_device?(user:, ip:, user_agent:)
    return true if user.nil?

    scope = AuditLog.where(action: 'login', ip_address: ip, created_at: 24.hours.ago..)
    if user.is_a?(User)
      scope = scope.where(user_id: user.id)
    elsif user.is_a?(Customer)
      scope = scope.where(auditable_type: 'Customer', auditable_id: user.id)
    end

    !scope.exists?
  rescue => e
    Rails.logger.error("[AuditLogger] Erro ao verificar new_device: #{e.message}")
    true
  end

  # Verifica se deve enviar alerta de novo dispositivo APÓS o login ser registrado.
  # Conta quantos logins bem-sucedidos existem para este IP nas últimas 24h.
  # Se há apenas 1 (o atual), é a primeira vez → envia alerta.
  def self.new_device_alert?(user:, ip:)
    return false if user.nil?

    scope = AuditLog.where(action: 'login', ip_address: ip, created_at: 24.hours.ago..)
    if user.is_a?(User)
      scope = scope.where(user_id: user.id)
    elsif user.is_a?(Customer)
      scope = scope.where(auditable_type: 'Customer', auditable_id: user.id)
    end

    # Exatamente 1 registro = só o login atual foi o primeiro neste IP → alerta
    scope.count == 1
  rescue => e
    Rails.logger.error("[AuditLogger] Erro ao verificar new_device_alert: #{e.message}")
    false
  end

  private

  # Cache de geolocalização (evita chamar API a cada log)
  @@geolocation_cache = {}
  @@geolocation_cache_lock = Mutex.new

  def self.geolocate(ip)
    return { city: 'Desconhecido', region: '??', country: '??' } if ip.blank?

    # IPs locais/privados
    return { city: 'Rede Local', region: 'LAN', country: '??' } if ip.match?(/^(127\.|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)/)

    # Verifica cache (TTL: 1 hora)
    cached = @@geolocation_cache_lock.synchronize do
      entry = @@geolocation_cache[ip]
      if entry && entry[:expires_at] > Time.current
        entry[:data]
      else
        nil
      end
    end
    return cached if cached

    begin
      response = Net::HTTP.get(URI("https://ip-api.com/json/#{ip}?fields=status,country,regionName,city"))
      data = JSON.parse(response)

      result = if data['status'] == 'success'
        {
          city: data['city'] || 'Desconhecido',
          region: data['regionName'] || '??',
          country: data['countryCode'] || '??'
        }
      else
        { city: 'Desconhecido', region: '??', country: '??' }
      end

      # Salva no cache
      @@geolocation_cache_lock.synchronize do
        @@geolocation_cache[ip] = { data: result, expires_at: 1.hour.from_now }
      end

      result
    rescue
      { city: 'Erro', region: '??', country: '??' }
    end
  end

  def self.device_info(user_agent)
    ua = user_agent.to_s

    os = if ua.include?('Windows')
           'Windows'
         elsif ua.include?('Mac OS X') || ua.include?('Macintosh')
           'macOS'
         elsif ua.include?('Android')
           'Android'
         elsif ua.include?('iPhone') || ua.include?('iPad')
           'iOS'
         elsif ua.include?('Linux')
           'Linux'
         else
           'Desconhecido'
         end

    browser = if ua.include?('Edg')
                'Edge'
              elsif ua.include?('Chrome')
                'Chrome'
              elsif ua.include?('Safari') && !ua.include?('Chrome')
                'Safari'
              elsif ua.include?('Firefox')
                'Firefox'
              else
                'Navegador'
              end

    "#{os} · #{browser}"
  end
end
