class EmployeeService < ApplicationRecord
  belongs_to :user
  belongs_to :service

  validates :user_id, uniqueness: { scope: :service_id }
end