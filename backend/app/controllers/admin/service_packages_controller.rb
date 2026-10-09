# app/controllers/admin/service_packages_controller.rb
# Controller para gerenciamento de pacotes de serviços.
# Suporta múltiplos profissionais via package_employees.

class Admin::ServicePackagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!
  before_action :require_services_management!, except: [:index]
  before_action :set_service_package, only: [:update, :destroy]

  def index
    packages = @establishment.service_packages
                            .includes(:user, :service, :employees)
                            .order(created_at: :desc)

    render json: packages.map { |pkg| render_package(pkg) }, status: :ok
  end

  def create
    unless ServicePackagePolicy.new(current_user, nil, @establishment).create?
      return render json: { error: 'Acesso negado: Você não tem permissão para criar pacotes.' }, status: :forbidden
    end

    package = @establishment.service_packages.new(service_package_safe_params)

    if package.save
      # Salva vínculos com profissionais
      sync_package_employees(package, params[:employee_ids])

      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'create_package',
        auditable: package,
        ip_address: request.remote_ip,
        details: { name: package.name, price: package.price.to_f, sessions_total: package.sessions_total }
      )

      render json: render_package(package), status: :created
    else
      render json: { errors: package.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    unless ServicePackagePolicy.new(current_user, @service_package, @establishment).update?
      return render json: { error: 'Acesso negado: Você não tem permissão para editar este pacote.' }, status: :forbidden
    end

    @service_package.assign_attributes(service_package_safe_params)
    changes = @service_package.changes

    if @service_package.save
      # Atualiza vínculos com profissionais
      sync_package_employees(@service_package, params[:employee_ids])

      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'update_package',
        auditable: @service_package,
        ip_address: request.remote_ip,
        details: { changes: changes }
      )

      render json: render_package(@service_package), status: :ok
    else
      render json: { errors: @service_package.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    unless ServicePackagePolicy.new(current_user, @service_package, @establishment).destroy?
      return render json: { error: 'Acesso negado: Você não tem permissão para excluir este pacote.' }, status: :forbidden
    end

    @service_package.discard

    AuditLog.create!(
      user: current_user,
      establishment: @establishment,
      action: 'destroy_package',
      auditable: @service_package,
      ip_address: request.remote_ip,
      details: { name: @service_package.name }
    )

    head :no_content
  end

  private

  def set_service_package
    return if performed?

    @service_package = @establishment.service_packages.find_by(id: params[:id])

    return if @service_package.present?

    render json: { error: 'Pacote não encontrado' }, status: :not_found
  end

  def service_package_params
    params.require(:service_package).permit(
      :name,
      :description,
      :included_items,
      :duration_minutes,
      :price,
      :active,
      :service_id,
      :user_id,
      :sessions_total
    )
  end

  def service_package_safe_params
    safe_params = service_package_params.dup
    if current_user.employee?
      safe_params[:user_id] = current_user.id
    elsif safe_params[:user_id].present?
      uid = safe_params[:user_id].to_i
      is_valid_user = (uid == @establishment.owner_id) ||
                      @establishment.establishment_memberships.where(active: true).exists?(user_id: uid)
      unless is_valid_user
        safe_params[:user_id] = nil
      end
    end

    # 🔒 SEGURANÇA (Anti-IDOR): Garante que o service_id pertence ao estabelecimento
    if safe_params[:service_id].present?
      sid = safe_params[:service_id].to_i
      unless @establishment.services.exists?(id: sid)
        safe_params[:service_id] = nil
      end
    end

    safe_params
  end

  # Sincroniza vínculos do pacote com profissionais
  def sync_package_employees(package, employee_ids)
    if current_user.employee?
      # Funcionário só pode associar a si próprio
      package.package_employees.where.not(user_id: current_user.id).destroy_all
      package.package_employees.find_or_create_by(user_id: current_user.id)
      return
    end

    return unless employee_ids.is_a?(Array)

    # Filtra apenas IDs válidos que pertencem ao estabelecimento
    valid_ids = @establishment.establishment_memberships
                             .joins(:user)
                             .where(establishment_memberships: { active: true }, users: { active: true })
                             .pluck(:user_id)
                             .select { |id| employee_ids.include?(id) }

    # Remove vínculos antigos e cria novos
    package.package_employees.where.not(user_id: valid_ids).destroy_all
    valid_ids.each do |user_id|
      package.package_employees.find_or_create_by(user_id: user_id)
    end
  end

  def render_package(package)
    {
      id: package.id,
      name: package.name,
      description: package.description,
      included_items: package.included_items,
      duration_minutes: package.duration_minutes,
      price: package.price.to_f,
      active: package.active,
      service_id: package.service_id,
      user_id: package.user_id,
      sessions_total: package.sessions_total,
      created_at: package.created_at,
      updated_at: package.updated_at,
      user: package.user ? { id: package.user.id, name: package.user.name } : nil,
      service: package.service ? { id: package.service.id, name: package.service.name, duration_minutes: package.service.duration_minutes } : nil,
      employees: package.employees.map { |e| { id: e.id, name: e.name } }
    }
  end
end
