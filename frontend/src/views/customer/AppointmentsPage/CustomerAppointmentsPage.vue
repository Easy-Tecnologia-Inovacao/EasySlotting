<template>
  <CustomerLayout>
    <div
      class="agendamentos-page"
      :data-bs-theme="store.isDarkMode ? 'dark' : 'light'"
      :style="pageThemeVars"
    >
      <div class="container-fluid px-0">
        <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
          <div>
            <h2 class="fw-800 mb-1 dynamic-text">Meus Agendamentos</h2>
            <p class="dynamic-text opacity-75 mb-0">Acompanhe seus próximos horários.</p>
          </div>
        </div>

        <div v-if="loading" class="text-center py-5">
          <div class="spinner-border text-primary" role="status">
            <span class="visually-hidden">Carregando...</span>
          </div>
          <p class="mt-2 dynamic-text opacity-75">Buscando agendamentos...</p>
        </div>

        <div v-else class="d-grid gap-3">
          <div
            v-for="item in appointments"
            :key="item.id"
            class="card border-0 shadow-sm rounded-4 p-4 appointment-card"
          >
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3">
              <div class="flex-grow-1">
                <div class="d-flex align-items-center gap-2 mb-2 flex-wrap">
                  <h5 class="fw-bold dynamic-text mb-0">{{ item.service?.name || 'Serviço Excluído' }}</h5>
                  <span v-if="item.from_plan" class="badge rounded-pill px-2 py-1" style="font-size: 0.65rem; background: rgba(251,191,36,0.15); color: #d97706;">Pacote</span>
                  <span v-else class="badge rounded-pill px-2 py-1" style="font-size: 0.65rem; background: rgba(59,130,246,0.15); color: #2563eb;">Avulso</span>
                </div>

                <div class="d-flex flex-column gap-1">
                  <div class="d-flex align-items-center gap-2">
                    <i class="bi bi-person dynamic-text opacity-75" style="font-size: 0.85rem;"></i>
                    <span class="dynamic-text opacity-75 small"><strong>Profissional:</strong> {{ item.employee?.name || 'Profissional Excluído' }}</span>
                  </div>
                  <div class="d-flex align-items-center gap-2">
                    <i class="bi bi-calendar-event dynamic-text opacity-75" style="font-size: 0.85rem;"></i>
                    <span class="dynamic-text opacity-75 small"><strong>Data:</strong> {{ formatDate(item.appointment_date) }}</span>
                  </div>
                  <div class="d-flex align-items-center gap-2">
                    <i class="bi bi-clock dynamic-text opacity-75" style="font-size: 0.85rem;"></i>
                    <span class="dynamic-text opacity-75 small"><strong>Horário:</strong> {{ formatTime(item.start_time) }} — {{ formatTime(item.end_time) }}</span>
                  </div>
                  <div v-if="item.service?.duration_minutes" class="d-flex align-items-center gap-2">
                    <i class="bi bi-hourglass-split dynamic-text opacity-75" style="font-size: 0.85rem;"></i>
                    <span class="dynamic-text opacity-75 small"><strong>Duração:</strong> {{ item.service.duration_minutes }} minutos</span>
                  </div>
                </div>
              </div>

              <div class="text-end flex-shrink-0">
                <span class="badge rounded-pill px-3 py-2" :class="getStatusBadgeClass(item.status)">
                  {{ getStatusLabel(item.status) }}
                </span>
                
                <div v-if="item.status !== 'canceled' && item.status !== 'completed'" class="mt-3 d-flex flex-wrap gap-2 justify-content-end">
                  <button 
                    v-if="item.status === 'pending'"
                    class="btn btn-sm btn-confirm rounded-pill px-3"
                    @click="confirmAppointment(item)"
                    :disabled="confirmingId === item.id"
                  >
                    <span v-if="confirmingId === item.id" class="spinner-border spinner-border-sm me-1"></span>
                    <i v-else class="bi bi-check-circle me-1"></i>
                    Confirmar
                  </button>
                  <button 
                    class="btn btn-sm custom-outline-btn rounded-pill px-3"
                    @click="openRescheduleModal(item)"
                  >
                    Reagendar
                  </button>
                  <button 
                    class="btn btn-sm btn-outline-danger rounded-pill px-3"
                    @click="openCancelModal(item)"
                    :disabled="cancelingId === item.id"
                  >
                    <span v-if="cancelingId === item.id" class="spinner-border spinner-border-sm me-1"></span>
                    Cancelar
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-if="!loading && appointments.length === 0" class="text-center py-5 empty-state">
          <div class="mb-4">
            <i class="bi bi-calendar-x text-secondary opacity-50" style="font-size: 4rem;"></i>
          </div>
          <h4 class="fw-bold dynamic-text mb-2">Nenhum agendamento ativo</h4>
          <p class="dynamic-text opacity-75 mb-0">Você não possui horários agendados no momento.</p>
          <router-link :to="{ name: 'agendamento', params: { slug: currentSlug } }" class="btn custom-btn rounded-pill px-4 mt-4 fw-bold shadow-sm">
            Agendar Agora
          </router-link>
        </div>
      </div>

      <!-- Alerta inline da lista -->
      <div v-if="listError" class="alert-inline alert-inline--error my-3">
        <i class="bi bi-exclamation-circle-fill me-2"></i>{{ listError }}
      </div>
      <div v-if="listSuccess" class="alert-inline alert-inline--success my-3">
        <i class="bi bi-check-circle-fill me-2"></i>{{ listSuccess }}
      </div>
    </div>

    <!-- Modal Reagendar -->
    <div class="modal fade" id="modalReagendar" tabindex="-1" aria-hidden="true" ref="modalReagendarRef">
      <div class="modal-dialog modal-dialog-centered modal-lg modal-dialog-scrollable">
        <div class="modal-content" :data-bs-theme="store.isDarkMode ? 'dark' : 'light'" :style="pageThemeVars">
          <div class="modal-header border-bottom-0 pb-0">
            <h5 class="modal-title fw-bold dynamic-text">Reagendar Horário</h5>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          
          <div class="modal-body custom-scrollbar pt-3" v-if="selectedAppointment">
            <!-- 1. Escolha do Profissional -->
            <section class="mb-4">
              <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-3">
                1. Escolha o Profissional
              </label>
              <div class="colab-container pb-2 custom-scrollbar d-flex gap-3 overflow-auto">
                <div 
                  v-for="emp in allEmployees"
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
                  <span class="small dynamic-text opacity-75 colab-text text-center" style="font-size: 0.7rem;">
                    {{ emp.role_label || 'Profissional' }}
                  </span>
                </div>
                <div v-if="loadingBooking" class="p-3 text-center w-100">
                  <div class="spinner-border spinner-border-sm text-primary"></div>
                </div>
              </div>
            </section>

            <!-- 2. Escolha do Serviço -->
            <section class="mb-4" v-if="selectedEmployeeId">
              <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-3">
                2. Escolha o Serviço
              </label>
              <div class="services-grid overflow-auto d-flex gap-3 pb-2 custom-scrollbar">
                <div 
                  v-for="service in filteredServices"
                  :key="service.id"
                  class="service-select-card-mini p-3 shadow-sm flex-shrink-0"
                  :class="{ active: selectedServiceId === service.id }"
                  @click="selectService(service.id)"
                  style="min-width: 160px; cursor: pointer; border-radius: 16px; border: 1px solid var(--card-border); background: var(--bs-body-bg);"
                >
                  <div class="d-flex flex-column align-items-center text-center">
                    <div class="icon-box-mini mb-2 rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px; background: rgba(99,102,241,0.1); color: #6366f1;">
                      <i class="bi bi-scissors"></i>
                    </div>
                    <div class="fw-bold small dynamic-text">{{ service.name }}</div>
                    <div class="small opacity-75 dynamic-text" style="font-size: 0.7rem;">{{ service.duration_minutes }} min</div>
                  </div>
                </div>
                <div v-if="selectedEmployeeId && filteredServices.length === 0 && !loadingBooking" class="small text-muted p-2">
                  Nenhum serviço disponível para este profissional.
                </div>
              </div>
            </section>

            <!-- 3. Dia -->
            <section class="mb-4" v-if="selectedServiceId">
              <div class="d-flex justify-content-between align-items-center mb-3">
                <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-0">
                  3. Escolha o Dia
                </label>
                <button
                  class="btn btn-sm rounded-pill fw-bold px-3 py-1 custom-outline-btn shadow-sm"
                  @click="goToTodayReschedule"
                >
                  Hoje
                </button>
              </div>
              <div class="d-flex align-items-center gap-2 gap-md-3">
                <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollList(dateScrollRef, -1)">
                  <i class="bi bi-chevron-left fs-5"></i>
                </button>
                <div class="date-container pb-2 flex-grow-1" ref="dateScrollRef">
                  <div
                    v-for="(date, index) in availableDates"
                    :key="index"
                    class="date-card shadow-sm flex-shrink-0"
                    :class="{ active: selectedDate === date.apiDate }"
                    @click="selectDate(date.apiDate)"
                  >
                    <span class="small dynamic-text date-text opacity-75 mb-1">{{ date.weekDay }}</span>
                    <span class="fw-bold fs-4 dynamic-text date-text lh-1">{{ date.dayNumber }}</span>
                    <span class="small dynamic-text date-text opacity-75 mt-1">{{ date.monthName }}</span>
                  </div>
                  <div v-if="loadingAvailableDays" class="d-flex align-items-center gap-2 p-2">
                    <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
                    <span class="small text-muted">Carregando datas...</span>
                  </div>
                  <div v-if="!loadingAvailableDays && availableDates.length === 0" class="small text-muted p-2">
                    <i class="bi bi-calendar-x me-1"></i>Nenhum dia disponível.
                  </div>
                </div>
                <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollList(dateScrollRef, 1)">
                  <i class="bi bi-chevron-right fs-5"></i>
                </button>
              </div>
            </section>

            <!-- 4. Hora -->
            <section class="mb-4" v-if="selectedDate">
              <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
                4. Escolha a Nova Hora
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
                <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
                <span class="small text-muted">Carregando horários...</span>
              </div>
              <div v-if="!loadingAvailability && selectedDate && allTimesForDisplay.length === 0" class="small text-muted mt-3">
                <i class="bi bi-clock-history me-1"></i>Nenhum horário disponível neste dia.
              </div>
            </section>
          </div>
          
          <div class="modal-footer border-top-0 pb-4 pt-2 flex-column align-items-stretch gap-2">
            <!-- Alerta inline do modal -->
            <div v-if="modalError" class="alert-inline alert-inline--error">
              <i class="bi bi-exclamation-circle-fill me-2"></i>{{ modalError }}
            </div>
            <div v-if="modalSuccess" class="alert-inline alert-inline--success">
              <i class="bi bi-check-circle-fill me-2"></i>{{ modalSuccess }}
            </div>
            <div class="d-flex gap-2 justify-content-end">
              <button type="button" class="btn btn-outline-secondary rounded-pill px-4 fw-bold" data-bs-dismiss="modal">Cancelar</button>
              <button
                type="button"
                class="btn custom-btn rounded-pill px-4 fw-bold"
                @click="confirmReschedule"
                :disabled="loadingSubmit || !selectedDate || !selectedTime"
              >
                <span v-if="loadingSubmit" class="spinner-border spinner-border-sm me-2" role="status"></span>
                {{ loadingSubmit ? 'Salvando...' : 'Confirmar Novo Horário' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Cancelar Agendamento -->
    <div class="modal fade" id="modalCancelAppointment" tabindex="-1" aria-hidden="true" ref="modalCancelRef">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content" :data-bs-theme="store.isDarkMode ? 'dark' : 'light'" :style="pageThemeVars">
          <div class="modal-header border-bottom-0 pb-0">
            <h5 class="modal-title fw-bold dynamic-text text-danger mb-0">
              <i class="bi bi-exclamation-triangle me-2"></i>Cancelar Agendamento
            </h5>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body pt-3">
            <p class="dynamic-text opacity-75 small mb-4">
              Tem certeza que deseja cancelar este agendamento? Esta ação não pode ser desfeita.
            </p>

            <div v-if="appointmentToCancel" class="p-3 rounded-3 mb-3" style="background: var(--bs-tertiary-bg); border: 1px solid var(--card-border);">
              <div class="d-flex flex-column gap-1 small">
                <div class="d-flex align-items-center gap-2">
                  <i class="bi bi-scissors dynamic-text opacity-75"></i>
                  <span class="dynamic-text"><strong>{{ appointmentToCancel.service?.name || 'Serviço' }}</strong></span>
                </div>
                <div class="d-flex align-items-center gap-2">
                  <i class="bi bi-person dynamic-text opacity-75"></i>
                  <span class="dynamic-text opacity-75">{{ appointmentToCancel.employee?.name || 'Profissional' }}</span>
                </div>
                <div class="d-flex align-items-center gap-2">
                  <i class="bi bi-calendar-event dynamic-text opacity-75"></i>
                  <span class="dynamic-text opacity-75">{{ formatDate(appointmentToCancel.appointment_date) }} às {{ formatTime(appointmentToCancel.start_time) }}</span>
                </div>
              </div>
            </div>

            <div class="mb-3">
              <label class="form-label small fw-bold dynamic-text opacity-75">Por que você está cancelando?</label>
              <select v-model="cancelReasonType" class="form-select custom-input dynamic-text border-1">
                <option value="">Selecione um motivo...</option>
                <option value="Financeiro">Motivos financeiros</option>
                <option value="Viagem">Mudança ou viagem</option>
                <option value="Insatisfação">Insatisfação com o serviço</option>
                <option value="Horario">Problema de horário</option>
                <option value="Outro">Outro motivo</option>
              </select>
            </div>
            <div class="mb-3">
              <label class="form-label small fw-bold dynamic-text opacity-75">Detalhes adicionais (opcional)</label>
              <textarea v-model="cancelReasonText" class="form-control custom-input dynamic-text" rows="3" placeholder="Escreva aqui..."></textarea>
            </div>
            <div class="mb-3" v-if="appointmentToCancel">
              <label class="form-label small fw-bold dynamic-text opacity-75">
                Para confirmar, digite <strong>CONFIRMAR</strong>
              </label>
              <input
                v-model="cancelConfirmText"
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
              @click="confirmCancelAppointment"
              :disabled="!cancelReasonType || cancelConfirmText !== 'CONFIRMAR' || cancelingId !== null"
            >
              <span v-if="cancelingId !== null" class="spinner-border spinner-border-sm me-2"></span>
              Confirmar Cancelamento
            </button>
          </div>
        </div>
      </div>
    </div>

  </CustomerLayout>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useThemeStore } from '@/stores/themeStore'
import CustomerLayout from '@/views/customer/Layout/CustomerLayout.vue'
import { api } from '@/services/api'
import { Modal } from 'bootstrap'

const store = useThemeStore()
const route = useRoute()

const currentSlug = computed(() => {
  return String(
    route.params.slug ||
    sessionStorage.getItem('site-slug') ||
    localStorage.getItem('site-slug') ||
    ''
  )
})

const appointments = ref<any[]>([])
const loading = ref(true)
const cancelingId = ref<number | null>(null)
const confirmingId = ref<number | null>(null)
const listError = ref('')
const listSuccess = ref('')
const modalError = ref('')
const modalSuccess = ref('')

// Modal de cancelamento
const modalCancelRef = ref<HTMLElement | null>(null)
let bsModalCancel: Modal | null = null
const appointmentToCancel = ref<any>(null)
const cancelReasonType = ref('')
const cancelReasonText = ref('')
const cancelConfirmText = ref('')

const modalReagendarRef = ref<HTMLElement | null>(null)
let bootstrapModal: Modal | null = null
const selectedAppointment = ref<any>(null)

// ── NOVOS REFS PARA SELEÇÃO LIVRE ──
const availableServices = ref<any[]>([])
const allEmployees = ref<any[]>([])
const employeeServices = ref<any[]>([])
const loadingBooking = ref(false)
const selectedServiceId = ref<number | null>(null)
const selectedEmployeeId = ref<number | null>(null)

const filteredEmployees = computed(() => {
  return allEmployees.value
})

const filteredServices = computed(() => {
  if (!selectedEmployeeId.value) return availableServices.value
  const empId = selectedEmployeeId.value
  const serviceIds = employeeServices.value
    .filter((es: any) => es.employee_id === empId)
    .map((es: any) => es.service_id)
  return availableServices.value.filter((s: any) => serviceIds.includes(s.id))
})

const fetchBookingData = async (slug: string) => {
  loadingBooking.value = true
  try {
    const { data } = await api.get(`/public/establishments/${slug}/booking_data`)
    availableServices.value = data.services || []
    allEmployees.value = data.employees || []
    employeeServices.value = data.employee_services || []
  } catch (error) {
    console.error('Erro ao buscar dados do estabelecimento:', error)
  } finally {
    loadingBooking.value = false
  }
}

const selectService = async (id: number) => {
  selectedServiceId.value = id
  selectedDate.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []

  if (selectedAppointment.value && selectedEmployeeId.value) {
    const slug = selectedAppointment.value.establishment?.slug
    await fetchAvailableDays(slug, id, selectedEmployeeId.value)
  }
}

const selectEmployee = async (id: number) => {
  selectedEmployeeId.value = id
  selectedServiceId.value = null
  selectedDate.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
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

// Botão "Hoje" do modal de reagendamento
const goToTodayReschedule = async () => {
  const today = getTodayString()
  const todayExists = availableDates.value.find((d) => d.apiDate === today)
  if (todayExists) {
    await selectDate(today)
    // Scroll para o início da lista de datas
    if (dateScrollRef.value) dateScrollRef.value.scrollLeft = 0
  }
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

const selectDate = async (date: string) => {
  selectedDate.value = date
  selectedTime.value = ''
  if (selectedAppointment.value && selectedServiceId.value && selectedEmployeeId.value) {
    const slug = selectedAppointment.value.establishment?.slug
    await fetchAvailability(slug, selectedServiceId.value, selectedEmployeeId.value, date)
  }
}

const pageThemeVars = computed(() => ({
  '--button-bg': store.themeConfig.buttonBg,
  '--button-hover': store.themeConfig.buttonHover,
  '--custom-text-color': store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight,
  '--bs-tertiary-bg': store.isDarkMode ? store.themeConfig.cardDark : store.themeConfig.cardLight,
  '--card-border': store.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'
}))

const fetchAppointments = async () => {
  loading.value = true
  try {
    const response = await api.get('/customer/appointments')
    appointments.value = response.data
  } catch (error) {
    console.error('Erro ao buscar agendamentos:', error)
  } finally {
    loading.value = false
  }
}

const confirmAppointment = async (appointment: any) => {
  const serviceName = appointment.service?.name || 'serviço'
  const employeeName = appointment.employee?.name || 'profissional'
  const dateStr = formatDate(appointment.appointment_date)
  const timeStr = formatTime(appointment.start_time)

  const confirmed = window.confirm(
    `Confirmar presença?\n\n` +
    `Serviço: ${serviceName}\n` +
    `Profissional: ${employeeName}\n` +
    `Data: ${dateStr} às ${timeStr}\n\n` +
    `Caso não possa ir no dia, utilize o botão "Reagendar" para escolher outro horário.`
  )

  if (!confirmed) return

  confirmingId.value = appointment.id
  listError.value = ''
  listSuccess.value = ''

  try {
    await api.patch(`/customer/appointments/${appointment.id}/confirm`)
    listSuccess.value = 'Presença confirmada com sucesso!'
    await fetchAppointments()
  } catch (error: any) {
    const msg = error.response?.data?.error || error.message || 'Erro desconhecido'
    listError.value = `Erro ao confirmar: ${msg}`
  } finally {
    confirmingId.value = null
  }
}

const openCancelModal = (appointment: any) => {
  appointmentToCancel.value = appointment
  cancelReasonType.value = ''
  cancelReasonText.value = ''
  cancelConfirmText.value = ''

  if (modalCancelRef.value) {
    if (!bsModalCancel) bsModalCancel = new Modal(modalCancelRef.value)
    bsModalCancel.show()
  }
}

const confirmCancelAppointment = async () => {
  if (!appointmentToCancel.value || !cancelReasonType.value || cancelConfirmText.value !== 'CONFIRMAR') return

  listError.value = ''
  listSuccess.value = ''

  let reason = cancelReasonType.value
  if (cancelReasonText.value.trim() !== '') {
    reason += `: ${cancelReasonText.value.trim()}`
  }

  cancelingId.value = appointmentToCancel.value.id
  try {
    await api.patch(`/customer/appointments/${appointmentToCancel.value.id}/cancel`, {
      cancellation_reason: reason
    })
    listSuccess.value = 'Agendamento cancelado com sucesso.'
    if (bsModalCancel) bsModalCancel.hide()
    await fetchAppointments()
  } catch (error: any) {
    listError.value = error.response?.data?.error || 'Erro ao cancelar o agendamento.'
  } finally {
    cancelingId.value = null
  }
}

const loadingSubmit = ref(false)

const openRescheduleModal = async (appointment: any) => {
  selectedAppointment.value = appointment
  selectedDate.value = ''
  selectedTime.value = ''
  availableDates.value = []
  availableTimes.value = []
  occupiedTimes.value = []
  modalError.value = ''
  modalSuccess.value = ''
  
  // Inicializa seleções com os valores atuais (profissional primeiro)
  selectedEmployeeId.value = appointment.employee_id
  selectedServiceId.value = appointment.service_id

  if (modalReagendarRef.value) {
    if (!bootstrapModal) {
      bootstrapModal = new Modal(modalReagendarRef.value)
    }
    bootstrapModal.show()
  }
  
  const slug = appointment.establishment?.slug
  if (slug) {
    await fetchBookingData(slug)
    if (selectedServiceId.value && selectedEmployeeId.value) {
      await fetchAvailableDays(slug, selectedServiceId.value, selectedEmployeeId.value)
    }
  }
}

const confirmReschedule = async () => {
  if (!selectedDate.value || !selectedTime.value || !selectedServiceId.value || !selectedEmployeeId.value) {
    modalError.value = 'Por favor, selecione o serviço, profissional, data e horário.'
    return
  }

  loadingSubmit.value = true
  modalError.value = ''
  modalSuccess.value = ''

  try {
    await api.patch(`/customer/appointments/${selectedAppointment.value.id}/reschedule`, {
      appointment_date: selectedDate.value,
      start_time:       selectedTime.value,
      service_id:       selectedServiceId.value,
      employee_id:      selectedEmployeeId.value
    })

    modalSuccess.value = 'Reagendamento realizado com sucesso!'
    listSuccess.value = 'Agendamento atualizado com sucesso.'
    
    setTimeout(() => {
      if (bootstrapModal) bootstrapModal.hide()
      fetchAppointments()
    }, 1500)
  } catch (error: any) {
    modalError.value = error.response?.data?.error || 'Erro ao reagendar. Tente novamente.'
  } finally {
    loadingSubmit.value = false
  }
}

const formatDate = (dateString: string) => {
  if (!dateString) return ''
  const [year, month, day] = dateString.split('-')
  return `${day}/${month}/${year}`
}

/**
 * Normaliza qualquer formato de hora ("HH:MM", "HH:MM:SS", ISO completa)
 * para sempre retornar "HH:MM" de forma segura.
 */
const formatTime = (value: string): string => {
  if (!value) return '--:--'
  // Formato simples "HH:MM" ou "HH:MM:SS" — retorna os 5 primeiros chars
  if (/^\d{2}:\d{2}/.test(value)) return value.substring(0, 5)
  // ISO string completa — extrai apenas a parte HH:MM após o 'T'
  const isoMatch = value.match(/T(\d{2}:\d{2})/)
  if (isoMatch) return isoMatch[1] ?? value
  return value
}

const isPastAppointment = (dateString: string, timeString: string) => {
  if (!dateString || !timeString) return false

  const timeStr = formatTime(timeString)

  const parts = dateString.split('-').map(Number)
  const year = parts[0] || 0
  const month = parts[1] || 1
  const day = parts[2] || 1

  const timeParts = timeStr.split(':').map(Number)
  const hours = timeParts[0] || 0
  const minutes = timeParts[1] || 0

  const appointmentDate = new Date(year, month - 1, day, hours, minutes)
  return appointmentDate < new Date()
}

const getStatusLabel = (status: string) => {
  const map: Record<string, string> = {
    pending: 'Pendente',
    confirmed: 'Confirmado',
    completed: 'Concluído',
    canceled: 'Cancelado'
  }
  return map[status] || status
}

const getStatusBadgeClass = (status: string) => {
  const map: Record<string, string> = {
    pending: 'text-bg-warning',
    confirmed: 'text-bg-primary',
    completed: 'text-bg-success',
    canceled: 'text-bg-danger'
  }
  return map[status] || 'text-bg-secondary'
}

onMounted(() => {
  fetchAppointments()
})
</script>

<style scoped>
.appointment-card {
  background: var(--bs-tertiary-bg);
  border: 1px solid var(--card-border) !important;
}

.custom-outline-btn {
  color: var(--button-bg) !important;
  border-color: var(--button-bg) !important;
  background: transparent !important;
}

.custom-outline-btn:hover {
  background-color: var(--button-hover) !important;
  border-color: var(--button-hover) !important;
  color: #fff !important;
}

.btn-confirm {
  background-color: #16a34a;
  border-color: #16a34a;
  color: #fff;
  font-weight: 600;
  transition: all 0.2s ease;
}

.btn-confirm:hover {
  background-color: #15803d;
  border-color: #15803d;
  color: #fff;
}

.btn-confirm:disabled {
  opacity: 0.6;
  cursor: not-allowed;
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

/* Modal UI Styles from AgendamentoView */
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

.service-selection-card.selected {
  border-color: var(--button-bg) !important;
  box-shadow: 0 0 0 1px var(--button-bg);
}

.icon-box-dynamic {
  background: rgba(100, 100, 100, 0.1);
  color: var(--custom-text-color);
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
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

/* Alertas inline */
.alert-inline {
  border-radius: 12px;
  padding: 10px 14px;
  font-size: 0.83rem;
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

.alert-inline--success {
  background: rgba(25, 135, 84, 0.1);
  border: 1px solid rgba(25, 135, 84, 0.25);
  color: #198754;
}

[data-bs-theme='dark'] .alert-inline--success {
  background: rgba(25, 135, 84, 0.15);
  color: #6fcf97;
}

.custom-input {
  border: 1.5px solid #d1d5db !important;
}

[data-bs-theme='dark'] .custom-input {
  border-color: rgba(255, 255, 255, 0.15) !important;
}
</style>