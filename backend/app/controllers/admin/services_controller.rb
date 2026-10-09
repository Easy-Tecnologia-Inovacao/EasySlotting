class Admin::ServicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!
  before_action :require_services_management!, except: [:index]
  before_action :set_service, only: [:update, :destroy]

  def index
    services = @establishment.services.includes(:employees)

    render json: services.as_json(
      include: {
        employees: { only: [:id, :name] }
      }
    ), status: :ok
  end

  def create
    unless ServicePolicy.new(current_user, nil, @establishment).create?
      return render json: { error: 'Acesso negado: Você não tem permissão para criar serviços.' }, status: :forbidden
    end

    service = @establishment.services.new(service_params.except(:employee_ids))

    if service.save
      attach_employees(service)
      service.reload

      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'create_service',
        auditable: service,
        ip_address: request.remote_ip,
        details: { name: service.name, price: service.price.to_f, duration_minutes: service.duration_minutes }
      )

      render json: render_service(service), status: :created
    else
      render json: { errors: service.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    unless ServicePolicy.new(current_user, @service, @establishment).update?
      return render json: { error: 'Acesso negado: Você não tem permissão para editar este serviço.' }, status: :forbidden
    end

    @service.assign_attributes(service_params.except(:employee_ids))
    changes = @service.changes

    if @service.save
      sync_employees(@service)
      @service.reload

      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'update_service',
        auditable: @service,
        ip_address: request.remote_ip,
        details: { changes: changes }
      )

      render json: render_service(@service), status: :ok
    else
      render json: { errors: @service.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    unless ServicePolicy.new(current_user, @service, @establishment).destroy?
      return render json: { error: 'Acesso negado: Você não tem permissão para excluir este serviço.' }, status: :forbidden
    end

    @service.discard

    AuditLog.create!(
      user: current_user,
      establishment: @establishment,
      action: 'destroy_service',
      auditable: @service,
      ip_address: request.remote_ip,
      details: { name: @service.name }
    )

    head :no_content
  end

  private

  def set_service
    return if performed?

    # Filtra usando default_scope (sem deletados)
    @service = @establishment.services.find_by(id: params[:id])

    return if @service.present?

    render json: { error: 'Serviço não encontrado' }, status: :not_found
  end

  def service_params
    params.require(:service).permit(
      :name,
      :description,
      :service_type,
      :duration_minutes,
      :price,
      :active,
      employee_ids: []
    )
  end

  def normalized_employee_ids
    if current_user.employee?
      [current_user.id]
    else
      ids = Array(service_params[:employee_ids]).reject(&:blank?).map(&:to_i).uniq
      @establishment.establishment_memberships
                    .joins(:user)
                    .where(user_id: ids, establishment_memberships: { active: true }, users: { active: true })
                    .pluck(:user_id)
    end
  end

  def attach_employees(service)
    normalized_employee_ids.each do |user_id|
      service.employee_services.find_or_create_by!(user_id: user_id)
    end
  end

  def sync_employees(service)
    return unless service_params.key?(:employee_ids)

    novos_ids = normalized_employee_ids
    service.employee_services.where.not(user_id: novos_ids).destroy_all

    atuais = service.employee_services.pluck(:user_id)
    (novos_ids - atuais).each do |user_id|
      service.employee_services.create!(user_id: user_id)
    end
  end

  def render_service(service)
    service.as_json(
      only: [
        :id,
        :name,
        :description,
        :service_type,
        :duration_minutes,
        :price,
        :active,
        :establishment_id,
        :created_at,
        :updated_at
      ],
      include: {
        employees: { only: [:id, :name] }
      }
    )
  end
end