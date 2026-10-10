<template>
  <SuperAdminLayout>
    <div class="container-fluid">
      <!-- Header com painel em gradiente (hero-card) -->
      <section class="hero-card mb-4">
        <div class="row align-items-center g-4">
          <div class="col-12 col-xl-8">
            <span class="eyebrow-badge mb-3">
              <i class="bi bi-box-seam me-1"></i> Gerenciamento
            </span>
            <h1 class="page-title mb-2">Gerenciar planos</h1>
            <p class="page-subtitle mb-0">
              Aqui o super admin altera preços, promoções, destaque e configurações dos planos.
            </p>
          </div>
          <div class="col-12 col-xl-4 text-xl-end">
            <button class="btn btn-primary rounded-3 fw-semibold px-4 py-2 shadow-sm" :disabled="loading || !hasLoaded || saving || deletingPlanId !== null || catalogFull" @click="openCreateModal">
              <i class="bi bi-plus-lg me-2"></i>
              Novo plano
            </button>
          </div>
        </div>
      </section>

      <div v-if="!loading" class="alert alert-info rounded-4">
        <strong>{{ activePlanCount }} de 4 faixas de plano em uso.</strong>
        Cada plano ativo tem um limite exclusivo de 1, 2, 3 ou 4 sessões por conta de proprietário ou funcionário.
        Você pode usar só as faixas que desejar; não precisa criar quatro planos nem oferecer quatro sessões.
        Cadastre do menor para o maior: cada novo plano ativo deve ter preço normal e sessões maiores que os anteriores.
        Um upgrade substitui o limite anterior, sem somar sessões.
        <span v-if="catalogFull">O maior plano já oferece 4 sessões. Edite ou inative esse plano antes de cadastrar um superior.</span>
      </div>

      <div v-if="loading" class="text-center py-5">
        <div class="spinner-border" role="status"></div>
        <p class="mt-3 text-secondary mb-0">Carregando planos...</p>
      </div>

      <div v-else-if="!hasLoaded && errorMessage" class="alert alert-danger rounded-4" role="alert">
        <p>{{ errorMessage }}</p>
        <button type="button" class="btn btn-outline-danger" @click="loadPlans">Tentar novamente</button>
      </div>
      <div v-else-if="hasLoaded" class="card plans-table-card">
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table align-middle mb-0">
              <thead>
                <tr>
                  <th class="px-4 py-3">Plano</th>
                  <th class="py-3">Preço</th>
                  <th class="py-3">Duração</th>
                  <th class="py-3">Sessões do proprietário</th>
                  <th class="py-3">Status</th>
                  <th class="py-3">Promoção</th>
                  <th class="py-3 text-end pe-4">Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="plan in plans" :key="plan.id">
                  <td class="px-4 py-3">
                    <div class="fw-semibold d-flex align-items-center gap-2">
                      {{ plan.name }}
                      <span v-if="plan.highlight" class="badge rounded-pill text-bg-primary">
                        Destaque
                      </span>
                    </div>
                    <div class="small text-secondary">Código: {{ plan.code }}</div>
                  </td>

                  <td>
                    <div class="fw-semibold">R$ {{ formatPrice(plan.price) }}</div>
                    <div v-if="plan.promotional_price !== null && plan.promotional_price !== undefined" class="small text-success">
                      Promo: R$ {{ formatPrice(plan.promotional_price) }}
                    </div>
                  </td>

                  <td>{{ periodLabel(plan.duration_months) }}</td>

                  <td>{{ plan.max_owner_sessions ?? 1 }} {{ (plan.max_owner_sessions ?? 1) === 1 ? 'sessão' : 'sessões' }}</td>

                  <td>
                    <span
                      class="badge rounded-pill"
                      :class="plan.active ? 'text-bg-success' : 'text-bg-secondary'"
                    >
                      {{ plan.active ? 'Ativo' : 'Inativo' }}
                    </span>
                  </td>

                  <td>
                    <span
                      class="badge rounded-pill"
                      :class="plan.promotion_active ? 'text-bg-warning' : 'bg-secondary bg-opacity-25 text-secondary border border-secondary border-opacity-25'"
                    >
                      {{ promotionLabel(plan) }}
                    </span>
                  </td>

                  <td class="text-end pe-4">
                    <div class="d-flex justify-content-end gap-2">
                      <button
                        type="button"
                        class="btn btn-sm btn-outline-primary rounded-3"
                        :disabled="saving || deletingPlanId !== null"
                        @click="openEditModal(plan)"
                      >
                        Editar
                      </button>
                      <button
                        type="button"
                        class="btn btn-sm btn-outline-danger rounded-3"
                        :disabled="saving || deletingPlanId !== null"
                        :aria-label="`Excluir plano ${plan.name}`"
                        @click="deletePlan(plan)"
                      >
                        {{ deletingPlanId === plan.id ? 'Excluindo...' : 'Excluir' }}
                      </button>
                    </div>
                  </td>
                </tr>

                <tr v-if="plans.length === 0">
                  <td colspan="7" class="text-center py-5 text-secondary">
                    Nenhum plano encontrado.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div v-if="successMessage" class="alert alert-success rounded-4 mt-4 shadow-sm" role="status">
        {{ successMessage }}
      </div>

      <div v-if="hasLoaded && errorMessage" class="alert alert-danger rounded-4 mt-4 shadow-sm" role="alert">
        {{ errorMessage }}
      </div>
    </div>

    <div v-if="showModal" class="custom-modal-backdrop">
      <div class="card border-0 shadow rounded-4 custom-modal">
        <div class="card-body p-4 p-lg-5">

          <!-- ── Cabeçalho ── -->
          <div class="d-flex justify-content-between align-items-start mb-4">
            <div>
              <span class="badge rounded-pill text-bg-primary mb-2">
                <i class="bi bi-box me-1"></i>
                {{ editingPlanId ? 'Editar plano' : 'Novo plano' }}
              </span>
              <h3 class="fw-bold mb-1">
                {{ editingPlanId ? 'Atualizar plano' : 'Cadastrar novo plano' }}
              </h3>
              <p class="text-secondary mb-0 small">
                Preencha as informações abaixo. Campos marcados com <span class="text-danger">*</span> são obrigatórios.
              </p>
            </div>
            <button type="button" class="btn-close ms-3 flex-shrink-0" aria-label="Fechar" @click="closeModal"></button>
          </div>

          <!-- ══ SEÇÃO 1 — Identificação ══ -->
          <div class="modal-section mb-4">
            <div class="modal-section-title">
              <i class="bi bi-tag-fill text-primary me-2"></i>
              Identificação
            </div>
            <div class="row g-3 mt-1">

              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">
                  Nome do plano <span class="text-danger">*</span>
                </label>
                <input
                  v-model="form.name"
                  type="text"
                  class="form-control rounded-3"
                  placeholder="Ex: Plano Profissional, Plano Básico..."
                  maxlength="100"
                />
                <div class="form-text">
                  <i class="bi bi-info-circle me-1"></i>
                  Nome visível para os clientes na página de planos. Mínimo 2 caracteres.
                </div>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">
                  Código único <span class="text-danger">*</span>
                </label>
                <div class="input-group">
                  <span class="input-group-text rounded-start-3">
                    <i class="bi bi-hash"></i>
                  </span>
                  <input
                    v-model="form.code"
                    type="text"
                    class="form-control rounded-end-3"
                    placeholder="ex: plano-basico, pro_mensal"
                    maxlength="50"
                  />
                </div>
                <div class="form-text">
                  <i class="bi bi-shield-check me-1"></i>
                  Identificador interno único — apenas letras minúsculas, números, hífens e underscores. Não pode ser alterado após uso em assinaturas.
                </div>
              </div>

              <div class="col-12">
                <label class="form-label fw-semibold">Descrição</label>
                <textarea
                  v-model="form.description"
                  rows="2"
                  class="form-control rounded-3"
                  placeholder="Descreva o que está incluído neste plano. Ex: Acesso completo a agendamentos, relatórios e até 5 funcionários..."
                  maxlength="500"
                ></textarea>
                <div class="form-text">
                  <i class="bi bi-chat-left-text me-1"></i>
                  Texto exibido abaixo do nome do plano. Máximo 500 caracteres.
                </div>
              </div>

            </div>
          </div>

          <!-- ══ SEÇÃO 2 — Preço & Duração ══ -->
          <div class="modal-section mb-4">
            <div class="modal-section-title">
              <i class="bi bi-currency-dollar text-success me-2"></i>
              Preço &amp; Duração
            </div>
            <div class="row g-3 mt-1">

              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">
                  Preço normal (R$) <span class="text-danger">*</span>
                </label>
                <div class="input-group">
                  <span class="input-group-text rounded-start-3 fw-semibold">R$</span>
                  <input
                    v-model="form.price"
                    type="number"
                    step="0.01"
                    min="0.01"
                    class="form-control rounded-end-3"
                    placeholder="0,00"
                  />
                </div>
                <div class="form-text">
                  <i class="bi bi-info-circle me-1"></i>
                  Valor cobrado por período. Deve ser maior que zero.
                  Respeite a ordem crescente dos planos; promoções não alteram essa ordem.
                </div>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold">
                  Duração do plano <span class="text-danger">*</span>
                </label>
                <div class="input-group">
                  <input
                    v-model="form.duration_months"
                    type="number"
                    min="1"
                    max="24"
                    class="form-control rounded-start-3"
                    placeholder="1"
                  />
                  <span class="input-group-text rounded-end-3">meses</span>
                </div>
                <div class="form-text">
                  <i class="bi bi-calendar3 me-1"></i>
                  Por quantos meses o plano é válido após a contratação. Ex: 1 = mensal, 12 = anual.
                </div>
              </div>

            </div>
          </div>

          <!-- ══ SEÇÃO 3 — Limites do Plano ══ -->
          <div class="modal-section mb-4">
            <div class="modal-section-title">
              <i class="bi bi-sliders text-warning me-2"></i>
              Limites do Plano
              <span class="badge rounded-pill bg-secondary bg-opacity-25 text-secondary border border-secondary border-opacity-25 ms-2 fw-normal small">
                Campos opcionais em branco: ilimitado
              </span>
            </div>
            <div class="row g-3 mt-1">

              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">
                  <i class="bi bi-people me-1 text-secondary"></i>
                  Máx. funcionários
                </label>
                <input
                  v-model="form.max_employees"
                  type="number"
                  min="0"
                  class="form-control rounded-3"
                  placeholder="Ilimitado"
                />
                <div class="form-text">Quantos colaboradores o estabelecimento pode cadastrar.</div>
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">
                  <i class="bi bi-scissors me-1 text-secondary"></i>
                  Máx. serviços
                </label>
                <input
                  v-model="form.max_services"
                  type="number"
                  min="0"
                  class="form-control rounded-3"
                  placeholder="Ilimitado"
                />
                <div class="form-text">Quantidade de serviços que podem ser cadastrados no catálogo.</div>
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label fw-semibold">
                  <i class="bi bi-calendar-check me-1 text-secondary"></i>
                  Máx. agendamentos/mês
                </label>
                <input
                  v-model="form.max_appointments_per_month"
                  type="number"
                  min="0"
                  class="form-control rounded-3"
                  placeholder="Ilimitado"
                />
                <div class="form-text">Pendentes, confirmados e concluídos no mês do atendimento. Cancelados liberam vaga.</div>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label fw-semibold" for="ownerSessionLimit">
                  <i class="bi bi-laptop me-1 text-secondary"></i>
                  Aparelhos simultâneos por conta da equipe <span class="text-danger">*</span>
                </label>
                <select id="ownerSessionLimit" v-model.number="form.max_owner_sessions" class="form-select rounded-3">
                  <option v-for="limit in 4" :key="limit" :value="limit" :disabled="form.active && (isSessionLimitUsed(limit) || isSessionLimitOutOfOrder(limit))">
                    {{ limit }} {{ limit === 1 ? 'sessão' : 'sessões' }}{{ form.active && isSessionLimitUsed(limit) ? ' — em uso por outro plano' : form.active && isSessionLimitOutOfOrder(limit) ? ' — fora da ordem crescente' : '' }}
                  </option>
                </select>
                <div class="form-text">
                  Escolha de 1 a 4 sessões. A quantidade não pode se repetir entre planos ativos.
                  Planos cadastrados depois devem oferecer mais sessões.
                  Aplica-se separadamente ao proprietário e a cada funcionário vinculado. Clientes não têm teto de aparelhos.
                </div>
              </div>

            </div>
          </div>

          <!-- ══ SEÇÃO 4 — Configurações ══ -->
          <div class="modal-section mb-4">
            <div class="modal-section-title">
              <i class="bi bi-toggles text-info me-2"></i>
              Visibilidade &amp; Status
            </div>
            <div class="row g-3 mt-1">

              <div class="col-12 col-md-4">
                <label class="config-check-card d-block mb-0" :class="{ 'active': form.active }">
                  <div class="d-flex align-items-start gap-3">
                    <input v-model="form.active" class="form-check-input mt-1 flex-shrink-0" type="checkbox" id="activeCheck" />
                    <div>
                      <div class="form-check-label fw-semibold d-block">
                        <i class="bi bi-eye me-1"></i> Plano ativo
                      </div>
                      <div class="form-text mt-0">
                        Planos ativos aparecem para novos clientes na página de contratação. Desative para pausar sem excluir.
                      </div>
                    </div>
                  </div>
                </label>
              </div>

              <div class="col-12 col-md-4">
                <label class="config-check-card d-block mb-0" :class="{ 'active': form.highlight }">
                  <div class="d-flex align-items-start gap-3">
                    <input v-model="form.highlight" class="form-check-input mt-1 flex-shrink-0" type="checkbox" id="highlightCheck" />
                    <div>
                      <div class="form-check-label fw-semibold d-block">
                        <i class="bi bi-star me-1"></i> Plano em destaque
                      </div>
                      <div class="form-text mt-0">
                        Marca o plano com um badge "Recomendado" para guiar a escolha do cliente. Use em apenas 1 plano por vez.
                      </div>
                    </div>
                  </div>
                </label>
              </div>

              <div class="col-12 col-md-4">
                <label class="config-check-card promo d-block mb-0" :class="{ 'active': form.promotion_active }">
                  <div class="d-flex align-items-start gap-3">
                    <input
                      v-model="form.promotion_active"
                      class="form-check-input mt-1 flex-shrink-0"
                      type="checkbox"
                      id="promotionCheck"
                    />
                    <div>
                      <div class="form-check-label fw-semibold d-block">
                        <i class="bi bi-lightning me-1"></i> Promoção ativa
                      </div>
                      <div class="form-text mt-0">
                        Habilita o preço promocional por tempo limitado. Os campos abaixo serão liberados.
                      </div>
                    </div>
                  </div>
                </label>
              </div>

            </div>
          </div>

          <!-- ══ SEÇÃO 5 — Promoção (condicional) ══ -->
          <transition name="promo-slide">
            <div v-if="form.promotion_active" class="modal-section modal-section--promo mb-4">
              <div class="modal-section-title">
                <i class="bi bi-lightning-charge-fill text-warning me-2"></i>
                Configuração da Promoção
                <span class="badge rounded-pill text-bg-warning ms-2 fw-normal small">Ativa</span>
              </div>
              <div class="row g-3 mt-1">

                <div class="col-12">
                  <label class="form-label fw-semibold" for="promotionMode">Definir desconto por</label>
                  <select id="promotionMode" v-model="form.promotion_mode" class="form-select rounded-3">
                    <option value="price">Preço promocional</option>
                    <option value="percentage">Percentual</option>
                  </select>
                </div>
                <div class="col-12 col-md-4">
                  <label class="form-label fw-semibold">Preço promocional (R$)</label>
                  <div class="input-group">
                    <span class="input-group-text rounded-start-3 promo-addon fw-semibold">R$</span>
                    <input
                      v-model="form.promotional_price"
                      :disabled="form.promotion_mode !== 'price'"
                      type="number"
                      step="0.01"
                      min="0"
                      class="form-control rounded-end-3"
                      placeholder="0,00"
                    />
                  </div>
                  <div class="form-text">
                    <i class="bi bi-info-circle me-1"></i>
                    Deve ser menor que o preço normal. O desconto (%) será calculado automaticamente.
                  </div>
                </div>

                <div class="col-12 col-md-4">
                  <label class="form-label fw-semibold">Desconto (%)</label>
                  <div class="input-group">
                    <input
                      v-model="form.discount_percentage"
                      :disabled="form.promotion_mode !== 'percentage'"
                      type="number"
                      min="0"
                      max="100"
                      class="form-control rounded-start-3"
                      placeholder="Ex: 20"
                    />
                    <span class="input-group-text rounded-end-3 promo-addon">%</span>
                  </div>
                  <div class="form-text">
                    Alternativa ao preço promocional — preencha um ou outro, não os dois.
                  </div>
                </div>

                <div class="col-12 col-md-4">
                  <label class="form-label fw-semibold">
                    Início da promoção <span class="text-danger">*</span>
                  </label>
                  <input
                    v-model="form.promotion_starts_at"
                    type="datetime-local"
                    class="form-control rounded-3"
                  />
                  <div class="form-text">
                    <i class="bi bi-calendar-event me-1"></i>
                    Data e hora no fuso local deste navegador em que o preço promocional passa a valer.
                  </div>
                </div>

                <div class="col-12 col-md-4">
                  <label class="form-label fw-semibold">
                    Duração da promoção (dias) <span class="text-danger">*</span>
                  </label>
                  <div class="input-group">
                    <input
                      v-model="form.promotion_duration_days"
                      type="number"
                      min="1"
                      max="365"
                      class="form-control rounded-start-3"
                      placeholder="Ex: 30"
                    />
                    <span class="input-group-text rounded-end-3">dias</span>
                  </div>
                  <div class="form-text">
                    <i class="bi bi-hourglass-split me-1"></i>
                    A data de término será calculada automaticamente a partir do início. Máximo 365 dias.
                  </div>
                </div>

                <div v-if="form.promotion_starts_at && form.promotion_duration_days" class="col-12">
                  <div class="alert alert-warning rounded-3 py-2 mb-0 d-flex align-items-center gap-2 small">
                    <i class="bi bi-clock-history fs-5"></i>
                    <span>
                      Promoção ativa de
                      <strong>{{ formatDatePreview(form.promotion_starts_at) }}</strong>
                      até
                      <strong>{{ calcEndDate(form.promotion_starts_at, form.promotion_duration_days) }}</strong>
                    </span>
                  </div>
                </div>

              </div>
            </div>
          </transition>

          <!-- ── Erros de validação ── -->
          <div v-if="errorMessage" class="alert alert-danger rounded-3 mt-2 mb-0" role="alert">{{ errorMessage }}</div>
          <div v-if="validationErrors.length > 0" class="alert alert-warning rounded-3 mt-2 mb-0">
            <div class="fw-semibold mb-1"><i class="bi bi-exclamation-triangle me-1"></i> Corrija os erros antes de salvar:</div>
            <ul class="mb-0 ps-3">
              <li v-for="(err, i) in validationErrors" :key="i">{{ err }}</li>
            </ul>
          </div>

          <!-- ── Botões ── -->
          <div class="d-flex justify-content-end gap-2 mt-4">
            <button class="btn btn-outline-secondary rounded-3 px-4" @click="closeModal">
              Cancelar
            </button>
            <button class="btn btn-primary rounded-3 px-4" :disabled="saving" @click="savePlan">
              <i class="bi bi-floppy me-2"></i>
              {{ saving ? 'Salvando...' : 'Salvar plano' }}
            </button>
          </div>

        </div>
      </div>
    </div>
  </SuperAdminLayout>
