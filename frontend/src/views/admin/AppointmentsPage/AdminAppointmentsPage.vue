<template>
  <AdminLayout>
    <section class="page-shell">
      <div class="page-content">
        <!-- Header com visual premium -->
        <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
          <div class="header-overlay"></div>
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1 w-100">
            <div class="d-flex align-items-center gap-3">
              <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                <i class="bi bi-calendar-check fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Gestão de Agendamentos</h1>
                <p class="text-muted mb-0 small-text-responsive">Acompanhe os atendimentos do dia, filtre por profissional e gerencie os agendamentos.</p>
              </div>
            </div>
          </div>
        </div>

        <div class="admin-card shadow-sm mb-4">
          <div class="section-header">
            <div class="section-header-left">
              <div class="section-icon bg-primary bg-opacity-10 text-primary">
                <i class="bi bi-calendar-week"></i>
              </div>
              <div>
                <h5 class="section-title mb-0">Navegação por Dia</h5>
                <p class="section-subtitle mb-0">
                  Selecione a data para visualizar os agendamentos.
                </p>
              </div>
            </div>

            <button
              class="btn btn-today rounded-pill fw-bold px-4 py-2"
              @click="goToToday"
            >
              <i class="bi bi-calendar-event me-2"></i>Hoje
            </button>
          </div>

          <div class="d-flex align-items-center gap-3">
            <button
              class="btn btn-scroll d-none d-md-flex align-items-center justify-content-center"
              @click="scrollCalendar(-1)"
            >
              <i class="bi bi-chevron-left"></i>
            </button>

            <div class="date-container flex-grow-1" ref="calendarContainer">
              <div
                v-for="(day, index) in calendarDays"
                :key="index"
                class="date-card transition-all"
                :class="{ 'disabled-day': day.isBlocked, active: selectedDate === day.dateStr && !day.isBlocked }"
                @click="selectDate(day)"
              >
                <div
                  v-if="day.holidayName"
                  class="position-absolute top-0 end-0 mt-2 me-2 rounded-circle bg-danger shadow-sm"
                  style="width: 8px; height: 8px;"
                ></div>

                <span class="small fw-bold opacity-75">{{ day.weekDay }}</span>
                <span
                  class="fs-3 fw-900 lh-1 my-1"
                  :class="{ 'text-danger': (day.holidayName || day.isFolgaExtra) && selectedDate !== day.dateStr }"
                >
                  {{ day.dayNum }}
                </span>
                <span class="small fw-bold opacity-75">{{ day.monthName }}</span>
              </div>
            </div>

            <button
              class="btn btn-scroll d-none d-md-flex align-items-center justify-content-center"
              @click="scrollCalendar(1)"
            >
              <i class="bi bi-chevron-right"></i>
            </button>
          </div>
        </div>

        <div class="admin-card shadow-sm mb-4" v-if="isOwner">
          <div class="section-header pb-3 mb-3 border-bottom">
            <div class="section-header-left">
              <div class="section-icon bg-info bg-opacity-10 text-info">
                <i class="bi bi-funnel"></i>
              </div>
              <div>
                <h5 class="section-title mb-0">Filtro de Profissionais</h5>
                <p class="section-subtitle mb-0">
                  Selecione um profissional ou visualize todos.
                </p>
              </div>
            </div>
          </div>

          <div class="d-flex align-items-center gap-2 overflow-x-auto pb-2 pt-1 px-1 hide-scrollbar">
            <button
              v-for="colab in colaboradores"
              :key="colab.id"
              class="btn colab-filter-btn px-4 py-2 transition-all rounded-pill fw-bold d-flex align-items-center"
              :class="{ active: selectedColab === colab.id }"
              @click="selectColaborador(colab.id)"
            >
              <img
                v-if="colab.img"
                :src="colab.img"
                class="rounded-circle me-2 border border-2 border-white shadow-sm"
                style="width: 28px; height: 28px; object-fit: cover;"
              >
              <i v-else class="bi bi-people-fill me-2 opacity-50 fs-5"></i>
              {{ colab.nome }}
            </button>
          </div>
        </div>

        <div class="admin-card shadow-sm mb-4" v-else-if="colaboradores.length > 0">
          <div class="d-flex align-items-center gap-2">
            <div class="section-icon bg-info bg-opacity-10 text-info" style="width:36px;height:36px;font-size:0.95rem;">
              <i class="bi bi-person-badge"></i>
            </div>
            <div>
              <span class="fw-bold text-body" style="font-size:0.88rem;">Profissional:</span>
              <span class="fw-bold ms-1" style="font-size:0.88rem; color: var(--bs-primary);">
                {{ colaboradores[0]?.nome }}
              </span>
            </div>
          </div>
        </div>

        <div class="admin-card shadow-sm mb-5">
          <div class="appointments-topbar">
            <div class="section-header-left">
              <div class="section-icon bg-success bg-opacity-10 text-success">
                <i class="bi bi-card-checklist"></i>
              </div>
              <div>
                <h5 class="section-title mb-0 d-flex align-items-center flex-wrap gap-2">
                  Atendimentos
                  <span class="date-highlight">
                    {{ formatDateDisplay(selectedDate) }}
                  </span>
                </h5>
                <p class="section-subtitle mb-0">
                  Lista de reservas do dia conforme o filtro.
                </p>
              </div>
            </div>

            <div class="d-flex align-items-center gap-2 flex-wrap">
              <span class="custom-counter-badge">
                {{ agendamentosFiltrados.length }} reserva(s)
              </span>
              <button
                class="btn btn-primary rounded-pill fw-bold px-3 py-2 shadow-sm transition-all hover-lift"
                type="button"
                data-bs-toggle="modal"
                data-bs-target="#modalNovoEncaixe"
                @click="novoEncaixe"
              >
                <i class="bi bi-plus-lg me-1"></i>Novo Encaixe
              </button>
            </div>
          </div>

          <div class="status-filter-bar">
            <button
              v-for="sf in statusFilters"
              :key="sf.value"
              class="status-filter-btn"
              :class="{ active: selectedStatus === sf.value }"
              :style="selectedStatus === sf.value
                ? `background: ${sf.color}; border-color: ${sf.color}; box-shadow: 0 2px 8px ${sf.color}33;`
                : `color: ${sf.color}; border-color: ${sf.color}44;`"
              @click="selectStatusFilter(sf.value)"
            >
              <i class="bi" :class="sf.icon"></i>
              <span>{{ sf.label }}</span>
              <span
                class="status-filter-count"
                :style="selectedStatus === sf.value
                  ? 'background: rgba(255,255,255,0.25); color: #fff;'
                  : `background: ${sf.color}18; color: ${sf.color};`"
              >
                {{ statusCounts[sf.value] ?? 0 }}
              </span>
            </button>
          </div>

          <div v-if="carregando" class="empty-state">
            <div class="empty-state-icon">
              <i class="bi bi-hourglass-split"></i>
            </div>
            <h5 class="fw-bold text-body">Carregando agendamentos...</h5>
            <p class="mb-0 opacity-60 text-muted">
              Aguarde enquanto os dados são carregados.
            </p>
          </div>

          <div v-else-if="agendamentosFiltrados.length > 0" class="agenda-timeline">
            <div
              v-for="agenda in agendamentosFiltrados"
              :key="agenda.id"
              class="agenda-row"
            >
              <div class="agenda-time">
                <div class="agenda-time-text" :style="getStatusTextColor(agenda.status)">
                  {{ agenda.hora }}
                </div>
              </div>

              <div class="agenda-line-col">
                <div class="agenda-line"></div>
                <div class="agenda-dot" :style="getTimelineDotColor(agenda.status)"></div>
              </div>

              <div class="agenda-card" :style="getStatusBorderColor(agenda.status)">
                <div class="agenda-card-content">
                  <div class="agenda-main">
                    <div class="agenda-main-header">
                      <div class="agenda-title-wrap">
                        <div class="d-flex align-items-center gap-2 flex-wrap">
                          <h5 class="fw-bold mb-0 text-body">{{ agenda.clienteNome }}</h5>
                          <span
                            v-if="agenda.servicePackage"
                            class="badge rounded-pill fw-bold border shadow-sm"
                            style="background:rgba(99,102,241,0.1);color:#6366f1;border-color:#6366f1 !important;font-size:0.7rem;"
                          >
                            <i class="bi bi-star-fill me-1"></i>Plano Mensal
                          </span>
                          <span
                            v-else
                            class="badge rounded-pill fw-bold border shadow-sm"
                            style="background:rgba(16,185,129,0.1);color:#10b981;border-color:#10b981 !important;font-size:0.7rem;"
                          >
                            <i class="bi bi-scissors me-1"></i>Serviço Avulso
                          </span>
                        </div>

                        <span
                          class="badge rounded-pill fw-bold border shadow-sm agenda-status-badge"
                          :style="getStatusBadgeStyle(agenda.status)"
                        >
                          Status: {{ agenda.status }}
                        </span>
                      </div>
                    </div>

                    <!-- Bloco de informações do plano mensal -->
                    <div v-if="agenda.servicePackage" class="mt-2 p-2 rounded-3" style="background:rgba(99,102,241,0.07);border:1px solid rgba(99,102,241,0.2);">
                      <small class="fw-bold text-body">
                        <i class="bi bi-star me-1 text-primary"></i>
                        Plano: {{ agenda.servicePackage.name }}
                        <span class="text-muted fw-normal ms-2">({{ agenda.servicePackage.sessions_total }} sessões/mês)</span>
                      </small>
                    </div>

                    <div class="d-flex flex-wrap gap-2 mt-2">
                      <span class="info-pill">
                        <i class="bi bi-scissors me-2 text-primary"></i>
                        {{ agenda.servico }}
                      </span>

                      <span class="info-pill">
                        <i class="bi bi-cash-stack me-2 text-success"></i>
                        <template v-if="agenda.servicePackage">Plano Mensal</template>
                        <template v-else>R$ {{ agenda.preco.toFixed(2).replace('.', ',') }}</template>
                      </span>

                      <span class="info-pill">
                        <i class="bi bi-person-badge me-2 text-info"></i>
                        {{ agenda.funcionarioNome }}
                      </span>

                      <span v-if="agenda.clienteEmail" class="info-pill">
                        <i class="bi bi-envelope me-2 text-secondary"></i>
                        {{ agenda.clienteEmail }}
                      </span>
                    </div>
                    <div v-if="agenda.status === 'Cancelado' && agenda.cancellationReason" class="mt-2 p-2 rounded-3" style="background:rgba(220,53,69,0.07);border:1px solid rgba(220,53,69,0.2);">
                      <small class="fw-bold text-danger">
                        <i class="bi bi-info-circle me-1"></i>
                        Motivo: <span class="fw-normal text-body">{{ agenda.cancellationReason }}</span>
                      </small>
                    </div>
                  </div>


                  <div class="agenda-actions-inline">
                    <button
                      v-if="agenda.status !== 'Concluído' && agenda.status !== 'Cancelado' && agenda.status !== 'Confirmado'"
                      class="btn btn-sm btn-outline-secondary rounded-pill fw-bold px-3 transition-all shadow-sm hover-lift"
                      @click="abrirRemanejar(agenda)"
                      data-bs-toggle="modal"
                      data-bs-target="#modalRemanejar"
                      title="Mudar Horário"
                      :disabled="!canManageAppointment(agenda)"
                    >
                      <i class="bi bi-clock-history me-1"></i> Remanejar
                    </button>

                    <button
                      v-if="agenda.status === 'Confirmado'"
                      class="btn btn-sm btn-success rounded-pill fw-bold px-3 transition-all shadow-sm hover-lift"
                      @click="abrirCheckout(agenda)"
                      data-bs-toggle="modal"
                      data-bs-target="#modalCheckout"
                      title="Finalizar Pagamento"
                      :disabled="!canManageAppointment(agenda)"
                    >
                      <i class="bi bi-check-circle me-1"></i> Pagar
                    </button>

                    <button
                      v-if="agenda.status !== 'Concluído' && agenda.status !== 'Cancelado'"
                      class="btn btn-sm btn-outline-danger rounded-pill fw-bold px-3 transition-all shadow-sm hover-lift"
                      @click="cancelarAgendamento(agenda.id)"
                      title="Cancelar Agendamento"
                      :disabled="!canManageAppointment(agenda)"
                    >
                      <i class="bi bi-x-lg"></i>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="empty-state">
            <div class="empty-state-icon">
              <i class="bi bi-calendar-x"></i>
            </div>
            <h5 class="fw-bold text-body">Nenhum agendamento encontrado</h5>
            <p class="mb-0 opacity-60 text-muted">
              Não há reservas marcadas para esta data com o filtro selecionado.
            </p>
        </div>
      </div>
    </div>
  </section>

    <div class="modal fade" id="modalRemanejar" tabindex="-1" aria-hidden="true" ref="modalReagendarRef">
      <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
        <div class="modal-content" :data-bs-theme="store.isDarkMode ? 'dark' : 'light'" :style="pageThemeVars">
          <div class="modal-header border-bottom-0 pb-0">
            <div>
              <h5 class="modal-title fw-bold dynamic-text mb-0">
                <i class="bi bi-calendar-range me-2" style="color:#6366f1"></i>Reagendar Sessão
              </h5>
              <p class="small dynamic-text opacity-75 mb-0 mt-1" v-if="remanejarAgenda?.servicePackage">
                Pacote {{ remanejarAgenda.servicePackage.name }} • {{ remanejarAgenda.servico }}
              </p>
            </div>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" aria-label="Close" id="closeRemanejarBtn" @click="limparModalAberto"></button>
          </div>
          
          <div class="modal-body custom-scrollbar pt-3" v-if="remanejarAgenda">
            <p class="small text-muted mb-3">Selecione o novo profissional, data e horário para remanejar o agendamento.</p>
            <!-- 1. Escolha do Tipo: Serviço Avulso ou Pacote Mensal -->
            <section class="mb-4">
              <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-1">
                1. Tipo de Atendimento
              </label>
              <p class="small text-muted mb-2">Escolha se será um serviço avulso ou uma sessão de pacote mensal.</p>
              <div class="d-flex flex-wrap gap-2 mb-3">
                <button
                  type="button"
                  class="btn rounded-pill fw-bold px-4 py-2 shadow-sm transition-all"
                  :class="selectedBookingMode === 'service' ? 'btn-primary' : 'btn-outline-secondary'"
                  @click="selectBookingMode('service')"
                >
                  <i class="bi bi-scissors me-1"></i> Serviço Avulso
                </button>
                <button
                  type="button"
                  class="btn rounded-pill fw-bold px-4 py-2 shadow-sm transition-all"
                  :class="selectedBookingMode === 'package' ? 'btn-primary' : 'btn-outline-secondary'"
                  @click="selectBookingMode('package')"
                  :disabled="pacotesServico.length === 0"
                >
                  <i class="bi bi-calendar-event me-1"></i> Pacote Mensal
                </button>
              </div>
            </section>

            <!-- 1b. Escolha do Serviço (se modo avulso) -->
            <section class="mb-4" v-if="selectedBookingMode === 'service'">
              <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-1">
                2. Escolha o Serviço
              </label>
              <p class="small text-muted mb-2">Selecione o serviço que será realizado no novo horário.</p>
              <div class="services-grid overflow-auto d-flex gap-3 pb-2 custom-scrollbar" style="pointer-events: auto;">
                <div 
                  v-for="service in servicosDisponiveis"
                  :key="service.id"
                  class="service-select-card-mini p-3 shadow-sm flex-shrink-0 transition-all hover-lift"
                  :class="{ 'border-primary': selectedServiceId === service.id }"
                  @click="selectService(service.id)"
                  :style="{'min-width': '160px', 'cursor': 'pointer', 'border-radius': '16px', 'border': selectedServiceId === service.id ? '2px solid var(--bs-primary)' : '1px solid rgba(0,0,0,0.1)', 'background': 'rgba(255,255,255,0.05)'}"
                >
                  <div class="d-flex flex-column align-items-center text-center">
                    <div class="icon-box-mini mb-2 rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px; background: rgba(var(--bs-primary-rgb), 0.1); color: var(--bs-primary);">
                      <i class="bi bi-scissors"></i>
                    </div>
                    <div class="fw-bold small">{{ service.name }}</div>
                    <div class="small opacity-75" style="font-size: 0.7rem;">{{ service.duration_minutes }} min</div>
                  </div>
                </div>
              </div>
            </section>

            <!-- 1c. Escolha do Pacote (se modo pacote) -->
            <section class="mb-4" v-if="selectedBookingMode === 'package'">
              <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-1">
                2. Escolha o Pacote
              </label>
              <p class="small text-muted mb-2">Selecione o pacote mensal para o agendamento.</p>
              <div class="services-grid overflow-auto d-flex gap-3 pb-2 custom-scrollbar" style="pointer-events: auto;">
                <div 
                  v-for="pkg in pacotesServico"
                  :key="pkg.id"
                  class="service-select-card-mini p-3 shadow-sm flex-shrink-0 transition-all hover-lift"
                  :class="{ 'border-primary': selectedPackageId === pkg.id }"
                  @click="selectPackage(pkg)"
                  :style="{'min-width': '180px', 'cursor': 'pointer', 'border-radius': '16px', 'border': selectedPackageId === pkg.id ? '2px solid var(--bs-primary)' : '1px solid rgba(0,0,0,0.1)', 'background': 'rgba(255,255,255,0.05)'}"
                >
                  <div class="d-flex flex-column align-items-center text-center">
                    <div class="icon-box-mini mb-2 rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px; background: rgba(99,102,241,0.1); color: #6366f1;">
                      <i class="bi bi-calendar-event"></i>
                    </div>
                    <div class="fw-bold small">{{ pkg.name }}</div>
                    <div class="small opacity-75" style="font-size: 0.7rem;">{{ pkg.sessions_total }} sessões/mês</div>
                    <div class="small fw-bold" style="color: #6366f1; font-size: 0.75rem;">R$ {{ Number(pkg.price).toFixed(2).replace('.', ',') }}</div>
                  </div>
                </div>
              </div>
            </section>

            <!-- 2. Escolha do Profissional -->
            <section class="mb-4" v-if="selectedServiceId">
              <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-1">
                {{ remanejarAgenda?.servicePackage ? '1.' : '2.' }} Escolha o Profissional
              </label>
              <p class="small text-muted mb-2">Selecione quem irá atender o cliente.</p>
              <div class="colab-container pb-2 custom-scrollbar d-flex gap-3 overflow-auto">
                <div 
                  v-for="emp in colaboradores.filter(c => c.id !== 'all')"
                  :key="emp.id"
                  class="colab-select-card shadow-sm flex-shrink-0"
                  :class="{ active: selectedEmployeeId === emp.id }"
                  @click="selectEmployee(emp.id)"
                >
                  <div class="avatar-placeholder fs-4">
                    <i class="bi bi-person"></i>
                  </div>
                  <span class="fw-bold small mb-1 colab-text text-center" style="line-height: 1.1;">
                    {{ emp.nome }}
                  </span>
                </div>
              </div>
            </section>

            <!-- 3. Dia -->
            <section class="mb-4" v-if="selectedEmployeeId">
              <div class="d-flex justify-content-between align-items-center mb-1">
                <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-0">
                  {{ remanejarAgenda?.servicePackage ? '2.' : '3.' }} Escolha o Dia
                </label>
                <button
                  class="btn btn-sm rounded-pill fw-bold px-3 py-1 custom-outline-btn shadow-sm"
                  @click="goToTodayReschedule"
                >
                  Hoje
                </button>
              </div>
              <div class="d-flex align-items-center gap-2">
                <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollList(dateScrollRef, -1)">
                  <i class="bi bi-chevron-left fs-5"></i>
                </button>
                <div class="date-container pb-2 flex-grow-1" ref="dateScrollRef" style="display: flex; overflow-x: auto; scroll-behavior: smooth;">
                  <div
                    v-for="(date, index) in availableDates"
                    :key="index"
                    class="date-card shadow-sm flex-shrink-0"
                    :class="[
                      { active: selectedDateReschedule === date.apiDate },
                      { 'opacity-50 pointer-events-none': 
                        (remanejarAgenda?.servicePackage && occupiedPackageWeeks.has(getSundayOfDate(date.apiDate)) && selectedDateReschedule !== date.apiDate) ||
                        (remanejarAgenda?.servicePackage && rescheduleBounds.min && date.apiDate <= rescheduleBounds.min) ||
                        (remanejarAgenda?.servicePackage && rescheduleBounds.max && date.apiDate >= rescheduleBounds.max)
                      }
                    ]"
                    @click="selectDateRescheduleFunc(date.apiDate)"
                  >
                    <span class="small dynamic-text date-text opacity-75 mb-1">{{ date.weekDay }}</span>
                    <span class="fw-bold fs-4 dynamic-text date-text lh-1">{{ date.dayNumber }}</span>
                    <span class="small dynamic-text date-text opacity-75 mt-1">{{ date.monthName }}</span>
                  </div>
                  <div v-if="loadingAvailableDays" class="d-flex align-items-center gap-2 p-2">
                    <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
                    <span class="small text-muted fw-bold">Carregando datas...</span>
                  </div>
                </div>
                <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollList(dateScrollRef, 1)">
                  <i class="bi bi-chevron-right fs-5"></i>
                </button>
              </div>
            </section>

            <!-- 4. Hora -->
            <section class="mb-4" v-if="selectedDateReschedule">
              <label class="small fw-bold mb-1 text-uppercase dynamic-text opacity-75">
                {{ remanejarAgenda?.servicePackage ? '3.' : '4.' }} Escolha o Horário
              </label>
              <p class="small text-muted mb-2">Horários livres para o profissional. Cinza = ocupado.</p>
              <div class="hours-grid">
                <div
                  v-for="(time, index) in allTimesForDisplay"
                  :key="index"
                  class="hour-item shadow-sm dynamic-text"
                  :class="{
                    active: selectedTime === time,
                    occupied: occupiedTimes.includes(time),
                    past: isPastTimeForSelectedDate(time)
                  }"
                  @click="canSelectTime(time) && (selectedTime = time)"
                >
                  {{ time }}
                </div>
              </div>
              <div v-if="loadingAvailability" class="d-flex align-items-center gap-2 mt-3">
                <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
                <span class="small text-muted fw-bold">Carregando horários...</span>
              </div>
              <div v-if="!loadingAvailability && selectedDateReschedule && allTimesForDisplay.length === 0" class="small text-danger fw-bold mt-3">
                <i class="bi bi-clock-history me-1"></i>Nenhum horário disponível neste dia.
              </div>
            </section>
          </div>
          
          <div class="modal-footer border-top-0 pb-4 pt-0 flex-column align-items-stretch gap-2">
            <div v-if="modalError" class="alert alert-danger fw-bold border-0" style="background: rgba(220,53,69,0.1); color: #dc3545;">
              <i class="bi bi-exclamation-circle-fill me-2"></i>{{ modalError }}
            </div>
            <div v-if="modalSuccess" class="alert alert-success fw-bold border-0" style="background: rgba(25,135,84,0.1); color: #198754;">
              <i class="bi bi-check-circle-fill me-2"></i>{{ modalSuccess }}
            </div>
            <div class="d-flex gap-2 justify-content-end w-100">
              <button type="button" class="btn custom-outline-btn rounded-pill px-4 fw-bold" data-bs-dismiss="modal">Cancelar</button>
              <button
                type="button"
                class="btn rounded-pill px-4 fw-bold"
                :style="{ background: 'var(--bs-primary)', color: '#fff', border: 'none' }"
                @click="confirmReschedule"
                :disabled="loadingSubmit || !selectedDateReschedule || !selectedTime || !selectedServiceId || !selectedEmployeeId"
              >
                <span v-if="loadingSubmit" class="spinner-border spinner-border-sm me-2"></span>
                Confirmar Novo Horário
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="modal fade" id="modalCheckout" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered">
        <div
          class="modal-content border-0 shadow-lg rounded-4"
          style="background: var(--glass-bg); backdrop-filter: blur(15px);"
          v-if="checkoutAgenda"
        >
          <!-- ── PLANO MENSAL: UI simplificada sem sistema de pagamento ── -->
          <template v-if="checkoutAgenda.servicePackage">
            <div class="modal-header border-bottom border-opacity-10">
              <h5 class="modal-title fw-bold">
                <i class="bi bi-star-fill me-2 text-warning"></i> Confirmar Atendimento — Plano Mensal
              </h5>
              <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" @click="limparModalAberto(); $event.target.blur()" aria-label="Close" id="closeCheckoutBtn"></button>
            </div>

            <div class="modal-body p-4">
              <!-- Badge de sessão do ciclo -->
              <div class="text-center mb-4">
                <div class="d-inline-flex align-items-center gap-3 px-4 py-3 rounded-4 border" style="background: rgba(99,102,241,0.07); border-color: rgba(99,102,241,0.25) !important;">
                  <div>
                    <div class="small text-muted fw-bold mb-1">Progresso do Plano</div>
                    <div class="fs-3 fw-900" style="color: #6366f1;">
                      {{ checkoutAgenda.sessionsUsed }} / {{ checkoutAgenda.sessionsTotal }}
                    </div>
                    <div class="small text-muted">sessões realizadas</div>
                  </div>
                  <i class="bi bi-arrow-right fs-4 text-muted"></i>
                  <div>
                    <div class="small text-muted fw-bold mb-1">Após confirmar</div>
                    <div class="fs-3 fw-900 text-success">
                      {{ checkoutAgenda.sessionsUsed + 1 }} / {{ checkoutAgenda.sessionsTotal }}
                    </div>
                    <div class="small text-muted">sessões realizadas</div>
                  </div>
                </div>
              </div>

              <!-- Resumo do atendimento -->
              <div class="mb-4 bg-body-tertiary p-3 rounded-4 border">
                <div class="d-flex justify-content-between align-items-center mb-2">
                  <span class="small text-muted fw-bold">Cliente</span>
                  <span class="fw-bold">{{ checkoutAgenda.clienteNome }}</span>
                </div>

                <div class="d-flex justify-content-between align-items-center mb-2">
                  <span class="small text-muted fw-bold">Profissional</span>
                  <span class="fw-bold">{{ getColaboradorNome(checkoutAgenda.colabId) }}</span>
                </div>

                <div class="d-flex justify-content-between align-items-center mb-2">
                  <span class="small text-muted fw-bold">Serviço</span>
                  <span class="fw-bold text-body">{{ checkoutAgenda.servico }}</span>
                </div>

                <div class="d-flex justify-content-between align-items-center">
                  <span class="small text-muted fw-bold">Plano</span>
                  <span class="badge rounded-pill fw-bold" style="background: rgba(99,102,241,0.15); color: #6366f1;">
                    <i class="bi bi-star-fill me-1"></i>{{ checkoutAgenda.servicePackage.name }}
                  </span>
                </div>
              </div>

              <!-- Produtos extras (mantido mesmo no plano) -->
              <h6 class="fw-bold mb-2 fs-6">Vendeu produtos extras?</h6>
              <p class="small text-muted mb-3">Adicione produtos vendidos durante o atendimento. O estoque será baixado automaticamente.</p>

              <div class="d-flex gap-2 mb-3">
                <select class="form-select custom-input shadow-sm fw-bold flex-grow-1" v-model="produtoAtualSelecionado">
                  <option value="">Selecione um produto...</option>

                  <optgroup label="Estoque da Loja">
                    <option
                      v-for="prod in produtosLoja"
                      :key="prod.id"
                      :value="prod.id"
                      :disabled="getEstoqueDisponivel(prod) <= 0"
                    >
                      {{ prod.nome || 'Produto sem nome' }} - R$ {{ prod.preco.toFixed(2).replace('.', ',') }} (Est: {{ getEstoqueDisponivel(prod) }})
                    </option>
                  </optgroup>

                  <optgroup
                    v-if="produtosDoProfissional.length > 0"
                    :label="'Estoque de ' + getColaboradorNome(checkoutAgenda.colabId)"
                  >
                    <option
                      v-for="prod in produtosDoProfissional"
                      :key="prod.id"
                      :value="prod.id"
                      :disabled="getEstoqueDisponivel(prod) <= 0"
                    >
                      {{ prod.nome || 'Produto sem nome' }} - R$ {{ prod.preco.toFixed(2).replace('.', ',') }} (Est: {{ getEstoqueDisponivel(prod) }})
                    </option>
                  </optgroup>
                </select>

                <input
                  type="number"
                  class="form-control custom-input shadow-sm fw-bold text-center"
                  style="width: 70px; min-width: 70px;"
                  v-model.number="produtoQuantidade"
                  min="1"
                  placeholder="Qtd"
                >

                <button
                  class="btn btn-primary rounded-3 px-3 shadow-sm transition-all hover-lift"
                  @click="adicionarProdutoAoCheckout"
                  :disabled="!produtoAtualSelecionado || produtoQuantidade < 1"
                >
                  <i class="bi bi-plus-lg"></i>
                </button>
              </div>

              <div v-if="produtosAdicionados.length > 0" class="mb-3">
                <ul class="list-group shadow-sm rounded-3">
                  <li
                    v-for="(item, index) in produtosAdicionados"
                    :key="index"
                    class="list-group-item d-flex justify-content-between align-items-center bg-body-tertiary border-dashed"
                  >
                    <div>
                      <span class="fw-bold small d-block">{{ item.nome }}</span>
                      <span class="text-muted" style="font-size: 0.75rem;">
                        {{ item.qtde }}x R$ {{ item.preco.toFixed(2).replace('.', ',') }}
                      </span>
                    </div>
                    <div class="d-flex align-items-center gap-3">
                      <span class="fw-bold text-body">R$ {{ (item.preco * item.qtde).toFixed(2).replace('.', ',') }}</span>
                      <button class="btn btn-sm text-danger p-0 transition-all hover-lift" @click="removerProdutoDoCheckout(index)" title="Remover item">
                        <i class="bi bi-trash fs-5"></i>
                      </button>
                    </div>
                  </li>
                </ul>
              </div>

              <!-- Forma de pagamento: exigida se houver produtos extras ou se for a primeira sessão do plano -->
              <div v-if="produtosAdicionados.length > 0 || checkoutAgenda.sessionsUsed === 0">
                <h6 class="fw-bold mb-2 fs-6">Forma de Pagamento</h6>
                <p class="small text-muted mb-3">Selecione como o cliente irá pagar. O registro será incluído no financeiro.</p>
                <div class="d-flex flex-wrap gap-2 mb-3">
                  <label class="btn btn-outline-secondary border rounded-pill px-3 py-2 flex-grow-1" :class="{ 'active-payment': metodoPagamento === 'pix' }">
                    <input type="radio" class="d-none" value="pix" v-model="metodoPagamento"> <i class="bi bi-qr-code me-1"></i> PIX
                  </label>
                  <label class="btn btn-outline-secondary border rounded-pill px-3 py-2 flex-grow-1" :class="{ 'active-payment': metodoPagamento === 'cartao' }">
                    <input type="radio" class="d-none" value="cartao" v-model="metodoPagamento"> <i class="bi bi-credit-card me-1"></i> Cartão
                  </label>
                  <label class="btn btn-outline-secondary border rounded-pill px-3 py-2 flex-grow-1" :class="{ 'active-payment': metodoPagamento === 'dinheiro' }">
                    <input type="radio" class="d-none" value="dinheiro" v-model="metodoPagamento"> <i class="bi bi-cash me-1"></i> Dinheiro
                  </label>
                </div>
                <div class="d-flex justify-content-between align-items-center border-top pt-3">
                  <span class="fs-6 fw-bold text-muted">Total a Pagar:</span>
                  <span class="fs-4 fw-900 text-success">R$ {{ calcularTotalCheckout().toFixed(2).replace('.', ',') }}</span>
                </div>
              </div>
            </div>

            <div class="modal-footer border-top border-opacity-10">
              <button
                type="button"
                class="btn btn-success btn-lg rounded-pill fw-bold w-100 shadow-sm transition-all hover-lift"
                @click="confirmarPagamento"
              >
                <i class="bi bi-check2-circle me-2"></i> Confirmar Atendimento
              </button>
            </div>
          </template>

          <!-- ── SERVIÇO AVULSO: UI completa com pagamento ── -->
          <template v-else>
            <div class="modal-header border-bottom border-opacity-10">
              <h5 class="modal-title fw-bold">
                <i class="bi bi-wallet2 me-2 text-success"></i> Finalizar Pagamento
              </h5>
              <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" @click="limparModalAberto(); $event.target.blur()" aria-label="Close" id="closeCheckoutBtn"></button>
            </div>

            <div class="modal-body p-4">
              <div class="mb-4 bg-body-tertiary p-3 rounded-4 border">
                <div class="d-flex justify-content-between align-items-center mb-2">
                  <span class="small text-muted fw-bold">Cliente</span>
                  <span class="fw-bold">{{ checkoutAgenda.clienteNome }}</span>
                </div>

                <div class="d-flex justify-content-between align-items-center mb-2">
                  <span class="small text-muted fw-bold">Profissional</span>
                  <span class="fw-bold">{{ getColaboradorNome(checkoutAgenda.colabId) }}</span>
                </div>

                <template v-if="checkoutAgenda.servicePackage">
                  <div v-if="checkoutAgenda.sessionsUsed === 0" class="d-flex justify-content-between align-items-center mb-2">
                    <span class="small text-muted fw-bold">Pacote ({{ checkoutAgenda.servicePackage.name }})</span>
                    <span class="fw-bold text-body">R$ {{ Number(checkoutAgenda.servicePackage.price || 0).toFixed(2).replace('.', ',') }}</span>
                  </div>
                  <div v-else class="d-flex justify-content-between align-items-center mb-2">
                    <span class="small text-muted fw-bold">Pacote ({{ checkoutAgenda.servicePackage.name }})</span>
                    <span class="fw-bold text-success">Já Pago</span>
                  </div>
                </template>
                <div v-else class="d-flex justify-content-between align-items-center mb-2">
                  <span class="small text-muted fw-bold">Serviço ({{ checkoutAgenda.servico }})</span>
                  <span class="fw-bold text-body">R$ {{ checkoutAgenda.preco.toFixed(2).replace('.', ',') }}</span>
                </div>
              </div>

              <h6 class="fw-bold mb-3 fs-6">Vendeu produtos extras?</h6>

              <div class="d-flex gap-2 mb-3">
                <select class="form-select custom-input shadow-sm fw-bold flex-grow-1" v-model="produtoAtualSelecionado">
                  <option value="">Selecione um produto...</option>

                  <optgroup label="Estoque da Loja">
                    <option
                      v-for="prod in produtosLoja"
                      :key="prod.id"
                      :value="prod.id"
                      :disabled="getEstoqueDisponivel(prod) <= 0"
                    >
                      {{ prod.nome || 'Produto sem nome' }} - R$ {{ prod.preco.toFixed(2).replace('.', ',') }} (Est: {{ getEstoqueDisponivel(prod) }})
                    </option>
                  </optgroup>

                  <optgroup
                    v-if="produtosDoProfissional.length > 0"
                    :label="'Estoque de ' + getColaboradorNome(checkoutAgenda.colabId)"
                  >
                    <option
                      v-for="prod in produtosDoProfissional"
                      :key="prod.id"
                      :value="prod.id"
                      :disabled="getEstoqueDisponivel(prod) <= 0"
                    >
                      {{ prod.nome || 'Produto sem nome' }} - R$ {{ prod.preco.toFixed(2).replace('.', ',') }} (Est: {{ getEstoqueDisponivel(prod) }})
                    </option>
                  </optgroup>
                </select>

                <input
                  type="number"
                  class="form-control custom-input shadow-sm fw-bold text-center"
                  style="width: 70px; min-width: 70px;"
                  v-model.number="produtoQuantidade"
                  min="1"
                  placeholder="Qtd"
                >

                <button
                  class="btn btn-primary rounded-3 px-3 shadow-sm transition-all hover-lift"
                  @click="adicionarProdutoAoCheckout"
                  :disabled="!produtoAtualSelecionado || produtoQuantidade < 1"
                >
                  <i class="bi bi-plus-lg"></i>
                </button>
              </div>

              <div v-if="produtosAdicionados.length > 0" class="mb-4">
                <ul class="list-group shadow-sm rounded-3">
                  <li
                    v-for="(item, index) in produtosAdicionados"
                    :key="index"
                    class="list-group-item d-flex justify-content-between align-items-center bg-body-tertiary border-dashed"
                  >
                    <div>
                      <span class="fw-bold small d-block">{{ item.nome }}</span>
                      <span class="text-muted" style="font-size: 0.75rem;">
                        {{ item.qtde }}x R$ {{ item.preco.toFixed(2).replace('.', ',') }}
                      </span>
                    </div>

                    <div class="d-flex align-items-center gap-3">
                      <span class="fw-bold text-body">R$ {{ (item.preco * item.qtde).toFixed(2).replace('.', ',') }}</span>
                      <button
                        class="btn btn-sm text-danger p-0 transition-all hover-lift"
                        @click="removerProdutoDoCheckout(index)"
                        title="Remover item"
                      >
                        <i class="bi bi-trash fs-5"></i>
                      </button>
                    </div>
                  </li>
                </ul>
              </div>

              <h6 class="fw-bold mb-3 fs-6">Forma de Pagamento</h6>
              <div class="d-flex flex-wrap gap-2 mb-4">
                <label class="btn btn-outline-secondary border rounded-pill px-3 py-2 flex-grow-1" :class="{ 'active-payment': metodoPagamento === 'pix' }">
                  <input type="radio" class="d-none" value="pix" v-model="metodoPagamento"> <i class="bi bi-qr-code me-1"></i> PIX
                </label>
                <label class="btn btn-outline-secondary border rounded-pill px-3 py-2 flex-grow-1" :class="{ 'active-payment': metodoPagamento === 'cartao' }">
                  <input type="radio" class="d-none" value="cartao" v-model="metodoPagamento"> <i class="bi bi-credit-card me-1"></i> Cartão
                </label>
                <label class="btn btn-outline-secondary border rounded-pill px-3 py-2 flex-grow-1" :class="{ 'active-payment': metodoPagamento === 'dinheiro' }">
                  <input type="radio" class="d-none" value="dinheiro" v-model="metodoPagamento"> <i class="bi bi-cash me-1"></i> Dinheiro
                </label>
              </div>

              <div class="d-flex justify-content-between align-items-center border-top pt-4 mt-2">
                <span class="fs-5 fw-bold text-muted">Total a Pagar:</span>
                <span class="fs-2 fw-900 text-success">R$ {{ calcularTotalCheckout().toFixed(2).replace('.', ',') }}</span>
              </div>
            </div>

            <div class="modal-footer border-top border-opacity-10">
              <button
                type="button"
                class="btn btn-success btn-lg rounded-pill fw-bold w-100 shadow-sm transition-all hover-lift"
                @click="confirmarPagamento"
              >
                <i class="bi bi-check2-circle me-2"></i> Confirmar Pagamento
              </button>
            </div>
          </template>
        </div>
      </div>
    </div>

    <div class="modal fade" id="modalNovoEncaixe" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered modal-lg">
        <div
          class="modal-content border-0 shadow-lg rounded-4"
          style="background: var(--glass-bg); backdrop-filter: blur(15px);"
        >
          <div class="modal-header border-bottom border-opacity-10">
            <h5 class="modal-title fw-bold">
              <i class="bi bi-plus-circle me-2 text-primary"></i> Novo Encaixe
            </h5>
            <button
              type="button"
              class="btn-close shadow-none"
              data-bs-dismiss="modal"
              @click="limparModalAberto(); $event.target.blur()"
              aria-label="Close"
              id="closeNovoEncaixeBtn"
            ></button>
          </div>

          <div class="modal-body p-4">
            <div class="row g-3">
              <div class="col-md-12">
                <label class="form-label small fw-bold text-muted">Tipo de Cliente</label>

                <div class="d-flex flex-wrap gap-2">
                  <label
                    class="btn btn-outline-primary rounded-pill px-3 py-2 fw-bold"
                    :class="{ active: novoEncaixeForm.customerMode === 'registered' }"
                  >
                    <input
                      type="radio"
                      class="d-none"
                      value="registered"
                      v-model="novoEncaixeForm.customerMode"
                    >
                    Cliente cadastrado
                  </label>

                  <label
                    class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-bold"
                    :class="{ active: novoEncaixeForm.customerMode === 'walk_in' }"
                  >
                    <input
                      type="radio"
                      class="d-none"
                      value="walk_in"
                      v-model="novoEncaixeForm.customerMode"
                    >
                    Cliente sem cadastro
                  </label>
                </div>
              </div>

              <div class="col-md-6" v-if="novoEncaixeForm.customerMode === 'registered'">
                <label class="form-label small fw-bold text-muted">Cliente cadastrado</label>
                <div class="position-relative">
                  <input type="password" style="position: absolute; width: 0; height: 0; opacity: 0; border: none; padding: 0; margin: 0;" tabindex="-1" autocomplete="new-password">
                  <input
                    ref="clienteSearchInput"
                    type="text"
                    class="form-control custom-input shadow-sm fw-bold"
                    :value="clienteSearchTerm"
                    @input="onClienteSearchInput"
                    @focus="onFocusCliente"
                    @blur="onClienteBlur"
                    placeholder="Pesquisar por e-mail..."
                    autocomplete="off"
                  >
                  <button
                    v-if="clienteSearchTerm"
                    type="button"
                    class="btn btn-sm position-absolute end-0 top-50 translate-middle-y me-2 p-0 border-0 bg-transparent text-muted"
                    @mousedown.prevent="clearClienteSearch"
                    style="z-index: 5;"
                  >
                    <i class="bi bi-x-circle-fill"></i>
                  </button>
                  <div
                    v-if="showClienteDropdown && clientesFiltrados.length > 0"
                    class="position-absolute w-100 shadow-lg border rounded-3 mt-1"
                    style="max-height: 200px; overflow-y: auto; z-index: 1050; background: var(--bs-body-bg);"
                  >
                    <div
                      v-for="cliente in clientesFiltrados"
                      :key="cliente.id"
                      class="px-3 py-2 cursor-pointer border-bottom"
                      :class="{ 'bg-primary bg-opacity-10': novoEncaixeForm.customerId === cliente.id }"
                      style="cursor: pointer; transition: background 0.15s;"
                      @mousedown.prevent="selectCliente(cliente)"
                    >
                      <div class="fw-bold small">{{ cliente.email }}</div>
                      <div class="text-muted" style="font-size: 0.75rem;">{{ cliente.name }}</div>
                    </div>
                  </div>
                  <div
                    v-if="showClienteDropdown && clienteSearchTerm && clientesFiltrados.length === 0"
                    class="position-absolute w-100 shadow-lg border rounded-3 mt-1 p-3 text-center"
                    style="z-index: 1050; background: var(--bs-body-bg);"
                  >
                    <small class="text-muted">Nenhum cliente encontrado</small>
                  </div>
                </div>
                <small class="text-muted" style="font-size: 0.7rem;">
                  {{ novoEncaixeForm.customerId ? 'Selecionado: ' + clienteSearchTerm : 'Digite o email para pesquisar' }}
                </small>
              </div>

              <div class="col-md-6" v-if="novoEncaixeForm.customerMode === 'walk_in'">
                <label class="form-label small fw-bold text-muted">Nome do Cliente</label>
                <input
                  type="text"
                  class="form-control custom-input shadow-sm fw-bold"
                  v-model="novoEncaixeForm.walkInName"
                  placeholder="Digite o nome do cliente"
                  maxlength="100"
                >
                <div class="form-text extra-small text-muted mt-1">Nome completo do cliente avulso (Máx. 100 caracteres).</div>
              </div>

              <div class="col-md-6" v-if="novoEncaixeForm.customerMode === 'walk_in'">
                <label class="form-label small fw-bold text-muted">Email do Cliente <span class="text-danger">*</span></label>
                <div style="position: relative;">
                  <input type="password" style="position: absolute; width: 0; height: 0; opacity: 0; border: none; padding: 0; margin: 0;" tabindex="-1" autocomplete="new-password">
                  <input
                    type="email"
                    class="form-control custom-input shadow-sm fw-bold"
                    v-model="novoEncaixeForm.walkInEmail"
                    placeholder="cliente@email.com"
                    maxlength="150"
                    required
                  >
                </div>
                <div class="form-text extra-small text-muted mt-1">E-mail para envio de convite de cadastro.</div>
              </div>

              <div class="col-md-6">
                <label class="form-label small fw-bold text-muted">Profissional</label>
                <select
                  class="form-select custom-input shadow-sm fw-bold"
                  v-model="novoEncaixeForm.employeeId"
                  @change="handleNovoEncaixeChange"
                >
                  <option value="">Selecione</option>
                  <option
                    v-for="c in colaboradores.filter(c => c.id !== 'all')"
                    :key="c.id"
                    :value="c.id"
                  >
                    {{ c.nome }}
                  </option>
                </select>
                <div class="form-text extra-small text-muted mt-1">Profissional que irá atender o cliente.</div>
              </div>

              <div class="col-md-6">
                <label class="form-label small fw-bold text-muted">Serviço</label>
                <select
                  class="form-select custom-input shadow-sm fw-bold"
                  v-model="novoEncaixeForm.serviceId"
                  @change="handleNovoEncaixeChange"
                >
                  <option value="">Selecione</option>
                  <option
                    v-for="serv in servicosDisponiveis"
                    :key="serv.id"
                    :value="serv.id"
                  >
                    {{ serv.name }} — {{ serv.duration_minutes }} min — R$ {{ Number(serv.price).toFixed(2).replace('.', ',') }}
                  </option>
                </select>
                <div class="form-text extra-small text-muted mt-1">Serviço a ser realizado (duração e preço).</div>
              </div>

              <div class="col-md-6">
                <label class="form-label small fw-bold text-muted">Data</label>
                <input
                  type="date"
                  class="form-control custom-input shadow-sm fw-bold"
                  v-model="novoEncaixeForm.appointmentDate"
                  @change="handleNovoEncaixeChange"
                >
                <div class="form-text extra-small text-muted mt-1">Dia em que o atendimento será realizado.</div>
              </div>

              <div class="col-md-12">
                <label class="form-label small fw-bold text-muted">Horário Disponível</label>
                <div class="form-text extra-small text-muted mb-1">Horários livres para o profissional no dia selecionado. Cinza = ocupado.</div>
                
                <div v-if="!novoEncaixePodeBuscarHorarios" class="alert alert-secondary small border-0 mt-2 py-2">
                  <i class="bi bi-info-circle me-1"></i> Selecione profissional, serviço e data para ver os horários.
                </div>
                
                <div v-else-if="carregandoHorariosNovoEncaixe" class="d-flex align-items-center gap-2 mt-3">
                  <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
                  <span class="small text-muted fw-bold">Carregando horários...</span>
                </div>
                
                <div v-else-if="todosHorariosNovoEncaixeParaDisplay.length === 0" class="small text-danger fw-bold mt-3">
                  <i class="bi bi-clock-history me-1"></i>Nenhum horário disponível neste dia.
                </div>

                <div v-else class="hours-grid mt-2">
                  <div
                    v-for="hora in todosHorariosNovoEncaixeParaDisplay"
                    :key="hora"
                    class="hour-item shadow-sm dynamic-text"
                    :class="{ 
                      active: novoEncaixeForm.startTime === hora,
                      occupied: horariosOcupadosNovoEncaixe.includes(hora),
                      past: isPastTimeNovoEncaixe(hora)
                    }"
                    @click="canSelectTimeNovoEncaixe(hora) && (novoEncaixeForm.startTime = hora)"
                  >
                    {{ hora }}
                  </div>
                </div>
              </div>

              <div class="col-md-12">
                <label class="form-label small fw-bold text-muted">Observações</label>
                <textarea
                  class="form-control custom-input shadow-sm"
                  rows="3"
                  v-model="novoEncaixeForm.notes"
                  placeholder="Ex: Cliente pediu corte específico, alergia a produto..."
                  maxlength="500"
                ></textarea>
                <div class="form-text extra-small text-muted mt-1">Anotações internas sobre o atendimento (visível apenas para a equipe).</div>
              </div>
            </div>
          </div>

          <div class="modal-footer border-top border-opacity-10">
            <button
              type="button"
              class="btn btn-primary btn-lg rounded-pill fw-bold w-100 shadow-sm transition-all hover-lift"
              @click="confirmarNovoEncaixe"
              :disabled="!novoEncaixeValido || criandoNovoEncaixe"
            >
              <i class="bi bi-check2-circle me-2"></i>
              {{ criandoNovoEncaixe ? 'Criando encaixe...' : 'Criar Encaixe' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { api } from '@/services/api'
import { useThemeStore } from '@/stores/themeStore'

const store = useThemeStore()

const selectedDate = ref('')
const selectedColab = ref('all')
const calendarContainer = ref(null)
const holidays = ref({})
const calendarDays = ref([])
const todosAgendamentos = ref([])

const selectedStatus = ref('all')
const statusFilters = [
  { value: 'all', label: 'Todos', icon: 'bi-list-check', color: 'var(--bs-primary)' },
  { value: 'Pendente', label: 'Pendentes', icon: 'bi-clock', color: '#f59e0b' },
  { value: 'Confirmado', label: 'Confirmados', icon: 'bi-check-circle', color: '#3b82f6' },
  { value: 'Concluído', label: 'Concluídos', icon: 'bi-check2-circle', color: '#22c55e' },
  { value: 'Cancelado', label: 'Cancelados', icon: 'bi-x-circle', color: '#ef4444' }
]

const currentUserRole = computed(() => {
  let role = localStorage.getItem('role') || sessionStorage.getItem('role')
  if (!role) {
    const userStr = localStorage.getItem('user') || sessionStorage.getItem('user')
    if (userStr) {
      try { role = JSON.parse(userStr).role } catch { role = '' }
    }
  }
  return role || ''
})

const isOwner = computed(() => currentUserRole.value === 'owner' || currentUserRole.value === 'super_admin')

const currentUserId = computed(() => {
  const userStr = localStorage.getItem('user') || sessionStorage.getItem('user')
  if (userStr) {
    try { return Number(JSON.parse(userStr).id) } catch { return null }
  }
  return null
})

const canManageSchedule = computed(() => {
  if (isOwner.value) return true
  const rawPerms = localStorage.getItem('establishment-permissions') || sessionStorage.getItem('establishment-permissions')
  if (rawPerms) {
    try {
      const perms = JSON.parse(rawPerms)
      return perms?.can_manage_schedule === true
    } catch { return false }
  }
  return false
})

function canManageAppointment(agenda) {
  if (!agenda) return false
  if (isOwner.value || canManageSchedule.value) return true
  if (currentUserId.value && Number(agenda.colabId) === currentUserId.value) return true
  return false
}

const checkoutAgenda = ref(null)
const metodoPagamento = ref('pix')
const produtoAtualSelecionado = ref('')
const produtoQuantidade = ref(1)
const produtosAdicionados = ref([])

const remanejarAgenda = ref(null)
const modalReagendarRef = ref(null)

const selectedServiceId = ref(null)
const selectedBookingMode = ref('service')
const selectedPackageId = ref(null)
const selectedEmployeeId = ref(null)
const selectedDateReschedule = ref('')
const selectedTime = ref('')

const availableDaysFromApi = ref([])
const availableDates = ref([])
const loadingAvailableDays = ref(false)

const availableTimes = ref([])
const occupiedTimes = ref([])
const loadingAvailability = ref(false)

const modalError = ref('')
const modalSuccess = ref('')
const loadingSubmit = ref(false)
const dateScrollRef = ref(null)

const occupiedPackageWeeks = ref(new Set())
const rescheduleBounds = ref({ min: '', max: '' })

const getSundayOfDate = (dateStr) => {
  const d = new Date(dateStr + 'T12:00:00')
  const diff = d.getDate() - d.getDay()
  const sunday = new Date(d.setDate(diff))
  return `${sunday.getFullYear()}-${String(sunday.getMonth() + 1).padStart(2, '0')}-${String(sunday.getDate()).padStart(2, '0')}`
}

const pageThemeVars = computed(() => ({
  '--custom-text-color': store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight,
  '--bs-tertiary-bg': store.isDarkMode ? store.themeConfig.cardDark : store.themeConfig.cardLight,
  '--card-border': store.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'
}))

const allTimesForDisplay = computed(() => {
  const unique = [...new Set([...availableTimes.value, ...occupiedTimes.value])]
  return unique.sort((a, b) => a.localeCompare(b))
})

const getTodayString = () => {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
}

const isPastTimeForSelectedDate = (time) => {
  if (!selectedDateReschedule.value) return false
  if (selectedDateReschedule.value !== getTodayString()) return false
  const now = new Date()
  const current = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
  return time < current
}

const canSelectTime = (time) => {
  return !occupiedTimes.value.includes(time) && !isPastTimeForSelectedDate(time)
}

const scrollList = (elementRef, direction) => {
  if (elementRef) {
    elementRef.scrollBy({ left: direction * 200, behavior: 'smooth' })
  }
}

const buildAvailableDates = () => {
  const result = []
  for (const apiDate of availableDaysFromApi.value) {
    const parts = apiDate.split('-')
    if (parts.length !== 3) continue
    const d = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
    result.push({
      dayNumber: d.getDate(),
      monthName: months[d.getMonth()] || '',
      weekDay: daysWeek[d.getDay()] || '',
      apiDate
    })
  }
  availableDates.value = result
}

const fetchAvailableDaysForReschedule = async () => {
  if (!establishmentSlug.value) return
  loadingAvailableDays.value = true
  try {
    const { data } = await api.get(`/public/establishments/${establishmentSlug.value}/available_days`, {
      params: { service_id: selectedServiceId.value, employee_id: selectedEmployeeId.value, days_ahead: 30 }
    })
    availableDaysFromApi.value = Array.isArray(data.available_days) ? data.available_days.map(i => i.date) : []
    buildAvailableDates()
    
    if (availableDates.value.length > 0) {
      const today = getTodayString()
      const todayExists = availableDates.value.find((d) => d.apiDate === today)
      selectedDateReschedule.value = todayExists ? today : (availableDates.value[0]?.apiDate || '')
      await fetchAvailabilityForReschedule(selectedDateReschedule.value)
    }
  } catch (error) {
    console.error('Erro ao buscar dias', error)
  } finally {
    loadingAvailableDays.value = false
  }
}

const fetchAvailabilityForReschedule = async (date) => {
  if (!establishmentId.value) return
  loadingAvailability.value = true
  try {
    const { data } = await api.get(`/appointments/available_slots`, {
      params: { 
        establishment_id: establishmentId.value,
        service_id: selectedServiceId.value, 
        employee_id: selectedEmployeeId.value, 
        appointment_date: date,
        ignore_appointment_id: remanejarAgenda.value?.id 
      }
    })
    availableTimes.value = Array.isArray(data.slots?.available_slots) ? data.slots.available_slots : []
    occupiedTimes.value = Array.isArray(data.slots?.occupied_slots) ? data.slots.occupied_slots : []
  } catch (error) {
    console.error('Erro ao buscar horários:', error)
  } finally {
    loadingAvailability.value = false
  }
}

const selectService = (id) => {
  selectedServiceId.value = id
  selectedPackageId.value = null
  selectedBookingMode.value = 'service'
  selectedEmployeeId.value = null
  selectedDateReschedule.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
}

const selectBookingMode = (mode) => {
  selectedBookingMode.value = mode
  selectedServiceId.value = null
  selectedPackageId.value = null
  selectedEmployeeId.value = null
  selectedDateReschedule.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
}

const selectPackage = (pkg) => {
  selectedPackageId.value = pkg.id
  selectedServiceId.value = pkg.service_id || null
  selectedBookingMode.value = 'package'
  selectedEmployeeId.value = null
  selectedDateReschedule.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
}

const selectEmployee = async (id) => {
  selectedEmployeeId.value = id
  selectedDateReschedule.value = ''
  selectedTime.value = ''
  await fetchAvailableDaysForReschedule()
}

const selectDateRescheduleFunc = async (date) => {
  if (remanejarAgenda.value?.servicePackage) {
    const sunday = getSundayOfDate(date)
    if (occupiedPackageWeeks.value.has(sunday) && selectedDateReschedule.value !== date) {
      modalError.value = 'O plano mensal permite apenas uma sessão por semana. O cliente já possui uma sessão nesta semana.'
      setTimeout(() => { if(modalError.value.includes('plano mensal')) modalError.value = '' }, 4000)
      return
    }
    if (rescheduleBounds.value.min && date <= rescheduleBounds.value.min) {
      modalError.value = 'Esta sessão não pode ser agendada antes ou no mesmo dia da sessão anterior do plano.'
      setTimeout(() => { if(modalError.value.includes('sessão anterior')) modalError.value = '' }, 4000)
      return
    }
    if (rescheduleBounds.value.max && date >= rescheduleBounds.value.max) {
      modalError.value = 'Esta sessão não pode ser agendada após ou no mesmo dia da próxima sessão do plano.'
      setTimeout(() => { if(modalError.value.includes('próxima sessão')) modalError.value = '' }, 4000)
      return
    }
  }
  selectedDateReschedule.value = date
  selectedTime.value = ''
  await fetchAvailabilityForReschedule(date)
}

const goToTodayReschedule = async () => {
  const today = getTodayString()
  if (availableDates.value.find((d) => d.apiDate === today)) {
    await selectDateRescheduleFunc(today)
    if (dateScrollRef.value) dateScrollRef.value.scrollLeft = 0
  }
}

const carregando = ref(false)
const establishmentId = ref(null)

// ─── Persistência de Modal (mantém modal aberto ao recarregar) ──────────────
const MODAL_STORAGE_KEY = 'appointments_open_modal'

function salvarModalAberto(tipo, agendaId) {
  localStorage.setItem(MODAL_STORAGE_KEY, JSON.stringify({ tipo, agendaId, timestamp: Date.now() }))
}

function limparModalAberto() {
  localStorage.removeItem(MODAL_STORAGE_KEY)
}

function restaurarModalAberto() {
  try {
    const raw = localStorage.getItem(MODAL_STORAGE_KEY)
    if (!raw) return
    const { tipo, agendaId, timestamp } = JSON.parse(raw)
    // Expira após 5 minutos para evitar loops
    if (Date.now() - timestamp > 5 * 60 * 1000) {
      limparModalAberto()
      return
    }

    if (tipo === 'novoEncaixe') {
      // Para novo encaixe, apenas reabre o modal com dados limpos
      novoEncaixe()
      return
    }

    const agenda = todosAgendamentos.value.find(a => a.id === agendaId)
    if (!agenda) {
      limparModalAberto()
      return
    }
    if (tipo === 'checkout') {
      abrirCheckout(agenda)
    } else if (tipo === 'remanejar') {
      abrirRemanejar(agenda)
    }
  } catch {
    limparModalAberto()
  }
}
const establishmentSlug = ref(null)

const diasFechados = ref([])
const folgasExtrasDB = ref([])

const colaboradores = ref([
  { id: 'all', nome: 'Todos', img: null }
])

const produtosEstoque = ref([])
const servicosDisponiveis = ref([])
const pacotesServico = ref([])
const clientesCadastrados = ref([])
const clienteSearchTerm = ref('')
const showClienteDropdown = ref(false)
const clienteSearchInput = ref(null)

const clientesFiltrados = computed(() => {
  const term = clienteSearchTerm.value.toLowerCase().trim()
  if (!term) return []
  return clientesCadastrados.value.filter(c =>
    c.email?.toLowerCase().includes(term) || c.name?.toLowerCase().includes(term)
  ).slice(0, 10)
})

function onClienteSearchInput(e) {
  clienteSearchTerm.value = e.target.value
  showClienteDropdown.value = true
}

function onFocusCliente() {
  if (novoEncaixeForm.value.customerId) {
    novoEncaixeForm.value.customerId = ''
    clienteSearchTerm.value = ''
  }
  showClienteDropdown.value = true
}

function onClienteBlur() {
  setTimeout(() => { showClienteDropdown.value = false }, 150)
}

function selectCliente(cliente) {
  novoEncaixeForm.value.customerId = cliente.id
  clienteSearchTerm.value = cliente.email
  showClienteDropdown.value = false
}

function clearClienteSearch() {
  clienteSearchTerm.value = ''
  novoEncaixeForm.value.customerId = ''
  showClienteDropdown.value = false
}

const novoEncaixeForm = ref({
  customerMode: 'registered',
  customerId: '',
  walkInName: '',
  walkInPhone: '',
  walkInEmail: '',
  employeeId: '',
  serviceId: '',
  appointmentDate: '',
  startTime: '',
  notes: ''
})

const horariosNovoEncaixe = ref([])
const horariosOcupadosNovoEncaixe = ref([])
const carregandoHorariosNovoEncaixe = ref(false)
const criandoNovoEncaixe = ref(false)

const todosHorariosNovoEncaixeParaDisplay = computed(() => {
  const unique = [...new Set([...horariosNovoEncaixe.value, ...horariosOcupadosNovoEncaixe.value])]
  return unique.sort((a, b) => a.localeCompare(b))
})

const isPastTimeNovoEncaixe = (time) => {
  if (!novoEncaixeForm.value.appointmentDate) return false
  if (novoEncaixeForm.value.appointmentDate !== getTodayString()) return false
  const now = new Date()
  const current = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
  return time < current
}

const canSelectTimeNovoEncaixe = (time) => {
  return !horariosOcupadosNovoEncaixe.value.includes(time) && !isPastTimeNovoEncaixe(time)
}

const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
const daysWeek = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']

const STATUS_LABELS = {
  pending: 'Pendente',
  confirmed: 'Confirmado',
  completed: 'Concluído',
  canceled: 'Cancelado'
}

const padDate = (n) => n.toString().padStart(2, '0')
const formatDateString = (dateObj) =>
  `${dateObj.getFullYear()}-${padDate(dateObj.getMonth() + 1)}-${padDate(dateObj.getDate())}`

function formatHora(value) {
  if (!value) return '--:--'

  if (typeof value === 'string') {
    const matchHoraSimples = value.match(/^(\d{2}):(\d{2})/)
    if (matchHoraSimples) return `${matchHoraSimples[1]}:${matchHoraSimples[2]}`

    const matchIso = value.match(/T(\d{2}):(\d{2})/)
    if (matchIso) return `${matchIso[1]}:${matchIso[2]}`
  }

  try {
    const date = new Date(value)
    if (!Number.isNaN(date.getTime())) {
      return date.toLocaleTimeString('pt-BR', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
      })
    }
  } catch {}

  return '--:--'
}

const agendamentosFiltrados = computed(() => {
  return todosAgendamentos.value
    .filter((ag) => {
      const mesmaData = ag.data === selectedDate.value
      const profissionalOk =
        selectedColab.value === 'all' || Number(ag.colabId) === Number(selectedColab.value)
      const statusOk =
        selectedStatus.value === 'all' || ag.status === selectedStatus.value

      return mesmaData && profissionalOk && statusOk
    })
    .sort((a, b) => a.hora.localeCompare(b.hora))
})

const statusCounts = computed(() => {
  const base = todosAgendamentos.value.filter(ag => ag.data === selectedDate.value)
  return {
    all: base.length,
    'Pendente': base.filter(ag => ag.status === 'Pendente').length,
    'Confirmado': base.filter(ag => ag.status === 'Confirmado').length,
    'Concluído': base.filter(ag => ag.status === 'Concluído').length,
    'Cancelado': base.filter(ag => ag.status === 'Cancelado').length
  }
})

const produtosLoja = computed(() => {
  return produtosEstoque.value.filter((p) => p.dono === 'loja')
})

const produtosDoProfissional = computed(() => {
  if (!checkoutAgenda.value) return []
  return produtosEstoque.value.filter(
    (p) => p.dono === 'funcionario' && Number(p.donoId) === Number(checkoutAgenda.value.colabId)
  )
})

const novoEncaixePodeBuscarHorarios = computed(() => {
  return !!(
    novoEncaixeForm.value.employeeId &&
    novoEncaixeForm.value.serviceId &&
    novoEncaixeForm.value.appointmentDate
  )
})

const novoEncaixeValido = computed(() => {
  const clienteValido =
    novoEncaixeForm.value.customerMode === 'registered'
      ? !!novoEncaixeForm.value.customerId
      : !!novoEncaixeForm.value.walkInName && !!novoEncaixeForm.value.walkInEmail

  return !!(
    clienteValido &&
    novoEncaixeForm.value.employeeId &&
    novoEncaixeForm.value.serviceId &&
    novoEncaixeForm.value.appointmentDate &&
    novoEncaixeForm.value.startTime
  )
})

function normalizarAgendamento(item) {
  const employeeId =
    item.employee_id != null
      ? Number(item.employee_id)
      : item.employee?.id != null
        ? Number(item.employee.id)
        : null

  const serviceId =
    item.service_id != null
      ? Number(item.service_id)
      : item.service?.id != null
        ? Number(item.service.id)
        : null

  const preco =
    item.price != null
      ? Number(item.price)
      : item.price_snapshot != null
        ? Number(item.price_snapshot)
        : 0

  return {
    id: Number(item.id),
    data: item.appointment_date,
    hora: formatHora(item.start_time),
    horaFim: formatHora(item.end_time),
    clienteNome:
      item.customer_name ||
      item.customer_name_snapshot ||
      item.customer?.name ||
      'Cliente',
    clienteEmail: item.customer?.email || null,
    servico:
      item.service_name ||
      item.service_name_snapshot ||
      item.service?.name ||
      'Serviço',
    serviceId,
    servicePackage: item.service_package || null,
    // Sessões do plano para exibir progresso no modal de confirmação
    sessionsUsed: item.sessions_used ?? item.service_package_sale?.sessions_used ?? 0,
    sessionsTotal: item.sessions_total ?? item.service_package_sale?.sessions_total ?? item.service_package?.sessions_total ?? 0,
    preco,
    colabId: employeeId,
    funcionarioNome:
      item.employee_name ||
      item.employee_name_snapshot ||
      item.employee?.name ||
      'Profissional',
    status: STATUS_LABELS[item.status] || item.status,
    statusOriginal: item.status,
    cancellationReason: item.cancellation_reason || null
  }
}

function normalizarColaborador(item) {
  return {
    id: Number(
      item.user?.id ??
      item.employee?.id ??
      item.user_id ??
      item.employee_id ??
      item.id ??
      0
    ),
    nome:
      item.user?.name ||
      item.employee?.name ||
      item.name ||
      item.nome ||
      'Profissional',
    img:
      item.user?.image ||
      item.user?.avatar_url ||
      item.employee?.image ||
      item.employee?.avatar_url ||
      item.image ||
      item.avatar_url ||
      null
  }
}

function normalizarProduto(item) {
  const ownerId = item.owner_user_id ?? item.ownerUserId ?? null
  const scope = item.stock_scope ?? item.stockScope ?? 'loja'

  return {
    id: Number(item.id),
    nome: item.name || item.nome || 'Produto sem nome',
    preco: Number(item.sale_price ?? item.preco ?? 0),
    dono: scope === 'funcionario' ? 'funcionario' : 'loja',
    donoId: scope === 'funcionario' && ownerId != null ? Number(ownerId) : null,
    estoque: Number(item.quantity ?? item.estoque ?? 0)
  }
}

function getColaboradorNome(id) {
  return colaboradores.value.find((c) => Number(c.id) === Number(id))?.nome || '---'
}

async function fetchEstablishment() {
  try {
    const { data } = await api.get('/admin/establishment')
    establishmentId.value = data?.id || null
    establishmentSlug.value = data?.slug || null
  } catch (error) {
    console.error('Erro ao buscar estabelecimento:', error)
    establishmentId.value = null
    establishmentSlug.value = null
  }
}

async function fetchColaboradores() {
  try {
    const { data } = await api.get('/admin/team')

    const lista =
      Array.isArray(data) ? data :
      Array.isArray(data?.team) ? data.team :
      Array.isArray(data?.employees) ? data.employees :
      Array.isArray(data?.members) ? data.members :
      Array.isArray(data?.data) ? data.data :
      []

    colaboradores.value = [
      { id: 'all', nome: 'Todos', img: null },
      ...lista.map(normalizarColaborador)
    ]

    if (!isOwner.value) {
      let currentUserId = null
      const userStr = localStorage.getItem('user') || sessionStorage.getItem('user')
      if (userStr) {
        try { currentUserId = JSON.parse(userStr).id } catch { /* noop */ }
      }
      if (currentUserId) {
        const found = lista.find((m) => {
          const normalized = normalizarColaborador(m)
          return Number(normalized.id) === Number(currentUserId)
        })
        if (found) {
          colaboradores.value = [normalizarColaborador(found)]
          selectedColab.value = Number(currentUserId)
        }
      }
    }
  } catch (error) {
    console.error('Erro ao buscar colaboradores:', error)
    colaboradores.value = [{ id: 'all', nome: 'Todos', img: null }]
  }
}

async function fetchClientesCadastrados() {
  try {
    const { data } = await api.get('/admin/customers')
    clientesCadastrados.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Erro ao buscar clientes cadastrados:', error)
    clientesCadastrados.value = []
  }
}

async function fetchProdutos() {
  try {
    const { data } = await api.get('/stock_items')
    const lista = Array.isArray(data) ? data : []
    produtosEstoque.value = lista.map(normalizarProduto)
  } catch (error) {
    console.error('Erro ao buscar estoque:', error)
    produtosEstoque.value = []
  }
}

async function fetchServicos() {
  try {
    const { data } = await api.get('/services')
    servicosDisponiveis.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Erro ao buscar serviços:', error)
    servicosDisponiveis.value = []
  }
}

async function fetchPacotes() {
  try {
    const { data } = await api.get('/service_packages')
    pacotesServico.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Erro ao buscar pacotes:', error)
    pacotesServico.value = []
  }
}

async function fetchAppointments() {
  if (!selectedDate.value || !establishmentId.value) {
    todosAgendamentos.value = []
    return
  }

  carregando.value = true

  try {
    const params = {
      establishment_id: establishmentId.value,
      start_date: selectedDate.value,
      end_date: selectedDate.value
    }

    if (selectedColab.value !== 'all') {
      params.employee_id = Number(selectedColab.value)
    }

    const { data } = await api.get('/appointments', { params })

    const lista =
      Array.isArray(data)
        ? data
        : Array.isArray(data?.appointments)
          ? data.appointments
          : Array.isArray(data?.data)
            ? data.data
            : []

    todosAgendamentos.value = lista.map(normalizarAgendamento)
  } catch (error) {
    console.error('Erro ao buscar agendamentos:', error)
    todosAgendamentos.value = []
  } finally {
    carregando.value = false
  }
}

async function carregarHorariosDisponiveisBase({
  employeeId,
  serviceId,
  appointmentDate,
  ignoreAppointmentId = null
}) {
  const { data } = await api.get('/appointments/available_slots', {
    params: {
      establishment_id: establishmentId.value,
      employee_id: employeeId,
      service_id: serviceId,
      appointment_date: appointmentDate,
      ignore_appointment_id: ignoreAppointmentId
    }
  })

  return data?.slots || []
}

async function abrirRemanejar(agenda) {
  if (!canManageAppointment(agenda)) {
    alert('Acesso negado: Você não pode gerenciar agendamentos de outro profissional.')
    return
  }
  remanejarAgenda.value = { ...agenda }
  salvarModalAberto('remanejar', agenda.id)
  
  selectedServiceId.value = Number(agenda.serviceId)
  selectedEmployeeId.value = Number(agenda.colabId)
  selectedDateReschedule.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
  occupiedTimes.value = []
  occupiedPackageWeeks.value.clear()
  rescheduleBounds.value = { min: '', max: '' }
  modalError.value = ''
  modalSuccess.value = ''
  
  // Define o modo baseado no tipo do agendamento atual
  if (agenda.servicePackage) {
    selectedBookingMode.value = 'package'
    selectedPackageId.value = agenda.servicePackage.id || null
  } else {
    selectedBookingMode.value = 'service'
    selectedPackageId.value = null
  }
  
  if (agenda.servicePackage) {
    try {
      const { data } = await api.get(`/appointments/${agenda.id}/package_occupied_weeks`)
      if (data.occupied_weeks) {
        data.occupied_weeks.forEach(w => {
          occupiedPackageWeeks.value.add(w)
        })
      }
      if (data.min_date || data.max_date) {
        rescheduleBounds.value = {
          min: data.min_date || '',
          max: data.max_date || ''
        }
      }
    } catch (error) {
      console.error('Erro ao buscar semanas ocupadas', error)
    }
  }

  await fetchAvailableDaysForReschedule()
}

async function confirmReschedule() {
  if (remanejarAgenda.value && !canManageAppointment(remanejarAgenda.value)) {
    modalError.value = 'Acesso negado: Você não pode gerenciar agendamentos de outro profissional.'
    return
  }

  if (!canManageSchedule.value && Number(selectedEmployeeId.value) !== currentUserId.value) {
    modalError.value = 'Acesso negado: Você não tem permissão para transferir agendamentos para outro profissional.'
    return
  }

  if (!selectedDateReschedule.value || !selectedTime.value || !selectedServiceId.value || !selectedEmployeeId.value) {
    modalError.value = 'Por favor, selecione o serviço/pacote, profissional, data e horário.'
    return
  }

  loadingSubmit.value = true
  modalError.value = ''
  modalSuccess.value = ''

  try {
    const payload = {
      appointment_date: selectedDateReschedule.value,
      start_time: selectedTime.value,
      service_id: selectedServiceId.value,
      employee_id: selectedEmployeeId.value
    }

    // Se selecionou um pacote, envia o service_package_id
    if (selectedBookingMode.value === 'package' && selectedPackageId.value) {
      payload.service_package_id = selectedPackageId.value
    }

    await api.patch(`/appointments/${remanejarAgenda.value.id}/reschedule`, payload)

    modalSuccess.value = 'Reagendamento realizado com sucesso!'
    
    setTimeout(() => {
      document.getElementById('closeRemanejarBtn')?.click()
      fetchAppointments()
    }, 1500)
  } catch (error) {
    console.error('Erro ao reagendar:', error)
    modalError.value = error.response?.data?.error || 'Erro ao reagendar. Tente novamente.'
  } finally {
    loadingSubmit.value = false
  }
}

function abrirCheckout(agenda) {
  if (!canManageAppointment(agenda)) {
    alert('Acesso negado: Você não pode gerenciar agendamentos de outro profissional.')
    return
  }

  checkoutAgenda.value = {
    ...agenda,
    colabId: Number(agenda.colabId),
    // Sessões do plano: carregadas do agendamento para exibir o progresso no modal
    sessionsUsed: agenda.servicePackage ? (agenda.sessionsUsed ?? 0) : 0,
    sessionsTotal: agenda.servicePackage ? (agenda.sessionsTotal ?? agenda.servicePackage?.sessions_total ?? 4) : 0
  }
  produtoAtualSelecionado.value = ''
  produtosAdicionados.value = []
  metodoPagamento.value = 'pix'
  salvarModalAberto('checkout', agenda.id)
}

function getEstoqueDisponivel(prod) {
  const naLista = produtosAdicionados.value.find(
    (p) => Number(p.id) === Number(prod.id)
  )
  const qtdeNaLista = naLista ? naLista.qtde : 0
  return Number(prod.estoque) - Number(qtdeNaLista)
}

function adicionarProdutoAoCheckout() {
  if (!produtoAtualSelecionado.value) return

  const produtoId = Number(produtoAtualSelecionado.value)
  const quantidade = Math.max(1, Number(produtoQuantidade.value) || 1)

  const prodReal = produtosEstoque.value.find((p) => Number(p.id) === produtoId)
  if (!prodReal) return

  const estoqueDisp = getEstoqueDisponivel(prodReal)
  if (estoqueDisp > 0) {
    const itemJaAdicionado = produtosAdicionados.value.find(
      (p) => Number(p.id) === produtoId
    )

    if (itemJaAdicionado) {
      const novaQtde = Math.min(itemJaAdicionado.qtde + quantidade, estoqueDisp)
      itemJaAdicionado.qtde = novaQtde
    } else {
      produtosAdicionados.value.push({
        ...prodReal,
        id: produtoId,
        qtde: Math.min(quantidade, estoqueDisp)
      })
    }
  }

  produtoAtualSelecionado.value = ''
  produtoQuantidade.value = 1
}

function removerProdutoDoCheckout(index) {
  produtosAdicionados.value.splice(index, 1)
}

function calcularTotalCheckout() {
  if (!checkoutAgenda.value) return 0

  let total = 0

  if (checkoutAgenda.value.servicePackage) {
    if (checkoutAgenda.value.sessionsUsed === 0) {
      total = Number(checkoutAgenda.value.servicePackage.price || 0)
    } else {
      total = 0
    }
  } else {
    total = Number(checkoutAgenda.value.preco || 0)
  }

  for (const item of produtosAdicionados.value) {
    total += Number(item.preco) * Number(item.qtde)
  }

  return total
}

// Calcula apenas o valor dos produtos extras (para planos mensais)
function calcularTotalProdutos() {
  let total = 0
  for (const item of produtosAdicionados.value) {
    total += Number(item.preco) * Number(item.qtde)
  }
  return total
}

function montarPayloadCheckout() {
  if (!checkoutAgenda.value) return null

  const produtos = produtosAdicionados.value.map((item) => ({
    stock_item_id: Number(item.id),
    name: item.nome,
    unit_price: Number(item.preco),
    quantity: Number(item.qtde),
    total_price: Number(item.preco) * Number(item.qtde),
    owner_type: item.dono,
    owner_user_id: item.donoId ? Number(item.donoId) : null
  }))

  const serviceAmount = Number(checkoutAgenda.value.preco || 0)
  const productsAmount = produtos.reduce((acc, item) => acc + Number(item.total_price), 0)
  const totalAmount = serviceAmount + productsAmount

  return {
    employee_id: Number(checkoutAgenda.value.colabId),
    payment_method: metodoPagamento.value,
    service_amount: serviceAmount,
    products_amount: productsAmount,
    total_amount: totalAmount,
    products: produtos,
    notes: 'Checkout realizado pelo painel administrativo'
  }
}

async function confirmarPagamento() {
  if (!checkoutAgenda.value) return

  const payload = montarPayloadCheckout()

  if (!payload) {
    alert('Não foi possível montar os dados do checkout.')
    return
  }

  try {
    await api.patch(`/appointments/${checkoutAgenda.value.id}/complete`, payload)

    document.getElementById('closeCheckoutBtn')?.click()
    checkoutAgenda.value = null
    produtoAtualSelecionado.value = ''
    produtosAdicionados.value = []
    metodoPagamento.value = 'pix'

    await fetchAppointments()
    alert('Pagamento/atendimento concluído com sucesso!')
  } catch (error) {
    console.error('Erro ao concluir atendimento:', error)
    alert(error?.response?.data?.error || 'Não foi possível concluir o atendimento.')
  }
}

async function fetchHolidays() {
  try {
    const year = new Date().getFullYear()
    const safeYear = parseInt(year, 10)
    if (isNaN(safeYear) || safeYear < 2000 || safeYear > 2100) return

    const response = await fetch(`https://brasilapi.com.br/api/feriados/v1/${safeYear}`, { credentials: 'omit' })
    if (!response.ok) return
    const data = await response.json()
    const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/

    if (Array.isArray(data)) {
      const newHolidays = {}
      data.forEach((f) => {
        const date = typeof f?.date === 'string' ? f.date.trim() : ''
        const name = typeof f?.name === 'string' ? f.name.replace(/<[^>]*>/g, '').trim().slice(0, 100) : ''
        if (DATE_REGEX.test(date) && name) {
          newHolidays[date] = name
        }
      })
      holidays.value = newHolidays
    }
  } catch (error) {
    console.error('Erro feriados:', error)
  }
}

function generateCalendar() {
  const days = []
  let firstValidFound = false

  for (let i = 0; i < 30; i++) {
    const d = new Date()
    d.setDate(d.getDate() + i)

    const dateStr = formatDateString(d)
    const holidayName = holidays.value[dateStr] || null
    const isFolgaExtra = folgasExtrasDB.value.includes(dateStr)
    const isBlocked = Boolean(isFolgaExtra)

    if (!isBlocked && !firstValidFound) {
      if (!selectedDate.value) selectedDate.value = dateStr
      firstValidFound = true
    }

    days.push({
      dateStr,
      dayNum: d.getDate(),
      weekDay: daysWeek[d.getDay()],
      monthName: months[d.getMonth()],
      isBlocked,
      holidayName,
      isFolgaExtra
    })
  }

  calendarDays.value = days
}

async function selectDate(day) {
  if (day.isBlocked) return

  selectedDate.value = day.dateStr
  await fetchAppointments()
}

async function selectColaborador(id) {
  selectedColab.value = id === 'all' ? 'all' : Number(id)
  await fetchAppointments()
}

function selectStatusFilter(status) {
  selectedStatus.value = status
}

function scrollCalendar(direction) {
  if (calendarContainer.value) {
    calendarContainer.value.scrollBy({
      left: direction * 300,
      behavior: 'smooth'
    })
  }
}

async function goToToday() {
  const hoje = formatDateString(new Date())
  selectedDate.value = hoje

  if (calendarContainer.value) {
    calendarContainer.value.scrollTo({
      left: 0,
      behavior: 'smooth'
    })
  }

  await fetchAppointments()
}

function novoEncaixe() {
  novoEncaixeForm.value = {
    customerMode: 'registered',
    customerId: '',
    walkInName: '',
    walkInPhone: '',
    walkInEmail: '',
    employeeId: selectedColab.value !== 'all' ? Number(selectedColab.value) : '',
    serviceId: '',
    appointmentDate: selectedDate.value || formatDateString(new Date()),
    startTime: '',
    notes: ''
  }
  clienteSearchTerm.value = ''
  showClienteDropdown.value = false
  horariosNovoEncaixe.value = []
  salvarModalAberto('novoEncaixe', selectedDate.value || formatDateString(new Date()))
}

async function handleNovoEncaixeChange() {
  novoEncaixeForm.value.startTime = ''
  horariosNovoEncaixe.value = []

  if (!novoEncaixePodeBuscarHorarios.value) return

  await carregarHorariosNovoEncaixe()
}

async function carregarHorariosNovoEncaixe() {
  if (!novoEncaixePodeBuscarHorarios.value) {
    horariosNovoEncaixe.value = []
    return
  }

  carregandoHorariosNovoEncaixe.value = true

  try {
    const res = await carregarHorariosDisponiveisBase({
      employeeId: Number(novoEncaixeForm.value.employeeId),
      serviceId: Number(novoEncaixeForm.value.serviceId),
      appointmentDate: novoEncaixeForm.value.appointmentDate
    })
    horariosNovoEncaixe.value = Array.isArray(res?.available_slots) ? res.available_slots : []
    horariosOcupadosNovoEncaixe.value = Array.isArray(res?.occupied_slots) ? res.occupied_slots : []
  } catch (error) {
    console.error('Erro ao carregar horários do novo encaixe:', error)
    horariosNovoEncaixe.value = []
    horariosOcupadosNovoEncaixe.value = []
  } finally {
    carregandoHorariosNovoEncaixe.value = false
  }
}

function sanitizeText(text) {
  if (typeof text !== 'string') return ''
  return text
    .replace(/<[^>]*>/g, '') // Remove HTML tags
    .replace(/[&<>"']/g, (m) => {
      const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#x27;'
      }
      return map[m]
    })
    .trim()
}

