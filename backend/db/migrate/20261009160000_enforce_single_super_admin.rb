class EnforceSingleSuperAdmin < ActiveRecord::Migration[8.1]
  def up
    if select_value("SELECT COUNT(*) FROM users WHERE role = 'super_admin'").to_i > 1
      raise ActiveRecord::MigrationError,
        'Existem múltiplos super admins. Escolha administrativamente qual conta preservar e reclassifique as demais antes de repetir db:migrate. Nenhuma conta foi removida.'
    end
    add_index :users, :role, unique: true, where: "role = 'super_admin'", name: 'index_users_on_single_super_admin'
  end

  def down
    remove_index :users, name: 'index_users_on_single_super_admin'
  end
end
