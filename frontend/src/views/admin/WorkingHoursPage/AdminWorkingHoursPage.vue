<template>
  <AdminLayout>
    <section class="page-shell">
      <div class="page-content">
        <!-- Header com visual premium -->
        <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
          <div class="header-overlay"></div>
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1">
            <div class="d-flex align-items-center gap-3">
              <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                <i class="bi bi-clock-history fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Configuração de Horários</h1>
                <p class="text-muted mb-0 small-text-responsive">Defina horários de atendimento, disponibilidade e folgas dos profissionais do seu estabelecimento.</p>
              </div>
            </div>

          </div>
        </div>

        <div class="admin-card shadow-sm mb-4">
          <div class="d-flex align-items-center justify-content-between mb-4 border-bottom pb-3">
            <div>
              <h5 class="fw-bold mb-1 text-body">
                <i class="bi bi-gear-wide-connected me-2 text-primary"></i>
                Configuração Global
              </h5>
              <p class="small text-muted mb-0">
                Defina um horário padrão para aplicar rapidamente a todos os profissionais. 
                Isso economiza tempo quando todos trabalham no mesmo horário.
              </p>
            </div>
          </div>
          
          <div class="row g-4" v-if="isOwnerOrAdmin">
            <div class="col-12">
              <div class="p-3 bg-primary-subtle rounded-4 border border-primary-subtle w-100">
                <div class="form-check">
                  <input class="form-check-input" type="checkbox" id="checkGlobalTodosMain" v-model="aplicarATodosColaboradores">
                  <label class="form-check-label small fw-bold text-primary" for="checkGlobalTodosMain" style="cursor: pointer;">
                    <i class="bi bi-people-fill me-1"></i>
                    Aplicar horários abaixo a todos os colaboradores ativos
                  </label>
                </div>
              </div>
            </div>
          </div>

          <div class="row g-3 mt-2">
            <div class="col-md-5">
              <div class="row g-2">
                <div class="col-6">
                  <label class="form-label small text-muted fw-bold mb-1">
                    <i class="bi bi-sunrise me-1"></i> Início Manhã
                  </label>
                  <input type="time" class="form-control custom-input" v-model="globalHorario.inicioManha">
                  <div class="form-text extra-small text-muted">Horário de abertura do estabelecimento</div>
                </div>
                <div class="col-6">
                  <label class="form-label small text-muted fw-bold mb-1">
                    <i class="bi bi-sunset me-1"></i> Fim Manhã
                  </label>
                  <input type="time" class="form-control custom-input" v-model="globalHorario.fimManha">
                  <div class="form-text extra-small text-muted">Intervalo para almoço ou pausa</div>
                </div>
              </div>
            </div>
            <div class="col-md-5">
              <div class="row g-2">
                <div class="col-6">
                  <label class="form-label small text-muted fw-bold mb-1">
                    <i class="bi bi-sunset me-1"></i> Início Tarde
                  </label>
                  <input type="time" class="form-control custom-input" v-model="globalHorario.inicioTarde">
                  <div class="form-text extra-small text-muted">Retorno após o intervalo</div>
                </div>
                <div class="col-6">
                  <label class="form-label small text-muted fw-bold mb-1">
                    <i class="bi bi-moon me-1"></i> Fim Tarde
                  </label>
                  <input type="time" class="form-control custom-input" v-model="globalHorario.fimTarde">
                  <div class="form-text extra-small text-muted">Horário de fechamento do estabelecimento</div>
                </div>
              </div>
            </div>
            <div class="col-md-2 d-flex align-items-end" v-if="canManageSchedule">
              <button 
                class="btn btn-primary w-100 rounded-pill fw-bold shadow-sm py-2" 
                @click="aplicarHorarioGlobal"
                :disabled="salvando || !canManageSchedule"
              >
                <i class="bi bi-check2-all me-1"></i> Aplicar
              </button>
            </div>
          </div>

          <div class="mt-3 p-3 bg-body-tertiary rounded-4 border-start border-primary border-4 shadow-sm">
            <div class="d-flex gap-2">
              <i class="bi bi-lightbulb-fill text-warning fs-5"></i>
              <div>
                <p class="small mb-1 fw-bold text-body">Como funciona?</p>
                <p class="small text-muted mb-0">
                  Este painel aplica o <strong>mesmo horário</strong> para todos os profissionais de uma vez.
                  Se cada profissional tem horários diferentes, desmarque a opção acima e configure
                  individualmente clicando nos botões de <strong>"Dias de Atendimento"</strong> ou <strong>"Folgas e Feriados"</strong> abaixo.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="admin-card shadow-sm mb-4">
          <div class="d-flex align-items-center justify-content-between mb-4 border-bottom pb-3 flex-wrap gap-3">
            <div>
              <h5 class="fw-bold mb-1 text-body">
                <i class="bi bi-sliders me-2 text-primary"></i>
                Ajustes da Agenda
              </h5>
              <p class="small text-muted mb-0">
                Configure individualmente cada profissional: defina seus dias de atendimento, horários de trabalho, folgas e feriados.
              </p>
            </div>
          </div>

          <div class="row g-3 mb-4">
            <div class="col-12">
              <div class="p-3 bg-body-tertiary rounded-4 border shadow-sm">
                <div class="d-flex align-items-center justify-content-between mb-3">
                  <div>
                    <h6 class="fw-bold mb-1">
                      <i class="bi bi-arrow-left-right me-2 text-primary"></i>
                      Modo de Configuração
                    </h6>
                    <p class="small text-muted mb-0">Escolha como seus clientes vão agendar: por horário ou por dia.</p>
                  </div>
                </div>
                <div class="d-flex align-items-center bg-body bg-opacity-50 p-1 rounded-pill border shadow-sm mb-3" style="backdrop-filter: blur(8px);">
                  <button 
                    type="button"
                    class="btn btn-sm rounded-pill px-3 py-2 d-flex align-items-center gap-2 transition-all flex-fill justify-content-center"
                    :class="bookingMode === 'time' ? 'btn-primary shadow-sm fw-bold' : 'btn-link text-muted text-decoration-none'"
                    :disabled="!canManageEstablishment"
                    @click="setBookingMode('time')"
                  >
                    <i class="bi bi-clock-history"></i>
                    <span>Por Horas</span>
                  </button>
                  <button 
                    type="button"
                    class="btn btn-sm rounded-pill px-3 py-2 d-flex align-items-center gap-2 transition-all flex-fill justify-content-center"
                    :class="bookingMode === 'day' ? 'btn-primary shadow-sm fw-bold' : 'btn-link text-muted text-decoration-none'"
                    :disabled="!canManageEstablishment"
                    @click="setBookingMode('day')"
                  >
                    <i class="bi bi-calendar-date"></i>
                    <span>Por Dias</span>
                  </button>
                </div>
                <div class="p-3 bg-primary-subtle rounded-4 border border-primary-subtle">
                  <div class="d-flex gap-2">
                    <i class="bi bi-info-circle-fill text-primary fs-5"></i>
                    <div>
                      <p class="small mb-1 fw-bold text-primary" v-if="bookingMode === 'time'">
                        <i class="bi bi-clock me-1"></i> Modo Por Horas (recomendado para salões, clínicas e consultórios)
                      </p>
                      <p class="small mb-1 fw-bold text-primary" v-else>
                        <i class="bi bi-calendar-event me-1"></i> Modo Por Dias (recomendado para aulas, palestras e eventos)
                      </p>
                      <p class="small text-muted mb-0" v-if="bookingMode === 'time'">
                        Os clientes escolhem um <strong>horário específico</strong> na agenda (ex: 09:00, 10:30, 14:00).
                        Configure os turnos de cada dia da semana e o sistema gera automaticamente os horários disponíveis
                        para os clientes agendarem.
                      </p>
                      <p class="small text-muted mb-0" v-else>
                        Os clientes escolhem apenas o <strong>dia da semana</strong> disponível (ex: Segunda, Terça).
                        Útil quando o profissional atende no mesmo horário todos os dias e o cliente agenda
                        a data que preferir.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="row g-3 align-items-stretch">
            <div class="col-md-6">
              <button
                class="config-action-card w-100"
                data-bs-toggle="modal"
                data-bs-target="#modalDiasAtendimento"
                :disabled="!canManageSchedule"
              >
                <div class="action-left">
                  <div class="action-icon bg-primary-subtle text-primary">
                    <i class="bi bi-calendar-week"></i>
                  </div>
                  <div class="text-start">
                    <h6 class="mb-1 fw-bold">Dias de Atendimento da Semana</h6>
                    <p class="mb-0 text-muted small">
                      Escolha quais dias da semana o profissional atende e defina os horários de cada turno
                    </p>
                  </div>
                </div>
                <i class="bi bi-chevron-right action-arrow"></i>
              </button>
            </div>

            <div class="col-md-6">
              <button
                class="config-action-card w-100"
                data-bs-toggle="modal"
                data-bs-target="#modalFolgasFeriados"
                :disabled="!canManageSchedule"
              >
                <div class="action-left">
                  <div class="action-icon bg-danger-subtle text-danger">
                    <i class="bi bi-calendar-x"></i>
                  </div>
                  <div class="text-start">
                    <h6 class="mb-1 fw-bold">Folgas e Feriados do Calendário</h6>
                    <p class="mb-0 text-muted small">
                      Marque dias específicos como folga ou configure como o profissional trabalha em feriados
                    </p>
                  </div>
                </div>
                <i class="bi bi-chevron-right action-arrow"></i>
              </button>
            </div>
          </div>
        </div>

        <div class="admin-card shadow-sm mb-4" v-if="canViewAllSchedules">
          <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2 pb-2 border-bottom">
            <div>
              <h5 class="fw-bold mb-1">
                <i class="bi bi-calendar2-week me-2 text-danger"></i>
                Visão Geral da Equipe
              </h5>
              <p class="small text-muted mb-0">
                Visualize todas as ausências (folgas e feriados) de todos os profissionais em um só lugar.
              </p>
            </div>
          </div>

          <div v-if="carregandoTodasAgendas" class="empty-folga-state">
            <div class="spinner-border text-primary mb-2" role="status" style="width: 2rem; height: 2rem;">
              <span class="visually-hidden">Carregando...</span>
            </div>
            <div class="fw-bold text-body">Buscando agendas de todos os colaboradores...</div>
          </div>

          <div v-else-if="erroCarregarAgendas" class="empty-folga-state py-4 border-0">
            <i class="bi bi-exclamation-triangle-fill text-warning fs-3 mb-2"></i>
            <div class="small fw-bold text-muted">{{ erroCarregarAgendas }}</div>
          </div>

          <div v-else class="row g-4 mt-1">
            <div 
              v-for="colab in agendaPorColaborador" 
              :key="colab.id" 
              class="col-12 col-xl-6"
            >
              <div class="employee-folga-card p-3 rounded-4 shadow-sm border h-100">
                <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-2">
                  <div class="d-flex align-items-center gap-2">
                    <div class="employee-avatar-badge d-flex align-items-center justify-content-center bg-primary bg-opacity-10 text-primary fw-bold rounded-circle border shadow-sm">
                      {{ colab.nome.charAt(0).toUpperCase() }}
                    </div>
                    <div>
                      <h6 class="fw-extrabold mb-0 text-body">{{ colab.nome }}</h6>
                      <span class="small text-muted font-11">Cronograma de Ausências</span>
                    </div>
                  </div>
                  <span class="badge badge-glow-neutral">
                    {{ colab.cronograma.length }} {{ colab.cronograma.length === 1 ? 'evento' : 'eventos' }}
                  </span>
                </div>

                <div v-if="colab.cronograma.length === 0" class="empty-folga-state py-4 border-0">
                  <i class="bi bi-calendar2-check fs-4 mb-2 text-muted opacity-50"></i>
                  <div class="small fw-bold text-muted">Nenhuma folga ou feriado programado</div>
                </div>

                <div v-else class="cronograma-list d-flex flex-column gap-2">
                  <div
                    v-for="item in colab.cronograma"
                    :key="colab.id + '-' + item.date"
                    class="cronograma-item transition-all shadow-sm border-start border-3"
                    :class="{
                      'border-secondary': item.tipo === 'folga',
                      'border-danger': item.tipo === 'feriado_fechado',
                      'border-success': item.tipo === 'feriado_aberto'
                    }"
                  >
                    <div class="d-flex align-items-center justify-content-between gap-3">
                      <div class="d-flex align-items-center gap-2">
                        <div 
                          class="cronograma-icon-badge d-flex align-items-center justify-content-center rounded-3 border"
                          :class="{
                            'bg-secondary bg-opacity-10 text-secondary border-secondary-subtle': item.tipo === 'folga',
                            'bg-danger bg-opacity-10 text-danger border-danger-subtle': item.tipo === 'feriado_fechado',
                            'bg-success bg-opacity-10 text-success border-success-subtle': item.tipo === 'feriado_aberto'
                          }"
                          style="width: 36px; height: 36px; flex-shrink: 0;"
                        >
                          <i class="bi" :class="{
                            'bi-person-x-fill': item.tipo === 'folga',
                            'bi-calendar-x-fill': item.tipo === 'feriado_fechado',
                            'bi-calendar-check-fill': item.tipo === 'feriado_aberto'
                          } + ' fs-5'"></i>
                        </div>
                        
                        <div>
                          <div class="fw-bold text-body font-13">{{ item.label }}</div>
                          <div class="small text-muted font-11">{{ item.description }}</div>
                        </div>
                      </div>

                      <div class="d-flex align-items-center gap-2">
                        <span
                          class="badge font-11 shadow-sm px-2 py-1"
                          :class="{
                            'bg-secondary bg-opacity-10 text-secondary border border-secondary-subtle': item.tipo === 'folga',
                            'bg-danger bg-opacity-10 text-danger border border-danger-subtle': item.tipo === 'feriado_fechado',
                            'bg-success bg-opacity-10 text-success border border-success-subtle': item.tipo === 'feriado_aberto'
                          }"
                        >
                          {{ formatarData(item.date) }}
                        </span>

                        <button
                          v-if="item.removivel && canManageSchedule"
                          type="button"
                          class="btn btn-action-table rounded-circle shadow-sm btn-action-delete"
                          @click="removerFolga(item.date, colab.id)"
                          title="Remover folga"
                          style="width: 28px; height: 28px;"
                        >
                          <i class="bi bi-trash-fill font-11"></i>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="d-flex justify-content-end align-items-center mt-4 mb-5 border-top pt-4">
          <div class="me-auto">
            <p class="small text-muted mb-0" v-if="!selectedEmployeeId">
              <i class="bi bi-info-circle me-1"></i>
              Selecione um profissional nos modais acima para salvar suas configurações
            </p>
            <p class="small text-muted mb-0" v-else-if="!agendaCarregada">
              <i class="bi bi-hourglass-split me-1"></i>
              Aguarde o carregamento da agenda...
            </p>
            <p class="small text-muted mb-0" v-else>
              <i class="bi bi-check-circle-fill text-success me-1"></i>
              Configurações prontas para salvar para <strong>{{ selectedEmployee?.nome }}</strong>
            </p>
          </div>
          <button
            type="button"
            class="btn btn-primary btn-lg rounded-pill px-5 py-3 fw-bold shadow hover-lift transition-all"
            @click="abrirModalConfirmacaoSalvar"
            :disabled="!selectedEmployeeId || salvando || !agendaCarregada || !canManageSchedule"
            v-if="canManageSchedule"
          >
            <i class="bi bi-cloud-check me-2"></i>
            {{ salvando ? 'Salvando...' : 'Salvar Agenda' }}
          </button>
        </div>
      </div>
    </section>


    <div class="modal fade" id="modalDiasAtendimento" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-xl modal-dialog-centered">
        <div class="modal-content custom-theme-modal shadow-lg">
          <div class="modal-header custom-modal-header border-0">
            <div>
              <h4 class="modal-title fw-bold mb-1">
                <i class="bi bi-calendar-week me-2 text-primary"></i>
                Dias de Atendimento
              </h4>
              <p class="text-muted mb-0 small">
                Configure quais dias da semana o profissional atende e os horários de cada turno (manhã e tarde/noite).
              </p>
            </div>
            <button type="button" class="btn-close opacity-75" data-bs-dismiss="modal" @click="$event.target.blur()"></button>
          </div>

          <div class="modal-body pt-0">
            <div class="mb-3">
              <label class="form-label fw-bold text-muted small">Profissional</label>
              <select
                class="form-select custom-input shadow-sm fw-bold"
                v-model="selectedEmployeeId"
              >
                <option value="">Escolha um profissional</option>
                <option
                  v-for="colab in colaboradores"
                  :key="colab.id"
                  :value="colab.id"
                >
                  {{ colab.nome }}
                </option>
              </select>
            </div>

            <div v-if="!selectedEmployeeId" class="empty-folga-state">
              <i class="bi bi-person-badge fs-3 mb-2"></i>
              <div>Selecione um profissional acima para configurar os horários</div>
            </div>

            <div v-else-if="carregandoAgenda" class="empty-folga-state">
              <i class="bi bi-hourglass-split fs-3 mb-2"></i>
              <div>Carregando agenda do funcionário...</div>
            </div>

            <div v-else class="row g-3">
              <div class="col-12 mb-3">
                <div class="admin-card shadow-sm bg-body-tertiary border p-3" style="border-radius: 16px;">
                  <div class="d-flex gap-2">
                    <i class="bi bi-info-circle-fill text-primary fs-5"></i>
                    <div>
                      <h6 class="fw-bold mb-1">Como configurar?</h6>
                      <p class="small text-muted mb-0">
                        <strong>1.</strong> Ative ou desative cada dia usando o interruptor ao lado do nome.<br>
                        <strong>2.</strong> Para os dias ativos, defina os horários de <strong>início</strong> e <strong>fim</strong> de cada turno.<br>
                        <strong>3.</strong> O sistema cria automaticamente os horários disponíveis para os clientes agendarem.
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <div
                class="col-sm-6 col-lg-6"
                v-for="dia in agendaDiasSemana"
                :key="dia.weekday"
              >
                <div
                  class="day-card p-3 h-100"
                  :class="{ 'disabled-card': !dia.ativo, 'active-card border-primary': dia.ativo }"
                >
                  <div class="d-flex justify-content-between align-items-center mb-3">
                    <label class="fw-bold cursor-pointer mb-0" :for="'check-'+dia.weekday">
                      {{ dia.nome }}
                    </label>

                    <div class="form-check form-switch m-0">
                      <input
                        class="form-check-input fs-5 cursor-pointer shadow-sm"
                        type="checkbox"
                        :id="'check-'+dia.weekday"
                        v-model="dia.ativo"
                      >
                    </div>
                  </div>

                  <div v-if="dia.ativo">
                    <div class="mb-3">
                      <div class="small fw-bold text-info mb-2">
                        <i class="bi bi-sunrise me-1"></i> Turno da manhã
                      </div>
                      <div class="row g-2">
                        <div class="col-6">
                          <label class="form-label small text-muted fw-bold mb-1">Início</label>
                          <input
                            type="time"
                            class="form-control form-control-sm custom-time-input"
                            v-model="dia.inicioManha"
                          >
                          <div class="form-text extra-small text-muted">Horário que o profissional começa a atender</div>
                        </div>

                        <div class="col-6">
                          <label class="form-label small text-muted fw-bold mb-1">Fim</label>
                          <input
                            type="time"
                            class="form-control form-control-sm custom-time-input"
                            v-model="dia.fimManha"
                          >
                          <div class="form-text extra-small text-muted">Horário do intervalo/almoço</div>
                        </div>
                      </div>
                    </div>

                    <div>
                      <div class="small fw-bold text-success mb-2">
                        <i class="bi bi-sunset me-1"></i> Turno da tarde/noite
                      </div>
                      <div class="row g-2">
                        <div class="col-6">
                          <label class="form-label small text-muted fw-bold mb-1">Início</label>
                          <input
                            type="time"
                            class="form-control form-control-sm custom-time-input"
                            v-model="dia.inicioTarde"
                          >
                          <div class="form-text extra-small text-muted">Retorno após o intervalo</div>
                        </div>

                        <div class="col-6">
                          <label class="form-label small text-muted fw-bold mb-1">Fim</label>
                          <input
                            type="time"
                            class="form-control form-control-sm custom-time-input"
                            v-model="dia.fimTarde"
                          >
                          <div class="form-text extra-small text-muted">Horário de encerramento do expediente</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div v-else class="small text-muted fw-bold fst-italic">
                    <i class="bi bi-x-circle me-1"></i> Dia desativado — sem atendimento
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer border-0 pt-0">
            <button type="button" class="btn btn-light rounded-pill px-4 fw-bold" data-bs-dismiss="modal" @click="$event.target.blur()">
              Fechar
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="modal fade" id="modalFolgasFeriados" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content custom-theme-modal shadow-lg">
          <div class="modal-header custom-modal-header border-0">
            <div>
              <h4 class="modal-title fw-bold mb-1">
                <i class="bi bi-calendar-x me-2 text-danger"></i>
                Folgas e Feriados
              </h4>
              <p class="text-muted mb-0 small">
                Gerencie as ausências do profissional: folgas individuais e como ele trabalha nos feriados.
              </p>
            </div>
            <button type="button" class="btn-close opacity-75" data-bs-dismiss="modal" @click="$event.target.blur()"></button>
          </div>

          <div class="modal-body pt-0">
            <div class="mb-3">
              <label class="form-label fw-bold text-muted small">Profissional</label>
              <select
                class="form-select custom-input shadow-sm fw-bold"
                v-model="selectedEmployeeId"
              >
                <option value="">Escolha um profissional</option>
                <option
                  v-for="colab in colaboradores"
                  :key="colab.id"
                  :value="colab.id"
                >
                  {{ colab.nome }}
                </option>
              </select>
            </div>

            <div v-if="!selectedEmployeeId" class="empty-folga-state">
              <i class="bi bi-person-badge fs-3 mb-2"></i>
              <div>Selecione um profissional acima para configurar folgas e feriados</div>
            </div>

            <div v-else-if="carregandoAgenda" class="empty-folga-state">
              <i class="bi bi-hourglass-split fs-3 mb-2"></i>
              <div>Carregando agenda do funcionário...</div>
            </div>

            <div v-else>
              <div class="admin-card shadow-sm bg-body-tertiary border p-3 mb-3" style="border-radius: 16px;">
                <div class="d-flex gap-2">
                  <i class="bi bi-info-circle-fill text-primary fs-5"></i>
                  <div>
                    <h6 class="fw-bold mb-1">Como usar o calendário?</h6>
                    <p class="small text-muted mb-0">
                      <strong>1.</strong> Navegue entre os meses usando as setas.<br>
                      <strong>2.</strong> Clique em um dia para <strong>marcar como folga</strong> (ausência do profissional).<br>
                      <strong>3.</strong> Em feriados, clique para alternar entre <strong>fechado</strong> e <strong>aberto</strong>.<br>
                      <strong>4.</strong> Dias passados não podem ser alterados.
                    </p>
                  </div>
                </div>
              </div>

              <div class="calendar-app mx-auto shadow-sm mt-2">
                <div class="calendar-header">
                  <div class="calendar-nav-controls">
                    <button class="btn btn-sm btn-light border btn-icon shadow-sm rounded-circle" @click="changeMonth(-1)">
                      <i class="bi bi-chevron-left"></i>
                    </button>

                    <h6 class="fw-bold m-0 mx-2 text-body text-center" style="min-width: 140px;">
                      {{ monthNames[currentMonth] }} {{ currentYear }}
                    </h6>

                    <button class="btn btn-sm btn-light border btn-icon shadow-sm rounded-circle" @click="changeMonth(1)">
                      <i class="bi bi-chevron-right"></i>
                    </button>
                  </div>

                  <button class="btn btn-outline-primary rounded-pill fw-bold px-3 py-1 shadow-sm" @click="goToToday()">
                    Hoje
                  </button>
                </div>

                <div class="calendar-grid mb-2 border-bottom pb-2">
                  <div class="calendar-day-name text-muted small fw-bold">D</div>
                  <div class="calendar-day-name text-muted small fw-bold">S</div>
                  <div class="calendar-day-name text-muted small fw-bold">T</div>
                  <div class="calendar-day-name text-muted small fw-bold">Q</div>
                  <div class="calendar-day-name text-muted small fw-bold">Q</div>
                  <div class="calendar-day-name text-muted small fw-bold">S</div>
                  <div class="calendar-day-name text-muted small fw-bold">S</div>
                </div>

                <div class="calendar-grid">
                  <div v-for="n in emptyDays" :key="'empty'+n" class="calendar-day empty"></div>

                  <div
                    v-for="day in daysInMonth"
                    :key="'day'+day"
                    class="calendar-day shadow-sm"
                    :class="{
                      'blocked': isBlocked(day) && !isHoliday(day),
                      'holiday-day': isHoliday(day) && !isWorkedHoliday(day),
                      'worked-holiday': isHoliday(day) && isWorkedHoliday(day),
                      'today': isToday(day),
                      'past-day': isPast(day)
                    }"
                    :title="isHoliday(day)
                      ? (isWorkedHoliday(day)
                        ? 'Feriado: ' + isHoliday(day) + ' (Aberto)'
                        : 'Feriado: ' + isHoliday(day) + ' (Fechado)')
                      : (isBlocked(day) ? 'Folga Manual' : '')"
                    @click="toggleBlockDate(day)"
                  >
                    {{ day }}
                  </div>
                </div>
              </div>

              <div class="d-flex flex-wrap justify-content-center gap-3 gap-md-4 mt-4 mx-auto p-3 bg-body-tertiary rounded-4 border legend-box">
                <div class="d-flex align-items-center gap-2 small fw-bold text-muted">
                  <span class="legend-dot bg-body border border-secondary-subtle"></span> Dia normal
                </div>
                <div class="d-flex align-items-center gap-2 small fw-bold text-primary">
                  <span class="legend-dot bg-primary border border-primary"></span> Hoje
                </div>
                <div class="d-flex align-items-center gap-2 small fw-bold text-secondary">
                  <span class="legend-dot bg-secondary border border-secondary"></span> Folga (ausência)
                </div>
                <div class="d-flex align-items-center gap-2 small fw-bold text-danger">
                  <span class="legend-dot border legend-holiday-closed"></span>
                  Feriado — fechado
                </div>
                <div class="d-flex align-items-center gap-2 small fw-bold text-success">
                  <span class="legend-dot border border-success legend-holiday-open"></span>
                  Feriado — aberto
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer border-0 pt-0">
            <button type="button" class="btn btn-light rounded-pill px-4 fw-bold" data-bs-dismiss="modal" @click="$event.target.blur()">
              Fechar
            </button>
          </div>
        </div>
      </div>
    </div>
    <div class="modal fade" id="modalConfirmarSalvarAgenda" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content custom-theme-modal shadow-lg">
          <div class="modal-header custom-modal-header border-0">
            <div>
              <h4 class="modal-title fw-bold mb-1">
                <i class="bi bi-cloud-check me-2 text-primary"></i>
                Confirmar Salvamento
              </h4>
              <p class="text-muted mb-0 small">
                Verifique as informações antes de salvar as alterações.
              </p>
            </div>
            <button
              type="button"
              class="btn-close opacity-75"
              data-bs-dismiss="modal"
              @click="$event.target.blur()"
            ></button>
          </div>
        
          <div class="modal-body pt-0">
            <div class="admin-card shadow-sm border-0 p-3">
              <div class="small text-muted mb-2 fw-bold">Profissional</div>
              <div class="fw-bold fs-5">
                {{ selectedEmployee?.nome || 'Nenhum profissional selecionado' }}
              </div>
              <p class="small text-muted mb-0 mt-2">
                As configurações de dias de atendimento, horários, folgas e feriados serão salvas para este profissional.
              </p>
            </div>
          </div>
        
          <div class="modal-footer border-0 pt-0 d-flex justify-content-end gap-2">
            <button
              type="button"
              class="btn btn-light rounded-pill px-4 fw-bold"
              data-bs-dismiss="modal"
              :disabled="salvando"
              @click="$event.target.blur()"
            >
              <i class="bi bi-x-circle me-1"></i> Cancelar
            </button>
          
            <button
              type="button"
              class="btn btn-primary rounded-pill px-4 fw-bold"
              @click="confirmarSalvarAgenda"
              :disabled="salvando || !canManageSchedule"
            >
              <i class="bi bi-check2-circle me-2"></i>
              {{ salvando ? 'Salvando...' : 'Sim, salvar' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import { ref, computed, onMounted, watch } from 'vue'
import { Modal } from 'bootstrap'
import { api } from '@/services/api'

const currentUser = computed(() => {
  try {
    const raw = localStorage.getItem('user') || sessionStorage.getItem('user')
    return raw ? JSON.parse(raw) : null
  } catch { return null }
})

const canViewAllSchedules = computed(() => {
  const user = currentUser.value
  if (!user) return false
  if (user.role === 'owner' || user.role === 'super_admin') return true
  const rawPerms = localStorage.getItem('establishment-permissions') || sessionStorage.getItem('establishment-permissions')
  if (rawPerms) {
    try {
      const perms = JSON.parse(rawPerms)
      return perms?.can_manage_schedule === true
    } catch { return false }
  }
  return false
})

const isOwnerOrAdmin = computed(() => {
  const user = currentUser.value
  if (!user) return false
  return user.role === 'owner' || user.role === 'super_admin'
})

const canManageSchedule = computed(() => {
  const user = currentUser.value
  if (!user) return false
  if (user.role === 'owner' || user.role === 'super_admin') return true
  const rawPerms = localStorage.getItem('establishment-permissions') || sessionStorage.getItem('establishment-permissions')
  if (rawPerms) {
    try {
      const perms = JSON.parse(rawPerms)
      return perms?.can_manage_schedule === true
    } catch { return false }
  }
  return false
})

const canManageEstablishment = computed(() => {
  const user = currentUser.value
  if (!user) return false
  if (user.role === 'owner' || user.role === 'super_admin') return true
  const rawPerms = localStorage.getItem('establishment-permissions') || sessionStorage.getItem('establishment-permissions')
  if (rawPerms) {
    try {
      const perms = JSON.parse(rawPerms)
      return perms?.can_manage_establishment === true
    } catch { return false }
  }
  return false
})

// Configurações globais
const bookingMode = ref('time')

async function fetchGlobalConfig() {
  try {
    const { data } = await api.get('/admin/establishment')
    if (data) {
      bookingMode.value = data.booking_mode || 'time'
    }
  } catch (error) {
    console.error('Erro ao buscar configs globais:', error)
  }
}

async function saveGlobalConfig() {
  if (!canManageEstablishment.value) {
    alert('Você não tem permissão para alterar as configurações do estabelecimento.')
    return
  }

  try {
    await api.patch('/admin/establishment', {
      establishment: {
        booking_mode: bookingMode.value
      }
    })
  } catch (error) {
    console.error('Erro ao salvar config:', error)
    alert('Erro ao salvar configurações de agendamento.')
  }
}

function setBookingMode(mode) {
  if (!canManageEstablishment.value) {
    alert('Você não tem permissão para alterar as configurações do estabelecimento.')
    return
  }
  bookingMode.value = mode
  saveGlobalConfig()
}

const colaboradores = ref([])
const selectedEmployeeId = ref('')
const carregandoAgenda = ref(false)
const salvando = ref(false)
const agendaCarregada = ref(false)
const modalConfirmacaoSalvarRef = ref(null)

const criarDiasSemanaPadrao = () => ([
  { weekday: 1, nome: 'Segunda', ativo: true, inicioManha: '08:00', fimManha: '12:00', inicioTarde: '13:00', fimTarde: '22:00' },
  { weekday: 2, nome: 'Terça',   ativo: true, inicioManha: '08:00', fimManha: '12:00', inicioTarde: '13:00', fimTarde: '22:00' },
  { weekday: 3, nome: 'Quarta',  ativo: true, inicioManha: '08:00', fimManha: '12:00', inicioTarde: '13:00', fimTarde: '22:00' },
  { weekday: 4, nome: 'Quinta',  ativo: true, inicioManha: '08:00', fimManha: '12:00', inicioTarde: '13:00', fimTarde: '22:00' },
  { weekday: 5, nome: 'Sexta',   ativo: true, inicioManha: '08:00', fimManha: '12:00', inicioTarde: '13:00', fimTarde: '22:00' },
  { weekday: 6, nome: 'Sábado',  ativo: true, inicioManha: '08:00', fimManha: '12:00', inicioTarde: '13:00', fimTarde: '22:00' },
  { weekday: 0, nome: 'Domingo', ativo: false, inicioManha: '08:00', fimManha: '12:00', inicioTarde: '13:00', fimTarde: '22:00' }
])

const agendaDiasSemana = ref(criarDiasSemanaPadrao())
const blockedDates = ref([])
const workedHolidays = ref([])
const folgasOriginais = ref([])
const feriadosOriginais = ref([])

const globalHorario = ref({
  inicioManha: '08:00',
  fimManha: '12:00',
  inicioTarde: '13:00',
  fimTarde: '22:00'
})

const aplicarATodosColaboradores = ref(false)

function validarHorarios(h) {
  if (!h.inicioManha || !h.fimManha || !h.inicioTarde || !h.fimTarde) {
    alert('Por favor, preencha todos os horários da configuração global.')
    return false
  }
  if (h.inicioManha >= h.fimManha) {
    alert('O início da manhã deve ser anterior ao fim da manhã.')
    return false
  }
  if (h.fimManha > h.inicioTarde) {
    alert('O turno da tarde deve começar após o fim do turno da manhã.')
    return false
  }
  if (h.inicioTarde >= h.fimTarde) {
    alert('O início da tarde deve ser anterior ao fim da tarde.')
    return false
  }
  return true
}

function aplicarHorarioGlobal() {
  if (!canManageSchedule.value) {
    alert('Você não tem permissão para gerenciar a agenda.')
    return
  }

  if (!validarHorarios(globalHorario.value)) return

  if (aplicarATodosColaboradores.value) {
    if (!isOwnerOrAdmin.value) {
      alert('Acesso negado: apenas o proprietário pode aplicar agenda para todos os colaboradores.')
      return
    }

    if (!confirm('Tem certeza que deseja aplicar este horário para TODOS os colaboradores ativos da empresa? Isso substituirá os horários de todos eles.')) {
      return
    }
    
    salvando.value = true
    
    // Se tiver um funcionário selecionado, usamos a agenda dele como base para quais dias estão ativos.
    // Se não tiver, usamos o padrão (Seg-Sáb ativo, Dom inativo).
    const diasBase = selectedEmployeeId.value ? agendaDiasSemana.value : criarDiasSemanaPadrao()

    const payload = {
      days: diasBase.map((dia) => ({
        weekday: dia.weekday,
        is_available: dia.ativo,
        morning_start_time: dia.ativo ? globalHorario.value.inicioManha : null,
        morning_end_time: dia.ativo ? globalHorario.value.fimManha : null,
        afternoon_start_time: dia.ativo ? globalHorario.value.inicioTarde : null,
        afternoon_end_time: dia.ativo ? globalHorario.value.fimTarde : null
      }))
    }

    api.patch('/admin/team/bulk_schedule', payload)
      .then(() => {
        alert('Agenda global aplicada com sucesso a todos os colaboradores!')
        if (selectedEmployeeId.value) {
          carregarAgendaFuncionario()
        }
      })
      .catch(err => {
        console.error('Erro ao aplicar agenda global:', err)
        const msg = err.response?.data?.error || 'Erro ao aplicar agenda global.'
        alert(msg)
      })
      .finally(() => {
        salvando.value = false
      })
  } else {
    if (!selectedEmployeeId.value) {
      alert('Selecione um profissional ou marque "Aplicar a todos os colaboradores".')
      return
    }
    // Aplica apenas para o colaborador atual (em memória)
    agendaDiasSemana.value.forEach(dia => {
      if (dia.ativo) {
        dia.inicioManha = globalHorario.value.inicioManha
        dia.fimManha = globalHorario.value.fimManha
        dia.inicioTarde = globalHorario.value.inicioTarde
        dia.fimTarde = globalHorario.value.fimTarde
      }
    })
    alert('Horários aplicados localmente. Lembre-se de clicar em "Salvar Agenda" para persistir as alterações.')
  }
}

const today = new Date()
const currentMonth = ref(today.getMonth())
const currentYear = ref(today.getFullYear())

const monthNames = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
]

const holidays = ref({})
const todosColaboradoresAgendas = ref({})
const carregandoTodasAgendas = ref(false)
const erroCarregarAgendas = ref('')

async function carregarTodasAgendas() {
  if (colaboradores.value.length === 0) return
  carregandoTodasAgendas.value = true
  erroCarregarAgendas.value = ''

  try {
    const { data } = await api.get('/admin/team/all_schedules')
    const agendas = {}

    if (Array.isArray(data?.employees)) {
      data.employees.forEach((emp) => {
        agendas[emp.id] = {
          id: emp.id,
          nome: emp.nome,
          blockedDates: Array.isArray(emp.blocked_dates) ? [...emp.blocked_dates] : [],
          workedHolidays: Array.isArray(emp.worked_holidays) ? [...emp.worked_holidays] : []
        }
      })
    }

    todosColaboradoresAgendas.value = agendas
  } catch (err) {
    if (err?.response?.status === 403) {
      erroCarregarAgendas.value = 'Você não tem permissão para visualizar as agendas de todos os profissionais.'
    } else {
      erroCarregarAgendas.value = 'Erro ao carregar as agendas da equipe. Tente novamente.'
    }
  } finally {
    carregandoTodasAgendas.value = false
  }
}

const selectedEmployee = computed(() => {
  return colaboradores.value.find(c => Number(c.id) === Number(selectedEmployeeId.value)) || null
})

const cronogramaFolgasEFeriados = computed(() => {
  if (!selectedEmployeeId.value) return []

  const list = []
  const d = new Date()
  const todayStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`

  // 1. Folgas Manuais
  blockedDates.value.forEach(date => {
    if (date < todayStr) return
    const holidayName = holidays.value[date]
    if (!holidayName) {
      list.push({
        date,
        tipo: 'folga',
        label: `Folga: ${selectedEmployee.value?.nome || 'Profissional'}`,
        description: 'Bloqueio manual de atendimento',
        removivel: true
      })
    }
  })

  // 2. Feriados do ano
  Object.entries(holidays.value).forEach(([date, name]) => {
    if (date < todayStr) return
    const isTrabalhado = workedHolidays.value.includes(date)
    list.push({
      date,
      tipo: isTrabalhado ? 'feriado_aberto' : 'feriado_fechado',
      label: `Feriado: ${name}`,
      description: isTrabalhado ? 'Aberto (Profissional trabalha)' : 'Fechado (Sem expediente)',
      removivel: false
    })
  })

  // Ordena cronologicamente por data
  return list.sort((a, b) => a.date.localeCompare(b.date))
})

const agendaPorColaborador = computed(() => {
  const d = new Date()
  const todayStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`

  return colaboradores.value.map(colab => {
    const agenda = todosColaboradoresAgendas.value[colab.id] || { blockedDates: [], workedHolidays: [] }
    const list = []

    // 1. Folgas Manuais
    agenda.blockedDates.forEach((date) => {
      if (date < todayStr) return
      const holidayName = holidays.value[date]
      if (!holidayName) {
        list.push({
          date,
          tipo: 'folga',
          label: 'Folga',
          description: 'Bloqueio manual',
          removivel: true
        })
      }
    })

    // 2. Feriados do ano
    Object.entries(holidays.value).forEach(([date, name]) => {
      if (date < todayStr) return
      const isTrabalhado = agenda.workedHolidays.includes(date)
      list.push({
        date,
        tipo: isTrabalhado ? 'feriado_aberto' : 'feriado_fechado',
        label: `Feriado: ${name}`,
        description: isTrabalhado ? 'Aberto (Trabalha)' : 'Fechado (Ausente)',
        removivel: false
      })
    })

    // Ordena cronologicamente
    list.sort((a, b) => a.date.localeCompare(b.date))

    return {
      id: colab.id,
      nome: colab.nome,
      cronograma: list
    }
  })
})

const listaFolgas = computed(() => {
  return [...blockedDates.value].sort()
})

const emptyDays = computed(() => {
  return new Date(currentYear.value, currentMonth.value, 1).getDay()
})

const daysInMonth = computed(() => {
  return new Date(currentYear.value, currentMonth.value + 1, 0).getDate()
})

function formatarData(data) {
  const [ano, mes, dia] = data.split('-')
  return `${dia}/${mes}/${ano}`
}

async function removerFolga(data, employeeId) {
  if (!canManageSchedule.value) {
    alert('Você não tem permissão para remover folgas.')
    return
  }

  if (!data) return

  const targetId = employeeId || selectedEmployeeId.value
  if (!targetId) {
    alert('Selecione um profissional ou identifique o colaborador.')
    return
  }

  const colab = colaboradores.value.find(c => Number(c.id) === Number(targetId))
  const nomeColab = colab ? colab.nome : 'profissional'

  const confirmar = confirm(`Deseja remover a folga do dia ${formatarData(data)} para ${nomeColab}?`)
  if (!confirmar) return

  salvando.value = true
  try {
    const { data: scheduleData } = await api.get(`/admin/team/${targetId}/schedule`)

    const currentBlocked = Array.isArray(scheduleData?.blocked_dates) ? scheduleData.blocked_dates : []
    const currentWorked = Array.isArray(scheduleData?.worked_holidays) ? scheduleData.worked_holidays : []

    const updatedBlocked = currentBlocked.filter(d => d !== data)

    const payload = {
      days: (scheduleData?.schedule || []).map((dia) => ({
        weekday: dia.weekday,
        is_available: dia.is_available,
        morning_start_time: dia.morning_start_time,
        morning_end_time: dia.morning_end_time,
        afternoon_start_time: dia.afternoon_start_time,
        afternoon_end_time: dia.afternoon_end_time
      })),
      blocked_dates: updatedBlocked,
      worked_holidays: currentWorked
    }

    await api.patch(`/admin/team/${targetId}/schedule`, payload)

    alert(`Folga de ${nomeColab} removida com sucesso!`)

    if (Number(targetId) === Number(selectedEmployeeId.value)) {
      blockedDates.value = updatedBlocked
      folgasOriginais.value = [...updatedBlocked]
    }

    await carregarTodasAgendas()
  } catch (error) {
    console.error('Erro ao remover folga:', error)
    alert(error?.response?.data?.error || 'Erro ao remover folga.')
  } finally {
    salvando.value = false
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
      'Profissional'
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

    colaboradores.value = lista.map(normalizarColaborador)
  } catch (error) {
    console.error('Erro ao buscar colaboradores:', error)
    colaboradores.value = []
  }
}

function aplicarAgendaRecebida(schedule) {
  const base = criarDiasSemanaPadrao()

  if (!Array.isArray(schedule) || schedule.length === 0) {
    agendaDiasSemana.value = base
    return
  }

  agendaDiasSemana.value = base.map((diaBase) => {
    const found = schedule.find((item) => Number(item.weekday) === Number(diaBase.weekday))
    if (!found) return diaBase

    return {
      weekday: Number(found.weekday),
      nome: found.nome || diaBase.nome,
      ativo: !!found.is_available,
      inicioManha: found.morning_start_time || diaBase.inicioManha,
      fimManha: found.morning_end_time || diaBase.fimManha,
      inicioTarde: found.afternoon_start_time || diaBase.inicioTarde,
      fimTarde: found.afternoon_end_time || diaBase.fimTarde
    }
  })
}

async function carregarAgendaFuncionario() {
  agendaCarregada.value = false

  if (!selectedEmployeeId.value) {
    agendaDiasSemana.value = criarDiasSemanaPadrao()
    blockedDates.value = []
    workedHolidays.value = []
    folgasOriginais.value = []
    feriadosOriginais.value = []
    return
  }

  carregandoAgenda.value = true

  try {
    const { data } = await api.get(`/admin/team/${selectedEmployeeId.value}/schedule`)

    aplicarAgendaRecebida(data?.schedule || [])

    const folgasCarregadas = Array.isArray(data?.blocked_dates) ? [...data.blocked_dates] : []
    const feriadosCarregados = Array.isArray(data?.worked_holidays) ? [...data.worked_holidays] : []

    blockedDates.value = folgasCarregadas
    workedHolidays.value = feriadosCarregados
    folgasOriginais.value = [...folgasCarregadas]
    feriadosOriginais.value = [...feriadosCarregados]

    agendaCarregada.value = true
  } catch (error) {
    console.error('Erro ao carregar agenda do funcionário:', error)
    agendaDiasSemana.value = criarDiasSemanaPadrao()
    blockedDates.value = []
    workedHolidays.value = []
    folgasOriginais.value = []
    feriadosOriginais.value = []
    alert(error?.response?.data?.error || 'Não foi possível carregar a agenda do funcionário.')
  } finally {
    carregandoAgenda.value = false
  }
}

function validarHorariosAgenda() {
  for (const dia of agendaDiasSemana.value) {
    if (!dia.ativo) continue

    if (!dia.inicioManha || !dia.fimManha || !dia.inicioTarde || !dia.fimTarde) {
      alert(`Preencha os 4 horários de ${dia.nome}.`)
      return false
    }

    if (dia.inicioManha >= dia.fimManha) {
      alert(`No turno da manhã de ${dia.nome}, o horário final precisa ser maior que o inicial.`)
      return false
    }

    if (dia.inicioTarde >= dia.fimTarde) {
      alert(`No turno da tarde/noite de ${dia.nome}, o horário final precisa ser maior que o inicial.`)
      return false
    }

    if (dia.fimManha > dia.inicioTarde) {
      alert(`Em ${dia.nome}, o turno da tarde/noite deve começar depois do fim da manhã.`)
      return false
    }
  }

  return true
}

function abrirModalConfirmacaoSalvar() {
  if (!canManageSchedule.value) {
    alert('Você não tem permissão para gerenciar a agenda.')
    return
  }

  if (!selectedEmployeeId.value) {
    alert('Selecione um profissional.')
    return
  }

  if (!agendaCarregada.value || carregandoAgenda.value) {
    alert('Aguarde carregar a agenda antes de salvar.')
    return
  }

  if (salvando.value) return
  if (!validarHorariosAgenda()) return

  if (!Array.isArray(blockedDates.value)) {
    alert('Erro interno: estado de folgas inválido.')
    return
  }

  if (!Array.isArray(workedHolidays.value)) {
    alert('Erro interno: estado de feriados inválido.')
    return
  }

  const modalElement = document.getElementById('modalConfirmarSalvarAgenda')
  if (!modalElement) return

  modalConfirmacaoSalvarRef.value = Modal.getOrCreateInstance(modalElement)
  modalConfirmacaoSalvarRef.value.show()
}

async function confirmarSalvarAgenda() {
  if (!canManageSchedule.value) {
    alert('Você não tem permissão para gerenciar a agenda.')
    return
  }

  if (!selectedEmployeeId.value) {
    alert('Selecione um profissional.')
    return
  }

  if (!agendaCarregada.value || carregandoAgenda.value) {
    alert('Aguarde carregar a agenda antes de salvar.')
    return
  }

  if (salvando.value) return
  if (!validarHorariosAgenda()) return

  const feriados = [...new Set(workedHolidays.value)].sort()
  const folgas = [...new Set(blockedDates.value.filter((d) => !feriados.includes(d)))].sort()

  const payload = {
    days: agendaDiasSemana.value.map((dia) => ({
      weekday: dia.weekday,
      is_available: dia.ativo,
      morning_start_time: dia.ativo ? dia.inicioManha : null,
      morning_end_time: dia.ativo ? dia.fimManha : null,
      afternoon_start_time: dia.ativo ? dia.inicioTarde : null,
      afternoon_end_time: dia.ativo ? dia.fimTarde : null
    })),
    blocked_dates: folgas,
    worked_holidays: feriados
  }

  salvando.value = true

  try {
    await api.patch(`/admin/team/${selectedEmployeeId.value}/schedule`, payload)

    modalConfirmacaoSalvarRef.value?.hide()
    alert('Agenda salva com sucesso!')
    await carregarAgendaFuncionario()
    await carregarTodasAgendas()
  } catch (error) {
    console.error('Erro ao salvar agenda:', error)

    alert(
      error?.response?.data?.error ||
      'Não foi possível salvar a agenda.'
    )
  } finally {
    salvando.value = false
  }
}

function isToday(day) {
  const d = new Date()
  return (
    d.getMonth() === currentMonth.value &&
    d.getFullYear() === currentYear.value &&
    d.getDate() === day
  )
}

function isPast(day) {
  const dateStr = getDateString(day)
  const d = new Date()
  const todayStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  return dateStr < todayStr
}

function getDateString(day) {
  return `${currentYear.value}-${String(currentMonth.value + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
}

function isHoliday(day) {
  return holidays.value[getDateString(day)]
}

function isWorkedHoliday(day) {
  return workedHolidays.value.includes(getDateString(day))
}

function isBlocked(day) {
  return blockedDates.value.includes(getDateString(day))
}

function toggleBlockDate(day) {
  if (!canManageSchedule.value) {
    alert('Você não tem permissão para gerenciar a agenda.')
    return
  }

  if (!selectedEmployeeId.value) {
    alert('Selecione um profissional primeiro.')
    return
  }

  if (isPast(day)) {
    alert('Não é possível alterar folgas ou feriados em datas passadas.')
    return
  }

  const dateStr = getDateString(day)
  const holidayName = isHoliday(day)

  if (holidayName) {
    const estaComoAberto = workedHolidays.value.includes(dateStr)

    if (estaComoAberto) {
      workedHolidays.value = workedHolidays.value.filter(d => d !== dateStr)
      blockedDates.value = [...new Set([...blockedDates.value, dateStr])]
    } else {
      workedHolidays.value = [...new Set([...workedHolidays.value, dateStr])]
      blockedDates.value = blockedDates.value.filter(d => d !== dateStr)
    }

    return
  }

  if (blockedDates.value.includes(dateStr)) {
    blockedDates.value = blockedDates.value.filter(d => d !== dateStr)
  } else {
    blockedDates.value = [...new Set([...blockedDates.value, dateStr])]
  }

  workedHolidays.value = workedHolidays.value.filter(d => d !== dateStr)
}

async function fetchHolidays(year) {
  const safeYear = parseInt(year, 10)
  if (isNaN(safeYear) || safeYear < 2000 || safeYear > 2100) return

  try {
    const response = await fetch(`https://brasilapi.com.br/api/feriados/v1/${safeYear}`, {
      credentials: 'omit'
    })
    if (!response.ok) throw new Error('API de feriados indisponível')
    const data = await response.json()

    const newHolidays = {}
    const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/

    if (Array.isArray(data)) {
      data.forEach((f) => {
        const date = typeof f?.date === 'string' ? f.date.trim() : ''
        const name = typeof f?.name === 'string' ? f.name.replace(/<[^>]*>/g, '').trim().slice(0, 100) : ''
        if (DATE_REGEX.test(date) && name) {
          newHolidays[date] = name
        }
      })
    }

    holidays.value = newHolidays
  } catch (error) {
    console.error('Erro ao buscar feriados:', error)
  }
}

