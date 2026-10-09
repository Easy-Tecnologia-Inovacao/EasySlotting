<template>
  <AdminLayout>
    <section class="page-shell">
      <div class="page-content">
        <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
          <div class="header-overlay"></div>
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1 w-100">
            <div class="d-flex align-items-center gap-3">
              <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                <i class="bi bi-pie-chart-fill fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Painel de Controle</h1>
                <p class="text-muted mb-0 small-text-responsive">Visao completa do desempenho do seu estabelecimento.</p>
              </div>
            </div>
            <div class="d-flex gap-2">
              <button class="btn btn-primary rounded-pill fw-bold px-4 py-2.5 shadow-sm" @click="carregarTudo" :disabled="loading" aria-label="Atualizar dados do painel">
                <i class="bi bi-arrow-clockwise me-2"></i>Atualizar
              </button>
            </div>
          </div>
        </div>

        <div v-if="erro" class="alert alert-danger rounded-4 mb-4">
          <div class="fw-bold mb-1">Erro ao carregar dados.</div>
          <div class="small">{{ erro }}</div>
        </div>

        <div class="admin-card shadow-sm mb-4">
          <div class="row g-3 align-items-end">
            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">Periodo</label>
              <select class="form-select custom-input fw-bold" v-model="periodo" @change="aplicarPeriodo">
                <option value="hoje">Hoje</option>
                <option value="7dias">Ultimos 7 dias</option>
                <option value="30dias">Ultimos 30 dias</option>
                <option value="6meses">Ultimos 6 meses</option>
                <option value="1ano">Ultimo ano</option>
              </select>
            </div>
            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">De</label>
              <input type="date" class="form-control custom-input fw-bold" v-model="dataDe" />
            </div>
            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">Ate</label>
              <input type="date" class="form-control custom-input fw-bold" v-model="dataAte" />
            </div>
            <div class="col-md-3">
              <button class="btn btn-primary rounded-pill fw-bold px-4 w-100" @click="carregarTudo" :disabled="loading" aria-label="Aplicar filtros de periodo">
                <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>Aplicar
              </button>
            </div>
          </div>
        </div>

        <div v-if="loading" class="admin-card mb-4">
          <div class="d-flex align-items-center gap-3">
            <div class="spinner-border text-primary" role="status"></div>
            <div class="fw-bold">Carregando dados...</div>
          </div>
        </div>

        <template v-else>
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

          <div v-if="activeTab === 'visao-geral'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Painel de Controle Geral do Estabelecimento:</strong>
                <span class="banner-text">
                  Visão consolidada com os principais indicadores do seu negócio: faturamento bruto, total de atendimentos, ticket médio, cancelamentos, clientes únicos e alertas rápidos.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-6 col-xl-3">
                <div class="metric-card metric-card-primary h-100">
                  <div class="metric-icon"><i class="bi bi-cash-stack"></i></div>
                  <div>
                    <span class="metric-label">Faturamento do periodo</span>
                    <h3 class="metric-value">R$ {{ formatMoney(kpis.receitaBruta) }}</h3>
                    <small class="metric-helper">Receita bruta total no periodo selecionado</small>
                  </div>
                </div>
              </div>
              <div class="col-md-6 col-xl-3">
                <div class="metric-card metric-card-success h-100">
                  <div class="metric-icon"><i class="bi bi-calendar-check"></i></div>
                  <div>
                    <span class="metric-label">Atendimentos</span>
                    <h3 class="metric-value">{{ kpis.totalAtendimentos }}</h3>
                    <small class="metric-helper">{{ kpis.concluidos }} concluidos, {{ kpis.cancelados }} cancelados</small>
                  </div>
                </div>
              </div>
              <div class="col-md-6 col-xl-3">
                <div class="metric-card metric-card-warning h-100">
                  <div class="metric-icon"><i class="bi bi-graph-up-arrow"></i></div>
                  <div>
                    <span class="metric-label">Ticket medio</span>
                    <h3 class="metric-value">R$ {{ formatMoney(kpis.ticketMedio) }}</h3>
                    <small class="metric-helper">Valor medio por atendimento</small>
                  </div>
                </div>
              </div>
              <div class="col-md-6 col-xl-3">
                <div class="metric-card metric-card-danger h-100">
                  <div class="metric-icon"><i class="bi bi-x-circle"></i></div>
                  <div>
                    <span class="metric-label">Cancelamentos</span>
                    <h3 class="metric-value">{{ kpis.cancelados }}</h3>
                    <small class="metric-helper">{{ kpis.taxaCancelamento }}% de cancelamento</small>
                  </div>
                </div>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-6 col-xl-3">
                <div class="metric-card h-100">
                  <div class="metric-icon" style="background:rgba(25,135,84,0.1);color:var(--bs-success)"><i class="bi bi-people"></i></div>
                  <div>
                    <span class="metric-label">Clientes atendidos</span>
                    <h3 class="metric-value">{{ kpis.clientesAtendidos }}</h3>
                    <small class="metric-helper">Clientes unicos no periodo</small>
                  </div>
                </div>
              </div>
              <div class="col-md-6 col-xl-3">
                <div class="metric-card h-100">
                  <div class="metric-icon" style="background:rgba(13,110,253,0.1);color:var(--bs-primary)"><i class="bi bi-cash-coin"></i></div>
                  <div>
                    <span class="metric-label">Lucro liquido</span>
                    <h3 class="metric-value">R$ {{ formatMoney(kpis.receitaLiquida) }}</h3>
                    <small class="metric-helper">Receita menos despesas e comissoes</small>
                  </div>
                </div>
              </div>
              <div class="col-md-6 col-xl-3">
                <div class="metric-card h-100">
                  <div class="metric-icon" style="background:rgba(255,193,7,0.1);color:var(--bs-warning)"><i class="bi bi-hourglass-split"></i></div>
                  <div>
                    <span class="metric-label">Comissao pendente</span>
                    <h3 class="metric-value">R$ {{ formatMoney(kpis.comissaoPendente) }}</h3>
                    <small class="metric-helper">Ainda nao foi pago a equipe</small>
                  </div>
                </div>
              </div>
              <div class="col-md-6 col-xl-3">
                <div class="metric-card h-100">
                  <div class="metric-icon" style="background:rgba(108,117,125,0.1);color:var(--bs-secondary)"><i class="bi bi-box-seam"></i></div>
                  <div>
                    <span class="metric-label">Estoque baixo</span>
                    <h3 class="metric-value">{{ alertas.estoqueBaixo }}</h3>
                    <small class="metric-helper">Itens abaixo do estoque minimo</small>
                  </div>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-bar-chart-line me-2 text-primary"></i>Atendimentos por status</h5>
                  <div class="row g-3">
                    <div class="col-sm-6" v-for="item in cardsStatus" :key="item.label">
                      <div class="status-card">
                        <span class="status-dot" :class="item.dotClass"></span>
                        <span class="small text-muted fw-bold">{{ item.label }}</span>
                        <h4 class="fw-900 mb-0">{{ item.total }}</h4>
                        <small class="text-muted">{{ item.percentual }}%</small>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-exclamation-triangle me-2 text-warning"></i>Alertas</h5>
                  <div class="d-flex flex-column gap-3">
                    <div class="alert-item warning">
                      <i class="bi bi-box-seam"></i>
                      <div><strong>{{ alertas.estoqueBaixo }}</strong> itens com estoque baixo</div>
                    </div>
                    <div class="alert-item danger">
                      <i class="bi bi-person-x"></i>
                      <div><strong>{{ alertas.profissionaisSemRegra }}</strong> profissionais sem regra de comissao</div>
                    </div>
                    <div class="alert-item primary">
                      <i class="bi bi-scissors"></i>
                      <div>Mais vendido: <strong>{{ alertas.servicoMaisVendido }}</strong></div>
                    </div>
                    <div class="alert-item success">
                      <i class="bi bi-box2-heart"></i>
                      <div><strong>{{ alertas.pacotesAtivos }}</strong> pacotes ativos</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="activeTab === 'financeiro'">
            <!-- Banner Explicativo sobre o Resumo Financeiro -->
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Entenda o Resumo Financeiro:</strong>
                <span class="banner-text">
                  A <strong>Receita Bruta</strong> é o valor total recebido dos atendimentos concluídos. As <strong>Despesas</strong> são os custos operacionais registrados. As <strong>Comissões</strong> correspondem à parte devida à equipe. O <strong>Lucro Líquido</strong> é o resultado final (Receita - Despesas - Comissões).
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-4">
                <div class="metric-card metric-card-primary h-100">
                  <div class="metric-icon"><i class="bi bi-cash-stack"></i></div>
                  <div>
                    <span class="metric-label">Receita bruta</span>
                    <h3 class="metric-value">R$ {{ formatMoney(kpis.receitaBruta) }}</h3>
                    <small class="metric-helper">Soma de todos os atendimentos e vendas concluídas no período</small>
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="metric-card metric-card-danger h-100">
                  <div class="metric-icon"><i class="bi bi-dash-circle"></i></div>
                  <div>
                    <span class="metric-label">Despesas</span>
                    <h3 class="metric-value">R$ {{ formatMoney(kpis.despesas) }}</h3>
                    <small class="metric-helper">Custos operacionais lançados (contas, insumos, manutenção)</small>
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="metric-card metric-card-success h-100">
                  <div class="metric-icon"><i class="bi bi-plus-circle"></i></div>
                  <div>
                    <span class="metric-label">Lucro liquido</span>
                    <h3 class="metric-value">R$ {{ formatMoney(kpis.receitaLiquida) }}</h3>
                    <small class="metric-helper">Receita Bruta menos Despesas e Comissões pagas/devidas</small>
                  </div>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-8">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-1"><i class="bi bi-graph-up me-2 text-primary"></i>Receita por dia</h5>
                  <p class="small text-muted mb-3">Evolução diária do faturamento dos atendimentos no período selecionado.</p>
                  <div class="chart-bars">
                    <div v-for="dia in receitaPorDia" :key="dia.data" class="chart-bar-item">
                      <div class="chart-bar-label">{{ dia.label }}</div>
                      <div class="chart-bar-track">
                        <div class="chart-bar-fill" :style="{ width: dia.percentual + '%' }"></div>
                      </div>
                      <div class="chart-bar-value">R$ {{ formatMoney(dia.valor) }}</div>
                    </div>
                    <div v-if="!receitaPorDia.length" class="text-muted small py-3">Sem dados no periodo.</div>
                  </div>
                </div>
              </div>
              <div class="col-xl-4">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-1"><i class="bi bi-pie-chart me-2 text-primary"></i>Receita por servico</h5>
                  <p class="small text-muted mb-3">Faturamento gerado por cada tipo de serviço oferecido.</p>
                  <div class="d-flex flex-column gap-2">
                    <div v-for="serv in receitaPorServico" :key="serv.nome" class="rank-mini">
                      <div class="d-flex justify-content-between">
                        <span class="fw-bold small">{{ serv.nome }}</span>
                        <span class="fw-bold text-primary small">R$ {{ formatMoney(serv.valor) }}</span>
                      </div>
                      <div class="progress custom-progress mt-1" style="height:6px">
                        <div class="progress-bar" :style="{ width: serv.percentual + '%' }"></div>
                      </div>
                    </div>
                    <div v-if="!receitaPorServico.length" class="text-muted small">Sem dados.</div>
                  </div>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-1"><i class="bi bi-people me-2 text-primary"></i>Receita por profissional</h5>
                  <p class="small text-muted mb-3">Total produzido por cada barbeiro/profissional da equipe no período.</p>
                  <div class="d-flex flex-column gap-3">
                    <div v-for="prof in topProfissionais" :key="prof.nome" class="team-card">
                      <div class="d-flex align-items-center gap-3">
                        <div class="avatar-circle">{{ prof.nome.charAt(0) }}</div>
                        <div class="flex-grow-1">
                          <div class="d-flex justify-content-between">
                            <strong>{{ prof.nome }}</strong>
                            <span class="fw-bold text-success">R$ {{ formatMoney(prof.producao) }}</span>
                          </div>
                          <small class="text-muted">{{ prof.atendimentos }} atendimentos</small>
                          <div class="progress custom-progress mt-1" style="height:5px">
                            <div class="progress-bar" :style="{ width: prof.percentual + '%' }"></div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div v-if="!topProfissionais.length" class="text-muted small">Sem dados.</div>
                  </div>
                </div>
              </div>
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-1"><i class="bi bi-credit-card me-2 text-primary"></i>Comissoes da Equipe</h5>
                  <p class="small text-muted mb-3">Valores calculados com base nas regras financeiras da equipe.</p>
                  <div class="row g-3">
                    <div class="col-6">
                      <div class="kpi-mini">
                        <span class="small text-muted fw-bold">Pendente (A Pagar)</span>
                        <h4 class="fw-900 text-warning mb-1">R$ {{ formatMoney(kpis.comissaoPendente) }}</h4>
                        <small class="text-muted" style="font-size:0.75rem;">Comissões acumuladas a repassar à equipe</small>
                      </div>
                    </div>
                    <div class="col-6">
                      <div class="kpi-mini">
                        <span class="small text-muted fw-bold">Paga (Repassada)</span>
                        <h4 class="fw-900 text-success mb-1">R$ {{ formatMoney(kpis.comissaoPaga) }}</h4>
                        <small class="text-muted" style="font-size:0.75rem;">Valores já pagos aos profissionais no período</small>
                      </div>
                    </div>
                  </div>
                  <hr>
                  <div class="kpi-mini">
                    <span class="small text-muted fw-bold">Margem de lucro</span>
                    <h4 class="fw-900 mb-0" :class="margemLucro >= 0 ? 'text-success' : 'text-danger'">{{ margemLucro }}%</h4>
                    <small class="text-muted">Percentual da Receita Bruta retido como Lucro Líquido (Lucro / Receita Bruta)</small>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="activeTab === 'agendamentos'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Indicadores e Controle de Agendamentos:</strong>
                <span class="banner-text">
                  Acompanhe os agendamentos de hoje, atendimentos concluídos, pendentes de confirmação, cancelamentos, distribuição por dia da semana e horários de maior movimento.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-3">
                <div class="metric-card metric-card-primary h-100">
                  <div class="metric-icon"><i class="bi bi-calendar-event"></i></div>
                  <div>
                    <span class="metric-label">Hoje</span>
                    <h3 class="metric-value">{{ agendamentosHoje }}</h3>
                    <small class="metric-helper">Agendamentos para hoje</small>
                  </div>
                </div>
              </div>
              <div class="col-md-3">
                <div class="metric-card metric-card-success h-100">
                  <div class="metric-icon"><i class="bi bi-check-circle"></i></div>
                  <div>
                    <span class="metric-label">Concluidos</span>
                    <h3 class="metric-value">{{ kpis.concluidos }}</h3>
                    <small class="metric-helper">Atendimentos finalizados</small>
                  </div>
                </div>
              </div>
              <div class="col-md-3">
                <div class="metric-card metric-card-warning h-100">
                  <div class="metric-icon"><i class="bi bi-clock"></i></div>
                  <div>
                    <span class="metric-label">Pendentes</span>
                    <h3 class="metric-value">{{ kpis.pendentes }}</h3>
                    <small class="metric-helper">Aguardando confirmacao</small>
                  </div>
                </div>
              </div>
              <div class="col-md-3">
                <div class="metric-card metric-card-danger h-100">
                  <div class="metric-icon"><i class="bi bi-clock-history"></i></div>
                  <div>
                    <span class="metric-label">Cancelados</span>
                    <h3 class="metric-value">{{ kpis.cancelados }}</h3>
                    <small class="metric-helper">{{ kpis.taxaCancelamento }}% do total</small>
                  </div>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-8">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-bar-chart me-2 text-primary"></i>Agendamentos por dia da semana</h5>
                  <div class="chart-bars">
                    <div v-for="dia in agendamentosPorDiaSemana" :key="dia.nome" class="chart-bar-item">
                      <div class="chart-bar-label">{{ dia.nome }}</div>
                      <div class="chart-bar-track">
                        <div class="chart-bar-fill bg-success" :style="{ width: dia.percentual + '%' }"></div>
                      </div>
                      <div class="chart-bar-value">{{ dia.total }}</div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="col-xl-4">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-clock me-2 text-primary"></i>Horarios mais movimentados</h5>
                  <div class="d-flex flex-column gap-2">
                    <div v-for="hora in horariosTop" :key="hora.hora" class="d-flex justify-content-between align-items-center p-2 rounded" style="background:rgba(var(--bs-body-color-rgb),0.02)">
                      <span class="fw-bold small">{{ hora.hora }}</span>
                      <span class="badge bg-primary bg-opacity-10 text-primary rounded-pill">{{ hora.total }}</span>
                    </div>
                    <div v-if="!horariosTop.length" class="text-muted small">Sem dados.</div>
                  </div>
                </div>
              </div>
            </div>

            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-calendar-week me-2 text-primary"></i>Ultimos agendamentos</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead>
                    <tr>
                      <th>Data</th>
                      <th>Cliente</th>
                      <th>Servico</th>
                      <th>Profissional</th>
                      <th>Valor</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="ag in ultimosAgendamentos" :key="ag.id">
                      <td class="fw-bold small">{{ ag.appointment_date }}</td>
                      <td>{{ maskName(ag.customer_name) || 'Cliente' }}</td>
                      <td>{{ ag.service_name_snapshot }}</td>
                      <td>{{ ag.employee_name }}</td>
                      <td class="fw-bold">R$ {{ formatMoney(ag.price_snapshot) }}</td>
                      <td>
                        <span class="badge rounded-pill px-3 py-1 fw-bold" :class="statusBadge(ag.status)">{{ statusLabel(ag.status) }}</span>
                      </td>
                    </tr>
                    <tr v-if="!ultimosAgendamentos.length">
                      <td colspan="6" class="text-muted text-center py-3">Nenhum agendamento no periodo.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div v-if="activeTab === 'clientes'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Análise da Base de Clientes:</strong>
                <span class="banner-text">
                  Métricas de clientes únicos, frequência de visitas, relação entre novos clientes e recorrentes, ticket médio individual e ranking dos melhores clientes.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-4">
                <div class="metric-card metric-card-primary h-100">
                  <div class="metric-icon"><i class="bi bi-people"></i></div>
                  <div>
                    <span class="metric-label">Clientes unicos</span>
                    <h3 class="metric-value">{{ clientesUnicos }}</h3>
                    <small class="metric-helper">Clientes que visitaram no periodo</small>
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="metric-card metric-card-success h-100">
                  <div class="metric-icon"><i class="bi bi-arrow-repeat"></i></div>
                  <div>
                    <span class="metric-label">Clientes recorrentes</span>
                    <h3 class="metric-value">{{ clientesRecorrentes }}</h3>
                    <small class="metric-helper">Com mais de 1 atendimento</small>
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="metric-card metric-card-warning h-100">
                  <div class="metric-icon"><i class="bi bi-person-check"></i></div>
                  <div>
                    <span class="metric-label">Novos clientes</span>
                    <h3 class="metric-value">{{ novosClientes }}</h3>
                    <small class="metric-helper">Primeira visita no periodo</small>
                  </div>
                </div>
              </div>
            </div>

            <div class="row g-4 mb-4">
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-trophy me-2 text-primary"></i>Top clientes por visitas</h5>
                  <div class="d-flex flex-column gap-2">
                    <div v-for="(cli, i) in topClientes" :key="cli.nome" class="d-flex align-items-center gap-3 p-2 rounded" style="background:rgba(var(--bs-body-color-rgb),0.02)">
                      <span class="fw-900 text-muted" style="width:24px">{{ i + 1 }}</span>
                      <div class="flex-grow-1">
                        <strong class="small">{{ maskName(cli.nome) }}</strong>
                        <small class="d-block text-muted">{{ cli.total }} visitas</small>
                      </div>
                      <span class="fw-bold text-primary small">R$ {{ formatMoney(cli.gasto) }}</span>
                    </div>
                    <div v-if="!topClientes.length" class="text-muted small">Sem dados de clientes.</div>
                  </div>
                </div>
              </div>
              <div class="col-xl-6">
                <div class="admin-card h-100">
                  <h5 class="fw-bold mb-3"><i class="bi bi-pie-chart me-2 text-primary"></i>Frequencia</h5>
                  <div class="row g-3">
                    <div class="col-6">
                      <div class="kpi-mini">
                        <span class="small text-muted fw-bold">Frequencia media</span>
                        <h4 class="fw-900 mb-0">{{ frequenciaMedia }}</h4>
                        <small class="text-muted">visitas por cliente</small>
                      </div>
                    </div>
                    <div class="col-6">
                      <div class="kpi-mini">
                        <span class="small text-muted fw-bold">Ticket medio</span>
                        <h4 class="fw-900 mb-0">R$ {{ formatMoney(ticketMedioCliente) }}</h4>
                        <small class="text-muted">gasto medio por cliente</small>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="activeTab === 'servicos'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Desempenho por Tipo de Serviço:</strong>
                <span class="banner-text">
                  Ranking dos serviços mais realizados na empresa, quantidade vendida, receita total gerada e percentual de participação de cada serviço no faturamento.
                </span>
              </div>
            </div>

            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-scissors me-2 text-primary"></i>Ranking de servicos</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Servico</th>
                      <th>Quantidade</th>
                      <th>Receita</th>
                      <th>Participacao</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(serv, i) in rankingServicos" :key="serv.nome">
                      <td class="fw-900">{{ i + 1 }}</td>
                      <td class="fw-bold">{{ serv.nome }}</td>
                      <td>{{ serv.quantidade }}</td>
                      <td class="fw-bold text-success">R$ {{ formatMoney(serv.receita) }}</td>
                      <td>
                        <div class="progress custom-progress" style="height:6px;width:120px">
                          <div class="progress-bar" :style="{ width: serv.percentual + '%' }"></div>
                        </div>
                        <small class="text-muted">{{ serv.percentual }}%</small>
                      </td>
                    </tr>
                    <tr v-if="!rankingServicos.length">
                      <td colspan="5" class="text-muted text-center py-3">Nenhum servico no periodo.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div v-if="activeTab === 'barbeiros'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Desempenho e Produtividade da Equipe:</strong>
                <span class="banner-text">
                  Comparativo de cada barbeiro/profissional por número de atendimentos, receita gerada, ticket médio e modelo financeiro aplicado (comissão, fixo ou diária).
                </span>
              </div>
            </div>

            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-people me-2 text-primary"></i>Desempenho da equipe</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead>
                    <tr>
                      <th>Barbeiro</th>
                      <th>Clientes</th>
                      <th>Receita</th>
                      <th>Ticket medio</th>
                      <th>Modelo</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="prof in rankingBarbeiros" :key="prof.nome">
                      <td>
                        <div class="d-flex align-items-center gap-2">
                          <div class="avatar-circle-sm">{{ prof.nome.charAt(0) }}</div>
                          <strong>{{ prof.nome }}</strong>
                        </div>
                      </td>
                      <td>{{ prof.atendimentos }}</td>
                      <td class="fw-bold text-success">R$ {{ formatMoney(prof.producao) }}</td>
                      <td class="fw-bold">R$ {{ formatMoney(prof.ticketMedio) }}</td>
                      <td><span class="badge rounded-pill bg-primary bg-opacity-10 text-primary">{{ prof.modelo || '-' }}</span></td>
                    </tr>
                    <tr v-if="!rankingBarbeiros.length">
                      <td colspan="5" class="text-muted text-center py-3">Nenhum profissional no periodo.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div v-if="activeTab === 'produtos'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Controle de Estoque e Produtos:</strong>
                <span class="banner-text">
                  Visão geral do inventário: total de itens cadastrados, valor financeiro em estoque e alertas de produtos com quantidade abaixo do mínimo configurado.
                </span>
              </div>
            </div>

            <div class="row g-3 mb-4">
              <div class="col-md-4">
                <div class="metric-card metric-card-primary h-100">
                  <div class="metric-icon"><i class="bi bi-box"></i></div>
                  <div>
                    <span class="metric-label">Total de itens</span>
                    <h3 class="metric-value">{{ stockItems.length }}</h3>
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="metric-card metric-card-danger h-100">
                  <div class="metric-icon"><i class="bi bi-exclamation-triangle"></i></div>
                  <div>
                    <span class="metric-label">Estoque baixo</span>
                    <h3 class="metric-value">{{ alertas.estoqueBaixo }}</h3>
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <div class="metric-card metric-card-success h-100">
                  <div class="metric-icon"><i class="bi bi-cash"></i></div>
                  <div>
                    <span class="metric-label">Valor em estoque</span>
                    <h3 class="metric-value">R$ {{ formatMoney(valorEstoque) }}</h3>
                  </div>
                </div>
              </div>
            </div>

            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-box-seam me-2 text-primary"></i>Itens em estoque</h5>
              <div class="table-responsive">
                <table class="table table-clean align-middle mb-0">
                  <thead>
                    <tr>
                      <th>Produto</th>
                      <th>Quantidade</th>
                      <th>Estoque minimo</th>
                      <th>Preco</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="item in stockItems" :key="item.id || item.nome || item.name">
                      <td class="fw-bold">{{ item.nome || item.name }}</td>
                      <td>{{ item.estoque ?? item.quantity }} un.</td>
                      <td>{{ item.estoque_minimo ?? item.minimum_stock }} un.</td>
                      <td class="fw-bold">R$ {{ formatMoney(Number(item.preco || item.sale_price || 0)) }}</td>
                      <td>
                        <span class="badge rounded-pill fw-bold" :class="Number(item.estoque ?? item.quantity) <= Number(item.estoque_minimo ?? item.minimum_stock) ? 'bg-danger bg-opacity-10 text-danger' : 'bg-success bg-opacity-10 text-success'">
                          {{ Number(item.estoque ?? item.quantity) <= Number(item.estoque_minimo ?? item.minimum_stock) ? 'Baixo' : 'OK' }}
                        </span>
                      </td>
                    </tr>
                    <tr v-if="!stockItems.length">
                      <td colspan="5" class="text-muted text-center py-3">Nenhum item em estoque.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div v-if="activeTab === 'marketing'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Canais de Aquisição e Marketing:</strong>
                <span class="banner-text">
                  Análise de onde seus clientes vieram (redes sociais, indicação, busca orgânica, etc.) para identificar quais canais geram mais agendamentos e retorno.
                </span>
              </div>
            </div>

            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-megaphone me-2 text-primary"></i>Canais de aquisicao</h5>
              <p class="small text-muted mb-3">Dados sobre de onde vem seus clientes. Funcionalidade disponivel em breve.</p>
              <div class="row g-3">
                <div class="col-md-3" v-for="canal in canaisMarketing" :key="canal.nome">
                  <div class="text-center p-4 rounded-4" style="background:rgba(var(--bs-body-color-rgb),0.02);border:1px dashed var(--card-border)">
                    <i :class="canal.icone + ' fs-1 text-muted mb-2 d-block'"></i>
                    <strong>{{ canal.nome }}</strong>
                    <h4 class="fw-900 text-muted mt-1">--</h4>
                    <small class="text-muted">Em breve</small>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="activeTab === 'fidelizacao'">
            <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
              <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                <i class="bi bi-info-circle-fill fs-5"></i>
              </div>
              <div class="small">
                <strong class="d-block banner-title mb-1">Programa de Fidelização e Retenção:</strong>
                <span class="banner-text">
                  Gerencie clientes VIP (mais de 3 visitas), identifique quem está sem visitar há mais de 60 dias e ative estratégias de retenção como pontos e recompensas.
                </span>
              </div>
            </div>

            <div class="admin-card mb-4">
              <h5 class="fw-bold mb-3"><i class="bi bi-heart me-2 text-primary"></i>Programa de fidelizacao</h5>
              <p class="small text-muted mb-3">Gerencie clientes VIP, aniversariantes e programa de pontos. Funcionalidade disponivel em breve.</p>
              <div class="row g-3">
                <div class="col-md-4">
                  <div class="text-center p-4 rounded-4" style="background:rgba(var(--bs-body-color-rgb),0.02);border:1px dashed var(--card-border)">
                    <i class="bi bi-star fs-1 text-warning mb-2 d-block"></i>
                    <strong>Clientes VIP</strong>
                    <h4 class="fw-900 text-muted mt-1">{{ clientesRecorrentes }}</h4>
                    <small class="text-muted">Com 3+ visitas</small>
                  </div>
                </div>
                <div class="col-md-4">
                  <div class="text-center p-4 rounded-4" style="background:rgba(var(--bs-body-color-rgb),0.02);border:1px dashed var(--card-border)">
                    <i class="bi bi-calendar-heart fs-1 text-danger mb-2 d-block"></i>
                    <strong>Sem visitar 60+ dias</strong>
                    <h4 class="fw-900 text-muted mt-1">--</h4>
                    <small class="text-muted">Em breve</small>
                  </div>
                </div>
                <div class="col-md-4">
                  <div class="text-center p-4 rounded-4" style="background:rgba(var(--bs-body-color-rgb),0.02);border:1px dashed var(--card-border)">
                    <i class="bi bi-gift fs-1 text-success mb-2 d-block"></i>
                    <strong>Aniversariantes</strong>
                    <h4 class="fw-900 text-muted mt-1">--</h4>
                    <small class="text-muted">Em breve</small>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>

        <div class="mt-4 pt-3 border-top" style="border-color: var(--card-border) !important">
          <p class="small text-muted mb-0" style="opacity: 0.6">
            <i class="bi bi-shield-lock me-1"></i>
            Dados pessoais mascarados conforme LGPD. Apenas dados necessarios para operacao sao exibidos.
          </p>
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
  { id: 'clientes', label: 'Clientes', icon: 'bi bi-people' },
  { id: 'servicos', label: 'Servicos', icon: 'bi bi-scissors' },
  { id: 'barbeiros', label: 'Barbeiros', icon: 'bi bi-person-badge' },
  { id: 'produtos', label: 'Produtos', icon: 'bi bi-box' },
  { id: 'marketing', label: 'Marketing', icon: 'bi bi-megaphone' },
  { id: 'fidelizacao', label: 'Fidelizacao', icon: 'bi bi-heart' }
]

