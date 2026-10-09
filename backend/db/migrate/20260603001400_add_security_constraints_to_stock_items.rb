class AddSecurityConstraintsToStockItems < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :stock_items, "sale_price >= 0", name: "chk_stock_items_sale_price_non_negative"
    add_check_constraint :stock_items, "quantity >= 0", name: "chk_stock_items_quantity_non_negative"
    add_check_constraint :stock_items, "minimum_stock >= 0", name: "chk_stock_items_minimum_stock_non_negative"
  end
end
