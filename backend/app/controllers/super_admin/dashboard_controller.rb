module SuperAdmin
  class DashboardController < ApplicationController
    before_action :authenticate_user!
    before_action :require_super_admin!
    rate_limit to: 30, within: 1.minute, by: -> { current_user.id }, name: 'dashboard',
      with: -> {
        response.headers['Retry-After'] = '60'
        render json: { error: 'Muitas atualizações. Aguarde um minuto e tente novamente.' }, status: :too_many_requests
      }

    def index
      generated_at = Time.current
      today = generated_at.to_date
      month_start = generated_at.beginning_of_month
      next_month = month_start.next_month
      # Selecionar a última iniciada ANTES de verificar vigência evita ressuscitar
      # um contrato substituído quando o mais novo vence ou fica inadimplente.
      latest_ids = Subscription.where.not(status: 'pending').where('start_date <= ?', today)
        .select('DISTINCT ON (establishment_id) id').order(:establishment_id, created_at: :desc, id: :desc)
      current_contracts = Subscription.where(id: latest_ids, status: %w[active canceled])
        .where('end_date >= ?', today)
        .joins(:establishment).where(establishments: { active: true })

      plans_count                   = Plan.count
      active_subscriptions_count    = current_contracts.count
      canceled_subscriptions_count  = Subscription.where(status: 'canceled').count
      establishments_count          = Establishment.count
      customers_count               = Customer.count

      # Estabelecimentos novos neste mês
      new_establishments_this_month = Establishment
        .where(created_at: month_start...next_month)
        .count

      # Valor bruto contratado por mês de cadastro, nunca pagamento confirmado.
      # PostgreSQL armazena datetime sem fuso em UTC; agrupar no fuso Rails.
      zone = Subscription.connection.quote(Time.zone.tzinfo.identifier)
      month_expression = Arel.sql("DATE_TRUNC('month', subscriptions.created_at AT TIME ZONE 'UTC' AT TIME ZONE #{zone})")
      totals = Subscription.where.not(status: 'pending')
        .where(created_at: (month_start - 5.months)...next_month)
        .group(month_expression).sum(:price_paid)
        .transform_keys { |period| period.to_date }
      contracted_value_trend = (0..5).map do |offset|
        period = month_start - (5 - offset).months
        { month: period.strftime('%m/%Y'), value: (totals[period.to_date] || 0).to_f }
      end

      current_contracts_by_plan = current_contracts.group(:plan_id).count
      subscriptions_by_plan = Plan
        .order(:id).pluck(:id, :name).map do |id, name|
          { name: name, total: current_contracts_by_plan.fetch(id, 0) }
        end

      cancellation_reasons = SubscriptionCancellation
        .group(:reason)
        .count
        .map { |reason, total| { reason: format_reason(reason), total: total } }

      recent_cancellations = SubscriptionCancellation
        .joins(subscription: :plan)
        .select('subscription_cancellations.id, subscription_cancellations.reason, subscription_cancellations.canceled_by_role, subscription_cancellations.created_at, plans.name AS plan_name')
        .order(created_at: :desc, id: :desc)
        .limit(8)
        .map do |c|
          {
            id:                c.id,
            reason:            format_reason(c.reason),
            canceled_by_role:  c.canceled_by_role,
            created_at:        c.created_at,
            plan_name:         c.plan_name
          }
        end

      render json: {
        generated_at: generated_at.iso8601,
        summary: {
          plans_count:                  plans_count,
          active_subscriptions_count:   active_subscriptions_count,
          canceled_subscriptions_count: canceled_subscriptions_count,
          establishments_count:         establishments_count,
          customers_count:              customers_count,
          new_establishments_this_month: new_establishments_this_month,
          monthly_contracted_value:     (totals[month_start.to_date] || 0).to_f
        },
        charts: {
          subscriptions_by_plan:  subscriptions_by_plan,
          cancellation_reasons:   cancellation_reasons,
          contracted_value_trend: contracted_value_trend
        },
        recent_cancellations: recent_cancellations
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
