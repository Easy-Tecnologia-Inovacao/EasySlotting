class MigrateAppointmentsCustomerFk < ActiveRecord::Migration[8.1]
  def up
    # 1. Remove a FK antiga que aponta para users
    remove_foreign_key :appointments, column: :customer_id

    # 2. Permite NULL temporariamente para poder limpar dados orfãos
    change_column_null :appointments, :customer_id, true

    # 3. Anula agendamentos cujo customer_id não existe em customers
    #    (dados de seed antigo que apontavam para users)
    execute <<-SQL
      UPDATE appointments
      SET customer_id = NULL
      WHERE customer_id NOT IN (SELECT id FROM customers)
    SQL

    # 4. Adiciona FK nova apontando para customers (opcional = NULL permitido)
    add_foreign_key :appointments, :customers, column: :customer_id
  end

  def down
    remove_foreign_key :appointments, column: :customer_id
    change_column_null :appointments, :customer_id, false
    add_foreign_key :appointments, :users, column: :customer_id
  end
end
