namespace :backup do
  desc 'Cria backup do banco de dados PostgreSQL'
  task database: :environment do
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    backup_dir = Rails.root.join('tmp', 'backups')
    FileUtils.mkdir_p(backup_dir)

    backup_file = backup_dir.join("backup_#{timestamp}.sql.gz")

    db_config = ActiveRecord::Base.connection_db_config.configuration_hash
    host = db_config[:host] || 'localhost'
    port = db_config[:port] || 5432
    username = db_config[:username] || 'postgres'
    database = db_config[:database]
    password = db_config[:password]

    puts "Iniciando backup do banco #{database}..."

    env_vars = password.present? ? { 'PGPASSWORD' => password.to_s } : {}

    cmd = [
      'pg_dump',
      "--host=#{host}",
      "--port=#{port}",
      "--username=#{username}",
      "--dbname=#{database}",
      '--no-owner',
      '--no-privileges',
      '-Fc'
    ].join(' ')

    pid = Process.spawn(env_vars, "#{cmd} | gzip > #{backup_file}", out: '/dev/null', err: '/dev/null')
    Process.wait(pid)

    if $?.success?
      size_mb = (File.size(backup_file) / 1024.0 / 1024.0).round(2)
      puts "Backup criado com sucesso: #{backup_file} (#{size_mb} MB)"

      backups = Dir.glob(backup_dir.join('backup_*.sql.gz')).sort
      if backups.length > 7
        old_backups = backups.first(backups.length - 7)
        old_backups.each do |old|
          File.delete(old)
          puts "Backup antigo removido: #{File.basename(old)}"
        end
      end
    else
      puts "ERRO: Falha ao criar backup."
      exit 1
    end
  end

  desc 'Remove backups com mais de 90 dias'
  task cleanup: :environment do
    backup_dir = Rails.root.join('tmp', 'backups')
    return unless Dir.exist?(backup_dir)

    cutoff = 90.days.ago
    removed = 0

    Dir.glob(backup_dir.join('backup_*.sql.gz')).each do |file|
      if File.mtime(file) < cutoff
        File.delete(file)
        removed += 1
      end
    end

    puts "#{removed} backup(s) antigo(s) removido(s)."
  end
end

# Agendamento via cron (adicione ao crontab do servidor):
# 0 2 * * * cd /caminho/api && RAILS_ENV=production bundle exec rake backup:database
# 0 4 1 * * cd /caminho/api && RAILS_ENV=production bundle exec rake backup:cleanup
#
# NOTA: Backups ficam apenas localmente (tmp/backups/).
# Para backup off-site, configure AWS S3, Google Cloud Storage, ou similar.
# Exemplo com aws-cli:
#   aws s3 cp tmp/backups/backup_*.sql.gz s3://seu-bucket/backups/