async function confirmarNovoEncaixe() {
  if (!novoEncaixeValido.value) {
    alert('Preencha os campos obrigatórios.')
    return
  }

  criandoNovoEncaixe.value = true

  try {
    const payload = {
      establishment_id: establishmentId.value,
      employee_id: Number(novoEncaixeForm.value.employeeId),
      service_id: Number(novoEncaixeForm.value.serviceId),
      appointment_date: novoEncaixeForm.value.appointmentDate,
      start_time: novoEncaixeForm.value.startTime,
      notes: sanitizeText(novoEncaixeForm.value.notes),
      status: 'confirmed',
      customer_mode: novoEncaixeForm.value.customerMode
    }

    if (novoEncaixeForm.value.customerMode === 'registered') {
      payload.customer_id = Number(novoEncaixeForm.value.customerId)
    } else {
      payload.walk_in_name = sanitizeText(novoEncaixeForm.value.walkInName)
      payload.walk_in_email = sanitizeText(novoEncaixeForm.value.walkInEmail)
    }

    await api.post('/appointments', payload)

    document.getElementById('closeNovoEncaixeBtn')?.click()
    limparModalAberto()

    novoEncaixeForm.value = {
      customerMode: 'registered',
      customerId: '',
      walkInName: '',
      walkInPhone: '',
      walkInEmail: '',
      employeeId: '',
      serviceId: '',
      appointmentDate: '',
      startTime: '',
      notes: ''
    }

    horariosNovoEncaixe.value = []

    await fetchClientesCadastrados()
    await fetchAppointments()

    alert('Novo encaixe criado com sucesso!')
  } catch (error) {
    console.error('Erro ao criar novo encaixe:', error)
    alert(error?.response?.data?.error || 'Não foi possível criar o encaixe.')
  } finally {
    criandoNovoEncaixe.value = false
  }
}

