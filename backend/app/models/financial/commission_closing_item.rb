class CommissionClosingItem < ApplicationRecord
  belongs_to :commission_closing
  belongs_to :commission
  belongs_to :appointment

  validates :service_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_amount, numericality: { greater_than_or_equal_to: 0 }
end
