module Financial
  class AppointmentRevenueCreator
    def self.call(appointment)
      new(appointment).call
    end

    def initialize(appointment)
      @appointment = appointment
    end

    def call
      return nil if @appointment.blank?
      return nil if @appointment.price_snapshot.blank?

      existing_transaction = FinancialTransaction.find_by(
        source_type: 'Appointment',
        source_id: @appointment.id,
        category: 'appointment_revenue'
      )

      return existing_transaction if existing_transaction.present?

      FinancialTransaction.create!(
        establishment: @appointment.establishment,
        appointment: @appointment,
        employee: @appointment.employee,
        user: @appointment.customer,
        kind: 'income',
        category: 'appointment_revenue',
        source_type: 'Appointment',
        source_id: @appointment.id,
        description: "Receita do agendamento ##{@appointment.id}",
        amount: @appointment.price_snapshot,
        occurred_on: @appointment.appointment_date,
        status: 'paid',
        metadata: {
          service_id: @appointment.service_id,
          service_name: @appointment.service_name_snapshot,
          customer_name: @appointment.customer_name_snapshot
        }
      )
    end
  end
end