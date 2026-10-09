class EnforceUniqueActivePlanSessionLimits < ActiveRecord::Migration[8.1]
  def up
    duplicates = select_values(<<~SQL)
      SELECT max_owner_sessions
      FROM plans
      WHERE active = TRUE
      GROUP BY max_owner_sessions
      HAVING COUNT(*) > 1
    SQL
    if duplicates.any?
      raise ActiveRecord::MigrationError,
            "Há planos ativos com limites repetidos (#{duplicates.join(', ')}). " \
            'Configure limites distintos de 1 a 4 ou inative planos excedentes antes de repetir a migração. ' \
            'Nenhum preço, benefício ou assinatura foi alterado automaticamente.'
    end

    add_index :plans, :max_owner_sessions, unique: true, where: 'active = TRUE',
              name: 'index_plans_on_unique_active_owner_sessions'
  end

  def down
    remove_index :plans, name: 'index_plans_on_unique_active_owner_sessions'
  end
end
