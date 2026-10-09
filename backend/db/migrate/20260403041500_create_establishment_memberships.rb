class CreateEstablishmentMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :establishment_memberships do |t|
      # 🔗 Relacionamentos
      t.bigint :establishment_id, null: false
      t.bigint :user_id, null: false

      # 👤 Papel no sistema
      t.string :role, null: false, default: "employee"
      t.boolean :active, default: true

      # 🧠 Informações do funcionário
      t.string :specialty

      # 💰 Modelo financeiro
      t.string :financial_model
      t.decimal :financial_value, precision: 10, scale: 2
      t.string :pix_key

      # 🔐 Permissões
      t.boolean :can_view_only_own_clients, default: true, null: false
      t.boolean :can_manage_schedule, default: false, null: false
      t.boolean :can_manage_services, default: false, null: false
      t.boolean :can_manage_financial, default: false, null: false

      t.timestamps
    end

    # 🔎 Indexes
    add_index :establishment_memberships,
              [:establishment_id, :user_id],
              unique: true,
              name: "index_memberships_on_establishment_and_user"

    add_index :establishment_memberships,
              :establishment_id,
              name: "index_memberships_on_establishment_id"

    add_index :establishment_memberships,
              :user_id,
              name: "index_memberships_on_user_id"

    # 🔗 Foreign Keys
    add_foreign_key :establishment_memberships, :establishments
    add_foreign_key :establishment_memberships, :users
  end
end