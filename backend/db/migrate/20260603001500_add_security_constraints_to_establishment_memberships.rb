class AddSecurityConstraintsToEstablishmentMemberships < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :establishment_memberships, "financial_value >= 0", name: "chk_memberships_financial_value_non_negative"
  end
end