</template>


<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '@/services/api'
import SuperAdminLayout from '@/views/super-admin/Layout/SuperAdminLayout.vue'

const plans = ref([])
const loading = ref(true)
const hasLoaded = ref(false)
const saving = ref(false)
const deletingPlanId = ref(null)
const successMessage = ref('')
const showModal = ref(false)
const editingPlanId = ref(null)
const errorMessage = ref('')
const validationErrors = ref([])

const getEmptyForm = () => ({
  name: '',
  code: '',
  description: '',
  price: '',
  duration_months: 1,
  max_employees: '',
  max_services: '',
  max_appointments_per_month: '',
  max_owner_sessions: 1,
  active: true,
  highlight: false,
  promotional_price: '',
  promotion_mode: 'price',
  discount_percentage: '',
  promotion_active: false,
  promotion_starts_at: '',
  promotion_duration_days: ''
})

const form = ref(getEmptyForm())
const activePlanCount = computed(() => plans.value.filter(plan => plan.active).length)
const highestActiveSessionLimit = computed(() => Math.max(0,
  ...plans.value.filter(plan => plan.active).map(plan => Number(plan.max_owner_sessions))
))
const catalogFull = computed(() => highestActiveSessionLimit.value >= 4)
const otherActivePlans = computed(() => plans.value.filter(plan => plan.active && plan.id !== editingPlanId.value))
const isSessionLimitUsed = (limit) => plans.value.some(plan =>
  plan.active && plan.id !== editingPlanId.value && Number(plan.max_owner_sessions) === limit
)
const isEarlierPlan = (plan) => !editingPlanId.value || Number(plan.id) < Number(editingPlanId.value)
const isSessionLimitOutOfOrder = (limit) => otherActivePlans.value.some(plan =>
  isEarlierPlan(plan) ? limit <= Number(plan.max_owner_sessions) : limit >= Number(plan.max_owner_sessions)
)

