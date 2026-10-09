class ServicePackageUsage < ApplicationRecord
  belongs_to :service_package_sale
  belongs_to :appointment, optional: true

  validates :used_at, presence: true
end