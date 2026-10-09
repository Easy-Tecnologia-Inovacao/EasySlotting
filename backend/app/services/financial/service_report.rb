module Financial
  class ServiceReport
    def initialize(establishment:, params:)
      @establishment = establishment
      @params = params
    end

    def call
      raise 'Estabelecimento não informado.' if @establishment.blank?

      services = fetch_services
      total_servicos = services.size
      ativos = services.count(&:active)
      inativos = total_servicos - ativos

      ticket_medio =
        if total_servicos.positive?
          (services.sum { |s| s.price.to_d } / total_servicos).round(2)
        else
          0.to_d
        end

      media_duracao =
        if total_servicos.positive?
          (services.sum { |s| s.duration_minutes.to_i }.to_f / total_servicos).round
        else
          0
        end

      # Métricas de agendamentos e faturamento no período
      appointments_scope = fetch_completed_appointments
      total_agendamentos = appointments_scope.count
      faturamento_total = appointments_scope.sum { |a| (a.price_snapshot || a.service&.price || 0).to_d }

      appointments_by_service = appointments_scope.group_by(&:service_id)
      employees_count_by_service = EmployeeService.where(service_id: services.map(&:id)).group(:service_id).count

      servico_mais_caro = services.max_by { |s| s.price.to_d }
      servico_mais_barato = services.min_by { |s| s.price.to_d }
      maior_duracao = services.max_by { |s| s.duration_minutes.to_i }

      # Destaque de agendamentos / faturamento
      service_stats = services.map do |service|
        appts = appointments_by_service[service.id] || []
        count = appts.size
        rev = appts.sum { |a| (a.price_snapshot || service.price || 0).to_d }
        {
          service: service,
          appointments_count: count,
          revenue: rev
        }
      end

      mais_agendado_item = service_stats.select { |i| i[:appointments_count].positive? }.max_by { |i| i[:appointments_count] }
      maior_faturamento_item = service_stats.select { |i| i[:revenue].positive? }.max_by { |i| i[:revenue] }

      catalog = build_catalog(services, appointments_by_service, employees_count_by_service)
      ranking = build_ranking(services, service_stats)

      {
        summary: {
          total_servicos: total_servicos,
          ativos: ativos,
          inativos: inativos,
          ticket_medio: ticket_medio.to_f,
          percentual_ativos: percentage(ativos, total_servicos),
          percentual_inativos: percentage(inativos, total_servicos),
          media_duracao: media_duracao,
          total_agendamentos: total_agendamentos,
          faturamento_total: faturamento_total.to_f
        },
        highlights: {
          servico_mais_caro: serialize_service(servico_mais_caro),
          servico_mais_barato: serialize_service(servico_mais_barato),
          maior_duracao: serialize_service(maior_duracao),
          mais_agendado: mais_agendado_item ? serialize_service(mais_agendado_item[:service], appointments_count: mais_agendado_item[:appointments_count]) : nil,
          maior_faturamento: maior_faturamento_item ? serialize_service(maior_faturamento_item[:service], revenue: maior_faturamento_item[:revenue].to_f) : nil
        },
        ranking: ranking,
        services: catalog
      }
    end

    private

    def fetch_services
      Service.where(establishment_id: @establishment.id)
             .order(active: :desc, name: :asc)
             .to_a
    end

    def fetch_completed_appointments
      scope = Appointment.where(establishment_id: @establishment.id, status: 'completed')
      d_from, d_to = resolved_date_bounds

      if d_from.present? && d_to.present?
        scope = scope.where(appointment_date: d_from..d_to)
      end

      scope.includes(:service).to_a
    end

    def build_catalog(services, appointments_by_service, employees_count_by_service)
      services.map do |service|
        appts = appointments_by_service[service.id] || []
        count = appts.size
        rev = appts.sum { |a| (a.price_snapshot || service.price || 0).to_d }
        emp_count = employees_count_by_service[service.id] || 0

        serialize_service(
          service,
          appointments_count: count,
          revenue: rev.to_f,
          employees_count: emp_count
        )
      end
    end

    def build_ranking(services, service_stats)
      highest_price = [services.map { |s| s.price.to_d }.max.to_f, 1].max
      stats_by_id = service_stats.index_by { |i| i[:service].id }

      services
        .sort_by { |s| -s.price.to_d }
        .map do |service|
          stat = stats_by_id[service.id]
          data = serialize_service(
            service,
            appointments_count: stat ? stat[:appointments_count] : 0,
            revenue: stat ? stat[:revenue].to_f : 0.0
          )
          data.merge(
            percentual: ((service.price.to_d.to_f / highest_price) * 100).round
          )
        end
    end

    def serialize_service(service, extra = {})
      return nil if service.blank?

      {
        id: service.id,
        name: service.name,
        service_type: service.service_type,
        price: service.price.to_d.to_f,
        duration_minutes: service.duration_minutes.to_i,
        description: service.description,
        active: service.active
      }.merge(extra)
    end

    def percentage(value, total)
      return 0 if total.to_i <= 0

      ((value.to_f / total.to_f) * 100).round
    end

    def custom_range?
      @params[:date_from].present? && @params[:date_to].present?
    end

    def resolved_date_bounds
      if custom_range?
        d_from = Date.parse(@params[:date_from])
        d_to   = Date.parse(@params[:date_to])
        # Normaliza ordem invertida em vez de retornar 0 resultados silenciosamente
        d_from, d_to = d_to, d_from if d_from > d_to
        [d_from, d_to]
      else
        range = period_range
        [range.begin.to_date, range.end.to_date]
      end
    rescue ArgumentError
      [29.days.ago.to_date, Date.current]
    end

    def period_range
      case @params[:period]
      when 'hoje'
        Date.current.beginning_of_day..Date.current.end_of_day
      when '7dias'
        6.days.ago.beginning_of_day..Time.current.end_of_day
      when '30dias'
        29.days.ago.beginning_of_day..Time.current.end_of_day
      when '6meses'
        6.months.ago.beginning_of_day..Time.current.end_of_day
      when '1ano'
        1.year.ago.beginning_of_day..Time.current.end_of_day
      else
        29.days.ago.beginning_of_day..Time.current.end_of_day
      end
    end
  end
end
