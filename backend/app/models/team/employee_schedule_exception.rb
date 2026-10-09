class EmployeeScheduleException < ApplicationRecord
  belongs_to :user

  validates :exception_date, presence: true
  validates :kind, presence: true, inclusion: { in: %w[blocked_date worked_holiday] }
end