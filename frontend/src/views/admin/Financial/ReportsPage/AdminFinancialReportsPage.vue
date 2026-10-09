<template>
  <AdminLayout>
    <section class="page-shell">
      <div class="page-content">
        <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
          <div class="header-overlay"></div>
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1 w-100">
            <div class="d-flex align-items-center gap-3">
              <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                <i class="bi bi-file-earmark-bar-graph fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Relatorios</h1>
                <p class="text-muted mb-0 small-text-responsive">Analise completa do desempenho do seu estabelecimento.</p>
              </div>
            </div>
            <div class="d-flex gap-2">
              <button class="btn btn-primary rounded-pill fw-bold px-4 py-2.5 shadow-sm" @click="carregarRelatorio" :disabled="loading">
                <i class="bi bi-arrow-clockwise me-2"></i>Atualizar
              </button>
            </div>
          </div>
        </div>

        <div v-if="erro" class="alert alert-danger rounded-4 mb-4">{{ erro }}</div>

        <div class="admin-card shadow-sm mb-4">
          <div class="row g-3 align-items-end">
            <div class="col-md-2">
              <label class="form-label small fw-bold text-muted">Periodo</label>
              <select class="form-select custom-input fw-bold" v-model="filters.periodo" @change="aplicarPeriodo">
                <option value="hoje">Hoje</option>
                <option value="7dias">7 dias</option>
                <option value="30dias">30 dias</option>
                <option value="6meses">6 meses</option>
                <option value="1ano">1 ano</option>
              </select>
            </div>
            <div class="col-md-2">
              <label class="form-label small fw-bold text-muted">De</label>
              <input type="date" class="form-control custom-input fw-bold" v-model="filters.dataDe" />
            </div>
            <div class="col-md-2">
              <label class="form-label small fw-bold text-muted">Ate</label>
              <input type="date" class="form-control custom-input fw-bold" v-model="filters.dataAte" />
            </div>
            <div class="col-md-2">
              <label class="form-label small fw-bold text-muted">Profissional</label>
              <select class="form-select custom-input fw-bold" v-model="filters.profissional">
                <option value="todos">Todos</option>
                <option v-for="p in profissionaisOpts" :key="p.value" :value="p.value">{{ p.label }}</option>
              </select>
            </div>
            <div class="col-md-2">
              <label class="form-label small fw-bold text-muted">Servico</label>
              <select class="form-select custom-input fw-bold" v-model="filters.servico">
                <option value="todos">Todos</option>
                <option v-for="s in servicosOpts" :key="s.value" :value="s.value">{{ s.label }}</option>
              </select>
            </div>
            <div class="col-md-2">
              <button class="btn btn-primary rounded-pill fw-bold px-4 w-100" @click="carregarRelatorio" :disabled="loading">
                <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>Aplicar
              </button>
            </div>
          </div>
        </div>

        <div v-if="loading" class="admin-card mb-4">
          <div class="d-flex align-items-center gap-3">
            <div class="spinner-border text-primary" role="status"></div>
            <div class="fw-bold">Carregando relatorios...</div>
          </div>
        </div>

        <template v-else>
          <ul class="nav nav-pills gap-2 mb-4 flex-wrap">
            <li v-for="tab in tabs" :key="tab.id">
              <button class="nav-link rounded-pill fw-bold px-4 py-2" :class="{ active: activeTab === tab.id }" @click="activeTab = tab.id">
                <i :class="tab.icon + ' me-2'"></i>{{ tab.label }}
              </button>
            </li>
          </ul>

          <!-- VISAO GERAL -->
          <div v-if="activeTab === 'visao-geral'">
            <!-- Banner Explicativo sobre Relatórios -->
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Entenda o Relatório Geral do Estabelecimento:</strong>
                <span class="banner-text">
                  Consolidação completa de atendimentos, faturamento bruto, média de ticket por cliente, taxa de cancelamentos e distribuição da receita por dia da semana e canal de agendamento.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-4 col-xl-2" v-for="kpi in kpisGeral" :key="kpi.label">
                <div class="metric-card h-100" :class="kpi.borderClass">
                  <div class="metric-icon" :style="{ background: kpi.iconBg, color: kpi.iconColor }"><i :class="kpi.icon"></i></div>
                  <div>
                    <span class="metric-label">{{ kpi.label }}</span>
                    <h4 class="metric-value">{{ kpi.value }}</h4>
                    <small class="metric-helper">{{ kpi.helper }}</small>
                  </div>
                </div>
              </div>
            </div>
            <div class="row g-4">
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-bar-chart-line me-2 text-primary"></i>Status dos atendimentos</h5>
                  <div class="d-flex flex-column gap-2">
                    <div v-for="s in statusBreakdown" :key="s.label" class="d-flex align-items-center gap-3 p-2 rounded" style="background:rgba(var(--bs-body-color-rgb),0.02)">
                      <span class="status-dot" :class="s.dot"></span>
                      <span class="flex-grow-1 fw-bold small">{{ s.label }}</span>
                      <span class="fw-bold">{{ s.total }}</span>
                      <span class="small text-muted">{{ s.pct }}%</span>
                      <div class="progress custom-progress" style="height:5px;width:80px">
                        <div class="progress-bar" :class="'bg-' + s.dot" :style="{ width: s.pct + '%' }"></div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-exclamation-triangle me-2 text-warning"></i>Alertas</h5>
                  <div class="d-flex flex-column gap-2">
                    <div v-for="a in alertas" :key="a.texto" class="alert-item" :class="a.tipo">
                      <i :class="a.icone"></i>
                      <div><strong>{{ a.valor }}</strong> {{ a.texto }}</div>
                    </div>
                    <div v-if="!alertas.length" class="text-muted small">Nenhum alerta.</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- FINANCEIRO -->
          <div v-if="activeTab === 'financeiro'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Relatório Financeiro Detalhado:</strong>
                <span class="banner-text">
                  Receita total bruta gerada no período, despesas registradas, lucro líquido apurado, evolução do faturamento ao longo do tempo e distribuição por forma de pagamento.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-4"><div class="metric-card metric-card-primary h-100"><div class="metric-icon"><i class="bi bi-cash-stack"></i></div><div><span class="metric-label">Receita total</span><h3 class="metric-value">R$ {{ fmt(receitaBruta) }}</h3></div></div></div>
              <div class="col-md-4"><div class="metric-card metric-card-danger h-100"><div class="metric-icon"><i class="bi bi-dash-circle"></i></div><div><span class="metric-label">Despesas</span><h3 class="metric-value">R$ {{ fmt(despesas) }}</h3></div></div></div>
              <div class="col-md-4"><div class="metric-card metric-card-success h-100"><div class="metric-icon"><i class="bi bi-plus-circle"></i></div><div><span class="metric-label">Lucro liquido</span><h3 class="metric-value">R$ {{ fmt(lucroLiquido) }}</h3></div></div></div>
            </div>
            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-graph-up me-2 text-primary"></i>Evolucao do faturamento</h5>
                  <div class="chart-bars">
                    <div v-for="d in evolucaoFaturamento" :key="d.label" class="chart-bar-item">
                      <div class="chart-bar-label">{{ d.label }}</div>
                      <div class="chart-bar-track"><div class="chart-bar-fill" :style="{ width: d.pct + '%' }"></div></div>
                      <div class="chart-bar-value">R$ {{ fmt(d.valor) }}</div>
                    </div>
                    <div v-if="!evolucaoFaturamento.length" class="text-muted small py-3">Sem dados.</div>
                  </div>
                </div>
              </div>
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-credit-card me-2 text-primary"></i>Por forma de pagamento</h5>
                  <div class="d-flex flex-column gap-2">
                    <div v-for="p in receitaPorPagamento" :key="p.nome" class="d-flex justify-content-between align-items-center p-2 rounded" style="background:rgba(var(--bs-body-color-rgb),0.02)">
                      <span class="fw-bold small">{{ p.nome }}</span>
                      <div class="d-flex align-items-center gap-3">
                        <div class="progress custom-progress" style="height:5px;width:100px"><div class="progress-bar" :style="{ width: p.pct + '%' }"></div></div>
                        <span class="fw-bold text-primary small">R$ {{ fmt(p.valor) }}</span>
                      </div>
                    </div>
                    <div v-if="!receitaPorPagamento.length" class="text-muted small">Sem dados.</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- AGENDAMENTOS -->
          <div v-if="activeTab === 'agendamentos'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Relatório Completo de Agendamentos:</strong>
                <span class="banner-text">
                  Total de atendimentos no período, breakdown por status (concluídos, cancelados, pendentes), distribuição por dia da semana e horários de pico de demanda.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-3"><div class="metric-card metric-card-primary h-100"><div class="metric-icon"><i class="bi bi-calendar-check"></i></div><div><span class="metric-label">Total</span><h3 class="metric-value">{{ totalAgendamentos }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card metric-card-success h-100"><div class="metric-icon"><i class="bi bi-check-circle"></i></div><div><span class="metric-label">Concluidos</span><h3 class="metric-value">{{ concluidos }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card metric-card-danger h-100"><div class="metric-icon"><i class="bi bi-x-octagon"></i></div><div><span class="metric-label">Cancelados</span><h3 class="metric-value">{{ cancelados }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card metric-card-warning h-100"><div class="metric-icon"><i class="bi bi-clock"></i></div><div><span class="metric-label">Pendentes</span><h3 class="metric-value">{{ noShows }}</h3></div></div></div>
            </div>
            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-bar-chart me-2 text-primary"></i>Por dia da semana</h5>
                  <div class="chart-bars">
                    <div v-for="d in agendamentosPorDiaSemana" :key="d.nome" class="chart-bar-item">
                      <div class="chart-bar-label">{{ d.nome }}</div>
                      <div class="chart-bar-track"><div class="chart-bar-fill bg-success" :style="{ width: d.pct + '%' }"></div></div>
                      <div class="chart-bar-value">{{ d.total }}</div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-clock me-2 text-primary"></i>Horarios mais movimentados</h5>
                  <div class="d-flex flex-column gap-2">
                    <div v-for="h in horariosTop" :key="h.hora" class="d-flex justify-content-between align-items-center p-2 rounded" style="background:rgba(var(--bs-body-color-rgb),0.02)">
                      <span class="fw-bold small">{{ h.hora }}</span>
                      <span class="badge bg-primary bg-opacity-10 text-primary rounded-pill">{{ h.total }}</span>
                    </div>
                    <div v-if="!horariosTop.length" class="text-muted small">Sem dados.</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- SERVICOS -->
          <div v-if="activeTab === 'servicos'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Ranking e Análise por Tipo de Serviço:</strong>
                <span class="banner-text">
                  Quais serviços mais foram realizados, a receita gerada por cada um, ticket médio e percentual de participação no faturamento total do estabelecimento.
                </span>
              </div>
            </div>

            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-scissors me-2 text-primary"></i>Ranking de servicos</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead><tr><th>#</th><th>Servico</th><th>Quantidade</th><th>Receita</th><th>Ticket medio</th><th>Participacao</th></tr></thead>
                  <tbody>
                    <tr v-for="(s, i) in rankingServicos" :key="s.nome">
                      <td class="fw-900">{{ i + 1 }}</td>
                      <td class="fw-bold">{{ s.nome }}</td>
                      <td>{{ s.quantidade }}</td>
                      <td class="fw-bold text-success">R$ {{ fmt(s.receita) }}</td>
                      <td class="fw-bold">R$ {{ fmt(s.ticketMedio) }}</td>
                      <td><div class="progress custom-progress" style="height:6px;width:100px"><div class="progress-bar" :style="{ width: s.pct + '%' }"></div></div><small class="text-muted">{{ s.pct }}%</small></td>
                    </tr>
                    <tr v-if="!rankingServicos.length"><td colspan="6" class="text-muted text-center py-3">Sem dados.</td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- PROFISSIONAIS -->
          <div v-if="activeTab === 'profissionais'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Desempenho Individual dos Profissionais:</strong>
                <span class="banner-text">
                  Relatório por barbeiro/profissional com número de atendimentos prestados, receita gerada, ticket médio e modelo de remuneração (comissão, fixo ou diária).
                </span>
              </div>
            </div>

            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-people me-2 text-primary"></i>Desempenho da equipe</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead><tr><th>Profissional</th><th>Clientes</th><th>Receita</th><th>Ticket medio</th><th>Modelo</th></tr></thead>
                  <tbody>
                    <tr v-for="p in rankingProfissionais" :key="p.nome">
                      <td><div class="d-flex align-items-center gap-2"><div class="avatar-circle-sm">{{ p.nome.charAt(0) }}</div><strong>{{ p.nome }}</strong></div></td>
                      <td>{{ p.atendimentos }}</td>
                      <td class="fw-bold text-success">R$ {{ fmt(p.producao) }}</td>
                      <td class="fw-bold">R$ {{ fmt(p.ticketMedio) }}</td>
                      <td><span class="badge rounded-pill bg-primary bg-opacity-10 text-primary">{{ p.modelo || '-' }}</span></td>
                    </tr>
                    <tr v-if="!rankingProfissionais.length"><td colspan="5" class="text-muted text-center py-3">Sem dados.</td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- CLIENTES -->
          <div v-if="activeTab === 'clientes'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Análise Completa da Base de Clientes:</strong>
                <span class="banner-text">
                  Clientes únicos, recorrentes, novos e inativos no período. Ranking dos melhores clientes por visitas e gasto total, com ticket médio individual para estratégias de retenção.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-3"><div class="metric-card metric-card-primary h-100"><div class="metric-icon"><i class="bi bi-people"></i></div><div><span class="metric-label">Unicos</span><h3 class="metric-value">{{ clientesUnicos }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card metric-card-success h-100"><div class="metric-icon"><i class="bi bi-arrow-repeat"></i></div><div><span class="metric-label">Recorrentes</span><h3 class="metric-value">{{ clientesRecorrentes }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card metric-card-warning h-100"><div class="metric-icon"><i class="bi bi-person-check"></i></div><div><span class="metric-label">Novos</span><h3 class="metric-value">{{ novosClientes }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card h-100"><div class="metric-icon" style="background:rgba(108,117,125,0.1);color:var(--bs-secondary)"><i class="bi bi-clock-history"></i></div><div><span class="metric-label">Inativos</span><h3 class="metric-value">{{ clientesInativos }}</h3></div></div></div>
            </div>
            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-trophy me-2 text-primary"></i>Top clientes</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead><tr><th>#</th><th>Cliente</th><th>Visitas</th><th>Total gasto</th><th>Ticket medio</th></tr></thead>
                  <tbody>
                    <tr v-for="(c, i) in topClientes" :key="c.nome">
                      <td class="fw-900">{{ i + 1 }}</td>
                      <td class="fw-bold">{{ maskName(c.nome) }}</td>
                      <td>{{ c.total }}</td>
                      <td class="fw-bold text-success">R$ {{ fmt(c.gasto) }}</td>
                      <td class="fw-bold">R$ {{ fmt(c.gasto / c.total) }}</td>
                    </tr>
                    <tr v-if="!topClientes.length"><td colspan="5" class="text-muted text-center py-3">Sem dados.</td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- PRODUTOS -->
          <div v-if="activeTab === 'produtos'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Inventário e Resultados de Produtos:</strong>
                <span class="banner-text">
                  Total de itens cadastrados no estoque, valor financeiro imobilizado, produtos com quantidade abaixo do mínimo e receita gerada pela venda de produtos no período.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-3"><div class="metric-card metric-card-primary h-100"><div class="metric-icon"><i class="bi bi-box"></i></div><div><span class="metric-label">Total itens</span><h3 class="metric-value">{{ stockItems.length }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card metric-card-danger h-100"><div class="metric-icon"><i class="bi bi-exclamation-triangle"></i></div><div><span class="metric-label">Estoque baixo</span><h3 class="metric-value">{{ estoqueBaixo }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card metric-card-success h-100"><div class="metric-icon"><i class="bi bi-cash"></i></div><div><span class="metric-label">Valor estoque</span><h3 class="metric-value">R$ {{ fmt(valorEstoque) }}</h3></div></div></div>
              <div class="col-md-3"><div class="metric-card metric-card-warning h-100"><div class="metric-icon"><i class="bi bi-currency-dollar"></i></div><div><span class="metric-label">Receita produtos</span><h3 class="metric-value">R$ {{ fmt(receitaProdutos) }}</h3></div></div></div>
            </div>
            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-box-seam me-2 text-primary"></i>Itens em estoque</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead><tr><th>Produto</th><th>Quantidade</th><th>Minimo</th><th>Preco</th><th>Status</th></tr></thead>
                  <tbody>
                    <tr v-for="item in stockItems" :key="item.id || item.nome">
                      <td class="fw-bold">{{ item.nome || item.name }}</td>
                      <td>{{ item.estoque ?? item.quantity }} un.</td>
                      <td>{{ item.estoque_minimo ?? item.minimum_stock }} un.</td>
                      <td class="fw-bold">R$ {{ fmt(Number(item.preco || item.sale_price || 0)) }}</td>
                      <td><span class="badge rounded-pill fw-bold" :class="Number(item.estoque ?? item.quantity) <= Number(item.estoque_minimo ?? item.minimum_stock) ? 'bg-danger bg-opacity-10 text-danger' : 'bg-success bg-opacity-10 text-success'">{{ Number(item.estoque ?? item.quantity) <= Number(item.estoque_minimo ?? item.minimum_stock) ? 'Baixo' : 'OK' }}</span></td>
                    </tr>
                    <tr v-if="!stockItems.length"><td colspan="5" class="text-muted text-center py-3">Sem itens.</td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- HORARIOS -->
          <div v-if="activeTab === 'horarios'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Mapa de Horários e Dias de Pico:</strong>
                <span class="banner-text">
                  Identifique os horários de maior movimento para alocar melhor a equipe, os dias da semana com mais agendamentos e horários ociosos que podem ser aproveitados com promoções.
                </span>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-clock me-2 text-primary"></i>Horarios de maior movimento</h5>
                  <div class="chart-bars">
                    <div v-for="h in horariosTop" :key="h.hora" class="chart-bar-item">
                      <div class="chart-bar-label">{{ h.hora }}</div>
                      <div class="chart-bar-track"><div class="chart-bar-fill bg-primary" :style="{ width: h.pct + '%' }"></div></div>
                      <div class="chart-bar-value">{{ h.total }}</div>
                    </div>
                    <div v-if="!horariosTop.length" class="text-muted small py-3">Sem dados.</div>
                  </div>
                </div>
              </div>
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-calendar-week me-2 text-primary"></i>Dias mais movimentados</h5>
                  <div class="chart-bars">
                    <div v-for="d in agendamentosPorDiaSemana" :key="d.nome" class="chart-bar-item">
                      <div class="chart-bar-label">{{ d.nome }}</div>
                      <div class="chart-bar-track"><div class="chart-bar-fill bg-success" :style="{ width: d.pct + '%' }"></div></div>
                      <div class="chart-bar-value">{{ d.total }}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="admin-card">
              <h5 class="fw-bold mb-3"><i class="bi bi-clock-history me-2 text-primary"></i>Horarios ociosos</h5>
              <div class="d-flex flex-wrap gap-2">
                <span v-for="h in horariosOciosos" :key="h" class="badge bg-secondary bg-opacity-10 text-secondary rounded-pill px-3 py-2 fw-bold">{{ h }}</span>
                <span v-if="!horariosOciosos.length" class="text-muted small">Nenhum horario ocioso identificado.</span>
              </div>
            </div>
          </div>

          <!-- COMISSOES -->
          <div v-if="activeTab === 'comissoes'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Relatório Consolidado de Comissões:</strong>
                <span class="banner-text">
                  Visão consolidada do total de comissões calculadas no período, valor já pago à equipe, valor pendente de repasse e breakdown individual por profissional.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-4"><div class="metric-card metric-card-primary h-100"><div class="metric-icon"><i class="bi bi-cash-coin"></i></div><div><span class="metric-label">Total comissao</span><h3 class="metric-value">R$ {{ fmt(comissaoTotal) }}</h3></div></div></div>
              <div class="col-md-4"><div class="metric-card metric-card-warning h-100"><div class="metric-icon"><i class="bi bi-hourglass-split"></i></div><div><span class="metric-label">Pendente</span><h3 class="metric-value">R$ {{ fmt(comissaoPendente) }}</h3></div></div></div>
              <div class="col-md-4"><div class="metric-card metric-card-success h-100"><div class="metric-icon"><i class="bi bi-check-circle"></i></div><div><span class="metric-label">Paga</span><h3 class="metric-value">R$ {{ fmt(comissaoPaga) }}</h3></div></div></div>
            </div>
            <div class="admin-card">
              <h5 class="fw-bold mb-3"><i class="bi bi-people me-2 text-primary"></i>Comissao por profissional</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead><tr><th>Profissional</th><th>Receita</th><th>Ticket medio</th><th>Modelo</th></tr></thead>
                  <tbody>
                    <tr v-for="p in rankingProfissionais" :key="p.nome">
                      <td><div class="d-flex align-items-center gap-2"><div class="avatar-circle-sm">{{ p.nome.charAt(0) }}</div><strong>{{ p.nome }}</strong></div></td>
                      <td class="fw-bold text-success">R$ {{ fmt(p.producao) }}</td>
                      <td class="fw-bold">R$ {{ fmt(p.ticketMedio) }}</td>
                      <td><span class="badge rounded-pill bg-primary bg-opacity-10 text-primary">{{ p.modelo || '-' }}</span></td>
                    </tr>
                    <tr v-if="!rankingProfissionais.length"><td colspan="4" class="text-muted text-center py-3">Sem dados.</td></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- ANALISES -->
          <div v-if="activeTab === 'analises'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Análises Avançadas e Indicadores Estratégicos:</strong>
                <span class="banner-text">
                  Métricas-chave para decisões de negócio: ticket médio geral, margem de lucro, taxa de cancelamento, taxa de no-show, serviço mais lucrativo e melhor profissional do período.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-4">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-arrow-up-right me-2 text-success"></i>Crescimento</h5>
                  <div class="kpi-mini">
                    <span class="small text-muted fw-bold">Ticket medio</span>
                    <h4 class="fw-900 mb-0">R$ {{ fmt(ticketMedio) }}</h4>
                  </div>
                  <hr>
                  <div class="kpi-mini">
                    <span class="small text-muted fw-bold">Frequencia media</span>
                    <h4 class="fw-900 mb-0">{{ frequenciaMedia }}x</h4>
                    <small class="text-muted">visitas por cliente</small>
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-star me-2 text-warning"></i>Melhores</h5>
                  <div class="kpi-mini mb-3">
                    <span class="small text-muted fw-bold">Servico mais vendido</span>
                    <h4 class="fw-900 mb-0 small">{{ rankingServicos[0]?.nome || '-' }}</h4>
                  </div>
                  <div class="kpi-mini mb-3">
                    <span class="small text-muted fw-bold">Melhor profissional</span>
                    <h4 class="fw-900 mb-0 small">{{ rankingProfissionais[0]?.nome || '-' }}</h4>
                  </div>
                  <div class="kpi-mini">
                    <span class="small text-muted fw-bold">Dia mais movimentado</span>
                    <h4 class="fw-900 mb-0 small">{{ diaMaisMovimentado }}</h4>
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-pie-chart me-2 text-primary"></i>Metricas</h5>
                  <div class="kpi-mini mb-3">
                    <span class="small text-muted fw-bold">Margem de lucro</span>
                    <h4 class="fw-900 mb-0" :class="margemLucro >= 0 ? 'text-success' : 'text-danger'">{{ margemLucro }}%</h4>
                  </div>
                  <div class="kpi-mini mb-3">
                    <span class="small text-muted fw-bold">Taxa de cancelamento</span>
                    <h4 class="fw-900 mb-0">{{ taxaCancelamento }}%</h4>
                  </div>
                  <div class="kpi-mini">
                    <span class="small text-muted fw-bold">Taxa de no-show</span>
                    <h4 class="fw-900 mb-0">{{ taxaNoShow }}%</h4>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- LANCAMENTOS (tabela detalhada) -->
          <div v-if="activeTab === 'visao-geral' && entries.length" class="admin-card mt-4">
            <div class="section-header mb-3">
              <h5 class="fw-bold mb-0"><i class="bi bi-table me-2 text-primary"></i>Lancamentos detalhados</h5>
              <span class="small text-muted">{{ entries.length }} registro(s)</span>
            </div>
            <div class="table-responsive">
              <table class="table table-clean align-middle mb-0">
                <thead><tr><th>Data</th><th>Cliente</th><th>Profissional</th><th>Servico</th><th>Status</th><th>Valor</th></tr></thead>
                <tbody>
                  <tr v-for="e in entries.slice(0, 20)" :key="e.id">
                    <td class="fw-bold small">{{ e.date }}</td>
                    <td>{{ maskName(e.customer) }}</td>
                    <td>{{ e.employee }}</td>
                    <td>{{ e.service }}</td>
                    <td><span class="badge rounded-pill px-3 py-1 fw-bold" :class="statusClass(e.status)">{{ statusLabel(e.status) }}</span></td>
                    <td class="fw-bold">R$ {{ fmt(e.value) }}</td>
                  </tr>
                  <tr v-if="!entries.length"><td colspan="6" class="text-muted text-center py-3">Sem lancamentos.</td></tr>
                </tbody>
              </table>
            </div>
          </div>
        </template>

        <div class="mt-4 pt-3 border-top" style="border-color: var(--card-border) !important">
          <p class="small text-muted mb-0" style="opacity: 0.6"><i class="bi bi-shield-lock me-1"></i>Dados pessoais mascarados conforme LGPD.</p>
        </div>
      </div>
    </section>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import { api } from '@/services/api'

const loading = ref(false)
const erro = ref('')
const activeTab = ref('visao-geral')

const tabs = [
  { id: 'visao-geral', label: 'Visao Geral', icon: 'bi bi-eye' },
  { id: 'financeiro', label: 'Financeiro', icon: 'bi bi-cash-stack' },
  { id: 'agendamentos', label: 'Agendamentos', icon: 'bi bi-calendar-check' },
  { id: 'servicos', label: 'Servicos', icon: 'bi bi-scissors' },
  { id: 'profissionais', label: 'Profissionais', icon: 'bi bi-people' },
  { id: 'clientes', label: 'Clientes', icon: 'bi bi-person-check' },
  { id: 'produtos', label: 'Produtos', icon: 'bi bi-box' },
  { id: 'horarios', label: 'Horarios', icon: 'bi bi-clock' },
  { id: 'comissoes', label: 'Comissoes', icon: 'bi bi-cash-coin' },
  { id: 'analises', label: 'Analises', icon: 'bi bi-graph-up' }
]

const filters = ref({ periodo: '30dias', dataDe: '', dataAte: '', profissional: 'todos', servico: 'todos' })

const summary = ref({ gross_revenue: 0, appointments_count: 0, average_ticket: 0, removed_team_production: 0, commissions_pending: 0, commissions_paid: 0 })
const entries = ref<any[]>([])
const team = ref<any[]>([])
const stockItems = ref<any[]>([])
const profissionaisOpts = ref<{ value: string; label: string }[]>([])
const servicosOpts = ref<{ value: string; label: string }[]>([])

function fmt(v: number) { return Number(v || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }
function maskName(n: string) { if (!n) return '***'; return n.length <= 2 ? n.charAt(0) + '*' : n.charAt(0) + '*'.repeat(Math.min(n.length - 2, 4)) + n.charAt(n.length - 1) }

function toInputDate(d: Date) { return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` }
function aplicarPeriodo() {
  const h = new Date(), i = new Date()
  switch (filters.value.periodo) { case 'hoje': break; case '7dias': i.setDate(h.getDate() - 7); break; case '30dias': i.setDate(h.getDate() - 30); break; case '6meses': i.setMonth(h.getMonth() - 6); break; case '1ano': i.setFullYear(h.getFullYear() - 1); break }
  filters.value.dataDe = toInputDate(i); filters.value.dataAte = toInputDate(h)
}

function normalizarEntry(e: any) {
  return { id: e.id, date: e.date, customer: e.customer, employee: e.employee, service: e.service, status: e.status || 'pending', value: Number(e.value || 0), employee_id: e.employee_id, service_id: e.service_id }
}

// R-1: helper seguro — retorna fallback em 403 sem derrubar o Promise.all
async function safeGet(url: string, params = {}, fallback: any = null) {
  try {
    const { data } = await api.get(url, { params })
    return data
  } catch (err: any) {
    if (err?.response?.status === 403) return fallback
    throw err
  }
}

async function carregarRelatorio() {
  // R-3: validação de intervalo de datas antes de enviar ao servidor
  if (filters.value.dataDe && filters.value.dataAte && filters.value.dataDe > filters.value.dataAte) {
    erro.value = 'A data inicial não pode ser posterior à data final.'
    return
  }

  loading.value = true; erro.value = ''
  try {
    const params: Record<string, string> = {}
    if (filters.value.dataDe) params.date_from = filters.value.dataDe
    if (filters.value.dataAte) params.date_to = filters.value.dataAte
    if (filters.value.profissional !== 'todos') params.employee_id = filters.value.profissional
    if (filters.value.servico !== 'todos') params.service_id = filters.value.servico

    // R-1: rotas opcionais usam safeGet — 403 retorna fallback vazio sem derrubar o relatório
    const [reportRes, teamRes, stockRes] = await Promise.all([
      api.get('/financial/reports', { params }).then(r => r.data),
      safeGet('/admin/team', {}, []),
      safeGet('/stock_items', {}, [])
    ])

    summary.value = reportRes?.summary || { gross_revenue: 0, appointments_count: 0, average_ticket: 0, removed_team_production: 0, commissions_pending: 0, commissions_paid: 0 }
    entries.value = Array.isArray(reportRes?.entries) ? reportRes.entries.map(normalizarEntry) : []
    team.value = Array.isArray(teamRes) ? teamRes : Array.isArray(teamRes?.memberships) ? teamRes.memberships : []
    stockItems.value = Array.isArray(stockRes) ? stockRes : Array.isArray(stockRes?.stock_items) ? stockRes.stock_items : []

    profissionaisOpts.value = [...new Set(entries.value.map(e => e.employee).filter(Boolean))].map(n => ({ value: n, label: n }))
    servicosOpts.value = [...new Set(entries.value.map(e => e.service).filter(Boolean))].map(n => ({ value: n, label: n }))
  } catch (err: any) {
    const serverMsg = err?.response?.data?.error
    erro.value = serverMsg || 'Nao foi possivel carregar o relatorio.'
  } finally { loading.value = false }
}

const receitaBruta = computed(() => summary.value.gross_revenue || receitaFromEntries.value)
const despesas = computed(() => summary.value.removed_team_production || 0)
const lucroLiquido = computed(() => receitaBruta.value - despesas.value - comissaoPendente.value)
const receitaFromEntries = computed(() => entries.value.reduce((a, e) => a + e.value, 0))
const comissaoPendente = computed(() => summary.value.commissions_pending || 0)
const comissaoPaga = computed(() => summary.value.commissions_paid || 0)
const comissaoTotal = computed(() => comissaoPendente.value + comissaoPaga.value)
const margemLucro = computed(() => { const b = receitaBruta.value || 1; return Math.round((lucroLiquido.value / b) * 100) })

const totalAgendamentos = computed(() => summary.value.appointments_count || entries.value.length)
const concluidos = computed(() => entries.value.filter(e => e.status === 'completed').length)
const cancelados = computed(() => entries.value.filter(e => e.status === 'canceled').length)
const noShows = computed(() => entries.value.filter(e => e.status === 'pending' || e.status === 'no_show' || e.status === 'missed').length)
const pendentes = computed(() => noShows.value)
const taxaCancelamento = computed(() => { const t = totalAgendamentos.value || 1; return Math.round((cancelados.value / t) * 100) })
const taxaPendentes = computed(() => { const t = totalAgendamentos.value || 1; return Math.round((pendentes.value / t) * 100) })
const taxaNoShow = computed(() => taxaPendentes.value)

const statusBreakdown = computed(() => {
  const t = totalAgendamentos.value || 1
  return [
    { label: 'Concluidos', total: concluidos.value, pct: Math.round((concluidos.value / t) * 100), dot: 'success' },
    { label: 'Pendentes', total: pendentes.value, pct: Math.round((pendentes.value / t) * 100), dot: 'warning' },
    { label: 'Cancelados', total: cancelados.value, pct: Math.round((cancelados.value / t) * 100), dot: 'danger' }
  ]
})

const alertas = computed(() => {
  const arr = []
  const eb = stockItems.value.filter(i => Number(i.estoque ?? i.quantity) <= Number(i.estoque_minimo ?? i.minimum_stock)).length
  if (eb) arr.push({ valor: eb, texto: 'itens com estoque baixo', icone: 'bi bi-box-seam', tipo: 'warning' })
  const psr = team.value.filter((m: any) => !m.financial_model).length
  if (psr) arr.push({ valor: psr, texto: 'profissionais sem regra de comissao', icone: 'bi bi-person-x', tipo: 'danger' })
  return arr
})

const kpisGeral = computed(() => [
  { label: 'Faturamento', value: 'R$ ' + fmt(receitaBruta.value), icon: 'bi bi-cash-stack', iconBg: 'rgba(13,110,253,0.1)', iconColor: 'var(--bs-primary)', borderClass: 'metric-card-primary', helper: 'Receita total' },
  { label: 'Atendimentos', value: String(totalAgendamentos.value), icon: 'bi bi-calendar-check', iconBg: 'rgba(25,135,84,0.1)', iconColor: 'var(--bs-success)', borderClass: 'metric-card-success', helper: 'Total no periodo' },
  { label: 'Ticket medio', value: 'R$ ' + fmt(summary.value.average_ticket || ticketMedio.value), icon: 'bi bi-graph-up-arrow', iconBg: 'rgba(255,193,7,0.1)', iconColor: 'var(--bs-warning)', borderClass: 'metric-card-warning', helper: 'Valor medio' },
  { label: 'Cancelados', value: String(cancelados.value), icon: 'bi bi-x-circle', iconBg: 'rgba(220,53,69,0.1)', iconColor: 'var(--bs-danger)', borderClass: 'metric-card-danger', helper: taxaCancelamento.value + '%' },
  { label: 'Pendentes', value: String(pendentes.value), icon: 'bi bi-clock', iconBg: 'rgba(255,193,7,0.1)', iconColor: 'var(--bs-warning)', borderClass: 'metric-card-warning', helper: taxaPendentes.value + '%' },
  { label: 'Lucro', value: 'R$ ' + fmt(lucroLiquido.value), icon: 'bi bi-cash-coin', iconBg: 'rgba(25,135,84,0.1)', iconColor: 'var(--bs-success)', borderClass: 'metric-card-success', helper: margemLucro.value + '% margem' }
])

const ticketMedio = computed(() => { const t = totalAgendamentos.value || 1; return receitaFromEntries.value / t })

const evolucaoFaturamento = computed(() => {
  const mapa: Record<string, number> = {}
  entries.value.forEach(e => { if (e.date) mapa[e.date.slice(5)] = (mapa[e.date.slice(5)] || 0) + e.value })
  const arr = Object.entries(mapa).map(([l, v]) => ({ label: l, valor: v, pct: 0 })).sort((a, b) => a.label.localeCompare(b.label)).slice(-14)
  const max = Math.max(...arr.map(d => d.valor), 1)
  arr.forEach(d => { d.pct = Math.round((d.valor / max) * 100) })
  return arr
})

const receitaPorPagamento = computed(() => [{ nome: 'Servicos', valor: receitaFromEntries.value, pct: 100 }])

const agendamentosPorDiaSemana = computed(() => {
  const nomes = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab']
  const c = [0, 0, 0, 0, 0, 0, 0]
  entries.value.forEach(e => { if (e.date) { const d = new Date(e.date + 'T12:00:00'); const i = d.getDay(); c[i] = (c[i] ?? 0) + 1 } })
  const max = Math.max(...c, 1)
  return nomes.map((nome, i) => ({ nome, total: c[i] ?? 0, pct: Math.round(((c[i] ?? 0) / max) * 100) }))
})

const horariosTop = computed(() => {
  const mapa: Record<string, number> = {}
  entries.value.forEach(e => { if (e.start_time) { const h = e.start_time.slice(0, 5); mapa[h] = (mapa[h] || 0) + 1 } })
  const arr = Object.entries(mapa).map(([h, t]) => ({ hora: h, total: t, pct: 0 })).sort((a, b) => b.total - a.total).slice(0, 10)
  const max = arr[0]?.total || 1
  arr.forEach(h => { h.pct = Math.round((h.total / max) * 100) })
  return arr
})

const horariosOciosos = computed(() => {
  const busy = new Set(horariosTop.value.slice(0, 5).map(h => h.hora))
  const all = ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00']
  return all.filter(h => !busy.has(h))
})

const rankingServicos = computed(() => {
  const mapa: Record<string, { nome: string; quantidade: number; receita: number; ticketMedio: number; pct: number }> = {}
  entries.value.forEach(e => { const n = e.service; if (!mapa[n]) mapa[n] = { nome: n, quantidade: 0, receita: 0, ticketMedio: 0, pct: 0 }; mapa[n].quantidade++; mapa[n].receita += e.value })
  const arr = Object.values(mapa).sort((a, b) => b.receita - a.receita)
  const total = arr.reduce((a, s) => a + s.receita, 0) || 1
  arr.forEach(s => { s.ticketMedio = s.quantidade ? s.receita / s.quantidade : 0; s.pct = Math.round((s.receita / total) * 100) })
  return arr
})

const rankingProfissionais = computed(() => {
  const mapa: Record<string, any> = {}
  entries.value.forEach(e => { const n = e.employee; if (!mapa[n]) mapa[n] = { nome: n, atendimentos: 0, producao: 0, ticketMedio: 0, modelo: '' }; mapa[n].atendimentos++; mapa[n].producao += e.value })
  const membershipMap: Record<string, string> = {}
  team.value.forEach((m: any) => { membershipMap[m.user_name || m.name] = m.financial_model || '' })
  Object.values(mapa).forEach((p: any) => { p.ticketMedio = p.atendimentos ? p.producao / p.atendimentos : 0; p.modelo = membershipMap[p.nome] || '-' })
  return Object.values(mapa).sort((a: any, b: any) => b.producao - a.producao)
})

const clientesUnicos = computed(() => new Set(entries.value.map(e => e.customer).filter(Boolean)).size)
const clientesRecorrentes = computed(() => { const m: Record<string, number> = {}; entries.value.forEach(e => { const c = e.customer || 'X'; m[c] = (m[c] || 0) + 1 }); return Object.values(m).filter(v => v > 1).length })
const novosClientes = computed(() => { const m: Record<string, number> = {}; entries.value.forEach(e => { const c = e.customer || 'X'; m[c] = (m[c] || 0) + 1 }); return Object.values(m).filter(v => v === 1).length })
const clientesInativos = computed(() => { const m: Record<string, number> = {}; entries.value.forEach(e => { const c = e.customer || 'X'; m[c] = (m[c] || 0) + 1 }); return Object.values(m).filter(v => v === 1).length })
const frequenciaMedia = computed(() => { const t = totalAgendamentos.value; const c = clientesUnicos.value || 1; return (t / c).toFixed(1) })

const topClientes = computed(() => {
  const m: Record<string, { nome: string; total: number; gasto: number }> = {}
  entries.value.forEach(e => { const c = e.customer || 'X'; if (!m[c]) m[c] = { nome: c, total: 0, gasto: 0 }; m[c].total++; m[c].gasto += e.value })
  return Object.values(m).sort((a, b) => b.gasto - a.gasto).slice(0, 10)
})

const estoqueBaixo = computed(() => stockItems.value.filter(i => Number(i.estoque ?? i.quantity) <= Number(i.estoque_minimo ?? i.minimum_stock)).length)
const valorEstoque = computed(() => stockItems.value.reduce((a, i) => a + (Number(i.estoque ?? i.quantity) * Number(i.preco || i.sale_price || 0)), 0))
const receitaProdutos = computed(() => 0)
const diaMaisMovimentado = computed(() => { const d = agendamentosPorDiaSemana.value; return d.length ? d.sort((a, b) => b.total - a.total)[0]?.nome || '-' : '-' })

function statusClass(s: string) { switch (s) { case 'completed': return 'bg-success bg-opacity-10 text-success border-success'; case 'confirmed': return 'bg-primary bg-opacity-10 text-primary border-primary'; case 'pending': return 'bg-warning bg-opacity-10 text-warning border-warning'; case 'canceled': return 'bg-danger bg-opacity-10 text-danger border-danger'; default: return 'bg-secondary bg-opacity-10 text-secondary border-secondary' } }
function statusLabel(s: string) { switch (s) { case 'completed': return 'Concluido'; case 'confirmed': return 'Confirmado'; case 'pending': return 'Pendente'; case 'canceled': return 'Cancelado'; case 'no_show': return 'Pendente'; case 'missed': return 'Pendente'; default: return s } }

function imprimir() { window.print() }

onMounted(() => { aplicarPeriodo(); carregarRelatorio() })
</script>

<style scoped>
.page-shell { width: 100%; min-width: 100%; max-width: 100%; display: block; }
.page-content { width: 100%; min-width: 100%; max-width: 100% !important; display: block; }
.dashboard-header { background: rgba(var(--bs-body-bg-rgb), 0.4) !important; border: 1px solid var(--card-border) !important; backdrop-filter: blur(12px) !important; border-radius: 20px !important; }
.header-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: radial-gradient(circle at top right, rgba(13, 110, 253, 0.08), transparent 70%); pointer-events: none; }
.header-icon-container { width: 54px; height: 54px; border-color: var(--card-border) !important; flex-shrink: 0; }
.text-gradient { background: linear-gradient(135deg, var(--logo-color, var(--bs-primary)), #00c6ff); -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; font-weight: 800; }
.admin-card { background: var(--glass-bg); border: 1px solid var(--card-border); border-radius: 22px; padding: 1.5rem 1.75rem; backdrop-filter: blur(15px); box-shadow: 0 4px 20px var(--card-shadow); }
.custom-input { border-radius: 12px; padding: 10px 14px; border: 1px solid var(--card-border); background-color: var(--bs-body-bg); color: var(--bs-body-color); transition: all 0.2s; }
.custom-input:focus { border-color: var(--bs-primary); box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.15); }
.metric-card { border-radius: 20px; padding: 1.3rem 1.5rem; display: flex; align-items: flex-start; gap: 14px; border: 1px solid var(--card-border); background: rgba(var(--bs-body-color-rgb), 0.015); backdrop-filter: blur(10px); transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1); box-shadow: 0 4px 15px rgba(0, 0, 0, 0.02); }
.metric-card:hover { transform: translateY(-4px) scale(1.01); box-shadow: 0 10px 25px var(--card-shadow) !important; }
.metric-card-primary { border-left: 4px solid var(--bs-primary); }
.metric-card-success { border-left: 4px solid var(--bs-success); }
.metric-card-warning { border-left: 4px solid var(--bs-warning); }
.metric-card-danger { border-left: 4px solid var(--bs-danger); }
.metric-icon { width: 52px; height: 52px; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 1.25rem; flex-shrink: 0; }
.metric-label { display: block; font-size: 0.8rem; color: var(--bs-secondary-color); font-weight: 700; margin-bottom: 4px; }
.metric-value { font-weight: 900; margin-bottom: 4px; }
.metric-helper { color: var(--bs-secondary-color); }
.status-dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
.status-dot.success { background: var(--bs-success); }
.status-dot.danger { background: var(--bs-danger); }
.status-dot.warning { background: var(--bs-warning); }
.alert-item { display: flex; align-items: center; gap: 12px; padding: 0.85rem 1rem; border-radius: 14px; border: 1px solid var(--card-border); transition: all 0.2s; }
.alert-item.warning { border-left: 4px solid var(--bs-warning); }
.alert-item.danger { border-left: 4px solid var(--bs-danger); }
.avatar-circle-sm { width: 32px; height: 32px; border-radius: 50%; background: rgba(13, 110, 253, 0.1); color: var(--bs-primary); display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 0.85rem; flex-shrink: 0; }
.custom-progress { border-radius: 10px; background: rgba(var(--bs-body-color-rgb), 0.08); }
.chart-bars { display: flex; flex-direction: column; gap: 10px; }
.chart-bar-item { display: flex; align-items: center; gap: 12px; }
.chart-bar-label { min-width: 48px; font-size: 0.75rem; font-weight: 700; color: var(--bs-secondary-color); }
.chart-bar-track { flex: 1; height: 10px; background: rgba(var(--bs-body-color-rgb), 0.06); border-radius: 10px; overflow: hidden; }
.chart-bar-fill { height: 100%; background: var(--bs-primary); border-radius: 10px; transition: width 0.6s ease; }
.chart-bar-fill.bg-success { background: var(--bs-success) !important; }
.chart-bar-fill.bg-primary { background: var(--bs-primary) !important; }
.chart-bar-value { min-width: 72px; font-size: 0.8rem; font-weight: 700; text-align: right; }
.kpi-mini { background: rgba(var(--bs-body-color-rgb), 0.015); border: 1px solid var(--card-border); border-radius: 16px; padding: 1rem; }
.table-clean th { font-size: 0.75rem; font-weight: 700; text-transform: uppercase; color: var(--bs-secondary-color); border-bottom: 1px solid var(--card-border); padding: 12px 16px; }
.table-clean td { padding: 12px 16px; border-bottom: 1px solid rgba(var(--bs-body-color-rgb), 0.05); }
.section-header { display: flex; justify-content: space-between; align-items: center; gap: 16px; flex-wrap: wrap; }
.nav-pills .nav-link { color: var(--bs-secondary-color); border: 1px solid transparent; transition: all 0.2s; }
.nav-pills .nav-link.active { background: var(--bs-primary); color: #fff; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }
.nav-pills .nav-link:not(.active):hover { background: rgba(var(--bs-body-color-rgb), 0.06); border-color: var(--card-border); }

/* Banner Explicativo com Alto Contraste */
.explanation-banner {
  background: rgba(13, 110, 253, 0.06) !important;
  border: 1px solid rgba(13, 110, 253, 0.18) !important;
  border-radius: 16px !important;
}
.banner-title { color: var(--bs-body-color, #212529) !important; font-weight: 800; }
.banner-text { color: var(--bs-secondary-color, #6c757d) !important; }

[data-bs-theme="dark"] .explanation-banner {
  background: rgba(13, 110, 253, 0.15) !important;
  border-color: rgba(13, 110, 253, 0.35) !important;
}
[data-bs-theme="dark"] .banner-title { color: #ffffff !important; }
[data-bs-theme="dark"] .banner-text { color: #cbd5e1 !important; }
[data-bs-theme="dark"] .banner-text strong { color: #60a5fa !important; }

@media print { .admin-card { break-inside: avoid; } .nav-pills, .dashboard-header, .btn { display: none !important; } }
</style>
