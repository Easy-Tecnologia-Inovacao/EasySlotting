<template>
  <SuperAdminLayout>
    <div class="security-logs-page container-fluid">
      <!-- Header -->
      <SuperAdminPageHeader
        eyebrow="Auditoria"
        icon="bi-shield-lock"
        title="Logs de Segurança"
        subtitle="Monitore logins, tentativas falhas e atividades suspeitas em todos os estabelecimentos."
      />

      <!-- Resumo de Segurança -->
      <div class="row g-3 mb-4">
        <div class="col-md-3">
          <div class="admin-card shadow-sm p-3 text-center">
            <div class="fs-2 fw-bold text-primary">{{ summary.logins_24h ?? '—' }}</div>
            <div class="small text-muted fw-bold">Logins (24h)</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="admin-card shadow-sm p-3 text-center">
            <div class="fs-2 fw-bold" :class="summary.failed_logins_24h == null ? 'text-muted' : summary.failed_logins_24h > 0 ? 'text-danger' : 'text-success'">
              {{ summary.failed_logins_24h ?? '—' }}
            </div>
            <div class="small text-muted fw-bold">Falhas (24h)</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="admin-card shadow-sm p-3 text-center">
            <div class="fs-2 fw-bold" :class="summary.suspicious_ip_count == null ? 'text-muted' : summary.suspicious_ip_count > 0 ? 'text-warning' : 'text-success'">
              {{ summary.suspicious_ip_count ?? '—' }}
            </div>
            <div class="small text-muted fw-bold">IPs Suspeitos</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="admin-card shadow-sm p-3 text-center">
            <div class="fs-2 fw-bold text-info">{{ totalLogs ?? '—' }}</div>
            <div class="small text-muted fw-bold">Total de Logs</div>
          </div>
        </div>
      </div>

      <div v-if="summaryError" class="alert alert-warning" role="alert">{{ summaryError }} <button class="btn btn-sm btn-outline-primary" @click="fetchSummary">Tentar novamente</button></div>
      <p v-if="summaryGeneratedAt" class="small text-muted">Resumo atualizado em {{ formatDate(summaryGeneratedAt) }} (cache de até 2 minutos).</p>
      <!-- Filtros -->
      <div class="admin-card shadow-sm mb-4">
        <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-3">
          <h5 class="fw-bold mb-0">Filtros</h5>
          <button class="btn btn-sm btn-outline-primary rounded-pill" @click="clearFilters">
            <i class="bi bi-x-circle me-1"></i>Limpar
          </button>
        </div>
        <div class="row g-3">
          <div class="col-md-2">
            <label class="form-label small fw-bold text-muted">Tipo de Ação</label>
            <select class="form-select form-select-sm" v-model="filters.action_type">
              <option value="">Todas</option>
              <option v-for="action in actions" :key="action.value" :value="action.value">{{ action.label }}</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label small fw-bold text-muted">Estabelecimento</label>
            <div class="input-group input-group-sm mb-2">
              <input v-model="establishmentQuery" maxlength="100" class="form-control" aria-label="Buscar estabelecimento pelo nome" placeholder="Nome do estabelecimento" @keyup.enter="fetchEstablishments">
              <button class="btn btn-outline-primary" :disabled="optionsLoading" @click="fetchEstablishments">Localizar</button>
            </div>
            <div v-if="optionsError" class="text-danger small" role="alert">{{ optionsError }} <button class="btn btn-link btn-sm" @click="fetchEstablishments">Tentar novamente</button></div>
            <div v-if="hasMoreEstablishments" class="small text-muted">Mostrando 50 opções. Refine a busca pelo nome.</div>
            <select class="form-select form-select-sm" v-model="filters.establishment_id">
              <option value="">Todos</option>
              <option v-for="est in establishments" :key="est.id" :value="est.id">{{ est.name }}</option>
            </select>
          </div>
          <div class="col-md-2">
            <label class="form-label small fw-bold text-muted">Data Início</label>
            <input type="date" class="form-control form-control-sm" v-model="filters.start_date">
          </div>
          <div class="col-md-2">
            <label class="form-label small fw-bold text-muted">Data Fim</label>
            <input type="date" class="form-control form-control-sm" v-model="filters.end_date">
          </div>
          <div class="col-md-3 d-flex align-items-end">
            <button class="btn btn-primary btn-sm w-100 rounded-pill fw-bold" @click="applyFilters">
              <i class="bi bi-search me-1"></i>Buscar
            </button>
          </div>
        </div>
      </div>

      <!-- Tabela de Logs -->
      <div class="admin-card shadow-sm">
        <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-3">
          <h5 class="fw-bold mb-0">Atividade Recente</h5>
          <span class="badge bg-secondary">{{ totalLogs ?? '—' }} registros</span>
        </div>

        <div v-if="loading" class="text-center py-4">
          <div class="spinner-border text-primary" role="status"></div>
        </div>

        <div v-else-if="logsError" class="alert alert-danger" role="alert">{{ logsError }} <button class="btn btn-sm btn-outline-primary" @click="fetchLogs">Tentar novamente</button></div>
        <div v-else-if="logs.length === 0" class="text-center py-5">
          <i class="bi bi-shield-check fs-1 text-success opacity-50"></i>
          <p class="text-muted mt-2">Nenhum log encontrado.</p>
        </div>

        <div v-else class="table-responsive">
          <table class="table table-hover align-middle mb-0">
            <thead>
              <tr>
                <th>Ação</th>
                <th>Usuário</th>
                <th>Estabelecimento</th>
                <th>IP</th>
                <th>Localização</th>
                <th>Dispositivo</th>
                <th>Data/Hora</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="log in logs" :key="log.id">
                <td>
                  <span class="badge rounded-pill" :class="getActionBadge(log.action)">
                    <i :class="getActionIcon(log.action)" class="me-1"></i>
                    {{ getActionLabel(log.action) }}
                  </span>
                </td>
                <td>
                  <div v-if="log.user">
                    <div class="fw-bold small">{{ log.user.name }}</div>
                    <div class="text-muted" style="font-size: 0.75rem;">{{ log.user.email }}</div>
                  </div>
                  <span v-else class="text-muted small">—</span>
                </td>
                <td>
                  <div v-if="log.establishment">
                    <div class="fw-bold small">{{ log.establishment.name }}</div>
                    <div class="text-muted" style="font-size: 0.75rem;">{{ log.establishment.slug }}</div>
                  </div>
                  <span v-else class="text-muted small">—</span>
                </td>
                <td><code class="small">{{ log.ip_address || '—' }}</code></td>
                <td>
                  <div v-if="log.location" class="small">
                    <div class="fw-bold">{{ log.location.city }}</div>
                    <div class="text-muted" style="font-size: 0.7rem;">{{ log.location.region }}, {{ log.location.country }}</div>
                  </div>
                  <span v-else class="text-muted small">—</span>
                </td>
                <td><span class="small">{{ log.device || '—' }}</span></td>
                <td><span class="small text-muted">{{ formatDate(log.timestamp) }}</span></td>
              </tr>
            </tbody>
          </table>
        </div>

        <p v-if="truncated" class="alert alert-info mt-3">Limite de páginas atingido. Refine o período ou os filtros para consultar os demais registros.</p>
        <!-- Paginação -->
        <div v-if="!loading && !logsError && totalPages > 1" class="d-flex justify-content-center mt-3 pt-3 border-top">
          <nav>
            <ul class="pagination pagination-sm mb-0">
              <li class="page-item" :class="{ disabled: currentPage === 1 }">
                <button class="page-link" :disabled="loading || currentPage === 1" @click="goToPage(currentPage - 1)">Anterior</button>
              </li>
              <li
                v-for="page in visiblePages"
                :key="page"
                class="page-item"
                :class="{ active: page === currentPage }"
              >
                <button class="page-link" @click="goToPage(page)">{{ page }}</button>
              </li>
              <li class="page-item" :class="{ disabled: currentPage === totalPages }">
                <button class="page-link" :disabled="loading || currentPage === totalPages" @click="goToPage(currentPage + 1)">Próxima</button>
              </li>
            </ul>
          </nav>
        </div>
      </div>
    </div>
  </SuperAdminLayout>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import SuperAdminLayout from '@/views/super-admin/Layout/SuperAdminLayout.vue'
