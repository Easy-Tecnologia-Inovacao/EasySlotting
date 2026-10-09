class AddEmployeeNameSnapshotToAppointments < ActiveRecord::Migration[8.1]
  def up
    add_column :appointments, :employee_name_snapshot, :string

    execute <<~SQL
      UPDATE appointments
      SET employee_name_snapshot = users.name
      FROM users
      WHERE users.id = appointments.employee_id
        AND appointments.employee_name_snapshot IS NULL
    SQL
  end

  def down
    remove_column :appointments, :employee_name_snapshot
  end
end