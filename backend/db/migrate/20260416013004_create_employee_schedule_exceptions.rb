class CreateEmployeeScheduleExceptions < ActiveRecord::Migration[8.1]
  def change
    create_table :employee_schedule_exceptions do |t|
      t.references :user, null: false, foreign_key: true
      t.date :exception_date, null: false
      t.string :kind, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :employee_schedule_exceptions,
              [:user_id, :exception_date, :kind],
              unique: true,
              name: 'idx_employee_schedule_exceptions_unique'
  end
end