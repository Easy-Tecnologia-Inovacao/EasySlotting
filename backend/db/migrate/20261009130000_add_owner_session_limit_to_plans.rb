class AddOwnerSessionLimitToPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :plans, :max_owner_sessions, :integer, null: false, default: 1
    add_check_constraint :plans, 'max_owner_sessions BETWEEN 1 AND 4',
                         name: 'plans_max_owner_sessions_range'
  end
end
