class CommissionClosingHistory < ApplicationRecord
  belongs_to :commission_closing
  belongs_to :user

  validates :action, presence: true
end
