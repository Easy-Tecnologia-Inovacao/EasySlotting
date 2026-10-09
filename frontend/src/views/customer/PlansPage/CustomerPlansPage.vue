<template>
  <CustomerLayout>
    <div
      class="planos-page"
      :data-bs-theme="store.isDarkMode ? 'dark' : 'light'"
      :style="pageThemeVars"
    >
      <div class="container-fluid px-0">
        <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
          <div>
            <h2 class="fw-800 mb-1 dynamic-text">Pacotes Mensais</h2>
            <p class="dynamic-text opacity-75 mb-0">Gerencie seus pacotes de serviços e sessões.</p>
          </div>
        </div>

        <!-- Estado de Loading -->
        <div v-if="loading" class="text-center py-5">
          <div class="spinner-border text-primary" role="status">
            <span class="visually-hidden">Carregando...</span>
          </div>
          <p class="mt-2 dynamic-text opacity-75">Buscando seus pacotes...</p>
        </div>

        <!-- Lista de Pacotes -->
        <div v-else-if="planos.length > 0" class="d-grid gap-4">
          <div
            v-for="plano in planos"
            :key="plano.id"
            class="card border-0 shadow-sm rounded-4 p-4 plano-card"
          >
            <!-- Header do Card -->
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-3">
              <div class="flex-grow-1">
                <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                  <h4 class="fw-bold dynamic-text mb-0">{{ plano.package_name }}</h4>
                  <span class="badge rounded-pill px-3 py-2 fs-6" :class="getStatusBadgeClass(plano.status)">
                    {{ getStatusLabel(plano.status) }}
                  </span>
                </div>

                <!-- Info compacta do pacote -->
                <div class="d-flex flex-column gap-1">
                  <div class="d-flex align-items-center gap-2">
                    <i class="bi bi-scissors dynamic-text opacity-75" style="font-size: 0.85rem;"></i>
                    <span class="dynamic-text opacity-75 small"><strong>Serviço:</strong> {{ plano.service_name }}</span>
                  </div>
                  <div class="d-flex align-items-center gap-2">
                    <i class="bi bi-person dynamic-text opacity-75" style="font-size: 0.85rem;"></i>
                    <span class="dynamic-text opacity-75 small"><strong>Profissional:</strong> {{ plano.typical_employee_name || 'A definir' }}</span>
                  </div>
                  <div class="d-flex align-items-center gap-2">
                    <i class="bi bi-cash dynamic-text opacity-75" style="font-size: 0.85rem;"></i>
                    <span class="dynamic-text opacity-75 small"><strong>Valor:</strong> R$ {{ plano.total_price.toFixed(2).replace('.', ',') }} — pagamento no estabelecimento</span>
                  </div>
                </div>
              </div>

              <div class="text-end flex-shrink-0">
                <!-- Status do Pagamento -->
                <div v-if="plano.status === 'active'" class="mb-2">
                  <span 
                    class="badge rounded-pill px-3 border"
                    :class="plano.payment_status === 'paid' ? 'bg-success bg-opacity-10 text-success border-success border-opacity-25' : 'bg-warning bg-opacity-10 text-warning border-warning border-opacity-25'"
                  >
                    <i class="bi" :class="plano.payment_status === 'paid' ? 'bi-patch-check-fill' : 'bi-hourglass-split'"></i>
                    {{ plano.payment_status === 'paid' ? 'Pago' : 'Pendente' }}
                  </span>
                </div>
                <button
                  v-if="plano.status === 'active'"
                  class="btn btn-sm btn-outline-danger rounded-pill px-3 py-1 fw-bold border-0"
                  style="background: rgba(220,53,69,0.1);"
                  @click="openCancelPackageModal(plano)"
                  :disabled="cancelingPackageId === plano.id"
                >
                  <span v-if="cancelingPackageId === plano.id" class="spinner-border spinner-border-sm"></span>
                  <span v-else>Cancelar</span>
                </button>
              </div>
            </div>

            <!-- Barra de Progresso de Sessões -->
            <div class="progress-section bg-body-tertiary rounded-4 p-3 mb-4 border">
              <div class="d-flex justify-content-between align-items-center mb-2">
                <span class="fw-bold dynamic-text small text-uppercase">Uso das Sessões</span>
                <span class="fw-bold text-primary">
                  {{ plano.sessions_used }}/{{ plano.sessions_total }}
                </span>
              </div>
              <div class="progress" style="height: 10px; border-radius: 10px; background-color: var(--card-border);">
                <div 
                  class="progress-bar progress-bar-striped progress-bar-animated" 
                  role="progressbar" 
                  :style="{ width: getProgressPercentage(plano.sessions_used, plano.sessions_total) + '%' }" 
                  :class="getProgressColor(plano.sessions_used, plano.sessions_total)"
                ></div>
              </div>
              <div class="mt-2 text-end">
                <small class="dynamic-text fw-bold" :class="plano.sessions_remaining === 0 ? 'text-danger' : 'text-success'">
                  {{ plano.sessions_remaining }} {{ plano.sessions_remaining === 1 ? 'sessão restante' : 'sessões restantes' }}
                </small>
              </div>
            </div>

            <!-- ── Timeline de Sessões ── -->
            <div class="mb-2">
              <p class="small fw-bold text-uppercase mb-3" style="color: #6366f1; letter-spacing: 0.05em;">
                <i class="bi bi-calendar2-check me-2"></i>Suas Sessões
              </p>
              <div class="d-grid gap-3">

                <!-- Sessões concluídas (verde) -->
                <div
                  v-for="(usage, idx) in (plano.usages || [])"
                  :key="'usage-' + usage.id"
                  class="session-card session-card--completed"
                >
                  <div class="session-card__icon session-icon--completed">
                    <i class="bi bi-check-lg"></i>
                  </div>
                  <div class="session-card__info">
                    <h6 class="session-card__title">Sessão {{ Number(idx) + 1 }}</h6>
                    <p class="session-card__sub"><i class="bi bi-person me-1"></i>{{ usage.employee_name || 'Profissional' }}</p>
                  </div>
                  <div class="session-card__dates">
                    <div class="session-date-block">
                      <span class="session-date-label">Data</span>
                      <span class="session-date-value">{{ formatDate(usage.appointment?.appointment_date) }}</span>
                    </div>
                    <div class="session-date-block">
                      <span class="session-date-label">Horário</span>
                      <span class="session-date-value">{{ usage.appointment?.start_time }}</span>
                    </div>
                  </div>
                  <div class="session-card__actions">
                    <span class="badge rounded-pill session-badge--completed">Concluída</span>
                  </div>
                </div>

                <!-- Sessões agendadas: próxima (azul) e demais (amarelo) -->
                <div
                  v-for="(appt, idx) in (plano.pending_appointments || [])"
                  :key="'appt-' + appt.id"
                  :class="['session-card', appt.id === plano.next_appointment_id ? 'session-card--next' : 'session-card--scheduled']"
                >
                  <div :class="['session-card__icon', appt.id === plano.next_appointment_id ? 'session-icon--next' : 'session-icon--scheduled']">
                    <i :class="appt.id === plano.next_appointment_id ? 'bi bi-star-fill' : 'bi bi-clock'"></i>
                  </div>
                  <div class="session-card__info">
                    <h6 class="session-card__title">
                      Sessão {{ (plano.usages?.length || 0) + Number(idx) + 1 }}
                      <span v-if="appt.id === plano.next_appointment_id" class="ms-2 badge rounded-pill session-badge--next" style="font-size:0.6rem;">Próxima</span>
                    </h6>
                    <p class="session-card__sub"><i class="bi bi-person me-1"></i>{{ appt.employee?.name || 'Profissional' }}</p>
                  </div>
                  <div class="session-card__dates">
                    <div class="session-date-block">
                      <span class="session-date-label">Data</span>
                      <span class="session-date-value">{{ formatDate(appt.appointment_date) }}</span>
                    </div>
                    <div class="session-date-block">
                      <span class="session-date-label">Horário</span>
                      <span class="session-date-value">{{ appt.start_time }}</span>
                    </div>
                  </div>
                  <div class="session-card__actions">
                    <span :class="['badge rounded-pill mb-1', appt.id === plano.next_appointment_id ? 'session-badge--next' : 'session-badge--scheduled']">{{ getApptStatusLabel(appt.status) }}</span>
                    <button
                      class="btn btn-sm rounded-pill px-3 fw-bold session-reschedule-btn"
                      @click="openRescheduleModal(appt, plano)"
                    >
                      <i class="bi bi-calendar-event me-1"></i>Reagendar
                    </button>
                  </div>
                </div>

                <!-- Slots vazios (sessões ainda não agendadas) -->
                <template v-if="plano.status === 'active'">
                  <div
                    v-for="n in Math.max(0, plano.sessions_remaining - (plano.pending_appointments?.length || 0))"
                    :key="'empty-' + n"
                    class="session-card session-card--empty"
                  >
                    <div class="session-card__icon session-icon--empty">
                      <i class="bi bi-calendar-plus"></i>
                    </div>
                    <div class="session-card__info">
                      <h6 class="session-card__title">Sessão {{ (plano.usages?.length || 0) + (plano.pending_appointments?.length || 0) + Number(n) }}</h6>
                      <p class="session-card__sub opacity-50">Não agendada</p>
                    </div>
                    <div class="session-card__dates"></div>
                    <div class="session-card__actions">
                      <button
                        class="btn btn-sm rounded-pill px-3 fw-bold"
                        style="background: rgba(99,102,241,0.1); color:#6366f1; border:1px solid rgba(99,102,241,0.3);"
                        @click="openNewSessionModal(plano)"
                      >
                        <i class="bi bi-plus-circle me-1"></i>Agendar
                      </button>
                    </div>
                  </div>
                </template>

              </div>
            </div>
          </div>
        </div>

        <!-- Estado Vazio -->
        <div v-else class="text-center py-5 empty-state">
            <div class="mb-4">
              <i class="bi bi-star text-secondary opacity-50" style="font-size: 4rem;"></i>
            </div>
            <h4 class="fw-bold dynamic-text mb-2">Nenhum pacote encontrado</h4>
            <p class="dynamic-text opacity-75 mb-0">Você ainda não possui pacotes mensais ativos.</p>
            <router-link :to="{ name: 'agendamento', params: { slug: currentSlug } }" class="btn custom-btn rounded-pill px-4 mt-4 fw-bold shadow-sm">
              Agendar Agora
            </router-link>
          </div>

          <!-- Alerta inline para erros globais -->
          <div v-if="pageError" class="alert-inline alert-inline--error my-4">
            <i class="bi bi-exclamation-circle-fill me-2"></i>{{ pageError }}
          </div>
          <div v-if="listSuccess" class="alert-inline alert-inline--success my-4">
            <i class="bi bi-check-circle-fill me-2"></i>{{ listSuccess }}
          </div>

    <!-- Modal Único: Reagendar Sessão / Agendar Nova Sessão -->
    <div class="modal fade" id="modalReagendar" tabindex="-1" aria-hidden="true" ref="modalReagendarRef">
      <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
        <div class="modal-content" :data-bs-theme="store.isDarkMode ? 'dark' : 'light'" :style="pageThemeVars">
          <div class="modal-header border-bottom-0 pb-0">
            <div>
              <h5 class="modal-title fw-bold dynamic-text mb-0">
                <span v-if="modalMode === 'new_session'"><i class="bi bi-plus-circle me-2 text-primary"></i>Agendar Nova Sessão</span>
                <span v-else><i class="bi bi-calendar-range me-2" style="color:#6366f1"></i>Reagendar Sessão</span>
              </h5>
              <p class="small dynamic-text opacity-75 mb-0 mt-1" v-if="currentPlanForReschedule">
                {{ currentPlanForReschedule.package_name }} • {{ currentPlanForReschedule.service_name }}
              </p>
            </div>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body custom-scrollbar pt-3">


            <!-- 1. Escolha o Profissional -->
            <section class="mb-4">
              <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
                1. Escolha o Profissional
              </label>
              <div class="colab-container pb-2 custom-scrollbar d-flex gap-3 overflow-auto">
                <div 
                  v-for="emp in availableEmployeesForService"
                  :key="emp.id"
                  class="colab-select-card shadow-sm flex-shrink-0"
                  :class="{ active: selectedEmployeeId === emp.id }"
                  @click="selectEmployee(emp.id)"
                  style="min-width: 140px;"
                >
                  <div class="avatar-placeholder fs-4">
                    <i class="bi bi-person"></i>
                  </div>
                  <span class="fw-bold small mb-1 dynamic-text colab-text text-center">
                    {{ emp.name }}
                  </span>
                  <span class="small dynamic-text opacity-75 colab-text" style="font-size: 0.7rem;">
                    {{ emp.role_label || 'Profissional' }}
                  </span>
                </div>
                <div v-if="loadingEmployees" class="p-3 text-center w-100">
                  <div class="spinner-border spinner-border-sm text-primary"></div>
                </div>
              </div>
            </section>

            <!-- 3. Dia -->
            <section class="mb-4" v-if="selectedEmployeeId">
              <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
                2. Escolha o Dia
              </label>
              <div class="d-flex align-items-center gap-2 gap-md-3">
                <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollList(dateScrollRef, -1)">
                  <i class="bi bi-chevron-left fs-5"></i>
                </button>
                <div class="date-container pb-2 flex-grow-1" ref="dateScrollRef">
                  <div
                    v-for="(date, index) in availableDates"
                    :key="index"
                    class="date-card shadow-sm flex-shrink-0"
                    :class="[
                      { active: selectedDate === date.apiDate },
                      { 'opacity-50 pointer-events-none': 
                        (occupiedWeeks.has(getSundayOfDate(date.apiDate)) && selectedDate !== date.apiDate) ||
                        (rescheduleBounds.min && date.apiDate <= rescheduleBounds.min) ||
                        (rescheduleBounds.max && date.apiDate >= rescheduleBounds.max)
                      }
                    ]"
                    @click="selectDate(date.apiDate)"
                  >
                    <span class="small dynamic-text date-text opacity-75 mb-1">{{ date.weekDay }}</span>
                    <span class="fw-bold fs-4 dynamic-text date-text lh-1">{{ date.dayNumber }}</span>
                    <span class="small dynamic-text date-text opacity-75 mt-1">{{ date.monthName }}</span>
                  </div>
                  <div v-if="loadingAvailableDays" class="d-flex align-items-center gap-2 p-2">
                    <div class="spinner-border spinner-border-sm text-primary"></div>
                    <span class="small text-muted">Carregando...</span>
                  </div>
                  <div v-if="!loadingAvailableDays && availableDates.length === 0" class="small text-muted p-2">Nenhum dia disponível.</div>
                </div>
                <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollList(dateScrollRef, 1)">
                  <i class="bi bi-chevron-right fs-5"></i>
                </button>
              </div>
            </section>

            <!-- 4. Hora -->
            <section class="mb-2" v-if="selectedDate">
              <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
                3. Escolha o Horário
              </label>
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
                 <div class="spinner-border spinner-border-sm text-primary"></div>
                 <span class="small text-muted ms-2">Buscando horários...</span>
              </div>
              <div v-if="!loadingAvailability && selectedDate && allTimesForDisplay.length === 0" class="small text-muted mt-3">Nenhum horário disponível neste dia.</div>
            </section>

          </div><!-- fim modal-body -->

          <div class="modal-footer border-top-0 pb-4 pt-2 flex-column align-items-stretch gap-2">
            <!-- Alerta inline do modal -->
            <div v-if="modalError" class="alert-inline alert-inline--error">
              <i class="bi bi-exclamation-circle-fill me-2"></i>{{ modalError }}
            </div>
            <div v-if="modalSuccess" class="alert-inline alert-inline--success">
              <i class="bi bi-check-circle-fill me-2"></i>{{ modalSuccess }}
            </div>

            <!-- Aviso de Pagamento -->
            <div 
              v-if="modalMode === 'new_session' && currentPlanForReschedule && currentPlanForReschedule.sessions_used === 0" 
              class="mb-2 p-2 rounded-3 bg-info bg-opacity-10 border border-info border-opacity-25"
            >
              <div class="d-flex align-items-center gap-2 text-info">
                <i class="bi bi-info-circle-fill small"></i>
                <span class="small fw-bold">Aviso de Pagamento</span>
              </div>
              <p class="small mb-0 opacity-75 dynamic-text" style="font-size: 0.8rem;">
                Como esta é a <strong>primeira sessão</strong> do novo ciclo, o pagamento do pacote será realizado no estabelecimento.
              </p>
            </div>

            <div class="d-flex gap-2 justify-content-end">
              <button type="button" class="btn btn-outline-secondary rounded-pill px-4 fw-bold" data-bs-dismiss="modal">Cancelar</button>
              <button
                type="button"
                class="btn custom-btn rounded-pill px-4 fw-bold"
                @click="confirmModalAction"
                :disabled="loadingSubmit || !selectedDate || !selectedTime"
              >
                <span v-if="loadingSubmit" class="spinner-border spinner-border-sm me-2" role="status"></span>
                <span v-if="!loadingSubmit">
                  <span v-if="modalMode === 'new_session'">Agendar Sessão</span>
                  <span v-else>Confirmar Novo Horário</span>
                </span>
                <span v-else>Salvando...</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Cancelamento de Pacote -->
    <div class="modal fade" id="modalCancelPackage" tabindex="-1" aria-hidden="true" ref="modalCancelPackageRef">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content" :data-bs-theme="store.isDarkMode ? 'dark' : 'light'" :style="pageThemeVars">
          <div class="modal-header border-bottom-0 pb-0">
            <h5 class="modal-title fw-bold dynamic-text text-danger mb-0">
              <i class="bi bi-exclamation-triangle me-2"></i>Cancelar Pacote
            </h5>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body pt-3">
            <p class="dynamic-text opacity-75 small mb-4">
              Tem certeza que deseja cancelar este pacote permanentemente? Todas as sessões pendentes serão desmarcadas e você não poderá mais usá-lo.
            </p>
            <div class="mb-3">
              <label class="form-label small fw-bold dynamic-text opacity-75">Por que você está cancelando?</label>
              <select v-model="cancelReasonType" class="form-select custom-input dynamic-text border-1">
                <option value="">Selecione um motivo...</option>
                <option value="Financeiro">Motivos financeiros</option>
                <option value="Viagem">Mudança ou viagem</option>
                <option value="Insatisfação">Insatisfação com o serviço</option>
                <option value="Outro">Outro motivo</option>
              </select>
            </div>
            <div class="mb-3">
              <label class="form-label small fw-bold dynamic-text opacity-75">Detalhes adicionais (opcional)</label>
              <textarea v-model="cancelReasonText" class="form-control custom-input dynamic-text" rows="3" placeholder="Escreva aqui..." maxlength="300"></textarea>
              <div class="text-end mt-1">
                <small class="text-muted" :class="{ 'text-danger fw-bold': cancelReasonText.length >= 280 }">
                  {{ cancelReasonText.length }}/300
                </small>
              </div>
            </div>
            <div class="mb-3" v-if="packageToCancel">
              <label class="form-label small fw-bold dynamic-text opacity-75">
                Para confirmar, digite <strong>CONFIRMAR</strong>
              </label>
              <input
                v-model="cancelConfirmName"
                type="text"
                class="form-control custom-input dynamic-text border-1"
                placeholder="CONFIRMAR"
                autocomplete="off"
              />
            </div>
          </div>
          <div class="modal-footer border-top-0 pt-0">
            <button type="button" class="btn btn-light rounded-pill px-4 fw-bold shadow-sm" data-bs-dismiss="modal">
              Voltar
            </button>
            <button
              type="button"
              class="btn btn-danger rounded-pill px-4 fw-bold shadow-sm"
              @click="confirmCancelPackage"
              :disabled="!cancelReasonType || cancelConfirmName !== 'CONFIRMAR' || cancelingPackageId !== null"
            >
              <span v-if="cancelingPackageId !== null" class="spinner-border spinner-border-sm me-2"></span>
              Confirmar Cancelamento
            </button>
          </div>
        </div>
      </div>
    </div> <!-- Fim do Modal -->

    </div> <!-- container-fluid -->
  </div> <!-- planos-page -->
</CustomerLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useThemeStore } from '@/stores/themeStore'
import { api } from '@/services/api'
import CustomerLayout from '@/views/customer/Layout/CustomerLayout.vue'
import { Modal } from 'bootstrap'

const store = useThemeStore()
const route = useRoute()

const planos = ref<any[]>([])
const loading = ref(true)
const pageError = ref('')

const currentSlug = computed(() => {
  return String(
    route.params.slug ||
    sessionStorage.getItem('site-slug') ||
    localStorage.getItem('site-slug') ||
    ''
  )
})

const pageThemeVars = computed(() => ({
  '--button-bg': store.themeConfig.buttonBg,
  '--button-hover': store.themeConfig.buttonHover,
  '--custom-text-color': store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight,
  '--bs-tertiary-bg': store.isDarkMode ? store.themeConfig.cardDark : store.themeConfig.cardLight,
  '--card-border': store.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'
}))

const fetchPlanos = async () => {
  loading.value = true
  pageError.value = ''
  
  try {
    const response = await api.get('/customer/service_packages')
    planos.value = response.data
  } catch (error: any) {
    console.error('Erro ao buscar planos:', error)
    pageError.value = 'Não foi possível carregar seus pacotes mensais. Tente novamente mais tarde.'
  } finally {
    loading.value = false
  }
}