const loadPlans = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await api.get('/super_admin/plans')
    if (!Array.isArray(response.data)) throw new Error('Resposta inválida')
    plans.value = response.data
    hasLoaded.value = true
  } catch (error) {
    hasLoaded.value = false
    errorMessage.value = 'Não foi possível carregar os planos. Tente novamente.'
  } finally {
    loading.value = false
  }
}

const openCreateModal = () => {
  if (loading.value || !hasLoaded.value || saving.value || deletingPlanId.value !== null || catalogFull.value) return
  successMessage.value = ''
  editingPlanId.value = null
  form.value = getEmptyForm()
  form.value.max_owner_sessions = Math.min(highestActiveSessionLimit.value + 1, 4)
  errorMessage.value = ''
  validationErrors.value = []
  showModal.value = true
}

const openEditModal = (plan) => {
  if (!hasLoaded.value || saving.value || deletingPlanId.value !== null) return
  successMessage.value = ''
  errorMessage.value = ''
  validationErrors.value = []
  editingPlanId.value = plan.id
  form.value = {
    name: plan.name || '',
    code: plan.code || '',
    description: plan.description || '',
    price: plan.price ?? '',
    duration_months: plan.duration_months ?? 1,
    max_employees: plan.max_employees ?? '',
    max_services: plan.max_services ?? '',
    max_appointments_per_month: plan.max_appointments_per_month ?? '',
    max_owner_sessions: plan.max_owner_sessions ?? 1,
    active: !!plan.active,
    highlight: !!plan.highlight,
    promotional_price: plan.promotional_price ?? '',
    promotion_mode: 'price',
    discount_percentage: plan.discount_percentage ?? '',
    promotion_active: !!plan.promotion_active,
    promotion_starts_at: formatDateTimeLocal(plan.promotion_starts_at),
    promotion_duration_days: plan.promotion_duration_days ?? ''
  }
  showModal.value = true
}

