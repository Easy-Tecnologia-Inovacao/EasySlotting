class CreatePackageEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :package_employees do |t|
      t.references :service_package, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :package_employees, [:service_package_id, :user_id], unique: true
  end
end
