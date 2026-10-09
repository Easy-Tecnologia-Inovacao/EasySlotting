class CreateFinancialTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_transactions do |t|
      t.references :establishment, null: false, foreign_key: true
      t.references :appointment, null: true, foreign_key: true
      t.references :employee, null: true, foreign_key: { to_table: :users }
      t.references :user, null: true, foreign_key: true

      t.string :kind, null: false
      t.string :category, null: false
      t.string :source_type
      t.bigint :source_id
      t.text :description
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.date :occurred_on, null: false
      t.string :status, null: false, default: 'paid'
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :financial_transactions, :kind
    add_index :financial_transactions, :category
    add_index :financial_transactions, :status
    add_index :financial_transactions, :occurred_on
    add_index :financial_transactions, [:source_type, :source_id]
  end
end