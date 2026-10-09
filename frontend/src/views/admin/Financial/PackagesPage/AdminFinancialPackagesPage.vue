<template>
  <AdminLayout>
    <section class="page-shell">
      <div class="page-content">

        <!-- Header com visual premium (idêntico à Dashboard Financeira) -->
        <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
          <div class="header-overlay"></div>
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1 w-100">
            <div class="d-flex align-items-center gap-3">
              <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                <i class="bi bi-box2-fill fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Análise de Pacotes Mensais</h1>
                <p class="text-muted mb-0 small-text-responsive">Acompanhe de forma clara os indicadores, preços, duração e oportunidades comerciais dos pacotes.</p>
              </div>
            </div>

            <button class="btn btn-primary rounded-pill fw-bold px-4 py-2.5 shadow-sm transition-all hover-lift" @click="carregarPacotes" :disabled="loading">
              <i class="bi bi-arrow-clockwise me-2"></i>Atualizar dados
            </button>
          </div>
        </div>

        <!-- Filtro de Período -->
        <div class="admin-card shadow-sm mb-4">
          <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap gap-2">
            <div>
              <h5 class="fw-bold mb-1">
                <i class="bi bi-funnel me-2 text-primary"></i>
                Filtros do período
              </h5>
              <p class="small text-muted mb-0">
                Escolha um período rápido ou defina datas específicas para analisar os pacotes cadastrados.
              </p>
            </div>

            <div class="d-flex gap-2 flex-wrap">
              <button
                class="btn btn-outline-secondary rounded-pill fw-bold px-4"
                :disabled="loading"
                @click="limparFiltros"
              >
                Limpar filtros
              </button>

              <button
                class="btn btn-primary rounded-pill fw-bold px-4 shadow-sm"
                :disabled="loading"
                @click="carregarPacotes"
              >
                <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
                Aplicar filtros
              </button>
            </div>
          </div>

          <div class="row g-3 align-items-end">
            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">Atalho de período</label>
              <select class="form-select custom-input fw-bold" v-model="periodo">
                <option value="hoje">Hoje</option>
                <option value="7dias">Últimos 7 dias</option>
                <option value="30dias">Últimos 30 dias</option>
                <option value="6meses">Últimos 6 meses</option>
                <option value="1ano">Último ano</option>
              </select>
            </div>

            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">Data de início</label>
              <input type="date" class="form-control custom-input fw-bold" v-model="dataDe">
            </div>

            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">Data de fim</label>
              <input type="date" class="form-control custom-input fw-bold" v-model="dataAte">
            </div>

            <div class="col-md-3">
              <div class="small text-muted fw-bold mb-1">Status do catálogo</div>
              <div class="text-muted small">
                {{ totalPacotes }} pacote(s) cadastrado(s)
              </div>
            </div>
          </div>

          <div v-if="erro" class="alert alert-danger rounded-4 mt-3 mb-0">
            {{ erro }}
          </div>
        </div>

        <div v-if="loading" class="admin-card mb-4">
          <div class="d-flex align-items-center gap-3">
            <div class="spinner-border text-primary" role="status"></div>
            <div>
              <div class="fw-bold">Carregando informações dos pacotes...</div>
              <small class="text-muted">Aguarde enquanto os dados do período selecionado são atualizados.</small>
            </div>
          </div>
        </div>

        <template v-else>
          <!-- Sub-páginas com exatamente a mesma paleta de botões e abas da Dashboard -->
          <ul class="nav nav-pills gap-2 mb-4 flex-wrap">
            <li v-for="tab in tabs" :key="tab.id">
              <button
                class="nav-link rounded-pill fw-bold px-4 py-2"
                :class="{ active: activeTab === tab.id }"
                @click="activeTab = tab.id"
              >
                <i :class="tab.icon + ' me-2'"></i>{{ tab.label }}
              </button>
            </li>
          </ul>

          <!-- SUB-PÁGINA 1: VISÃO GERAL -->
          <div v-if="activeTab === 'visao-geral'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Entenda a Gestão de Pacotes Mensais:</strong>
                <span class="banner-text">
                  Os <strong>Pacotes Mensais</strong> permitem fidelizar clientes com serviços combinados. Aqui você analisa o total de pacotes <strong>Ativos</strong>, o <strong>Preço Médio</strong> cobrado, a <strong>Duração Média</strong> dos atendimentos e alertas para decisão.
                </span>
              </div>
            </div>

            <!-- Cards de KPIs Padronizados com a Paleta Oficial -->
            <div class="row g-3 mb-4">
              <div class="col-md-6 col-xl-3">
                <div class="metric-card metric-card-primary h-100">
                  <div class="metric-icon"><i class="bi bi-box"></i></div>
                  <div>
                    <span class="metric-label">Total de pacotes</span>
                    <h3 class="metric-value">{{ totalPacotes }}</h3>
                    <small class="metric-helper">Quantidade total no catálogo</small>
                  </div>
                </div>
              </div>

              <div class="col-md-6 col-xl-3">
                <div class="metric-card metric-card-success h-100">
                  <div class="metric-icon"><i class="bi bi-check-circle"></i></div>
                  <div>
                    <span class="metric-label">Pacotes ativos</span>
                    <h3 class="metric-value">{{ ativos }}</h3>
                    <small class="metric-helper">Liberados para venda ao cliente</small>
                  </div>
                </div>
              </div>

              <div class="col-md-6 col-xl-3">
                <div class="metric-card metric-card-warning h-100">
                  <div class="metric-icon"><i class="bi bi-cash-stack"></i></div>
                  <div>
                    <span class="metric-label">Preço médio</span>
                    <h3 class="metric-value">R$ {{ formatMoney(ticketMedio) }}</h3>
                    <small class="metric-helper">Valor médio cobrado</small>
                  </div>
                </div>
              </div>

              <div class="col-md-6 col-xl-3">
                <div class="metric-card metric-card-danger h-100">
                  <div class="metric-icon"><i class="bi bi-pause-circle"></i></div>
                  <div>
                    <span class="metric-label">Pacotes inativos</span>
                    <h3 class="metric-value">{{ inativos }}</h3>
                    <small class="metric-helper">Pacotes pausados/revisão</small>
                  </div>
                </div>
              </div>
            </div>

            <!-- Resumo e Insights -->
            <div class="row g-4 mb-4">
              <div class="col-12 col-xxl-7">
                <div class="admin-card h-100">
                  <div class="section-header mb-3">
                    <div>
                      <h5 class="fw-bold mb-1"><i class="bi bi-bar-chart-line me-2 text-primary"></i>Resumo de catálogo</h5>
                      <p class="small text-muted mb-0">Visão sintética das faixas de preço e duração.</p>
                    </div>
                  </div>
                  <div class="row g-3">
                    <div class="col-sm-6">
                      <div class="summary-box">
                        <span class="summary-label">Maior preço</span>
                        <h5 class="summary-value">{{ pacoteMaisCaro?.name || '-' }}</h5>
                        <small class="text-muted">R$ {{ formatMoney(pacoteMaisCaro?.price || 0) }}</small>
                      </div>
                    </div>
                    <div class="col-sm-6">
                      <div class="summary-box">
                        <span class="summary-label">Menor preço</span>
                        <h5 class="summary-value">{{ pacoteMaisBarato?.name || '-' }}</h5>
                        <small class="text-muted">R$ {{ formatMoney(pacoteMaisBarato?.price || 0) }}</small>
                      </div>
                    </div>
                    <div class="col-sm-6">
                      <div class="summary-box">
                        <span class="summary-label">Maior duração</span>
                        <h5 class="summary-value">{{ maiorDuracao?.name || '-' }}</h5>
                        <small class="text-muted">{{ maiorDuracao?.duration_minutes || 0 }} min</small>
                      </div>
                    </div>
                    <div class="col-sm-6">
                      <div class="summary-box">
                        <span class="summary-label">Duração média</span>
                        <h5 class="summary-value">{{ mediaDuracao }} min</h5>
                        <small class="text-muted">Tempo médio por atendimento</small>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div class="col-12 col-xxl-5">
                <div class="admin-card h-100">
                  <div class="section-header mb-3">
                    <div>
                      <h5 class="fw-bold mb-1"><i class="bi bi-lightbulb me-2 text-warning"></i>Insights para decisão</h5>
                      <p class="small text-muted mb-0">Leituras rápidas para apoiar sua estratégia.</p>
                    </div>
                  </div>
                  <div class="d-flex flex-column gap-3">
                    <div class="alert-item primary">
                      <i class="bi bi-box2-heart text-primary fs-4"></i>
                      <div>
                        <strong class="d-block">{{ ativos }} pacotes ativos</strong>
                        <small class="text-muted">Disponíveis para venda e agendamento</small>
                      </div>
                    </div>
                    <div class="alert-item success">
                      <i class="bi bi-currency-dollar text-success fs-4"></i>
                      <div>
                        <strong class="d-block">R$ {{ formatMoney(ticketMedio) }} preço médio</strong>
                        <small class="text-muted">Ticket médio estimado dos pacotes</small>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- SUB-PÁGINA 2: CATÁLOGO DE PACOTES -->
          <div v-if="activeTab === 'catalogo'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-box2-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Catálogo Completo de Pacotes:</strong>
                <span class="banner-text">
                  Listagem de todos os pacotes ofertados. Veja o status, a duração estimada, o preço cobrado e a relação de serviços inclusos em cada pacote.
                </span>
              </div>
            </div>

            <div class="admin-card">
              <div class="section-header mb-4">
                <div>
                  <h5 class="fw-bold mb-1"><i class="bi bi-table me-2 text-primary"></i>Tabela de Pacotes Cadastrados</h5>
                  <p class="small text-muted mb-0">Consulte e acompanhe as regras de cada pacote da sua empresa.</p>
                </div>
              </div>

              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead>
                    <tr>
                      <th>Nome do Pacote</th>
                      <th>Status</th>
                      <th>Duração Estimada</th>
                      <th>Preço de Venda</th>
                      <th>Serviços Inclusos</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="!pacotes.length">
                      <td colspan="5" class="text-center text-muted py-4">Nenhum pacote encontrado com os filtros selecionados.</td>
                    </tr>
                    <tr v-for="pacote in pacotes" :key="pacote.id">
                      <td class="fw-bold">{{ pacote.name }}</td>
                      <td>
                        <span
                          class="badge rounded-pill px-3 py-2 fw-bold border"
                          :class="pacote.active
                            ? 'bg-success bg-opacity-10 text-success border-success'
                            : 'bg-secondary bg-opacity-10 text-secondary border-secondary'"
                        >
                          {{ pacote.active ? 'Ativo' : 'Inativo' }}
                        </span>
                      </td>
                      <td>{{ pacote.duration_minutes }} min</td>
                      <td class="fw-bold text-success">R$ {{ formatMoney(pacote.price) }}</td>
                      <td>{{ pacote.items?.join(', ') || 'Nenhum item' }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- SUB-PÁGINA 3: DESEMPENHO & RANKING -->
          <div v-if="activeTab === 'desempenho'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-trophy-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Ranking e Posicionamento de Valor:</strong>
                <span class="banner-text">
                  Compare os pacotes pelo valor de venda e identifique a participação de cada um no portfólio da sua empresa.
                </span>
              </div>
            </div>

            <div class="admin-card mb-4">
              <div class="section-header mb-4">
                <div>
                  <h5 class="fw-bold mb-1"><i class="bi bi-trophy me-2 text-primary"></i>Ranking de Preço dos Pacotes</h5>
                  <p class="small text-muted mb-0">Pacotes ordenados do maior para o menor valor.</p>
                </div>
              </div>

              <div v-if="!rankingPacotes.length" class="text-muted small">Nenhum pacote no período.</div>

              <div v-else class="d-flex flex-column gap-3">
                <div v-for="(pacote, index) in rankingPacotes" :key="pacote.id" class="rank-card">
                  <div class="rank-number">{{ index + 1 }}</div>
                  <div class="flex-grow-1">
                    <div class="d-flex justify-content-between align-items-center gap-3 flex-wrap mb-2">
                      <div>
                        <strong>{{ pacote.name }}</strong>
                        <small class="d-block text-muted">{{ pacote.duration_minutes }} min de duração</small>
                      </div>
                      <div class="text-end">
                        <strong class="text-success d-block">R$ {{ formatMoney(pacote.price) }}</strong>
                        <small class="text-muted">{{ pacote.active ? 'Ativo' : 'Inativo' }}</small>
                      </div>
                    </div>
                    <div class="progress custom-progress">
                      <div class="progress-bar" role="progressbar" :style="{ width: pacote.percentual + '%' }"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- SUB-PÁGINA 4: PREÇOS & DURAÇÃO -->
          <div v-if="activeTab === 'insights'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-tag-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Relação Preço vs. Tempo de Atendimento:</strong>
                <span class="banner-text">
                  Analise a relação entre o valor cobrado e o tempo exigido para a prestação dos serviços do pacote.
                </span>
              </div>
            </div>

            <div class="row g-4">
              <div class="col-md-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-tag me-2 text-primary"></i>Extremos de Valor</h5>
                  <div class="d-flex flex-column gap-3">
                    <div class="p-3 rounded-4 summary-box">
                      <span class="small text-muted fw-bold d-block mb-1">Pacote com maior preço</span>
                      <h4 class="fw-bold text-success mb-1">R$ {{ formatMoney(pacoteMaisCaro?.price || 0) }}</h4>
                      <div class="fw-bold">{{ pacoteMaisCaro?.name || '-' }}</div>
                      <small class="text-muted">{{ pacoteMaisCaro?.duration_minutes || 0 }} min de duração</small>
                    </div>
                    <div class="p-3 rounded-4 summary-box">
                      <span class="small text-muted fw-bold d-block mb-1">Pacote com menor preço</span>
                      <h4 class="fw-bold text-primary mb-1">R$ {{ formatMoney(pacoteMaisBarato?.price || 0) }}</h4>
                      <div class="fw-bold">{{ pacoteMaisBarato?.name || '-' }}</div>
                      <small class="text-muted">{{ pacoteMaisBarato?.duration_minutes || 0 }} min de duração</small>
                    </div>
                  </div>
                </div>
              </div>

              <div class="col-md-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-clock me-2 text-primary"></i>Extremos de Tempo</h5>
                  <div class="d-flex flex-column gap-3">
                    <div class="p-3 rounded-4 summary-box">
                      <span class="small text-muted fw-bold d-block mb-1">Pacote com maior duração</span>
                      <h4 class="fw-bold text-warning mb-1">{{ maiorDuracao?.duration_minutes || 0 }} min</h4>
                      <div class="fw-bold">{{ maiorDuracao?.name || '-' }}</div>
                      <small class="text-muted">R$ {{ formatMoney(maiorDuracao?.price || 0) }}</small>
                    </div>
                    <div class="p-3 rounded-4 summary-box">
                      <span class="small text-muted fw-bold d-block mb-1">Média geral de duração</span>
                      <h4 class="fw-bold text-info mb-1">{{ mediaDuracao }} min</h4>
                      <div class="fw-bold">Tempo médio estimado</div>
                      <small class="text-muted">Calculado sobre todo o catálogo</small>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>

      </div>
    </section>
  </AdminLayout>
</template>

<script setup lang="ts">

import { computed, onMounted, ref } from 'vue'
import { api } from '@/services/api'
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'

const loading = ref(false)
const erro = ref('')

const activeTab = ref('visao-geral')

const tabs = [
  { id: 'visao-geral', label: 'Visão Geral', icon: 'bi bi-eye' },
  { id: 'catalogo', label: 'Catálogo de Pacotes', icon: 'bi bi-box2' },
  { id: 'desempenho', label: 'Desempenho & Ranking', icon: 'bi bi-trophy' },
  { id: 'insights', label: 'Preços & Duração', icon: 'bi bi-currency-dollar' }
]

const periodo = ref('30dias')
const dataDe = ref('')
const dataAte = ref('')

interface PackageItem {
  id: number
  name: string
  price: number
  duration_minutes: number
  description: string
  active: boolean
  items: any[]
  percentual?: number
}

const pacotes = ref<PackageItem[]>([])
const summary = ref({
  total_pacotes: 0,
  ativos: 0,
  inativos: 0,
  ticket_medio: 0,
  percentual_ativos: 0,
  percentual_inativos: 0,
  media_duracao: 0
})

const highlights = ref<{
  pacote_mais_caro: PackageItem | null
  pacote_mais_barato: PackageItem | null
  maior_duracao: PackageItem | null
}>({
  pacote_mais_caro: null,
  pacote_mais_barato: null,
  maior_duracao: null
})

const rankingPacotes = ref<PackageItem[]>([])

function formatMoney(v: number | string | null | undefined): string {
  return Number(v || 0).toFixed(2).replace('.', ',')
}

function montarParams() {
  return {
    period: !dataDe.value && !dataAte.value ? periodo.value : undefined,
    date_from: dataDe.value || undefined,
    date_to: dataAte.value || undefined
  }
}

function normalizarPacote(item: any): PackageItem {
  return {
    id: Number(item?.id || 0),
    name: item?.name || 'Pacote',
    price: Number(item?.price || 0),
    duration_minutes: Number(item?.duration_minutes || 0),
    description: item?.description || '',
    active: Boolean(item?.active),
    items: Array.isArray(item?.items) ? item.items : []
  }
}

async function carregarPacotes() {
  // P-2: validação de intervalo de datas antes de enviar ao servidor
  if (dataDe.value && dataAte.value && dataDe.value > dataAte.value) {
    erro.value = 'A data de início não pode ser posterior à data de fim.'
    return
  }

  loading.value = true
  erro.value = ''

  try {
    const { data } = await api.get('/financial/packages', {
      params: montarParams()
    })

    summary.value = {
      total_pacotes: Number(data?.summary?.total_pacotes || 0),
      ativos: Number(data?.summary?.ativos || 0),
      inativos: Number(data?.summary?.inativos || 0),
      ticket_medio: Number(data?.summary?.ticket_medio || 0),
      percentual_ativos: Number(data?.summary?.percentual_ativos || 0),
      percentual_inativos: Number(data?.summary?.percentual_inativos || 0),
      media_duracao: Number(data?.summary?.media_duracao || 0)
    }

    highlights.value = {
      pacote_mais_caro: data?.highlights?.pacote_mais_caro
        ? normalizarPacote(data.highlights.pacote_mais_caro)
        : null,
      pacote_mais_barato: data?.highlights?.pacote_mais_barato
        ? normalizarPacote(data.highlights.pacote_mais_barato)
        : null,
      maior_duracao: data?.highlights?.maior_duracao
        ? normalizarPacote(data.highlights.maior_duracao)
        : null
    }

    const lista = Array.isArray(data?.packages)
      ? data.packages.map(normalizarPacote)
      : []

    pacotes.value = lista

    const ordenados = [...lista].sort((a, b) => b.price - a.price)
    const maiorValor = ordenados[0]?.price || 1

    rankingPacotes.value = ordenados.map((p) => ({
      ...p,
      percentual: Math.round((p.price / maiorValor) * 100)
    }))
  } catch (e: any) {
    // P-1: sem verificação de token — o servidor rejeita se não autenticado
    const serverMsg = e?.response?.data?.error
    erro.value = serverMsg || 'Não foi possível carregar as informações dos pacotes.'
  } finally {
    loading.value = false
  }
}

function limparFiltros() {
  periodo.value = '30dias'
  dataDe.value = ''
  dataAte.value = ''
  carregarPacotes()
}

const totalPacotes = computed(() => summary.value.total_pacotes)
const ativos = computed(() => summary.value.ativos)
const inativos = computed(() => summary.value.inativos)
const ticketMedio = computed(() => summary.value.ticket_medio)

const percentualAtivos = computed(() => summary.value.percentual_ativos)
const percentualInativos = computed(() => summary.value.percentual_inativos)
const mediaDuracao = computed(() => summary.value.media_duracao)

const pacoteMaisCaro = computed(() => highlights.value.pacote_mais_caro)
const pacoteMaisBarato = computed(() => highlights.value.pacote_mais_barato)
const maiorDuracao = computed(() => highlights.value.maior_duracao)

onMounted(() => {
  carregarPacotes()
})
</script>

<style scoped>
.page-shell {
  width: 100%;
  min-width: 100%;
  max-width: 100%;
  display: block;
}

.page-content {
  width: 100%;
  min-width: 100%;
  max-width: 100% !important;
  display: block;
}

.dashboard-header {
  background: rgba(var(--bs-body-bg-rgb), 0.4) !important;
  border: 1px solid var(--card-border) !important;
  backdrop-filter: blur(12px) !important;
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
  padding: 10px 14px;
  border: 1px solid var(--card-border);
  background-color: var(--bs-body-bg);
  color: var(--bs-body-color);
  transition: all 0.2s;
}

.custom-input:focus {
  border-color: var(--bs-primary);
  box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.15);
}

