class AddServicePackageIdToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_column :appointments, :service_package_id, :integer
  end
end
