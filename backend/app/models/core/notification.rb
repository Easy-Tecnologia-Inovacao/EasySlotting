class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :establishment

  validates :title, :content, presence: true

  scope :unread, -> { where(read: false) }
end