const deletePlan = async (plan) => {
  if (loading.value || !hasLoaded.value || saving.value || deletingPlanId.value !== null || showModal.value) return
  if (!window.confirm(`Excluir o plano "${plan.name}"? Esta ação não pode ser desfeita. Planos com assinaturas vinculadas não podem ser excluídos.`)) return

  deletingPlanId.value = plan.id
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await api.delete(`/super_admin/plans/${encodeURIComponent(plan.id)}`)
    plans.value = plans.value.filter(item => item.id !== plan.id)
    successMessage.value = 'Plano excluído com sucesso.'
  } catch (error) {
    const serverMsg = error?.response?.data?.error
    errorMessage.value = typeof serverMsg === 'string' && serverMsg.length < 300
      ? serverMsg
      : 'Não foi possível excluir o plano. Atualize a lista e tente novamente.'
  } finally {
    deletingPlanId.value = null
  }
}

const closeModal = () => {
  showModal.value = false
  validationErrors.value = []
  errorMessage.value = ''
}

const validateForm = () => {
  const errors = []
  const f = form.value

  if (!f.name || f.name.trim().length < 2 || f.name.trim().length > 100) {
    errors.push('Nome deve ter entre 2 e 100 caracteres.')
  }
  if (!f.code || f.code.trim().length === 0) {
    errors.push('Código é obrigatório.')
  } else if (f.code.trim().length > 50 || !/^[a-z0-9_-]+$/.test(f.code.trim())) {
    errors.push('Código deve conter apenas letras minúsculas, números, hífens e underscores.')
  }
  const price = normalizeNumber(f.price)
  if (!Number.isFinite(price) || price <= 0 || price >= 100000) {
    errors.push('Preço deve ser maior que zero e menor que R$ 100.000.')
  } else if (f.active && otherActivePlans.value.some(plan =>
    isEarlierPlan(plan) ? price <= Number(plan.price) : price >= Number(plan.price)
  )) {
    errors.push('O preço normal deve crescer conforme a ordem de cadastro dos planos ativos.')
  }
  const months = normalizeInteger(f.duration_months)
  if (!Number.isInteger(months) || months <= 0 || months > 24) {
    errors.push('Duração deve estar entre 1 e 24 meses.')
  }
  if (f.promotion_active) {
    const startsAt = new Date(f.promotion_starts_at)
    if (!f.promotion_starts_at || Number.isNaN(startsAt.getTime()) || startsAt.getFullYear() < 1 || startsAt.getFullYear() > 9998) {
      errors.push('Informe um início válido para a promoção, entre os anos 1 e 9998.')
    }
    const days = normalizeNullableInteger(f.promotion_duration_days)
    if (!Number.isInteger(days) || days <= 0 || days > 365) {
      errors.push('Duração da promoção deve ser entre 1 e 365 dias.')
    }
    const promoPrice = normalizeNullableNumber(f.promotional_price)
    if (f.promotion_mode === 'price' && (promoPrice === null || !Number.isFinite(promoPrice) || promoPrice < 0 || promoPrice >= price)) {
      errors.push('Preço promocional deve ser informado, não negativo e menor que o preço normal.')
    }
    const discount = normalizeNullableInteger(f.discount_percentage)
    if (f.promotion_mode === 'percentage' && (!Number.isInteger(discount) || discount < 1 || discount > 100)) {
      errors.push('Desconto deve ser um inteiro entre 1 e 100.')
    }
  }

  const maxEmp = normalizeNullableInteger(f.max_employees)
  if (maxEmp !== null && (!Number.isInteger(maxEmp) || maxEmp < 0 || maxEmp > 2147483647)) {
    errors.push('Máx. funcionários deve ser um inteiro entre 0 e 2147483647, ou ficar em branco.')
  }
  const maxServ = normalizeNullableInteger(f.max_services)
  if (maxServ !== null && (!Number.isInteger(maxServ) || maxServ < 0 || maxServ > 2147483647)) {
    errors.push('Máx. serviços deve ser um inteiro entre 0 e 2147483647, ou ficar em branco.')
  }
  const maxApp = normalizeNullableInteger(f.max_appointments_per_month)
  if (maxApp !== null && (!Number.isInteger(maxApp) || maxApp < 0 || maxApp > 2147483647)) {
    errors.push('Máx. agendamentos/mês deve ser um inteiro entre 0 e 2147483647, ou ficar em branco.')
  }

  if (!Number.isInteger(Number(f.max_owner_sessions)) || Number(f.max_owner_sessions) < 1 || Number(f.max_owner_sessions) > 4) {
    errors.push('Aparelhos simultâneos do proprietário deve estar entre 1 e 4.')
  } else if (f.active && isSessionLimitUsed(Number(f.max_owner_sessions))) {
    errors.push('Esse limite já pertence a outro plano ativo. Escolha uma faixa disponível ou inative o outro plano.')
  } else if (f.active && isSessionLimitOutOfOrder(Number(f.max_owner_sessions))) {
    errors.push('As sessões devem crescer conforme a ordem de cadastro dos planos ativos.')
  }

  return errors
}

