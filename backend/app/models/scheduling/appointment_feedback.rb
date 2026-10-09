# app/models/scheduling/appointment_feedback.rb
class AppointmentFeedback < ApplicationRecord
  belongs_to :appointment
  belongs_to :customer

  validates :rating,  presence: true, inclusion: { in: 1..5, message: 'deve ser entre 1 e 5' }
  validates :comment, length: { maximum: 1000 }, allow_blank: true
  validates :appointment_id, uniqueness: { message: 'já possui um feedback' }

  # Garante que o customer só avalia seus próprios agendamentos concluídos
  validate :appointment_must_be_completed
  validate :customer_must_own_appointment

  private

  def appointment_must_be_completed
    return unless appointment
    unless appointment.status == 'completed'
      errors.add(:appointment, 'precisa estar concluído para receber feedback')
    end
  end

  def customer_must_own_appointment
    return unless appointment && customer
    unless appointment.customer_id == customer.id
      errors.add(:customer, 'não autorizado para este agendamento')
    end
  end
end
