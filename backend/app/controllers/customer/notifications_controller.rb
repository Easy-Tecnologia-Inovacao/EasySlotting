# app/controllers/customer/notifications_controller.rb
# Controller para notificações do customer.
# Segurança: retorna apenas notificações do estabelecimento do customer logado.

class Customer::NotificationsController < ApplicationController
  before_action :authenticate_customer!

  # GET /api/customer/notifications
  def index
    # Busca notificações do estabelecimento do customer
    # Por enquanto retorna lista vazia (notificações serão implementadas futuramente)
    render json: { notifications: [] }, status: :ok
  end

  # PATCH /api/customer/notifications/:id/read
  def read
    # Placeholder — notificações serão implementadas futuramente
    render json: { success: true }, status: :ok
  end

  # PATCH /api/customer/notifications/read_all
  def read_all
    # Placeholder — notificações serão implementadas futuramente
    render json: { success: true }, status: :ok
  end
end
