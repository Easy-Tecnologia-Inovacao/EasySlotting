<template>
  <AdminLayout>
    <div class="plans-page container-fluid">
      <section class="hero-card mb-4">
        <div class="row align-items-center g-4">
          <div class="col-12 col-xl-8">
            <span class="eyebrow-badge mb-3">Gestão de assinatura</span>
            <h1 class="page-title mb-2">Planos do seu estabelecimento</h1>
            <p class="page-subtitle mb-0">
              Acompanhe seu plano atual, compare benefícios e faça upgrade quando quiser.
            </p>
          </div>

          <div class="col-12 col-xl-4">
            <div class="hero-side-card">
              <div class="small text-secondary mb-1">Status da assinatura</div>
              <div class="d-flex align-items-center gap-2 mb-2">
                <span class="status-dot" :class="statusDotClass(currentSubscription)"></span>
                <strong class="text-body">
                  {{ currentSubscriptionStatusText }}
                </strong>
              </div>
              <div class="small text-secondary">
                {{ currentSubscription?.end_date ? `Renovação até ${formatDate(currentSubscription.end_date)}` : 'Escolha um plano para começar.' }}
              </div>
            </div>
          </div>
        </div>
      </section>

      <div v-if="loading" class="loading-state text-center py-5">
        <div class="spinner-border" role="status"></div>
        <p class="mt-3 text-secondary mb-0">Carregando informações...</p>
      </div>

      <template v-else>
        <div v-if="!isOwner" class="alert alert-warning rounded-4 mb-4 shadow-sm d-flex align-items-center gap-2">
          <i class="bi bi-shield-lock-fill fs-5 text-warning"></i>
          <span>Acesso restrito: Apenas o proprietário deste estabelecimento pode contratar ou cancelar planos de assinatura.</span>
        </div>

        <section class="current-plan-wrapper mb-4">
          <div class="current-plan-card">
            <div class="row align-items-center g-4">
              <div class="col-12 col-lg-8">
                <div class="d-flex flex-wrap align-items-center gap-2 mb-3">
                  <span class="badge rounded-pill current-plan-badge">Plano atual</span>
                  <span
                    v-if="hasCurrentSubscription"
                    class="badge rounded-pill"
                    :class="statusBadgeClass(currentSubscription?.status)"
                  >
                    {{ currentSubscriptionStatusText }}
                  </span>
                </div>

                <h2 class="current-plan-title mb-2">
                  {{ currentSubscription?.plan?.name || 'Nenhum plano ativo' }}
                </h2>

                <p class="current-plan-description mb-0">
                  {{ currentSubscriptionMessage }}
                </p>
              </div>

              <div class="col-12 col-lg-4">
                <div class="price-panel ms-lg-auto">
                  <div class="small text-secondary mb-1">Valor atual</div>
                  <div class="current-price mb-1">
                    <template v-if="currentSubscription?.plan">
                      R$ {{ formatPrice(currentSubscription.price_paid || currentSubscription.plan.price) }}
                    </template>
                    <template v-else>
                      --
                    </template>
                  </div>
                  <div class="small text-secondary mb-3">
                    <template v-if="currentSubscription?.end_date">
                      válido até {{ formatDate(currentSubscription.end_date) }}
                    </template>
                    <template v-else>
                      aguardando contratação
                    </template>
                  </div>

                  <button
                    v-if="canCancelSubscription && isOwner"
                    class="btn btn-outline-danger rounded-3 fw-semibold w-100"
                    @click="openCancelModal"
                  >
                    Cancelar plano
                  </button>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section class="mb-3">
          <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
              <h3 class="section-title mb-1">Planos disponíveis</h3>
              <p class="section-subtitle mb-0">
                Compare recursos e escolha o melhor plano para sua operação.
              </p>
            </div>
          </div>
        </section>

        <section class="row g-4">
          <div
            v-for="plan in plans"
            :key="plan.id"
            class="col-12 col-md-6 col-xxl-4"
          >
            <div
              class="pricing-card h-100"
              :class="{
                'is-highlight': plan.highlight,
                'is-current': isCurrentPlan(plan)
              }"
            >
              <div class="pricing-card-inner">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                  <div>
                    <div class="plan-name mb-1">{{ plan.name }}</div>
                    <div class="plan-description">
                      {{ plan.description || 'Plano completo para o seu estabelecimento.' }}
                    </div>
                  </div>

                  <div class="d-flex flex-column align-items-end gap-2">
                    <span v-if="plan.highlight" class="badge rounded-pill featured-badge">
                      Mais escolhido
                    </span>

                    <span v-if="isCurrentPlan(plan)" class="badge rounded-pill current-badge">
                      Em uso
                    </span>
                  </div>
                </div>

                <div class="price-area mb-4">
                  <div
                    v-if="isPromotionRunning(plan) && plan.promotional_price"
                    class="old-price-row mb-1"
                  >
                    <span class="old-price">R$ {{ formatPrice(plan.price) }}</span>
                    <span class="discount-badge">
                      -{{ plan.discount_percentage || calculateDiscount(plan) }}%
                    </span>
                  </div>

                  <div class="d-flex align-items-end gap-2">
                    <div class="main-price">
                      R$ {{ formatPrice(displayPrice(plan)) }}
                    </div>
                    <div class="price-period">
                      / {{ periodLabel(plan.duration_months) }}
                    </div>
                  </div>
                </div>

                <div class="features-box mb-4">
                  <div class="feature-item">
                    <i class="bi bi-check2-circle"></i>
                    <span>{{ limitLabel(plan.max_employees, 'funcionários') }}</span>
                  </div>

                  <div class="feature-item">
                    <i class="bi bi-check2-circle"></i>
                    <span>{{ limitLabel(plan.max_services, 'serviços') }}</span>
                  </div>

                  <div class="feature-item">
                    <i class="bi bi-check2-circle"></i>
                    <span>{{ limitLabel(plan.max_appointments_per_month, 'agendamentos/mês') }}</span>
                  </div>

                  <div class="feature-item">
                    <i class="bi bi-laptop"></i>
                    <span>Até {{ plan.max_owner_sessions ?? 1 }} {{ (plan.max_owner_sessions ?? 1) === 1 ? 'aparelho conectado' : 'aparelhos conectados' }} por conta do proprietário ou funcionário</span>
                  </div>

                  <div class="feature-item">
                    <i class="bi bi-check2-circle"></i>
                    <span>Site público do estabelecimento</span>
                  </div>

                  <div class="feature-item">
                    <i class="bi bi-check2-circle"></i>
                    <span>Gestão de equipe e serviços</span>
                  </div>
                </div>

                <div class="mt-auto">
                  <button
                    class="btn w-100 rounded-3 fw-semibold action-btn"
                    :class="isCurrentPlan(plan) ? 'btn-outline-secondary' : 'btn-primary'"
                    :disabled="submittingId === plan.id || isCurrentPlan(plan) || !isOwner"
                    @click="selectPlan(plan)"
                  >
                    <span v-if="submittingId === plan.id">Processando...</span>
                    <span v-else-if="isCurrentPlan(plan)">Plano atual</span>
                    <span v-else-if="!isOwner">Restrito ao proprietário</span>
                    <span v-else>Escolher plano</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </section>

        <div v-if="errorMessage" class="alert alert-danger rounded-4 mt-4 shadow-sm">
          {{ errorMessage }}
        </div>
      </template>
    </div>

    <div v-if="showCancelModal" class="custom-modal-backdrop">
      <div class="card border-0 shadow rounded-4 custom-modal">
        <div class="card-body p-4 p-lg-5">
          <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
              <span class="cancel-eyebrow mb-2">Cancelar assinatura</span>
              <h3 class="fw-bold mb-1">Tem certeza que deseja cancelar seu plano?</h3>
              <p class="text-secondary mb-0">
                Seu feedback ajuda a melhorar a plataforma. Você pode nos informar o motivo do cancelamento.
              </p>
            </div>

            <button class="btn btn-sm btn-light rounded-circle" @click="closeCancelModal">
              <i class="bi bi-x-lg"></i>
            </button>
          </div>

          <div class="alert alert-warning rounded-4 mb-4">
            Ao cancelar, seu plano continuará disponível até o fim do período contratado.
          </div>

          <div class="mb-3">
            <label class="form-label fw-semibold">Motivo do cancelamento</label>
            <select v-model="cancelReason" class="form-select rounded-3">
              <option value="">Selecione um motivo</option>
              <option v-for="item in cancelReasons" :key="item.value" :value="item.value">
                {{ item.label }}
              </option>
            </select>
          </div>

          <div class="mb-4">
            <label class="form-label fw-semibold">Quer nos contar mais?</label>
            <textarea
              v-model="cancelDetails"
              rows="4"
              class="form-control rounded-3"
              placeholder="Escreva aqui o que quiser..."
              maxlength="500"
            ></textarea>
            <div class="form-text small text-muted mt-1">Descreva brevemente seu feedback (Máx. 500 caracteres).</div>
          </div>

          <div class="d-flex justify-content-end gap-2">
            <button class="btn btn-light rounded-3" @click="closeCancelModal">
              Voltar
            </button>
            <button
              class="btn btn-danger rounded-3"
              :disabled="cancelLoading || !cancelReason"
              @click="cancelSubscription"
            >
              {{ cancelLoading ? 'Cancelando...' : 'Confirmar cancelamento' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import { onMounted, ref, computed } from 'vue'
import { api } from '@/services/api'
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'

const plans = ref([])
const currentSubscription = ref(null)
const loading = ref(true)
const submittingId = ref(null)
const errorMessage = ref('')

const showCancelModal = ref(false)
const cancelReason = ref('')
const cancelDetails = ref('')
const cancelLoading = ref(false)

const cancelReasons = [
  { value: 'preco_muito_alto', label: 'Preço muito alto' },
  { value: 'nao_estou_usando', label: 'Não estou usando o suficiente' },
  { value: 'encontrei_outra_plataforma', label: 'Encontrei outra plataforma' },
  { value: 'faltam_funcionalidades', label: 'Faltam funcionalidades' },
  { value: 'dificuldade_de_uso', label: 'Dificuldade de uso' },
  { value: 'atendimento_suporte', label: 'Atendimento / suporte' },
  { value: 'problema_tecnico', label: 'Problema técnico' },
  { value: 'outro', label: 'Outro motivo' }
]

const isOwner = computed(() => {
  let role = localStorage.getItem('role') || sessionStorage.getItem('role')
  if (!role) {
    const userStr = localStorage.getItem('user') || sessionStorage.getItem('user')
    if (userStr) {
      try { role = JSON.parse(userStr).role } catch { role = '' }
    }
  }
  return role === 'owner' || role === 'super_admin'
})

const hasCurrentSubscription = computed(() => !!currentSubscription.value?.id)

const subscriptionExpired = computed(() => {
  const endDate = currentSubscription.value?.end_date
  if (!endDate) return false

  const today = new Date()
  const end = new Date(`${endDate}T23:59:59`)
  return end < today
})

const subscriptionStillUsable = computed(() => {
  if (!currentSubscription.value?.id) return false
  if (subscriptionExpired.value) return false

  const status = currentSubscription.value?.status
  return status === 'active' || status === 'canceled'
})

const canCancelSubscription = computed(() => {
  if (!currentSubscription.value?.id) return false
  if (subscriptionExpired.value) return false

  return currentSubscription.value?.status === 'active'
})

const isCanceledButStillAvailable = computed(() => {
  if (!currentSubscription.value?.id) return false
  if (subscriptionExpired.value) return false

  return currentSubscription.value?.status === 'canceled'
})

const currentSubscriptionMessage = computed(() => {
  if (!hasCurrentSubscription.value) {
    return 'Seu estabelecimento ainda não possui um plano ativo. Escolha um dos planos abaixo para começar.'
  }

  if (isCanceledButStillAvailable.value) {
    return `Seu plano foi cancelado, mas continua disponível até ${formatDate(currentSubscription.value?.end_date)}.`
  }

  if (subscriptionExpired.value) {
    return 'Sua assinatura expirou. Escolha um novo plano para continuar usando os recursos premium.'
  }

  return currentSubscription.value?.plan?.description || 'Seu estabelecimento possui um plano ativo.'
})

const currentSubscriptionStatusText = computed(() => {
  if (!hasCurrentSubscription.value) return 'Sem assinatura ativa'

  if (isCanceledButStillAvailable.value) {
    return `Cancelado, mas ativo até ${formatDate(currentSubscription.value?.end_date)}`
  }

  if (subscriptionExpired.value) {
    return 'Assinatura expirada'
  }

  return statusLabel(currentSubscription.value?.status)
})

const loadPlans = async () => {
  const response = await api.get('/plans')
  plans.value = Array.isArray(response.data) ? response.data : []
}

const loadCurrentSubscription = async () => {
  try {
    const response = await api.get('/me/subscription')
    currentSubscription.value = response.data || null
  } catch (error) {
    currentSubscription.value = null
    if (error?.response?.status === 403) {
      errorMessage.value = 'Acesso restrito: Apenas o proprietário deste estabelecimento pode gerenciar a assinatura.'
      throw error
    }
  }
}

const loadData = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    await Promise.all([loadPlans(), loadCurrentSubscription()])
  } catch (error) {
    console.error('Erro ao carregar página de planos:', error)
    if (!errorMessage.value) {
      errorMessage.value = error?.response?.data?.error || 'Não foi possível carregar os planos.'
    }
  } finally {
    loading.value = false
  }
}

