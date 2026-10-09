class ServicePackage < ApplicationRecord
  before_validation :sanitize_data

  belongs_to :establishment
  belongs_to :user, optional: true
  belongs_to :service, optional: true

  has_many :package_employees, dependent: :destroy
  has_many :employees, through: :package_employees, source: :user

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :included_items, length: { maximum: 1000 }, allow_blank: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1440 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0, less_than: 1_000_000 }
  validates :service_id, presence: true
  validate :service_belongs_to_establishment, if: -> { service_id.present? }
  validates :sessions_total, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :active, inclusion: { in: [true, false] }

  # Soft Delete
  default_scope { where(deleted_at: nil) }

  def discard
    update!(deleted_at: Time.current)
  end

  private

  def sanitize_data
    self.name = ActionView::Base.full_sanitizer.sanitize(name).to_s.strip if name.present?
    self.description = ActionView::Base.full_sanitizer.sanitize(description).to_s.strip if description.present?
    self.included_items = ActionView::Base.full_sanitizer.sanitize(included_items).to_s.strip if included_items.present?
  end

  def service_belongs_to_establishment
    return if establishment_id.blank?

    unless Service.where(id: service_id, establishment_id: establishment_id).exists?
      errors.add(:service_id, 'não pertence a este estabelecimento')
    end
  end

  def self.with_deleted
    unscoped
  end

  scope :active, -> { where(active: true) }
end