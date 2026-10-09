# app/jobs/audit_log_cleanup_job.rb
# Job para expurgo automatizado de logs de auditoria antigos (LGPD / Marco Civil da Internet)
# Retenção padrão: 730 dias (2 anos)
# Utiliza SolidQueue (nativo do Rails 8) sem necessidade de Redis/Sidekiq.

class AuditLogCleanupJob < ApplicationJob
  queue_as :default

  def perform(retention_days = 730)
    cutoff_date = retention_days.days.ago
    deleted_count = 0

    # Processa em lotes de 1000 para evitar lock de tabela e pico de memória
    AuditLog.where('created_at < ?', cutoff_date).in_batches(of: 1000) do |relation|
      count = relation.delete_all
      deleted_count += count
    end

    Rails.logger.info("[AuditLogCleanupJob] Expurgo concluído. #{deleted_count} registros anteriores a #{cutoff_date.iso8601} foram removidos.")
  rescue => e
    Rails.logger.error("[AuditLogCleanupJob] Falha ao expurgar audit logs: #{e.message}")
    raise e
  end
end
