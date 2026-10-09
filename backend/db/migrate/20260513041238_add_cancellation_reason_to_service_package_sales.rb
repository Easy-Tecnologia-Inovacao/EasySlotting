class AddCancellationReasonToServicePackageSales < ActiveRecord::Migration[8.1]
  def change
    add_column :service_package_sales, :cancellation_reason, :string
  end
end