function changeMonth(dir) {
  const oldYear = currentYear.value

  currentMonth.value += dir

  if (currentMonth.value < 0) {
    currentMonth.value = 11
    currentYear.value--
  } else if (currentMonth.value > 11) {
    currentMonth.value = 0
    currentYear.value++
  }

  if (currentYear.value !== oldYear) {
    fetchHolidays(currentYear.value)
  }
}

function goToToday() {
  const oldYear = currentYear.value
  currentMonth.value = today.getMonth()
  currentYear.value = today.getFullYear()

  if (currentYear.value !== oldYear) {
    fetchHolidays(currentYear.value)
  }
}

watch(selectedEmployeeId, async (novoId) => {
  if (salvando.value) return

  agendaCarregada.value = false

  if (!novoId) {
    agendaDiasSemana.value = criarDiasSemanaPadrao()
    blockedDates.value = []
    workedHolidays.value = []
    folgasOriginais.value = []
    feriadosOriginais.value = []
    return
  }

  await carregarAgendaFuncionario()
})

onMounted(async () => {
  await fetchGlobalConfig()
  await fetchHolidays(currentYear.value)
  await fetchColaboradores()
  await carregarTodasAgendas()
})
</script>

<style scoped>
/* Ajuste de Layout Tela Cheia */
.page-content {
  max-width: 100% !important;
}