async function cancelarAgendamento(id) {
  const agenda = todosAgendamentos.value.find(a => Number(a.id) === Number(id))
  if (agenda && !canManageAppointment(agenda)) {
    alert('Acesso negado: Você não pode cancelar agendamentos de outro profissional.')
    return
  }

  if (!confirm('Deseja realmente cancelar este agendamento?')) return

  try {
    await api.patch(`/appointments/${id}/cancel`)
    await fetchAppointments()
    alert('Agendamento cancelado com sucesso!')
  } catch (error) {
    console.error('Erro ao cancelar agendamento:', error)
    alert(error?.response?.data?.error || 'Não foi possível cancelar o agendamento.')
  }
}

function formatDateDisplay(dateString) {
  if (!dateString) return ''
  const [y, m, d] = dateString.split('-')
  return `${d}/${m}/${y}`
}

function getStatusBorderColor(s) {
  if (s === 'Pendente') return { 'border-left-color': '#f59e0b' }
  if (s === 'Confirmado') return { 'border-left-color': '#3b82f6' }
  if (s === 'Concluído') return { 'border-left-color': '#22c55e' }
  return { 'border-left-color': '#ef4444' }
}

function getStatusTextColor(s) {
  if (s === 'Pendente') return { color: '#f59e0b' }
  if (s === 'Confirmado') return { color: '#3b82f6' }
  if (s === 'Concluído') return { color: '#22c55e' }
  return { color: '#ef4444' }
}

