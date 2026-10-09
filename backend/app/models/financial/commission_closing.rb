class CommissionClosing < ApplicationRecord
  belongs_to :establishment
  belongs_to :employee, class_name: 'User'
  belongs_to :membership, class_name: 'EstablishmentMembership', optional: true
  belongs_to :closed_by, class_name: 'User', optional: true

  has_many :commission_closing_items, dependent: :destroy
  has_many :commission_closing_histories, dependent: :destroy
  has_many :commissions, dependent: :nullify

  STATUSES = %w[open pending_review closed reopened cancelled].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :reference_month, presence: true
  validates :reference_month, uniqueness: { scope: [:establishment_id, :employee_id], message: 'já possui fechamento para este mês' }
  validates :period_start, :period_end, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
  scope :for_month, ->(month) { where(reference_month: month) if month.present? }
  scope :for_employee, ->(employee_id) { where(employee_id: employee_id) if employee_id.present? }
  scope :for_status, ->(status) { where(status: status) if status.present? }

  def closed?
    status == 'closed'
  end

  def open?
    status == 'open'
  end

  def reopened?
    status == 'reopened'
  end
end
