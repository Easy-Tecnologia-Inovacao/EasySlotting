class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.boolean :active, default: true
      t.boolean :allow_password_change, default: false
      t.datetime :confirmation_sent_at
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.string :email, null: false
      t.string :encrypted_password, null: false, default: ""
      t.string :image
      t.string :name
      t.string :phone
      t.string :provider, null: false, default: "email"
      t.datetime :remember_created_at
      t.datetime :reset_password_sent_at
      t.string :reset_password_token
      t.string :role, null: false, default: "customer"
      t.json :tokens
      t.string :uid, null: false, default: ""
      t.string :unconfirmed_email

      t.timestamps
    end

    add_index :users, :confirmation_token, unique: true
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :role
    add_index :users, [:uid, :provider], unique: true
  end
end