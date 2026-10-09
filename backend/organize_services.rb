require 'fileutils'

api_dir = __dir__
puts "Iniciando organizacao dos Services..."

# 1. Deletar application.rb invalido (se existir)
app_service = File.join(api_dir, 'app', 'services', 'financial', 'application.rb')
if File.exist?(app_service)
  FileUtils.rm(app_service)
  puts "✅ app/services/financial/application.rb removido."
end

# 2. Mover appointments de financial para scheduling e mudar namespace
fin_appointments_dir = File.join(api_dir, 'app', 'services', 'financial', 'appointments')
sch_appointments_dir = File.join(api_dir, 'app', 'services', 'scheduling', 'appointments')

if Dir.exist?(fin_appointments_dir)
  FileUtils.mkdir_p(sch_appointments_dir)

  Dir.glob(File.join(fin_appointments_dir, '*.rb')).each do |source|
    filename = File.basename(source)
    target = File.join(sch_appointments_dir, filename)

    content = File.read(source)
    # Mudar módulo de Financial::Appointments:: para Scheduling::Appointments::
    content.gsub!(/module Financial\n  module Appointments/, "module Scheduling\n  module Appointments")
    
    File.write(target, content)
    FileUtils.rm(source)
    puts "✅ Service movido: financial/appointments/#{filename} -> scheduling/appointments/#{filename}"
  end

  # Remover a pasta velha se estiver vazia
  if Dir.empty?(fin_appointments_dir)
    Dir.rmdir(fin_appointments_dir)
    puts "✅ Diretorio vazio removido: app/services/financial/appointments"
  end
else
  puts "⚠️ Diretorio app/services/financial/appointments não encontrado (já movido ou inexistente)."
end

puts "Concluido! Services organizados."
