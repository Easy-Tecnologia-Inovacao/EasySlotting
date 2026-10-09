namespace :audit do
  desc 'Remove logs de auditoria com mais de 90 dias (LGPD - minimização de dados)'
  task retention: :environment do
    cutoff = 90.days.ago
    count = AuditLog.where('created_at < ?', cutoff).delete_all
    puts "#{count} log(s) de auditoria antigo(s) removido(s) (anteriores a #{cutoff.strftime('%d/%m/%Y')})."
  end
end

# Para agendar via cron (adicione ao crontab do servidor):
# 0 3 * * 0 cd /caminho/api && RAILS_ENV=production bundle exec rake audit:retention
# Executa todo domingo às 3h da manhã.