const savePlan = async () => {
  if (loading.value || !hasLoaded.value || saving.value || deletingPlanId.value !== null) return
  errorMessage.value = ''
  validationErrors.value = []

  const errors = validateForm()
  if (errors.length > 0) {
    validationErrors.value = errors
    return
  }

  saving.value = true

  const payload = {
    plan: {
      name: form.value.name,
      code: form.value.code,
      description: form.value.description,
      price: normalizeNumber(form.value.price),
      duration_months: normalizeInteger(form.value.duration_months),
      max_employees: normalizeNullableInteger(form.value.max_employees),
      max_services: normalizeNullableInteger(form.value.max_services),
      max_appointments_per_month: normalizeNullableInteger(form.value.max_appointments_per_month),
      max_owner_sessions: Number(form.value.max_owner_sessions),
      active: form.value.active,
      highlight: form.value.highlight,
      promotion_mode: form.value.promotion_mode,
      promotional_price: form.value.promotion_mode === 'price' ? normalizeNullableNumber(form.value.promotional_price) : null,
      discount_percentage: form.value.promotion_mode === 'percentage' ? normalizeNullableInteger(form.value.discount_percentage) : null,
      promotion_active: form.value.promotion_active,
      promotion_starts_at: form.value.promotion_active && form.value.promotion_starts_at ? new Date(form.value.promotion_starts_at).toISOString() : null,
      promotion_duration_days: normalizeNullableInteger(form.value.promotion_duration_days)
    }
  }

  try {
    if (editingPlanId.value) {
      await api.put(`/super_admin/plans/${editingPlanId.value}`, payload)
    } else {
      await api.post('/super_admin/plans', payload)
    }

    closeModal()
    await loadPlans()
  } catch (error) {
    // Exibe apenas a mensagem genérica do servidor — nunca detalhes de stack trace
    const serverMsg = error?.response?.data?.error
    errorMessage.value = typeof serverMsg === 'string' && serverMsg.length < 300
      ? serverMsg
      : 'Não foi possível salvar o plano. Verifique os dados e tente novamente.'
  } finally {
    saving.value = false
  }
}

