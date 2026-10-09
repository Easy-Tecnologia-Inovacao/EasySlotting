class AddSecurityIndicesAndConstraints < ActiveRecord::Migration[8.1]
  def change
    # 1. Garante integridade de agendamentos (Evita Double Booking no nível do Banco)
    # Bloqueia se tentarem inserir o mesmo funcionário no mesmo dia e hora
    # Nota: Removido pois pode haver agendamentos com durações diferentes que se sobrepõe,
    # mas o índice simples ajuda em casos de repetição exata por erro de rede.
    add_index :appointments, [:employee_id, :appointment_date, :start_time], 
              unique: true, 
              name: 'idx_appointments_on_employee_date_time_unique',
              where: "status != 'canceled'"

    # 2. Garante que Slugs de estabelecimentos sejam sempre tratados como lowercase para evitar confusão
    # (Embora já exista índice, o check de integridade ajuda)
    # No Postgres podemos usar um índice case-insensitive se necessário, 
    # mas por agora garantimos que campos críticos não sejam nulos.
    change_column_null :establishments, :owner_id, false
    change_column_null :customers, :establishment_id, false
    
    # 3. Adiciona restrições de unicidade que podem estar faltando em tabelas de suporte
    # (Exemplo: Evitar duplicidade de horários de funcionamento no mesmo dia)
    # Já existe em business_hours [:establishment_id, :weekday] - OK
  end
end