function getTimelineDotColor(s) {
  if (s === 'Pendente') return { background: '#f59e0b' }
  if (s === 'Confirmado') return { background: '#3b82f6' }
  if (s === 'Concluído') return { background: '#22c55e' }
  return { background: '#ef4444' }
}

function getStatusBadgeStyle(s) {
  if (s === 'Pendente') return { background: 'rgba(245,158,11,0.12)', color: '#f59e0b', borderColor: 'rgba(245,158,11,0.3)' }
  if (s === 'Confirmado') return { background: 'rgba(59,130,246,0.12)', color: '#3b82f6', borderColor: 'rgba(59,130,246,0.3)' }
  if (s === 'Concluído') return { background: 'rgba(34,197,94,0.12)', color: '#22c55e', borderColor: 'rgba(34,197,94,0.3)' }
  return { background: 'rgba(239,68,68,0.12)', color: '#ef4444', borderColor: 'rgba(239,68,68,0.3)' }
}

watch([selectedDate, establishmentId], async ([novaData, novoEstablishmentId]) => {
  if (novaData && novoEstablishmentId) {
    await fetchAppointments()
  }
})

let refreshInterval = null

onMounted(async () => {
  await fetchHolidays()
  await fetchEstablishment()
  await fetchColaboradores()
  await fetchProdutos()
  await fetchServicos()
  await fetchPacotes()
  await fetchClientesCadastrados()

  generateCalendar()

  if (!selectedDate.value) {
    selectedDate.value = formatDateString(new Date())
  }

  await fetchAppointments()

  // Restaura modal aberto antes do refresh
  restaurarModalAberto()

  refreshInterval = setInterval(() => {
    if (selectedDate.value && establishmentId.value) {
      fetchAppointments()
    }
  }, 300000)

  // Fecha dropdown de clientes ao clicar fora
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.position-relative')) {
      showClienteDropdown.value = false
    }
  })
})

