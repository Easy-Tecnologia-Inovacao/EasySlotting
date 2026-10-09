# app/controllers/admin/customers_controller.rb
# Lista customers do estabelecimento do usuário logado (owner/employee).
# Migrado para buscar da tabela customers (não mais de users).

class Admin::CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!

  # GET /api/admin/customers
  def index
    customers = @establishment.customers.where(active: true).order(:name)

    # 🔒 SEGURANÇA: Funcionários com flag "ver apenas próprios clientes"
    # só recebem clientes dos seus próprios agendamentos
    unless current_user&.owner? || current_user&.super_admin?
      membership = current_membership
      if membership&.can_view_only_own_clients? && !membership&.can_manage_schedule?
        customer_ids = @establishment.appointments
                                     .where(employee_id: current_user.id)
                                     .where.not(customer_id: nil)
                                     .distinct
                                     .pluck(:customer_id)
        customers = customers.where(id: customer_ids)
      end
    end

    render json: customers.select(:id, :name, :email, :phone), status: :ok
  rescue StandardError => e
    Rails.logger.error("[Admin::Customers#index] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao listar clientes.' }, status: :internal_server_error
  end
end