import SuperAdminPageHeader from '@/components/super-admin/SuperAdminPageHeader.vue'
import { api } from '@/services/api'

const loading = ref(false)
const logs = ref([])
const summary = ref({})
const totalLogs = ref(null)
const currentPage = ref(1)
const totalPages = ref(1)
const establishments = ref([])

const filters = ref({
  action_type: '',
  establishment_id: '',
  start_date: '',
  end_date: ''
})

const visiblePages = computed(() => {
  const pages = []
  const start = Math.max(1, currentPage.value - 2)
  const end = Math.min(totalPages.value, currentPage.value + 2)
  for (let i = start; i <= end; i++) pages.push(i)
  return pages
})

const logsError = ref('')
const summaryError = ref('')
const optionsError = ref('')
const optionsLoading = ref(false)
const summaryGeneratedAt = ref('')
const establishmentQuery = ref('')
const hasMoreEstablishments = ref(false)
const actions = ref([])
const truncated = ref(false)
let alive = true, logsRequest = 0, summaryRequest = 0, optionsRequest = 0
let appliedFilters = { ...filters.value }
const count = value => Number.isSafeInteger(value) && value >= 0

const fetchLogs = async () => {
  const request = ++logsRequest
  loading.value = true
  logsError.value = ''
  logs.value = []
  totalLogs.value = null
  totalPages.value = 0
  truncated.value = false
  try {
    const params = { page: currentPage.value, per_page: 50, ...appliedFilters }
    Object.keys(params).forEach(key => { if (!params[key]) delete params[key] })
    const { data } = await api.get('/super_admin/audit_logs', { params })
    if (!alive || request !== logsRequest) return
    if (!Array.isArray(data?.logs) || !data.logs.every(log => log && count(log.id) && typeof log.action === 'string') ||
        !count(data.pagination?.total_count) || !count(data.pagination?.total_pages)) throw new Error('invalid response')
    logs.value = data.logs
    totalLogs.value = data.pagination.total_count
    totalPages.value = data.pagination.total_pages
    truncated.value = data.pagination.truncated === true
  } catch (error) {
    if (!alive || request !== logsRequest) return
    logsError.value = error?.response?.status === 422
      ? 'Filtros inválidos. Confira os valores e o intervalo de datas.'
      : 'Não foi possível carregar os logs. Tente novamente.'
  } finally {
    if (alive && request === logsRequest) loading.value = false
  }
}

