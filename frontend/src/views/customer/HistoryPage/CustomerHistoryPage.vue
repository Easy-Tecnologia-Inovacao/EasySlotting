<template>
  <CustomerLayout>
    <div
      class="historico-page"
      :data-bs-theme="store.isDarkMode ? 'dark' : 'light'"
      :style="pageThemeVars"
    >
      <div class="container-fluid px-0">

        <!-- Header -->
        <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
          <div>
            <h2 class="fw-800 mb-1 dynamic-text">Histórico de Agendamentos</h2>
            <p class="dynamic-text opacity-75 mb-0">
              Seus atendimentos concluídos. Avalie sua experiência — o feedback é anônimo.
            </p>
          </div>
        </div>

        <!-- Carregando -->
        <div v-if="loading" class="text-center py-5">
          <div class="spinner-border text-primary" role="status"></div>
          <p class="mt-3 dynamic-text opacity-75">Carregando histórico...</p>
        </div>

        <!-- Erro ao carregar -->
        <div v-else-if="loadError" class="alert alert-danger rounded-4 border-0 shadow-sm">
          <i class="bi bi-exclamation-circle-fill me-2"></i>{{ loadError }}
        </div>

        <!-- Nenhum item -->
        <div v-else-if="!history.length" class="text-center py-5 opacity-75">
          <i class="bi bi-calendar-x fs-1 dynamic-text"></i>
          <p class="mt-3 dynamic-text">Nenhum atendimento concluído ainda.</p>
        </div>

        <!-- Lista de histórico -->
        <div v-else class="d-grid gap-3">
          <div
            v-for="item in history"
            :key="item.id"
            class="card border-0 shadow-sm rounded-4 p-4 history-card"
          >
            <!-- Informações do agendamento -->
            <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-3">
              <div>
                <h5 class="fw-bold dynamic-text mb-1">{{ item.service.name }}</h5>
                <p class="dynamic-text opacity-75 mb-1">
                  <i class="bi bi-person me-1"></i>{{ item.employee.name }}
                </p>
                <p class="dynamic-text opacity-75 mb-0">
                  <i class="bi bi-calendar3 me-1"></i>{{ formatDate(item.appointment_date) }}
                  às {{ item.start_time }}
                </p>
              </div>
              <span class="badge text-bg-success rounded-pill px-3 py-2">Concluído</span>
            </div>

            <!-- Feedback já enviado -->
            <div v-if="item.feedback" class="feedback-sent rounded-4 p-3">
              <div class="d-flex align-items-center gap-2 mb-2">
                <i class="bi bi-check-circle-fill text-success fs-5"></i>
                <strong class="dynamic-text">Seu feedback</strong>
                <span class="small dynamic-text opacity-50 ms-auto">
                  {{ formatDate(item.feedback.created_at) }}
                </span>
              </div>

              <!-- Estrelas exibidas -->
              <div class="mb-2 d-flex gap-1">
                <i
                  v-for="star in 5"
                  :key="star"
                  class="bi fs-5"
                  :class="item.feedback.rating >= star ? 'bi-star-fill text-warning' : 'bi-star text-secondary opacity-50'"
                ></i>
              </div>

              <p v-if="item.feedback.comment" class="small dynamic-text opacity-75 mb-0 fst-italic">
                "{{ item.feedback.comment }}"
              </p>
              <p v-else class="small dynamic-text opacity-50 mb-0">
                Sem comentário.
              </p>
            </div>

            <!-- Formulário de feedback -->
            <div v-else class="feedback-box rounded-4 p-3">
              <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                <strong class="dynamic-text">Deixe seu feedback anônimo</strong>
                <span class="small dynamic-text opacity-75">
                  <i class="bi bi-shield-check me-1"></i>Seu nome não será exibido
                </span>
              </div>

              <!-- Estrelas interativas -->
              <div class="mb-3 d-flex gap-2 flex-wrap" role="group" :aria-label="`Avaliação para ${item.service.name}`">
                <button
                  v-for="star in 5"
                  :key="star"
                  type="button"
                  class="btn btn-sm rounded-circle star-btn"
                  :class="item.draftRating >= star ? 'btn-warning' : 'btn-outline-secondary'"
                  :aria-label="`${star} estrela${star > 1 ? 's' : ''}`"
                  @click="item.draftRating = star"
                >
                  <i class="bi bi-star-fill"></i>
                </button>
              </div>

              <!-- Erro de validação local -->
              <div v-if="item.ratingError" class="small text-danger mb-2">
                <i class="bi bi-exclamation-circle me-1"></i>{{ item.ratingError }}
              </div>

              <textarea
                v-model="item.draftComment"
                class="form-control custom-input mb-3"
                rows="3"
                maxlength="1000"
                placeholder="Conte como foi sua experiência (opcional)..."
                :aria-label="`Comentário para ${item.service.name}`"
              ></textarea>

              <div class="d-flex justify-content-between align-items-center">
                <span class="small dynamic-text opacity-50">
                  {{ item.draftComment?.length || 0 }}/1000
                </span>
                <button
                  class="btn custom-btn rounded-pill px-4"
                  :disabled="item.submitting"
                  @click="submitFeedback(item)"
                >
                  <span v-if="item.submitting" class="spinner-border spinner-border-sm me-2"></span>
                  {{ item.submitting ? 'Enviando...' : 'Enviar feedback' }}
                </button>
              </div>

              <!-- Erro ao enviar -->
              <div v-if="item.submitError" class="alert-inline alert-inline--error mt-3">
                <i class="bi bi-exclamation-circle-fill me-2"></i>{{ item.submitError }}
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  </CustomerLayout>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useThemeStore } from '@/stores/themeStore'
import CustomerLayout from '@/views/customer/Layout/CustomerLayout.vue'
import { api } from '@/services/api'