const selectPlan = async (plan) => {
  if (!isOwner.value) {
    alert('Acesso negado: Apenas o proprietário pode contratar planos.')
    return
  }

  if (isCurrentPlan(plan)) {
    alert('Este plano já é o plano ativo do seu estabelecimento.')
    return
  }

  submittingId.value = plan.id
  errorMessage.value = ''

  try {
    await api.post('/subscriptions', {
      plan_id: plan.id
    })

    await loadData()
    alert(`Plano "${plan.name}" selecionado com sucesso!`)
  } catch (error) {
    console.error('Erro ao contratar plano:', error)
    errorMessage.value =
      error?.response?.data?.error || 'Não foi possível contratar este plano.'
  } finally {
    submittingId.value = null
  }
}

const openCancelModal = () => {
  if (!isOwner.value) {
    alert('Acesso negado: Apenas o proprietário pode cancelar o plano.')
    return
  }
  cancelReason.value = ''
  cancelDetails.value = ''
  showCancelModal.value = true
}

const closeCancelModal = () => {
  showCancelModal.value = false
}

const sanitizeText = (text) => {
  if (typeof text !== 'string') return ''
  return text
    .replace(/<[^>]*>/g, '') // Remove tags HTML sem alterar caracteres legítimos
    .trim()
    .slice(0, 500)
}

