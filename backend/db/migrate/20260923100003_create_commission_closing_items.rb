class CreateCommissionClosingItems < ActiveRecord::Migration[8.1]
  def change
    create_table :commission_closing_items do |t|
      t.references :commission_closing, null: false, foreign_key: true
      t.references :commission, null: false, foreign_key: true
      t.references :appointment, null: false, foreign_key: true

      t.decimal :service_amount, precision: 10, scale: 2, null: false
      t.string  :commission_rule_applied
      t.decimal :commission_amount, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
