class MigrateServicePackageSalesCustomerFk < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :service_package_sales, column: :customer_id

    # Permite NULL para poder limpar dados orfãos
    change_column_null :service_package_sales, :customer_id, true

    # Anula registros cujo customer_id não existe em customers
    execute <<-SQL
      UPDATE service_package_sales
      SET customer_id = NULL
      WHERE customer_id NOT IN (SELECT id FROM customers)
    SQL

    add_foreign_key :service_package_sales, :customers, column: :customer_id
  end

  def down
    remove_foreign_key :service_package_sales, column: :customer_id
    change_column_null :service_package_sales, :customer_id, false
    add_foreign_key :service_package_sales, :users, column: :customer_id
  end
end
