# Demo data is destructive and must never run in staging/production.
if Rails.env.development?
puts '==========================================='
puts '      INICIANDO SEED DO BANCO DE DADOS     '
puts '==========================================='
puts 'Limpando dados antigos...'

# TRUNCATE com CASCADE evita erros de chave estrangeira no PostgreSQL
# Isso limpa o banco de dados antes de popular novamente, para não duplicar.
ActiveRecord::Base.connection.truncate_tables(
  :service_package_usages, :service_package_sales, :financial_transactions,
  :commissions, :appointments, :stock_items, :employee_services,
  :employee_schedule_exceptions, :employee_working_hours, :business_hours,
  :customers, :establishment_memberships, :addresses, :subscription_cancellations,
  :subscriptions, :service_packages, :services, :establishments, :plans, :users,
  cascade: true, reset_sequences: true
) rescue nil

# Fallback sequencial se o truncate_tables não funcionar
if User.count > 0
  ServicePackageUsage.delete_all
  ServicePackageSale.delete_all
  FinancialTransaction.delete_all
  Commission.delete_all
  Appointment.delete_all
  StockItem.delete_all
  EmployeeService.delete_all
  EmployeeScheduleException.delete_all
  EmployeeWorkingHour.delete_all
  BusinessHour.delete_all
  Customer.delete_all
  EstablishmentMembership.delete_all
  Address.delete_all
  SubscriptionCancellation.delete_all
  Subscription.delete_all
  ServicePackage.delete_all
  Service.delete_all
  Establishment.delete_all
  Plan.delete_all
  User.delete_all
end

puts 'Criando planos...'
# =========================================================
# PLANOS DO SISTEMA
# Necessários para vincular às assinaturas das empresas
# =========================================================
monthly_plan = Plan.create!(
  code: 'monthly',
  name: 'Plano Mensal',
  description: 'Ideal para estabelecimentos que estão começando.',
  price: 49.90,
  duration_months: 1,
  active: true,
  highlight: false
)

puts 'Criando Super Admin...'
# =========================================================
# 1. SUPER ADMIN - Administrador Geral do Sistema
# Esse usuário acessa o painel de administração global (Planos, etc.)
# =========================================================
admin_email = ENV.fetch('BOOTSTRAP_ADMIN_EMAIL', 'admin@example.test').strip.downcase
admin_password = ENV['BOOTSTRAP_ADMIN_PASSWORD'].presence || "#{SecureRandom.hex(24)}Z9!"
puts 'Para acessar o super admin do seed, configure BOOTSTRAP_ADMIN_EMAIL/PASSWORD antes de executar; a senha não é exibida.'
super_admin = User.create!(
  name: 'Super Admin',
  email: admin_email,
  password: admin_password,
  password_confirmation: admin_password,
  role: 'super_admin',
  uid: admin_email,
  provider: 'email',
  active: true
)

puts 'Criando Owners (Donos de Empresa)...'
# =========================================================
# 2. OWNERS - Donos de Estabelecimentos (2 Donos)
# Eles têm acesso total ao painel da sua respectiva empresa
# =========================================================
owner1 = User.create!(
  name: 'Dono Empresa 1',
  email: 'dono1@empresa.com',
  password: 'Slot@2024',
  password_confirmation: 'Slot@2024',
  role: 'owner',
  uid: 'dono1@empresa.com',
  provider: 'email',
  active: true,
  phone: '(11) 99999-0001'
)

owner2 = User.create!(
  name: 'Dono Empresa 2',
  email: 'dono2@empresa.com',
  password: 'Slot@2024',
  password_confirmation: 'Slot@2024',
  role: 'owner',
  uid: 'dono2@empresa.com',
  provider: 'email',
  active: true,
  phone: '(11) 99999-0002'
)

puts 'Criando Estabelecimentos...'
# =========================================================
# 3. ESTABELECIMENTOS - Uma empresa para cada Owner
# =========================================================
est1 = Establishment.create!(
  name: 'Empresa do Dono 1',
  slug: 'empresa-1',
  owner: owner1,
  active: true,
  category: 'barbearia',
  description: 'Descrição da Empresa 1.',
  email: 'contato@empresa1.com',
  phone: '1133330001',
  status: 'active',
  timezone: 'America/Sao_Paulo'
)

