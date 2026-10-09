# app/models/customer.rb
# Model de cliente isolado por estabelecimento.
# Utiliza has_secure_password (BCrypt) com autenticação própria via JWT.
# A unicidade do email é composta: [email + establishment_id],
# permitindo que o mesmo email se cadastre em múltiplos estabelecimentos.

class Customer < ApplicationRecord
  has_secure_password

  include PasswordStrengthValidatable

  belongs_to :establishment

  has_many :appointments,            foreign_key: :customer_id, dependent: :nullify
  has_many :service_package_sales,   foreign_key: :customer_id, dependent: :nullify

  # ── Validações ────────────────────────────────────────────────────────────
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  validates :email,
            presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: 'inválido' }

  validates :email,
            uniqueness: {
              scope: :establishment_id,
              message: 'já está cadastrado neste estabelecimento'
            }

  validate :validate_password_strength, if: -> { password.present? }
  validates :phone, length: { maximum: 20 }, allow_blank: true
  validates :cellphone, length: { maximum: 20 }, allow_blank: true

  # ── Callbacks ─────────────────────────────────────────────────────────────
  before_validation :sanitize_data
  before_save { self.email = email.downcase.strip if email.present? }
  before_create :set_initial_password_changed_at
  before_save :update_password_changed_at, if: :will_save_change_to_password_digest?
  before_save :invalidate_refresh_tokens, if: :will_save_change_to_password_digest?

  # ── Lockable ──────────────────────────────────────────────────────────────
  MAX_FAILED_ATTEMPTS = 5
  LOCK_DURATION = 30.minutes

  def access_locked?
    locked_at.present? && locked_at > LOCK_DURATION.ago
  end

  def increment_failed_attempts!
    self.failed_attempts = (failed_attempts || 0) + 1
    if failed_attempts >= MAX_FAILED_ATTEMPTS
      self.locked_at = Time.current
    end
    save!(validate: false)
  end

  def reset_failed_attempts!
    update_columns(failed_attempts: 0, locked_at: nil) if failed_attempts.to_i > 0 || locked_at.present?
  end

  # ── Helpers ───────────────────────────────────────────────────────────────
  def active?
    active
  end

  def trusted_device?(ip: nil, device_token: nil)
    list = trusted_ips || []

    # 1. Verificação por token de dispositivo persistente (OWASP Session Management)
    return true if device_token.present? && list.include?("device:#{device_token}")

    return true if ip.blank?

    # 2. IP exato na lista
    return true if list.include?(ip)

    false
  end

  def trusted_ip?(ip)
    trusted_device?(ip: ip)
  end

  def add_trusted_device!(ip: nil, device_token: nil)
    current_ips = (trusted_ips || []).dup

    # Validação estrita de formato e tamanho do device_token (prevenção contra payload DoS / injeção)
    if device_token.is_a?(String) && device_token.strip.match?(/\A[a-zA-Z0-9_\-]{8,64}\z/)
      token_entry = "device:#{device_token.strip}"
      current_ips << token_entry unless current_ips.include?(token_entry)
    end

    if ip.present?
      clean_ip = ip.to_s.strip
      current_ips << clean_ip unless current_ips.include?(clean_ip)
    end

    # Mantém no máximo 30 entradas recentes
    current_ips = current_ips.last(30)
    update_columns(trusted_ips: current_ips)
  end

  def add_trusted_ip!(ip)
    add_trusted_device!(ip: ip)
  end

  def generate_login_otp!
    code = sprintf('%06d', SecureRandom.random_number(1_000_000))
    update_columns(login_otp_code: code, login_otp_sent_at: Time.current)
    code
  end

  def verify_login_otp(code)
    return false if login_otp_code.blank? || login_otp_sent_at.blank?
    return false if login_otp_sent_at < 10.minutes.ago

    if ActiveSupport::SecurityUtils.secure_compare(login_otp_code.to_s.strip, code.to_s.strip)
      update_columns(login_otp_code: nil, login_otp_sent_at: nil)
      true
    else
      false
    end
  end

  def as_safe_json
    as_json
  end

  def as_json(options = {})
    super(options.merge(except: [
      :password_digest,
      :reset_password_token,
      :reset_password_sent_at,
      :refresh_token,
      :refresh_token_expires_at,
      :consent_terms_at,
      :consent_privacy_at,
      :login_otp_code,
      :login_otp_sent_at,
      :trusted_ips,
      :failed_attempts,
      :locked_at
    ]))
  end

  private

  def set_initial_password_changed_at
    self.password_changed_at = Time.current if password_changed_at.nil?
  end

  def update_password_changed_at
    self.password_changed_at = Time.current unless new_record?
  end

  # Invalida todos os refresh tokens ao mudar a senha (segurança)
  def invalidate_refresh_tokens
    self.refresh_token = nil
    self.refresh_token_expires_at = nil
  end

  def sanitize_data
    self.name = ActionView::Base.full_sanitizer.sanitize(name).to_s.strip if name.present?
    self.email = ActionView::Base.full_sanitizer.sanitize(email).to_s.strip if email.present?
    self.phone = ActionView::Base.full_sanitizer.sanitize(phone).to_s.strip if phone.present?
    self.cellphone = ActionView::Base.full_sanitizer.sanitize(cellphone).to_s.strip if cellphone.present?
  end
end
