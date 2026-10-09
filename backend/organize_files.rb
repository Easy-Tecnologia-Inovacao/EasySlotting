require 'fileutils'

api_dir = __dir__
puts "Iniciando a organizacao dos arquivos..."

# 1. Mover Models
models_dir = File.join(api_dir, 'app', 'models')
model_groups = {
  'core' => %w[user.rb establishment.rb address.rb business_hour.rb establishment_membership.rb],
  'team' => %w[archived_employee.rb employee_service.rb employee_working_hour.rb],
  'scheduling' => %w[appointment.rb service.rb service_package.rb service_package_usage.rb service_package_sale.rb],
  'financial' => %w[financial_transaction.rb commission.rb plan.rb subscription.rb subscription_cancellation.rb],
  'inventory' => %w[stock_item.rb]
}

model_groups.each do |folder, files|
  target_dir = File.join(models_dir, folder)
  FileUtils.mkdir_p(target_dir)

  files.each do |file|
    source = File.join(models_dir, file)
    target = File.join(target_dir, file)

    if File.exist?(source)
      FileUtils.mv(source, target)
      puts "✅ Model movido: #{file} -> #{folder}/#{file}"
    end
  end
end

# 2. Corrigir CustomerProfileController perdido em models
wrong_profile = File.join(models_dir, 'customer_profile_controller.rb')
if File.exist?(wrong_profile)
  target_dir = File.join(api_dir, 'app', 'controllers', 'customer')
  FileUtils.mkdir_p(target_dir)
  target_file = File.join(target_dir, 'profile_controller.rb')
  
  content = File.read(wrong_profile)
  content.sub!(/class\s+CustomerProfileController/, "class Customer::ProfileController")
  
  File.write(target_file, content)
  FileUtils.rm(wrong_profile)
  puts "✅ CustomerProfileController movido de models para controllers/customer/profile_controller.rb"
end

# 3. Mover e renomear Controllers
controllers_dir = File.join(api_dir, 'app', 'controllers')
controller_moves = {
  'admin_establishments_controller.rb' => ['admin', 'establishments_controller.rb', 'Admin::EstablishmentsController', 'AdminEstablishmentsController'],
  'admin_team_controller.rb' => ['admin', 'team_controller.rb', 'Admin::TeamController', 'AdminTeamController'],
  'admin_customers_controller.rb' => ['admin', 'customers_controller.rb', 'Admin::CustomersController', 'AdminCustomersController'],
  'admin_team_schedule_controller.rb' => ['admin', 'team_schedule_controller.rb', 'Admin::TeamScheduleController', 'AdminTeamScheduleController'],
  'appointments_controller.rb' => ['admin', 'appointments_controller.rb', 'Admin::AppointmentsController', 'AppointmentsController'],
  'services_controller.rb' => ['admin', 'services_controller.rb', 'Admin::ServicesController', 'ServicesController'],
  'service_packages_controller.rb' => ['admin', 'service_packages_controller.rb', 'Admin::ServicePackagesController', 'ServicePackagesController'],
  'stock_items_controller.rb' => ['admin', 'stock_items_controller.rb', 'Admin::StockItemsController', 'StockItemsController'],
  'customer_appointments_controller.rb' => ['customer', 'appointments_controller.rb', 'Customer::AppointmentsController', 'CustomerAppointmentsController'],
  'public_establishments_controller.rb' => ['public', 'establishments_controller.rb', 'Public::EstablishmentsController', 'PublicEstablishmentsController'],
  'public_booking_controller.rb' => ['public', 'booking_controller.rb', 'Public::BookingController', 'PublicBookingController'],
  'owner_onboarding_controller.rb' => ['account', 'onboarding_controller.rb', 'Account::OnboardingController', 'OwnerOnboardingController'],
  'users_controller.rb' => ['account', 'users_controller.rb', 'Account::UsersController', 'UsersController'],
  'subscriptions_controller.rb' => ['account', 'subscriptions_controller.rb', 'Account::SubscriptionsController', 'SubscriptionsController']
}

controller_moves.each do |old_file, (folder, new_file, new_class, old_class)|
  source = File.join(controllers_dir, old_file)
  if File.exist?(source)
    target_dir = File.join(controllers_dir, folder)
    FileUtils.mkdir_p(target_dir)
    target = File.join(target_dir, new_file)

    content = File.read(source)
    content.sub!(/class\s+#{old_class}/, "class #{new_class}")
    
    File.write(target, content)
    FileUtils.rm(source)
    puts "✅ Controller movido: #{old_file} -> #{folder}/#{new_file} (#{new_class})"
  end
end

puts "Concluido! Arquivos organizados com sucesso."
