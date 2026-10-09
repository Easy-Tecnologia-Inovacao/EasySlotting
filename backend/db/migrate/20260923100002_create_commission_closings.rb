class CreateCommissionClosings < ActiveRecord::Migration[8.1]
  def change
    create_table :commission_closings do |t|
      t.references :establishment, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: { to_table: :users }
      t.references :membership, null: true, foreign_key: { to_table: :establishment_memberships }

      t.string   :reference_month, null: false
      t.date     :period_start, null: false
      t.date     :period_end, null: false

      t.integer  :services_count, default: 0
      t.decimal  :gross_revenue, precision: 10, scale: 2, default: 0
      t.string   :financial_model_snapshot
      t.decimal  :financial_value_snapshot, precision: 10, scale: 2
      t.decimal  :commission_bonus_snapshot, precision: 5, scale: 2
      t.decimal  :gross_commission_amount, precision: 10, scale: 2, default: 0

      t.string   :status, null: false, default: 'open'
      t.datetime :closed_at
      t.bigint   :closed_by_id
      t.text     :notes

      t.timestamps
    end

    add_index :commission_closings, [:establishment_id, :employee_id, :reference_month],
              unique: true, name: 'idx_closings_est_emp_month'
    add_index :commission_closings, :status
    add_foreign_key :commission_closings, :users, column: :closed_by_id
  end
end
