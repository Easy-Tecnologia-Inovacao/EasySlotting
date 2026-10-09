
# test/security_check.rb
require_relative "../config/environment"
require "securerandom"

puts "--- INICIANDO VERIFICAÇÃO DE SEGURANÇA (SCRIPT DIRETO) ---"

def check(name)
  print "Rodando: #{name}... "
  yield
  puts " [PASSOU]"
rescue => e
  puts " [FALHOU]"
  puts "  Erro: #{e.message}"
  if e.respond_to?(:record) && e.record
    puts "  Detalhes: #{e.record.errors.full_messages}" 
  else
    puts "  Stack: #{e.backtrace.first(3).join("\n  ")}"
  end
end

suffix = SecureRandom.hex(4)

check("Criação de Massa de Dados") do
  @owner = User.create!(
    name: "Owner Test",
    email: "owner-#{suffix}@test.com", 
    password: "password123", 
    role: "owner", 
    confirmed_at: Time.current, 
    uid: "owner-#{suffix}@test.com", 
    provider: "email"
  )
  
  @est_a = Establishment.create!(name: "Est A", slug: "est-a-#{suffix}", email: "a-#{suffix}@test.com", owner: @owner)
  
  @service = Service.create!(
    establishment: @est_a, 
    name: "Corte", 
    price: 50.0, 
    duration_minutes: 30,
    service_type: "normal"
  )
end

check("Isolamento Multitenant") do
  @est_b = Establishment.create!(name: "Est B", slug: "est-b-#{suffix}", email: "b-#{suffix}@test.com", owner: @owner)
  @customer_b = Customer.create!(
    establishment: @est_b, 
    name: "Cli B", 
    email: "clib@test.com", 
    password: "password123"
  )
  
  found = @est_a.customers.find_by(id: @customer_b.id)
  raise "Vazamento detectado!" if found
end

check("Proteção de Concorrência (Double Booking)") do
  params = {
    establishment: @est_a,
    customer: Customer.create!(
      establishment: @est_a, 
      name: "Cli A", 
      email: "clia-#{suffix}@test.com", 
      password: "password123"
    ),
    service: @service,
    employee_id: @owner.id,
    appointment_date: Date.current + 1.day,
    start_time: "10:00",
    end_time: "10:30",
    status: 'pending'
  }
  
  Appointment.create!(params)
  
  begin
    Appointment.create!(params)
    raise "Deveria ter falhado!"
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # Sucesso
  end
end

check("Pessimistic Locking") do
  sale = ServicePackageSale.create!(
    establishment: @est_a,
    customer: Customer.create!(
      establishment: @est_a, 
      name: "Cli A 2", 
      email: "clia2-#{suffix}@test.com", 
      password: "password123"
    ),
    service_package: ServicePackage.create!(establishment: @est_a, name: "Pack", price: 100, duration_minutes: 30),
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
  raise "Lock falhou" unless sale.sessions_used == 1
end

puts "--- VERIFICAÇÃO CONCLUÍDA ---"
