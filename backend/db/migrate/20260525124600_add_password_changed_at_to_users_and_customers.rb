class AddPasswordChangedAtToUsersAndCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_changed_at, :datetime
    add_column :customers, :password_changed_at, :datetime

    # Inicializa os dados existentes com a data de criação ou data atual para evitar bloqueio em lote
    up_only do
      execute "UPDATE users SET password_changed_at = COALESCE(created_at, NOW())"
      execute "UPDATE customers SET password_changed_at = COALESCE(created_at, NOW())"
    end
  end
end