const normalizeNumber = (value) => {
  return value === '' || value === null || value === undefined ? 0 : Number(value)
}

const normalizeNullableNumber = (value) => {
  return value === '' || value === null || value === undefined ? null : Number(value)
}

const normalizeInteger = (value) => {
  return value === '' || value === null || value === undefined ? 0 : Number(value)
}

const normalizeNullableInteger = (value) => {
  return value === '' || value === null || value === undefined ? null : Number(value)
}

const formatPrice = (value) => {
  return Number(value || 0).toFixed(2).replace('.', ',')
}

const promotionLabel = (plan) => {
  if (!plan.promotion_active) return 'Desligada'
  const start = new Date(plan.promotion_starts_at).getTime()
  const end = new Date(plan.promotion_ends_at).getTime()
  if (!plan.promotion_starts_at || !plan.promotion_ends_at || !Number.isFinite(start) || !Number.isFinite(end)) return 'Configuração incompleta'
  if (Date.now() < start) return 'Agendada'
  return Date.now() < end ? 'Em andamento' : 'Encerrada'
}

const periodLabel = (months) => {
  if (months === 1) return '1 mês'
  return `${months} meses`
}

const formatDateTimeLocal = (value) => {
  if (!value) return ''

  const date = new Date(value)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hour = String(date.getHours()).padStart(2, '0')
  const minute = String(date.getMinutes()).padStart(2, '0')

  return `${year}-${month}-${day}T${hour}:${minute}`
}