# Endereço e Assinatura da Empresa 1
Address.create!(establishment: est1, street: 'Rua Um', number: '100', neighborhood: 'Centro', city: 'São Paulo', state: 'SP', country: 'Brasil')
Subscription.create!(establishment: est1, plan: monthly_plan, status: 'active', billing_cycle: 'monthly', start_date: Date.current, end_date: Date.current + 30.days)

est2 = Establishment.create!(
  name: 'Empresa do Dono 2',
  slug: 'empresa-2',
  owner: owner2,
  active: true,
  category: 'salao_beleza',
  description: 'Descrição da Empresa 2.',
  email: 'contato@empresa2.com',
  phone: '1133330002',
  status: 'active',
  timezone: 'America/Sao_Paulo'
)

# Endereço e Assinatura da Empresa 2
Address.create!(establishment: est2, street: 'Rua Dois', number: '200', neighborhood: 'Jardins', city: 'São Paulo', state: 'SP', country: 'Brasil')
Subscription.create!(establishment: est2, plan: monthly_plan, status: 'active', billing_cycle: 'monthly', start_date: Date.current, end_date: Date.current + 30.days)

# Criando Horários de funcionamento para as duas empresas (Segunda a Sábado)
[est1, est2].each do |est|
  (1..6).each do |weekday|
    BusinessHour.create!(establishment: est, weekday: weekday, is_open: true, start_time: '08:00', end_time: '19:00')
  end
  # Domingo fechado
  BusinessHour.create!(establishment: est, weekday: 0, is_open: false)
end

puts 'Criando Funcionários (Employees)...'
# =========================================================
# 4. FUNCIONÁRIOS (Employees) - 2 para cada empresa
# =========================================================
# Funcionários da Empresa 1
emp1_est1 = User.create!(name: 'Funcionario 1 (Emp 1)', email: 'func1@empresa1.com', password: 'Slot@2024', password_confirmation: 'Slot@2024', role: 'employee', uid: 'func1@empresa1.com', active: true)
emp2_est1 = User.create!(name: 'Funcionario 2 (Emp 1)', email: 'func2@empresa1.com', password: 'Slot@2024', password_confirmation: 'Slot@2024', role: 'employee', uid: 'func2@empresa1.com', active: true)

# Funcionários da Empresa 2
emp1_est2 = User.create!(name: 'Funcionario 1 (Emp 2)', email: 'func1@empresa2.com', password: 'Slot@2024', password_confirmation: 'Slot@2024', role: 'employee', uid: 'func1@empresa2.com', active: true)
emp2_est2 = User.create!(name: 'Funcionario 2 (Emp 2)', email: 'func2@empresa2.com', password: 'Slot@2024', password_confirmation: 'Slot@2024', role: 'employee', uid: 'func2@empresa2.com', active: true)

# Vinculando os funcionários aos seus respectivos estabelecimentos e criando horários
[ [emp1_est1, est1], [emp2_est1, est1], [emp1_est2, est2], [emp2_est2, est2] ].each do |emp, est|
  EstablishmentMembership.create!(
    user: emp, establishment: est, role: 'employee', active: true,
    financial_model: 'porcentagem', financial_value: 50.0,
    can_manage_schedule: true, can_view_only_own_clients: true
  )
  
  # Horários de trabalho do funcionário (Segunda a Sábado, 9h-12h e 13h-18h)
  (1..6).each do |weekday|
    EmployeeWorkingHour.create!(user: emp, weekday: weekday, is_available: true, morning_start_time: '09:00', morning_end_time: '12:00', afternoon_start_time: '13:00', afternoon_end_time: '18:00')
  end
  EmployeeWorkingHour.create!(user: emp, weekday: 0, is_available: false) # Domingo
end

puts 'Criando Serviços...'
# =========================================================
# 5. SERVIÇOS E VÍNCULO DE FUNCIONÁRIOS AOS SERVIÇOS
# =========================================================
# Serviços Empresa 1
servico_corte_est1 = Service.create!(establishment: est1, name: 'Corte Simples', duration_minutes: 30, price: 50.0, active: true, service_type: 'servico')
servico_barba_est1 = Service.create!(establishment: est1, name: 'Barba Modelada', duration_minutes: 20, price: 30.0, active: true, service_type: 'servico')

# Serviços Empresa 2
servico_corte_est2 = Service.create!(establishment: est2, name: 'Corte Especial', duration_minutes: 60, price: 100.0, active: true, service_type: 'servico')
servico_pintura_est2 = Service.create!(establishment: est2, name: 'Pintura', duration_minutes: 120, price: 200.0, active: true, service_type: 'servico')

