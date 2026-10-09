class AddSessionsTotalToServicePackages < ActiveRecord::Migration[8.1]
  def change
    add_column :service_packages, :sessions_total, :integer
  end
end
