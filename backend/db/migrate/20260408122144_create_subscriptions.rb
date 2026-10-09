class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.string :billing_cycle
      t.datetime :canceled_at
      t.date :end_date
      t.bigint :establishment_id, null: false
      t.datetime :expires_at
      t.date :next_billing_date
      t.bigint :plan_id, null: false
      t.decimal :price_paid, precision: 10, scale: 2
      t.date :start_date
      t.string :status

      t.timestamps
    end

    add_index :subscriptions, :establishment_id
    add_index :subscriptions, :plan_id

    add_foreign_key :subscriptions, :establishments
    add_foreign_key :subscriptions, :plans
  end
end