module Scheduling
  module Appointments
    class CreateService
      def self.call(...)
        new(...).call
      end

      def initialize(establishment_id:, customer_id:, employee_id:, service_id:, appointment_date:, start_time:, notes: nil, status: nil)
        @establishment_id = establishment_id
        @customer_id = customer_id
        @employee_id = employee_id
        @service_id = service_id
        @appointment_date = Date.parse(appointment_date.to_s)
        @start_time = start_time
        @notes = notes
        @status = status.presence || 'confirmed'
      end

      def call
        Appointment.transaction do
          establishment = Establishment.find(@establishment_id)
          customer = Customer.find_by!(id: @customer_id, establishment_id: @establishment_id)
          membership = establishment.establishment_memberships.where(active: true, role: 'employee').find_by!(user_id: @employee_id)
          employee = User.lock.find(membership.user_id)
          service = Service.find_by!(id: @service_id, establishment_id: @establishment_id)

          validate_employee_service!(employee, service)
          validate_employee_working_day!(employee)
          validate_business_day!(establishment)

          parsed_start = Time.zone.parse("2000-01-01 #{@start_time}")
          raise StandardError, 'Horário inválido.' if parsed_start.blank?

          parsed_end = parsed_start + service.duration_minutes.minutes

          validate_inside_working_hours!(establishment, employee, parsed_start, parsed_end)
          validate_conflict!(parsed_start, parsed_end)

          Appointment.create!(
            establishment_id: @establishment_id,
            customer_id: @customer_id,
            customer_name_snapshot: customer.name,
            employee_id: @employee_id,
            employee_name_snapshot: employee.name,
            service_id: @service_id,
            service_name_snapshot: service.name,
            price_snapshot: service.price,
            appointment_date: @appointment_date,
            start_time: parsed_start.strftime('%H:%M'),
            end_time: parsed_end.strftime('%H:%M'),
            duration_minutes: service.duration_minutes,
            notes: @notes,
            status: @status
          )
        end
      end

      private

      def weekday
        @appointment_date.wday
      end

      def validate_employee_service!(employee, service)
        exists = EmployeeService.exists?(user_id: employee.id, service_id: service.id)
        raise StandardError, 'Funcionário não atende esse serviço.' unless exists
      end

      def validate_employee_working_day!(employee)
        working_hour = EmployeeWorkingHour.find_by(
          user_id: employee.id,
          weekday: weekday,
          is_available: true
        )

        raise StandardError, 'Funcionário não está disponível neste dia.' if working_hour.blank?
      end

      def validate_business_day!(establishment)
        business_hour = BusinessHour.find_by(
          establishment_id: establishment.id,
          weekday: weekday,
          is_open: true
        )

        raise StandardError, 'Estabelecimento fechado nesta data.' if business_hour.blank?
      end

      def validate_inside_working_hours!(establishment, employee, parsed_start, parsed_end)
        business_hour = BusinessHour.find_by!(
          establishment_id: establishment.id,
          weekday: weekday,
          is_open: true
        )

        employee_hour = EmployeeWorkingHour.find_by!(
          user_id: employee.id,
          weekday: weekday,
          is_available: true
        )

        business_start = Time.zone.parse("2000-01-01 #{business_hour.start_time.strftime('%H:%M')}")
        business_end = Time.zone.parse("2000-01-01 #{business_hour.end_time.strftime('%H:%M')}")

        employee_start = Time.zone.parse("2000-01-01 #{employee_hour.start_time.strftime('%H:%M')}")
        employee_end = Time.zone.parse("2000-01-01 #{employee_hour.end_time.strftime('%H:%M')}")

        allowed_start = [business_start, employee_start].max
        allowed_end = [business_end, employee_end].min

        if parsed_start < allowed_start || parsed_end > allowed_end
          raise StandardError, 'Horário fora da disponibilidade do profissional ou do estabelecimento.'
        end
      end

      def validate_conflict!(parsed_start, parsed_end)
        parsed_start_str = parsed_start.strftime('%H:%M')
        parsed_end_str   = parsed_end.strftime('%H:%M')

        conflict = Appointment.active_for_schedule
                              .where(
                                establishment_id: @establishment_id,
                                employee_id: @employee_id,
                                appointment_date: @appointment_date
                              )
                              .where('start_time < ? AND end_time > ?', parsed_end_str, parsed_start_str)
                              .exists?

        raise StandardError, 'Já existe um agendamento nesse horário para este profissional.' if conflict
      end
    end
  end
end