module Financial
  class PackageReport
    def initialize(establishment:, params:)
      @establishment = establishment
      @params = params
    end

    def call
      raise 'Estabelecimento não informado.' if @establishment.blank?

      packages = filtered_packages

      total_pacotes = packages.size
      ativos = packages.count(&:active)
      inativos = total_pacotes - ativos

      ticket_medio =
        if total_pacotes.positive?
          packages.sum { |p| p.price.to_d } / total_pacotes
        else
          0.to_d
        end

      media_duracao =
        if total_pacotes.positive?
          (packages.sum { |p| p.duration_minutes.to_i }.to_f / total_pacotes).round
        else
          0
        end

      pacote_mais_caro = packages.max_by { |p| p.price.to_d }
      pacote_mais_barato = packages.min_by { |p| p.price.to_d }
      maior_duracao = packages.max_by { |p| p.duration_minutes.to_i }

      ranking = build_ranking(packages)
      catalog = build_catalog(packages)

      {
        summary: {
          total_pacotes: total_pacotes,
          ativos: ativos,
          inativos: inativos,
          ticket_medio: ticket_medio.to_f,
          percentual_ativos: percentage(ativos, total_pacotes),
          percentual_inativos: percentage(inativos, total_pacotes),
          media_duracao: media_duracao
        },
        highlights: {
          pacote_mais_caro: serialize_package(pacote_mais_caro),
          pacote_mais_barato: serialize_package(pacote_mais_barato),
          maior_duracao: serialize_package(maior_duracao)
        },
        ranking: ranking,
        packages: catalog
      }
    end

    private

    def filtered_packages
      scope = ServicePackage.where(establishment_id: @establishment.id)

      if custom_range?
        d_from = parsed_date_from
        d_to   = parsed_date_to
        # Normaliza ordem invertida em vez de retornar 0 resultados silenciosamente
        d_from, d_to = d_to, d_from if d_from > d_to
        scope = scope.where(created_at: d_from.beginning_of_day..d_to.end_of_day)
      else
        scope = scope.where(created_at: period_range)
      end

      scope.order(created_at: :desc).to_a
    end

    def build_ranking(packages)
      highest_price = [packages.map { |p| p.price.to_d }.max.to_f, 1].max

      packages
        .sort_by { |p| -p.price.to_d }
        .map do |package|
          data = serialize_package(package)
          data.merge(
            percentual: ((package.price.to_d.to_f / highest_price) * 100).round
          )
        end
    end

    def build_catalog(packages)
      packages.map do |package|
        serialize_package(package)
      end
    end

    def serialize_package(package)
      return nil if package.blank?

      {
        id: package.id,
        name: package.name,
        price: package.price.to_d.to_f,
        duration_minutes: package.duration_minutes.to_i,
        description: package.description,
        active: package.active,
        items: parse_items(package.included_items)
      }
    end

    def parse_items(value)
      return [] if value.blank?

      value
        .to_s
        .split(',')
        .map(&:strip)
        .reject(&:blank?)
    end

    def percentage(value, total)
      return 0 if total.to_i <= 0

      ((value.to_f / total.to_f) * 100).round
    end

    def custom_range?
      @params[:date_from].present? && @params[:date_to].present?
    end

    def parsed_date_from
      Date.parse(@params[:date_from])
    rescue ArgumentError
      29.days.ago.to_date
    end

    def parsed_date_to
      Date.parse(@params[:date_to])
    rescue ArgumentError
      Date.current
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