const formatDatePreview = (value) => {
  if (!value) return ''
  const d = new Date(value)
  return d.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

const calcEndDate = (startsAt, durationDays) => {
  if (!startsAt || !durationDays) return ''
  const start = new Date(startsAt)
  const end = new Date(start.getTime() + Number(durationDays) * 24 * 60 * 60 * 1000)
  return end.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

onMounted(() => {
  loadPlans()
})
</script>

<style scoped>
.plans-table-card {
  border: 1px solid var(--bs-border-color);
  border-radius: 24px;
  overflow: hidden;
  background-color: var(--bs-body-bg);
}

.plans-table-card .table {
  --bs-table-bg: var(--bs-body-bg);
  --bs-table-border-color: var(--bs-border-color);
}

.table th {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--bs-secondary-color);
  border-bottom-width: 1px;
}

.table td {
  vertical-align: middle;
}

.table tbody tr:last-child td {
  border-bottom: 0;
}

/* ── Hero Card (Painel em gradiente) ── */
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
  font-size: clamp(1.9rem, 2vw, 2.7rem);
  font-weight: 800;
  letter-spacing: -0.02em;
}

.page-subtitle {
  color: var(--bs-secondary-color);
  max-width: 760px;
  font-size: 1rem;
}

/* ── Backdrop e Modal ── */
.custom-modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.65);
  backdrop-filter: blur(6px);
  z-index: 2100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}