/* Header Premium */
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

:host, :root {
  --holiday-bg: rgba(220, 53, 69, 0.08);
  --holiday-color: #dc3545;
  --work-bg: rgba(25, 135, 84, 0.08);
  --work-color: #198754;
  --card-shadow: rgba(0, 0, 0, 0.08);
}

[data-bs-theme="dark"] {
  --holiday-bg: rgba(220, 53, 69, 0.15);
  --holiday-color: #ff8c96;
  --work-bg: rgba(25, 135, 84, 0.15);
  --work-color: #75d49b;
  --card-shadow: rgba(0, 0, 0, 0.4);
}

.cursor-pointer {
  cursor: pointer;
}

.admin-card {
  background: var(--glass-bg);
  border: 1px solid var(--card-border);
  border-radius: 22px;
  padding: 1.5rem 1.75rem;
  backdrop-filter: blur(15px);
  box-shadow: 0 4px 20px var(--card-shadow);
}

.custom-input {
  border-radius: 12px;
  padding: 10px 15px;
  border: 1px solid var(--card-border);
  background-color: var(--bs-body-bg);
  color: var(--bs-body-color);
  transition: all 0.2s;
}

.custom-input:focus {
  border-color: var(--bs-primary) !important;
  box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.15) !important;
}

.config-action-card {
  border: 1px solid var(--card-border);
  background: var(--bs-tertiary-bg);
  border-radius: 18px;
  padding: 1rem 1.1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: all 0.25s ease;
  color: inherit;
  box-shadow: 0 2px 8px var(--card-shadow);
  height: 100%;
  min-height: 90px;
}

