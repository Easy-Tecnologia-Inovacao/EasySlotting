class SetDefaultSessionsTotalOnServicePackages < ActiveRecord::Migration[8.1]
  def change
    # Define default = 4 para a coluna sessions_total e preenche os nil existentes
    change_column_default :service_packages, :sessions_total, from: nil, to: 4
    ServicePackage.where(sessions_total: nil).update_all(sessions_total: 4)
  end
end