onUnmounted(() => {
  if (refreshInterval) clearInterval(refreshInterval)
})
</script>

<style scoped>
.cursor-pointer {
  cursor: pointer;
}

/* Ajuste de Layout Tela Cheia */
.page-content {
  max-width: 100% !important;
}

/* ══════════════════════════════════════════════════════════════
   SECTION HEADERS
   ══════════════════════════════════════════════════════════════ */
.section-header-left {
  display: flex;
  align-items: center;
  gap: 0.875rem;
}

.section-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.15rem;
  flex-shrink: 0;
}

.section-title {
  font-size: 1rem;
  font-weight: 700;
  letter-spacing: -0.01em;
}

.section-subtitle {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--bs-secondary);
}

/* ══════════════════════════════════════════════════════════════
   DASHBOARD HEADER
   ══════════════════════════════════════════════════════════════ */
.dashboard-header {
  background: rgba(var(--bs-body-bg-rgb), 0.4) !important;
  border: 1px solid var(--card-border) !important;
  backdrop-filter: blur(12px) !important;
  position: relative;
  border-radius: 20px !important;
}

.header-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at top right, rgba(13, 110, 253, 0.08), transparent 70%);
  pointer-events: none;
}

.header-icon-container {
  width: 54px;
  height: 54px;
  border-color: var(--card-border) !important;
  flex-shrink: 0;
}

