<template>
  <AdminLayout>
    <section class="page-shell">
      <div class="page-content">

        <!-- Header Premium -->
        <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
          <div class="header-overlay"></div>
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1 w-100">
            <div class="d-flex align-items-center gap-3">
              <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                <i class="bi bi-file-earmark-lock fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Fechamento</h1>
                <p class="text-muted mb-0 small-text-responsive">
                  Cálculo, controle, fechamento e documentação de comissões brutas da equipe.
                </p>
              </div>
            </div>

            <div class="d-flex align-items-center gap-2 flex-wrap">
              <button class="btn btn-outline-primary rounded-pill fw-bold px-3 py-2 shadow-sm" @click="exportarCSV" :disabled="loading">
                <i class="bi bi-filetype-csv me-2"></i>Exportar CSV
              </button>
              <button class="btn btn-outline-secondary rounded-pill fw-bold px-3 py-2 shadow-sm" @click="imprimirRelatorio" :disabled="loading">
                <i class="bi bi-printer me-2"></i>Imprimir Relatório
              </button>
              <button class="btn btn-primary rounded-pill fw-bold px-4 py-2 shadow-sm" @click="carregarDados" :disabled="loading">
                <i class="bi bi-arrow-clockwise me-2" :class="{ 'spin': loading }"></i>Atualizar
              </button>
            </div>
          </div>
        </div>

        <!-- Alerta informativo institucional -->
        <div class="explanation-banner p-3 mb-4 d-flex align-items-center gap-3">
          <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 flex-shrink-0 d-flex align-items-center justify-content-center" style="width: 42px; height: 42px;">
            <i class="bi bi-shield-check fs-5"></i>
          </div>
          <div class="small">
            <strong class="d-block banner-title mb-1">Módulo de Fechamento Operacional:</strong>
            <span class="banner-text">
              O EasySlotting é uma ferramenta de <strong>cálculo e registro documental</strong> de comissões brutas. O sistema <strong>não realiza pagamentos, transferências bancárias ou PIX</strong>, e não calcula encargos trabalhistas ou tributos.
            </span>
          </div>
        </div>

        <div v-if="erro" class="alert alert-danger rounded-4 mb-4 d-flex align-items-center justify-content-between">
          <div><i class="bi bi-exclamation-triangle-fill me-2"></i>{{ erro }}</div>
          <button class="btn-close" @click="erro = ''"></button>
        </div>

        <div v-if="sucessoMsg" class="alert alert-success rounded-4 mb-4 d-flex align-items-center justify-content-between">
          <div><i class="bi bi-check-circle-fill me-2"></i>{{ sucessoMsg }}</div>
          <button class="btn-close" @click="sucessoMsg = ''"></button>
        </div>

        <!-- Filtros de Período -->
        <div class="admin-card shadow-sm mb-4">
          <div class="row g-3 align-items-end">
            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">Mês de Referência</label>
              <input type="month" class="form-control custom-input fw-bold" v-model="filters.mesReferencia" @change="aplicarMesReferencia" />
            </div>
            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">Período de Início</label>
              <input type="date" class="form-control custom-input fw-bold" v-model="filters.dataDe" />
            </div>
            <div class="col-md-3">
              <label class="form-label small fw-bold text-muted">Período de Fim</label>
              <input type="date" class="form-control custom-input fw-bold" v-model="filters.dataAte" />
            </div>
            <div class="col-md-3">
              <button class="btn btn-primary rounded-pill fw-bold px-4 w-100" @click="carregarDados" :disabled="loading">
                <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>Filtrar
              </button>
            </div>
          </div>
        </div>

        <!-- KPIs Globais Fixos -->
        <div class="row g-3 mb-4">
          <div class="col-md-3">
            <div class="metric-card metric-card-primary h-100">
              <div class="metric-icon"><i class="bi bi-wallet2"></i></div>
              <div>
                <span class="metric-label">Comissão Bruta Total</span>
                <h3 class="metric-value text-primary">R$ {{ fmt(kpis.comissaoTotal) }}</h3>
                <small class="metric-helper">Total apurado no período</small>
              </div>
            </div>
          </div>
          <div class="col-md-3">
            <div class="metric-card metric-card-success h-100">
              <div class="metric-icon"><i class="bi bi-graph-up-arrow"></i></div>
              <div>
                <span class="metric-label">Faturamento da Equipe</span>
                <h3 class="metric-value text-success">R$ {{ fmt(kpis.producaoTotal) }}</h3>
                <small class="metric-helper">Receita gerada pelos profissionais</small>
              </div>
            </div>
          </div>
          <div class="col-md-3">
            <div class="metric-card metric-card-warning h-100">
              <div class="metric-icon"><i class="bi bi-hourglass-split"></i></div>
              <div>
                <span class="metric-label">Aguardando Fechamento</span>
                <h3 class="metric-value text-warning">{{ aguardandoLista.length }}</h3>
                <small class="metric-helper">Profissionais com comissão em aberto</small>
              </div>
            </div>
          </div>
          <div class="col-md-3">
            <div class="metric-card metric-card-info h-100">
              <div class="metric-icon"><i class="bi bi-lock-fill"></i></div>
              <div>
                <span class="metric-label">Fechados no Mês</span>
                <h3 class="metric-value text-info">{{ fechadosLista.length }}</h3>
                <small class="metric-helper">Fechamentos registrados e auditados</small>
              </div>
            </div>
          </div>
        </div>

        <!-- Tabs de Navegação -->
        <ul class="nav nav-pills gap-2 mb-4 flex-wrap" style="position:relative;z-index:10">
          <li v-for="tab in tabs" :key="tab.id">
            <button
              class="nav-link rounded-pill fw-bold px-4 py-2 position-relative"
              :class="{ active: activeTab === tab.id }"
              @click.prevent="activeTab = tab.id"
            >
              <i :class="tab.icon + ' me-2'"></i>{{ tab.label }}
              <span v-if="tab.id === 'aguardando' && aguardandoLista.length > 0" class="badge rounded-pill bg-warning text-dark ms-2">
                {{ aguardandoLista.length }}
              </span>
              <span v-if="tab.id === 'fechados' && fechadosLista.length > 0" class="badge rounded-pill bg-info text-white ms-2">
                {{ fechadosLista.length }}
              </span>
            </button>
          </li>
        </ul>

        <!-- TAB 1: PROFISSIONAIS -->
        <div v-if="activeTab === 'profissionais'">
          <div class="row g-4">
            <div v-for="p in profissionais" :key="p.id" class="col-md-6 col-xl-4">
              <div class="admin-card h-100 d-flex flex-column justify-content-between">
                <div>
                  <div class="d-flex justify-content-between align-items-start mb-3 gap-2">
                    <div class="d-flex align-items-center gap-3">
                      <div class="avatar-circle">{{ p.nome.charAt(0) }}</div>
                      <div>
                        <h5 class="fw-bold mb-0 text-body">{{ p.nome }}</h5>
                        <small class="text-muted">{{ p.especialidade }}</small>
                      </div>
                    </div>
                    <span class="badge rounded-pill px-3 py-1.5 fw-bold border" :class="getVinculoBadgeClass(p.tipo_vinculo)">
                      {{ getTipoVinculoNome(p.tipo_vinculo) }}
                    </span>
                  </div>

                  <!-- Aviso específico para CLT -->
                  <div v-if="p.tipo_vinculo === 'clt'" class="p-2 mb-3 rounded-3 bg-secondary bg-opacity-10 border border-secondary-subtle small text-muted">
                    <i class="bi bi-info-circle me-1 text-primary"></i>
                    <em>Valor bruto — encaminhar ao responsável pela folha de pagamento.</em>
                  </div>

                  <div class="row g-2 mb-3">
                    <div class="col-6">
                      <div class="mini-kpi">
                        <span>Atendimentos</span>
                        <strong class="text-body">{{ p.atendimentos }}</strong>
                      </div>
                    </div>
                    <div class="col-6">
                      <div class="mini-kpi">
                        <span>Faturamento</span>
                        <strong class="text-success">R$ {{ fmt(p.producao) }}</strong>
                      </div>
                    </div>
                  </div>

                  <div class="d-flex justify-content-between mb-2 small">
                    <span class="text-muted">Modelo</span>
                    <strong class="text-body">{{ getModeloNome(p.financial_model) }}</strong>
                  </div>

                  <div class="d-flex justify-content-between mb-3 small">
                    <span class="text-muted">Regra de cálculo</span>
                    <strong class="text-body text-end">{{ getRegraTexto(p) }}</strong>
                  </div>

                  <div class="text-center p-3 rounded-4 mb-3" style="background:rgba(13,110,253,0.05);border:1px solid rgba(13,110,253,0.15)">
                    <span class="small text-muted d-block">Comissão Bruta Calculada</span>
                    <h3 class="fw-900 text-primary mb-0">R$ {{ fmt(p.comissao) }}</h3>
                  </div>
                </div>

                <div>
                  <div class="d-flex align-items-center justify-content-between pt-2 border-top">
                    <span class="small text-muted">Status no período:</span>
                    <span v-if="p.fechamento_status === 'closed'" class="badge bg-success bg-opacity-10 text-success rounded-pill px-3 py-1 fw-bold">
                      <i class="bi bi-lock-fill me-1"></i>Fechado
                    </span>
                    <span v-else-if="p.comissao > 0" class="badge bg-warning bg-opacity-10 text-warning rounded-pill px-3 py-1 fw-bold">
                      <i class="bi bi-hourglass-split me-1"></i>Aguardando Fechamento
                    </span>
                    <span v-else class="badge bg-secondary bg-opacity-10 text-secondary rounded-pill px-3 py-1">
                      Sem movimento
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="!profissionais.length" class="col-12 text-muted small text-center py-5 admin-card">
              Nenhum profissional encontrado para o período selecionado.
            </div>
          </div>
        </div>

        <!-- TAB 2: AGUARDANDO FECHAMENTO -->
        <div v-if="activeTab === 'aguardando'">
          <div class="row g-4">
            <div v-for="p in aguardandoLista" :key="p.id" class="col-md-6 col-xl-4">
              <div class="admin-card h-100 d-flex flex-column justify-content-between border-warning-subtle">
                <div>
                  <div class="d-flex justify-content-between align-items-start mb-3 gap-2">
                    <div class="d-flex align-items-center gap-3">
                      <div class="avatar-circle bg-warning bg-opacity-10 text-warning">{{ p.nome.charAt(0) }}</div>
                      <div>
                        <h5 class="fw-bold mb-0 text-body">{{ p.nome }}</h5>
                        <small class="text-muted">{{ p.especialidade }}</small>
                      </div>
                    </div>
                    <span class="badge rounded-pill px-3 py-1.5 fw-bold border" :class="getVinculoBadgeClass(p.tipo_vinculo)">
                      {{ getTipoVinculoNome(p.tipo_vinculo) }}
                    </span>
                  </div>

                  <div class="row g-2 mb-3">
                    <div class="col-6">
                      <div class="mini-kpi">
                        <span>Atendimentos</span>
                        <strong class="text-body">{{ p.atendimentos }}</strong>
                      </div>
                    </div>
                    <div class="col-6">
                      <div class="mini-kpi">
                        <span>Faturamento</span>
                        <strong class="text-success">R$ {{ fmt(p.producao) }}</strong>
                      </div>
                    </div>
                  </div>

                  <div class="d-flex justify-content-between mb-2 small">
                    <span class="text-muted">Regra Vigente</span>
                    <strong class="text-body text-end">{{ getRegraTexto(p) }}</strong>
                  </div>

                  <div class="text-center p-3 rounded-4 mb-3" style="background:rgba(255,193,7,0.08);border:1px solid rgba(255,193,7,0.25)">
                    <span class="small text-muted d-block">Valor Bruto a Fechar</span>
                    <h3 class="fw-900 text-warning-emphasis mb-0">R$ {{ fmt(p.comissao) }}</h3>
                  </div>
                </div>

                <div class="d-flex gap-2">
                  <button class="btn btn-outline-secondary rounded-pill fw-bold py-2 w-50" @click="abrirModalDetalhes(p)">
                    <i class="bi bi-list-check me-1"></i>Detalhes
                  </button>
                  <button class="btn btn-primary rounded-pill fw-bold py-2 w-50 shadow-sm" @click="abrirModalFechar(p)">
                    <i class="bi bi-lock me-1"></i>Fechar
                  </button>
                </div>
              </div>
            </div>

            <div v-if="!aguardandoLista.length" class="col-12 text-center py-5 admin-card">
              <div class="bg-success bg-opacity-10 rounded-circle d-inline-flex p-4 mb-3 text-success">
                <i class="bi bi-check2-all fs-1"></i>
              </div>
              <h5 class="fw-bold text-body">Nenhuma comissão aguardando fechamento</h5>
              <p class="text-muted mb-0">Todas as comissões apuradas deste período já foram fechadas ou não há atendimentos pendentes.</p>
            </div>
          </div>
        </div>

        <!-- TAB 3: FECHADOS -->
        <div v-if="activeTab === 'fechados'">
          <div class="admin-card mb-4">
            <div class="d-flex justify-content-between align-items-center mb-3">
              <h5 class="fw-bold mb-0 text-body">
                <i class="bi bi-lock-fill me-2 text-info"></i>Fechamentos Concluídos
              </h5>
              <span class="badge bg-info bg-opacity-10 text-info rounded-pill px-3 py-1.5 fw-bold">
                {{ fechadosLista.length }} Registros
              </span>
            </div>

            <div v-if="!fechadosLista.length" class="text-muted small text-center py-5">
              Nenhum fechamento registrado para este mês de referência.
            </div>

            <div v-else class="table-responsive">
              <table class="table table-clean align-middle mb-0">
                <thead>
                  <tr>
                    <th>Profissional</th>
                    <th>Vínculo</th>
                    <th>Período</th>
                    <th>Serviços</th>
                    <th>Faturamento</th>
                    <th>Comissão Bruta</th>
                    <th>Fechado em</th>
                    <th>Responsável</th>
                    <th class="text-end">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="c in fechadosLista" :key="c.id">
                    <td>
                      <strong class="text-body">{{ c.employee_name }}</strong>
                    </td>
                    <td>
                      <span class="badge rounded-pill px-2.5 py-1 small border" :class="getVinculoBadgeClass(c.tipo_vinculo)">
                        {{ getTipoVinculoNome(c.tipo_vinculo) }}
                      </span>
                    </td>
                    <td class="small text-muted">{{ c.period_start }} até {{ c.period_end }}</td>
                    <td class="fw-bold">{{ c.services_count }}</td>
                    <td class="text-success fw-bold">R$ {{ fmt(c.gross_revenue) }}</td>
                    <td class="text-primary fw-bold fs-6">R$ {{ fmt(c.gross_commission_amount) }}</td>
                    <td class="small">{{ c.closed_at }}</td>
                    <td class="small text-muted">{{ c.closed_by_name || '-' }}</td>
                    <td class="text-end">
                      <button class="btn btn-sm btn-outline-primary rounded-pill fw-bold px-3" @click="verFechamentoDetalhe(c.id)">
                        <i class="bi bi-eye me-1"></i>Ver
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Footer com Disclaimer LGPD & Tributário -->
        <div class="mt-4 pt-3 border-top" style="border-color: var(--card-border) !important">
          <p class="small text-muted mb-0" style="opacity: 0.75">
            <i class="bi bi-info-circle me-1"></i>
            <strong>Aviso Legal:</strong> Os valores apresentados correspondem aos valores brutos calculados pelo sistema com base nos serviços registrados e nas regras de comissão configuradas. O EasySlotting não realiza pagamentos nem determina tributos, retenções ou encargos trabalhistas/fiscais aplicáveis.
          </p>
        </div>

      </div>
    </section>

    <!-- MODAL 1: DETALHES DE ATENDIMENTOS (PREVIEW) -->
    <div class="modal fade" id="modalDetalhesPreview" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow-lg rounded-4">
          <div class="modal-header border-bottom-0 pb-0">
            <div>
              <h5 class="modal-title fw-bold text-body">
                <i class="bi bi-list-check text-primary me-2"></i>Serviços Prestados no Período
              </h5>
              <p class="small text-muted mb-0" v-if="previewProfissional">
                Profissional: <strong>{{ previewProfissional.employee_name }}</strong> &bull; Vínculo: <strong>{{ getTipoVinculoNome(previewProfissional.tipo_vinculo) }}</strong>
              </p>
            </div>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal"></button>
          </div>

          <div class="modal-body pt-3">
            <div v-if="carregandoPreview" class="text-center py-4">
              <div class="spinner-border text-primary" role="status"></div>
              <div class="small text-muted mt-2">Carregando serviços...</div>
            </div>

            <div v-else-if="previewProfissional">
              <div class="row g-2 mb-3">
                <div class="col-4">
                  <div class="mini-kpi">
                    <span>Qtd Serviços</span>
                    <strong class="text-body">{{ previewProfissional.services_count }}</strong>
                  </div>
                </div>
                <div class="col-4">
                  <div class="mini-kpi">
                    <span>Faturamento Total</span>
                    <strong class="text-success">R$ {{ fmt(previewProfissional.gross_revenue) }}</strong>
                  </div>
                </div>
                <div class="col-4">
                  <div class="mini-kpi">
                    <span>Comissão Bruta</span>
                    <strong class="text-primary">R$ {{ fmt(previewProfissional.gross_commission) }}</strong>
                  </div>
                </div>
              </div>

              <div class="table-responsive" style="max-height: 380px; overflow-y: auto;">
                <table class="table table-sm align-middle table-hover">
                  <thead>
                    <tr class="small text-muted">
                      <th>Data/Hora</th>
                      <th>Serviço</th>
                      <th>Cliente</th>
                      <th class="text-end">Valor Serviço</th>
                      <th class="text-end">Comissão</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="item in previewProfissional.items" :key="item.id">
                      <td class="small">{{ item.date }} {{ item.time }}</td>
                      <td class="fw-bold small">{{ item.service_name }}</td>
                      <td class="small text-muted">{{ item.customer_name }}</td>
                      <td class="text-end small">R$ {{ fmt(item.service_amount) }}</td>
                      <td class="text-end fw-bold text-primary small">R$ {{ fmt(item.commission_amount) }}</td>
                    </tr>
                    <tr v-if="!previewProfissional.items.length">
                      <td colspan="5" class="text-center text-muted small py-3">Nenhum serviço registrado neste período.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="modal-footer border-top-0 pt-0">
            <button type="button" class="btn btn-light rounded-pill px-4 fw-bold border" data-bs-dismiss="modal">Fechar</button>
            <button
              v-if="previewProfissional && previewProfissional.items.length > 0"
              type="button"
              class="btn btn-primary rounded-pill px-4 fw-bold shadow-sm"
              @click="converterPreviewParaFechar"
            >
              <i class="bi bi-lock me-1"></i>Prosseguir para Fechamento
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL 2: CONFIRMAÇÃO DE FECHAMENTO -->
    <div class="modal fade" id="modalConfirmarFechamento" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg rounded-4">
          <div class="modal-header border-bottom-0 pb-0">
            <h5 class="modal-title fw-bold text-body">
              <i class="bi bi-lock-fill text-primary me-2"></i>Confirmar Fechamento de Comissão
            </h5>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" :disabled="salvandoFechamento"></button>
          </div>

          <div class="modal-body pt-3" v-if="fechandoProfissional">
            <div class="p-3 rounded-4 bg-body-tertiary mb-3 border">
              <div class="d-flex justify-content-between mb-1">
                <span class="text-muted small">Profissional:</span>
                <strong class="text-body">{{ fechandoProfissional.nome }}</strong>
              </div>
              <div class="d-flex justify-content-between mb-1">
                <span class="text-muted small">Vínculo:</span>
                <span class="badge rounded-pill px-2 py-0.5 border" :class="getVinculoBadgeClass(fechandoProfissional.tipo_vinculo)">
                  {{ getTipoVinculoNome(fechandoProfissional.tipo_vinculo) }}
                </span>
              </div>
              <div class="d-flex justify-content-between mb-1">
                <span class="text-muted small">Mês de Referência:</span>
                <strong>{{ filters.mesReferencia }}</strong>
              </div>
              <div class="d-flex justify-content-between mb-1">
                <span class="text-muted small">Qtd de Atendimentos:</span>
                <strong>{{ fechandoProfissional.atendimentos }}</strong>
              </div>
              <div class="d-flex justify-content-between mb-1">
                <span class="text-muted small">Faturamento da Produção:</span>
                <strong class="text-success">R$ {{ fmt(fechandoProfissional.producao) }}</strong>
              </div>
              <div class="d-flex justify-content-between pt-2 mt-2 border-top">
                <span class="fw-bold">Comissão Bruta Calculada:</span>
                <strong class="text-primary fs-5">R$ {{ fmt(fechandoProfissional.comissao) }}</strong>
              </div>
            </div>

            <!-- Disclaimer de responsabilidade institucional -->
            <div class="p-3 rounded-3 bg-warning bg-opacity-10 border border-warning-subtle small mb-3">
              <i class="bi bi-exclamation-triangle-fill text-warning me-1"></i>
              <strong>Atenção:</strong> Este fechamento registra documentalmente o valor bruto calculado com base nos atendimentos e regras de comissão do período. O EasySlotting <strong>não realiza o pagamento</strong> nem calcula encargos, impostos ou deduções trabalhistas.
            </div>

            <div class="mb-2">
              <label class="form-label small fw-bold text-muted">Observações do Fechamento (opcional)</label>
              <textarea
                class="form-control custom-input"
                rows="2"
                placeholder="Ex: Acerto conferido com o profissional."
                v-model="observacoesFechamento"
                maxlength="500"
              ></textarea>
            </div>
          </div>

          <div class="modal-footer border-top-0 pt-0">
            <button type="button" class="btn btn-light rounded-pill px-4 fw-bold border" data-bs-dismiss="modal" :disabled="salvandoFechamento">Cancelar</button>
            <button type="button" class="btn btn-primary rounded-pill px-4 fw-bold shadow-sm" @click="confirmarFechamento" :disabled="salvandoFechamento">
              <span v-if="salvandoFechamento" class="spinner-border spinner-border-sm me-2"></span>
              {{ salvandoFechamento ? 'Registrando...' : 'Confirmar Fechamento' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL 3: AUDITORIA E DETALHES DE FECHAMENTO CONCLUÍDO -->
    <div class="modal fade" id="modalFechamentoAuditoria" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow-lg rounded-4">
          <div class="modal-header border-bottom-0 pb-0">
            <div>
              <h5 class="modal-title fw-bold text-body">
                <i class="bi bi-shield-check text-success me-2"></i>Fechamento Registrado #{{ detalheClosing?.id }}
              </h5>
              <p class="small text-muted mb-0" v-if="detalheClosing">
                Profissional: <strong>{{ detalheClosing.employee_name }}</strong> &bull; Mês: <strong>{{ detalheClosing.reference_month }}</strong>
              </p>
            </div>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal"></button>
          </div>

          <div class="modal-body pt-3" v-if="detalheClosing">
            <div class="row g-2 mb-3">
              <div class="col-md-3">
                <div class="mini-kpi">
                  <span>Comissão Bruta</span>
                  <strong class="text-primary fs-6">R$ {{ fmt(detalheClosing.gross_commission_amount) }}</strong>
                </div>
              </div>
              <div class="col-md-3">
                <div class="mini-kpi">
                  <span>Faturamento</span>
                  <strong class="text-success fs-6">R$ {{ fmt(detalheClosing.gross_revenue) }}</strong>
                </div>
              </div>
              <div class="col-md-3">
                <div class="mini-kpi">
                  <span>Serviços</span>
                  <strong class="text-body fs-6">{{ detalheClosing.services_count }}</strong>
                </div>
              </div>
              <div class="col-md-3">
                <div class="mini-kpi">
                  <span>Status</span>
                  <span class="badge bg-success bg-opacity-10 text-success rounded-pill fw-bold">
                    <i class="bi bi-lock-fill me-1"></i>Fechado
                  </span>
                </div>
              </div>
            </div>

            <!-- Abas do Modal de Detalhe -->
            <ul class="nav nav-tabs border-bottom mb-3">
              <li class="nav-item">
                <button
                  class="nav-link fw-bold"
                  :class="{ active: modalTab === 'servicos' }"
                  @click="modalTab = 'servicos'"
                >
                  Serviços ({{ detalheClosing.items?.length || 0 }})
                </button>
              </li>
              <li class="nav-item">
                <button
                  class="nav-link fw-bold"
                  :class="{ active: modalTab === 'auditoria' }"
                  @click="modalTab = 'auditoria'"
                >
                  Histórico & Auditoria
                </button>
              </li>
            </ul>

            <!-- Subaba Serviços -->
            <div v-if="modalTab === 'servicos'" class="table-responsive" style="max-height: 280px; overflow-y: auto;">
              <table class="table table-sm align-middle table-hover">
                <thead>
                  <tr class="small text-muted">
                    <th>Data/Hora</th>
                    <th>Serviço</th>
                    <th>Regra Aplicada</th>
                    <th class="text-end">Valor Base</th>
                    <th class="text-end">Comissão</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in detalheClosing.items" :key="item.id">
                    <td class="small">{{ item.date }} {{ item.time }}</td>
                    <td class="fw-bold small">{{ item.service_name }}</td>
                    <td class="small text-muted">{{ item.commission_rule_applied }}</td>
                    <td class="text-end small">R$ {{ fmt(item.service_amount) }}</td>
                    <td class="text-end fw-bold text-primary small">R$ {{ fmt(item.commission_amount) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Subaba Auditoria -->
            <div v-if="modalTab === 'auditoria'">
              <div class="timeline p-2" style="max-height: 280px; overflow-y: auto;">
                <div v-for="h in detalheClosing.histories" :key="h.id" class="p-2 mb-2 rounded-3 bg-body-tertiary border small">
                  <div class="d-flex justify-content-between">
                    <strong class="text-body"><i class="bi bi-clock-history me-1 text-primary"></i>{{ h.user_name }}</strong>
                    <span class="text-muted">{{ h.created_at }}</span>
                  </div>
                  <div class="mt-1">{{ h.description }}</div>
                </div>
              </div>
            </div>

            <!-- Reabertura com Motivo Obrigatório -->
            <div v-if="modoReabertura" class="mt-3 p-3 rounded-3 bg-danger bg-opacity-10 border border-danger-subtle">
              <label class="form-label small fw-bold text-danger">Motivo da Reabertura / Correção (Obrigatório)</label>
              <textarea
                class="form-control custom-input mb-2"
                rows="2"
                placeholder="Informe detalhadamente por que este fechamento precisa ser reaberto..."
                v-model="motivoReabertura"
              ></textarea>
              <div class="d-flex gap-2 justify-content-end">
                <button class="btn btn-sm btn-light border rounded-pill px-3" @click="modoReabertura = false" :disabled="reabrindoFechamento">Cancelar</button>
                <button class="btn btn-sm btn-danger rounded-pill px-3 fw-bold shadow-sm" @click="confirmarReabertura" :disabled="reabrindoFechamento || motivoReabertura.trim().length < 5">
                  <span v-if="reabrindoFechamento" class="spinner-border spinner-border-sm me-1"></span>
                  Confirmar Reabertura
                </button>
              </div>
            </div>
          </div>

          <div class="modal-footer border-top-0 pt-0 d-flex justify-content-between">
            <div>
              <button
                v-if="!modoReabertura && detalheClosing?.status === 'closed'"
                class="btn btn-outline-danger rounded-pill px-3 fw-bold"
                @click="modoReabertura = true"
              >
                <i class="bi bi-unlock me-1"></i>Reabrir Fechamento
              </button>
            </div>

            <button type="button" class="btn btn-light rounded-pill px-4 fw-bold border" data-bs-dismiss="modal">Fechar</button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import { api } from '@/services/api'
import { Modal } from 'bootstrap'

const loading = ref(false)
const erro = ref('')
const sucessoMsg = ref('')

const filters = ref({
  mesReferencia: toInputMonth(new Date()),
  dataDe: '',
  dataAte: ''
})

const tabs = [
  { id: 'profissionais', label: 'Profissionais', icon: 'bi bi-people' },
  { id: 'aguardando', label: 'Aguardando Fechamento', icon: 'bi bi-hourglass-split' },
  { id: 'fechados', label: 'Fechados', icon: 'bi bi-lock' }
]
const activeTab = ref('profissionais')

const resumo = ref({
  comissao_total: 0,
  producao_total: 0,
  atendimentos_total: 0,
  profissionais_sem_regra: 0
})

const profissionais = ref<any[]>([])
const aguardandoLista = ref<any[]>([])
const fechadosLista = ref<any[]>([])

// Modais
let modalPreviewInstance: Modal | null = null
let modalConfirmarInstance: Modal | null = null
let modalAuditoriaInstance: Modal | null = null

const previewProfissional = ref<any | null>(null)
const carregandoPreview = ref(false)

const fechandoProfissional = ref<any | null>(null)
const observacoesFechamento = ref('')
const salvandoFechamento = ref(false)

const detalheClosing = ref<any | null>(null)
const modalTab = ref<'servicos' | 'auditoria'>('servicos')
const modoReabertura = ref(false)
const motivoReabertura = ref('')
const reabrindoFechamento = ref(false)

function toInputMonth(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

function aplicarMesReferencia() {
  if (!filters.value.mesReferencia) return
  const parts = filters.value.mesReferencia.split('-').map(Number)
  const ano = parts[0] ?? new Date().getFullYear()
  const mes = parts[1] ?? (new Date().getMonth() + 1)
  const inicio = new Date(ano, mes - 1, 1)
  const fim = new Date(ano, mes, 0)
  filters.value.dataDe = toInputDate(inicio)
  filters.value.dataAte = toInputDate(fim)
}

function toInputDate(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

function fmt(v: number): string {
  return Number(v || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function getTipoVinculoNome(tipo?: string): string {
  const map: Record<string, string> = {
    clt: 'CLT',
    mei: 'MEI',
    pj: 'PJ',
    autonomo: 'Autônomo',
    parceiro: 'Parceiro'
  }
  return map[tipo || ''] || 'Autônomo'
}

function getVinculoBadgeClass(tipo?: string): string {
  switch (tipo) {
    case 'clt': return 'bg-primary bg-opacity-10 text-primary border-primary-subtle'
    case 'mei': return 'bg-success bg-opacity-10 text-success border-success-subtle'
    case 'pj': return 'bg-info bg-opacity-10 text-info border-info-subtle'
    case 'parceiro': return 'bg-purple bg-opacity-10 text-purple border-purple-subtle'
    default: return 'bg-secondary bg-opacity-10 text-secondary border-secondary-subtle'
  }
}

function getModeloNome(model?: string): string {
  const map: Record<string, string> = {
    porcentagem: 'Porcentagem (%)',
    fixo_servico: 'Fixo por serviço',
    diaria: 'Diária / Aluguel'
  }
  return map[model || ''] || 'Não definido'
}

function getRegraTexto(p: any): string {
  const bonus = Number(p.commission_bonus_percentage || 0)
  if (p.financial_model === 'porcentagem') {
    return `${p.financial_value}% sobre faturamento`
  }
  if (p.financial_model === 'fixo_servico') {
    let t = `R$ ${fmt(p.financial_value)} por atendimento`
    if (bonus > 0) t += ` + ${bonus}% bônus`
    return t
  }
  if (p.financial_model === 'diaria') {
    let t = `R$ ${fmt(p.financial_value)} diária`
    if (bonus > 0) t += ` + ${bonus}% bônus`
    return t
  }
  return 'Sem regra configurada'
}

async function carregarDados() {
  // C-2: validação de intervalo de datas antes de enviar ao servidor
  if (filters.value.dataDe && filters.value.dataAte && filters.value.dataDe > filters.value.dataAte) {
    erro.value = 'A data de início não pode ser posterior à data de fim.'
    return
  }

  loading.value = true
  erro.value = ''
  sucessoMsg.value = ''
  try {
    const params: Record<string, string> = {}
    if (filters.value.mesReferencia) params.reference_month = filters.value.mesReferencia
    if (filters.value.dataDe) params.date_from = filters.value.dataDe
    if (filters.value.dataAte) params.date_to = filters.value.dataAte

    const { data } = await api.get('/financial/commissions', { params })

    resumo.value = {
      comissao_total: Number(data?.summary?.comissao_total || 0),
      producao_total: Number(data?.summary?.producao_total || 0),
      atendimentos_total: Number(data?.summary?.atendimentos_total || 0),
      profissionais_sem_regra: Number(data?.summary?.profissionais_sem_regra || 0)
    }

    profissionais.value = Array.isArray(data?.professionals) ? data.professionals : []
    aguardandoLista.value = Array.isArray(data?.aguardando_fechamento) ? data.aguardando_fechamento : []
    fechadosLista.value = Array.isArray(data?.closed_closings) ? data.closed_closings : []
  } catch (e: any) {
    erro.value = e?.response?.data?.error || 'Erro ao carregar dados de comissões.'
  } finally {
    loading.value = false
  }
}

async function abrirModalDetalhes(p: any) {
  try {
    carregandoPreview.value = true
    modalPreviewInstance?.show()
    const { data } = await api.get('/financial/commission_closings/preview', {
      params: {
        employee_id: p.id,
        date_from: filters.value.dataDe,
        date_to: filters.value.dataAte
      }
    })
    previewProfissional.value = data
  } catch (e: any) {
    erro.value = e?.response?.data?.error || 'Erro ao carregar detalhes dos atendimentos.'
    modalPreviewInstance?.hide()
  } finally {
    carregandoPreview.value = false
  }
}

function converterPreviewParaFechar() {
  modalPreviewInstance?.hide()
  if (previewProfissional.value) {
    const original = profissionais.value.find(p => String(p.id) === String(previewProfissional.value.employee_id))
    if (original) {
      abrirModalFechar(original)
    }
  }
}

function abrirModalFechar(p: any) {
  fechandoProfissional.value = p
  observacoesFechamento.value = ''
  modalConfirmarInstance?.show()
}

async function confirmarFechamento() {
  if (!fechandoProfissional.value) return
  salvandoFechamento.value = true
  erro.value = ''
  try {
    const payload = {
      closing: {
        employee_id: fechandoProfissional.value.id,
        reference_month: filters.value.mesReferencia,
        period_start: filters.value.dataDe,
        period_end: filters.value.dataAte,
        notes: observacoesFechamento.value
      }
    }

    const { data } = await api.post('/financial/commission_closings', payload)
    sucessoMsg.value = data.message || 'Fechamento de comissão concluído com sucesso!'
    modalConfirmarInstance?.hide()
    await carregarDados()
  } catch (e: any) {
    // C-1: usa ref controlado em vez de alert() nativo
    erro.value = e?.response?.data?.error || 'Erro ao registrar fechamento de comissão.'
  } finally {
    salvandoFechamento.value = false
  }
}

async function verFechamentoDetalhe(closingId: number) {
  try {
    modoReabertura.value = false
    motivoReabertura.value = ''
    modalTab.value = 'servicos'

    const { data } = await api.get(`/financial/commission_closings/${closingId}`)
    detalheClosing.value = data
    modalAuditoriaInstance?.show()
  } catch (e: any) {
    // C-1: usa ref controlado em vez de alert() nativo
    erro.value = e?.response?.data?.error || 'Erro ao carregar detalhes do fechamento.'
  }
}

async function confirmarReabertura() {
  if (!detalheClosing.value || motivoReabertura.value.trim().length < 5) return
  reabrindoFechamento.value = true
  try {
    const { data } = await api.post(`/financial/commission_closings/${detalheClosing.value.id}/reopen`, {
      reason: motivoReabertura.value
    })
    sucessoMsg.value = data.message || 'Fechamento reaberto com sucesso.'
    modalAuditoriaInstance?.hide()
    await carregarDados()
  } catch (e: any) {
    // C-1: usa ref controlado em vez de alert() nativo
    erro.value = e?.response?.data?.error || 'Erro ao reabrir fechamento.'
  } finally {
    reabrindoFechamento.value = false
  }
}

function exportarCSV() {
  if (!fechadosLista.value.length && !profissionais.value.length) {
    alert('Nenhum dado para exportar no período.')
    return
  }

  const linhas: string[] = []
  linhas.push('Profissional;Vinculo;Modelo;Regra;Atendimentos;Faturamento;Comissao Bruta;Status;Periodo')

  profissionais.value.forEach(p => {
    linhas.push([
      `"${p.nome}"`,
      `"${getTipoVinculoNome(p.tipo_vinculo)}"`,
      `"${getModeloNome(p.financial_model)}"`,
      `"${getRegraTexto(p)}"`,
      p.atendimentos,
      p.producao.toFixed(2).replace('.', ','),
      p.comissao.toFixed(2).replace('.', ','),
      `"${p.fechamento_status === 'closed' ? 'Fechado' : 'Aguardando'}"`,
      `"${filters.value.mesReferencia}"`
    ].join(';'))
  })

  const blob = new Blob(['\uFEFF' + linhas.join('\n')], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.setAttribute('download', `fechamento_comissoes_${filters.value.mesReferencia}.csv`)
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

function imprimirRelatorio() {
  window.print()
}

const kpis = computed(() => ({
  comissaoTotal: resumo.value.comissao_total,
  producaoTotal: resumo.value.producao_total,
  atendimentosTotal: resumo.value.atendimentos_total
}))

onMounted(() => {
  aplicarMesReferencia()
  carregarDados()

  const modalPreviewEl = document.getElementById('modalDetalhesPreview')
  if (modalPreviewEl) modalPreviewInstance = new Modal(modalPreviewEl)

  const modalConfirmarEl = document.getElementById('modalConfirmarFechamento')
  if (modalConfirmarEl) modalConfirmarInstance = new Modal(modalConfirmarEl)

  const modalAuditoriaEl = document.getElementById('modalFechamentoAuditoria')
  if (modalAuditoriaEl) modalAuditoriaInstance = new Modal(modalAuditoriaEl)
})
</script>

<style scoped>
.page-shell { width: 100%; min-width: 100%; max-width: 100%; display: block; }
.page-content { width: 100%; min-width: 100%; max-width: 100% !important; display: block; }
.dashboard-header { background: rgba(var(--bs-body-bg-rgb), 0.4) !important; border: 1px solid var(--card-border) !important; backdrop-filter: blur(12px) !important; border-radius: 20px !important; position: relative; }
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
.metric-card-info { border-left: 4px solid var(--bs-info); }
.metric-icon { width: 52px; height: 52px; border-radius: 16px; display: flex; align-items: center; justify-content: center; background: rgba(13, 110, 253, 0.1); color: var(--bs-primary); font-size: 1.25rem; flex-shrink: 0; }
.metric-label { display: block; font-size: 0.8rem; color: var(--bs-secondary-color); font-weight: 700; margin-bottom: 4px; }
.metric-value { font-weight: 900; margin-bottom: 4px; }
.metric-helper { color: var(--bs-secondary-color); }
.avatar-circle { width: 44px; height: 44px; border-radius: 50%; background: rgba(13, 110, 253, 0.12); color: var(--bs-primary); display: flex; align-items: center; justify-content: center; font-weight: 900; flex-shrink: 0; }
.mini-kpi { background: rgba(var(--bs-body-color-rgb), 0.025); border: 1px solid var(--card-border); border-radius: 12px; padding: 8px 10px; display: flex; flex-direction: column; }
.mini-kpi span { font-size: 0.75rem; color: var(--bs-secondary-color); font-weight: 600; }
.mini-kpi strong { font-size: 1rem; }
.table-clean th { font-size: 0.75rem; font-weight: 700; text-transform: uppercase; color: var(--bs-secondary-color); border-bottom: 1px solid var(--card-border); padding: 12px 16px; }
.table-clean td { padding: 12px 16px; border-bottom: 1px solid rgba(var(--bs-body-color-rgb), 0.05); }
.nav-pills .nav-link { color: var(--bs-secondary-color); border: 1px solid transparent; transition: all 0.2s; position: relative; z-index: 2; }
.nav-pills .nav-link.active { background: var(--bs-primary); color: #fff; box-shadow: 0 4px 12px rgba(13, 110, 253, 0.3); }
.nav-pills .nav-link:not(.active):hover { background: rgba(var(--bs-body-color-rgb), 0.06); border-color: var(--card-border); }

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

.spin {
  animation: spin 1s linear infinite;
}
@keyframes spin { 100% { transform: rotate(360deg); } }

@media print {
  .dashboard-header button,
  .nav-pills,
  .admin-card:has(input),
  .btn,
  .modal {
    display: none !important;
  }
}
</style>
