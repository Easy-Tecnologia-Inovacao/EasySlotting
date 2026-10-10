class Subscription < ApplicationRecord
  belongs_to :establishment
  belongs_to :plan

  has_one :subscription_cancellation, dependent: :destroy

  STATUSES = %w[pending active overdue canceled expired].freeze
  BILLING_CYCLES = %w[monthly quarterly yearly].freeze

  # Uma tentativa pendente/futura não substitui o contrato já iniciado.
  # Um contrato substituído não volta a conceder benefícios após o novo vencer.
  scope :started, -> { where.not(status: 'pending').where('start_date <= ?', Date.current) }

  def self.current_for_use
    subscription = started.order(created_at: :desc, id: :desc).first
    subscription if subscription&.active?
  end

  validates :status, inclusion: { in: STATUSES }
  validates :billing_cycle, inclusion: { in: BILLING_CYCLES }
  validates :start_date, :end_date, presence: true
  validates :price_paid, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def expired?
    end_date.present? && end_date < Date.current
  end

  def active?
    return false if expired?

    status == "active" || status == "canceled"
  end

  def canceled_but_still_available?
    status == "canceled" && end_date.present? && end_date >= Date.current
  end
end
