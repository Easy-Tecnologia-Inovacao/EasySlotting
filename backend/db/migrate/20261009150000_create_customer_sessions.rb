class CreateCustomerSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_sessions do |t|
      t.references :customer, null: false, foreign_key: true
      t.uuid :session_id, null: false
      t.string :refresh_token_digest, null: false
      t.string :csrf_token_digest, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :customer_sessions, :session_id, unique: true
    add_index :customer_sessions, [:customer_id, :expires_at]
  end
end
