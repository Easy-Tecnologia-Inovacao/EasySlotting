module Financial
  module Reports
    class Generator
      DEFAULT_PER_PAGE = 20

      def initialize(establishment:, params:)
        @establishment = establishment
        @params = params
      end

      def call
        {
          filters: filters_payload,
          summary: summary_payload,
          revenue_by_origin: revenue_by_origin_payload,
          entries: entries_payload,
          pagination: pagination_payload
        }
      end

      private

      attr_reader :establishment, :params

      def filters_payload
        {
          period: params[:period].presence || '30dias',
          date_from: params[:date_from],
          date_to: params[:date_to],
          team_type: params[:team_type].presence || 'todos',
          employee_id: params[:employee_id].presence || 'todos',
          status: params[:status].presence || 'todos',
          service_id: params[:service_id].presence || 'todos',
          page: current_page,
          per_page: per_page
        }
      end

      def current_page
        value = params[:page].to_i
        value > 0 ? value : 1
      end

      def per_page
        value = params[:per_page].to_i
        value > 0 ? value : DEFAULT_PER_PAGE
      end

      def archived_employee_ids
        @archived_employee_ids ||= establishment.archived_employees.pluck(:user_id)
      end

      def archived_employees_map
        @archived_employees_map ||= establishment.archived_employees.index_by(&:user_id)
      end

      def base_appointments_scope
        establishment.appointments.includes(:service, :employee, :customer)
      end

      def filtered_appointments_scope
        @filtered_appointments_scope ||= begin
          scope = base_appointments_scope
          scope = apply_period(scope)
          scope = apply_custom_dates(scope)
          scope = apply_employee(scope)
          scope = apply_status(scope)
          scope = apply_service(scope)
          scope = apply_team_type(scope)
          scope.order(appointment_date: :desc, start_time: :desc, id: :desc)
        end
      end

      def completed_appointments_scope
        filtered_appointments_scope.where(status: 'completed')
      end

      def apply_period(scope)
        period = params[:period].presence || '30dias'

        case period
        when 'hoje'
          scope.where(appointment_date: Date.current)
        when '7dias'
          scope.where(appointment_date: 6.days.ago.to_date..Date.current)
        when '30dias'
          scope.where(appointment_date: 29.days.ago.to_date..Date.current)
        when '6meses'
          scope.where(appointment_date: 6.months.ago.to_date..Date.current)
        when '1ano'
          scope.where(appointment_date: 1.year.ago.to_date..Date.current)
        else
          scope
        end
      end

      def apply_custom_dates(scope)
        from = safe_date(params[:date_from])
        to = safe_date(params[:date_to])

        return scope if from.blank? && to.blank?

        if from.present? && to.present?
          scope.where(appointment_date: from..to)
        elsif from.present?
          scope.where('appointment_date >= ?', from)
        elsif to.present?
          scope.where('appointment_date <= ?', to)
        else
          scope
        end
      end

      def apply_employee(scope)
        employee_id = params[:employee_id]
        return scope if employee_id.blank? || employee_id == 'todos'

        scope.where(employee_id: employee_id)
      end

      def apply_status(scope)
        status = params[:status]
        return scope if status.blank? || status == 'todos'

        scope.where(status: status)
      end

      def apply_service(scope)
        service_id = params[:service_id]
        return scope if service_id.blank? || service_id == 'todos'

        scope.where(service_id: service_id)
      end

      def apply_team_type(scope)
        team_type = params[:team_type].presence || 'todos'

        case team_type
        when 'ativos'
          archived_employee_ids.any? ? scope.where.not(employee_id: archived_employee_ids) : scope
        when 'removidos'
          archived_employee_ids.any? ? scope.where(employee_id: archived_employee_ids) : scope.none
        else
          scope
        end
      end

      def safe_date(value)
        return nil if value.blank?

        Date.parse(value.to_s)
      rescue ArgumentError
        nil
      end

      def gross_revenue
        @gross_revenue ||= completed_appointments_scope.sum(:price_snapshot).to_f
      end

      def appointments_count
        @appointments_count ||= completed_appointments_scope.count
      end

      def average_ticket
        return 0.0 if appointments_count.zero?

        gross_revenue / appointments_count
      end

      def removed_team_production
        return 0.0 if archived_employee_ids.empty?

        completed_appointments_scope.where(employee_id: archived_employee_ids).sum(:price_snapshot).to_f
      end

      def filtered_commissions_scope
        @filtered_commissions_scope ||= begin
          scope = establishment.commissions

          if params[:employee_id].present? && params[:employee_id] != 'todos'
            scope = scope.where(employee_id: params[:employee_id])
          end

          if params[:date_from].present? || params[:date_to].present?
            from = safe_date(params[:date_from])
            to = safe_date(params[:date_to])

            if from.present? && to.present?
              scope = scope.joins(:appointment).where(appointments: { appointment_date: from..to })
            elsif from.present?
              scope = scope.joins(:appointment).where('appointments.appointment_date >= ?', from)
            elsif to.present?
              scope = scope.joins(:appointment).where('appointments.appointment_date <= ?', to)
            end
          end

          scope
        end
      end

      def commissions_pending
        filtered_commissions_scope.where(status: 'pending').sum(:amount).to_f
      end

      def commissions_paid
        filtered_commissions_scope.where(status: 'paid').sum(:amount).to_f
      end

      def summary_payload
        {
          gross_revenue: gross_revenue,
          appointments_count: appointments_count,
          average_ticket: average_ticket,
          removed_team_production: removed_team_production,
          commissions_pending: commissions_pending,
          commissions_paid: commissions_paid
        }
      end

      def revenue_by_origin_payload
        services_total = gross_revenue
        packages_total = packages_revenue
        products_total = products_revenue

        total = services_total + packages_total + products_total

        [
          build_origin_item('Serviços', services_total, total),
          build_origin_item('Pacotes', packages_total, total),
          build_origin_item('Produtos', products_total, total)
        ]
      end

      def packages_revenue
        scope = establishment.service_package_sales

        from = safe_date(params[:date_from])
        to = safe_date(params[:date_to])

        if from.present? && to.present?
          scope = scope.where(sold_at: from.beginning_of_day..to.end_of_day)
        elsif from.present?
          scope = scope.where('sold_at >= ?', from.beginning_of_day)
        elsif to.present?
          scope = scope.where('sold_at <= ?', to.end_of_day)
        end

        scope.sum(:total_price).to_f
      end

      def products_revenue
        scope = establishment.financial_transactions.where(kind: 'income', category: 'product_sale')

        from = safe_date(params[:date_from])
        to = safe_date(params[:date_to])

        if from.present? && to.present?
          scope = scope.where(occurred_on: from..to)
        elsif from.present?
          scope = scope.where('occurred_on >= ?', from)
        elsif to.present?
          scope = scope.where('occurred_on <= ?', to)
        end

        scope.sum(:amount).to_f
      end

      def build_origin_item(name, value, total)
        percentage = total.positive? ? ((value / total) * 100).round(2) : 0.0

        {
          name: name,
          value: value,
          percentage: percentage
        }
      end

      def paginated_entries_scope
        filtered_appointments_scope.offset((current_page - 1) * per_page).limit(per_page)
      end

      def employee_name_for(appointment)
        if appointment.has_attribute?(:employee_name_snapshot) && appointment.employee_name_snapshot.present?
          return appointment.employee_name_snapshot
        end

        archived = archived_employees_map[appointment.employee_id]
        if archived&.user_data.is_a?(Hash)
          archived_name = archived.user_data['name'] || archived.user_data[:name]
          return archived_name if archived_name.present?
        end

        return appointment.employee.name if appointment.employee&.name.present?

        'Profissional removido'
      end

      def employee_status_for(appointment)
        archived_employee_ids.include?(appointment.employee_id) ? 'removido' : 'ativo'
      end

      def service_name_for(appointment)
        return appointment.service_name_snapshot if appointment.service_name_snapshot.present?
        return appointment.service.name if appointment.service&.name.present?

        'Serviço removido'
      end

      def customer_name_for(appointment)
        return appointment.customer_name_snapshot if appointment.customer_name_snapshot.present?
        return appointment.customer.name if appointment.customer&.name.present?

        'Cliente'
      end

      def entries_payload
        paginated_entries_scope.map do |appointment|
          {
            id: appointment.id,
            date: appointment.appointment_date,
            customer: customer_name_for(appointment),
            employee: employee_name_for(appointment),
            employee_status: employee_status_for(appointment),
            service: service_name_for(appointment),
            status: appointment.status,
            value: appointment.price_snapshot.to_f,
            removed_at: archived_employees_map[appointment.employee_id]&.archived_at
          }
        end
      end

      def pagination_payload
        total = filtered_appointments_scope.count

        {
          page: current_page,
          per_page: per_page,
          total: total,
          total_pages: (total.to_f / per_page).ceil
        }
      end
    end
  end
end