.config-action-card .action-left {
  flex: 1;
  min-width: 0;
}

.config-action-card .action-left p {
  margin-bottom: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.config-action-card:hover {
  transform: translateY(-2px);
  border-color: rgba(13, 110, 253, 0.35);
  box-shadow: 0 0.75rem 1.5rem var(--card-shadow);
}

.config-action-card:disabled {
  opacity: 0.55;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.action-left {
  display: flex;
  align-items: center;
  gap: 14px;
}

.action-icon {
  width: 48px;
  height: 48px;
  border-radius: 15px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.2rem;
  flex-shrink: 0;
}

.action-arrow {
  font-size: 1.1rem;
  opacity: 0.6;
}

.day-summary-card {
  border: 1px solid var(--card-border);
  border-radius: 16px;
  padding: 1rem;
  background: var(--bs-tertiary-bg);
  box-shadow: 0 2px 10px var(--card-shadow);
}

.day-summary-card.inactive {
  opacity: 0.75;
  border-style: dashed;
}

.custom-theme-modal {
  background: var(--bs-body-bg);
  border: 1px solid var(--bs-border-color-translucent);
  border-radius: 24px;
  color: var(--bs-body-color);
  box-shadow: 0 10px 40px rgba(0,0,0,0.3);
}

.custom-modal-header,
.modal-footer,
.modal-body {
  padding-left: 1.4rem;
  padding-right: 1.4rem;
}

.day-card {
  border: 1px solid var(--bs-border-color-translucent) !important;
  transition: all 0.2s ease;
  background: var(--bs-tertiary-bg);
  border-radius: 16px;
  box-shadow: 0 2px 8px var(--card-shadow);
}

.active-card {
  background-color: var(--bs-secondary-bg);
  border-width: 2px !important;
  border-color: var(--bs-primary) !important;
  box-shadow: 0 .5rem 1rem rgba(13, 110, 253, .15)!important;
}

.disabled-card {
  opacity: 0.6;
  border-style: dashed !important;
}

.day-card:hover {
  transform: translateY(-3px);
}

.custom-time-input {
  border-radius: 12px;
  border: 1px solid var(--bs-border-color);
  background: var(--bs-body-bg);
  color: var(--bs-body-color);
  min-height: 42px;
}

.custom-time-input:focus {
  border-color: var(--bs-primary);
  box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.15);
}

[data-bs-theme="dark"] .custom-time-input::-webkit-calendar-picker-indicator {
  filter: invert(1);
  cursor: pointer;
}

.calendar-app {
  background: var(--bs-body-bg);
  border: 1px solid var(--bs-border-color-translucent);
  border-radius: 20px;
  padding: 20px;
  width: 100%;
  max-width: 420px;
  box-shadow: 0 4px 20px var(--card-shadow);
}

.calendar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
  gap: 10px;
}

