<template>
  <SuperAdminLayout>
    <div class="super-dashboard container-fluid">

      <!-- Header -->
      <section class="hero-card mb-4">
        <div class="row align-items-center g-4">
          <div class="col-12 col-xl-8">
            <span class="eyebrow-badge mb-3">
              <i class="bi bi-shield-lock-fill me-1"></i> Painel master
            </span>
            <h1 class="page-title mb-2">Dashboard do Super Admin</h1>
            <p class="page-subtitle mb-0">
              Acompanhe planos, assinaturas, receita e os principais indicadores da plataforma em tempo real.
            </p>
          </div>
          <div class="col-12 col-xl-4 text-xl-end">
            <span class="text-muted small">
              <i class="bi bi-clock me-1"></i>
              Atualizado em {{ new Date().toLocaleString('pt-BR') }}
            </span>
          </div>
        </div>
      </section>

      <!-- Loading -->
      <div v-if="loading" class="loading-state text-center py-5">
        <div class="spinner-border text-primary" role="status"></div>
        <p class="mt-3 text-secondary mb-0">Carregando dashboard...</p>
      </div>

      <template v-else>

        <!-- Cards de resumo -->
        <section class="stats-grid mb-4">
          <div class="stat-card">
            <div class="stat-icon bg-primary bg-opacity-10 text-primary">
              <i class="bi bi-stars"></i>
            </div>
            <div class="stat-label">Planos cadastrados</div>
            <div class="stat-value">{{ summary.plans_count }}</div>
          </div>

          <div class="stat-card">
            <div class="stat-icon bg-success bg-opacity-10 text-success">
              <i class="bi bi-check-circle-fill"></i>
            </div>
            <div class="stat-label">Assinaturas ativas</div>
            <div class="stat-value text-success">{{ summary.active_subscriptions_count }}</div>
          </div>

          <div class="stat-card">
            <div class="stat-icon bg-danger bg-opacity-10 text-danger">
              <i class="bi bi-x-circle-fill"></i>
            </div>
            <div class="stat-label">Assinaturas canceladas</div>
            <div class="stat-value text-danger">{{ summary.canceled_subscriptions_count }}</div>
          </div>

          <div class="stat-card">
            <div class="stat-icon bg-info bg-opacity-10 text-info">
              <i class="bi bi-buildings"></i>
            </div>
            <div class="stat-label">Estabelecimentos</div>
            <div class="stat-value">{{ summary.establishments_count }}</div>
            <div class="stat-sub">
              <span class="badge bg-success bg-opacity-10 text-success fw-semibold">
                +{{ summary.new_establishments_this_month }} este mês
              </span>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon bg-secondary bg-opacity-10 text-secondary">
              <i class="bi bi-people-fill"></i>
            </div>
            <div class="stat-label">Clientes cadastrados</div>
            <div class="stat-value">{{ summary.customers_count }}</div>
          </div>

          <div class="stat-card stat-card-revenue">
            <div class="stat-icon bg-warning bg-opacity-10 text-warning">
              <i class="bi bi-cash-coin"></i>
            </div>
            <div class="stat-label">Receita no mês</div>
            <div class="stat-value">R$ {{ formatPrice(summary.monthly_revenue) }}</div>
          </div>
        </section>

        <!-- Gráficos: Assinaturas + Cancelamentos + Tendência de Receita -->
        <section class="row g-4 mb-4">
          <div class="col-12 col-xl-5">
            <div class="chart-card h-100">
              <div class="chart-header">
                <h2 class="chart-title mb-1">Assinaturas por plano</h2>
                <p class="chart-subtitle mb-0">Distribuição por tipo de plano.</p>
              </div>
              <div class="chart-wrapper">
                <Bar :data="subscriptionsByPlanData" :options="barOptions" />
              </div>
            </div>
          </div>

          <div class="col-12 col-xl-3">
            <div class="chart-card h-100">
              <div class="chart-header">
                <h2 class="chart-title mb-1">Motivos de cancelamento</h2>
                <p class="chart-subtitle mb-0">Por que os clientes cancelam.</p>
              </div>
              <div class="chart-wrapper pie-wrapper">
                <Pie :data="cancellationReasonsData" :options="pieOptions" />
              </div>
            </div>
          </div>

          <div class="col-12 col-xl-4">
            <div class="chart-card h-100">
              <div class="chart-header">
                <h2 class="chart-title mb-1">Tendência de receita</h2>
                <p class="chart-subtitle mb-0">Últimos 6 meses.</p>
              </div>
              <div class="chart-wrapper">
                <Line :data="revenueTrendData" :options="lineOptions" />
              </div>
            </div>
          </div>
        </section>

        <!-- Tabela de cancelamentos recentes -->
        <section class="table-card">
          <div class="table-card-header">
            <div>
              <h2 class="table-title mb-1">Cancelamentos recentes</h2>
              <p class="table-subtitle mb-0">
                Use esses dados para entender os principais problemas e melhorar a retenção.
              </p>
            </div>
          </div>

          <div class="table-responsive">
            <table class="table align-middle mb-0">
              <thead>
                <tr>
                  <th class="px-4 py-3">Motivo</th>
                  <th class="py-3">Plano</th>
                  <th class="py-3">Perfil</th>
                  <th class="py-3">Detalhes</th>
                  <th class="py-3 pe-4 text-end">Data</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in recentCancellations" :key="item.id">
                  <td class="px-4 py-3">
                    <span class="badge rounded-pill badge-soft-warning">
                      {{ item.reason }}
                    </span>
                  </td>
                  <td>{{ item.plan_name || '-' }}</td>
                  <td>
                    <span class="badge rounded-pill bg-secondary bg-opacity-10 text-body fw-normal">
                      {{ item.canceled_by_role || '-' }}
                    </span>
                  </td>
                  <td class="text-secondary">{{ item.details || 'Sem detalhes informados.' }}</td>
                  <td class="text-end pe-4 text-muted small">{{ formatDateTime(item.created_at) }}</td>
                </tr>

                <tr v-if="recentCancellations.length === 0">
                  <td colspan="5" class="text-center py-5 text-secondary">
                    <i class="bi bi-check-circle fs-2 d-block mb-2 text-success"></i>
                    Nenhum cancelamento registrado ainda.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <div v-if="errorMessage" class="alert alert-danger rounded-4 mt-4 shadow-sm">
          <i class="bi bi-exclamation-circle-fill me-2"></i>{{ errorMessage }}
        </div>
      </template>
    </div>
  </SuperAdminLayout>
