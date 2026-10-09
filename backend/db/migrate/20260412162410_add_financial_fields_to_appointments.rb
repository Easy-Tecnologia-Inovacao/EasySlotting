class AddFinancialFieldsToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_column :appointments, :completed_at, :datetime
    add_column :appointments, :canceled_at, :datetime
    add_column :appointments, :cancellation_reason, :text
  end
end