# Vinculando quem faz qual serviço
EmployeeService.create!(user: emp1_est1, service: servico_corte_est1)
EmployeeService.create!(user: emp2_est1, service: servico_barba_est1)

EmployeeService.create!(user: emp1_est2, service: servico_corte_est2)
EmployeeService.create!(user: emp2_est2, service: servico_pintura_est2)

puts 'Criando Clientes (Customers)...'
# =========================================================
# 6. CLIENTES (Customers) - 2 para cada empresa
# Clientes acessam a página pública e têm seu próprio login isolado
# =========================================================
cliente1_est1 = Customer.create!(establishment: est1, name: 'Cliente 1 (Emp 1)', email: 'cliente1@empresa1.com', password: 'Slot@2024', phone: '11900000001', active: true)
cliente2_est1 = Customer.create!(establishment: est1, name: 'Cliente 2 (Emp 1)', email: 'cliente2@empresa1.com', password: 'Slot@2024', phone: '11900000002', active: true)

cliente1_est2 = Customer.create!(establishment: est2, name: 'Cliente 1 (Emp 2)', email: 'cliente1@empresa2.com', password: 'Slot@2024', phone: '11900000003', active: true)
cliente2_est2 = Customer.create!(establishment: est2, name: 'Cliente 2 (Emp 2)', email: 'cliente2@empresa2.com', password: 'Slot@2024', phone: '11900000004', active: true)

puts 'Criando alguns Agendamentos (Appointments)...'
# =========================================================
# 7. AGENDAMENTOS AVULSOS (Exemplo para o Dashboard não ficar vazio)
# =========================================================
Appointment.create!(
  customer: cliente1_est1, employee: emp1_est1, establishment: est1, service: servico_corte_est1,
  appointment_date: Date.current, start_time: '10:00', end_time: '10:30', duration_minutes: 30,
  price_snapshot: 50.0, status: 'confirmed', service_name_snapshot: 'Corte Simples', customer_name_snapshot: 'Cliente 1 (Emp 1)', employee_name_snapshot: 'Funcionario 1 (Emp 1)'
)

Appointment.create!(
  customer: cliente1_est2, employee: emp1_est2, establishment: est2, service: servico_corte_est2,
  appointment_date: Date.current + 1.day, start_time: '14:00', end_time: '15:00', duration_minutes: 60,
  price_snapshot: 100.0, status: 'pending', service_name_snapshot: 'Corte Especial', customer_name_snapshot: 'Cliente 1 (Emp 2)', employee_name_snapshot: 'Funcionario 1 (Emp 2)'
)

puts 'Criando Pacotes de Serviço (ServicePackages)...'
# =========================================================
# 8. PACOTES DE SERVIÇO (ServicePackages)
# Cada pacote é vinculado a um serviço e tem um número de sessões
# O cliente compra o pacote e agenda as sessões individualmente
# =========================================================
# --- Empresa 1: 2 pacotes de Corte Simples ---
pacote_corte_4x_est1 = ServicePackage.create!(
  establishment: est1,
  service: servico_corte_est1,
  name: 'Pacote Corte Mensal (4 sessões)',
  description: 'Quatro cortes simples por mês. Economize 20% em relação ao avulso!',
  sessions_total: 4,
  duration_minutes: 30,         # duração de cada sessão (igual ao serviço)
  price: 160.0,                 # 4x R$50 com desconto = R$160 (era R$200)
  included_items: '4 cortes simples, atendimento prioritário',
  active: true
)

pacote_barba_2x_est1 = ServicePackage.create!(
  establishment: est1,
  service: servico_barba_est1,
  name: 'Pacote Barba Quinzenal (2 sessões)',
  description: 'Duas modelagens de barba por mês. Preço especial de pacote.',
  sessions_total: 2,
  duration_minutes: 20,
  price: 50.0,                  # 2x R$30 com desconto = R$50 (era R$60)
  included_items: '2 modelagens de barba',
  active: true
)

# --- Empresa 2: 2 pacotes ---
pacote_corte_4x_est2 = ServicePackage.create!(
  establishment: est2,
  service: servico_corte_est2,
  name: 'Pacote Corte Premium (4 sessões)',
  description: 'Quatro cortes especiais com desconto exclusivo de pacote.',
  sessions_total: 4,
  duration_minutes: 60,
  price: 350.0,                 # 4x R$100 com desconto = R$350 (era R$400)
  included_items: '4 cortes especiais, hidratação capilar inclusa',
  active: true
)