.calendar-nav-controls {
  display: flex;
  align-items: center;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
  text-align: center;
}

.calendar-day-name {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 30px;
}

.calendar-day {
  aspect-ratio: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.2s;
  font-weight: 700;
  font-size: 0.95rem;
  color: var(--bs-body-color);
  border: 1px solid var(--bs-border-color-translucent);
  background: var(--bs-tertiary-bg);
}

.calendar-day:hover:not(.empty) {
  background: var(--bs-primary);
  color: white;
  transform: scale(1.12);
  border-color: var(--bs-primary);
  box-shadow: 0 .5rem 1rem rgba(13, 110, 253, .25)!important;
}

.calendar-day.blocked {
  background: var(--bs-secondary);
  color: white;
  text-decoration: line-through;
  border-color: var(--bs-secondary);
}

.calendar-day.today {
  background: var(--bs-primary);
  color: white;
  box-shadow: 0 0 15px rgba(13, 110, 253, 0.5);
  border-color: var(--bs-primary);
}

.calendar-day.holiday-day {
  background-color: var(--holiday-bg);
  color: var(--holiday-color);
  border: 2px dashed var(--bs-danger);
  text-decoration: line-through;
}

.calendar-day.worked-holiday {
  background-color: var(--work-bg);
  color: var(--work-color);
  border: 2px solid var(--bs-success);
}

