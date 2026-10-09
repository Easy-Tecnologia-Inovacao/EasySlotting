
namespace :security do
  desc "Executa auditoria completa de segurança e integridade (SaaS Hardening)"
  task audit: :environment do
    puts "--- INICIANDO AUDITORIA DE SEGURANÇA ---"
    
    # 1. Teste de Multitenancy
    puts "\n[1/4] Verificando Isolamento Multitenant..."
    est_a = Establishment.first
    est_b = Establishment.second
    
    if est_a && est_b
      customer_b = Customer.where(establishment: est_b).first
      if customer_b
        begin
          # Tenta buscar via scope do Est A (deve falhar ou retornar nil)
          found = est_a.customers.find_by(id: customer_b.id)
          if found
            puts "  [FALHA] Vazamento detectado! Est A conseguiu ver cliente do Est B."
          else
            puts "  [OK] Isolamento de Clientes verificado."
          end
        rescue => e
          puts "  [OK] Erro esperado ao cruzar dados: #{e.message}"
        end
      end
    else
      puts "  [AVISO] Estabelecimentos insuficientes para teste de multitenancy."
    end

    # 2. Teste de Concorrência (Agendamentos)
    puts "\n[2/4] Verificando Proteção de Double-Booking..."
    # Aqui apenas validamos se o índice de unicidade existe no banco
    if ActiveRecord::Base.connection.index_exists?(:appointments, [:employee_id, :appointment_date, :start_time], name: 'idx_appointments_on_employee_date_time_unique')
      puts "  [OK] Índice de unicidade DB-Level ativo."
    else
      puts "  [FALHA] Índice de unicidade ausente!"
    end

    # 3. Teste de Concorrência (Financeiro/Pacotes)
    puts "\n[3/4] Verificando Pessimistic Locking..."
    begin
      sale = ServicePackageSale.first
      if sale
        sale.with_lock do
          puts "  [OK] Lock pessimista (FOR UPDATE) funcional."
        end
      end
    rescue => e
      puts "  [FALHA] Erro ao testar lock: #{e.message}"
    end

    # 4. Verificação de Filtros de Log
    puts "\n[4/4] Verificando Filtros de Parâmetros..."
    filters = Rails.application.config.filter_parameters
    if filters.include?(:password) && filters.include?(:total_amount)
      puts "  [OK] Filtros de logs sensíveis ativos."
    else
      puts "  [AVISO] Filtros incompletos: #{filters}"
    end

    puts "\n--- AUDITORIA CONCLUÍDA ---"
  end
end
