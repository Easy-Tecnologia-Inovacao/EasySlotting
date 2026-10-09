class AddCommissionClosingToCommissions < ActiveRecord::Migration[8.1]
  def change
    add_reference :commissions, :commission_closing, foreign_key: true, null: true
  end
end