const cancelSubscription = async () => {
  if (!currentSubscription.value?.id) return

  if (!isOwner.value) {
    alert('Acesso negado: Apenas o proprietário pode cancelar o plano.')
    return
  }

  cancelLoading.value = true
  errorMessage.value = ''

  try {
    await api.patch(`/subscriptions/${currentSubscription.value.id}/cancel`, {
      reason: cancelReason.value,
      details: sanitizeText(cancelDetails.value)
    })

    closeCancelModal()
    await loadData()
    alert('Plano cancelado com sucesso. Ele continuará ativo até o fim do período contratado.')
  } catch (error) {
    console.error('Erro ao cancelar plano:', error)
    errorMessage.value =
      error?.response?.data?.error || 'Não foi possível cancelar o plano.'
  } finally {
    cancelLoading.value = false
  }
}

const isCurrentPlan = (plan) => {
  if (!subscriptionStillUsable.value) return false
  return currentSubscription.value?.plan?.id === plan.id
}

const isPromotionRunning = (plan) => {
  if (!plan.promotion_active) return false
  if (!plan.promotion_starts_at || !plan.promotion_ends_at) return false

  const now = new Date()
  const startsAt = new Date(plan.promotion_starts_at)
  const endsAt = new Date(plan.promotion_ends_at)

  return now >= startsAt && now <= endsAt
}

