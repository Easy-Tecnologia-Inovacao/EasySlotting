class FinancialTransaction < ApplicationRecord
  belongs_to :establishment
  belongs_to :appointment, optional: true
  belongs_to :employee, class_name: 'User', optional: true
  belongs_to :user, optional: true

  KINDS = %w[income expense].freeze
  STATUSES = %w[pending paid canceled].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :category, presence: true
  validates :occurred_on, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :source_id, uniqueness: { scope: [:source_type, :category], message: "já possui transação vinculada" }, if: -> { source_id.present? && source_type.present? }
end