// ==========================================
// LÓGICA DE REAGENDAMENTO / CANCELAMENTO
// ==========================================
const cancelingPackageId = ref<number | null>(null)
const listSuccess = ref('')
const modalError = ref('')
const modalSuccess = ref('')
const loadingSubmit = ref(false)

// Escopo do reagendamento: 'single' = só esta sessão | 'forever' = mudar para sempre (todas pendentes)
const rescheduleScope = ref<'single' | 'forever'>('single')
// Modo do modal: 'reschedule' = reagendar sessão existente | 'new_session' = agendar nova sessão
const modalMode = ref<'reschedule' | 'new_session'>('reschedule')
// Plano atual do modal
const currentPlanForReschedule = ref<any>(null)
// Todas as sessões pendentes do plano
const pendingAppointmentsForReschedule = ref<any[]>([])


const modalReagendarRef = ref<HTMLElement | null>(null)
let bootstrapModal: Modal | null = null
const selectedAppointment = ref<any>(null)

// ── LÓGICA DE SERVIÇOS E PROFISSIONAIS ──
const availableServices = ref<any[]>([])
const employees = ref<any[]>([])
const employeeServices = ref<any[]>([])
const loadingEmployees = ref(false)
const selectedServiceId = ref<number | null>(null)
const selectedEmployeeId = ref<number | null>(null)

