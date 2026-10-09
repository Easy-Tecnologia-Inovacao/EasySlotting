class Admin::StockItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!
  before_action :require_stock_management!, except: [:index]
  before_action :set_stock_item, only: [:update, :destroy, :add_stock]
  before_action :authorize_stock_item_ownership!, only: [:update, :destroy, :add_stock]

  def index
    # Proprietários e colaboradores com permissão geral veem todo o estoque ativo
    # Colaboradores sem can_manage_stock veem somente itens consignados a si mesmos
    if current_user.owner? || current_user.super_admin? || current_membership&.can_manage_stock?
      items = @establishment.stock_items.where(active: true).order(created_at: :desc)
    else
      items = @establishment.stock_items.where(active: true, stock_scope: 'funcionario', owner_user_id: current_user.id).order(created_at: :desc)
    end

    render json: items.map { |item| serialize_item(item) }, status: :ok
  end

  def create
    item = @establishment.stock_items.new(stock_item_params)

    if item.save
      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'create_stock_item',
        auditable: item,
        ip_address: request.remote_ip,
        details: { name: item.name, price: item.sale_price.to_f, quantity: item.quantity, stock_scope: item.stock_scope, owner_user_id: item.owner_user_id }
      )
      render json: serialize_item(item), status: :created
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @stock_item.assign_attributes(stock_item_params)
    changes = @stock_item.changes

    if @stock_item.save
      AuditLog.create!(
        user: current_user,
        establishment: @establishment,
        action: 'update_stock_item',
        auditable: @stock_item,
        ip_address: request.remote_ip,
        details: { changes: changes }
      )
      render json: serialize_item(@stock_item), status: :ok
    else
      render json: { errors: @stock_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Entrada atômica de estoque (proteção contra concorrência e race conditions)
  def add_stock
    qty = params[:quantity].to_i
    if qty <= 0 || qty > 999_999
      return render json: { error: 'A quantidade de entrada deve ser um número inteiro entre 1 e 999.999.' }, status: :unprocessable_entity
    end

    previous_qty = @stock_item.quantity
    @stock_item.increment_stock!(qty)

    AuditLog.create!(
      user: current_user,
      establishment: @establishment,
      action: 'add_stock_item',
      auditable: @stock_item,
      ip_address: request.remote_ip,
      details: { added_quantity: qty, previous_quantity: previous_qty, new_quantity: @stock_item.quantity }
    )

    render json: serialize_item(@stock_item), status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @stock_item.update(active: false)

    AuditLog.create!(
      user: current_user,
      establishment: @establishment,
      action: 'destroy_stock_item',
      auditable: @stock_item,
      ip_address: request.remote_ip,
      details: { name: @stock_item.name }
    )

    head :no_content
  end

  private

  def stock_item_params
    p = params.require(:stock_item).permit(
      :name,
      :sale_price,
      :quantity,
      :minimum_stock,
      :stock_scope,
      :owner_user_id
    )

    is_admin = current_user.owner? || current_user.super_admin?

    if p[:stock_scope] == 'loja'
      p[:owner_user_id] = nil
    elsif p[:stock_scope] == 'funcionario'
      if is_admin && p[:owner_user_id].present?
        # Administrador pode atribuir a membro ativo do estabelecimento
        unless @establishment.establishment_memberships.where(active: true).exists?(user_id: p[:owner_user_id])
          p[:owner_user_id] = current_user.id
        end
      else
        # Colaborador comum só pode criar/atribuir estoque a si mesmo (Anti-IDOR)
        p[:owner_user_id] = current_user.id
      end
    else
      p[:stock_scope] = 'loja'
      p[:owner_user_id] = nil
    end

    p
  end

  def set_stock_item
    @stock_item = @establishment.stock_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Produto de estoque não encontrado.' }, status: :not_found
  end

  def authorize_stock_item_ownership!
    return if current_user.owner? || current_user.super_admin?

    # Funcionários comuns só podem alterar/deletar se forem donos do item individual
    if @stock_item.stock_scope == 'funcionario' && @stock_item.owner_user_id != current_user.id
      render json: { error: 'Acesso negado: Você não tem permissão para alterar produtos de outro colaborador.' }, status: :forbidden and return
    end

    # Se for da loja, exige permissão can_manage_stock
    if @stock_item.stock_scope == 'loja' && !current_membership&.can_manage_stock?
      render json: { error: 'Acesso negado: Você não tem permissão para gerenciar o estoque geral da loja.' }, status: :forbidden and return
    end
  end

  def serialize_item(item)
    {
      id: item.id,
      nome: item.name,
      preco: item.sale_price.to_f,
      estoque: item.quantity,
      estoque_minimo: item.minimum_stock,
      dono: item.stock_scope,
      donoId: item.owner_user_id
    }
  end
end