.text-gradient {
  background: linear-gradient(135deg, var(--logo-color, var(--bs-primary)), #00c6ff);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  font-weight: 800;
}

/* ══════════════════════════════════════════════════════════════
   ADMIN CARD
   ══════════════════════════════════════════════════════════════ */
.admin-card {
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  border-radius: 18px;
  padding: 1.25rem 1.5rem;
  box-shadow: 0 2px 12px var(--card-shadow);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 1.1rem;
  flex-wrap: wrap;
}

/* ══════════════════════════════════════════════════════════════
   DATE CONTAINER & CARDS
   ══════════════════════════════════════════════════════════════ */
.date-container {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding: 8px 4px;
  scrollbar-width: none;
  scroll-behavior: smooth;
}

.date-container::-webkit-scrollbar {
  display: none;
}

.date-card {
  flex: 0 0 92px;
  width: 92px;
  height: 96px;
  border-radius: 16px;
  border: 1px solid var(--card-border);
  background: var(--bs-body-bg);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  position: relative;
  transition: all 0.2s ease;
}

.date-container::after {
  content: '';
  flex: 0 0 6px;
}

.date-card:not(.disabled-day):hover {
  transform: translateY(-3px);
  border-color: rgba(13, 110, 253, 0.35);
  background: rgba(var(--bs-body-color-rgb), 0.06);
  color: var(--bs-body-color) !important;
}

.date-card:not(.disabled-day):hover .small,
.date-card:not(.disabled-day):hover .fw-bold,
.date-card:not(.disabled-day):hover span {
  color: var(--bs-body-color) !important;
}

.date-card.active {
  background: var(--bs-primary);
  color: white;
  border-color: var(--bs-primary);
  box-shadow: 0 6px 14px rgba(13, 110, 253, 0.25) !important;
  transform: translateY(-3px) scale(1.02);
}

.date-card.active .text-danger {
  color: white !important;
}

.date-card.disabled-day {
  opacity: 0.42;
  cursor: not-allowed;
  border-style: dashed;
}

/* ══════════════════════════════════════════════════════════════
   SCROLL ARROWS
   ══════════════════════════════════════════════════════════════ */
.btn-scroll {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--bs-body-color);
  flex-shrink: 0;
  transition: all 0.2s ease;
}

