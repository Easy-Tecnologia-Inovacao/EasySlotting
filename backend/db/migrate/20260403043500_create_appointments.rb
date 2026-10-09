class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.date :appointment_date, null: false
      t.bigint :customer_id, null: false
      t.string :customer_name_snapshot
      t.integer :duration_minutes
      t.bigint :employee_id, null: false
      t.time :end_time, null: false
      t.bigint :establishment_id, null: false
      t.text :notes
      t.decimal :price_snapshot, precision: 10, scale: 2
      t.bigint :service_id, null: false
      t.string :service_name_snapshot
      t.time :start_time, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :appointments, :appointment_date
    add_index :appointments, :customer_id
    add_index :appointments, :employee_id
    add_index :appointments, :establishment_id
    add_index :appointments, :service_id
    add_index :appointments, :status

    add_foreign_key :appointments, :establishments
    add_foreign_key :appointments, :services
    add_foreign_key :appointments, :users, column: :customer_id
    add_foreign_key :appointments, :users, column: :employee_id
  end
end