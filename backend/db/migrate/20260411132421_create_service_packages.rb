class CreateServicePackages < ActiveRecord::Migration[8.1]
  def change
    create_table :service_packages do |t|
      t.references :establishment, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true

      t.string :name, null: false
      t.text :description
      t.text :included_items
      t.integer :duration_minutes, null: false, default: 30
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0.0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :service_packages, :active
    add_index :service_packages, [:establishment_id, :name]
  end
end