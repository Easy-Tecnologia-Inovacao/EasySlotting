class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  include DeviseTokenAuth::Concerns::User
  include PasswordStrengthValidatable

  before_validation :sanitize_user_data
  before_validation :sync_uid_with_email

  validates :role, inclusion: { in: %w[customer owner employee super_admin] }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :phone, format: { with: /\A\(\d{2}\) \d{4,5}-\d{4}\z/, message: "deve ser no formato (XX) XXXXX-XXXX ou (XX) XXXX-XXXX" }, allow_blank: true

  before_create :set_initial_password_changed_at
  before_save :update_password_changed_at, if: :will_save_change_to_encrypted_password?
  before_save :invalidate_all_tokens, if: :will_save_change_to_encrypted_password?

  # Estabelecimentos que o user possui (como owner)
  has_many :owned_establishments,
           class_name: 'Establishment',
           foreign_key: 'owner_id',
           dependent: :nullify

  # Memberships de employees/owners em estabelecimentos
  # Nota: customers agora usam o model Customer (tabela separada)
  has_many :establishment_memberships, dependent: :destroy
  has_many :establishments, through: :establishment_memberships

  has_many :employee_services, dependent: :destroy
  has_many :services, through: :employee_services

  has_many :service_packages, dependent: :nullify

  # Agendamentos como funcionário (employee)
  has_many :employee_appointments,
           class_name: 'Appointment',
           foreign_key: :employee_id,
           dependent: :nullify

  # Nota: agendamentos como customer são acessados via Customer model

  has_many :earned_commissions,
           class_name: 'Commission',
           foreign_key: :employee_id,
           dependent: :nullify

  has_many :sold_service_package_sales,
           class_name: 'ServicePackageSale',
           foreign_key: :sold_by_id,
           dependent: :nullify

  # Nota: service_package_sales como customer são acessados via Customer model

  has_many :archived_employee_records,
           class_name: 'ArchivedEmployee',
           foreign_key: :user_id,
           dependent: :nullify

  has_many :archived_employees_created,
           class_name: 'ArchivedEmployee',
           foreign_key: :archived_by_id,
           dependent: :nullify

  has_many :notifications, dependent: :destroy

  MAX_FAILED_ATTEMPTS = 5
  LOCK_DURATION = 30.minutes

  # ── Lockable custom (compatível com DeviseTokenAuth) ───────────────────────
  def access_locked?
    locked_at.present? && locked_at > LOCK_DURATION.ago
  end

  def active_for_authentication?
    super && !access_locked?
  end

  def lock_access!
    update_columns(locked_at: Time.current, failed_attempts: (failed_attempts || 0) + 1)
  end

  def unlock_access!
    update_columns(locked_at: nil, failed_attempts: 0)
  end

  def increment_failed_attempts!
    new_count = (failed_attempts || 0) + 1
    if new_count >= MAX_FAILED_ATTEMPTS
      lock_access!
    else
      update_columns(failed_attempts: new_count)
    end
  end

  def reset_failed_attempts!
    update_columns(failed_attempts: 0) if (failed_attempts || 0) > 0
  end

  # Soft delete com anonimização de PII (LGPD Art. 18-VI)
  def soft_delete_with_anonymization!
    update!(
      name: 'Conta Excluída',
      email: "deleted_#{id}_#{Time.current.to_i}@deleted.local",
      phone: nil,
      cellphone: nil,
      image: nil,
      encrypted_password: '',
      tokens: {},
      active: false,
      password_changed_at: nil,
      locked_at: nil,
      failed_attempts: 0
    )
  end

  def owner?
    role == 'owner'
  end

  def customer?
    role == 'customer'
  end

  def employee?
    role == 'employee'
  end

  def super_admin?
    role == 'super_admin'
  end

  # ── Dispositivos e IP Confiáveis (Estilo Discord / OWASP) ───────────────────
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

    if device_token.present?
      token_entry = "device:#{device_token}"
      current_ips << token_entry unless current_ips.include?(token_entry)
    end

    if ip.present?
      current_ips << ip unless current_ips.include?(ip)
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

  def as_json(options = {})
    super(options.merge(except: [:encrypted_password, :tokens, :confirmation_token, :reset_password_token, :uid, :provider, :login_otp_code, :login_otp_sent_at, :trusted_ips]))
  end

  private

  def sync_uid_with_email
    self.uid = email if email.present? && (uid.blank? || uid != email)
  end

  def sanitize_user_data
    if name.present?
      self.name = ActionView::Base.full_sanitizer.sanitize(name).to_s.strip
    end
    if phone.present?
      self.phone = ActionView::Base.full_sanitizer.sanitize(phone).to_s.strip
    end
  end

  def set_initial_password_changed_at
    self.password_changed_at = Time.current if password_changed_at.nil?
  end

  def update_password_changed_at
    self.password_changed_at = Time.current unless new_record?
  end

  # Invalida todos os tokens ao mudar a senha (segurança)
  # Isso force logout em todos os dispositivos
  def invalidate_all_tokens
    self.tokens = {} unless new_record?
  end
end