const displayPrice = (plan) => {
  if (isPromotionRunning(plan) && plan.promotional_price) {
    return Number(plan.promotional_price)
  }
  return Number(plan.price || 0)
}

const calculateDiscount = (plan) => {
  const price = Number(plan.price || 0)
  const promo = Number(plan.promotional_price || 0)

  if (!price || !promo || promo >= price) return 0
  return Math.round(((price - promo) / price) * 100)
}

const formatPrice = (value) => {
  return Number(value || 0).toFixed(2).replace('.', ',')
}

const periodLabel = (months) => {
  if (months === 1) return 'mês'
  if (months === 3) return 'trimestre'
  if (months === 12) return 'ano'
  return `${months} meses`
}

const limitLabel = (value, label) => {
  if (value === null || value === undefined) return `Ilimitado ${label}`
  return `${value} ${label}`
}

const formatDate = (value) => {
  if (!value) return '-'
  return new Date(`${value}T00:00:00`).toLocaleDateString('pt-BR')
}

const statusLabel = (status) => {
  const labels = {
    pending: 'Pendente',
    active: 'Ativa',
    overdue: 'Em atraso',
    canceled: 'Cancelada',
    expired: 'Expirada'
  }

  return labels[status] || status || '-'
}

const statusBadgeClass = (status) => {
  if (status === 'canceled' && !subscriptionExpired.value) return 'badge-warning-soft'

  const classes = {
    pending: 'badge-warning-soft',
    active: 'badge-success-soft',
    overdue: 'badge-danger-soft',
    canceled: 'badge-secondary-soft',
    expired: 'badge-dark-soft'
  }

  return classes[status] || 'badge-secondary-soft'
}