const availableEmployeesForService = computed(() => {
  if (!selectedServiceId.value) return []
  
  return employees.value.filter(emp => {
    return employeeServices.value.some(es => es.employee_id === emp.id && es.service_id === selectedServiceId.value)
  })
})

const fetchBookingData = async () => {
  loadingEmployees.value = true
  try {
    const slug = currentSlug.value
    if (!slug) return
    const { data } = await api.get(`/public/establishments/${slug}/booking_data`)
    availableServices.value = data.services || []
    employees.value = data.employees || []
    employeeServices.value = data.employee_services || []
  } catch (error) {
    console.error('Erro ao buscar dados do estabelecimento:', error)
  } finally {
    loadingEmployees.value = false
  }
}

// Todos os planos do cliente (exceto cancelados) — permite trocar de pacote livremente
const todosPlanos = computed(() => planos.value.filter((p: any) => p.status !== 'canceled'))

// Planos com sessões disponíveis (para validação na criação de nova sessão)
const planosAtivos = computed(() => planos.value.filter((p: any) => p.status === 'active' && p.sessions_remaining > 0))

// Plano selecionado no modal
const selectedPlanId = ref<number | null>(null)

const selectPlan = (plano: any) => {
  selectedPlanId.value = plano.id
  selectedServiceId.value = plano.service_id
  selectedEmployeeId.value = null
  selectedDate.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
}

const selectService = (id: number) => {
  selectedServiceId.value = id
  selectedEmployeeId.value = null
  selectedDate.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
}

const selectEmployee = async (id: number) => {
  selectedEmployeeId.value = id
  selectedDate.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
  
  const slug = currentSlug.value
  const serviceId = selectedServiceId.value
    
  if (slug && serviceId && id) {
    await fetchAvailableDays(slug, serviceId, id)
  }
}

interface DateItem {
  dayNumber: number
  monthName: string
  weekDay: string
  apiDate: string
}

const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
const weekDays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']

const availableDaysFromApi = ref<string[]>([])
const availableDates = ref<DateItem[]>([])
const loadingAvailableDays = ref(false)

const availableTimes = ref<string[]>([])
const occupiedTimes = ref<string[]>([])
const loadingAvailability = ref(false)

const selectedDate = ref('')
const selectedTime = ref('')
const dateScrollRef = ref<HTMLElement | null>(null)

const allTimesForDisplay = computed<string[]>(() => {
  const unique = [...new Set([...availableTimes.value, ...occupiedTimes.value])]
  return unique.sort((a, b) => a.localeCompare(b))
})

const getTodayString = () => {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
}

const getCurrentTimeHHMM = () => {
  const now = new Date()
  return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
}

const isPastTimeForSelectedDate = (time: string) => {
  if (!selectedDate.value) return false
  if (selectedDate.value !== getTodayString()) return false
  return time < getCurrentTimeHHMM()
}

const canSelectTime = (time: string) => {
  return !occupiedTimes.value.includes(time) && !isPastTimeForSelectedDate(time)
}

const scrollList = (elementRef: HTMLElement | null, direction: number) => {
  if (elementRef) {
    elementRef.scrollBy({ left: direction * 200, behavior: 'smooth' })
  }
}

