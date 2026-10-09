class AddLockableToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :failed_attempts, :integer, default: 0, null: false
    add_column :customers, :locked_at, :datetime
    add_index  :customers, :locked_at
  end
end
