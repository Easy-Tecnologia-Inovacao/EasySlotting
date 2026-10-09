# app/models/package_employee.rb
# Modelo de junção entre ServicePackage e User (Employee).
# Permite que um pacote esteja vinculado a múltiplos profissionais.

class PackageEmployee < ApplicationRecord
  belongs_to :service_package
  belongs_to :user

  validates :user_id, uniqueness: { scope: :service_package_id, message: 'já está vinculado a este pacote' }
end
