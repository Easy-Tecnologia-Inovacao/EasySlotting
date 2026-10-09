module Scheduling
  module Appointments
    class AvailableSlotsService
      def self.call(...)
        new(...).call
      end

      def initialize(establishment_id:, employee_id:, service_id:, appointment_date:, ignore_appointment_id: nil)
        @establishment_id = establishment_id
        @employee_id = employee_id.to_s
        @service_id = service_id
        @appointment_date = Date.parse(appointment_date.to_s)
        @ignore_appointment_id = ignore_appointment_id
      end

      def call
        establishment = Establishment.find(@establishment_id)
        service = establishment.services.find(@service_id)
        
        # O intervalo de avanço na grade é baseado na duração do serviço
        interval = service.duration_minutes.to_i

        if @employee_id == 'any'
          # Busca apenas funcionários com vínculo ativo no estabelecimento que oferecem o serviço
          active_employee_ids = establishment.establishment_memberships
                                            .where(active: true, role: 'employee')
                                            .pluck(:user_id)
          employee_ids = EmployeeService.where(service_id: service.id, user_id: active_employee_ids).pluck(:user_id)
          return empty_result if employee_ids.empty?

          all_available_slots = []
          
          employee_ids.each do |emp_id|
            result = compute_for_employee(emp_id, service, establishment, interval)
            all_available_slots.concat(result[:available_slots])
          end

          {
            success: true,
            available_slots: all_available_slots.uniq.sort,
            occupied_slots: [] # Quando for "qualquer profissional", não precisamos renderizar ocupados no UI do cliente
          }
        else
          compute_for_employee(@employee_id, service, establishment, interval)
        end
      end

      private

      def compute_for_employee(employee_id, service, establishment, interval)
        is_member = establishment.establishment_memberships
                                 .exists?(user_id: employee_id, active: true, role: 'employee')
        return empty_result unless is_member

        employee_service_exists = EmployeeService.exists?(user_id: employee_id, service_id: service.id)
        return empty_result unless employee_service_exists

        weekday = @appointment_date.wday

        business_hour = BusinessHour.find_by(
          establishment_id: establishment.id,
          weekday: weekday,
          is_open: true
        )

        employee_hour = EmployeeWorkingHour.find_by(
          user_id: employee_id,
          weekday: weekday,
          is_available: true
        )

        return empty_result if business_hour.blank? || employee_hour.blank?
        return empty_result if blocked_for_date?(employee_id, establishment)

        duration = service.duration_minutes.to_i

        appointments = Appointment.where(
          establishment_id: establishment.id,
          employee_id: employee_id,
          appointment_date: @appointment_date
        ).where.not(status: 'canceled')

        appointments = appointments.where.not(id: @ignore_appointment_id) if @ignore_appointment_id.present?

        occupied_ranges = appointments.map do |appointment|
          start_min = time_to_minutes(appointment.start_time)
          end_min   = time_to_minutes(appointment.end_time)
          { start: start_min, end: end_min }
        end

        morning_slots = generate_slots(
          start_time: employee_hour.morning_start_time,
          end_time:   employee_hour.morning_end_time,
          duration:   duration,
          interval:   interval
        )

        afternoon_slots = generate_slots(
          start_time: employee_hour.afternoon_start_time,
          end_time:   employee_hour.afternoon_end_time,
          duration:   duration,
          interval:   interval
        )

        all_slots = (morning_slots + afternoon_slots).uniq.sort

        available_slots = all_slots.select do |slot|
          slot_start = time_to_minutes(slot)
          slot_end = slot_start + duration

          is_available = occupied_ranges.none? do |item|
            slot_start < item[:end] && slot_end > item[:start]
          end

          is_available
        end

        occupied_slots = all_slots - available_slots

        tz = establishment.timezone.presence || 'America/Sao_Paulo'
        today_in_tz = Time.current.in_time_zone(tz).to_date

        if @appointment_date < today_in_tz
          return empty_result
        elsif @appointment_date == today_in_tz
          now_minutes = current_minutes_in_establishment_timezone(establishment)

          available_slots = available_slots.select { |slot| time_to_minutes(slot) >= now_minutes }
          occupied_slots = occupied_slots.select { |slot| time_to_minutes(slot) >= now_minutes }
        end

        {
          success: true,
          available_slots: available_slots.uniq.sort,
          occupied_slots: occupied_slots.uniq.sort
        }
      end

      def empty_result
        {
          success: true,
          available_slots: [],
          occupied_slots: []
        }
      end

      def blocked_for_date?(employee_id, establishment)
        has_blocked_date = EmployeeScheduleException.exists?(
          user_id: employee_id,
          exception_date: @appointment_date,
          kind: 'blocked_date',
          active: true
        )

        has_worked_holiday = EmployeeScheduleException.exists?(
          user_id: employee_id,
          exception_date: @appointment_date,
          kind: 'worked_holiday',
          active: true
        )

        return false if holiday_for_date?(establishment) && has_worked_holiday
        return true if has_blocked_date
        return true if holiday_for_date?(establishment)

        false
      end

      def holiday_for_date?(_establishment)
        Holidays.on(@appointment_date, :br).present?
      end

      def generate_slots(start_time:, end_time:, duration:, interval:)
        return [] if start_time.blank? || end_time.blank?

        start_minutes = time_to_minutes(start_time)
        end_minutes = time_to_minutes(end_time)

        return [] if start_minutes >= end_minutes

        slots = []
        current = start_minutes

        while (current + duration) <= end_minutes
          slots << minutes_to_time(current)
          current += interval
        end

        slots
      end

      def current_minutes_in_establishment_timezone(establishment)
        timezone = establishment.timezone.presence || 'America/Sao_Paulo'
        now = Time.current.in_time_zone(timezone)
        (now.hour * 60) + now.min
      end

      def time_to_minutes(time)
        hhmm = if time.is_a?(String)
                 time[0, 5]
               else
                 time.strftime('%H:%M')
               end
        hour, minute = hhmm.split(':').map(&:to_i)
        (hour * 60) + minute
      end

      def minutes_to_time(total_minutes)
        hour = total_minutes / 60
        minute = total_minutes % 60
        format('%02d:%02d', hour, minute)
      end
    end
  end
end