const buildAvailableDates = () => {
  const result: DateItem[] = []
  for (const apiDate of availableDaysFromApi.value) {
    const parts = apiDate.split('-')
    if (parts.length !== 3) continue
    const year = Number(parts[0])
    const month = Number(parts[1])
    const day = Number(parts[2])
    if (Number.isNaN(year) || Number.isNaN(month) || Number.isNaN(day)) continue
    
    const d = new Date(year, month - 1, day)
    result.push({
      dayNumber: d.getDate(),
      monthName: months[d.getMonth()] ?? '',
      weekDay: weekDays[d.getDay()] ?? '',
      apiDate
    })
  }
  availableDates.value = result
}

const fetchAvailability = async (slug: string, serviceId: number, employeeId: number, date: string) => {
  loadingAvailability.value = true
  try {
    const { data } = await api.get(`/public/establishments/${slug}/available_slots`, {
      params: { service_id: serviceId, employee_id: employeeId, date }
    })
    availableTimes.value = Array.isArray(data.available_slots) ? data.available_slots : []
    occupiedTimes.value = Array.isArray(data.occupied_slots) ? data.occupied_slots : []
  } catch (error) {
    console.error('Erro ao buscar disponibilidade:', error)
    availableTimes.value = []
    occupiedTimes.value = []
  } finally {
    loadingAvailability.value = false
  }
}

const fetchAvailableDays = async (slug: string, serviceId: number, employeeId: number) => {
  loadingAvailableDays.value = true
  try {
    const { data } = await api.get(`/public/establishments/${slug}/available_days`, {
      params: { service_id: serviceId, employee_id: employeeId, days_ahead: 30 }
    })
    availableDaysFromApi.value = Array.isArray(data.available_days) ? data.available_days.map((item: any) => item.date) : []
    buildAvailableDates()
    
    if (availableDates.value.length > 0) {
      const today = getTodayString()
      const todayExists = availableDates.value.find((d) => d.apiDate === today)
      selectedDate.value = todayExists ? today : (availableDates.value[0]?.apiDate || '')
      await fetchAvailability(slug, serviceId, employeeId, selectedDate.value)
    }
  } catch (error) {
    console.error('Erro ao buscar dias disponíveis:', error)
    availableDaysFromApi.value = []
    availableDates.value = []
  } finally {
    loadingAvailableDays.value = false
  }
}

const getSundayOfDate = (dateStr: string) => {
  const d = new Date(dateStr + 'T12:00:00')
  const diff = d.getDate() - d.getDay()
  const sunday = new Date(d.setDate(diff))
  return `${sunday.getFullYear()}-${String(sunday.getMonth() + 1).padStart(2, '0')}-${String(sunday.getDate()).padStart(2, '0')}`
}

const occupiedWeeks = computed<Set<string>>(() => {
  if (!currentPlanForReschedule.value || !currentPlanForReschedule.value.pending_appointments) return new Set()
  
  const appointments = currentPlanForReschedule.value.pending_appointments
  return new Set(
    appointments
      .filter((a: any) => a.id !== selectedAppointment.value?.id) // ignora a própria sessão se for reagendamento
      .map((a: any) => getSundayOfDate(a.appointment_date))
  )
})

const addOneMonthToDate = (dateStr: string) => {
  const parts = dateStr.split('-')
  if (parts.length !== 3) return ''
  const year = Number(parts[0])
  const month = Number(parts[1])
  const day = Number(parts[2])
  const d = new Date(year, month - 1, day)
  d.setMonth(d.getMonth() + 1)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const r = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${r}`
}

const subtractOneMonthFromDate = (dateStr: string) => {
  const parts = dateStr.split('-')
  if (parts.length !== 3) return ''
  const year = Number(parts[0])
  const month = Number(parts[1])
  const day = Number(parts[2])
  const d = new Date(year, month - 1, day)
  d.setMonth(d.getMonth() - 1)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const r = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${r}`
}

const rescheduleBounds = computed(() => {
  if (!currentPlanForReschedule.value) return { min: '', max: '' }
  
  const allAppointments = [
    ...(currentPlanForReschedule.value.usages?.map((u: any) => u.appointment) || []),
    ...(currentPlanForReschedule.value.pending_appointments || [])
  ].filter(a => a && a.appointment_date)
  
  allAppointments.sort((a, b) => a.appointment_date.localeCompare(b.appointment_date))
  
  let min = ''
  let max = ''
  
  if (modalMode.value === 'new_session') {
    if (allAppointments.length > 0) {
      min = allAppointments[allAppointments.length - 1].appointment_date
    }
  } else if (selectedAppointment.value) {
    const currentIndex = allAppointments.findIndex(a => a.id === selectedAppointment.value?.id)
    if (currentIndex !== -1 && allAppointments.length > 0) {
      const seqMin = currentIndex > 0 ? allAppointments[currentIndex - 1].appointment_date : ''
      const seqMax = currentIndex < allAppointments.length - 1 ? allAppointments[currentIndex + 1].appointment_date : ''
      
      // Para o min, usa o domingo da semana da sessão anterior (permite reagendar dentro da mesma semana)
      min = seqMin ? getSundayOfDate(seqMin) : ''
      max = seqMax || ''
    }
  }
  
  return { min, max }
})

const selectDate = async (date: string) => {
  const newSunday = getSundayOfDate(date)
  if (occupiedWeeks.value.has(newSunday)) {
    modalError.value = 'O pacote permite apenas uma sessão por semana. Você já possui uma sessão nesta semana.'
    
    // Auto-hide do erro após 4 segundos
    setTimeout(() => {
      if (modalError.value.includes('sessão por semana')) {
        modalError.value = ''
      }
    }, 4000)
    return
  }

  if (rescheduleBounds.value.min && newSunday <= rescheduleBounds.value.min) {
    modalError.value = 'Esta sessão não pode ser agendada em uma semana anterior ou igual à sessão anterior do pacote.'
    setTimeout(() => { if (modalError.value.includes('sessão anterior')) modalError.value = '' }, 4000)
    return
  }
  if (rescheduleBounds.value.max && date >= rescheduleBounds.value.max) {
    modalError.value = 'Esta sessão não pode ser agendada após ou no mesmo dia da próxima sessão do pacote.'
    setTimeout(() => { if (modalError.value.includes('próxima sessão')) modalError.value = '' }, 4000)
    return
  }

  modalError.value = ''
  selectedDate.value = date
  selectedTime.value = ''

  // Para nova sessão: usa dados do plano mas permite trocar
  if (modalMode.value === 'new_session' && currentPlanForReschedule.value) {
    const slug = currentSlug.value
    if (slug && selectedServiceId.value && selectedEmployeeId.value) {
      await fetchAvailability(slug, selectedServiceId.value, selectedEmployeeId.value, date)
    }
    return
  }

  // Para reagendamento: usa dados do agendamento selecionado
  if (selectedAppointment.value) {
    const slug = selectedAppointment.value?.establishment?.slug
    if (slug && selectedServiceId.value && selectedEmployeeId.value) {
      await fetchAvailability(slug, selectedServiceId.value, selectedEmployeeId.value, date)
    }
  }
}