pacote_pintura_2x_est2 = ServicePackage.create!(
  establishment: est2,
  service: servico_pintura_est2,
  name: 'Pacote Pintura Mensal (2 sessões)',
  description: 'Duas pinturas por mês com produtos premium.',
  sessions_total: 2,
  duration_minutes: 120,
  price: 360.0,                 # 2x R$200 com desconto = R$360 (era R$400)
  included_items: '2 pinturas, tintura premium, hidratação pós-coloração',
  active: true
)

puts 'Criando Vendas e Agendamentos de Pacote para Teste...'
# =========================================================
# 9. VENDA + AGENDAMENTOS DE PACOTE (para o cliente 1 da empresa 1)
# Simula o cliente comprando o pacote de 4 cortes e já tendo agendado 2 sessões
# =========================================================

# Venda do pacote (ServicePackageSale)
venda_pacote_est1 = ServicePackageSale.create!(
  establishment: est1,
  customer: cliente1_est1,
  service_package: pacote_corte_4x_est1,
  sessions_total: 4,
  sessions_used: 1,             # apenas 1 sessão JÁ CONCLUÍDA; a futura é "agendada", não "usada"
  total_price: 160.0,
  status: 'active',
  sold_at: 1.week.ago
)

# Sessão 1 do pacote - já concluída (semana passada)
apt_pacote_1 = Appointment.create!(
  customer: cliente1_est1,
  employee: emp1_est1,
  establishment: est1,
  service: servico_corte_est1,
  service_package: pacote_corte_4x_est1,
  appointment_date: Date.current - 7.days,
  start_time: '09:00', end_time: '09:30',
  duration_minutes: 30,
  price_snapshot: 40.0,
  status: 'completed',
  service_name_snapshot: 'Corte Simples', customer_name_snapshot: 'Cliente 1 (Emp 1)', employee_name_snapshot: 'Funcionario 1 (Emp 1)'
)

# Sessão 2 do pacote - agendada para a próxima semana (confirmada, ainda NÃO realizada)
# Não tem ServicePackageUsage — usage é criado apenas quando a sessão é CONCLUÍDA
Appointment.create!(
  customer: cliente1_est1,
  employee: emp1_est1,
  establishment: est1,
  service: servico_corte_est1,
  service_package: pacote_corte_4x_est1,
  appointment_date: Date.current + 7.days,
  start_time: '09:00', end_time: '09:30',
  duration_minutes: 30,
  price_snapshot: 40.0,
  status: 'confirmed',
  service_name_snapshot: 'Corte Simples', customer_name_snapshot: 'Cliente 1 (Emp 1)', employee_name_snapshot: 'Funcionario 1 (Emp 1)'
)

# Registro de uso APENAS da sessão concluída (usage = sessão realizada)
ServicePackageUsage.create!(service_package_sale: venda_pacote_est1, appointment: apt_pacote_1, used_at: apt_pacote_1.appointment_date)

puts '==========================================='
puts '             RESUMO DOS ACESSOS            '
puts '==========================================='
puts 'Super admin usa BOOTSTRAP_ADMIN_PASSWORD; as demais contas são demonstrações locais.'
puts ''
puts '--- SUPER ADMIN (Acesso ao Painel Geral de Super Admin) ---'
puts "Email: #{super_admin.email}"
puts ''
puts '--- DONOS (Owners - Acesso total ao Painel da Empresa) ---'
puts "Empresa 1: #{owner1.email}"
puts "Empresa 2: #{owner2.email}"
puts ''
puts '--- FUNCIONÁRIOS (Acesso limitado ao Painel da Empresa) ---'
puts "Empresa 1 - Func 1: #{emp1_est1.email}"
puts "Empresa 1 - Func 2: #{emp2_est1.email}"
puts "Empresa 2 - Func 1: #{emp1_est2.email}"
puts "Empresa 2 - Func 2: #{emp2_est2.email}"
puts ''
puts '--- CLIENTES (Acesso a página pública do estabelecimento) ---'
puts "Empresa 1 - Cliente 1: #{cliente1_est1.email}"
puts "Empresa 1 - Cliente 2: #{cliente2_est1.email}"
puts "Empresa 2 - Cliente 1: #{cliente1_est2.email}"
puts "Empresa 2 - Cliente 2: #{cliente2_est2.email}"
puts '==========================================='
puts 'Seed finalizado com sucesso!'
else
  load Rails.root.join('db/seeds/runtime.rb')
end
