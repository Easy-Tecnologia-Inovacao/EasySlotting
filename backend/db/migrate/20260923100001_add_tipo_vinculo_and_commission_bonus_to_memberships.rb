class AddTipoVinculoAndCommissionBonusToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :establishment_memberships, :tipo_vinculo, :string, default: 'autonomo'
    add_column :establishment_memberships, :commission_bonus_percentage, :decimal, precision: 5, scale: 2
  end
end