const modalCancelPackageRef = ref<HTMLElement | null>(null)
let bsModalCancelPackage: any = null

const packageToCancel = ref<any>(null)
const cancelReasonType = ref('')
const cancelReasonText = ref('')
const cancelConfirmName = ref('')

const openCancelPackageModal = (plano: any) => {
  packageToCancel.value = plano
  cancelReasonType.value = ''
  cancelReasonText.value = ''
  cancelConfirmName.value = ''
  
  if (modalCancelPackageRef.value) {
    if (!bsModalCancelPackage) {
      bsModalCancelPackage = new Modal(modalCancelPackageRef.value)
    }
    bsModalCancelPackage.show()
  }
}

const confirmCancelPackage = async () => {
  if (!packageToCancel.value || !cancelReasonType.value) return

  pageError.value = ''
  listSuccess.value = ''
  cancelingPackageId.value = packageToCancel.value.id

  let reason = cancelReasonType.value
  if (cancelReasonText.value.trim() !== '') {
    reason += `: ${cancelReasonText.value.trim()}`
  }

  try {
    await api.patch(`/customer/service_packages/${packageToCancel.value.id}/cancel`, {
      cancellation_reason: reason
    })
    listSuccess.value = 'Pacote cancelado com sucesso.'
    if (bsModalCancelPackage) bsModalCancelPackage.hide()
    await fetchPlanos()
  } catch (error: any) {
    pageError.value = error.response?.data?.error || 'Erro ao cancelar o pacote.'
  } finally {
    cancelingPackageId.value = null
  }
}

const openRescheduleModal = async (appointment: any, plano?: any) => {
  modalMode.value = 'reschedule'
  selectedAppointment.value = appointment
  selectedDate.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
  occupiedTimes.value = []
  modalError.value = ''
  modalSuccess.value = ''
  rescheduleScope.value = 'single'

  // Pré-seleciona o plano da sessão, mas re-busca TODOS os planos para o carrossel
  selectedPlanId.value = plano?.id ?? null
  selectedServiceId.value = appointment.service_id
  selectedEmployeeId.value = appointment.employee_id

  if (plano) {
    currentPlanForReschedule.value = plano
    pendingAppointmentsForReschedule.value = plano.pending_appointments ?? []
  } else {
    currentPlanForReschedule.value = null
    pendingAppointmentsForReschedule.value = [appointment]
  }

  openModal()
  
  // Busca em paralelo: todos os planos do cliente + dados de agenda (funcionários/slots)
  await Promise.all([fetchPlanos(), fetchBookingData()])

  const slug = appointment.establishment?.slug || currentSlug.value
  if (slug && selectedServiceId.value && selectedEmployeeId.value) {
    await fetchAvailableDays(slug, selectedServiceId.value, selectedEmployeeId.value)
  }
}

// Abre o modal no modo "Nova Sessão" (sem agendamento existente)
const openNewSessionModal = async (plano: any) => {
  modalMode.value = 'new_session'
  selectedAppointment.value = null
  selectedDate.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
  occupiedTimes.value = []
  modalError.value = ''
  modalSuccess.value = ''
  currentPlanForReschedule.value = plano
  pendingAppointmentsForReschedule.value = []

  // Pré-seleciona o plano que acionou o modal
  selectedPlanId.value = plano.id
  selectedServiceId.value = plano.service_id
  selectedEmployeeId.value = plano.typical_employee_id

  openModal()

  // Busca em paralelo: todos os planos do cliente + dados de agenda (funcionários/slots)
  await Promise.all([fetchPlanos(), fetchBookingData()])

  const slug = currentSlug.value
  if (slug && selectedServiceId.value && selectedEmployeeId.value) {
    await fetchAvailableDays(slug, selectedServiceId.value, selectedEmployeeId.value)
  }
}

const openModal = () => {
  if (modalReagendarRef.value) {
    if (!bootstrapModal) bootstrapModal = new Modal(modalReagendarRef.value)
    bootstrapModal.show()
  }
}

// Retorna a próxima sessão (a mais próxima por data) de um plano
const getNextAppointment = (plano: any) => {
  const pending = plano.pending_appointments
  if (!pending || pending.length === 0) return null
  return pending.reduce((nearest: any, appt: any) => {
    if (!nearest) return appt
    return appt.appointment_date < nearest.appointment_date ? appt : nearest
  }, null)
}

const confirmModalAction = async () => {
  modalError.value = ''
  modalSuccess.value = ''

  if (!selectedPlanId.value || !selectedDate.value || !selectedTime.value || !selectedServiceId.value || !selectedEmployeeId.value) {
    modalError.value = 'Selecione o pacote, profissional, data e horário.'
    return
  }

  // Obtém o plano selecionado entre todos os planos do cliente
  const planoSelecionado = planos.value.find((p: any) => p.id === selectedPlanId.value)
  if (!planoSelecionado) {
    modalError.value = 'Pacote selecionado inválido.'
    return
  }

  // Validação de sessões: apenas na criação de nova sessão
  if (modalMode.value === 'new_session' && (planoSelecionado.status !== 'active' || planoSelecionado.sessions_remaining <= 0)) {
    modalError.value = 'Este pacote não possui sessões disponíveis para agendamento.'
    return
  }

  loadingSubmit.value = true

  try {
    if (modalMode.value === 'new_session') {
      // ── NOVA SESSÃO: cria novo agendamento vinculado ao plano escolhido ──
      await api.post('/customer/appointments', {
        service_id:         selectedServiceId.value,
        service_package_id: planoSelecionado.service_package_id,
        employee_id:        selectedEmployeeId.value,
        appointment_date:   selectedDate.value,
        start_time:         selectedTime.value
      })
      modalSuccess.value = 'Sessão agendada com sucesso!'
      listSuccess.value = 'Sessão agendada com sucesso!'

    } else {
      // ── REAGENDAR: patch somente no agendamento selecionado ──
      await api.patch(`/customer/appointments/${selectedAppointment.value.id}/reschedule`, {
        appointment_date: selectedDate.value,
        start_time:       selectedTime.value,
        service_id:       selectedServiceId.value,
        employee_id:      selectedEmployeeId.value
      })
      modalSuccess.value = 'Sessão reagendada com sucesso!'
      listSuccess.value = 'Sessão reagendada com sucesso!'
    }

    setTimeout(() => {
      if (bootstrapModal) bootstrapModal.hide()
      fetchPlanos()
    }, 900)
  } catch (error: any) {
    modalError.value = error.response?.data?.error || 'Erro ao processar o agendamento.'
  } finally {
    loadingSubmit.value = false
  }
}

