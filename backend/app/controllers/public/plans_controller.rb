# app/controllers/public/plans_controller.rb
# Endpoint público — não requer autenticação.
# Expõe apenas campos necessários para a landing page; campos internos são omitidos.
class Public::PlansController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def index
    plans = Plan.where(active: true).in_catalog_order
    render json: plans.map { |plan| serialize(plan) }
  end

  private

  def serialize(plan)
    effective_price = plan.promotion_active? && plan.promotional_price.present? ? plan.promotional_price : plan.price

    {
      id:                         plan.id,
      name:                       plan.name,
      description:                plan.description,
      price:                      plan.price.to_f,
      promotional_price:          plan.promotional_price&.to_f,
      promotion_active:           plan.promotion_active?,
      effective_price:            effective_price.to_f,
      discount_percentage:        plan.discount_percentage,
      duration_months:            plan.duration_months,
      highlight:                  plan.highlight,
      max_employees:              plan.max_employees,
      max_services:               plan.max_services,
      max_appointments_per_month: plan.max_appointments_per_month,
      max_owner_sessions:         plan.max_owner_sessions
    }
  end
end