/* Nav Pills idênticos à Dashboard e Comissões */
.nav-pills .nav-link {
  color: var(--bs-secondary-color);
  border: 1px solid transparent;
  background: rgba(var(--bs-body-color-rgb), 0.02);
  transition: all 0.2s;
}

.nav-pills .nav-link.active {
  background: var(--bs-primary) !important;
  color: #ffffff !important;
  box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3);
}

.nav-pills .nav-link:not(.active):hover {
  background: rgba(var(--bs-body-color-rgb), 0.06);
  border-color: var(--card-border);
}

/* Banner Explicativo com Alto Contraste */
.explanation-banner {
  background: rgba(13, 110, 253, 0.06) !important;
  border: 1px solid rgba(13, 110, 253, 0.18) !important;
  border-radius: 16px !important;
}

.banner-title {
  color: var(--bs-body-color, #212529) !important;
  font-weight: 800;
}

.banner-text {
  color: var(--bs-secondary-color, #6c757d) !important;
}

[data-bs-theme="dark"] .explanation-banner {
  background: rgba(13, 110, 253, 0.15) !important;
  border-color: rgba(13, 110, 253, 0.35) !important;
}

[data-bs-theme="dark"] .banner-title {
  color: #ffffff !important;
}

[data-bs-theme="dark"] .banner-text {
  color: #cbd5e1 !important;
}

[data-bs-theme="dark"] .banner-text strong {
  color: #60a5fa !important;
}

.metric-card {
  border-radius: 20px;
  padding: 1.3rem 1.5rem;
  display: flex;
  align-items: flex-start;
  gap: 14px;
  border: 1px solid var(--card-border);
  background: rgba(var(--bs-body-color-rgb), 0.015);
  backdrop-filter: blur(10px);
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.02);
}

.metric-card:hover {
  transform: translateY(-4px) scale(1.01);
  box-shadow: 0 10px 25px var(--card-shadow) !important;
}

.metric-card-primary { border-left: 4px solid var(--bs-primary); }
.metric-card-success { border-left: 4px solid var(--bs-success); }
.metric-card-warning { border-left: 4px solid var(--bs-warning); }
.metric-card-danger { border-left: 4px solid var(--bs-danger); }

.metric-icon {
  width: 52px;
  height: 52px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(13, 110, 253, 0.1);
  color: var(--bs-primary);
  font-size: 1.25rem;
  flex-shrink: 0;
}

.metric-label { display: block; font-size: 0.8rem; color: var(--bs-secondary-color); font-weight: 700; margin-bottom: 4px; }
.metric-value { font-weight: 900; margin-bottom: 4px; }
.metric-helper { color: var(--bs-secondary-color); font-size: 0.75rem; }

.summary-box {
  padding: 1rem;
  border-radius: 16px;
  background: rgba(var(--bs-body-color-rgb), 0.015);
  border: 1px solid var(--card-border);
}

.summary-label { font-size: 0.75rem; font-weight: 700; color: var(--bs-secondary-color); text-transform: uppercase; }
.summary-value { font-size: 1.1rem; font-weight: 800; margin: 0.3rem 0; }

.alert-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 0.85rem 1rem;
  border-radius: 14px;
  border: 1px solid var(--card-border);
  background: rgba(var(--bs-body-color-rgb), 0.01);
  transition: all 0.2s;
}

.alert-item:hover { transform: translateY(-2px); box-shadow: 0 4px 12px var(--card-shadow); }
.alert-item.primary { border-left: 4px solid var(--bs-primary); }
.alert-item.success { border-left: 4px solid var(--bs-success); }
.alert-item.warning { border-left: 4px solid var(--bs-warning); }
.alert-item.danger { border-left: 4px solid var(--bs-danger); }

.rank-card {
  padding: 1rem;
  border-radius: 16px;
  background: rgba(var(--bs-body-color-rgb), 0.015);
  border: 1px solid var(--card-border);
  display: flex;
  align-items: center;
  gap: 1rem;
}

.rank-number {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: var(--bs-primary);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 800;
  font-size: 0.85rem;
}

.custom-progress {
  height: 6px;
  background: rgba(var(--bs-body-color-rgb), 0.08);
  border-radius: 10px;
}

.table-clean th {
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  color: var(--bs-secondary-color);
  border-bottom: 1px solid var(--card-border);
  padding: 12px 16px;
}

.table-clean td {
  padding: 12px 16px;
  border-bottom: 1px solid rgba(var(--bs-body-color-rgb), 0.05);
}
</style>