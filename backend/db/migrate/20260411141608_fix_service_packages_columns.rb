class FixServicePackagesColumns < ActiveRecord::Migration[8.1]
  def up
    change_column_null :service_packages, :user_id, true

    change_column_default :service_packages, :active, from: nil, to: true
    execute "UPDATE service_packages SET active = TRUE WHERE active IS NULL"
    change_column_null :service_packages, :active, false

    change_column_default :service_packages, :duration_minutes, from: nil, to: 30
    execute "UPDATE service_packages SET duration_minutes = 30 WHERE duration_minutes IS NULL"
    change_column_null :service_packages, :duration_minutes, false

    execute "UPDATE service_packages SET name = 'Pacote sem nome' WHERE name IS NULL OR name = ''"
    change_column_null :service_packages, :name, false

    execute "UPDATE service_packages SET price = 0.0 WHERE price IS NULL"
    change_column :service_packages, :price, :decimal, precision: 10, scale: 2, default: 0.0, null: false

    add_index :service_packages, :active unless index_exists?(:service_packages, :active)

    unless index_exists?(:service_packages, [:establishment_id, :name])
      add_index :service_packages, [:establishment_id, :name]
    end
  end

  def down
    remove_index :service_packages, column: [:establishment_id, :name] if index_exists?(:service_packages, [:establishment_id, :name])
    remove_index :service_packages, :active if index_exists?(:service_packages, :active)

    change_column_null :service_packages, :user_id, false
    change_column_null :service_packages, :active, true
    change_column_default :service_packages, :active, from: true, to: nil

    change_column_null :service_packages, :duration_minutes, true
    change_column_default :service_packages, :duration_minutes, from: 30, to: nil

    change_column_null :service_packages, :name, true

    change_column :service_packages, :price, :decimal
  end
end