.btn-scroll:hover {
  background: var(--bs-primary);
  color: #fff;
  border-color: var(--bs-primary);
}

/* ══════════════════════════════════════════════════════════════
   TODAY BUTTON
   ══════════════════════════════════════════════════════════════ */
.btn-today {
  background: transparent;
  color: var(--bs-primary);
  border: 1.5px solid var(--bs-primary);
  transition: all 0.2s ease;
}

.btn-today:hover {
  background: var(--bs-primary);
  color: #fff;
}

/* ══════════════════════════════════════════════════════════════
   COLLAB FILTER BUTTONS
   ══════════════════════════════════════════════════════════════ */
.colab-filter-btn {
  white-space: nowrap;
  border: 1px solid var(--card-border);
  background: var(--bs-body-bg);
  color: var(--bs-body-color);
  min-height: 44px;
  font-size: 0.83rem;
}

.colab-filter-btn:hover {
  border-color: rgba(13, 110, 253, 0.35);
  transform: translateY(-2px);
}

.colab-filter-btn.active {
  background: var(--bs-primary);
  color: white;
  border-color: var(--bs-primary);
  box-shadow: 0 6px 14px rgba(13, 110, 253, 0.25) !important;
}

/* ══════════════════════════════════════════════════════════════
   APPOINTMENTS TOPBAR
   ══════════════════════════════════════════════════════════════ */
