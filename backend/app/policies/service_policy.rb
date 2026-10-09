class ServicePolicy
  attr_reader :user, :service, :establishment

  def initialize(user, service, establishment = nil)
    @user = user
    @service = service
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

    # Funcionário só pode atualizar se estiver associado ao serviço
    service.employees.include?(user)
  end

  def destroy?
    update?
  end
end
