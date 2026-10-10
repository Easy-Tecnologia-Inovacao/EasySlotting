class SuperAdmin::AuditLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_super_admin!
  class InvalidFilter < StandardError; end
  rescue_from InvalidFilter do
    render json: { error: 'Filtros inválidos. Confira os valores e o intervalo de datas.' }, status: :unprocessable_entity
  end
  ACTION_LABELS = {
    'login' => 'Login', 'login_failed' => 'Falha de login', 'logout' => 'Logout',
    'password_change' => 'Mudança de senha', 'password_reset' => 'Redefinição de senha',
    'password_change_failed' => 'Falha ao alterar senha', 'password_reset_request' => 'Solicitação de redefinição',
    'write_blocked_password_expired' => 'Senha expirada', 'session_revoked' => 'Sessão encerrada',
    'other_sessions_revoked' => 'Outras sessões encerradas', 'staff_session_limit_reached' => 'Limite de sessões'
  }.freeze
  MAX_PAGES = 500

  def index
    page = integer_filter(:page, default: 1, max: MAX_PAGES)
    per_page = integer_filter(:per_page, default: 50, max: 200)
    logs = AuditLog.includes(:user, :establishment)
    action = string_filter(:action_type, max: 80)
    if action.present?
      action = 'password_change' if action == 'password_changed'
      raise InvalidFilter unless ACTION_LABELS.key?(action)
      logs = logs.where(action: action == 'password_change' ? %w[password_change password_changed] : action)
    end
    %i[user_id establishment_id].each do |key|
      id = integer_filter(key, max: 9_223_372_036_854_775_807)
      logs = logs.where(key => id) if id
    end
    start_date = date_filter(:start_date)
    end_date = date_filter(:end_date)
    raise InvalidFilter if start_date && end_date && start_date > end_date
    logs = logs.where('created_at >= ?', start_date.beginning_of_day) if start_date
    logs = logs.where('created_at < ?', end_date.next_day.beginning_of_day) if end_date
    total = logs.count
    render json: {
      logs: logs.order(created_at: :desc, id: :desc).offset((page - 1) * per_page).limit(per_page).map { |log| serialize_log(log) },
      pagination: { current_page: page, per_page: per_page, total_count: total,
        total_pages: [(total.to_f / per_page).ceil, MAX_PAGES].min, truncated: total > MAX_PAGES * per_page }
    }
  end

  def security_summary
    result = Rails.cache.fetch('super_admin/security_summary/v2', expires_in: 2.minutes) do
      now = Time.current
      recent = AuditLog.where(created_at: (now - 24.hours)..now)
      failures = recent.where(action: 'login_failed')
      { generated_at: now.iso8601, summary: {
        logins_24h: recent.where(action: 'login').count, failed_logins_24h: failures.count,
        suspicious_ip_count: failures.where.not(ip_address: [nil, '']).distinct.count(:ip_address)
      } }
    end
    render json: result
  end

  def filter_options
    query = string_filter(:q, max: 100)
    scope = Establishment.all
    scope = scope.where('name ILIKE ?', "%#{Establishment.sanitize_sql_like(query)}%") if query.present?
    rows = scope.order(:name, :id).limit(51).pluck(:id, :name)
    render json: { establishments: rows.first(50).map { |id, name| { id: id, name: name } },
      has_more: rows.length > 50, actions: ACTION_LABELS.map { |value, label| { value: value, label: label } } }
  end

  private

  def string_filter(key, max:)
    value = params[key]
    return nil if value.nil?
    raise InvalidFilter unless value.is_a?(String) && value.length <= max
    value.presence
  end

  def integer_filter(key, max:, default: nil)
    value = params[key]
    return default if value.nil? || value == ''
    raise InvalidFilter unless (value.is_a?(String) || value.is_a?(Integer)) && value.to_s.match?(/\A[0-9]{1,19}\z/)
    number = value.to_i
    raise InvalidFilter unless number.between?(1, max)
    number
  end

  def date_filter(key)
    value = string_filter(key, max: 10)
    return nil unless value
    raise InvalidFilter unless value.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/)
    date = Date.iso8601(value)
    raise InvalidFilter unless date.year.between?(1, 9998)
    date
  rescue Date::Error
    raise InvalidFilter
  end

  def safe_text(value, max = 120)
    value.is_a?(String) ? value.gsub(/[[:cntrl:]]/, '').truncate(max) : nil
  end

  def serialize_log(log)
    details = log.details.is_a?(Hash) ? log.details : {}
    location = details['location']
    { id: log.id, action: safe_text(log.action, 80), ip_address: safe_text(log.ip_address, 45),
      device: safe_text(details['device']),
      location: location.is_a?(Hash) ? %w[city region country].to_h { |key| [key, safe_text(location[key])] } : nil,
      timestamp: log.created_at.iso8601,
      user: log.user ? { id: log.user.id, name: safe_text(log.user.name), email: safe_text(log.user.email, 254) } : nil,
      establishment: log.establishment ? { id: log.establishment.id, name: safe_text(log.establishment.name), slug: safe_text(log.establishment.slug) } : nil }
  end
end
