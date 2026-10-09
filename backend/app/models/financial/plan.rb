class Plan < ApplicationRecord
  has_many :subscriptions, dependent: :restrict_with_exception

  before_validation :sanitize_data

  # Campos de texto — limites de comprimento e formato
  validates :name,
            presence: true,
            length: { minimum: 2, maximum: 100 }

  validates :code,
            presence: true,
            uniqueness: true,
            length: { maximum: 50 },
            format: {
              with: /\A[a-z0-9_\-]+\z/,
              message: "deve conter apenas letras minúsculas, números, hífens e underscores"
            }

  validates :description,
            length: { maximum: 500 },
            allow_blank: true

  # Campos numéricos — limites de valor
  validates :price,
            presence: true,
            numericality: { greater_than: 0, less_than: 100_000 }

  validates :duration_months,
            presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 24 }

  validates :discount_percentage,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true

  validates :promotional_price,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :promotion_duration_days,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 },
            allow_nil: true

  validates :max_employees,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :max_services,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :max_appointments_per_month,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  validate :code_immutable_if_subscribed, on: :update
  validate :promotional_price_must_be_less_than_regular_price

  before_validation :calculate_promotion_end_date
  before_validation :calculate_discount_percentage
  before_validation :calculate_promotional_price

  def promotion_running?
    return false unless promotion_active?

    now = Time.current
    promotion_starts_at.present? &&
      promotion_ends_at.present? &&
      now >= promotion_starts_at &&
      now <= promotion_ends_at
  end

  def current_price
    promotion_running? && promotional_price.present? ? promotional_price : price
  end

  private

  def code_immutable_if_subscribed
    if code_changed? && subscriptions.exists?
      errors.add(:code, "não pode ser alterado pois já existem assinaturas vinculadas a este plano")
    end
  end

  def promotional_price_must_be_less_than_regular_price
    return unless promotion_active? && promotional_price.present? && price.present?

    if promotional_price.to_f >= price.to_f
      errors.add(:promotional_price, "deve ser estritamente menor que o preço normal do plano")
    end
  end

  def sanitize_data
    self.name = ActionView::Base.full_sanitizer.sanitize(name).to_s.strip if name.present?
    # code: força minúsculas e remove espaços — sem tags HTML permitidas
    self.code = code.to_s.downcase.strip if code.present?
    self.description = ActionView::Base.full_sanitizer.sanitize(description).to_s.strip if description.present?
  end

  def calculate_promotion_end_date
    return unless promotion_starts_at.present? && promotion_duration_days.present?

    self.promotion_ends_at = promotion_starts_at + promotion_duration_days.days
  end

  def calculate_discount_percentage
    return unless price.present? && promotional_price.present? && price.to_f > 0

    self.discount_percentage = (((price - promotional_price) / price) * 100).round
  end

  def calculate_promotional_price
    return unless price.present? && discount_percentage.present? && promotional_price.blank?

    self.promotional_price = price - (price * discount_percentage / 100.0)
  end
end