const fetchSummary = async () => {
  const request = ++summaryRequest
  summary.value = {}
  summaryGeneratedAt.value = ''
  summaryError.value = ''
  try {
    const { data } = await api.get('/super_admin/audit_logs/security_summary')
    if (!alive || request !== summaryRequest) return
    if (!['logins_24h', 'failed_logins_24h', 'suspicious_ip_count'].every(key => count(data?.summary?.[key])) ||
        typeof data.generated_at !== 'string' || !Number.isFinite(Date.parse(data.generated_at))) throw new Error('invalid response')
    summary.value = data.summary
    summaryGeneratedAt.value = data.generated_at
  } catch {
    if (alive && request === summaryRequest) summaryError.value = 'Resumo indisponível. Isso não significa ausência de eventos.'
  }
}

const fetchEstablishments = async () => {
  const request = ++optionsRequest
  optionsLoading.value = true
  optionsError.value = ''
  hasMoreEstablishments.value = false
  try {
    const { data } = await api.get('/super_admin/audit_logs/filter_options', { params: { q: establishmentQuery.value } })
    if (!alive || request !== optionsRequest) return
    if (!Array.isArray(data?.establishments) || !data.establishments.every(item => count(item?.id) && typeof item.name === 'string') ||
        !Array.isArray(data.actions) || !data.actions.every(item => typeof item?.value === 'string' && typeof item.label === 'string')) throw new Error('invalid response')
    const selected = establishments.value.find(item => String(item.id) === String(filters.value.establishment_id))
    establishments.value = data.establishments
    if (selected && !establishments.value.some(item => item.id === selected.id)) establishments.value = [selected, ...establishments.value]
    actions.value = data.actions
    hasMoreEstablishments.value = data.has_more === true
  } catch {
    if (alive && request === optionsRequest) optionsError.value = 'Não foi possível carregar as opções de filtro.'
  } finally {
    if (alive && request === optionsRequest) optionsLoading.value = false
  }
}

const applyFilters = () => {
  appliedFilters = { ...filters.value }
  currentPage.value = 1
  return fetchLogs()
}
const clearFilters = () => {
  filters.value = { action_type: '', establishment_id: '', start_date: '', end_date: '' }
  return applyFilters()
}
const goToPage = (page) => {
  if (loading.value || page < 1 || page > totalPages.value) return
  currentPage.value = page
  return fetchLogs()
}
onBeforeUnmount(() => { alive = false; logsRequest++; summaryRequest++; optionsRequest++ })

const getActionBadge = (action) => {
  const badges = {
    'login': 'bg-success bg-opacity-10 text-success',
    'login_failed': 'bg-danger bg-opacity-10 text-danger',
    'logout': 'bg-secondary bg-opacity-10 text-secondary',
    'password_change': 'bg-warning bg-opacity-10 text-warning'
  }
  return badges[action] || 'bg-secondary bg-opacity-10 text-secondary'
}

const getActionIcon = (action) => {
  const icons = {
    'login': 'bi bi-box-arrow-in-right',
    'login_failed': 'bi bi-x-circle',
    'logout': 'bi bi-box-arrow-right',
    'password_change': 'bi bi-key'
  }
  return icons[action] || 'bi bi-circle'
}

const getActionLabel = action => actions.value.find(item => item.value === (action === 'password_changed' ? 'password_change' : action))?.label || action

const formatDate = (dateStr) => {
  if (!dateStr) return '—'
  const d = new Date(dateStr)
  return d.toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

onMounted(() => {
  fetchLogs()
  fetchSummary()
  fetchEstablishments()
})
</script>

<style scoped>
.security-logs-page {
  width: 100%;
  min-height: calc(100vh - 100px);
}

.table {
  width: 100%;
}

.table th {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--bs-secondary-color);
  font-weight: 700;
  white-space: nowrap;
}

.table td {
  vertical-align: middle;
}
</style>