</template>

<script setup>
import { onMounted, ref, computed } from 'vue'
import { api } from '@/services/api'
import SuperAdminLayout from '@/views/super-admin/Layout/SuperAdminLayout.vue'

import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  BarElement,
  LineElement,
  PointElement,
  CategoryScale,
  LinearScale,
  Filler
} from 'chart.js'
import { Pie, Bar, Line } from 'vue-chartjs'

ChartJS.register(Title, Tooltip, Legend, ArcElement, BarElement, LineElement, PointElement, CategoryScale, LinearScale, Filler)

const loading      = ref(true)
const errorMessage = ref('')

const summary = ref({
  plans_count:                   0,
  active_subscriptions_count:    0,
  canceled_subscriptions_count:  0,
  establishments_count:          0,
  customers_count:               0,
  new_establishments_this_month: 0,
  monthly_revenue:               0
})

const subscriptionsByPlan  = ref([])
const cancellationReasons  = ref([])
const recentCancellations  = ref([])
const revenueTrend         = ref([])

const loadDashboard = async () => {
  loading.value      = true
  errorMessage.value = ''

  try {
    const response = await api.get('/super_admin/dashboard')
    summary.value             = response.data?.summary            || summary.value
    subscriptionsByPlan.value = response.data?.charts?.subscriptions_by_plan || []
    cancellationReasons.value = response.data?.charts?.cancellation_reasons  || []
    revenueTrend.value        = response.data?.charts?.revenue_trend          || []
    recentCancellations.value = response.data?.recent_cancellations           || []
  } catch (error) {
    console.error('Erro ao carregar dashboard:', error)
    errorMessage.value = error?.response?.data?.error || 'Não foi possível carregar o dashboard.'
  } finally {
    loading.value = false
  }
}

