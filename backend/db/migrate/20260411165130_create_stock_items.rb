class CreateStockItems < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_items do |t|
      t.references :establishment, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :sale_price, precision: 10, scale: 2, null: false, default: 0
      t.integer :quantity, null: false, default: 0
      t.string :stock_scope, null: false, default: 'loja'
      t.bigint :owner_user_id
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_foreign_key :stock_items, :users, column: :owner_user_id
    add_index :stock_items, :active
    add_index :stock_items, :stock_scope
    add_index :stock_items, :owner_user_id
    add_index :stock_items, [:establishment_id, :name]
  end
end