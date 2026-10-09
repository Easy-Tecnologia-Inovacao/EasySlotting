class AddSecurityConstraintsToServicesAndPackages < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :services, "price >= 0", name: "chk_services_price_non_negative"
    add_check_constraint :services, "duration_minutes > 0", name: "chk_services_duration_positive"

    add_check_constraint :service_packages, "price >= 0", name: "chk_packages_price_non_negative"
    add_check_constraint :service_packages, "duration_minutes > 0", name: "chk_packages_duration_positive"
    add_check_constraint :service_packages, "sessions_total > 0", name: "chk_packages_sessions_positive"
  end
end
