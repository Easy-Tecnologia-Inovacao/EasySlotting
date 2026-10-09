module Scheduling
  module Appointments
    class RescheduleService
      def self.call(...)
        new(...).call
      end

      def initialize(appointment:, appointment_date:, start_time:, employee_id: nil, service_id: nil)
        @appointment = appointment
        @appointment_date = Date.parse(appointment_date.to_s)
        @start_time = start_time
        @employee_id = employee_id.presence || appointment.employee_id
        @service_id = service_id.presence || appointment.service_id
      end

      def call
        Appointment.transaction do
          establishment = @appointment.establishment
          membership = establishment.establishment_memberships.where(active: true, role: 'employee').find_by!(user_id: @employee_id)
          employee = User.lock.find(membership.user_id)

          old_date = @appointment.appointment_date
          old_time = @appointment.start_time.respond_to?(:strftime) ? @appointment.start_time.strftime('%H:%M') : @appointment.start_time.to_s[0, 5]

          # Para pacotes mensais, o servico deve permanecer o original
          if @appointment.service_package_id.present?
            @service_id = @appointment.service_id
            
            # Validação de 'Uma sessão por semana'
            new_sunday = @appointment_date - @appointment_date.wday.days
            existing_sundays = @appointment.cycle_appointments.where.not(id: @appointment.id).where.not(status: %w[canceled completed]).map do |a|
              d = Date.parse(a.appointment_date.to_s)
              d - d.wday.days
            end

            if existing_sundays.include?(new_sunday)
              raise 'Você já possui uma sessão deste pacote agendada para a semana da data escolhida.'
            end

            # Validação de sequência cronológica (sem trava de mês)
            all_appointments = @appointment.cycle_appointments.where.not(status: 'canceled').order(appointment_date: :asc, start_time: :asc)
            current_index = all_appointments.index { |a| a.id == @appointment.id }

            if current_index.present? && all_appointments.length > 0
              seq_min_date = current_index > 0 ? all_appointments[current_index - 1].appointment_date : nil
              seq_max_date = current_index < all_appointments.length - 1 ? all_appointments[current_index + 1].appointment_date : nil

              # Compara por semana (domingos) para permitir reagendar dentro da mesma semana
              new_sunday = @appointment_date - @appointment_date.wday.days

              if seq_min_date.present?
                prev_sunday = seq_min_date - seq_min_date.wday.days
                if new_sunday <= prev_sunday
                  raise "Esta sessão não pode ser agendada em uma semana anterior ou igual à sessão anterior do pacote."
                end
              end

              if seq_max_date.present?
                next_sunday = seq_max_date - seq_max_date.wday.days
                if new_sunday >= next_sunday
                  raise "Esta sessão não pode ser agendada em uma semana posterior ou igual à próxima sessão do pacote."
                end
              end
            end
          end

          # Valida se o profissional realiza o serviço selecionado
          unless EmployeeService.exists?(user_id: employee.id, service_id: @service_id)
            raise 'O profissional selecionado não realiza este serviço.'
          end

          service = establishment.services.find(@service_id)
          duration_minutes = service.duration_minutes.to_i

          parsed_start = Time.zone.parse("2000-01-01 #{@start_time}")
          raise 'Horário inválido.' if parsed_start.blank?

          parsed_end       = parsed_start + duration_minutes.minutes
          parsed_start_str = parsed_start.strftime('%H:%M')
          parsed_end_str   = parsed_end.strftime('%H:%M')

          # SQL-based conflict check for better performance and consistency
          conflict = Appointment.active_for_schedule
                                .where(
                                  establishment_id: @appointment.establishment_id,
                                  employee_id: employee.id,
                                  appointment_date: @appointment_date
                                )
                                .where.not(id: @appointment.id)
                                .where('start_time < ? AND end_time > ?', parsed_end_str, parsed_start_str)
                                .exists?

          raise 'Já existe um agendamento nesse horário para este profissional.' if conflict

          @appointment.update!(
            service_id: @service_id,
            service_name_snapshot: service.name,
            duration_minutes: duration_minutes,
            employee_id: employee.id,
            employee_name_snapshot: employee.name,
            appointment_date: @appointment_date,
            start_time: parsed_start_str,
            end_time: parsed_end_str,
            status: 'confirmed'
          )
        end

        # Envia emails de notificação de reagendamento (fora da transação)
        send_reschedule_emails(old_date, old_time)

        @appointment
      end

      private

      def send_reschedule_emails(old_date, old_time)
        establishment = @appointment.establishment

        # Email para o cliente
        if @appointment.customer&.email.present?
          AppointmentMailer.customer_reschedule_notification(@appointment, old_date, old_time).deliver_later
        end

        # Email para o profissional
        if @appointment.employee&.email.present?
          AppointmentMailer.employee_reschedule_notification(@appointment, old_date, old_time).deliver_later
        end

        # Email para o proprietário
        owner = establishment.owner
        if owner&.email.present?
          AppointmentMailer.owner_reschedule_notification(@appointment, old_date, old_time).deliver_later
        end
      rescue => e
        Rails.logger.error("[RescheduleService] Falha ao enviar emails de reagendamento: #{e.message}")
      end
    end
  end
end