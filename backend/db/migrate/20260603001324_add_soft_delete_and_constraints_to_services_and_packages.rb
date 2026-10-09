class AddSoftDeleteAndConstraintsToServicesAndPackages < ActiveRecord::Migration[8.1]
  def change
    # 1. Soft delete fields and indexes
    add_column :services, :deleted_at, :datetime
    add_index :services, :deleted_at

    add_column :service_packages, :deleted_at, :datetime
    add_index :service_packages, :deleted_at

    # 2. Convert service_packages.service_id to bigint and add foreign key constraint
    change_column :service_packages, :service_id, :bigint
    add_foreign_key :service_packages, :services
  end
end
