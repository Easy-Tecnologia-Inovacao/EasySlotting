class Public::BookingController < ApplicationController
  before_action :set_establishment

  def booking_data
    services = @establishment.services.where(active: true).order(:name)

    memberships = @establishment.establishment_memberships
                                .joins(:user)
                                .includes(:user)
                                .where(establishment_memberships: { active: true }, users: { active: true })

    employee_ids = memberships.pluck(:user_id)

    employee_services = EmployeeService
      .where(user_id: employee_ids, service_id: services.select(:id))

    owner_id = @establishment.owner_id

    employees = memberships.reject { |m| m.user_id == owner_id }.map do |membership|
      {
        id: membership.user.id,
        name: membership.user.name,
        role_label: membership.specialty.presence || membership.role
      }
    end

    render json: {
      establishment: {
        id: @establishment.id,
        name: @establishment.name,
        slug: @establishment.slug,
        appointment_interval: @establishment.appointment_interval,
        timezone: @establishment.timezone
      },
      services: services.map do |service|
        {
          id: service.id,
          name: service.name,
          description: service.description,
          price: service.price.to_s,
          duration_minutes: service.duration_minutes
        }
      end,
      employees: employees,
      employee_services: employee_services.map do |es|
        {
          employee_id: es.user_id,
          service_id: es.service_id
        }
      end
    }
  end

  # GET /api/public/establishments/:slug/service_packages
  # Retorna pacotes ativos do estabelecimento para exibição pública.
  # Segurança: dados são sempre buscados pelo @establishment (scoped por slug ativo).
  def service_packages
    packages = @establishment.service_packages
                             .where(active: true)
                             .includes(:service)
                             .order(:name)

    render json: packages.map { |pkg| serialize_package(pkg) }
  end

  def available_days
    service = @establishment.services.find_by(id: params[:service_id])

    return render json: { error: 'Serviço não encontrado.' }, status: :unprocessable_entity unless service

    employee_id = params[:employee_id].to_s
    days_ahead  = [(params[:days_ahead] || 30).to_i, 1].max
    days_ahead  = 60 if days_ahead > 60

    tz         = @establishment.timezone.presence || 'America/Sao_Paulo'
    start_date = Time.current.in_time_zone(tz).to_date
    end_date   = start_date + (days_ahead - 1).days
    date_range = start_date..end_date

    if employee_id == 'any'
      available_days = available_days_for_any_employee(service, date_range, tz)
    else
      return render json: { error: 'Profissional inválido.' }, status: :unprocessable_entity \
        unless employee_belongs_to_establishment?(employee_id)

      available_days = available_days_for_employee(employee_id, service, date_range, tz)
    end

    render json: { success: true, available_days: available_days }
  rescue Date::Error
    render json: { error: 'Data inválida.' }, status: :unprocessable_entity
  end

  def available_slots
    service = @establishment.services.find_by(id: params[:service_id])

    return render json: { error: 'Serviço não encontrado.' }, status: :unprocessable_entity unless service

    employee_id = params[:employee_id].to_s
    date        = params[:date].to_s

    return render json: { error: 'Data é obrigatória.' }, status: :unprocessable_entity if date.blank?

    if employee_id == 'any'
      result = available_slots_for_any_employee(service, date)
    else
      return render json: { error: 'Profissional inválido.' }, status: :unprocessable_entity \
        unless employee_belongs_to_establishment?(employee_id)

      result = Scheduling::Appointments::AvailableSlotsService.call(
        establishment_id: @establishment.id,
        employee_id:      employee_id,
        service_id:       service.id,
        appointment_date: date
      )
    end

    render json: {
      success:         true,
      available_slots: result[:available_slots] || [],
      occupied_slots:  result[:occupied_slots]  || []
    }
  rescue Date::Error
    render json: { error: 'Data inválida.' }, status: :unprocessable_entity
  end

  private

  def set_establishment
    @establishment = Establishment.find_by!(slug: params[:slug], active: true)
  end

  def serialize_package(pkg)
    {
      id:               pkg.id,
      name:             pkg.name,
      description:      pkg.description.presence,
      included_items:   pkg.included_items.presence,
      sessions_total:   [pkg.sessions_total.to_i, 1].max,
      duration_minutes: pkg.duration_minutes,
      total_price:      pkg.price.to_f,
      service_id:       pkg.service_id,
      service_name:     pkg.service&.name
    }
  end

  def employee_belongs_to_establishment?(employee_id)
    @establishment.establishment_memberships
                  .joins(:user)
                  .where(establishment_memberships: { active: true }, users: { active: true }, user_id: employee_id)
                  .exists?
  end

  # ─── AVAILABLE DAYS ────────────────────────────────────────────────────────

  # Versão otimizada: pré-carrega TUDO antes dos loops
  def available_days_for_employee(employee_id, service, date_range, tz)
    # 1. Pré-carrega horários de trabalho do funcionário (indexados por weekday)
    working_hours = EmployeeWorkingHour
      .where(user_id: employee_id, is_available: true)
      .index_by(&:weekday)

    # 2. Pré-carrega horários do estabelecimento (indexados por weekday)
    business_hours = BusinessHour
      .where(establishment_id: @establishment.id, is_open: true)
      .index_by(&:weekday)

    # 3. Pré-carrega exceções do funcionário no range inteiro (1 query)
    exceptions = EmployeeScheduleException
      .where(user_id: employee_id, exception_date: date_range, active: true)
      .group_by { |e| [e.exception_date.to_s, e.kind] }

    # 4. Pré-carrega agendamentos no range inteiro (1 query)
    appointments_by_date = Appointment
      .where(
        establishment_id: @establishment.id,
        employee_id:      employee_id,
        appointment_date: date_range
      )
      .where.not(status: 'canceled')
      .group_by { |a| a.appointment_date.to_s }

    now_in_tz    = Time.current.in_time_zone(tz)
    today        = now_in_tz.to_date
    now_minutes  = (now_in_tz.hour * 60) + now_in_tz.min
    duration     = service.duration_minutes.to_i
    interval     = duration

    available_days = []

    date_range.each do |date|
      next if date < today

      weekday       = date.wday
      employee_hour = working_hours[weekday]
      business_hour = business_hours[weekday]

      next if employee_hour.nil? || business_hour.nil?
      next if date_blocked?(date, exceptions)

      day_appointments = appointments_by_date[date.to_s] || []
      occupied_ranges  = build_occupied_ranges(day_appointments)

      slots = build_all_slots(employee_hour, business_hour, duration, interval)

      # Para hoje: filtra slots que já passaram
      slots = slots.select { |s| time_to_minutes(s) >= now_minutes } if date == today

      has_slot = slots.any? do |slot|
        slot_start = time_to_minutes(slot)
        slot_end   = slot_start + duration
        occupied_ranges.none? { |r| slot_start < r[:end] && slot_end > r[:start] }
      end

      available_days << { date: date.to_s } if has_slot
    end

    available_days
  end

  def available_days_for_any_employee(service, date_range, tz)
    employee_ids = allowed_employee_ids_for_service(service)
    return [] if employee_ids.empty?

    # Pré-carrega horários de trabalho de todos os funcionários (1 query)
    working_hours_by_employee = EmployeeWorkingHour
      .where(user_id: employee_ids, is_available: true)
      .group_by(&:user_id)
      .transform_values { |hours| hours.index_by(&:weekday) }

    # Pré-carrega horários do estabelecimento (1 query)
    business_hours = BusinessHour
      .where(establishment_id: @establishment.id, is_open: true)
      .index_by(&:weekday)

    # Pré-carrega exceções de todos os funcionários no range inteiro (1 query)
    exceptions_by_employee = EmployeeScheduleException
      .where(user_id: employee_ids, exception_date: date_range, active: true)
      .group_by(&:user_id)
      .transform_values { |exs| exs.group_by { |e| [e.exception_date.to_s, e.kind] } }

    # Pré-carrega agendamentos de todos os funcionários no range inteiro (1 query)
    appointments_by_employee_date = Appointment
      .where(
        establishment_id: @establishment.id,
        employee_id:      employee_ids,
        appointment_date: date_range
      )
      .where.not(status: 'canceled')
      .group_by { |a| [a.employee_id, a.appointment_date.to_s] }

    now_in_tz   = Time.current.in_time_zone(tz)
    today       = now_in_tz.to_date
    now_minutes = (now_in_tz.hour * 60) + now_in_tz.min
    duration    = service.duration_minutes.to_i
    interval    = duration

    available_days = []

    date_range.each do |date|
      next if date < today

      weekday       = date.wday
      business_hour = business_hours[weekday]
      next if business_hour.nil?

      day_has_slot = employee_ids.any? do |emp_id|
        employee_hour = working_hours_by_employee.dig(emp_id, weekday)
        next false if employee_hour.nil?

        exceptions = exceptions_by_employee[emp_id] || {}
        next false if date_blocked?(date, exceptions)

        day_appointments = appointments_by_employee_date[[emp_id, date.to_s]] || []
        occupied_ranges  = build_occupied_ranges(day_appointments)

        slots = build_all_slots(employee_hour, business_hour, duration, interval)
        slots = slots.select { |s| time_to_minutes(s) >= now_minutes } if date == today

        slots.any? do |slot|
          slot_start = time_to_minutes(slot)
          slot_end   = slot_start + duration
          occupied_ranges.none? { |r| slot_start < r[:end] && slot_end > r[:start] }
        end
      end

      available_days << { date: date.to_s } if day_has_slot
    end

    available_days
  end

  # ─── AVAILABLE SLOTS ───────────────────────────────────────────────────────

  def available_slots_for_any_employee(service, date)
    employee_ids = allowed_employee_ids_for_service(service)

    available_slots = []
    occupied_slots  = []

    employee_ids.each do |employee_id|
      result = Scheduling::Appointments::AvailableSlotsService.call(
        establishment_id: @establishment.id,
        employee_id:      employee_id,
        service_id:       service.id,
        appointment_date: date
      )

      available_slots.concat(result[:available_slots] || [])
      occupied_slots.concat(result[:occupied_slots]   || [])
    end

    all_available = available_slots.uniq
    all_occupied  = occupied_slots.uniq

    # Se um horário está disponível para pelo menos UM profissional,
    # ele deve aparecer como disponível e não como ocupado.
    real_occupied = all_occupied - all_available

    {
      available_slots: all_available.sort,
      occupied_slots:  real_occupied.sort
    }
  end

  # ─── HELPERS ───────────────────────────────────────────────────────────────

  def allowed_employee_ids_for_service(service)
    memberships = @establishment.establishment_memberships
                                .joins(:user)
                                .where(establishment_memberships: { active: true }, users: { active: true })
                                .pluck(:user_id)

    EmployeeService
      .where(user_id: memberships, service_id: service.id)
      .pluck(:user_id)
      .uniq
  end

  # Verifica se uma data está bloqueada usando exceções pré-carregadas (sem queries)
  def date_blocked?(date, exceptions)
    has_blocked_date  = exceptions[[date.to_s, 'blocked_date']].present?
    has_worked_holiday = exceptions[[date.to_s, 'worked_holiday']].present?
    is_holiday        = Holidays.on(date, :br).present?

    # Feriado com worked_holiday → libera
    return false if is_holiday && has_worked_holiday

    # Bloqueio manual → bloqueia
    return true if has_blocked_date

    # Feriado sem worked_holiday → bloqueia
    return true if is_holiday

    false
  end

  def build_occupied_ranges(appointments)
    appointments.map do |a|
      { start: time_to_minutes(a.start_time), end: time_to_minutes(a.end_time) }
    end
  end

  def build_all_slots(employee_hour, business_hour, duration, interval)
    morning   = build_period_slots(
      period_start: employee_hour.morning_start_time,
      period_end:   employee_hour.morning_end_time,
      duration:     duration,
      interval:     interval
    )

    afternoon = build_period_slots(
      period_start: employee_hour.afternoon_start_time,
      period_end:   employee_hour.afternoon_end_time,
      duration:     duration,
      interval:     interval
    )

    (morning + afternoon).uniq.sort
  end

  def build_period_slots(period_start:, period_end:, duration:, interval:)
    return [] if period_start.blank? || period_end.blank?

    start_minutes = time_to_minutes(period_start)
    end_minutes   = time_to_minutes(period_end)

    return [] if start_minutes >= end_minutes

    slots   = []
    current = start_minutes

    while (current + duration) <= end_minutes
      slots << minutes_to_time(current)
      current += interval
    end

    slots
  end

  def time_to_minutes(time)
    hhmm = if time.is_a?(String)
             time[0, 5]
           else
             time.strftime('%H:%M')
           end
    parts = hhmm.split(':').map(&:to_i)
    (parts[0] * 60) + parts[1].to_i
  end

  def minutes_to_time(total_minutes)
    format('%02d:%02d', total_minutes / 60, total_minutes % 60)
  end
end