.legend-box {
  max-width: 700px;
}

.legend-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
}

.legend-holiday-closed {
  background: var(--holiday-bg);
  border: 1px dashed var(--bs-danger);
}

.legend-holiday-open {
  background: var(--work-bg);
  border: 1px solid var(--bs-success);
}

.btn-icon {
  width: 38px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.folga-badge {
  background: var(--holiday-bg);
  color: var(--holiday-color);
  border: 1px dashed var(--bs-danger);
  padding: 8px 12px;
  border-radius: 999px;
  font-weight: 600;
  font-size: 0.82rem;
  display: flex;
  align-items: center;
}

.folga-badge-removable {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding-right: 8px;
}

.btn-remove-folga {
  width: 28px;
  height: 28px;
  border: none;
  border-radius: 999px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(220, 53, 69, 0.18);
  color: var(--holiday-color);
  transition: all 0.2s ease;
  flex-shrink: 0;
}

.btn-remove-folga:hover {
  background: var(--bs-danger);
  color: #fff;
  transform: scale(1.08);
}

.empty-folga-state {
  min-height: 120px;
  border: 1px dashed var(--card-border);
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  color: var(--bs-secondary-color);
  background: var(--bs-tertiary-bg);
  text-align: center;
}

.transition-all {
  transition: all 0.2s ease;
}

.hover-lift:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 25px var(--card-shadow) !important;
}