const periodo = ref('30dias')
const dataDe = ref('')
const dataAte = ref('')
const establishmentId = ref(0)

const dashboardResumo = ref({ gross_revenue: 0, expenses: 0, net_revenue: 0, pending_commissions: 0, paid_commissions: 0 })
const appointments = ref<any[]>([])
const memberships = ref<any[]>([])
const stockItems = ref<any[]>([])
const servicePackages = ref<any[]>([])

function formatMoney(v: number) {
  return Number(v || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function toInputDate(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function isValidDate(dateStr: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(dateStr) && !isNaN(Date.parse(dateStr))
}

function maskName(name: string): string {
  if (!name) return '***'
  if (name.length <= 2) return name.charAt(0) + '*'
  return name.charAt(0) + '*'.repeat(Math.min(name.length - 2, 4)) + name.charAt(name.length - 1)
}

function aplicarPeriodo() {
  const hoje = new Date()
  const inicio = new Date()
  switch (periodo.value) {
    case 'hoje': break
    case '7dias': inicio.setDate(hoje.getDate() - 7); break
    case '30dias': inicio.setDate(hoje.getDate() - 30); break
    case '6meses': inicio.setMonth(hoje.getMonth() - 6); break
    case '1ano': inicio.setFullYear(hoje.getFullYear() - 1); break
  }
  dataDe.value = toInputDate(inicio)
  dataAte.value = toInputDate(hoje)
}

function normalizarAppointment(item: any) {
  return {
    id: item.id,
    status: item.status || 'pending',
    price_snapshot: Number(item.price_snapshot || 0),
    service_name_snapshot: item.service_name_snapshot || item.service?.name || item.service_name || 'Servico',
    employee_name: item.employee_name || item.employee?.name || item.employee_name_snapshot || 'Profissional',
    specialty: item.employee?.specialty || item.specialty || 'Equipe',
    removed_at: item.removed_at || item.employee_removed_at || null,
    appointment_date: item.appointment_date || null,
    customer_name: item.customer_name || item.customer?.name || null,
    start_time: item.start_time || null
  }
}

function normalizarMembership(item: any) {
  return {
    user_name: item.user_name || item.user?.name || 'Profissional',
    specialty: item.specialty || 'Equipe',
    financial_model: item.financial_model || null,
    financial_value: item.financial_value,
    removed_at: item.removed_at || (item.active === false ? 'inativo' : null)
  }
}

async function fetchJson(url: string) {
  const path = url.replace(/^https?:\/\/[^/]+/, '')
  const { data } = await api.get(path)
  return data
}

// Versão segura: retorna o fallback em caso de 403 (permissão negada)
// Evita que rotas opcionais (equipe, estoque) quebrem todo o dashboard
async function fetchJsonSafe(url: string, fallback: any = null) {
  try {
    return await fetchJson(url)
  } catch (err: any) {
    if (err?.response?.status === 403) return fallback
    throw err
  }
}

async function carregarTudo() {
  loading.value = true
  erro.value = ''
  try {
    // Validação de datas antes de enviar ao servidor
    if (dataDe.value && dataAte.value && dataDe.value > dataAte.value) {
      erro.value = 'A data inicial não pode ser posterior à data final.'
      loading.value = false
      return
    }

    const est = await fetchJson('/admin/establishment')
    establishmentId.value = Number(est?.id || 0)
    if (!establishmentId.value) { erro.value = 'Nao foi possivel carregar dados.'; return }

    const params = new URLSearchParams({ establishment_id: String(establishmentId.value) })
    if (dataDe.value && isValidDate(dataDe.value)) params.append('start_date', dataDe.value)
    if (dataAte.value && isValidDate(dataAte.value)) params.append('end_date', dataAte.value)

    // fetchJsonSafe para rotas opcionais: 403 retorna fallback vazio
    // evita que permissões faltando em equipe/estoque derrubem todo o painel
    const [dashRes, aptRes, teamRes, stockRes, pkgRes] = await Promise.all([
      fetchJson(`/financial/dashboard?${params}`),
      fetchJson(`/appointments?${params}`),
      fetchJsonSafe('/admin/team', []),
      fetchJsonSafe('/stock_items', []),
      fetchJsonSafe('/service_packages', [])
    ])

    dashboardResumo.value = dashRes?.summary || { gross_revenue: 0, expenses: 0, net_revenue: 0, pending_commissions: 0, paid_commissions: 0 }
    appointments.value = Array.isArray(aptRes) ? aptRes.map(normalizarAppointment) : Array.isArray(aptRes?.appointments) ? aptRes.appointments.map(normalizarAppointment) : []
    memberships.value = Array.isArray(teamRes) ? teamRes.map(normalizarMembership) : Array.isArray(teamRes?.memberships) ? teamRes.memberships.map(normalizarMembership) : []
    stockItems.value = Array.isArray(stockRes) ? stockRes : Array.isArray(stockRes?.stock_items) ? stockRes.stock_items : []
    servicePackages.value = Array.isArray(pkgRes) ? pkgRes : Array.isArray(pkgRes?.service_packages) ? pkgRes.service_packages : []
  } catch (err: any) {
    const serverMsg = err?.response?.data?.error
    erro.value = serverMsg || 'Nao foi possivel carregar os dados do painel financeiro.'
  } finally {
    loading.value = false
  }
}

const appointmentsFiltrados = computed(() => appointments.value)

const kpis = computed(() => {
  const total = appointmentsFiltrados.value.length
  const cancelados = appointmentsFiltrados.value.filter(a => a.status === 'canceled').length
  const concluidos = appointmentsFiltrados.value.filter(a => a.status === 'completed').length
  const confirmados = appointmentsFiltrados.value.filter(a => a.status === 'confirmed').length
  const pendentes = appointmentsFiltrados.value.filter(a => a.status === 'pending').length
  const receitaConcluidos = appointmentsFiltrados.value.filter(a => a.status === 'completed' || a.status === 'confirmed').reduce((acc, a) => acc + Number(a.price_snapshot || 0), 0)
  const receita = receitaConcluidos || appointmentsFiltrados.value.reduce((acc, a) => acc + Number(a.price_snapshot || 0), 0)
  const clientes = new Set(appointmentsFiltrados.value.map(a => a.customer_name).filter(Boolean)).size

  const bruta = Number(dashboardResumo.value.gross_revenue || 0) || receita
  const desp = Number(dashboardResumo.value.expenses || 0)
  const comPaga = Number(dashboardResumo.value.paid_commissions || 0)
  const comPend = Number(dashboardResumo.value.pending_commissions || 0)
  const liquidaResumo = Number(dashboardResumo.value.net_revenue || 0)
  const liquida = liquidaResumo !== 0 ? liquidaResumo : (bruta - desp - comPaga)

  return {
    receitaBruta: bruta,
    despesas: desp,
    receitaLiquida: liquida,
    comissaoPendente: comPend,
    comissaoPaga: comPaga,
    totalAtendimentos: total,
    ticketMedio: concluidos ? receita / concluidos : (total ? receita / total : 0),
    cancelados,
    concluidos,
    confirmados,
    pendentes,
    clientesAtendidos: clientes || total,
    taxaCancelamento: total ? Math.round((cancelados / total) * 100) : 0
  }
})

const cardsStatus = computed(() => {
  const total = kpis.value.totalAtendimentos || 1
  return [
    { label: 'Confirmados', total: kpis.value.confirmados, percentual: Math.round((kpis.value.confirmados / total) * 100), dotClass: 'primary' },
    { label: 'Concluidos', total: kpis.value.concluidos, percentual: Math.round((kpis.value.concluidos / total) * 100), dotClass: 'success' },
    { label: 'Pendentes', total: kpis.value.pendentes, percentual: Math.round((kpis.value.pendentes / total) * 100), dotClass: 'warning' },
    { label: 'Cancelados', total: kpis.value.cancelados, percentual: Math.round((kpis.value.cancelados / total) * 100), dotClass: 'danger' }
  ]
})

const alertas = computed(() => ({
  estoqueBaixo: stockItems.value.filter(i => Number(i.estoque ?? i.quantity) <= Number(i.estoque_minimo ?? i.minimum_stock)).length,
  profissionaisSemRegra: memberships.value.filter(i => !i.financial_model || i.financial_value == null).length,
  pacotesAtivos: servicePackages.value.filter(i => i.active).length,
  servicoMaisVendido: topServicos.value[0]?.nome || 'Sem dados'
}))

const topServicos = computed(() => {
  const mapa: Record<string, number> = {}
  appointmentsFiltrados.value.forEach(a => { mapa[a.service_name_snapshot] = (mapa[a.service_name_snapshot] || 0) + 1 })
  const total = appointmentsFiltrados.value.length || 1
  return Object.entries(mapa).map(([nome, qtd]) => ({ nome, total: qtd, percentual: Math.round((qtd / total) * 100) })).sort((a, b) => b.total - a.total).slice(0, 10)
})

const topProfissionais = computed(() => {
  const mapa: Record<string, any> = {}
  appointmentsFiltrados.value.forEach(a => {
    const n = a.employee_name
    if (!mapa[n]) mapa[n] = { nome: n, producao: 0, atendimentos: 0 }
    mapa[n].producao += Number(a.price_snapshot || 0)
    mapa[n].atendimentos++
  })
  const arr = Object.values(mapa).sort((a: any, b: any) => b.producao - a.producao)
  const max = arr[0]?.producao || 1
  arr.forEach((p: any) => { p.percentual = Math.round((p.producao / max) * 100) })
  return arr.slice(0, 10)
})

const receitaPorDia = computed(() => {
  const mapa: Record<string, number> = {}
  appointmentsFiltrados.value.forEach(a => {
    if (a.appointment_date) mapa[a.appointment_date] = (mapa[a.appointment_date] || 0) + Number(a.price_snapshot || 0)
  })
  const arr = Object.entries(mapa).map(([data, valor]) => ({ data, valor, label: data.slice(5), percentual: 0 })).sort((a, b) => a.data.localeCompare(b.data)).slice(-14)
  const max = Math.max(...arr.map(d => d.valor), 1)
  arr.forEach(d => { d.percentual = Math.round((d.valor / max) * 100) })
  return arr
})

const receitaPorServico = computed(() => {
  const mapa: Record<string, number> = {}
  appointmentsFiltrados.value.forEach(a => { mapa[a.service_name_snapshot] = (mapa[a.service_name_snapshot] || 0) + Number(a.price_snapshot || 0) })
  const arr = Object.entries(mapa).map(([nome, valor]) => ({ nome, valor, percentual: 0 })).sort((a, b) => b.valor - a.valor).slice(0, 8)
  const max = arr[0]?.valor || 1
  arr.forEach(s => { s.percentual = Math.round((s.valor / max) * 100) })
  return arr
})

const margemLucro = computed(() => {
  const bruta = kpis.value.receitaBruta || 1
  return Math.round(((kpis.value.receitaLiquida) / bruta) * 100)
})

const agendamentosHoje = computed(() => {
  const hoje = toInputDate(new Date())
  return appointments.value.filter(a => a.appointment_date === hoje).length
})

const noShows = computed(() => appointmentsFiltrados.value.filter(a => a.status === 'pending' || a.status === 'no_show' || a.status === 'missed').length)

const agendamentosPorDiaSemana = computed(() => {
  const nomes = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab']
  const contagem = [0, 0, 0, 0, 0, 0, 0]
  appointmentsFiltrados.value.forEach(a => {
    if (a.appointment_date) {
      const d = new Date(a.appointment_date + 'T12:00:00')
      const idx = d.getDay()
      contagem[idx] = (contagem[idx] ?? 0) + 1
    }
  })
  const max = Math.max(...contagem, 1)
  return nomes.map((nome, i) => ({ nome, total: contagem[i] ?? 0, percentual: Math.round(((contagem[i] ?? 0) / max) * 100) }))
})

const horariosTop = computed(() => {
  const mapa: Record<string, number> = {}
  appointmentsFiltrados.value.forEach(a => {
    if (a.start_time) {
      const h = a.start_time.slice(0, 5)
      mapa[h] = (mapa[h] || 0) + 1
    }
  })
  return Object.entries(mapa).map(([hora, total]) => ({ hora, total })).sort((a, b) => b.total - a.total).slice(0, 8)
})

const ultimosAgendamentos = computed(() => [...appointmentsFiltrados.value].sort((a, b) => (b.appointment_date || '').localeCompare(a.appointment_date || '')).slice(0, 15))

const clientesUnicos = computed(() => new Set(appointmentsFiltrados.value.map(a => a.customer_name).filter(Boolean)).size || appointmentsFiltrados.value.length)

const clientesRecorrentes = computed(() => {
  const mapa: Record<string, number> = {}
  appointmentsFiltrados.value.forEach(a => {
    const c = a.customer_name || `Cliente-${a.id}`
    mapa[c] = (mapa[c] || 0) + 1
  })
  return Object.values(mapa).filter(v => v > 1).length
})

const novosClientes = computed(() => {
  const mapa: Record<string, number> = {}
  appointmentsFiltrados.value.forEach(a => {
    const c = a.customer_name || `Cliente-${a.id}`
    mapa[c] = (mapa[c] || 0) + 1
  })
  return Object.values(mapa).filter(v => v === 1).length
})

const topClientes = computed(() => {
  const mapa: Record<string, { nome: string; total: number; gasto: number }> = {}
  appointmentsFiltrados.value.forEach(a => {
    const c = a.customer_name || `Cliente-${a.id}`
    if (!mapa[c]) mapa[c] = { nome: c, total: 0, gasto: 0 }
    mapa[c].total++
    mapa[c].gasto += Number(a.price_snapshot || 0)
  })
  return Object.values(mapa).sort((a, b) => b.total - a.total).slice(0, 8)
})

const frequenciaMedia = computed(() => {
  const total = kpis.value.totalAtendimentos
  const clientes = clientesUnicos.value || 1
  return (total / clientes).toFixed(1)
})

const ticketMedioCliente = computed(() => {
  const receita = appointmentsFiltrados.value.reduce((acc, a) => acc + Number(a.price_snapshot || 0), 0)
  const clientes = clientesUnicos.value || 1
  return receita / clientes
})

const rankingServicos = computed(() => {
  const mapa: Record<string, { nome: string; quantidade: number; receita: number; percentual: number }> = {}
  appointmentsFiltrados.value.forEach(a => {
    const n = a.service_name_snapshot
    if (!mapa[n]) mapa[n] = { nome: n, quantidade: 0, receita: 0, percentual: 0 }
    mapa[n].quantidade++
    mapa[n].receita += Number(a.price_snapshot || 0)
  })
  const arr = Object.values(mapa).sort((a, b) => b.receita - a.receita)
  const total = arr.reduce((acc, s) => acc + s.receita, 0) || 1
  arr.forEach(s => { s.percentual = Math.round((s.receita / total) * 100) })
  return arr
})

const rankingBarbeiros = computed(() => {
  const mapa: Record<string, any> = {}
  appointmentsFiltrados.value.forEach(a => {
    const n = a.employee_name
    if (!mapa[n]) mapa[n] = { nome: n, atendimentos: 0, producao: 0, ticketMedio: 0, modelo: '' }
    mapa[n].atendimentos++
    mapa[n].producao += Number(a.price_snapshot || 0)
  })
  const membershipMap: Record<string, string> = {}
  memberships.value.forEach(m => { membershipMap[m.user_name] = m.financial_model || '' })
  Object.values(mapa).forEach((p: any) => {
    p.ticketMedio = p.atendimentos ? p.producao / p.atendimentos : 0
    p.modelo = membershipMap[p.nome] || '-'
  })
  return Object.values(mapa).sort((a: any, b: any) => b.producao - a.producao)
})

const valorEstoque = computed(() => stockItems.value.reduce((acc, i) => acc + (Number(i.estoque ?? i.quantity) * Number(i.preco || i.sale_price || i.unit_cost || 0)), 0))

const canaisMarketing = [
  { nome: 'Instagram', icone: 'bi bi-instagram' },
  { nome: 'Google', icone: 'bi bi-google' },
  { nome: 'Indicacao', icone: 'bi bi-person-hearts' },
  { nome: 'WhatsApp', icone: 'bi bi-whatsapp' }
]

function statusBadge(s: string) {
  switch (s) {
    case 'pending': return 'bg-warning bg-opacity-10 text-warning border-warning'
    case 'confirmed': return 'bg-primary bg-opacity-10 text-primary border-primary'
    case 'completed': return 'bg-success bg-opacity-10 text-success border-success'
    case 'canceled': return 'bg-danger bg-opacity-10 text-danger border-danger'
    default: return 'bg-secondary bg-opacity-10 text-secondary border-secondary'
  }
}

function statusLabel(s: string) {
  switch (s) {
    case 'pending': return 'Pendente'
    case 'confirmed': return 'Confirmado'
    case 'completed': return 'Concluido'
    case 'canceled': return 'Cancelado'
    case 'no_show': return 'Pendente'
    case 'missed': return 'Pendente'
    default: return s
  }
}

onMounted(() => {
  aplicarPeriodo()
  carregarTudo()
})
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
.metric-icon { width: 52px; height: 52px; border-radius: 16px; display: flex; align-items: center; justify-content: center; background: rgba(13, 110, 253, 0.1); color: var(--bs-primary); font-size: 1.25rem; flex-shrink: 0; }
.metric-label { display: block; font-size: 0.8rem; color: var(--bs-secondary-color); font-weight: 700; margin-bottom: 4px; }
.metric-value { font-weight: 900; margin-bottom: 4px; }
.metric-helper { color: var(--bs-secondary-color); }
.status-card, .team-card, .kpi-mini, .rank-mini { background: rgba(var(--bs-body-color-rgb), 0.015); border: 1px solid var(--card-border); border-radius: 16px; padding: 1rem; transition: all 0.2s; }
.status-card:hover, .team-card:hover { transform: translateY(-2px); box-shadow: 0 6px 18px var(--card-shadow) !important; }
.status-dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; margin-bottom: 6px; }
.status-dot.primary { background: var(--bs-primary); }
.status-dot.success { background: var(--bs-success); }
.status-dot.warning { background: var(--bs-warning); }
.status-dot.danger { background: var(--bs-danger); }
.alert-item { display: flex; align-items: center; gap: 12px; padding: 0.85rem 1rem; border-radius: 14px; border: 1px solid var(--card-border); background: rgba(var(--bs-body-color-rgb), 0.01); transition: all 0.2s; }
.alert-item:hover { transform: translateY(-2px); box-shadow: 0 4px 12px var(--card-shadow); }
.alert-item.warning { border-left: 4px solid var(--bs-warning); }
.alert-item.danger { border-left: 4px solid var(--bs-danger); }
.alert-item.primary { border-left: 4px solid var(--bs-primary); }
.alert-item.success { border-left: 4px solid var(--bs-success); }
.avatar-circle { width: 42px; height: 42px; border-radius: 50%; background: rgba(13, 110, 253, 0.1); color: var(--bs-primary); display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 1.1rem; flex-shrink: 0; }
.avatar-circle-sm { width: 32px; height: 32px; border-radius: 50%; background: rgba(13, 110, 253, 0.1); color: var(--bs-primary); display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 0.85rem; flex-shrink: 0; }
.custom-progress { border-radius: 10px; background: rgba(var(--bs-body-color-rgb), 0.08); }
.chart-bars { display: flex; flex-direction: column; gap: 10px; }
.chart-bar-item { display: flex; align-items: center; gap: 12px; }
.chart-bar-label { min-width: 48px; font-size: 0.75rem; font-weight: 700; color: var(--bs-secondary-color); }
.chart-bar-track { flex: 1; height: 10px; background: rgba(var(--bs-body-color-rgb), 0.06); border-radius: 10px; overflow: hidden; }
.chart-bar-fill { height: 100%; background: var(--bs-primary); border-radius: 10px; transition: width 0.6s ease; }
.chart-bar-fill.bg-success { background: var(--bs-success) !important; }
.chart-bar-value { min-width: 72px; font-size: 0.8rem; font-weight: 700; text-align: right; }
.table-clean th { font-size: 0.75rem; font-weight: 700; text-transform: uppercase; color: var(--bs-secondary-color); border-bottom: 1px solid var(--card-border); padding: 12px 16px; }
.table-clean td { padding: 12px 16px; border-bottom: 1px solid rgba(var(--bs-body-color-rgb), 0.05); }
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
</style>
