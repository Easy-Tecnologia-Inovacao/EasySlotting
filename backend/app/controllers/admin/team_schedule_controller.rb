class Admin::TeamScheduleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :set_employee, except: [:all_schedules, :bulk_update]
  before_action :require_schedule_management!, except: [:show]

  TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/

  def show
    # 🔒 SEGURANÇA: Funcionário sem permissão de gerência de agenda só visualiza o próprio horário
    unless current_user&.owner? || current_user&.super_admin? || current_membership&.can_manage_schedule?
      if @employee.id != current_user.id
        return render json: { error: 'Acesso negado: Você não pode visualizar a agenda de outro profissional.' }, status: :forbidden
      end
    end

    working_hours = EmployeeWorkingHour.where(user_id: @employee.id).order(:weekday)
    exceptions = EmployeeScheduleException.where(user_id: @employee.id, active: true)
                                          .where('exception_date >= ?', Date.current)

    render json: {
      employee: {
        id: @employee.id,
        name: @employee.name
      },
      schedule: normalize_schedule(working_hours),
      blocked_dates: exceptions.where(kind: 'blocked_date').pluck(:exception_date).map(&:to_s),
      worked_holidays: exceptions.where(kind: 'worked_holiday').pluck(:exception_date).map(&:to_s)
    }, status: :ok
  end

  def all_schedules
    unless current_user&.owner? || current_user&.super_admin? || current_membership&.can_manage_schedule?
      return render json: { error: 'Acesso negado: você não tem permissão para visualizar agendas de todos os profissionais.' }, status: :forbidden
    end

    employee_ids = @establishment.establishment_memberships
                                  .where(role: 'employee', active: true)
                                  .pluck(:user_id)

    working_hours = EmployeeWorkingHour.where(user_id: employee_ids)
                                        .includes(:user)
                                        .order(:weekday)

    exceptions = EmployeeScheduleException.where(user_id: employee_ids, active: true)
                                           .where('exception_date >= ?', Date.current)

    schedules_by_employee = {}
    working_hours.each do |wh|
      uid = wh.user_id
      schedules_by_employee[uid] ||= []
      schedules_by_employee[uid] << {
        weekday: wh.weekday,
        is_available: wh.is_available,
        morning_start_time: wh.morning_start_time&.to_s,
        morning_end_time: wh.morning_end_time&.to_s,
        afternoon_start_time: wh.afternoon_start_time&.to_s,
        afternoon_end_time: wh.afternoon_end_time&.to_s
      }
    end

    blocked_by_employee = {}
    holidays_by_employee = {}
    exceptions.each do |exc|
      if exc.kind == 'blocked_date'
        blocked_by_employee[exc.user_id] ||= []
        blocked_by_employee[exc.user_id] << exc.exception_date.to_s
      elsif exc.kind == 'worked_holiday'
        holidays_by_employee[exc.user_id] ||= []
        holidays_by_employee[exc.user_id] << exc.exception_date.to_s
      end
    end

    employees = @establishment.establishment_memberships
                              .where(role: 'employee', active: true)
                              .includes(:user)
                              .map do |m|
      {
        id: m.user_id,
        nome: m.user&.name || 'Profissional',
        blocked_dates: blocked_by_employee[m.user_id] || [],
        worked_holidays: holidays_by_employee[m.user_id] || []
      }
    end

    AuditLogger.log(
      action: 'schedule_view_all',
      user: current_user,
      establishment: @establishment,
      auditable: nil,
      details: { employees_count: employees.count }
    )

    render json: { employees: employees }, status: :ok
  end

  def update
    days = params[:days]

    raise ArgumentError, 'Envie a lista de dias da agenda.' if days.blank?
    raise ArgumentError, 'Formato inválido para os dias da agenda.' unless days.is_a?(Array)

    EmployeeWorkingHour.transaction do
      days.each do |day|
        weekday = (day[:weekday] || day['weekday']).to_i
        raise ArgumentError, "Dia da semana inválido: #{weekday}." unless (0..6).cover?(weekday)

        is_available = ActiveModel::Type::Boolean.new.cast(day[:is_available] || day['is_available'])

        morning_start_time = day[:morning_start_time] || day['morning_start_time']
        morning_end_time = day[:morning_end_time] || day['morning_end_time']
        afternoon_start_time = day[:afternoon_start_time] || day['afternoon_start_time']
        afternoon_end_time = day[:afternoon_end_time] || day['afternoon_end_time']

        record = EmployeeWorkingHour.find_or_initialize_by(
          user_id: @employee.id,
          weekday: weekday
        )

        if is_available
          raise ArgumentError, "Informe o início da manhã do dia #{weekday}." if morning_start_time.blank?
          raise ArgumentError, "Informe o fim da manhã do dia #{weekday}." if morning_end_time.blank?
          raise ArgumentError, "Informe o início da tarde/noite do dia #{weekday}." if afternoon_start_time.blank?
          raise ArgumentError, "Informe o fim da tarde/noite do dia #{weekday}." if afternoon_end_time.blank?

          [morning_start_time, morning_end_time, afternoon_start_time, afternoon_end_time].each do |t|
            unless TIME_FORMAT.match?(t.to_s)
              raise ArgumentError, "Formato de horário inválido: #{t}. Use o formato HH:MM."
            end
          end

          if morning_start_time >= morning_end_time
            raise ArgumentError, "No dia #{weekday}, o fim da manhã deve ser maior que o início da manhã."
          end

          if afternoon_start_time >= afternoon_end_time
            raise ArgumentError, "No dia #{weekday}, o fim da tarde/noite deve ser maior que o início da tarde/noite."
          end

          if morning_end_time > afternoon_start_time
            raise ArgumentError, "No dia #{weekday}, a tarde/noite deve começar após o fim da manhã."
          end

          record.is_available = true
          record.morning_start_time = morning_start_time
          record.morning_end_time = morning_end_time
          record.afternoon_start_time = afternoon_start_time
          record.afternoon_end_time = afternoon_end_time
          record.start_time = morning_start_time
          record.end_time = afternoon_end_time
        else
          record.is_available = false
          record.morning_start_time = nil
          record.morning_end_time = nil
          record.afternoon_start_time = nil
          record.afternoon_end_time = nil
          record.start_time = nil
          record.end_time = nil
        end

        record.save!
      end

      today_str = Date.current.to_s
      blocked_dates = Array(params[:blocked_dates]).map(&:to_s).reject(&:blank?).uniq.sort.select { |d| d.match?(/\A\d{4}-\d{2}-\d{2}\z/) }
      worked_holidays = Array(params[:worked_holidays]).map(&:to_s).reject(&:blank?).uniq.sort.select { |d| d.match?(/\A\d{4}-\d{2}-\d{2}\z/) }

      # Camada extra de segurança no backend: recusa inserção de folgas passadas via API.
      blocked_dates = blocked_dates.select { |d| d >= today_str }
      worked_holidays = worked_holidays.select { |d| d >= today_str }

      # Se a data estiver marcada como feriado trabalhado,
      # ela não pode continuar também como folga manual.
      blocked_dates = blocked_dates - worked_holidays

      # Limpa as exceções futuras do funcionário e recria (preservando o histórico passado)
      EmployeeScheduleException.where(user_id: @employee.id)
                               .where('exception_date >= ?', Date.current)
                               .delete_all

      blocked_dates.each do |date|
        EmployeeScheduleException.create!(
          user_id: @employee.id,
          exception_date: date,
          kind: 'blocked_date',
          active: true
        )
      end

      worked_holidays.each do |date|
        EmployeeScheduleException.create!(
          user_id: @employee.id,
          exception_date: date,
          kind: 'worked_holiday',
          active: true
        )
      end

      AuditLogger.log(
        action: 'schedule_update',
        user: current_user,
        establishment: @establishment,
        auditable: @employee,
        details: { employee_name: @employee.name, days_updated: days.count }
      )
    end

    working_hours = EmployeeWorkingHour.where(user_id: @employee.id).order(:weekday)
    exceptions = EmployeeScheduleException.where(user_id: @employee.id, active: true)
                                          .where('exception_date >= ?', Date.current)

    render json: {
      message: 'Agenda do funcionário atualizada com sucesso.',
      employee: {
        id: @employee.id,
        name: @employee.name
      },
      schedule: normalize_schedule(working_hours),
      blocked_dates: exceptions.where(kind: 'blocked_date').pluck(:exception_date).map(&:to_s),
      worked_holidays: exceptions.where(kind: 'worked_holiday').pluck(:exception_date).map(&:to_s)
    }, status: :ok
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[TeamSchedule#update] #{e.class}: #{e.message}")
    render json: { error: 'Erro interno ao salvar a agenda.' }, status: :internal_server_error
  end

  def bulk_update
    # 🔒 SEGURANÇA: Restringe operação de alto impacto exclusivamente para owner ou super_admin
    unless current_user.owner? || current_user.super_admin?
      return render json: { error: 'Acesso negado: apenas o proprietário pode aplicar agenda global.' }, status: :forbidden
    end

    establishment = @establishment
    return render json: { error: 'Estabelecimento não encontrado' }, status: :not_found if establishment.nil?

    days = params[:days]
    raise ArgumentError, 'Envie a lista de dias da agenda.' if days.blank?
    raise ArgumentError, 'Formato inválido para os dias da agenda.' unless days.is_a?(Array)

    # Validação prévia de todos os dias
    days.each do |day|
      weekday = (day[:weekday] || day['weekday']).to_i
      raise ArgumentError, "Dia da semana inválido: #{weekday}." unless (0..6).cover?(weekday)

      is_available = ActiveModel::Type::Boolean.new.cast(day[:is_available] || day['is_available'])
      if is_available
        m_start = day[:morning_start_time] || day['morning_start_time']
        m_end = day[:morning_end_time] || day['morning_end_time']
        a_start = day[:afternoon_start_time] || day['afternoon_start_time']
        a_end = day[:afternoon_end_time] || day['afternoon_end_time']

        raise ArgumentError, "Informe o início da manhã do dia #{weekday}." if m_start.blank?
        raise ArgumentError, "Informe o fim da manhã do dia #{weekday}." if m_end.blank?
        raise ArgumentError, "Informe o início da tarde/noite do dia #{weekday}." if a_start.blank?
        raise ArgumentError, "Informe o fim da tarde/noite do dia #{weekday}." if a_end.blank?

        [m_start, m_end, a_start, a_end].each do |t|
          unless TIME_FORMAT.match?(t.to_s)
            raise ArgumentError, "Formato de horário inválido: #{t}. Use o formato HH:MM."
          end
        end

        if m_start >= m_end
          raise ArgumentError, "No dia #{weekday}, o fim da manhã deve ser maior que o início da manhã."
        end

        if a_start >= a_end
          raise ArgumentError, "No dia #{weekday}, o fim da tarde/noite deve ser maior que o início da tarde/noite."
        end

        if m_end > a_start
          raise ArgumentError, "No dia #{weekday}, a tarde/noite deve começar após o fim da manhã."
        end
      end
    end

    # Busca apenas os funcionários ativos vinculados a este estabelecimento
    employee_ids = establishment.establishment_memberships
                                .where(role: 'employee', active: true)
                                .pluck(:user_id)
    employees = User.where(id: employee_ids, role: 'employee', active: true)

    EmployeeWorkingHour.transaction do
      employees.each do |employee|
        days.each do |day|
          weekday = (day[:weekday] || day['weekday']).to_i
          is_available = ActiveModel::Type::Boolean.new.cast(day[:is_available] || day['is_available'])

          morning_start_time = day[:morning_start_time] || day['morning_start_time']
          morning_end_time = day[:morning_end_time] || day['morning_end_time']
          afternoon_start_time = day[:afternoon_start_time] || day['afternoon_start_time']
          afternoon_end_time = day[:afternoon_end_time] || day['afternoon_end_time']

          record = EmployeeWorkingHour.find_or_initialize_by(
            user_id: employee.id,
            weekday: weekday
          )

          if is_available
            record.is_available = true
            record.morning_start_time = morning_start_time
            record.morning_end_time = morning_end_time
            record.afternoon_start_time = afternoon_start_time
            record.afternoon_end_time = afternoon_end_time
            record.start_time = morning_start_time
            record.end_time = afternoon_end_time
          else
            record.is_available = false
            record.morning_start_time = nil
            record.morning_end_time = nil
            record.afternoon_start_time = nil
            record.afternoon_end_time = nil
            record.start_time = nil
            record.end_time = nil
          end

          record.save!
        end
      end

      sync_establishment_business_hours
    end

    AuditLogger.log(
      action: 'schedule_bulk_update',
      user: current_user,
      establishment: @establishment,
      auditable: nil,
      details: { employees_count: employees.count, days_updated: days.count }
    )

    render json: { message: "Agenda global aplicada com sucesso a #{employees.count} colaboradores." }, status: :ok
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: "Erro de validação: #{e.record.errors.full_messages.to_sentence}" }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[TeamSchedule#bulk_update] #{e.class}: #{e.message}")
    render json: { error: 'Erro interno ao aplicar agenda global.' }, status: :internal_server_error
  end

  private

  def set_employee
    # SEGURANÇA (3.2 – IDOR): Resolve de forma inequívoca o colaborador usando
    # uma query que aceita tanto o ID da membership quanto o user_id.
    # Evita a confusão onde params[:id] poderia coincidir com o user_id de outro
    # profissional no mesmo estabelecimento e alterar a agenda da pessoa errada.
    membership = @establishment.establishment_memberships
                               .where(active: true, role: 'employee')
                               .where('id = :id OR user_id = :id', id: params[:id].to_i)
                               .first

    unless membership&.user.present? && membership.user.role == 'employee'
      Rails.logger.warn(
        "[Admin::TeamSchedule#set_employee] Colaborador não encontrado: params[:id]=#{params[:id]}, " \
        "establishment=#{@establishment.id}"
      )
      raise ActiveRecord::RecordNotFound
    end

    @employee = membership.user
  end

  def normalize_schedule(working_hours)
    base = [
      {
        weekday: 1,
        nome: 'Segunda',
        is_available: true,
        morning_start_time: '08:00',
        morning_end_time: '12:00',
        afternoon_start_time: '13:00',
        afternoon_end_time: '22:00'
      },
      {
        weekday: 2,
        nome: 'Terça',
        is_available: true,
        morning_start_time: '08:00',
        morning_end_time: '12:00',
        afternoon_start_time: '13:00',
        afternoon_end_time: '22:00'
      },
      {
        weekday: 3,
        nome: 'Quarta',
        is_available: true,
        morning_start_time: '08:00',
        morning_end_time: '12:00',
        afternoon_start_time: '13:00',
        afternoon_end_time: '22:00'
      },
      {
        weekday: 4,
        nome: 'Quinta',
        is_available: true,
        morning_start_time: '08:00',
        morning_end_time: '12:00',
        afternoon_start_time: '13:00',
        afternoon_end_time: '22:00'
      },
      {
        weekday: 5,
        nome: 'Sexta',
        is_available: true,
        morning_start_time: '08:00',
        morning_end_time: '12:00',
        afternoon_start_time: '13:00',
        afternoon_end_time: '22:00'
      },
      {
        weekday: 6,
        nome: 'Sábado',
        is_available: true,
        morning_start_time: '08:00',
        morning_end_time: '12:00',
        afternoon_start_time: '13:00',
        afternoon_end_time: '22:00'
      },
      {
        weekday: 0,
        nome: 'Domingo',
        is_available: false,
        morning_start_time: '08:00',
        morning_end_time: '12:00',
        afternoon_start_time: '13:00',
        afternoon_end_time: '22:00'
      }
    ]

    by_weekday = working_hours.index_by(&:weekday)

    base.map do |day|
      record = by_weekday[day[:weekday]]

      if record.present?
        {
          weekday: record.weekday,
          nome: day[:nome],
          is_available: record.is_available,
          morning_start_time: format_time(record.morning_start_time) || day[:morning_start_time],
          morning_end_time: format_time(record.morning_end_time) || day[:morning_end_time],
          afternoon_start_time: format_time(record.afternoon_start_time) || day[:afternoon_start_time],
          afternoon_end_time: format_time(record.afternoon_end_time) || day[:afternoon_end_time]
        }
      else
        day
      end
    end
  end

  def format_time(value)
    return nil if value.blank?
    value.strftime('%H:%M')
  end

  # Sincroniza os BusinessHour do estabelecimento com base nos horários
  # ativos de todos os funcionários. Chamado dentro da transação para
  # garantir atomicidade com as EmployeeWorkingHour.
  def sync_establishment_business_hours
    membership_user_ids = @establishment.establishment_memberships
                                        .joins(:user)
                                        .where(establishment_memberships: { active: true }, users: { active: true })
                                        .pluck(:user_id)

    return if membership_user_ids.empty?

    # Uma única query para buscar todos os horários ativos dos membros,
    # agrupados por weekday com os extremos de horário.
    stats_by_weekday = EmployeeWorkingHour
      .where(user_id: membership_user_ids, is_available: true)
      .group(:weekday)
      .having('COUNT(*) > 0')
      .pluck(
        Arel.sql('weekday, MIN(morning_start_time) AS earliest, MAX(afternoon_end_time) AS latest')
      )

    stats_map = stats_by_weekday.to_h { |wd, earliest, latest| [wd, { earliest: earliest, latest: latest }] }

    records = BusinessHour.where(establishment_id: @establishment.id).index_by(&:weekday)

    (0..6).each do |wd|
      stat = stats_map[wd]

      record = records[wd] || BusinessHour.new(establishment_id: @establishment.id, weekday: wd)

      if stat
        record.assign_attributes(is_open: true, start_time: stat[:earliest], end_time: stat[:latest])
      else
        record.assign_attributes(is_open: false, start_time: nil, end_time: nil)
      end

      record.save!
    end
  end
end
