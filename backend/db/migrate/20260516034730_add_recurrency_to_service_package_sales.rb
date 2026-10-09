class AddRecurrencyToServicePackageSales < ActiveRecord::Migration[8.1]
  def change
    add_column :service_package_sales, :payment_status, :string, default: 'pending', null: false
    add_column :service_package_sales, :current_cycle, :integer, default: 1, null: false
  end
end
