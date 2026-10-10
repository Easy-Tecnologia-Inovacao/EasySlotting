# app/models/customer.rb
# Model de cliente isolado por estabelecimento.
# Utiliza has_secure_password (BCrypt) com autenticação própria via JWT.
# A unicidade do email é composta: [email + establishment_id],
# permitindo que o mesmo email se cadastre em múltiplos estabelecimentos.

class Customer < ApplicationRecord
  has_secure_password
  DUMMY_PASSWORD_DIGEST = BCrypt::Password.create(SecureRandom.hex(32)).to_s.freeze

  include PasswordStrengthValidatable
  include LoginProtection

  belongs_to :establishment

  has_many :appointments,            foreign_key: :customer_id, dependent: :nullify
  has_many :service_package_sales,   foreign_key: :customer_id, dependent: :nullify
  has_many :customer_sessions, dependent: :delete_all

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
  after_save :revoke_auth_sessions!, if: -> { saved_change_to_password_digest? || (saved_change_to_active? && !active?) }

  # O identificador no banco permite revogação imediata de access e refresh tokens.
  def valid_auth_session?(session_id)
    active? && establishment.active? && session_id.is_a?(String) && CustomerSession::SESSION_ID_PATTERN.match?(session_id) &&
      customer_sessions.active.exists?(session_id: session_id)
  end

  def revoke_auth_sessions!
    customer_sessions.delete_all
    customer_sessions.reset
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
      :auth_session_id,
      :first_login_at,
      :login_otp_attempts,
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
    self.auth_session_id = nil
    self.login_otp_code = nil
    self.login_otp_sent_at = nil
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
