
# test/security_suite.rb
require_relative "../config/environment"
require "minitest/autorun"
require "securerandom"

class SecuritySuiteTest < ActiveSupport::TestCase
  def setup
    begin
      suffix = SecureRandom.hex(4)
      @owner_a = User.create!(
        name: "Owner A",
        email: "owner-#{suffix}-1@test.com", 
        password: "Seguranca#2026", 
        role: "owner", 
        confirmed_at: Time.current, 
        uid: "owner-#{suffix}-1@test.com", 
        provider: "email"
      )
      
      @owner_b = User.create!(
        name: "Owner B",
        email: "owner-#{suffix}-2@test.com", 
        password: "Seguranca#2026", 
        role: "owner", 
        confirmed_at: Time.current, 
        uid: "owner-#{suffix}-2@test.com", 
        provider: "email"
      )
      
      @est_a = Establishment.create!(name: "Est A", slug: "est-a-#{suffix}", email: "a-#{suffix}@test.com", owner: @owner_a)
      @est_b = Establishment.create!(name: "Est B", slug: "est-b-#{suffix}", email: "b-#{suffix}@test.com", owner: @owner_b)
      
      @employee_a = User.create!(
        name: "Emp A",
        email: "emp-#{suffix}@test.com", 
        password: "Seguranca#2026", 
        role: "employee", 
        confirmed_at: Time.current, 
        uid: "emp-#{suffix}@test.com", 
        provider: "email"
      )
      
      EstablishmentMembership.create!(establishment: @est_a, user: @owner_a, role: 'owner')
      EstablishmentMembership.create!(establishment: @est_b, user: @owner_b, role: 'owner')
      EstablishmentMembership.create!(establishment: @est_a, user: @employee_a, role: 'employee')

      @customer_b = Customer.create!(establishment: @est_b, name: "Cliente B", email: "b-#{suffix}@test.com", password: "Seguranca#2026")
      
      # Use plain class names due to Zeitwerk collapse config
      @service_a = Service.create!(
        establishment: @est_a, 
        name: "Corte", 
        price: 50.0, 
        duration_minutes: 30,
        service_type: "normal"
      )
    rescue => e
      puts "\n!!! ERRO CRITICO NO SETUP DO TESTE !!!"
      puts "Mensagem: #{e.message}"
      puts "Erros: #{e.record.errors.full_messages}" if e.respond_to?(:record)
      raise e
    end
  end

  def test_multitenancy_isolation
    puts "Rodando: test_multitenancy_isolation"
    found = @est_a.customers.find_by(id: @customer_b.id)
    assert_nil found, "Vazamento detectado! Est A acessou cliente do Est B."
  end

  def test_double_booking_protection
    puts "Rodando: test_double_booking_protection"
    
    appointment_params = {
      establishment: @est_a,
      customer: Customer.create!(establishment: @est_a, name: "Cli A", email: "cli-a-#{SecureRandom.hex(4)}@test.com", password: "Seguranca#2026"),
      service: @service_a,
      employee_id: @employee_a.id,
      appointment_date: Date.current + 1.day,
      start_time: "10:00",
      end_time: "10:30",
      status: 'pending'
    }

    # Plain class name
    Appointment.create!(appointment_params)

    begin
      Appointment.create!(appointment_params)
      flunk "Deveria ter impedido o agendamento duplicado!"
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      assert true
    end
  end

  def test_pessimistic_locking
    puts "Rodando: test_pessimistic_locking"
    pkg = ServicePackage.create!(
      establishment: @est_a,
      service: @service_a,
      name: "Pack",
      price: 100,
      duration_minutes: 30,
      sessions_total: 10,
      active: true
    )
    
    sale = ServicePackageSale.create!(
      establishment: @est_a,
      customer: Customer.create!(establishment: @est_a, name: "Cli A", email: "cli-b-#{SecureRandom.hex(4)}@test.com", password: "Seguranca#2026"),
      service_package: pkg,
      sessions_total: 10,
      sessions_used: 0,
      status: 'active',
      sold_at: Time.current,
      total_price: 100.0
    )

    sale.with_lock do
      sale.sessions_used += 1
      sale.save!
    end
    assert_equal 1, sale.sessions_used
  end
end