.appointments-topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  margin-bottom: 1.25rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--card-border);
  flex-wrap: wrap;
}

.date-highlight {
  font-size: 0.8rem;
  font-weight: 700;
  color: var(--bs-primary);
  background: rgba(13, 110, 253, 0.08);
  border: 1px solid rgba(13, 110, 253, 0.15);
  padding: 0.3rem 0.7rem;
  border-radius: 999px;
}

.custom-counter-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 40px;
  padding: 0.5rem 0.9rem;
  border-radius: 999px;
  background: rgba(13, 110, 253, 0.12);
  color: var(--bs-primary);
  border: 1px solid rgba(13, 110, 253, 0.2);
  font-weight: 700;
  font-size: 0.83rem;
}

/* ══════════════════════════════════════════════════════════════
   INFO PILLS
   ══════════════════════════════════════════════════════════════ */
.info-pill {
  display: inline-flex;
  align-items: center;
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  padding: 0.35rem 0.7rem;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 600;
  color: var(--bs-body-color);
  transition: all 0.2s ease;
}

.info-pill:hover {
  background: rgba(var(--bs-body-color-rgb), 0.07);
  transform: translateY(-1px);
}

/* ══════════════════════════════════════════════════════════════
   EMPTY STATE
   ══════════════════════════════════════════════════════════════ */
.empty-state {
  text-align: center;
  padding: 2.5rem 1rem;
  background: var(--bs-tertiary-bg);
  border-radius: 18px;
  border: 2px dashed var(--card-border);
  margin-top: 0.5rem;
}

.empty-state-icon {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: rgba(108, 117, 125, 0.08);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
  font-size: 1.5rem;
  color: var(--bs-secondary);
  opacity: 0.7;
}

/* ══════════════════════════════════════════════════════════════
   CUSTOM INPUT
   ══════════════════════════════════════════════════════════════ */
.custom-input {
  border-radius: 12px;
  padding: 0.6rem 0.9rem;
  border: 1px solid var(--card-border);
  background-color: var(--bs-body-bg);
  color: var(--bs-body-color);
  transition: all 0.2s;
}

.custom-input:focus {
  border-color: var(--bs-primary) !important;
  box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.12) !important;
}

.active-payment {
  background-color: var(--bs-primary) !important;
  color: white !important;
  border-color: var(--bs-primary) !important;
}

.hide-scrollbar {
  scrollbar-width: none;
}

.hide-scrollbar::-webkit-scrollbar {
  display: none;
}

.border-dashed {
  border-style: dashed !important;
  border-width: 2px !important;
  border-color: var(--card-border) !important;
}

.transition-all {
  transition: all 0.2s ease;
}

.hover-lift:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0,0,0,0.08) !important;
}

/* ══════════════════════════════════════════════════════════════
   STATUS FILTER BAR
   ══════════════════════════════════════════════════════════════ */
.status-filter-bar {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 0;
  margin-bottom: 1rem;
  border-bottom: 1px solid var(--card-border);
  overflow-x: auto;
  scrollbar-width: none;
}

.status-filter-bar::-webkit-scrollbar {
  display: none;
}

.status-filter-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.4rem 0.75rem;
  border-radius: 999px;
  border: 1px solid;
  background: transparent;
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.status-filter-btn:hover {
  transform: translateY(-1px);
}

.status-filter-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  height: 18px;
  padding: 0 0.3rem;
  border-radius: 999px;
  font-size: 0.68rem;
  font-weight: 700;
  line-height: 1;
}

/* ══════════════════════════════════════════════════════════════
   TIMELINE
   ══════════════════════════════════════════════════════════════ */
.agenda-timeline {
  display: flex;
  flex-direction: column;
  gap: 0.875rem;
}

.agenda-row {
  display: grid;
  grid-template-columns: 82px 24px minmax(0, 1fr);
  gap: 0.875rem;
  align-items: center;
}

.agenda-time {
  display: flex;
  justify-content: flex-end;
  align-items: center;
}

.agenda-time-text {
  font-weight: 800;
  font-size: 0.95rem;
  line-height: 1;
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 0.7rem 0.8rem;
  min-width: 78px;
  text-align: center;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.02);
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.agenda-line-col {
  position: relative;
  display: flex;
  align-items: stretch;
  justify-content: center;
  min-height: 100%;
}

.agenda-line {
  width: 2px;
  background: var(--card-border);
  height: 100%;
}

.agenda-dot {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 12px;
  height: 12px;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  border: 2.5px solid var(--bs-body-bg);
  z-index: 2;
  box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.04);
}

.dot-primary { background: var(--bs-primary); }
.dot-success { background: var(--bs-success); }
.dot-warning { background: var(--bs-warning); }
.dot-secondary { background: var(--bs-secondary); }
.dot-danger { background: var(--bs-danger); }

/* ══════════════════════════════════════════════════════════════
   AGENDA CARD
   ══════════════════════════════════════════════════════════════ */
.agenda-card {
  border: 1px solid var(--card-border);
  border-left-width: 4px !important;
  border-radius: 16px;
  padding: 1rem 1.15rem;
  background: var(--bs-body-bg);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.02);
  transition: all 0.2s ease;
  width: 100%;
  min-height: 76px;
}

.agenda-card:hover {
  transform: translateY(-2px);
  background: rgba(var(--bs-body-color-rgb), 0.025);
  box-shadow: 0 6px 18px var(--card-shadow) !important;
}

.agenda-card-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.875rem;
  flex-wrap: nowrap;
}

.agenda-main {
  flex: 1 1 auto;
  min-width: 0;
}

.agenda-main-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.agenda-title-wrap {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  flex-wrap: wrap;
}

.agenda-title-wrap h5 {
  font-size: 0.95rem;
  font-weight: 700;
}

.agenda-status-badge {
  padding: 0.35rem 0.75rem;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.02em;
}

.agenda-actions-inline {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 0.4rem;
  flex-wrap: wrap;
  flex: 0 0 auto;
}

.agenda-actions-inline .btn {
  font-size: 0.78rem;
  padding: 0.4rem 0.75rem;
}

@media (max-width: 992px) {
  .agenda-card-content {
    flex-direction: column;
    align-items: flex-start;
  }

  .agenda-actions-inline {
    width: 100%;
    justify-content: flex-start;
    margin-top: 0.6rem;
    padding-top: 0.6rem;
    border-top: 1px solid var(--card-border);
  }
}

@media (max-width: 768px) {
  .admin-card {
    padding: 1rem;
  }

  .date-card {
    min-width: 82px;
    height: 88px;
  }

  .agenda-row {
    grid-template-columns: 1fr;
    gap: 0.6rem;
  }

  .agenda-time {
    justify-content: flex-start;
    padding-top: 0;
  }

  .agenda-line-col {
    display: none;
  }

  .agenda-main-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .agenda-title-wrap {
    align-items: flex-start;
    flex-direction: column;
    gap: 0.4rem;
  }
}

/* ══════════════════════════════════════════════════════════════
   MODAL: REAGENDAMENTO
   ══════════════════════════════════════════════════════════════ */
#modalRemanejar .colab-select-card, #modalRemanejar .date-card {
  flex-shrink: 0;
  width: 100px;
  height: 120px;
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: center;
  padding: 0.5rem;
}

#modalRemanejar .date-card {
  width: 85px;
  height: 105px;
}

#modalRemanejar .colab-select-card.active, #modalRemanejar .date-card.active {
  border-color: var(--bs-primary);
  background: var(--bs-primary);
  box-shadow: 0 8px 16px rgba(0,0,0,0.1);
}

#modalRemanejar .colab-select-card.active .colab-text, #modalRemanejar .colab-select-card.active .avatar-placeholder,
#modalRemanejar .date-card.active .date-text {
  color: #fff !important;
}

#modalRemanejar .avatar-placeholder {
  width: 45px;
  height: 45px;
  border-radius: 50%;
  background: rgba(100, 100, 100, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 8px;
  color: var(--custom-text-color);
}

#modalRemanejar .hours-grid, #modalNovoEncaixe .hours-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(85px, 1fr));
  gap: 0.6rem;
}

#modalRemanejar .hour-item, #modalNovoEncaixe .hour-item {
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  border-radius: 10px;
  padding: 0.55rem 0;
  text-align: center;
  font-weight: 600;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.2s;
}

#modalRemanejar .hour-item.active, #modalNovoEncaixe .hour-item.active {
  background: var(--bs-primary);
  color: #fff !important;
  border-color: var(--bs-primary);
  box-shadow: 0 4px 10px rgba(0,0,0,0.1);
}

#modalRemanejar .hour-item.occupied, #modalNovoEncaixe .hour-item.occupied {
  opacity: 0.4;
  cursor: not-allowed;
  background: rgba(0,0,0,0.05);
}

#modalRemanejar .scroll-arrow {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  padding: 0;
}

#modalRemanejar .scroll-arrow:hover {
  background: var(--bs-tertiary-bg);
}

#modalRemanejar .custom-outline-btn {
  color: var(--bs-primary) !important;
  border-color: var(--bs-primary) !important;
  background: transparent !important;
  transition: all 0.3s ease;
}
</style>