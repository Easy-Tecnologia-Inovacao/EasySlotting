class EmployeeWorkingHour < ApplicationRecord
  belongs_to :user

  validates :weekday, presence: true, inclusion: { in: 0..6 }
  validates :user_id, presence: true

  validate :validate_time_ranges

  private

  def validate_time_ranges
    return unless is_available

    if morning_start_time.present? && morning_end_time.present?
      if morning_start_time >= morning_end_time
        errors.add(:morning_end_time, 'deve ser maior que o início da manhã')
      end
    end

    if afternoon_start_time.present? && afternoon_end_time.present?
      if afternoon_start_time >= afternoon_end_time
        errors.add(:afternoon_end_time, 'deve ser maior que o início da tarde/noite')
      end
    end

    if morning_end_time.present? && afternoon_start_time.present?
      if morning_end_time > afternoon_start_time
        errors.add(:afternoon_start_time, 'deve começar após o fim da manhã')
      end
    end
  end
end