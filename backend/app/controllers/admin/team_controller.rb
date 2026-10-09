class Admin::TeamController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!
  before_action :require_team_management!, only: [:create, :update, :destroy]
  before_action :set_membership, only: [:update, :destroy], unless: -> { params[:user_id].present? }

  def index
    memberships = @establishment.establishment_memberships
                                .includes(:user)
                                .where(role: 'employee', active: true)
                                .order(created_at: :desc)

    unless current_user.owner? || current_user.super_admin?
      membership = current_membership
      if membership&.can_view_only_own_clients? && !membership&.can_manage_schedule?
        memberships = memberships.where(user_id: current_user.id)
      end
    end

    linked_employees = memberships.map { |m| serialize_membership(m) }

    render json: linked_employees
  end

  def create
    temp_password = generate_secure_temporary_password

    ActiveRecord::Base.transaction do
      user = User.create!(
        name: team_params[:name],
        email: team_params[:email],
        phone: team_params[:phone],
        role: 'employee',
        password: temp_password,
        password_confirmation: temp_password,
        allow_password_change: false,
        active: true
      )

      # Apenas owner/super_admin podem conceder permissoes administrativas/financeiras ao criar (Anti-Privilege-Escalation)
      is_admin = current_user.owner? || current_user.super_admin?

      membership = @establishment.establishment_memberships.create!(
        user: user,
        role: 'employee',
        active: true,
        specialty: team_params[:specialty],
        tipo_vinculo: team_params[:tipo_vinculo].presence || 'autonomo',
        financial_model: team_params[:financial_model],
        financial_value: normalize_financial_value(team_params[:financial_value]),
        commission_bonus_percentage: normalize_financial_value(team_params[:commission_bonus_percentage]),
        pix_key: team_params[:pix_key],
        can_view_only_own_clients: truthy_param(team_params[:can_view_only_own_clients]),
        can_manage_schedule: truthy_param(team_params[:can_manage_schedule]),
        can_manage_services: truthy_param(team_params[:can_manage_services]),
        # Apenas owner/super_admin podem conceder permissoes de alto impacto
        can_manage_financial:    is_admin ? truthy_param(team_params[:can_manage_financial])    : false,
        can_manage_team:         is_admin ? truthy_param(team_params[:can_manage_team])         : false,
        can_manage_establishment: is_admin ? truthy_param(team_params[:can_manage_establishment]) : false,
        can_manage_stock: truthy_param(team_params[:can_manage_stock])
      )

      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'create_employee',
        auditable: membership,
        ip_address: request.remote_ip,
        details: { name: user.name, email: user.email, specialty: membership.specialty }
      )

      begin
        UserMailer.employee_created(user, temp_password).deliver_later
      rescue StandardError => e
        Rails.logger.error "Erro ao enviar e-mail do funcionario: #{e.message}"
      end

      # Achado 4.1: Senha temporaria removida do JSON (trafega apenas pelo e-mail transacional)
      render json: {
        message: 'Funcionario cadastrado com sucesso. A senha temporaria foi enviada para o e-mail informado.',
        employee: serialize_membership(membership)
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      errors: e.record.errors.full_messages
    }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[Admin::Team#create] #{e.class}: #{e.message}")
    render json: {
      errors: ['Erro ao criar funcionario.']
    }, status: :unprocessable_entity
  end

  def update
    # Achado 2.1: Bloqueia auto-escalonamento de privilegios (funcionario editando o proprio vinculo)
    if @membership.user_id == current_user.id && !current_user.owner? && !current_user.super_admin?
      return render json: { error: 'Acesso negado: Voce nao pode alterar seu proprio vinculo ou permissoes.' }, status: :forbidden
    end

    is_admin = current_user.owner? || current_user.super_admin?
    can_manage_financial = is_admin || current_membership&.can_manage_financial?

    ActiveRecord::Base.transaction do
      # Achado 3.2: Apenas owner/super_admin podem alterar e-mail e telefone (credenciais de acesso)
      if is_admin
        @membership.user.assign_attributes(
          name: team_params[:name],
          email: team_params[:email],
          phone: team_params[:phone]
        )
      else
        # Funcionario com can_manage_team pode apenas alterar o nome do colega, nao as credenciais
        @membership.user.assign_attributes(
          name: team_params[:name]
        )
      end

      user_changes = @membership.user.changes
      @membership.user.save!

      membership_attrs = {
        specialty: team_params[:specialty],
        tipo_vinculo: team_params[:tipo_vinculo].presence || @membership.tipo_vinculo || 'autonomo'
      }

      # Achado 2.2: Apenas usuarios com acesso financeiro podem alterar dados de comissao e PIX
      if can_manage_financial
        membership_attrs.merge!(
          financial_model:              team_params[:financial_model],
          financial_value:              normalize_financial_value(team_params[:financial_value]),
          commission_bonus_percentage:  normalize_financial_value(team_params[:commission_bonus_percentage]),
          pix_key:                      team_params[:pix_key]
        )
      end

      # Achado 2.1: Apenas owner/super_admin podem alterar permissoes de alto impacto
      if is_admin
        membership_attrs.merge!(
          can_view_only_own_clients:  truthy_param(team_params[:can_view_only_own_clients]),
          can_manage_schedule:        truthy_param(team_params[:can_manage_schedule]),
          can_manage_services:        truthy_param(team_params[:can_manage_services]),
          can_manage_financial:       truthy_param(team_params[:can_manage_financial]),
          can_manage_team:            truthy_param(team_params[:can_manage_team]),
          can_manage_establishment:   truthy_param(team_params[:can_manage_establishment]),
          can_manage_stock:           truthy_param(team_params[:can_manage_stock])
        )
      else
        # Funcionario com can_manage_team pode alterar apenas permissoes operacionais nao-sensiveis
        membership_attrs.merge!(
          can_view_only_own_clients:  truthy_param(team_params[:can_view_only_own_clients]),
          can_manage_schedule:        truthy_param(team_params[:can_manage_schedule]),
          can_manage_services:        truthy_param(team_params[:can_manage_services]),
          can_manage_stock:           truthy_param(team_params[:can_manage_stock])
        )
      end

      @membership.assign_attributes(membership_attrs)

      # Achado 5.3: Mascarar PIX no audit log (dado pessoal sensivel - LGPD Art.6 III)
      raw_changes = @membership.changes
      safe_membership_changes = raw_changes.except('pix_key')
      safe_membership_changes['pix_key'] = ['[MASKED]', '[MASKED]'] if raw_changes.key?('pix_key')

      safe_user_changes = user_changes.except('email', 'phone')
      safe_user_changes['email'] = ['[MASKED]', '[MASKED]'] if user_changes.key?('email')
      safe_user_changes['phone'] = ['[MASKED]', '[MASKED]'] if user_changes.key?('phone')

      @membership.save!

      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'update_employee',
        auditable: @membership,
        ip_address: request.remote_ip,
        details: { user_changes: safe_user_changes, membership_changes: safe_membership_changes }
      )
    end

    render json: {
      message: 'Funcionario atualizado com sucesso',
      employee: serialize_membership(@membership.reload)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      errors: e.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def destroy
    if params[:user_id].present?
      membership = @establishment.establishment_memberships.find_by(user_id: params[:user_id], role: 'employee')

      unless membership
        render json: { error: 'Funcionario nao encontrado neste estabelecimento' }, status: :not_found
        return
      end

      user = membership.user

      # Bloqueia exclusao do proprietario da loja
      if user.id == @establishment.owner_id && !(current_user.id == @establishment.owner_id || current_user.super_admin?)
        render json: { error: 'Acesso negado: Nao e permitido excluir o proprietario' }, status: :forbidden
        return
      end

      possui_agendamentos = employee_has_appointments?(user)

      if possui_agendamentos
        render json: {
          error: 'Este funcionario possui agendamentos vinculados. Remaneje os agendamentos antes de excluir.'
        }, status: :unprocessable_entity
        return
      end

      ActiveRecord::Base.transaction do
        AuditLog.create!(
          user: current_user,
          establishment: @establishment,
          action: 'destroy_employee',
          auditable_type: 'User',
          auditable_id: user.id,
          ip_address: request.remote_ip,
          details: { name: user.name, email: '[MASKED]' }
        )

        # Achado 3.1: Escopo restrito ao estabelecimento atual (sem impacto cross-tenant)
        @establishment.establishment_memberships.where(user_id: user.id).destroy_all
        EmployeeService.joins(:service)
                       .where(user_id: user.id, services: { establishment_id: @establishment.id })
                       .destroy_all
        EmployeeWorkingHour.where(user_id: user.id).destroy_all

        # Anonimizar a conta User global somente se nao houver mais vinculos em outros estabelecimentos
        if user.establishment_memberships.empty? && user.owned_establishments.empty?
          user.soft_delete_with_anonymization!
        end
      end

      render json: {
        message: 'Funcionario excluido com sucesso'
      }
      return
    end

    user = @membership.user

    # Bloqueia exclusao do proprietario da loja
    if user.id == @establishment.owner_id && !(current_user.id == @establishment.owner_id || current_user.super_admin?)
      render json: { error: 'Acesso negado: Nao e permitido excluir o proprietario' }, status: :forbidden
      return
    end

    possui_agendamentos = employee_has_appointments?(user)

    if possui_agendamentos
      render json: {
        error: 'Este funcionario possui agendamentos vinculados. Remaneje os agendamentos antes de excluir.'
      }, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'destroy_employee',
        auditable_type: 'EstablishmentMembership',
        auditable_id: @membership.id,
        ip_address: request.remote_ip,
        details: { name: user.name, email: '[MASKED]' }
      )

      # Achado 3.1: Escopo restrito ao estabelecimento atual (sem impacto cross-tenant)
      @establishment.establishment_memberships.where(user_id: user.id).destroy_all
      EmployeeService.joins(:service)
                     .where(user_id: user.id, services: { establishment_id: @establishment.id })
                     .destroy_all
      EmployeeWorkingHour.where(user_id: user.id).destroy_all

      # Anonimizar a conta User global somente se nao houver mais vinculos em outros estabelecimentos
      if user.establishment_memberships.reload.empty? && user.owned_establishments.empty?
        user.soft_delete_with_anonymization!
      end
    end

    render json: {
      message: 'Funcionario excluido com sucesso'
    }
  rescue ActiveRecord::InvalidForeignKey => e
    Rails.logger.error("[Admin::Team#destroy] #{e.class}: #{e.message}")
    render json: {
      error: 'Nao foi possivel excluir o funcionario porque existem registros vinculados.'
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      errors: e.record.errors.full_messages
    }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[Admin::Team#destroy] #{e.class}: #{e.message}")
    render json: {
      error: 'Erro ao excluir funcionario.'
    }, status: :unprocessable_entity
  end

  private

  def set_membership
    @membership = @establishment.establishment_memberships.find_by(id: params[:id])

    unless @membership.present?
      render json: { error: 'Vinculo do funcionario nao encontrado' }, status: :not_found
      return
    end

    # Bloqueia modificacao do proprietario da loja por outros funcionarios
    if @membership.user_id == @establishment.owner_id
      unless current_user.id == @establishment.owner_id || current_user.super_admin?
        render json: { error: 'Acesso negado: Nao e permitido alterar os dados do proprietario' }, status: :forbidden
        return
      end
    end
  end

  def team_params
    params.require(:employee).permit(
      :name,
      :email,
      :phone,
      :specialty,
      :tipo_vinculo,
      :financial_model,
      :financial_value,
      :commission_bonus_percentage,
      :pix_key,
      :can_view_only_own_clients,
      :can_manage_schedule,
      :can_manage_services,
      :can_manage_financial,
      :can_manage_team,
      :can_manage_establishment,
      :can_manage_stock
    )
  end

  def serialize_membership(membership)
    can_see_sensitive = current_user.owner? ||
                        current_user.super_admin? ||
                        current_membership&.can_manage_team? ||
                        current_membership&.can_manage_financial? ||
                        membership.user_id == current_user.id

    data = {
      id: membership.id,
      user_id: membership.user_id,
      orphan: false,
      name: membership.user.name,
      email: membership.user.email,
      phone: membership.user.phone,
      specialty: membership.specialty,
      role: membership.role,
      active: membership.active
    }

    if can_see_sensitive
      data[:financial] = {
        tipo_vinculo: membership.tipo_vinculo || 'autonomo',
        model: membership.financial_model,
        value: membership.financial_value&.to_s,
        commission_bonus_percentage: membership.commission_bonus_percentage&.to_s,
        pix: membership.pix_key
      }
      data[:permissions] = {
        can_view_only_own_clients: membership.can_view_only_own_clients,
        can_manage_schedule: membership.can_manage_schedule?,
        can_manage_services: membership.can_manage_services?,
        can_manage_financial: membership.can_manage_financial?,
        can_manage_team: membership.can_manage_team?,
        can_manage_establishment: membership.can_manage_establishment?,
        can_manage_stock: membership.can_manage_stock?
      }
    end

    data
  end

  def normalize_financial_value(value)
    return nil if value.blank?

    value.to_s.tr(',', '.')
  end

  def truthy_param(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def employee_has_appointments?(user)
    return false unless defined?(Appointment) && @establishment.present?

    @establishment.appointments
                  .where(employee_id: user.id)
                  .where.not(status: %w[canceled completed])
                  .exists?
  rescue StandardError => e
    Rails.logger.error("[Admin::Team#employee_has_appointments?] #{e.class}: #{e.message}")
    raise StandardError, 'Erro ao verificar agendamentos do funcionario.'
  end

  def generate_secure_temporary_password
    # Garante pelo menos um caractere de cada grupo exigido pela validacao da model User
    uppercase = ('A'..'Z').to_a.sample(random: SecureRandom)
    lowercase = ('a'..'z').to_a.sample(random: SecureRandom)
    number    = ('0'..'9').to_a.sample(random: SecureRandom)
    special   = ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '='].sample(random: SecureRandom)

    # Pool de caracteres seguros para completar os 16 digitos
    pool = ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a + ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '=']

    # Preenche mais 12 caracteres aleatorios
    others = Array.new(12) { pool.sample(random: SecureRandom) }

    # Embaralha os caracteres de forma criptograficamente segura e junta
    (others + [uppercase, lowercase, number, special]).shuffle(random: SecureRandom).join
  end
end