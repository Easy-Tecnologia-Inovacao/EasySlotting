class CreateServicePackageSales < ActiveRecord::Migration[8.1]
  def change
    create_table :service_package_sales do |t|
      t.references :establishment, null: false, foreign_key: true
      t.references :service_package, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: { to_table: :users }
      t.references :sold_by, null: true, foreign_key: { to_table: :users }

      t.decimal :total_price, precision: 10, scale: 2, null: false, default: 0
      t.integer :sessions_total, null: false, default: 0
      t.integer :sessions_used, null: false, default: 0
      t.string :status, null: false, default: 'active'
      t.datetime :sold_at, null: false

      t.timestamps
    end

    add_index :service_package_sales, :status
    add_index :service_package_sales, :sold_at
  end
end