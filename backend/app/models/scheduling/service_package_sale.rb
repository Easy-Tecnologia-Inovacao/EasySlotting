class ServicePackageSale < ApplicationRecord
  belongs_to :establishment
  belongs_to :service_package
  belongs_to :customer, class_name: 'Customer'
  belongs_to :sold_by, class_name: 'User', optional: true

  has_many :service_package_usages, dependent: :destroy

  STATUSES = %w[active completed canceled expired].freeze

  before_validation :sanitize_data

  validates :status, inclusion: { in: STATUSES }
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }
  validates :sessions_total, numericality: { greater_than: 0 }
  validates :sessions_used, numericality: { greater_than_or_equal_to: 0 }
  validates :cancellation_reason, length: { maximum: 250 }, allow_blank: true
  validate :sessions_used_cannot_exceed_total

  def sessions_remaining
    sessions_total - sessions_used
  end

  def can_use_session?
    status == 'active' && sessions_remaining > 0
  end

  # Deduta uma sessão de forma atômica
  def use_session!(appointment = nil)
    transaction do
      lock! # Bloqueio pessimista (FOR UPDATE)
      
      raise "Pacote não está ativo." unless status == 'active'
      raise "Saldo de sessões esgotado." if sessions_used >= sessions_total

      self.sessions_used += 1
      self.status = 'completed' if sessions_used == sessions_total
      save!

      service_package_usages.create!(
        appointment: appointment,
        used_at: Time.current,
        notes: "Uso de sessão via agendamento ##{appointment&.id}"
      )
    end
  end

  private

  def sanitize_data
    if cancellation_reason.present?
      self.cancellation_reason = ActionView::Base.full_sanitizer.sanitize(cancellation_reason).to_s.strip
    end
  end

  def sessions_used_cannot_exceed_total
    if sessions_used > sessions_total
      errors.add(:sessions_used, "não pode ser maior que o total de sessões")
    end
  end
end