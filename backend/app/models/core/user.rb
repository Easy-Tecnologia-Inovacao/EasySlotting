class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  include DeviseTokenAuth::Concerns::User
  include PasswordStrengthValidatable
  include LoginProtection
  prepend OwnerSessionTokens

  before_validation :sanitize_user_data
  before_validation :sync_uid_with_email

  validates :role, inclusion: { in: %w[customer owner employee super_admin] }
  validates :role, uniqueness: { message: 'já possui uma conta de super admin no sistema' }, if: :super_admin?
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

  def active_for_authentication?
    super && active? && !access_locked?
  end

  # Revoga também a autorização de sessões já emitidas para contas desativadas.
  def valid_token?(token, client = 'default')
    return false unless %w[owner employee super_admin].include?(role) && active_for_authentication?
    with_lock do
      return false unless %w[owner employee super_admin].include?(role) && active_for_authentication?
      permitted = OwnerSessionPolicy.new(self).permitted_tokens
      # Expiração/downgrade revogam os excedentes de modo definitivo, sem
      # ressuscitá-los caso o plano seja ampliado novamente.
      update_columns(tokens: permitted) if tokens != permitted
      permitted.key?(client) && super
    end
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
  def as_json(options = {})
    super(options.merge(except: [:encrypted_password, :tokens, :confirmation_token, :reset_password_token, :uid, :provider, :login_otp_code, :login_otp_sent_at, :login_otp_attempts, :first_login_at, :failed_attempts, :locked_at, :trusted_ips]))
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
    unless new_record?
      self.tokens = {}
      self.login_otp_code = nil
      self.login_otp_sent_at = nil
    end
  end
end
