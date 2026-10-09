module Financial
  class CommissionCalculator
    def self.call(appointment)
      new(appointment).call
    end

    def initialize(appointment)
      @appointment = appointment
    end

    def call
      return nil if @appointment.blank?
      return nil if @appointment.price_snapshot.blank?
      return @appointment.commission if @appointment.commission.present?

      membership = EstablishmentMembership.find_by(
        establishment_id: @appointment.establishment_id,
        user_id: @appointment.employee_id,
        active: true
      )

      return nil unless membership

      amount = calculate_amount(membership)

      Commission.create!(
        establishment: @appointment.establishment,
        appointment: @appointment,
        employee: @appointment.employee,
        membership: membership,
        calculated_from_amount: @appointment.price_snapshot,
        amount: amount,
        status: 'pending',
        reference_month: @appointment.appointment_date.strftime('%Y-%m')
      )
    end

    private

    def calculate_amount(membership)
      price = @appointment.price_snapshot.to_d
      financial_value = membership.financial_value.to_d
      bonus_pct = membership.commission_bonus_percentage.to_d

      base = case membership.financial_model
             when 'porcentagem'
               (price * financial_value / 100).round(2)
             when 'fixo_servico'
               financial_value.round(2)
             when 'diaria'
               0.to_d
             else
               0.to_d
             end

      if membership.financial_model != 'porcentagem' && bonus_pct > 0
        base += (price * bonus_pct / 100).round(2)
      end

      base
    end
  end
end