// Helpers de formatação e status

/**
 * Converte "YYYY-MM-DD" para "DD/MM/YYYY" sem usar `new Date()`, que causaria
 * um UTC-to-local shift e poderia mostrar o dia anterior em fusos negativos.
 */
const formatDate = (dateString: string) => {
  if (!dateString) return ''
  const parts = dateString.split('-')
  if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`
  return dateString
}

/**
 * Normaliza qualquer formato de hora ("HH:MM", "HH:MM:SS", ISO completa)
 * para sempre retornar "HH:MM" de forma segura.
 */
const formatTime = (value: string): string => {
  if (!value) return '--:--'
  if (/^\d{2}:\d{2}/.test(value)) return value.substring(0, 5)
  const isoMatch = value.match(/T(\d{2}:\d{2})/)
  if (isoMatch) return isoMatch[1] ?? value
  return value
}

const formatDateTime = (dateString: string) => {
  if (!dateString) return ''
  if (/^\d{4}-\d{2}-\d{2}$/.test(dateString)) {
    return formatDate(dateString)
  }
  const dateObj = new Date(dateString)
  if (isNaN(dateObj.getTime())) return dateString
  const dateStr = dateObj.toLocaleDateString('pt-BR')
  const timeStr = dateObj.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
  return `${dateStr} às ${timeStr}`
}

/**
 * Extrai a data de uma string ISO completa → "DD/MM/YYYY"
 * Trata tanto "YYYY-MM-DD" quanto ISO com timezone (ex: "2026-05-12T20:02:59.334-03:00")
 */
const formatIsoDate = (value: string): string => {
  if (!value) return '—'
  // Se já é só data
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return formatDate(value)
  // Extrai a parte de data do ISO sem passar pelo UTC (evita shift de dia)
  const match = value.match(/^(\d{4})-(\d{2})-(\d{2})/)
  if (match) return `${match[3]}/${match[2]}/${match[1]}`
  return value
}

/**
 * Extrai a hora de uma string ISO completa → "HH:MM"
 * Respeitando o fuso da string (não converte para UTC).
 */
const formatIsoTime = (value: string): string => {
  if (!value) return '—'
  // ISO com timezone: "2026-05-12T20:02:59.334-03:00" → pega HH:MM do T
  const isoMatch = value.match(/T(\d{2}):(\d{2})/)
  if (isoMatch) return `${isoMatch[1]}:${isoMatch[2]}`
  // Só data, sem hora
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return '—'
  return '—'
}

const getStatusLabel = (status: string) => {
  const map: Record<string, string> = {
    active: 'Ativo',
    completed: 'Finalizado',
    canceled: 'Cancelado',
    expired: 'Expirado'
  }
  return map[status] || status
}

const getStatusBadgeClass = (status: string) => {
  const map: Record<string, string> = {
    active: 'text-bg-success',
    completed: 'text-bg-secondary',
    canceled: 'text-bg-danger',
    expired: 'text-bg-warning'
  }
  return map[status] || 'text-bg-primary'
}

const getProgressPercentage = (used: number, total: number) => {
  if (!total || total === 0) return 0
  const percentage = (used / total) * 100
  return Math.min(percentage, 100)
}

const getProgressColor = (used: number, total: number) => {
  if (!total || total === 0) return 'bg-secondary'
  const percentage = (used / total) * 100
  if (percentage >= 100) return 'bg-success'
  if (percentage >= 80) return 'bg-warning'
  return 'bg-primary'
}

const getApptStatusLabel = (status: string) => {
  const map: Record<string, string> = {
    pending: 'Agendada',
    confirmed: 'Confirmada',
    completed: 'Concluída',
    canceled: 'Cancelada',
    used: 'Utilizada'
  }
  return map[status] || status
}

const getApptStatusBadgeClass = (status: string) => {
  const map: Record<string, string> = {
    pending: 'text-bg-warning',
    confirmed: 'text-bg-primary',
    completed: 'text-bg-success',
    canceled: 'text-bg-danger',
    used: 'text-bg-secondary opacity-75'
  }
  return map[status] || 'text-bg-secondary'
}

onMounted(() => {
  fetchPlanos()
})
</script>

<style scoped>
.plano-card {
  background: var(--bs-tertiary-bg);
  border: 1px solid var(--card-border) !important;
}

/* Card da próxima sessão */
.next-session-card {
  background: rgba(99, 102, 241, 0.06);
  border: 1px solid rgba(99, 102, 241, 0.25);
  border-radius: 16px;
  padding: 1rem 1.25rem;
}

.next-session-empty {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
  background: var(--bs-tertiary-bg);
  border: 1.5px dashed var(--card-border) !important;
  padding: 0.85rem 1.25rem;
}

/* Opções de escopo do reagendamento (radio pills) */
.reschedule-scope-option {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.45rem 1rem;
  border: 1.5px solid var(--card-border);
  border-radius: 999px;
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  background: var(--bs-body-bg);
  color: var(--bs-body-color);
  transition: all 0.18s ease;
  user-select: none;
}

.reschedule-scope-option:hover {
  border-color: #6366f1;
  color: #6366f1;
}

.reschedule-scope-option.active {
  background: rgba(99, 102, 241, 0.1);
  border-color: #6366f1;
  color: #6366f1;
}

.custom-outline-btn {
  color: var(--button-bg) !important;
  border-color: var(--button-bg) !important;
  background: transparent !important;
  transition: all 0.3s ease;
}

.custom-outline-btn:hover {
  background-color: var(--button-hover) !important;
  border-color: var(--button-hover) !important;
  color: #fff !important;
}

.custom-btn {
  background-color: var(--button-bg);
  color: #fff;
  border: none;
  transition: all 0.3s ease;
}

.custom-btn:hover {
  background-color: var(--button-hover);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.dynamic-text {
  color: var(--custom-text-color) !important;
}

.alert-inline {
  border-radius: 12px;
  padding: 10px 14px;
  font-size: 0.85rem;
  font-weight: 600;
  display: flex;
  align-items: center;
}

.alert-inline--error {
  background: rgba(220, 53, 69, 0.1);
  border: 1px solid rgba(220, 53, 69, 0.25);
  color: #dc3545;
}

[data-bs-theme='dark'] .alert-inline--error {
  background: rgba(220, 53, 69, 0.15);
  color: #f88;
}

.progress-section {
  border-color: var(--card-border) !important;
}

/* Chips de informação do plano (Adquirido / Expira) */
.plan-info-chip {
  display: inline-flex;
  flex-direction: column;
  gap: 3px;
  background: var(--bs-tertiary-bg);
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 8px 14px;
  min-width: 130px;
}

.plan-info-label {
  font-size: 0.7rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--bs-secondary-color);
  opacity: 0.8;
}

.plan-info-value {
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--bs-body-color);
}

/* Modal UI Styles from AgendamentoView */
.modal-content {
  background: var(--bs-tertiary-bg);
  border: 1px solid var(--card-border);
  border-radius: 20px;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(100, 100, 100, 0.2);
  border-radius: 10px;
}

.service-selection-card {
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  border-radius: 16px;
  cursor: default;
  transition: all 0.2s;
}

/* Card de seleção de serviço destravado */
.service-select-card-mini {
  transition: all 0.2s ease;
}

.service-select-card-mini:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0,0,0,0.08) !important;
}

.service-select-card-mini.active {
  border-color: var(--button-bg) !important;
  background: var(--button-bg) !important;
  box-shadow: 0 8px 16px rgba(0,0,0,0.1) !important;
}

.service-select-card-mini.active .dynamic-text,
.service-select-card-mini.active .icon-box-mini {
  color: #fff !important;
}

.service-select-card-mini.active .icon-box-mini {
  background: rgba(255,255,255,0.2) !important;
}

.service-selection-card.selected .icon-box-dynamic {
  background: var(--button-bg);
  color: #fff;
}

.colab-container, .date-container {
  display: flex;
  overflow-x: auto;
  gap: 1rem;
  padding-bottom: 0.5rem;
  scroll-behavior: smooth;
  scrollbar-width: none;
}
.colab-container::-webkit-scrollbar, .date-container::-webkit-scrollbar {
  display: none;
}

.colab-select-card, .date-card {
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

.date-card {
  width: 85px;
  height: 105px;
}

.colab-select-card.active, .date-card.active {
  border-color: var(--button-bg);
  background: var(--button-bg);
  box-shadow: 0 8px 16px rgba(0,0,0,0.1);
}

.colab-select-card.active .colab-text, .colab-select-card.active .avatar-placeholder,
.date-card.active .date-text {
  color: #fff !important;
}

.avatar-placeholder {
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

.hours-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(85px, 1fr));
  gap: 0.75rem;
}

.hour-item {
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 0.6rem 0;
  text-align: center;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.hour-item.active {
  background: var(--button-bg);
  color: #fff !important;
  border-color: var(--button-bg);
  box-shadow: 0 4px 10px rgba(0,0,0,0.1);
}

.hour-item.occupied {
  opacity: 0.4;
  cursor: not-allowed;
  background: rgba(0,0,0,0.05);
}

.scroll-arrow {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--bs-body-bg);
  border: 1px solid var(--card-border);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--custom-text-color);
  transition: all 0.2s;
}
.scroll-arrow:hover {
  background: var(--button-bg);
  color: #fff;
  border-color: var(--button-bg);
}

/* ─── Session Cards (timeline) ─── */
.session-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.9rem 1.1rem;
  border-radius: 16px;
  border: 1.5px solid;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  flex-wrap: wrap;
}

.session-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(0,0,0,0.08);
}

/* Verde — concluída */
.session-card--completed {
  background: rgba(25, 135, 84, 0.06);
  border-color: rgba(25, 135, 84, 0.3);
}

/* Azul — próxima sessão */
.session-card--next {
  background: rgba(13, 110, 253, 0.07);
  border-color: rgba(13, 110, 253, 0.35);
}

/* Amarelo — agendada (não é a próxima) */
.session-card--scheduled {
  background: rgba(255, 193, 7, 0.07);
  border-color: rgba(255, 193, 7, 0.35);
}

/* Cinza — slot vazio (não agendada ainda) */
.session-card--empty {
  background: var(--bs-tertiary-bg);
  border-color: var(--card-border);
  border-style: dashed;
  opacity: 0.75;
}

.session-card__icon {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
}

.session-icon--completed { background: rgba(25,135,84,0.12); color: #198754; }
.session-icon--next      { background: rgba(13,110,253,0.12); color: #0d6efd; }
.session-icon--scheduled { background: rgba(255,193,7,0.15);  color: #cc8000; }
.session-icon--empty     { background: rgba(100,100,100,0.08); color: var(--bs-secondary-color); }

.session-card__info {
  flex: 1 1 140px;
  min-width: 0;
}

.session-card__title {
  font-size: 0.9rem;
  font-weight: 700;
  margin-bottom: 2px;
  color: var(--bs-body-color);
}

.session-card__sub {
  font-size: 0.78rem;
  margin: 0;
  color: var(--bs-secondary-color);
}

.session-card__dates {
  display: flex;
  gap: 1.25rem;
  flex-shrink: 0;
}

.session-date-block {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.session-date-label {
  font-size: 0.6rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  opacity: 0.5;
  color: var(--bs-body-color);
}

.session-date-value {
  font-size: 0.88rem;
  font-weight: 700;
  color: var(--bs-body-color);
}

.session-card__actions {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
  flex-shrink: 0;
}

/* Badges por status */
.session-badge--completed {
  background: rgba(25,135,84,0.12);
  color: #198754;
  border: 1px solid rgba(25,135,84,0.25);
  font-size: 0.72rem;
}

.session-badge--next {
  background: rgba(13,110,253,0.12);
  color: #0d6efd;
  border: 1px solid rgba(13,110,253,0.25);
  font-size: 0.72rem;
}

.session-badge--scheduled {
  background: rgba(255,193,7,0.15);
  color: #cc8000;
  border: 1px solid rgba(255,193,7,0.3);
  font-size: 0.72rem;
}

/* Botão reagendar dentro do card */
.session-reschedule-btn {
  background: rgba(99,102,241,0.08);
  color: #6366f1;
  border: 1px solid rgba(99,102,241,0.25);
  font-size: 0.75rem;
  transition: all 0.2s;
}

.session-reschedule-btn:hover {
  background: #6366f1;
  color: #fff;
  border-color: #6366f1;
}

/* Dark mode adjustments */
[data-bs-theme='dark'] .session-card--completed { background: rgba(25,135,84,0.1); }
[data-bs-theme='dark'] .session-card--next      { background: rgba(13,110,253,0.1); }
[data-bs-theme='dark'] .session-card--scheduled { background: rgba(255,193,7,0.1); }
[data-bs-theme='dark'] .session-badge--scheduled { color: #ffc107; }

/* Alert success inline */
.alert-inline--success {
  background: rgba(25,135,84,0.1);
  border: 1px solid rgba(25,135,84,0.25);
  color: #198754;
}
[data-bs-theme='dark'] .alert-inline--success {
  background: rgba(25,135,84,0.15);
  color: #75d89e;
}
</style>
