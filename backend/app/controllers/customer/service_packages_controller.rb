# app/controllers/customer/service_packages_controller.rb
# Controller para retornar os pacotes/planos mensais do cliente logado via JWT.
# Segurança: todos os endpoints usam current_customer.establishment_id para garantir
# multitenancy — nenhum dado de outro estabelecimento é exposto.

class Customer::ServicePackagesController < ApplicationController
  before_action :authenticate_customer!

  RATE_LIMIT_WINDOW = 1.hour
  MAX_PACKAGE_CANCELS_PER_WINDOW = 5

  # GET /api/customer/service_packages
  def index
    # Buscar os pacotes vendidos para este cliente específico
    # current_customer já está no contexto por causa do authenticate_customer!
    package_sales = current_customer.service_package_sales
                                    .where(status: 'active')
                                    .includes(
                                      service_package: :service,
                                      service_package_usages: { appointment: [:employee, :service] }
                                    )
                                    .order(sold_at: :desc, created_at: :desc)

    render json: package_sales.map { |sale| serialize_package(sale) }
  end

  # GET /api/customer/service_packages/available
  # Retorna todos os pacotes ATIVOS do estabelecimento do cliente, com flag
  # indicando se o cliente já possui assinatura ativa de cada pacote.
  # Segurança: scoped por establishment_id do current_customer (multitenancy).
  def available
    establishment_id = current_customer.establishment_id

    # Apenas pacotes ativos do estabelecimento do cliente
    packages = ServicePackage
      .where(establishment_id: establishment_id, active: true)
      .includes(:service)
      .order(:name)

    # Busca em batch as vendas ativas do cliente para estes pacotes
    active_sales_by_package = current_customer.service_package_sales
      .where(status: 'active')
      .where(service_package_id: packages.map(&:id))
      .index_by(&:service_package_id)

    render json: packages.map { |pkg|
      sale = active_sales_by_package[pkg.id]
      {
        id:                  pkg.id,
        name:                pkg.name,
        description:         pkg.description.presence,
        included_items:      pkg.included_items.presence,
        sessions_total:      [pkg.sessions_total.to_i, 1].max,
        duration_minutes:    pkg.duration_minutes,
        price:               pkg.price.to_f,
        service_id:          pkg.service_id,
        service_name:        pkg.service&.name,
        # Flag para o frontend saber se o cliente já tem este pacote ativo
        already_subscribed:  sale.present?,
        # Sessões restantes (null se não subscrito)
        sessions_remaining:  sale&.sessions_remaining,
        # ID da venda ativa (para uso no frontend)
        active_sale_id:      sale&.id
      }
    }
  rescue => e
    Rails.logger.error("[Customer::ServicePackagesController#available] #{e.class}: #{e.message}")
    render json: { error: 'Não foi possível carregar os pacotes disponíveis. Tente novamente.' }, status: :internal_server_error
  end

  # PATCH /api/customer/service_packages/:id/cancel
  def cancel
    sale = current_customer.service_package_sales.find(params[:id])
    canceled_count = 0
    cancellation_reason = if params[:cancellation_reason].present?
                            ActionController::Base.helpers.sanitize(
                              params[:cancellation_reason].to_s.strip, tags: []
                            ).truncate(250).presence
                          end

    # Rate limiting
    recent_cancels = AuditLog.where(
      establishment_id: current_customer.establishment_id,
      action: 'package_canceled',
      created_at: RATE_LIMIT_WINDOW.ago..
    ).where(
      '(auditable_type = ? AND auditable_id = ?) OR user_id = ?',
      'Customer', current_customer.id, current_customer.id
    ).count

    if recent_cancels >= MAX_PACKAGE_CANCELS_PER_WINDOW
      return render json: {
        error: 'Muitos cancelamentos. Aguarde antes de cancelar novamente.'
      }, status: :too_many_requests
    end

    # Captura o profissional antes do cancelamento (para envio de email)
    last_appt = Appointment.where(
      customer_id: current_customer.id,
      service_package_id: sale.service_package_id
    ).where.not(status: 'canceled').order(appointment_date: :desc).first
    employee_for_email = last_appt&.employee
    
    ActiveRecord::Base.transaction do
      sale.update!(
        status: 'canceled',
        cancellation_reason: cancellation_reason
      )
      
      # Cancelar apenas a quantidade de agendamentos pendentes equivalente ao que restava neste pacote
      # Se o cliente tiver dois pacotes iguais ativos, isso evita cancelar os agendamentos do outro pacote.
      appointments_to_cancel = Appointment
        .where(
          customer_id: current_customer.id,
          service_package_id: sale.service_package_id,
          status: %w[pending confirmed]
        )
      
      used_ids = sale.service_package_usages.pluck(:appointment_id).compact
      appointments_to_cancel = appointments_to_cancel.where.not(id: used_ids) if used_ids.any?
      
      appointments_to_cancel = appointments_to_cancel
        .order(appointment_date: :desc, start_time: :desc)
        .limit(sale.sessions_remaining)
        
      canceled_ids = appointments_to_cancel.pluck(:id)
      Appointment.where(id: canceled_ids).update_all(status: 'canceled')
      canceled_count = canceled_ids.length
    end

    # Auditoria do cancelamento (LGPD / rastreabilidade)
    AuditLogger.log(
      action: 'package_canceled',
      user: current_customer,
      establishment: current_customer.establishment,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      details: {
        event: 'package_canceled',
        package_sale_id: sale.id,
        package_name: sale.service_package&.name,
        cancellation_reason: cancellation_reason,
        sessions_remaining: sale.sessions_remaining,
        sessions_canceled: canceled_count
      }
    )

    # Envia emails de notificação de cancelamento do pacote
    send_cancel_package_emails(sale, cancellation_reason, canceled_count, employee_for_email)

    render json: { success: true, message: 'Pacote cancelado com sucesso.' }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Pacote não encontrado.' }, status: :not_found
  rescue => e
    Rails.logger.error("[Customer::ServicePackagesController#cancel] #{e.class}: #{e.message}")
    render json: { error: 'Não foi possível cancelar o pacote. Tente novamente.' }, status: :unprocessable_entity
  end

  private

  def send_cancel_package_emails(sale, reason, sessions_canceled, employee = nil)
    customer = current_customer

    # Email para o cliente
    if customer.email.present?
      CancellationMailer.package_customer(sale, reason, sessions_canceled, customer).deliver_later
    end

    # Email para o profissional (se houver)
    if employee&.email.present?
      CancellationMailer.package_employee(sale, reason, sessions_canceled, employee).deliver_later
    end

    # Email para o proprietário
    owner = sale.establishment&.owner
    if owner&.email.present?
      CancellationMailer.package_owner(sale, reason, sessions_canceled).deliver_later
    end
  rescue => e
    Rails.logger.error("[Customer::ServicePackagesController] Falha ao enviar emails de cancelamento: #{e.message}")
  end

  def serialize_package(sale)
    pkg = sale.service_package

    pending_appointments_data = []
    first_pending = nil

    if sale.status != 'canceled'
      # Agendamentos pendentes/confirmados vinculados a este plano e cliente
      # (sessões agendadas mas ainda não concluídas — não aparecem nos usages)
      pending_appointments = Appointment
        .where(
          customer_id:        current_customer.id,
          establishment_id:   current_customer.establishment_id,
          service_package_id: sale.service_package_id
        )
        .where(status: %w[pending confirmed])
        .where.not(
          id: sale.service_package_usages.pluck(:appointment_id).compact
        )
        .includes(:employee, :service, :establishment)
        .order(appointment_date: :asc, start_time: :asc)

      first_pending = pending_appointments.first

      pending_appointments_data = pending_appointments.map do |appt|
        {
          id: appt.id,
          appointment_date: appt.appointment_date,
          start_time: appt.start_time.respond_to?(:strftime) ? appt.start_time.strftime('%H:%M') : appt.start_time.to_s[0, 5],
          end_time: appt.end_time.respond_to?(:strftime) ? appt.end_time.strftime('%H:%M') : appt.end_time.to_s[0, 5],
          status: appt.status,
          service_id: appt.service_id,
          employee_id: appt.employee_id,
          service: { 
            id: appt.service_id, 
            name: appt.service_name_snapshot || appt.service&.name, 
            duration_minutes: appt.duration_minutes || appt.service&.duration_minutes 
          },
          employee: { 
            id: appt.employee_id, 
            name: appt.employee_name_snapshot || appt.employee&.name 
          },
          establishment: { 
            id: appt.establishment&.id,
            slug: appt.establishment&.slug 
          }
        }
      end
    end

    {
      id: sale.id,
      service_package_id: sale.service_package_id,
      package_name: pkg&.name || 'Plano Personalizado',
      service_name: pkg&.service&.name || pkg&.name || 'Diversos',
      service_id: pkg&.service_id,
      # Employee associado ao plano (para pré-preencher no agendamento)
      typical_employee_id:   first_pending&.employee_id || sale.service_package_usages.last&.appointment&.employee_id,
      typical_employee_name: first_pending&.employee&.name ||
                             first_pending&.employee_name_snapshot ||
                             sale.service_package_usages.last&.appointment&.employee&.name,
      sessions_total: sale.sessions_total,
      sessions_used: sale.sessions_used,
      sessions_remaining: sale.sessions_remaining,
      status: sale.status,
      payment_status: sale.payment_status,
      current_cycle: sale.current_cycle,
      cancellation_reason: sale.try(:cancellation_reason),
      sold_at: sale.sold_at || sale.created_at.to_date,
      expires_at: (sale.sold_at || sale.created_at.to_date) + 30.days,
      total_price: sale.total_price.to_f,
      # ID da sessão mais próxima (próxima a ser realizada) — usado pelo frontend para colorir de azul
      next_appointment_id: first_pending&.id,
      # Sessões agendadas ainda não realizadas
      pending_appointments: pending_appointments_data,
      # Histórico de sessões concluídas (ordenado por data ASC para montar timeline)
      usages: sale.service_package_usages.includes(:appointment).order(used_at: :asc).map do |usage|
        appt = usage.appointment
        {
          id: usage.id,
          used_at: usage.used_at,
          appointment_id: usage.appointment_id,
          employee_name: appt&.employee_name_snapshot || appt&.employee&.name || 'N/A',
          status: appt&.status || 'completed',
          appointment: appt ? {
            id: appt.id,
            appointment_date: appt.appointment_date,
            start_time: appt.start_time.respond_to?(:strftime) ? appt.start_time.strftime('%H:%M') : appt.start_time.to_s[0, 5],
            end_time: appt.end_time.respond_to?(:strftime) ? appt.end_time.strftime('%H:%M') : appt.end_time.to_s[0, 5],
            status: appt.status,
            service_id: appt.service_id,
            employee_id: appt.employee_id,
            service: { id: appt.service_id, name: appt.service_name_snapshot || appt.service&.name, duration_minutes: appt.duration_minutes || appt.service&.duration_minutes },
            employee: { id: appt.employee_id, name: appt.employee_name_snapshot || appt.employee&.name },
            establishment: { slug: appt.establishment&.slug }
          } : nil
        }
      end
    }
  end
end
