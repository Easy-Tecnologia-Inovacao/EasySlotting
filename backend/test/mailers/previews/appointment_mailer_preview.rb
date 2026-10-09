# Preview all emails at http://localhost:3000/rails/mailers/appointment_mailer
class AppointmentMailerPreview < ActionMailer::Preview
  def customer_notification_package
    appointment = Appointment.joins(:service_package)
                             .where.not(service_package_id: nil)
                             .order(created_at: :desc)
                             .first

    if appointment
      AppointmentMailer.customer_notification(appointment)
    else
      # Fallback: cria um appointment fake para preview
      AppointmentMailer.customer_notification(build_fake_package_appointment)
    end
  end

  def customer_notification_single
    appointment = Appointment.where(service_package_id: nil)
                             .order(created_at: :desc)
                             .first

    if appointment
      AppointmentMailer.customer_notification(appointment)
    else
      AppointmentMailer.customer_notification(build_fake_single_appointment)
    end
  end

  private

  def build_fake_package_appointment
    OpenStruct.new(
      id: 999,
      appointment_date: Date.tomorrow,
      start_time: '14:00',
      end_time: '15:00',
      price_snapshot: 120.0,
      service_package_id: 1,
      created_at: Time.current,
      status: 'pending',
      customer: OpenStruct.new(
        name: 'João da Silva',
        email: 'cortes.cortes0234@gmail.com',
        active?: true
      ),
      employee: OpenStruct.new(
        name: 'Maria Barbeira',
        email: 'funcionario@teste.com'
      ),
      service: OpenStruct.new(
        name: 'Corte Degradê',
        price: 45.0,
        duration_minutes: 30
      ),
      service_package: OpenStruct.new(
        name: 'Pacote Mensal Premium',
        sessions_total: 4,
        duration_minutes: 30
      ),
      establishment: OpenStruct.new(
        name: 'Barbearia EasySloting',
        phone: '47999894953',
        timezone: 'America/Sao_Paulo',
        owner: OpenStruct.new(email: 'dono@teste.com'),
        address: OpenStruct.new(
          street: 'Rua Jorge',
          number: '387',
          neighborhood: 'Itinga',
          city: 'Araquari',
          state: 'SC'
        )
      )
    )
  end

  def build_fake_single_appointment
    OpenStruct.new(
      id: 888,
      appointment_date: Date.tomorrow,
      start_time: '10:00',
      end_time: '10:30',
      price_snapshot: 45.0,
      service_package_id: nil,
      created_at: Time.current,
      status: 'pending',
      customer: OpenStruct.new(
        name: 'João da Silva',
        email: 'cortes.cortes0234@gmail.com',
        active?: true
      ),
      employee: OpenStruct.new(
        name: 'Maria Barbeira',
        email: 'funcionario@teste.com'
      ),
      service: OpenStruct.new(
        name: 'Corte Degradê',
        price: 45.0,
        duration_minutes: 30
      ),
      service_package: nil,
      establishment: OpenStruct.new(
        name: 'Barbearia EasySloting',
        phone: '47999894953',
        timezone: 'America/Sao_Paulo',
        owner: OpenStruct.new(email: 'dono@teste.com'),
        address: OpenStruct.new(
          street: 'Rua Jorge',
          number: '387',
          neighborhood: 'Itinga',
          city: 'Araquari',
          state: 'SC'
        )
      )
    )
  end
end
