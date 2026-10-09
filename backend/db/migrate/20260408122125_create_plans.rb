class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description

      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :duration_months, null: false, default: 1

      t.integer :max_employees
      t.integer :max_services
      t.integer :max_appointments_per_month

      t.boolean :active, null: false, default: true

      t.decimal :promotional_price, precision: 10, scale: 2
      t.integer :discount_percentage

      t.boolean :promotion_active, null: false, default: false
      t.datetime :promotion_starts_at
      t.datetime :promotion_ends_at
      t.integer :promotion_duration_days

      t.boolean :highlight, null: false, default: false

      t.timestamps
    end

    add_index :plans, :code, unique: true
    add_index :plans, :active
  end
end