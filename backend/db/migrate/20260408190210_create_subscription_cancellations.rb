class CreateSubscriptionCancellations < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_cancellations do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :reason, null: false
      t.text :details
      t.string :canceled_by_role, null: false

      t.timestamps
    end

    add_index :subscription_cancellations, :reason
    add_index :subscription_cancellations, :canceled_by_role
  end
end