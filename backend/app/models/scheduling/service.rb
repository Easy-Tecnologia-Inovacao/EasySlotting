class Service < ApplicationRecord
  before_validation :sanitize_data
  validate -> { PlanQuotaPolicy.validate(self, :services) }

  belongs_to :establishment

  has_many :employee_services, dependent: :destroy
  has_many :employees, through: :employee_services, source: :user

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :service_type, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1440 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000 }
  validates :active, inclusion: { in: [true, false] }

  # Soft Delete
  default_scope { where(deleted_at: nil) }

  def discard
    update!(deleted_at: Time.current)
  end

  private

  def sanitize_data
    self.name = ActionView::Base.full_sanitizer.sanitize(name).to_s.strip if name.present?
    self.service_type = ActionView::Base.full_sanitizer.sanitize(service_type).to_s.strip if service_type.present?
    self.description = ActionView::Base.full_sanitizer.sanitize(description).to_s.strip if description.present?
  end

  def self.with_deleted
    unscoped
  end
end