const statusDotClass = (sub) => {
  if (!sub) return 'is-inactive'
  if (sub.expired) return 'is-expired'
  if (sub.canceled_but_still_available) return 'is-warning'
  if (sub.status === 'active') return 'is-active'
  return 'is-inactive'
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.plans-page {
  padding-bottom: 2rem;
}

.hero-card {
  background:
    radial-gradient(circle at top left, rgba(13, 110, 253, 0.18), transparent 35%),
    linear-gradient(135deg, rgba(13, 110, 253, 0.08), rgba(13, 110, 253, 0.02));
  border: 1px solid var(--bs-border-color-translucent);
  border-radius: 24px;
  padding: 2rem;
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.08);
}

.eyebrow-badge {
  display: inline-flex;
  align-items: center;
  padding: 0.45rem 0.9rem;
  border-radius: 999px;
  background: rgba(13, 110, 253, 0.12);
  color: var(--bs-primary);
  font-size: 0.8rem;
  font-weight: 700;
}

.page-title {
  font-size: clamp(1.8rem, 2vw, 2.6rem);
  font-weight: 800;
  letter-spacing: -0.02em;
}

.page-subtitle {
  color: var(--bs-secondary-color);
  max-width: 720px;
  font-size: 1rem;
}

.hero-side-card {
  border: 1px solid var(--bs-border-color-translucent);
  background: rgba(255, 255, 255, 0.45);
  backdrop-filter: blur(12px);
  border-radius: 20px;
  padding: 1.25rem;
}

[data-bs-theme='dark'] .hero-side-card {
  background: rgba(255, 255, 255, 0.04);
}

.status-dot {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  display: inline-block;
}

.status-dot.is-active {
  background: #22c55e;
  box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.15);
}

.status-dot.is-warning {
  background: #f59e0b;
  box-shadow: 0 0 0 6px rgba(245, 158, 11, 0.15);
}

.status-dot.is-expired {
  background: #ef4444;
  box-shadow: 0 0 0 6px rgba(239, 68, 68, 0.15);
}

.status-dot.is-inactive {
  background: #6c757d;
}

.current-plan-wrapper {
  margin-top: 0.25rem;
}

.current-plan-card {
  border: 1px solid rgba(13, 110, 253, 0.2);
  border-radius: 24px;
  padding: 1.75rem;
  background: linear-gradient(135deg, rgba(13, 110, 253, 0.18), rgba(13, 110, 253, 0.05));
  box-shadow: 0 15px 40px rgba(13, 110, 253, 0.12);
}

.current-plan-badge {
  background: var(--bs-primary);
  color: white;
}

.current-plan-title {
  font-size: 1.75rem;
  font-weight: 800;
  letter-spacing: -0.02em;
}

.current-plan-description {
  color: var(--bs-secondary-color);
  max-width: 760px;
}

.price-panel {
  border: 1px solid var(--bs-border-color-translucent);
  border-radius: 20px;
  padding: 1.25rem;
  background: rgba(255, 255, 255, 0.35);
  min-width: 220px;
}

