class CreateEstablishments < ActiveRecord::Migration[8.1]
  def change
    create_table :establishments do |t|
      t.boolean :active, default: true
      t.jsonb :amenities, default: []
      t.integer :appointment_interval, null: false, default: 30
      t.string :banner
      t.string :category
      t.string :cnpj
      t.text :description
      t.string :email
      t.string :facebook
      t.string :instagram
      t.string :logo
      t.string :name, null: false
      t.boolean :online_booking_enabled, default: true
      t.bigint :owner_id, null: false
      t.jsonb :payment_methods, default: []
      t.string :phone
      t.jsonb :public_settings, default: {}
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.jsonb :testimonials, default: []
      t.string :timezone, default: "America/Sao_Paulo"
      t.string :whatsapp

      t.timestamps
    end

    add_index :establishments, :cnpj, unique: true
    add_index :establishments, :owner_id
    add_index :establishments, :slug, unique: true
    add_index :establishments, :status

    add_foreign_key :establishments, :users, column: :owner_id
  end
end