class AddSplitHoursToEmployeeWorkingHours < ActiveRecord::Migration[8.1]
  def change
    add_column :employee_working_hours, :morning_start_time, :time
    add_column :employee_working_hours, :morning_end_time, :time
    add_column :employee_working_hours, :afternoon_start_time, :time
    add_column :employee_working_hours, :afternoon_end_time, :time
  end
end