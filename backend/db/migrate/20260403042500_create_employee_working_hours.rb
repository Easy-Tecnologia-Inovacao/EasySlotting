class CreateEmployeeWorkingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :employee_working_hours do |t|
      t.time :end_time
      t.boolean :is_available, default: true
      t.time :start_time
      t.bigint :user_id, null: false
      t.integer :weekday, null: false

      t.timestamps
    end

    add_index :employee_working_hours, [:user_id, :weekday], unique: true, name: "index_employee_working_hours_on_user_and_weekday"
    add_index :employee_working_hours, :user_id
    add_foreign_key :employee_working_hours, :users
  end
end