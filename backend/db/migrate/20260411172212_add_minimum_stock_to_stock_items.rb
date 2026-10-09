class AddMinimumStockToStockItems < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_items, :minimum_stock, :integer, null: false, default: 1
    add_index :stock_items, :minimum_stock
  end
end