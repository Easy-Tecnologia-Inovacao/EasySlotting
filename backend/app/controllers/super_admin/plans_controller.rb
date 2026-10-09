module SuperAdmin
  class PlansController < ApplicationController
    before_action :authenticate_user!
    before_action :require_super_admin!
    before_action :set_plan, only: [:update]

    rescue_from ActiveRecord::RecordNotUnique, with: :render_plan_conflict

    def index
      render json: Plan.in_catalog_order
    end

    def create
      plan = Plan.new(plan_params)
      apply_promotion_rules(plan)

      if plan.save
        AuditLogger.log(
          action: 'super_admin_create_plan',
          user: current_user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          auditable: plan,
          details: {
            plan_id: plan.id,
            plan_code: plan.code,
            name: plan.name,
            price: plan.price
          }
        )
        render json: plan, status: :created
      else
        render json: { error: plan.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    end

    def update
      @plan.assign_attributes(plan_params)
      apply_promotion_rules(@plan)

      if @plan.save
        AuditLogger.log(
          action: 'super_admin_update_plan',
          user: current_user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          auditable: @plan,
          details: {
            plan_id: @plan.id,
            plan_code: @plan.code,
            changes: @plan.saved_changes
          }
        )
        render json: @plan
      else
        render json: { error: @plan.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    end

    private

    def render_plan_conflict
      render json: {
        error: 'Já existe um plano ativo com esse limite de sessões ou um plano com esse código. Atualize a lista e escolha valores disponíveis.'
      }, status: :unprocessable_entity
    end

    def set_plan
      @plan = Plan.find(params[:id])
    end


    def plan_params
      params.require(:plan).permit(
        :name,
        :code,
        :description,
        :price,
        :duration_months,
        :max_employees,
        :max_services,
        :max_appointments_per_month,
        :max_owner_sessions,
        :active,
        :promotional_price,
        :discount_percentage,
        :promotion_active,
        :promotion_starts_at,
        :promotion_duration_days,
        :highlight
      )
    end

    def apply_promotion_rules(plan)
      promotion_active = ActiveModel::Type::Boolean.new.cast(plan.promotion_active)

      unless promotion_active
        plan.promotional_price = nil
        plan.discount_percentage = nil
        plan.promotion_starts_at = nil
        plan.promotion_ends_at = nil
        plan.promotion_duration_days = nil
        return
      end

      if plan.promotion_starts_at.present? && plan.promotion_duration_days.present?
        plan.promotion_ends_at = plan.promotion_starts_at + plan.promotion_duration_days.days
      end
    end
  end
end
