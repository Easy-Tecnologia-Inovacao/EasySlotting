# lib/tasks/audit_log.rake
# Rake task para acionamento manual ou via cron para expurgo de audit logs antigos.
# Uso: bundle exec rake audit_logs:cleanup[730]

namespace :audit_logs do
  desc "Remove registros de AuditLog mais antigos que X dias (padrão 730 dias / 2 anos)"
  task :cleanup, [:days] => :environment do |_t, args|
    days = (args[:days] || 730).to_i
    puts "Iniciando expurgo de audit logs com mais de #{days} dias..."
    AuditLogCleanupJob.perform_now(days)
    puts "Expurgo finalizado com sucesso."
  end
end
