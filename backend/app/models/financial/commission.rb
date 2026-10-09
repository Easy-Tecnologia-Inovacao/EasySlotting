class Commission < ApplicationRecord
  belongs_to :establishment
  belongs_to :appointment
  belongs_to :employee, class_name: 'User'
  belongs_to :membership, class_name: 'EstablishmentMembership', optional: true
  belongs_to :commission_closing, optional: true

  STATUSES = %w[pending closed paid canceled].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :calculated_from_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :appointment_id, uniqueness: { message: "já possui comissão vinculada" }
end