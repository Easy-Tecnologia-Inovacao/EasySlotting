class AddServiceIdToServicePackages < ActiveRecord::Migration[8.1]
  def change
    add_column :service_packages, :service_id, :integer
    add_index  :service_packages, :service_id
    add_index  :service_packages, [:establishment_id, :active]
  end
end