const chartColors = ['#0d6efd','#6610f2','#198754','#ffc107','#dc3545','#20c997','#fd7e14']

const subscriptionsByPlanData = computed(() => ({
  labels: subscriptionsByPlan.value.map(i => i.name),
  datasets: [{
    label: 'Assinaturas',
    data: subscriptionsByPlan.value.map(i => i.total),
    borderRadius: 8,
    backgroundColor: subscriptionsByPlan.value.map((_, idx) => chartColors[idx % chartColors.length])
  }]
}))

const cancellationReasonsData = computed(() => ({
  labels: cancellationReasons.value.map(i => i.reason),
  datasets: [{
    data: cancellationReasons.value.map(i => i.total),
    backgroundColor: cancellationReasons.value.map((_, idx) => chartColors[idx % chartColors.length]),
    borderWidth: 1,
    borderColor: '#111827'
  }]
}))

const revenueTrendData = computed(() => ({
  labels: revenueTrend.value.map(i => i.month),
  datasets: [{
    label: 'Receita (R$)',
    data: revenueTrend.value.map(i => i.revenue),
    fill: true,
    borderColor: '#0d6efd',
    backgroundColor: 'rgba(13, 110, 253, 0.08)',
    tension: 0.4,
    pointBackgroundColor: '#0d6efd',
    pointRadius: 4
  }]
}))

const barOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } }
}

const pieOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { position: 'bottom' } }
}

const lineOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    y: {
      beginAtZero: true,
      ticks: { callback: (v) => `R$ ${Number(v).toFixed(0)}` }
    }
  }
}

const formatPrice = (value) =>
  Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

const formatDateTime = (value) => {
  if (!value) return '-'
  return new Date(value).toLocaleString('pt-BR')
}

onMounted(() => { loadDashboard() })
</script>

<style scoped>
.super-dashboard {
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
  font-size: clamp(1.9rem, 2vw, 2.7rem);
  font-weight: 800;
  letter-spacing: -0.02em;
}

.page-subtitle {
  color: var(--bs-secondary-color);
  max-width: 760px;
  font-size: 1rem;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 1rem;
}

.stat-card {
  border: 1px solid var(--bs-border-color-translucent);
  border-radius: 22px;
  padding: 1.25rem 1.3rem;
  background: var(--bs-body-bg);
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.05);
  transition: transform 0.2s, box-shadow 0.2s;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 16px 32px rgba(0, 0, 0, 0.09);
}

.stat-card-revenue {
  grid-column: span 1;
}

.stat-icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
  margin-bottom: 0.75rem;
}

.stat-sub {
  margin-top: 0.4rem;
}

.stat-label {
  color: var(--bs-secondary-color);
  font-size: 0.88rem;
  margin-bottom: 0.4rem;
}

.stat-value {
  font-size: 1.9rem;
  font-weight: 800;
  letter-spacing: -0.03em;
}

.chart-card,
.table-card {
  border: 1px solid var(--bs-border-color-translucent);
  border-radius: 24px;
  background: var(--bs-body-bg);
  overflow: hidden;
  box-shadow: 0 10px 24px rgba(0, 0, 0, 0.05);
}

.chart-header,
.table-card-header {
  padding: 1.4rem 1.5rem 1rem;
  border-bottom: 1px solid var(--bs-border-color-translucent);
}

.chart-title,
.table-title {
  font-size: 1.2rem;
  font-weight: 800;
}

.chart-subtitle,
.table-subtitle {
  color: var(--bs-secondary-color);
}

.chart-wrapper {
  height: 360px;
  padding: 1rem 1.5rem 1.5rem;
}

.pie-wrapper {
  height: 360px;
}

.badge-soft-warning {
  background: rgba(245, 158, 11, 0.12);
  color: #d97706;
}

.loading-state {
  min-height: 240px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.table th {
  font-size: 0.8rem;
  font-weight: 800;
  color: var(--bs-secondary-color);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

@media (max-width: 1199.98px) {
  .stats-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 767.98px) {
  .hero-card {
    padding: 1.25rem;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .chart-wrapper,
  .pie-wrapper {
    height: 280px;
  }
}
</style>