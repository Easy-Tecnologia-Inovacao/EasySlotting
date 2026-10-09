module SuperAdmin
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    before_action :require_super_admin!

    def index
      plans_count                   = Plan.count
      active_subscriptions_count    = Subscription.where(status: 'active').count
      canceled_subscriptions_count  = Subscription.where(status: 'canceled').count
      establishments_count          = Establishment.count
      customers_count               = Customer.count

      # Estabelecimentos novos neste mês
      new_establishments_this_month = Establishment
        .where('created_at >= ?', Time.current.beginning_of_month)
        .count

      # Receita acumulada do mês atual (assinaturas ativas e canceladas)
      monthly_revenue = Subscription
        .where(status: %w[active canceled])
        .where('created_at >= ?', Time.current.beginning_of_month)
        .sum(:price_paid)

      # Receita dos últimos 6 meses (para gráfico de tendência)
      revenue_trend = (0..5).map do |months_ago|
        period_start = months_ago.months.ago.beginning_of_month
        period_end   = months_ago.months.ago.end_of_month
        revenue      = Subscription
          .where(status: %w[active canceled])
          .where(created_at: period_start..period_end)
          .sum(:price_paid)
        {
          month:   period_start.strftime('%b/%Y'),
          revenue: revenue.to_f
        }
      end.reverse

      subscriptions_by_plan = Plan
        .left_joins(:subscriptions)
        .group('plans.id', 'plans.name')
        .select('plans.name, COUNT(subscriptions.id) AS total')
        .map { |row| { name: row.name, total: row.total.to_i } }

      cancellation_reasons = SubscriptionCancellation
        .group(:reason)
        .count
        .map { |reason, total| { reason: format_reason(reason), total: total } }

      recent_cancellations = SubscriptionCancellation
        .includes(subscription: :plan)
        .order(created_at: :desc)
        .limit(8)
        .map do |c|
          {
            id:                c.id,
            reason:            format_reason(c.reason),
            details:           c.details,
            canceled_by_role:  c.canceled_by_role,
            created_at:        c.created_at,
            plan_name:         c.subscription&.plan&.name
          }
        end

      establishments = Establishment.order(:name).select(:id, :name, :slug).map do |e|
        { id: e.id, name: e.name, slug: e.slug }
      end

      render json: {
        summary: {
          plans_count:                  plans_count,
          active_subscriptions_count:   active_subscriptions_count,
          canceled_subscriptions_count: canceled_subscriptions_count,
          establishments_count:         establishments_count,
          customers_count:              customers_count,
          new_establishments_this_month: new_establishments_this_month,
          monthly_revenue:              monthly_revenue.to_f
        },
        charts: {
          subscriptions_by_plan:  subscriptions_by_plan,
          cancellation_reasons:   cancellation_reasons,
          revenue_trend:          revenue_trend
        },
        recent_cancellations: recent_cancellations,
        establishments: establishments
      }, status: :ok
    end

    private


    def format_reason(reason)
      labels = {
        'preco_muito_alto' => 'Preço muito alto',
        'nao_estou_usando' => 'Não está usando',
        'encontrei_outra_plataforma' => 'Encontrou outra plataforma',
        'faltam_funcionalidades' => 'Faltam funcionalidades',
        'dificuldade_de_uso' => 'Dificuldade de uso',
        'atendimento_suporte' => 'Atendimento / suporte',
        'problema_tecnico' => 'Problema técnico',
        'outro' => 'Outro'
      }

      labels[reason] || reason.to_s.humanize
    end
  end
end