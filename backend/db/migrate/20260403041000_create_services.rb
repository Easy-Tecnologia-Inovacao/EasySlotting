class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.references :establishment, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :service_type, null: false
      t.integer :duration_minutes, null: false, default: 30
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0.0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :services, :active
    add_index :services, :service_type
    add_index :services, [:establishment_id, :name]
  end
end