class Account::SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_establishment_owner!

  def create
    plan = Plan.where(active: true).find_by(id: params[:plan_id])
    unless plan
      return render json: { error: 'Plano indisponível ou inativo.' }, status: :unprocessable_entity
    end

    subscription = nil

    @establishment.with_lock do
      current_subscription = @establishment.subscriptions.current_for_use

      if current_subscription&.status == 'active' && current_subscription.plan_id == plan.id
        return render json: { error: 'Este plano já é o plano ativo do seu estabelecimento.' }, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        if current_subscription.present?
          current_subscription.update!(
            status: 'canceled',
            canceled_at: Time.current
          )
        end

        subscription = @establishment.subscriptions.new(
          plan: plan,
          status: 'active',
          start_date: Date.current,
          end_date: Date.current + plan.duration_months.months,
          next_billing_date: Date.current + plan.duration_months.months,
          billing_cycle: billing_cycle_from(plan.duration_months),
          price_paid: plan.current_price
        )

        unless subscription.save
          raise ActiveRecord::Rollback
        end

        AuditLogger.log(
          action: 'subscription_created',
          user: current_user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          auditable: subscription,
          details: {
            establishment_id: @establishment.id,
            establishment_name: @establishment.name,
            plan_id: plan.id,
            plan_name: plan.name,
            price_paid: subscription.price_paid,
            billing_cycle: subscription.billing_cycle
          }
        )
      end
    end

    if subscription&.persisted?
      render json: subscription_response(subscription), status: :created
    else
      render json: { error: subscription&.errors&.full_messages&.to_sentence || 'Não foi possível contratar o plano.' }, status: :unprocessable_entity
    end
  end

  def show_current
    subscription = @establishment.subscriptions
      .includes(:plan)
      .current_for_use

    if subscription
      render json: subscription_response(subscription)
    else
      render json: nil, status: :ok
    end
  end

  def cancel
    subscription = @establishment.subscriptions.find_by(id: params[:id])
    unless subscription
      return render json: { error: 'Assinatura não encontrada para este estabelecimento.' }, status: :not_found
    end

    unless subscription.status == 'active'
      return render json: { error: 'Apenas assinaturas ativas podem ser canceladas.' }, status: :unprocessable_entity
    end

    raw_reason = params[:reason].to_s.strip
    unless SubscriptionCancellation::REASONS.include?(raw_reason)
      return render json: { error: 'Motivo de cancelamento inválido.' }, status: :unprocessable_entity
    end

    sanitized_details = ActionController::Base.helpers.sanitize(
      params[:details].to_s.strip, tags: []
    ).truncate(500).presence

    canceled_role = current_user.super_admin? ? 'super_admin' : 'owner'

    @establishment.with_lock do
      ActiveRecord::Base.transaction do
        subscription.update!(
          status: 'canceled',
          canceled_at: Time.current
        )

        subscription.create_subscription_cancellation!(
          reason: raw_reason,
          details: sanitized_details,
          canceled_by_role: canceled_role
        )

        AuditLogger.log(
          action: 'subscription_canceled',
          user: current_user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          auditable: subscription,
          details: {
            establishment_id: @establishment.id,
            establishment_name: @establishment.name,
            plan_id: subscription.plan_id,
            reason: raw_reason,
            details: sanitized_details
          }
        )
      end
    end

    render json: {
      message: 'Plano cancelado com sucesso. Ele continuará disponível até o fim do período contratado.',
      subscription: subscription_response(subscription.reload)
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  private

  def require_establishment_owner!
    return if current_user&.super_admin?

    unless current_user&.owner? && @establishment&.owner_id == current_user.id
      render json: { error: 'Acesso negado: Apenas o proprietário deste estabelecimento pode gerenciar a assinatura.' }, status: :forbidden and return
    end
  end

  def billing_cycle_from(duration)
    case duration
    when 1 then 'monthly'
    when 3 then 'quarterly'
    when 12 then 'yearly'
    else 'monthly'
    end
  end

  def subscription_response(subscription)
    {
      id: subscription.id,
      status: subscription.status,
      start_date: subscription.start_date,
      end_date: subscription.end_date,
      next_billing_date: subscription.next_billing_date,
      price_paid: subscription.price_paid,
      billing_cycle: subscription.billing_cycle,
      canceled_at: subscription.canceled_at,
      active_for_use: subscription.active?,
      expired: subscription.expired?,
      canceled_but_still_available: subscription.canceled_but_still_available?,
      plan: {
        id: subscription.plan.id,
        name: subscription.plan.name,
        code: subscription.plan.code,
        description: subscription.plan.description,
        price: subscription.plan.price,
        promotional_price: subscription.plan.promotional_price,
        duration_months: subscription.plan.duration_months,
        max_owner_sessions: subscription.plan.max_owner_sessions
      }
    }
  end
end
