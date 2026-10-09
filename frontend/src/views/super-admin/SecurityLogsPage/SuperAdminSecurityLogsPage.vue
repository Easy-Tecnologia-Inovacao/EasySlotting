<template>
  <SuperAdminLayout>
    <div class="security-logs-page">
      <!-- Header -->
      <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
        <div class="header-overlay"></div>
        <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1">
          <div class="d-flex align-items-center gap-3">
            <div class="header-icon-container bg-danger bg-opacity-10 text-danger rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
              <i class="bi bi-shield-lock fs-3"></i>
            </div>
            <div>
              <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Logs de Segurança</h1>
              <p class="text-muted mb-0 small-text-responsive">Monitore logins, tentativas falhas e atividades suspeitas em todos os estabelecimentos.</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Resumo de Segurança -->
      <div class="row g-3 mb-4">
        <div class="col-md-3">
          <div class="admin-card shadow-sm p-3 text-center">
            <div class="fs-2 fw-bold text-primary">{{ summary.logins_24h || 0 }}</div>
            <div class="small text-muted fw-bold">Logins (24h)</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="admin-card shadow-sm p-3 text-center">
            <div class="fs-2 fw-bold" :class="summary.failed_logins_24h > 0 ? 'text-danger' : 'text-success'">
              {{ summary.failed_logins_24h || 0 }}
            </div>
            <div class="small text-muted fw-bold">Falhas (24h)</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="admin-card shadow-sm p-3 text-center">
            <div class="fs-2 fw-bold" :class="summary.suspicious_ip_count > 0 ? 'text-warning' : 'text-success'">
              {{ summary.suspicious_ip_count || 0 }}
            </div>
            <div class="small text-muted fw-bold">IPs Suspeitos</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="admin-card shadow-sm p-3 text-center">
            <div class="fs-2 fw-bold text-info">{{ totalLogs }}</div>
            <div class="small text-muted fw-bold">Total de Logs</div>
          </div>
        </div>
      </div>

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
              <option value="login">Login</option>
              <option value="login_failed">Login Falhou</option>
              <option value="logout">Logout</option>
              <option value="password_change">Mudança de Senha</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label small fw-bold text-muted">Estabelecimento</label>
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
            <button class="btn btn-primary btn-sm w-100 rounded-pill fw-bold" @click="fetchLogs">
              <i class="bi bi-search me-1"></i>Buscar
            </button>
          </div>
        </div>
      </div>

      <!-- Tabela de Logs -->
      <div class="admin-card shadow-sm">
        <div class="d-flex align-items-center justify-content-between mb-3 border-bottom pb-3">
          <h5 class="fw-bold mb-0">Atividade Recente</h5>
          <span class="badge bg-secondary">{{ totalLogs }} registros</span>
        </div>

        <div v-if="loading" class="text-center py-4">
          <div class="spinner-border text-primary" role="status"></div>
        </div>

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

        <!-- Paginação -->
        <div v-if="totalPages > 1" class="d-flex justify-content-center mt-3 pt-3 border-top">
          <nav>
            <ul class="pagination pagination-sm mb-0">
              <li class="page-item" :class="{ disabled: currentPage === 1 }">
                <button class="page-link" @click="goToPage(currentPage - 1)">Anterior</button>
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
                <button class="page-link" @click="goToPage(currentPage + 1)">Próxima</button>
              </li>
            </ul>
          </nav>
        </div>
      </div>
    </div>
  </SuperAdminLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import SuperAdminLayout from '@/views/super-admin/Layout/SuperAdminLayout.vue'
import { api } from '@/services/api'

const loading = ref(false)
const logs = ref([])
const summary = ref({})
const totalLogs = ref(0)
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

const fetchLogs = async () => {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      per_page: 50,
      ...filters.value
    }

    Object.keys(params).forEach(key => {
      if (!params[key]) delete params[key]
    })

    const { data } = await api.get('/super_admin/audit_logs', { params })
    logs.value = data.logs
    totalLogs.value = data.pagination.total_count
    totalPages.value = data.pagination.total_pages
  } catch (error) {
    console.error('Erro ao buscar logs:', error)
  } finally {
    loading.value = false
  }
}

const fetchSummary = async () => {
  try {
    const { data } = await api.get('/super_admin/audit_logs/security_summary')
    summary.value = data.summary
  } catch (error) {
    console.error('Erro ao buscar resumo:', error)
  }
}

const fetchEstablishments = async () => {
  try {
    const { data } = await api.get('/super_admin/dashboard')
    establishments.value = data.establishments || []
  } catch (error) {
    console.error('Erro ao buscar estabelecimentos:', error)
  }
}

const clearFilters = () => {
  filters.value = { action_type: '', establishment_id: '', start_date: '', end_date: '' }
  currentPage.value = 1
  fetchLogs()
}

const goToPage = (page) => {
  if (page < 1 || page > totalPages.value) return
  currentPage.value = page
  fetchLogs()
}

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

const getActionLabel = (action) => {
  const labels = {
    'login': 'Login',
    'login_failed': 'Falha',
    'logout': 'Logout',
    'password_change': 'Senha'
  }
  return labels[action] || action
}

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

.dashboard-header {
  background: var(--bs-tertiary-bg);
  border: 1px solid var(--card-border);
}

.header-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(13, 110, 253, 0.05), rgba(111, 66, 193, 0.05));
}

.header-icon-container {
  width: 56px;
  height: 56px;
}

.text-gradient {
  background: linear-gradient(135deg, #0d6efd, #6610f2);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
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
