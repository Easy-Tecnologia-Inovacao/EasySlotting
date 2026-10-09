class Admin::AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!
  before_action :set_appointment, only: [:complete, :cancel, :reschedule, :package_occupied_weeks]

  ALLOWED_PAYMENT_METHODS = %w[pix cartao dinheiro cartao_credito cartao_debito plano_mensal nao_informado].freeze

  def index
    # Limpeza de no-shows (esquecidos no passado)
    AutoCancelNoShowsJob.perform_later

    appointments = @establishment.appointments
                                 .includes(:employee, :service, :customer,
                                           :service_package)

    unless current_user.owner? || current_user.super_admin?
      membership = current_membership
      if membership&.can_view_only_own_clients? && !membership&.can_manage_schedule?
        appointments = appointments.where(employee_id: current_user.id)
      end
    end

    appointments = appointments.where('appointment_date >= ?', params[:start_date]) if params[:start_date].present?
    appointments = appointments.where('appointment_date <= ?', params[:end_date])   if params[:end_date].present?
    appointments = appointments.where(employee_id: params[:employee_id])            if params[:employee_id].present?

    if params[:status].present?
      allowed_statuses = %w[pending confirmed completed canceled]
      requested_statuses = params[:status].split(',').map(&:strip) & allowed_statuses
      appointments = appointments.where(status: requested_statuses) if requested_statuses.any?
    end

    render json: appointments.map { |a|
      # Para planos mensais, busca o progresso de sessões do ciclo ativo
      package_sale_data = if a.service_package_id.present?
        sale = @establishment.service_package_sales
                             .where(
                               customer_id:        a.customer_id,
                               service_package_id: a.service_package_id,
                               status:             'active'
                             )
                             .order(created_at: :asc)
                             .first
        sale ? { sessions_used: sale.sessions_used, sessions_total: sale.sessions_total } : {}
      else
        {}
      end

      base = a.as_json(
        include: {
          employee: { only: [:id, :name] },
          service:  { only: [:id, :name, :duration_minutes] },
          customer: current_user.owner? || current_user.super_admin? ? { only: [:id, :name, :email] } : { only: [:id, :name] }
        }
      ).merge(
        'start_time'      => a.start_time.respond_to?(:strftime) ? a.start_time.strftime('%H:%M') : a.start_time.to_s[0, 5],
        'end_time'        => a.end_time.respond_to?(:strftime)   ? a.end_time.strftime('%H:%M')   : a.end_time.to_s[0, 5],
        'service_package' => a.service_package ? {
          id:             a.service_package.id,
          name:           a.service_package.name,
          sessions_total: a.service_package.sessions_total,
          price:          a.service_package.price
        } : nil,
        'sessions_used'   => package_sale_data[:sessions_used],
        'sessions_total'  => package_sale_data[:sessions_total]
      )
      base
    }, status: :ok
  end

  def available_slots
    result = Scheduling::Appointments::AvailableSlotsService.call(
      establishment_id: @establishment.id,
      employee_id: params[:employee_id],
      service_id: params[:service_id],
      appointment_date: params[:appointment_date],
      ignore_appointment_id: params[:ignore_appointment_id]
    )

    render json: { slots: result }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[AppointmentsController#available_slots] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { error: 'Não foi possível calcular os horários disponíveis. Tente novamente.' }, status: :unprocessable_entity
  end

  def create
    unless current_user.owner? || current_user.super_admin? || current_membership&.can_manage_schedule?
      if params[:employee_id].to_i != current_user.id
        return render json: { error: 'Acesso negado: Você não tem permissão para agendar para outro profissional' }, status: :forbidden
      end
    end

    customer_id = resolve_customer_id!

    sanitized_notes = if params[:notes].present?
                        ActionController::Base.helpers.sanitize(
                          params[:notes].to_s.strip, tags: []
                        ).truncate(500).presence
                      end

    # SEGURANÇA (2.1): O status inicial é sempre 'confirmed' — definido pelo servidor.
    # Parâmetros do cliente são ignorados para evitar bypass do fluxo de checkout
    # (geração de comissões, baixa de estoque, transações financeiras).
    appointment = Scheduling::Appointments::CreateService.call(
      establishment_id: @establishment.id,
      customer_id: customer_id,
      employee_id: params[:employee_id],
      service_id: params[:service_id],
      appointment_date: params[:appointment_date],
      start_time: params[:start_time],
      notes: sanitized_notes,
      status: 'confirmed'
    )

    AuditLogger.log(
      action: 'appointment_created_admin',
      user: current_user,
      establishment: @establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'appointment_created',
        appointment_id: appointment.id,
        appointment_date: params[:appointment_date],
        start_time: params[:start_time],
        employee_id: params[:employee_id],
        service_id: params[:service_id]
      }
    )

    render json: {
      message: 'Agendamento criado com sucesso',
      appointment: appointment.as_json(
        include: {
          employee: { only: [:id, :name] },
          service: { only: [:id, :name, :duration_minutes] },
          customer: current_user.owner? || current_user.super_admin? ? { only: [:id, :name, :email] } : { only: [:id, :name] }
        }
      ).merge(
        'start_time' => appointment.start_time.respond_to?(:strftime) ? appointment.start_time.strftime('%H:%M') : appointment.start_time.to_s[0, 5],
        'end_time' => appointment.end_time.respond_to?(:strftime) ? appointment.end_time.strftime('%H:%M') : appointment.end_time.to_s[0, 5]
      )
    }, status: :created
  rescue StandardError => e
    Rails.logger.error("[AppointmentsController#create] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { error: 'Não foi possível criar o agendamento. Tente novamente.' }, status: :unprocessable_entity
  end

  def cancel
    if %w[completed canceled].include?(@appointment.status)
      return render json: { error: 'Não é possível cancelar um agendamento já finalizado.' }, status: :unprocessable_entity
    end

    cancellation_reason = ActionController::Base.helpers.sanitize(
      params[:cancellation_reason].to_s.strip, tags: []
    ).truncate(250).presence

    @appointment.update!(
      status: 'canceled',
      canceled_at: Time.current,
      cancellation_reason: cancellation_reason
    )

    AuditLogger.log(
      action: 'appointment_canceled_admin',
      user: current_user,
      establishment: @establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'appointment_canceled',
        appointment_id: @appointment.id,
        appointment_date: @appointment.appointment_date,
        start_time: @appointment.start_time.respond_to?(:strftime) ? @appointment.start_time.strftime('%H:%M') : @appointment.start_time.to_s[0, 5],
        cancellation_reason: cancellation_reason
      }
    )

    # Envia emails de notificação de cancelamento
    send_cancel_appointment_emails(@appointment, cancellation_reason)

    render json: {
      message: 'Agendamento cancelado com sucesso',
      status: 'canceled'
    }, status: :ok
  rescue ActiveRecord::RecordInvalid
    render json: { error: 'Não foi possível cancelar o agendamento.' }, status: :unprocessable_entity
  end

  def reschedule
    if %w[completed canceled].include?(@appointment.status)
      return render json: { error: 'Não é possível reagendar um agendamento já finalizado.' }, status: :unprocessable_entity
    end

    unless current_user.owner? || current_user.super_admin? || current_membership&.can_manage_schedule?
      target_emp_id = params[:employee_id].presence || @appointment.employee_id
      if target_emp_id.to_i != current_user.id
        return render json: { error: 'Acesso negado: Você não tem permissão para reagendar para outro profissional.' }, status: :forbidden
      end
    end

    appointment = Scheduling::Appointments::RescheduleService.call(
      appointment: @appointment,
      appointment_date: params[:appointment_date],
      start_time: params[:start_time],
      employee_id: params[:employee_id],
      service_id: params[:service_id]
    )

    AuditLogger.log(
      action: 'appointment_rescheduled_admin',
      user: current_user,
      establishment: @establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'appointment_rescheduled',
        appointment_id: @appointment.id,
        new_date: params[:appointment_date],
        new_time: params[:start_time]
      }
    )

    render json: {
      message: 'Agendamento remanejado com sucesso',
      status: 'confirmed'
    }, status: :ok
  rescue StandardError => e
    Rails.logger.error("[AppointmentsController#reschedule] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { error: 'Não foi possível reagendar o agendamento. Tente novamente.' }, status: :unprocessable_entity
  end

  def package_occupied_weeks
    if @appointment.service_package_id.blank?
      return render json: { occupied_weeks: [], min_date: nil, max_date: nil }, status: :ok
    end

    cycle_appts = @appointment.cycle_appointments

    # 1. Semanas ocupadas do ciclo
    existing_sundays = cycle_appts.where.not(id: @appointment.id).where.not(status: %w[canceled completed]).map do |a|
      d = Date.parse(a.appointment_date.to_s)
      (d - d.wday.days).to_s
    end

    # 2. Limites cronológicos do ciclo ativo (apenas sequenciação, sem trava de mês)
    all_appointments = cycle_appts.where.not(status: 'canceled').order(appointment_date: :asc, start_time: :asc)

    current_index = all_appointments.index { |a| a.id == @appointment.id }
    min_date = nil
    max_date = nil

    if current_index.present? && all_appointments.length > 0
      seq_min = current_index > 0 ? all_appointments[current_index - 1].appointment_date : nil
      seq_max = current_index < all_appointments.length - 1 ? all_appointments[current_index + 1].appointment_date : nil

      min_date = seq_min&.to_s
      max_date = seq_max&.to_s
    end

    render json: {
      occupied_weeks: existing_sundays.uniq,
      min_date: min_date,
      max_date: max_date
    }, status: :ok
  end

  def complete
    if %w[completed canceled].include?(@appointment.status)
      return render json: { error: 'Agendamento já concluído ou cancelado.' }, status: :unprocessable_entity
    end

    # Apenas owner, super_admin ou quem pode gerenciar agenda pode reatribuir o profissional ao concluir
    can_change_employee = current_user.owner? || current_user.super_admin? || current_membership&.can_manage_schedule?
    employee_id = if can_change_employee && params[:employee_id].present?
                    membership = @establishment.establishment_memberships.where(active: true, role: 'employee').find_by(user_id: params[:employee_id])
                    return render json: { error: 'Profissional inválido para este estabelecimento.' }, status: :unprocessable_entity unless membership
                    membership.user_id
                  else
                    @appointment.employee_id
                  end

    # Validação e saneamento dos valores financeiros (impede injeção de valores negativos)
    products_amount = [params[:products_amount].to_d, 0.to_d].max
    raw_pm = params[:payment_method].to_s.strip.downcase
    payment_method = ALLOWED_PAYMENT_METHODS.include?(raw_pm) ? raw_pm : 'nao_informado'

    Appointment.transaction do
      service_amount   = @appointment.price_snapshot || 0
      total_amount     = service_amount + products_amount
      raw_products     = params[:products].presence || []
      products         = []
      notes            = if params[:notes].present?
                           ActionController::Base.helpers.sanitize(
                             params[:notes].to_s.strip, tags: []
                           ).truncate(500).presence
                         end

      @appointment.update!(
        status:       'completed',
        completed_at: Time.current,
        employee_id:  employee_id
      )

      # ── Plano Mensal: desconta sessão ao confirmar o atendimento ──────────
      # O botão "Confirmar Atendimento" (sem sistema de pagamento por enquanto)
      # é o gatilho para incrementar sessions_used (0/N → 1/N → ... → N/N).
      if @appointment.service_package_id.present?
        # Busca o plano ativo do cliente para este pacote.
        # Removemos o where('sessions_used < sessions_total') porque o plano se auto-renova na última sessão.
        package_sale = @establishment.service_package_sales
                                     .where(
                                       customer_id:        @appointment.customer_id,
                                       service_package_id: @appointment.service_package_id,
                                       status:             'active'
                                     )
                                     .order(created_at: :asc)
                                     .first

        if package_sale
          # Previne duplo desconto: verifica se já existe usage para este agendamento
          unless ServicePackageUsage.exists?(
            service_package_sale_id: package_sale.id,
            appointment_id:          @appointment.id
          )
            package = package_sale.service_package
            cycle_size = [package.sessions_total.to_i, 1].max

            is_first_session = false

            # 1. Lógica de Pagamento: Se é a primeira sessão do ciclo (sessions_used == 0), o pacote é marcado como pago!
            if package_sale.sessions_used == 0
              package_sale.update_column(:payment_status, 'paid')
              is_first_session = true
            end

            # Usa a sessão (isso incrementa sessions_used)
            package_sale.use_session!(@appointment)

            # 2. Lógica de Encerramento: Se for a última sessão do pacote (sessions_used == sessions_total)
            if package_sale.sessions_used >= package_sale.sessions_total
              package_sale.update!(status: 'completed')
            end
          end

          if defined?(is_first_session) && is_first_session
            package_price = package_sale.service_package.price || 0
            create_appointment_revenue(
              @appointment,
              total_amount:    package_price + products_amount,
              service_amount:  package_price,
              products_amount: products_amount,
              payment_method:  payment_method,
              products:        products,
              notes:           "Adesão do Plano Mensal ##{package_sale.id}. #{notes}"
            )
          else
            create_appointment_revenue(
              @appointment,
              total_amount:    products_amount,
              service_amount:  0,
              products_amount: products_amount,
              payment_method:  'plano_mensal',
              products:        products,
              notes:           "Atendimento do Plano Mensal ##{package_sale.id}. #{notes}"
            )
          end
        else
          # Plano sem saldo disponível — trata como serviço avulso
          create_appointment_revenue(
            @appointment,
            total_amount:    total_amount,
            service_amount:  service_amount,
            products_amount: products_amount,
            payment_method:  payment_method,
            products:        products,
            notes:           notes
          )
        end
      else
        create_appointment_revenue(
          @appointment,
          total_amount:    total_amount,
          service_amount:  service_amount,
          products_amount: products_amount,
          payment_method:  payment_method,
          products:        products,
          notes:           notes
        )
      end

      # Baixa de estoque dos produtos vendidos com suporte a stock_item_id e validação de quantidade
      if raw_products.is_a?(Array)
        raw_products.each do |p_data|
          p_id  = p_data[:id] || p_data['id'] || p_data[:stock_item_id] || p_data['stock_item_id']
          p_qty = (p_data[:quantity] || p_data['quantity']).to_i

          next unless p_id.present? && p_qty > 0

          stock_item = @establishment.stock_items.find_by(id: p_id)
          next unless stock_item

          # SEGURANÇA (3.1 – IDOR): Itens consignados por funcionário só podem ser
          # debitados pelo próprio dono, pelo profissional do atendimento ou por owners/super_admin.
          # Impede que um colaborador debite o estoque pessoal de outro colega.
          if stock_item.stock_scope == 'funcionario' && stock_item.owner_user_id.present?
            authorized = stock_item.owner_user_id == @appointment.employee_id ||
                         stock_item.owner_user_id == current_user.id           ||
                         current_user.owner? || current_user.super_admin?

            unless authorized
              Rails.logger.warn(
                "[Admin::Appointments#complete] IDOR bloqueado: user=#{current_user.id} " \
                "tentou debitar stock_item=#{stock_item.id} (dono=#{stock_item.owner_user_id}) " \
                "em appointment=#{@appointment.id}"
              )
              raise "O produto '#{stock_item.name}' não pertence ao profissional deste atendimento."
            end
          end

          stock_item.decrement_stock!(p_qty)
          products << p_data
        end
      end

      create_appointment_commission(@appointment)
    end

    AuditLogger.log(
      action: 'appointment_completed',
      user: current_user,
      establishment: @establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'appointment_completed',
        appointment_id: @appointment.id,
        appointment_date: @appointment.appointment_date,
        start_time: @appointment.start_time.respond_to?(:strftime) ? @appointment.start_time.strftime('%H:%M') : @appointment.start_time.to_s[0, 5],
        payment_method: payment_method,
        total_amount: (@appointment.price_snapshot || 0) + (params[:products_amount].to_d rescue 0)
      }
    )

    # Envia email de solicitação de feedback ao cliente
    if @appointment.customer&.email.present?
      FeedbackMailer.feedback_request(@appointment).deliver_later
    end

    render json: {
      message: 'Agendamento concluído com sucesso',
      status: 'completed'
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[AppointmentsController#complete] Validação falhou: #{e.message}")
    render json: { error: 'Não foi possível concluir o agendamento. Verifique os dados e tente novamente.' }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[AppointmentsController#complete] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    render json: { error: 'Não foi possível concluir o agendamento. Tente novamente.' }, status: :unprocessable_entity
  end


  def set_appointment
    @appointment = @establishment.appointments.find(params[:id])
    unless current_user.owner? || current_user.super_admin? || current_membership&.can_manage_schedule?
      if @appointment.employee_id != current_user.id
        render json: { error: 'Acesso negado: Você não pode gerenciar agendamentos de outro profissional' }, status: :forbidden and return
      end
    end
  end

  def resolve_customer_id!
    if params[:customer_mode] == 'walk_in'
      create_walk_in_customer!.id
    else
      customer_id = params[:customer_id].presence
      raise 'Selecione um cliente cadastrado.' if customer_id.blank?

      # Escopo multi-tenant: garante que o cliente pertence ao estabelecimento atual
      customer = @establishment.customers.find_by(id: customer_id)
      raise 'Cliente não encontrado neste estabelecimento.' unless customer

      # SEGURANÇA (2.2): A restrição `can_view_only_own_clients` é validada no servidor.
      # O frontend apenas oculta clientes na listagem — o backend precisa reforçar a
      # política de acesso para impedir que o colaborador forje o customer_id no payload.
      unless current_user.owner? || current_user.super_admin?
        membership = current_membership
        if membership&.can_view_only_own_clients? && !membership&.can_manage_schedule?
          has_prior_relation = @establishment.appointments
                                             .where(employee_id: current_user.id, customer_id: customer.id)
                                             .exists?
          unless has_prior_relation
            Rails.logger.warn(
              "[Admin::Appointments#resolve_customer_id!] Acesso negado: user=#{current_user.id} " \
              "(can_view_only_own_clients) tentou agendar para customer=#{customer.id} sem relação prévia."
            )
            raise 'Você não possui permissão para agendar para este cliente.'
          end
        end
      end

      customer.id
    end
  end

  def create_walk_in_customer!
    name  = ActionView::Base.full_sanitizer.sanitize(params[:walk_in_name].to_s).strip
    email = ActionView::Base.full_sanitizer.sanitize(params[:walk_in_email].to_s).strip.downcase

    raise 'Informe o nome do cliente.' if name.blank?
    raise 'Nome muito longo. Máximo de 100 caracteres.' if name.length > 100
    raise 'Informe o e-mail do cliente.' if email.blank?
    raise 'E-mail inválido.' unless email.match?(URI::MailTo::EMAIL_REGEXP)

    # Busca na tabela Customer isolada por estabelecimento (multi-tenant correto)
    existing_customer = @establishment.customers.find_by(email: email)
    return existing_customer if existing_customer.present?

    # Gera senha que atende todas as regras: maiúscula, minúscula, número, símbolo, 8+ chars
    random_password = "Wk#{SecureRandom.hex(6)}!1A"

    customer = @establishment.customers.create!(
      name:     name,
      email:    email,
      password: random_password,
      password_confirmation: random_password,
      active:   true
    )

    # Envia email de convite para criar conta no site
    CustomerMailer.account_invitation(customer, @establishment).deliver_later

    customer
  end

  def create_appointment_revenue(appointment, total_amount:, service_amount:, products_amount:, payment_method:, products:, notes:)
    existing_transaction = FinancialTransaction.find_by(
      source_type: 'Appointment',
      source_id: appointment.id,
      category: 'appointment_revenue'
    )

    return existing_transaction if existing_transaction.present?
    return if total_amount.blank?

    # Resolve o user para o financeiro:
    # - Walk-in / serviço avulso com user legacy: usa appointment.user se for User
    # - Cliente do sistema (Customer): user_id fica nil; customer_id vai no metadata
    legacy_user = appointment.respond_to?(:user) ? appointment.user : nil
    resolved_user = legacy_user.is_a?(User) ? legacy_user : nil

    FinancialTransaction.create!(
      establishment: appointment.establishment,
      appointment: appointment,
      employee: appointment.employee,
      user: resolved_user,          # nil para clientes do sistema (Customer)
      kind: 'income',
      category: 'appointment_revenue',
      source_type: 'Appointment',
      source_id: appointment.id,
      description: "Receita do agendamento ##{appointment.id}",
      amount: total_amount,
      occurred_on: appointment.appointment_date,
      status: 'paid',
      metadata: {
        payment_method: payment_method,
        service_amount: service_amount,
        products_amount: products_amount,
        total_amount: total_amount,
        products: products,
        notes: notes,
        service_id: appointment.service_id,
        service_name: appointment.service_name_snapshot,
        customer_name: appointment.customer_name_snapshot,
        customer_id: appointment.customer_id  # referência ao Customer (novo modelo)
      }
    )
  end

  def create_appointment_commission(appointment)
    return appointment.commission if appointment.commission.present?
    return if appointment.price_snapshot.blank?

    membership = EstablishmentMembership.find_by(
      establishment_id: appointment.establishment_id,
      user_id: appointment.employee_id,
      active: true
    )

    return unless membership

    amount = calculate_commission_amount(appointment, membership)

    Commission.create!(
      establishment: appointment.establishment,
      appointment: appointment,
      employee: appointment.employee,
      membership: membership,
      calculated_from_amount: appointment.price_snapshot,
      amount: amount,
      status: 'pending',
      reference_month: appointment.appointment_date.strftime('%Y-%m')
    )
  end

  def calculate_commission_amount(appointment, membership)
    price = appointment.price_snapshot.to_d
    financial_value = membership.financial_value.to_d

    case membership.financial_model
    when 'porcentagem'
      (price * financial_value / 100).round(2)
    when 'fixo_servico'
      financial_value.round(2)
    when 'diaria'
      0.to_d
    else
      0.to_d
    end
  end

  def send_cancel_appointment_emails(appointment, reason)
    # Email para o cliente
    if appointment.customer&.email.present?
      CancellationMailer.appointment_customer(appointment, reason).deliver_later
    end

    # Email para o profissional
    if appointment.employee&.email.present?
      CancellationMailer.appointment_employee(appointment, reason).deliver_later
    end

    # Email para o proprietário
    owner = appointment.establishment&.owner
    if owner&.email.present?
      CancellationMailer.appointment_owner(appointment, reason).deliver_later
    end
  rescue => e
    Rails.logger.error("[Admin::AppointmentsController] Falha ao enviar emails de cancelamento: #{e.message}")
  end
end