class AddExtendedPermissionsToEstablishmentMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :establishment_memberships, :can_manage_team, :boolean, default: false
    add_column :establishment_memberships, :can_manage_establishment, :boolean, default: false
    add_column :establishment_memberships, :can_manage_stock, :boolean, default: false
  end
end
