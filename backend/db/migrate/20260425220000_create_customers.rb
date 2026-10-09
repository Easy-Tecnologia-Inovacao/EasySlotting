class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string  :name,           null: false
      t.string  :email,          null: false
      t.string  :phone
      t.string  :cellphone
      t.string  :image
      t.string  :password_digest, null: false
      t.boolean :active,          default: true, null: false
      t.string  :reset_password_token
      t.datetime :reset_password_sent_at
      t.bigint  :establishment_id, null: false

      t.timestamps
    end

    # Unicidade composta: mesmo email pode existir em estabelecimentos diferentes
    add_index :customers, [:email, :establishment_id], unique: true,
              name: 'index_customers_on_email_and_establishment_id'

    add_index :customers, :establishment_id,
              name: 'index_customers_on_establishment_id'

    add_index :customers, :reset_password_token,
              unique: true, where: 'reset_password_token IS NOT NULL',
              name: 'index_customers_on_reset_password_token'

    add_foreign_key :customers, :establishments
  end
end
