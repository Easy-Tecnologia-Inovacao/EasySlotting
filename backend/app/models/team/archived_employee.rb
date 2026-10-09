class ArchivedEmployee < ApplicationRecord
  belongs_to :establishment
  belongs_to :user
  belongs_to :archived_by, class_name: 'User', optional: true

  validates :archived_at, presence: true
end