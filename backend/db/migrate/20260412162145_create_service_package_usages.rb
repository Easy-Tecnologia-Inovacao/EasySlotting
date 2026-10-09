class CreateServicePackageUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :service_package_usages do |t|
      t.references :service_package_sale, null: false, foreign_key: true
      t.references :appointment, null: true, foreign_key: true

      t.datetime :used_at, null: false
      t.text :notes

      t.timestamps
    end
  end
end