@media (max-width: 768px) {
  .custom-dark-modal {
    border-radius: 20px;
  }

  .calendar-app {
    max-width: 100%;
    padding: 16px;
  }
}

.calendar-day.past-day {
  opacity: 0.4;
  cursor: not-allowed !important;
  background-color: var(--bs-tertiary-bg) !important;
  border-color: var(--bs-border-color-translucent) !important;
  color: var(--bs-secondary-color) !important;
}

/* Cronograma de Folgas e Feriados List */
.cronograma-list {
  padding-right: 4px;
}

.cronograma-item {
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 0.75rem 1rem;
  background: rgba(var(--bs-body-color-rgb), 0.015);
  transition: all 0.2s ease;
}

.cronograma-item:hover {
  background: rgba(var(--bs-body-color-rgb), 0.03);
  transform: translateX(3px);
}

.badge-glow-neutral {
  background: rgba(var(--bs-body-color-rgb), 0.05) !important;
  color: var(--bs-body-color) !important;
  border: 1px solid var(--card-border) !important;
  border-radius: 50px;
  font-weight: 700;
}

/* Cards individuais de folgas dos funcionários */
.employee-folga-card {
  background: rgba(var(--bs-body-color-rgb), 0.005);
  border: 1px solid var(--card-border) !important;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.employee-folga-card:hover {
  background: rgba(var(--bs-body-color-rgb), 0.015);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px var(--card-shadow) !important;
}

.employee-avatar-badge {
  width: 38px;
  height: 38px;
  font-size: 1.1rem;
  border-color: var(--card-border) !important;
}


.font-11 {
  font-size: 0.72rem;
}

.font-13 {
  font-size: 0.82rem;
}

.fw-extrabold {
  font-weight: 800;
}

.btn-action-table {
  width: 36px;
  height: 36px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  border: 1px solid var(--card-border);
  background: rgba(var(--bs-body-color-rgb), 0.03);
  color: var(--bs-secondary-color);
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.btn-action-delete:hover {
  background-color: rgba(220, 53, 69, 0.1) !important;
  color: #dc3545 !important;
  border-color: rgba(220, 53, 69, 0.3) !important;
  transform: scale(1.1);
}
</style>