[data-bs-theme='dark'] .price-panel {
  background: rgba(255, 255, 255, 0.03);
}

.current-price {
  font-size: 2rem;
  font-weight: 800;
  color: var(--bs-primary);
  line-height: 1;
}

.section-title {
  font-size: 1.25rem;
  font-weight: 800;
}

.section-subtitle {
  color: var(--bs-secondary-color);
}

.pricing-card {
  height: 100%;
  border-radius: 24px;
  border: 1px solid var(--bs-border-color-translucent);
  background: var(--bs-body-bg);
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.05);
  transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease;
}

.pricing-card:hover {
  transform: translateY(-6px);
  box-shadow: 0 16px 36px rgba(0, 0, 0, 0.08);
}

.pricing-card.is-highlight {
  border-color: rgba(13, 110, 253, 0.45);
  box-shadow: 0 16px 36px rgba(13, 110, 253, 0.12);
}

.pricing-card.is-current {
  border: 2px solid #22c55e;
  box-shadow: 0 0 0 4px rgba(34, 197, 94, 0.1);
}

.pricing-card-inner {
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  height: 100%;
}

.plan-name {
  font-size: 1.4rem;
  font-weight: 800;
  letter-spacing: -0.02em;
}

.plan-description {
  color: var(--bs-secondary-color);
  font-size: 0.95rem;
}

.featured-badge {
  background: var(--bs-primary);
  color: white;
}

.current-badge {
  background: rgba(25, 135, 84, 0.12);
  color: #198754;
  border: 1px solid rgba(25, 135, 84, 0.18);
}

.price-area {
  padding: 1rem 0;
  border-top: 1px solid var(--bs-border-color-translucent);
  border-bottom: 1px solid var(--bs-border-color-translucent);
}

.old-price-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.old-price {
  color: var(--bs-secondary-color);
  text-decoration: line-through;
  font-size: 0.95rem;
}

.discount-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  padding: 0.2rem 0.55rem;
  font-size: 0.75rem;
  font-weight: 700;
  background: rgba(220, 53, 69, 0.12);
  color: #dc3545;
}

.main-price {
  font-size: 2.4rem;
  font-weight: 900;
  background: linear-gradient(90deg, #0d6efd, #3b82f6);
  background-clip: text;
  -webkit-background-clip: text;
  color: transparent;
  -webkit-text-fill-color: transparent;
}

.price-period {
  color: var(--bs-secondary-color);
  margin-bottom: 0.25rem;
}

.features-box {
  display: grid;
  gap: 0.75rem;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 0.65rem;
  color: var(--bs-body-color);
  font-size: 0.95rem;
}

.feature-item i {
  color: #16a34a;
  font-size: 1rem;
}

.action-btn {
  min-height: 46px;
}

.loading-state {
  min-height: 240px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.custom-modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.5);
  backdrop-filter: blur(4px);
  z-index: 2100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.custom-modal {
  width: 100%;
  max-width: 720px;
  max-height: 90vh;
  overflow-y: auto;
  border-radius: 24px;
}

.cancel-eyebrow {
  display: inline-flex;
  align-items: center;
  padding: 0.35rem 0.8rem;
  border-radius: 999px;
  background: rgba(220, 53, 69, 0.1);
  color: #dc3545;
  font-size: 0.78rem;
  font-weight: 700;
}

.badge-success-soft {
  background: rgba(34, 197, 94, 0.12);
  color: #22c55e;
}

.badge-warning-soft {
  background: rgba(245, 158, 11, 0.12);
  color: #f59e0b;
}

.badge-danger-soft {
  background: rgba(239, 68, 68, 0.12);
  color: #ef4444;
}

.badge-secondary-soft {
  background: rgba(108, 117, 125, 0.12);
  color: #6c757d;
}

.badge-dark-soft {
  background: rgba(33, 37, 41, 0.12);
  color: #212529;
}

@media (max-width: 991.98px) {
  .hero-card,
  .current-plan-card {
    padding: 1.25rem;
  }

  .pricing-card-inner {
    padding: 1.25rem;
  }

  .main-price {
    font-size: 1.85rem;
  }

  .current-price {
    font-size: 1.65rem;
  }
}
</style>
