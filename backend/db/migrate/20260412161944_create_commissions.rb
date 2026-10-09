class CreateCommissions < ActiveRecord::Migration[8.1]
  def change
    create_table :commissions do |t|
      t.references :establishment, null: false, foreign_key: true
      t.references :appointment, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: { to_table: :users }
      t.references :membership, null: true, foreign_key: { to_table: :establishment_memberships }

      t.decimal :calculated_from_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.string :status, null: false, default: 'pending'
      t.datetime :paid_at
      t.string :reference_month

      t.timestamps
    end

    add_index :commissions, :status
    add_index :commissions, :reference_month
  end
end