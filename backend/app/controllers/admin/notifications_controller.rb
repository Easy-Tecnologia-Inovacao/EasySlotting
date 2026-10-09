class Admin::NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!

  # GET /api/admin/notifications
  def index
    # 🔒 SEGURANÇA: Retorna apenas as notificações destinadas ao usuário atual do estabelecimento logado
    notifications = current_user.notifications
                                 .where(establishment_id: @establishment.id)
                                 .order(created_at: :desc)
                                 .limit(20)

    render json: notifications.map { |n| serialize_notification(n) }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[Admin::Notifications#index] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao carregar notificações.' }, status: :internal_server_error
  end

  # PATCH /api/admin/notifications/:id/read
  def read
    # 🔒 SEGURANÇA: Busca garantindo que pertence ao usuário logado
    notification = current_user.notifications.find_by!(id: params[:id], establishment_id: @establishment.id)
    notification.update!(read: true)
    render json: { success: true }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Notificação não encontrada.' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("[Admin::Notifications#read] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao marcar notificação.' }, status: :unprocessable_entity
  end

  # PATCH /api/admin/notifications/read_all
  def read_all
    current_user.notifications
                .where(establishment_id: @establishment.id, read: false)
                .update_all(read: true)

    render json: { success: true }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[Admin::Notifications#read_all] #{e.class}: #{e.message}")
    render json: { error: 'Erro ao marcar notificações.' }, status: :unprocessable_entity
  end

  private

  def serialize_notification(notification)
    {
      id: notification.id,
      title: notification.title,
      content: notification.content,
      read: notification.read,
      created_at: notification.created_at
    }
  end
end