.custom-modal {
  width: 100%;
  max-width: 960px;
  max-height: 92vh;
  overflow-y: auto;
  border-radius: 24px;
  background: var(--bs-body-bg);
  border: 1px solid var(--bs-border-color-translucent) !important;
  box-shadow: 0 24px 64px rgba(0, 0, 0, 0.45) !important;
}

/* ── Seções do modal ── */
.modal-section {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid var(--bs-border-color-translucent, rgba(255, 255, 255, 0.1));
  border-radius: 14px;
  padding: 1.15rem 1.25rem 1.25rem;
}

.modal-section--promo {
  background: rgba(255, 193, 7, 0.06);
  border: 1px solid rgba(255, 193, 7, 0.35);
}

.modal-section-title {
  font-size: 0.8rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--bs-secondary-color);
  display: flex;
  align-items: center;
  margin-bottom: 0.25rem;
}

/* ── Estilos de input no modal ── */
.custom-modal .input-group-text {
  background-color: var(--bs-tertiary-bg);
  border-color: var(--bs-border-color);
  color: var(--bs-secondary-color);
}

.custom-modal .promo-addon {
  background-color: rgba(255, 193, 7, 0.15) !important;
  border-color: rgba(255, 193, 7, 0.35) !important;
  color: #ffc107 !important;
}

.custom-modal .form-text {
  color: var(--bs-secondary-color);
  font-size: 0.775rem;
  line-height: 1.35;
  margin-top: 0.35rem;
}

.custom-modal .form-label {
  color: var(--bs-body-color);
  font-size: 0.875rem;
}

/* ── Cards de checkbox ── */
.config-check-card {
  background: var(--bs-body-bg);
  border: 1.5px solid var(--bs-border-color-translucent, rgba(255, 255, 255, 0.12));
  border-radius: 12px;
  padding: 0.95rem 1rem;
  transition: all 0.2s ease;
  height: 100%;
  cursor: pointer;
  color: var(--bs-body-color);
}

.config-check-card:hover {
  border-color: var(--bs-primary);
  background: rgba(13, 110, 253, 0.06);
}

.config-check-card.active {
  border-color: var(--bs-primary);
  background: rgba(13, 110, 253, 0.12);
  box-shadow: 0 0 0 1px rgba(13, 110, 253, 0.25);
}

.config-check-card.promo:hover {
  border-color: #ffc107;
  background: rgba(255, 193, 7, 0.06);
}

.config-check-card.promo.active {
  border-color: #ffc107;
  background: rgba(255, 193, 7, 0.14);
  box-shadow: 0 0 0 1px rgba(255, 193, 7, 0.25);
}

.config-check-card .form-check-label {
  color: var(--bs-body-color);
  font-size: 0.925rem;
}

.config-check-card .form-text {
  color: var(--bs-secondary-color);
  font-size: 0.775rem;
  line-height: 1.35;
}

/* ── Animação da seção de promoção ── */
.promo-slide-enter-active,
.promo-slide-leave-active {
  transition: all 0.3s ease;
  overflow: hidden;
}

.promo-slide-enter-from,
.promo-slide-leave-to {
  opacity: 0;
  max-height: 0;
  margin-bottom: 0;
  padding-top: 0;
  padding-bottom: 0;
}

.promo-slide-enter-to,
.promo-slide-leave-from {
  opacity: 1;
  max-height: 600px;
}
</style>
