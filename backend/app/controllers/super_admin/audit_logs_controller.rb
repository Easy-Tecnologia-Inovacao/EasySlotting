# app/controllers/super_admin/audit_logs_controller.rb
# Controller para visualização de logs de auditoria.
# Apenas super_admin podem acessar (dados sensíveis de segurança).

class SuperAdmin::AuditLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_super_admin!

  SENSITIVE_DETAILS_KEYS = %w[
    user_agent timestamp location token access_token refresh_token
    password encrypted_password password_digest secret api_key
  ].freeze

  # Allowlist de tipos de ação aceitos como filtro (5a — validação de input)
  ALLOWED_ACTION_TYPES = %w[
    login login_failed logout password_change password_reset
    write_blocked_password_expired
  ].freeze

  # GET /super_admin/audit_logs
  # Lista logs de auditoria com filtros (todos os estabelecimentos)
  def index
    logs = AuditLog.includes(:user, :establishment)

    # Filtros opcionais — action_type validado contra allowlist (5a)
    if params[:action_type].present? && ALLOWED_ACTION_TYPES.include?(params[:action_type])
      logs = logs.where(action: params[:action_type])
    end
    
    if params[:user_id].present? && params[:user_id].to_s =~ /\A\d+\z/
      logs = logs.where(user_id: params[:user_id].to_i)
    end
    
    if params[:establishment_id].present? && params[:establishment_id].to_s =~ /\A\d+\z/
      logs = logs.where(establishment_id: params[:establishment_id].to_i)
    end

    # Filtro por data seguro contra Date::Error
    if (start_d = safe_parse_date(params[:start_date]))
      logs = logs.where('created_at >= ?', start_d.beginning_of_day)
    end
    if (end_d = safe_parse_date(params[:end_date]))
      logs = logs.where('created_at <= ?', end_d.end_of_day)
    end

    # Paginação segura contra valores negativos ou zero
    page = [params[:page].to_i, 1].max
    per_page = [[(params[:per_page] || 50).to_i, 1].max, 200].min
    total = logs.count
    logs = logs.order(created_at: :desc).offset((page - 1) * per_page).limit(per_page)

    render json: {
      logs: logs.map { |log| serialize_log(log) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total,
        total_pages: (total.to_f / per_page).ceil
      }
    }
  end

  # GET /super_admin/audit_logs/security_summary
  # Resumo de segurança das últimas 24h (todos os estabelecimentos)
  def security_summary
    # Cache de 2 minutos para evitar sobrecarga do banco com múltiplas
    # queries de agregação a cada requisição (5c — rate limiting / cache)
    result = Rails.cache.fetch('super_admin/security_summary', expires_in: 2.minutes) do
      since = 24.hours.ago

      # Logins nas últimas 24h
      logins_24h = AuditLog
        .where(action: 'login', created_at: since..)
        .count

      # Logins falhos nas últimas 24h
      failed_logins_24h = AuditLog
        .where(action: 'login_failed', created_at: since..)
        .count

      # IPs únicos com falhas
      suspicious_ips = AuditLog
        .where(action: 'login_failed', created_at: since..)
        .distinct
        .pluck(:ip_address)
        .compact

      # Últimos 20 logs de segurança
      recent_logs = AuditLog
        .where(action: %w[login login_failed logout password_change])
        .includes(:user, :establishment)
        .order(created_at: :desc)
        .limit(20)
        .map { |log| serialize_log(log) }

      # Estabelecimentos mais ativos
      active_establishments = AuditLog
        .where(action: 'login', created_at: since..)
        .group(:establishment_id)
        .count
        .sort_by { |_, count| -count }
        .first(10)
        .map { |est_id, count| { establishment_id: est_id, login_count: count } }

      # Usuários mais ativos
      active_users = AuditLog
        .where(action: 'login', created_at: since..)
        .group(:user_id)
        .count
        .sort_by { |_, count| -count }
        .first(10)
        .map { |user_id, count| { user_id: user_id, login_count: count } }

      {
        summary: {
          logins_24h: logins_24h,
          failed_logins_24h: failed_logins_24h,
          suspicious_ips: suspicious_ips,
          suspicious_ip_count: suspicious_ips.length
        },
        recent_logs: recent_logs,
        active_establishments: active_establishments,
        active_users: active_users
      }
    end

    render json: result
  end

  private

  def safe_parse_date(date_str)
    return nil if date_str.blank?
    Date.parse(date_str.to_s)
  rescue Date::Error, ArgumentError
    nil
  end

  def serialize_log(log)
    safe_details = (log.details || {}).except(*SENSITIVE_DETAILS_KEYS)

    {
      id: log.id,
      action: log.action,
      ip_address: log.ip_address,
      # user_agent raw removido da resposta (5b) — informação sensível condensada
      # em 'device' (ex: "Windows · Chrome") é suficiente para o painel
      device: log.details&.dig('device'),
      location: log.details&.dig('location'),
      email_attempted: log.details&.dig('email_attempted'),
      reason: log.details&.dig('reason'),
      timestamp: log.created_at.iso8601,
      user: log.user ? {
        id: log.user.id,
        name: log.user.name,
        email: log.user.email
      } : nil,
      establishment: log.establishment ? {
        id: log.establishment.id,
        name: log.establishment.name,
        slug: log.establishment.slug
      } : nil,
      details: safe_details
    }
  end
end
