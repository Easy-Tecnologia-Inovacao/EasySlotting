class ServicePackagePolicy
  attr_reader :user, :package, :establishment

  def initialize(user, package, establishment = nil)
    @user = user
    @package = package
    @establishment = establishment
  end

  def index?
    user.owner? || user.employee? || user.super_admin?
  end

  def create?
    return true if user.owner? || user.super_admin?
    return false unless user.employee?

    membership = user.establishment_memberships.find_by(establishment: establishment)
    membership&.can_manage_services?
  end

  def update?
    return true if user.owner? || user.super_admin?
    return false unless user.employee?

    membership = user.establishment_memberships.find_by(establishment: establishment)
    return false unless membership&.can_manage_services?

    # Funcionário só pode atualizar se o pacote pertencer a ele ou se ele estiver associado ao pacote
    package.user_id == user.id || package.employees.include?(user)
  end

  def destroy?
    update?
  end
end