interface Feedback {
  id: number
  rating: number
  comment: string | null
  created_at: string
}

interface HistoryItem {
  id: number
  status: string
  appointment_date: string
  start_time: string
  service: { name: string }
  employee: { name: string }
  feedback: Feedback | null
  // campos locais de UI
  draftRating: number
  draftComment: string
  submitting: boolean
  ratingError: string
  submitError: string
}

const store = useThemeStore()
const loading   = ref(true)
const loadError = ref('')
const history   = ref<HistoryItem[]>([])

const fetchHistory = async () => {
  loading.value   = true
  loadError.value = ''
  try {
    const response = await api.get('/customer/appointments/history')
    history.value = response.data.map((item: any) => ({
      ...item,
      draftRating:  0,
      draftComment: '',
      submitting:   false,
      ratingError:  '',
      submitError:  ''
    }))
  } catch (err: any) {
    loadError.value = err?.response?.data?.error || 'Não foi possível carregar o histórico.'
  } finally {
    loading.value = false
  }
}

const submitFeedback = async (item: HistoryItem) => {
  item.ratingError  = ''
  item.submitError  = ''

  if (!item.draftRating || item.draftRating < 1) {
    item.ratingError = 'Selecione pelo menos 1 estrela para enviar o feedback.'
    return
  }

  item.submitting = true
  try {
    const response = await api.post(`/customer/appointments/${item.id}/feedback`, {
      feedback: {
        rating:  item.draftRating,
        comment: item.draftComment.trim()
      }
    })
    // Atualiza o item localmente com o feedback salvo
    item.feedback = response.data.feedback
  } catch (err: any) {
    const errors = err?.response?.data?.errors
    item.submitError = Array.isArray(errors)
      ? errors.join(', ')
      : err?.response?.data?.error || 'Erro ao enviar feedback.'
  } finally {
    item.submitting = false
  }
}

const formatDate = (dateStr: string) => {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return d.toLocaleDateString('pt-BR', { timeZone: 'UTC' })
}

onMounted(fetchHistory)

const pageThemeVars = computed(() => ({
  '--button-bg':         store.themeConfig.buttonBg,
  '--button-hover':      store.themeConfig.buttonHover,
  '--custom-text-color': store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight,
  '--bs-tertiary-bg':    store.isDarkMode ? store.themeConfig.cardDark  : store.themeConfig.cardLight,
  '--card-border':       store.isDarkMode ? 'rgba(255,255,255,0.1)'     : 'rgba(0,0,0,0.08)'
}))
</script>

<style scoped>
.history-card,
.feedback-box,
.feedback-sent {
  background: var(--bs-tertiary-bg);
  border: 1px solid var(--card-border);
  transition: background 0.3s;
}

.feedback-sent {
  border-color: rgba(25, 135, 84, 0.25);
}

.custom-input {
  border-radius: 14px;
  padding: 12px 14px;
  background: var(--bs-tertiary-bg);
  color: var(--custom-text-color);
  border: 1px solid var(--card-border);
  resize: vertical;
}

.star-btn {
  width: 38px;
  height: 38px;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.15s;
}

.star-btn:hover {
  transform: scale(1.15);
}

.custom-btn {
  background-color: var(--button-bg) !important;
  border-color: var(--button-bg) !important;
  color: #fff !important;
  transition: background-color 0.2s;
}

.custom-btn:hover:not(:disabled) {
  background-color: var(--button-hover) !important;
  border-color: var(--button-hover) !important;
}

.custom-btn:disabled {
  opacity: 0.65;
}

.dynamic-text {
  color: var(--custom-text-color) !important;
}

.alert-inline {
  padding: 0.65rem 1rem;
  border-radius: 12px;
  font-size: 0.875rem;
}

.alert-inline--error {
  background: rgba(220, 53, 69, 0.1);
  border: 1px solid rgba(220, 53, 69, 0.3);
  color: #dc3545;
}
</style>