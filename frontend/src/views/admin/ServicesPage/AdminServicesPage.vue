<template>
  <AdminLayout>
    <section class="page-shell">
      <div class="page-content">
        <!-- Header com visual premium -->
        <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
          <div class="header-overlay"></div>
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1">
            <div class="d-flex align-items-center gap-3">
              <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                <i class="bi bi-scissors fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Serviços & Pacotes</h1>
                <p class="text-muted mb-0 small-text-responsive">Cadastre os serviços avulsos e os planos de assinatura da sua unidade.</p>
              </div>
            </div>
          </div>
        </div>

        <!-- SERVIÇOS -->
        <div class="admin-card shadow-sm mb-4 p-4">
          <div class="section-header mb-4 border-bottom pb-3">
            <div>
              <div class="d-flex align-items-center gap-3 mb-1">
                <h5 class="fw-bold mb-0 text-body">Serviços Avulsos</h5>
                <span class="badge bg-primary rounded-pill px-4 py-2 fs-6 shadow-sm fw-bold">
                  {{ servicosVisiveis.length }} Ativos
                </span>
              </div>
              <p class="small text-muted mb-0 ps-1">
                Cadastre e edite os serviços que podem ser agendados individualmente pelos clientes.
              </p>
            </div>
            <button
              class="btn btn-outline-primary rounded-pill fw-bold px-4 py-2 transition-all shadow-sm hover-lift"
              @click="abrirFormularioServico"
              :disabled="loading"
            >
              <i class="bi bi-plus-lg me-2"></i>Novo Serviço
            </button>
          </div>

          <div v-if="servicosVisiveis.length > 0" class="table-responsive hide-scrollbar table-glass-card shadow-sm">
            <table class="table align-middle mb-0 custom-table">
              <thead>
                <tr class="small text-muted tracking-wide text-uppercase fw-bold">
                  <th class="ps-3 border-0">Serviço</th>
                  <th v-if="mostrarColunaProfissional" class="border-0">Profissionais</th>
                  <th class="border-0 text-center">Duração</th>
                  <th class="border-0 text-center">Preço</th>
                  <th class="text-end pe-3 border-0">Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(servico, index) in servicosVisiveis"
                  :key="index"
                  class="servico-row transition-all"
                >
                  <td class="ps-3 pe-3 cell-servico-principal">
                    <div class="servico-card-info">
                      <span class="servico-nome-inline">
                        {{ servico.nome }}
                      </span>
                      <div class="servico-meta-stack">
                        <div class="servico-meta-row">
                          <span class="servico-meta-label">Tipo</span>
                          <span class="servico-meta-value servico-tipo-badge">
                            {{ servico.tipo || 'Sem tipo' }}
                          </span>
                        </div>
                        <div v-if="servico.descricao" class="servico-meta-row">
                          <span class="servico-meta-label">Descrição</span>
                          <span class="servico-meta-value servico-descricao-text">
                            {{ servico.descricao }}
                          </span>
                        </div>
                      </div>
                    </div>
                  </td>

                  <td
                    v-if="mostrarColunaProfissional"
                    class="align-middle"
                    style="width: 260px;"
                  >
                    <div class="servico-info-text">
                      {{ getNomesColaboradores(servico.colabIds) || 'Não definido' }}
                    </div>
                  </td>

                  <td class="text-center align-middle" style="width: 140px;">
                    <div class="servico-info-text fw-semibold">
                      {{ exibirDuracao(servico.duracao) }}
                    </div>
                  </td>

                  <td class="text-center align-middle" style="width: 150px;">
                    <div class="servico-preco">
                      R$ {{ servico.preco }}
                    </div>
                  </td>

                  <td class="text-end text-nowrap pe-3 align-middle" style="width: 120px;">
                    <button
                      class="btn btn-light rounded-circle me-2 btn-action shadow-sm"
                      @click="editarServico(index)"
                      :disabled="loading"
                    >
                      <i class="bi bi-pencil"></i>
                    </button>

                    <button
                      class="btn btn-light rounded-circle text-danger btn-action btn-delete shadow-sm"
                      @click="removerServico(index)"
                      :disabled="loading"
                    >
                      <i class="bi bi-trash"></i>
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div v-else class="text-center py-5 text-muted bg-body-tertiary rounded-4 border border-dashed my-2 transition-all px-3">
            <h5 class="fw-bold text-body mb-3">Nenhum serviço cadastrado</h5>

            <p class="mb-2 fw-bold text-muted">
              Para começar, clique em <span class="text-primary">"Novo Serviço"</span>.
            </p>

            <ul class="text-muted small text-start d-inline-block mt-2 mb-0" style="max-width: 420px;">
              <li>Informe o <strong>nome do serviço</strong> que sua empresa oferece</li>
              <li>Digite o <strong>tipo do serviço</strong>, como por exemplo Corte, Barba, Estética</li>
              <li>Adicione uma <strong>descrição curta</strong> para deixar o serviço mais claro</li>
              <li>Defina a <strong>duração em horas e minutos</strong>, por exemplo <strong>01:30</strong></li>
              <li>Informe o <strong>preço</strong> que será cobrado do cliente</li>
              <li v-if="podeEscolherProfissional">
                Selecione <strong>um ou mais profissionais</strong> que podem executar o serviço
              </li>
            </ul>
          </div>
        </div>

        <!-- PACOTES -->
        <div class="admin-card shadow-sm mb-4 p-4">
          <div class="section-header mb-4 border-bottom pb-3">
            <div>
              <div class="d-flex align-items-center gap-3 mb-1">
                <h5 class="fw-bold mb-0 text-body">Pacotes Mensais</h5>
                <span class="badge bg-primary rounded-pill px-4 py-2 fs-6 shadow-sm fw-bold">
                  {{ pacotesVisiveis.length }} Ativos
                </span>
              </div>
              <p class="small text-muted mb-0 ps-1">
                Planos de assinatura mensal com quantidade de sessões inclusas para fidelizar clientes.
              </p>
            </div>
            <button
              class="btn btn-outline-primary rounded-pill fw-bold px-4 py-2 transition-all shadow-sm hover-lift"
              @click="abrirFormularioPacote"
              :disabled="loading"
            >
              <i class="bi bi-plus-lg me-2"></i>Novo Pacote
            </button>
          </div>

          <div v-if="pacotesVisiveis.length > 0" class="table-responsive hide-scrollbar table-glass-card shadow-sm">
            <table class="table align-middle mb-0 custom-table">
              <thead>
                <tr class="small text-muted tracking-wide text-uppercase fw-bold">
                  <th class="ps-3 border-0">Pacote</th>
                  <th v-if="mostrarColunaProfissional" class="border-0">Profissional</th>
                  <th class="border-0 text-center">Duração</th>
                  <th class="border-0 text-center">Mensalidade</th>
                  <th class="text-end pe-3 border-0">Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(pacote, index) in pacotesVisiveis" :key="index" class="servico-row transition-all">
                  <td class="ps-3 pe-3 cell-servico-principal">
                    <div class="servico-card-info">
                      <span class="servico-nome-inline">
                        {{ pacote.nome }}
                      </span>
                      <div class="servico-meta-stack">
                        <div class="servico-meta-row">
                          <span class="servico-meta-label">Itens</span>
                          <span class="servico-meta-value">
                            {{ pacote.itens || 'Não informado' }}
                          </span>
                        </div>
                        <div v-if="pacote.descricao" class="servico-meta-row">
                          <span class="servico-meta-label">Descrição</span>
                          <span class="servico-meta-value servico-descricao-text">
                            {{ pacote.descricao }}
                          </span>
                        </div>
                      </div>
                    </div>
                  </td>

                  <td v-if="mostrarColunaProfissional" class="align-middle" style="width: 220px;">
                    <div class="servico-info-text">
                      {{ getNomesColaboradores(pacote.colabIds) || 'Não definido' }}
                    </div>
                  </td>

                  <td class="text-center align-middle" style="width: 140px;">
                    <div class="servico-info-text fw-semibold">
                      {{ exibirDuracao(pacote.duracao) }}
                    </div>
                  </td>

                  <td class="text-center align-middle" style="width: 160px;">
                    <div class="servico-preco">
                      R$ {{ pacote.preco }}<span class="ms-1 small text-muted fw-bold">/mês</span>
                    </div>
                  </td>

                  <td class="text-end text-nowrap pe-3 align-middle" style="width: 120px;">
                    <button class="btn btn-light rounded-circle me-2 btn-action shadow-sm" @click="editarPacote(index)" :disabled="loading">
                      <i class="bi bi-pencil"></i>
                    </button>
                    <button class="btn btn-light rounded-circle text-danger btn-action btn-delete shadow-sm" @click="removerPacote(index)" :disabled="loading">
                      <i class="bi bi-trash"></i>
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div v-else class="text-center py-5 text-muted bg-body-tertiary rounded-4 border border-dashed my-2 transition-all px-3">
            <h5 class="fw-bold text-body mb-3">Nenhum pacote cadastrado</h5>

            <p class="mb-2 fw-bold text-muted">
              Crie pacotes mensais para fidelizar seus clientes e organizar ofertas recorrentes.
            </p>

            <ul class="text-muted small text-start d-inline-block mt-2 mb-0" style="max-width: 420px;">
              <li>Defina um <strong>nome para o pacote</strong></li>
              <li>Adicione uma <strong>descrição curta</strong> para explicar a proposta</li>
              <li>Descreva os <strong>itens inclusos</strong> para o cliente entender o benefício</li>
              <li>Informe a <strong>duração em horas e minutos</strong>, por exemplo <strong>01:00</strong></li>
              <li>Defina o <strong>valor mensal</strong> que será cobrado</li>
            </ul>
          </div>
        </div>

        <div class="d-flex justify-content-end align-items-center mt-4 mb-5 border-top pt-4">
          <button
            type="button"
            class="btn btn-primary btn-lg rounded-pill px-5 py-3 fw-bold shadow transition-all hover-lift"
            @click="salvarServicos"
            :disabled="loading"
          >
            <i class="bi bi-check2-circle me-2"></i>
            {{ loading ? 'Atualizando...' : 'Atualizar Listas' }}
          </button>
        </div>
      </div>
    </section>

    <!-- MODAL SERVIÇO -->
    <div
      class="modal fade"
      id="modalServico"
      tabindex="-1"
      aria-labelledby="modalServicoLabel"
      aria-hidden="true"
      ref="modalServicoRef"
    >
      <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content modal-custom">
          <div class="modal-header border-0 pb-0">
            <div>
              <h5 class="modal-title fw-bold" id="modalServicoLabel">
                {{ editandoServicoIndex !== null ? 'Editar Serviço' : 'Novo Serviço' }}
              </h5>
              <p class="text-muted small mb-0">
                Preencha as informações do serviço.
              </p>
            </div>

            <button
              type="button"
              class="btn-close"
              @click="fecharModalServicoComSeguranca"
              aria-label="Close"
            ></button>
          </div>

          <div class="modal-body pt-3">
            <div class="row g-3">
              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Nome do serviço</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': errosServico.nome }"
                  placeholder="Ex: Corte De Cabelo"
                  :value="novoServico.nome"
                  @input="aoDigitarServico('nome', formatarTexto(($event.target as HTMLInputElement).value))"
                  ref="inputNovoServico"
                  maxlength="100"
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  O nome comercial do serviço exibido no catálogo de agendamento (Ex: Corte Degradê).
                </div>
                <div v-if="errosServico.nome" class="invalid-feedback d-block">
                  {{ errosServico.nome }}
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Tipo do serviço</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': errosServico.tipo }"
                  placeholder="Ex: Cabelo"
                  :value="novoServico.tipo"
                  @input="aoDigitarServico('tipo', formatarTexto(($event.target as HTMLInputElement).value))"
                  maxlength="50"
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  A categoria/grupo do serviço para organização do catálogo (Ex: Cabelo, Barba, Estética).
                </div>
                <div v-if="errosServico.tipo" class="invalid-feedback d-block">
                  {{ errosServico.tipo }}
                </div>
              </div>

              <div class="col-12" v-if="podeEscolherProfissional">
                <label class="form-label fw-bold small text-muted">Profissionais</label>

                <div class="profissionais-selector" :class="{ 'is-invalid': errosServico.colabIds }">
                  <div class="profissionais-actions mb-2 d-flex align-items-center gap-2">
                    <button
                      type="button"
                      class="btn btn-sm btn-link text-decoration-none p-0 fw-bold"
                      @click="toggleTodosColaboradoresServico"
                    >
                      {{ novoServico.colabIds.length === colaboradores.length ? 'Desmarcar todos' : 'Marcar todos' }}
                    </button>
                    <span class="small text-muted">
                      {{ novoServico.colabIds.length }}/{{ colaboradores.length }} selecionados
                    </span>
                  </div>

                  <div class="profissionais-list">
                    <label
                      v-for="c in colaboradoresFiltrados"
                      :key="c.id"
                      class="profissional-item d-flex align-items-center gap-2"
                      :class="{ selected: novoServico.colabIds.includes(c.id) }"
                    >
                      <input
                        class="form-check-input"
                        type="checkbox"
                        :checked="novoServico.colabIds.includes(c.id)"
                        @change="toggleColaboradorServico(c.id)"
                      >
                      <span class="form-check-label">{{ c.nome }}</span>
                    </label>

                    <div v-if="colaboradoresFiltrados.length === 0" class="text-center py-3 text-muted small">
                      Nenhum profissional encontrado.
                    </div>
                  </div>
                </div>

                <div class="form-text small text-muted mt-1 ps-1">
                  Selecione quais profissionais podem realizar este serviço.
                </div>
                <div v-if="errosServico.colabIds" class="invalid-feedback d-block">
                  {{ errosServico.colabIds }}
                </div>
              </div>

              <div class="col-12">
                <label class="form-label fw-bold small text-muted">Descrição</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :value="novoServico.descricao"
                  placeholder="Ex: Corte na máquina e tesoura"
                  @input="aoDigitarServico('descricao', formatarTextoLivre(($event.target as HTMLInputElement).value))"
                  maxlength="500"
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  Resumo das etapas ou diferenciais inclusos neste atendimento.
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Duração</label>
                <div class="input-group has-validation">
                  <input
                    type="text"
                    class="form-control custom-input"
                    :class="{ 'is-invalid': errosServico.duracao }"
                    placeholder="01:30"
                    maxlength="5"
                    :value="novoServico.duracao"
                    @input="aoDigitarDuracaoServico($event)"
                    @blur="aoSairDuracaoServico($event)"
                  >
                  <span class="input-group-text custom-addon">hh:mm</span>
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  Tempo estimado para realização do serviço no formato hh:mm (Ex: 00:45 para 45min).
                </div>
                <div v-if="errosServico.duracao" class="invalid-feedback d-block">
                  {{ errosServico.duracao }}
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Preço</label>
                <div class="input-group has-validation">
                  <span class="input-group-text custom-addon">R$</span>
                  <input
                    type="text"
                    class="form-control custom-input"
                    :class="{ 'is-invalid': errosServico.preco }"
                    placeholder="60,00"
                    :value="novoServico.preco"
                    @input="aoDigitarPrecoServico($event)"
                    @blur="aoSairPrecoServico($event)"
                    maxlength="10"
                  >
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  O valor cobrado do cliente diretamente pelo serviço avulso.
                </div>
                <div v-if="errosServico.preco" class="invalid-feedback d-block">
                  {{ errosServico.preco }}
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer border-0 pt-0 flex-wrap">
            <button
              type="button"
              class="btn btn-light rounded-pill px-4 fw-bold border"
              @click="fecharModalServicoComSeguranca"
              :disabled="loading"
            >
              Cancelar
            </button>

            <button
              type="button"
              class="btn btn-primary rounded-pill px-4 fw-bold shadow-sm"
              @click="salvarNovoServico"
              :disabled="loading"
            >
              {{ editandoServicoIndex !== null ? 'Salvar Alterações' : 'Adicionar Serviço' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL PACOTE -->
    <div
      class="modal fade"
      id="modalPacote"
      tabindex="-1"
      aria-labelledby="modalPacoteLabel"
      aria-hidden="true"
      ref="modalPacoteRef"
    >
      <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content modal-custom">
          <div class="modal-header border-0 pb-0">
            <div>
              <h5 class="modal-title fw-bold" id="modalPacoteLabel">
                {{ editandoPacoteIndex !== null ? 'Editar Pacote' : 'Novo Pacote' }}
              </h5>
              <p class="text-muted small mb-0">
                Preencha as informações do pacote.
              </p>
            </div>

            <button
              type="button"
              class="btn-close"
              @click="fecharModalPacoteComSeguranca"
              aria-label="Close"
            ></button>
          </div>

          <div class="modal-body pt-3">
            <div class="row g-3">
              <div class="col-md-4">
                <label class="form-label fw-bold small text-muted">Nome do pacote</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': errosPacote.nome }"
                  placeholder="Ex: Plano Vip"
                  :value="novoPacote.nome"
                  @input="aoDigitarPacote('nome', formatarTexto(($event.target as HTMLInputElement).value))"
                  ref="inputNovoPacote"
                  maxlength="100"
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  Nome comercial do plano de assinatura ou combo de fidelidade (Ex: Clube VIP Mensal).
                </div>
                <div v-if="errosPacote.nome" class="invalid-feedback d-block">
                  {{ errosPacote.nome }}
                </div>
              </div>

              <div class="col-md-4">
                <label class="form-label fw-bold small text-muted">Descrição</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :value="novoPacote.descricao"
                  placeholder="Ex: Pacote mensal para clientes recorrentes"
                  @input="aoDigitarPacote('descricao', formatarTextoLivre(($event.target as HTMLInputElement).value))"
                  maxlength="500"
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  Informação resumida sobre o plano de fidelidade oferecido.
                </div>
              </div>

              <div class="col-md-4">
                <label class="form-label fw-bold small text-muted">Serviço Vinculado</label>
                <select
                  class="form-select custom-input"
                  :class="{ 'is-invalid': errosPacote.serviceId }"
                  v-model="novoPacote.serviceId"
                  @change="limparErroPacote('serviceId')"
                >
                  <option :value="null">Selecione o serviço...</option>
                  <option v-for="(s, index) in servicos" :key="s.id ?? index" :value="s.id">{{ s.nome }}</option>
                </select>
                <div class="form-text small text-muted mt-1 ps-1">
                  O serviço avulso do qual o pacote consumirá sessões no agendamento.
                </div>
                <div v-if="errosPacote.serviceId" class="invalid-feedback d-block">
                  {{ errosPacote.serviceId }}
                </div>
              </div>

              <div class="col-md-4">
                <label class="form-label fw-bold small text-muted">Quantidade de Sessões</label>
                <input
                  type="number"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': errosPacote.sessionsTotal }"
                  v-model.number="novoPacote.sessionsTotal"
                  min="1"
                  max="100"
                  @input="limparErroPacote('sessionsTotal')"
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  O total de créditos/sessões mensais que o cliente terá direito neste pacote.
                </div>
                <div v-if="errosPacote.sessionsTotal" class="invalid-feedback d-block">
                  {{ errosPacote.sessionsTotal }}
                </div>
              </div>

              <div v-if="podeEscolherProfissional" class="col-12">
                <label class="form-label fw-bold small text-muted">Profissionais</label>

                <div class="profissionais-selector" :class="{ 'is-invalid': errosPacote.colabIds }">
                  <div class="profissionais-actions mb-2 d-flex align-items-center gap-2">
                    <button
                      type="button"
                      class="btn btn-sm btn-link text-decoration-none p-0 fw-bold"
                      @click="toggleTodosColaboradoresPacote"
                    >
                      {{ novoPacote.colabIds.length === colaboradores.length ? 'Desmarcar todos' : 'Marcar todos' }}
                    </button>
                    <span class="small text-muted">
                      {{ novoPacote.colabIds.length }}/{{ colaboradores.length }} selecionados
                    </span>
                  </div>

                  <div class="profissionais-list">
                    <label
                      v-for="c in colaboradoresFiltrados"
                      :key="c.id"
                      class="profissional-item d-flex align-items-center gap-2"
                      :class="{ selected: novoPacote.colabIds.includes(c.id) }"
                    >
                      <input
                        class="form-check-input"
                        type="checkbox"
                        :checked="novoPacote.colabIds.includes(c.id)"
                        @change="toggleColaboradorPacote(c.id)"
                      >
                      <span class="form-check-label">{{ c.nome }}</span>
                    </label>

                    <div v-if="colaboradoresFiltrados.length === 0" class="text-center py-3 text-muted small">
                      Nenhum profissional encontrado.
                    </div>
                  </div>
                </div>

                <div class="form-text small text-muted mt-1 ps-1">
                  Selecione quais profissionais podem realizar este pacote.
                </div>
                <div v-if="errosPacote.colabIds" class="invalid-feedback d-block">
                  {{ errosPacote.colabIds }}
                </div>
              </div>

              <div class="col-md-5">
                <label class="form-label fw-bold small text-muted">Itens inclusos</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': errosPacote.itens }"
                  placeholder="Ex: 4 Cortes + 2 Barbas"
                  :value="novoPacote.itens"
                  @input="aoDigitarPacote('itens', formatarTextoLivre(($event.target as HTMLInputElement).value))"
                  maxlength="1000"
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  Detalhamento do que o cliente recebe (Ex: 4 Cortes + Cafés inclusos).
                </div>
                <div v-if="errosPacote.itens" class="invalid-feedback d-block">
                  {{ errosPacote.itens }}
                </div>
              </div>

              <div class="col-md-3">
                <label class="form-label fw-bold small text-muted">Duração</label>
                <div class="input-group has-validation">
                  <input
                    type="text"
                    class="form-control custom-input"
                    :class="{ 'is-invalid': errosPacote.duracao }"
                    placeholder="01:00"
                    maxlength="5"
                    :value="novoPacote.duracao"
                    @input="aoDigitarDuracaoPacote($event)"
                    @blur="aoSairDuracaoPacote($event)"
                  >
                  <span class="input-group-text custom-addon">hh:mm</span>
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  Tempo padrão reservado na agenda para cada atendimento deste pacote (hh:mm).
                </div>
                <div v-if="errosPacote.duracao" class="invalid-feedback d-block">
                  {{ errosPacote.duracao }}
                </div>
              </div>

              <div class="col-md-4">
                <label class="form-label fw-bold small text-muted">Mensalidade</label>
                <div class="input-group has-validation">
                  <span class="input-group-text custom-addon">R$</span>
                  <input
                    type="text"
                    class="form-control custom-input"
                    :class="{ 'is-invalid': errosPacote.preco }"
                    placeholder="250,00"
                    :value="novoPacote.preco"
                    @input="aoDigitarPrecoPacote($event)"
                    @blur="aoSairPrecoPacote($event)"
                    maxlength="10"
                  >
                  <span class="input-group-text custom-addon">/mês</span>
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  O valor recorrente que será cobrado mensalmente do assinante.
                </div>
                <div v-if="errosPacote.preco" class="invalid-feedback d-block">
                  {{ errosPacote.preco }}
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer border-0 pt-0 flex-wrap">
            <button
              type="button"
              class="btn btn-light rounded-pill px-4 fw-bold border"
              @click="fecharModalPacoteComSeguranca"
              :disabled="loading"
            >
              Cancelar
            </button>

            <button
              type="button"
              class="btn btn-primary rounded-pill px-4 fw-bold shadow-sm"
              @click="salvarNovoPacote"
              :disabled="loading"
            >
              {{ editandoPacoteIndex !== null ? 'Salvar Alterações' : 'Adicionar Pacote' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import { api } from '@/services/api'
import { computed, nextTick, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Modal } from 'bootstrap'
import {
  sanitizeText,
  sanitizeFreeText,
  validateServiceDTO,
  validateServicePackageDTO
} from '@/utils/security'

type TipoUsuario = 'boss' | 'funcionario'
type ModoServico = 'global' | 'funcionario'

interface Colaborador {
  id: number
  nome: string
}

interface Servico {
  id: number | null
  nome: string
  descricao: string
  tipo: string
  duracao: string
  preco: string
  colabIds: number[]
}

interface Pacote {
  id: number | null
  nome: string
  descricao: string
  itens: string
  duracao: string
  preco: string
  colabIds: number[]
  serviceId: number | null
  sessionsTotal: number | null
}

interface UsuarioLogado {
  tipo: TipoUsuario
  colabId: number | null
}

interface ErrosServico {
  nome?: string
  descricao?: string
  tipo?: string
  duracao?: string
  preco?: string
  colabIds?: string
}

interface ErrosPacote {
  nome?: string
  descricao?: string
  itens?: string
  duracao?: string
  preco?: string
  colabIds?: string
  serviceId?: string
  sessionsTotal?: string
}

interface AppConfig {
  modoServico?: ModoServico
}

interface ServiceApiResponse {
  id: number
  name: string
  description?: string
  service_type: string
  duration_minutes: number
  price: string | number
  employees?: Array<{ id: number; name: string }>
}

interface ServicePackageApiResponse {
  id: number
  name: string
  description?: string
  included_items?: string
  duration_minutes: number
  price: string | number
  user_id?: number | null
  user?: { id: number; name: string } | null
  service_id?: number | null
  sessions_total?: number | null
  employees?: Array<{ id: number; name: string }>
}

const loading = ref<boolean>(false)
const modoServico = ref<ModoServico>('global')
const nomeModeloOperacao = ref<string>('Equipe de Profissionais')

const colaboradores = ref<Colaborador[]>([])
const servicos = ref<Servico[]>([])
const pacotes = ref<Pacote[]>([])

const editandoServicoIndex = ref<number | null>(null)
const editandoPacoteIndex = ref<number | null>(null)

const inputNovoServico = ref<HTMLInputElement | null>(null)
const inputNovoPacote = ref<HTMLInputElement | null>(null)

const errosServico = ref<ErrosServico>({})
const errosPacote = ref<ErrosPacote>({})

const modalServicoRef = ref<HTMLElement | null>(null)
const modalPacoteRef = ref<HTMLElement | null>(null)

const buscaProfissional = ref('')

let modalServicoInstance: Modal | null = null
let modalPacoteInstance: Modal | null = null

let ultimoElementoFocadoAntesModalServico: HTMLElement | null = null
let ultimoElementoFocadoAntesModalPacote: HTMLElement | null = null

const router = useRouter()

const usuarioLogado = ref<UsuarioLogado>({
  tipo: 'boss',
  colabId: null
})

function sincronizarUsuarioLogado(): void {
  const userRaw = localStorage.getItem('user') || sessionStorage.getItem('user')
  if (userRaw) {
    try {
      const user = JSON.parse(userRaw)
      const role = user.role || localStorage.getItem('role') || sessionStorage.getItem('role')
      const isBoss = role === 'owner' || role === 'super_admin'
      usuarioLogado.value = {
        tipo: isBoss ? 'boss' : 'funcionario',
        colabId: user.id ? Number(user.id) : null
      }
    } catch (e) {
      console.error('Erro ao ler dados do usuário:', e)
    }
  }
}

const novoServicoPadrao = (): Servico => ({
  id: null,
  nome: '',
  descricao: '',
  tipo: '',
  duracao: '',
  preco: '',
  colabIds: []
})

const novoPacotePadrao = (): Pacote => ({
  id: null,
  nome: '',
  descricao: '',
  itens: '',
  duracao: '',
  preco: '',
  colabIds: [],
  serviceId: null,
  sessionsTotal: 4
})

const novoServico = ref<Servico>(novoServicoPadrao())
const novoPacote = ref<Pacote>(novoPacotePadrao())

onMounted(async () => {
  sincronizarUsuarioLogado()

  // 🔒 SEGURANÇA: Bloqueia acesso de funcionário caso não tenha permissão de gerenciar serviços
  const permsRaw = localStorage.getItem('establishment-permissions') || sessionStorage.getItem('establishment-permissions')
  if (usuarioLogado.value.tipo === 'funcionario' && permsRaw) {
    try {
      const perms = JSON.parse(permsRaw)
      if (perms.can_manage_services === false) {
        router.replace('/admin/agendamentos')
        return
      }
    } catch (e) {
      console.warn('Erro ao processar permissões:', e)
    }
  }

  const configSalva = JSON.parse(localStorage.getItem('app_config') || '{}') as AppConfig
  modoServico.value = configSalva.modoServico || 'global'

  if (modalServicoRef.value) {
    modalServicoInstance = new Modal(modalServicoRef.value)

    modalServicoRef.value.addEventListener('hidden.bs.modal', () => {
      editandoServicoIndex.value = null
      errosServico.value = {}
      novoServico.value = novoServicoPadrao()
      buscaProfissional.value = ''

      if (ultimoElementoFocadoAntesModalServico) {
        ultimoElementoFocadoAntesModalServico.focus()
        ultimoElementoFocadoAntesModalServico = null
      }
    })
  }

  if (modalPacoteRef.value) {
    modalPacoteInstance = new Modal(modalPacoteRef.value)

    modalPacoteRef.value.addEventListener('hidden.bs.modal', () => {
      editandoPacoteIndex.value = null
      errosPacote.value = {}
      novoPacote.value = novoPacotePadrao()

      if (ultimoElementoFocadoAntesModalPacote) {
        ultimoElementoFocadoAntesModalPacote.focus()
        ultimoElementoFocadoAntesModalPacote = null
      }
    })
  }

  await Promise.all([
    carregarServicos(),
    carregarPacotes(),
    carregarColaboradores()
  ])
})

const mostrarColunaProfissional = computed<boolean>(() => {
  return usuarioLogado.value.tipo === 'boss'
})

const podeEscolherProfissional = computed<boolean>(() => {
  return usuarioLogado.value.tipo === 'boss'
})

const servicosVisiveis = computed<Servico[]>(() => {
  if (usuarioLogado.value.tipo === 'boss') return servicos.value
  if (modoServico.value === 'global') return servicos.value

  return servicos.value.filter(servico =>
    usuarioLogado.value.colabId ? servico.colabIds.includes(Number(usuarioLogado.value.colabId)) : true
  )
})

const pacotesVisiveis = computed<Pacote[]>(() => {
  if (usuarioLogado.value.tipo === 'boss') return pacotes.value
  if (modoServico.value === 'global') return pacotes.value
  return pacotes.value.filter(pacote =>
    usuarioLogado.value.colabId ? pacote.colabIds.includes(Number(usuarioLogado.value.colabId)) : true
  )
})

const colaboradoresFiltrados = computed<Colaborador[]>(() => {
  if (!buscaProfissional.value) return colaboradores.value
  const termo = buscaProfissional.value.toLowerCase()
  return colaboradores.value.filter(c => c.nome.toLowerCase().includes(termo))
})

function formatarTexto(valor: string): string {
  return valor
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .replace(/^\s/, '')
    .replace(/\b\w/g, letra => letra.toUpperCase())
}

function formatarTextoLivre(valor: string): string {
  return valor
    .replace(/\s+/g, ' ')
    .replace(/^\s/, '')
    .replace(/\b[a-zà-ú]/g, letra => letra.toUpperCase())
}

function formatarMoeda(valor: string): string {
  const apenasNumeros = valor.replace(/\D/g, '').slice(0, 9)
  if (!apenasNumeros) return ''

  const temVirgula = valor.includes(',')
  if (temVirgula) {
    const partes = valor.split(',')
    const inteira = (partes[0] || '').replace(/\D/g, '').replace(/^0+/, '') || '0'
    const decimal = (partes[1] || '').replace(/\D/g, '').slice(0, 2).padEnd(2, '0')
    return `${inteira},${decimal}`
  }

  return apenasNumeros
}

function formatarMoedaDigitando(valor: string): string {
  const apenasNumeros = valor.replace(/\D/g, '').slice(0, 11)
  if (!apenasNumeros) return ''

  const inteira = apenasNumeros.slice(0, -2) || '0'
  const decimal = apenasNumeros.slice(-2).padEnd(2, '0')
  return `${inteira.replace(/^0+/, '') || '0'},${decimal}`
}

function formatarMoedaBlur(valor: string): string {
  const apenasNumeros = valor.replace(/\D/g, '')
  if (!apenasNumeros) return ''

  const numeroFormatado = (parseInt(apenasNumeros, 10) / 100).toFixed(2)
  return numeroFormatado.replace('.', ',')
}

function formatarMoedaBackend(valor: string | number): string {
  const numero = Number(valor || 0)
  return numero.toFixed(2).replace('.', ',')
}

function formatarDuracao(valor: string): string {
  const numeros = valor.replace(/\D/g, '').slice(0, 4)
  if (!numeros) return ''

  if (numeros.length <= 2) {
    const horas = parseInt(numeros, 10)
    if (horas > 23) return '23'
    if (numeros.length === 2) return `${numeros}:`
    return numeros
  }

  const horas = numeros.slice(0, 2)
  const horasNum = parseInt(horas, 10)
  const minutos = numeros.slice(2, 4)

  if (horasNum > 23) {
    const min = parseInt(minutos, 10)
    return min > 59 ? '23:59' : `23:${minutos}`
  }

  const minutosNum = parseInt(minutos, 10)
  if (minutosNum > 59) return `${horas}:59`

  return `${horas}:${minutos}`
}

function formatarDuracaoBlur(valor: string): string {
  const numeros = valor.replace(/\D/g, '').slice(0, 4)
  if (!numeros) return ''

  if (numeros.length <= 2) {
    const horas = parseInt(numeros, 10)
    if (horas > 23) return '23:00'
    return `${numeros.padStart(2, '0')}:00`
  }

  const horas = numeros.slice(0, 2).padStart(2, '0')
  const horasNum = parseInt(horas, 10)
  const minutos = numeros.slice(2, 4)

  if (horasNum > 23) {
    const min = parseInt(minutos, 10)
    return min > 59 ? '23:59' : `23:${minutos}${minutos.length === 1 ? '0' : ''}`
  }

  const minutosNum = parseInt(minutos, 10)
  if (minutosNum > 59) return `${horas}:59`

  return minutos.length === 1 ? `${horas}:${minutos}0` : `${horas}:${minutos}`
}

function duracaoValida(valor: string): boolean {
  return /^([0-1]\d|2[0-3]):([0-5]\d)$/.test(valor)
}

function exibirDuracao(valor: string): string {
  if (!duracaoValida(valor)) return valor || '-'
  const [horas = '00', minutos = '00'] = valor.split(':')
  return `${horas}h ${minutos}min`
}

function converterDuracaoParaMinutos(valor: string): number {
  if (!duracaoValida(valor)) return 0

  const partes = valor.split(':')
  const horas = Number(partes[0] ?? 0)
  const minutos = Number(partes[1] ?? 0)

  return (horas * 60) + minutos
}

function converterMinutosParaDuracao(minutosTotais: number): string {
  const total = Number(minutosTotais || 0)
  const horas = Math.floor(total / 60)
  const minutos = total % 60

  return `${String(horas).padStart(2, '0')}:${String(minutos).padStart(2, '0')}`
}

function getNomeColaborador(colabId: number | null): string {
  const colaborador = colaboradores.value.find(c => c.id === colabId)
  return colaborador?.nome || ''
}

function getNomesColaboradores(colabIds: number[]): string {
  return colaboradores.value
    .filter(c => colabIds.includes(c.id))
    .map(c => c.nome)
    .join(', ')
}

function limparErroServico(campo: keyof ErrosServico): void {
  if (errosServico.value[campo]) {
    delete errosServico.value[campo]
    errosServico.value = { ...errosServico.value }
  }
}

function limparErroPacote(campo: keyof ErrosPacote): void {
  if (errosPacote.value[campo]) {
    delete errosPacote.value[campo]
    errosPacote.value = { ...errosPacote.value }
  }
}

function aoDigitarServico(campo: keyof Servico, valor: string | number | number[] | null): void {
  ;(novoServico.value[campo] as string | number | number[] | null) = valor
  if (campo in errosServico.value) limparErroServico(campo as keyof ErrosServico)
}

function aoDigitarPacote(campo: keyof Pacote, valor: string | number | null): void {
  ;(novoPacote.value[campo] as string | number | null) = valor
  if (campo in errosPacote.value) limparErroPacote(campo as keyof ErrosPacote)
}

function aoDigitarDuracaoServico(event: Event): void {
  const input = event.target as HTMLInputElement
  const posCursor = input.selectionStart ?? input.value.length
  const formatoAntigo = input.value
  const formatado = formatarDuracao(input.value)
  aoDigitarServico('duracao', formatado)
  nextTick(() => {
    const diff = formatado.length - formatoAntigo.length
    const novaPos = Math.min(posCursor + diff, formatado.length)
    input.setSelectionRange(novaPos, novaPos)
  })
}

function aoDigitarDuracaoPacote(event: Event): void {
  const input = event.target as HTMLInputElement
  const posCursor = input.selectionStart ?? input.value.length
  const formatoAntigo = input.value
  const formatado = formatarDuracao(input.value)
  aoDigitarPacote('duracao', formatado)
  nextTick(() => {
    const diff = formatado.length - formatoAntigo.length
    const novaPos = Math.min(posCursor + diff, formatado.length)
    input.setSelectionRange(novaPos, novaPos)
  })
}

function aoDigitarPrecoServico(event: Event): void {
  const input = event.target as HTMLInputElement
  const posCursor = input.selectionStart ?? input.value.length
  const formatoAntigo = input.value
  const formatado = formatarMoedaDigitando(input.value)
  aoDigitarServico('preco', formatado)
  nextTick(() => {
    const diff = formatado.length - formatoAntigo.length
    const novaPos = Math.min(posCursor + diff, formatado.length)
    input.setSelectionRange(novaPos, novaPos)
  })
}

function aoDigitarPrecoPacote(event: Event): void {
  const input = event.target as HTMLInputElement
  const posCursor = input.selectionStart ?? input.value.length
  const formatoAntigo = input.value
  const formatado = formatarMoedaDigitando(input.value)
  aoDigitarPacote('preco', formatado)
  nextTick(() => {
    const diff = formatado.length - formatoAntigo.length
    const novaPos = Math.min(posCursor + diff, formatado.length)
    input.setSelectionRange(novaPos, novaPos)
  })
}

function aoSairPrecoServico(event: Event): void {
  const input = event.target as HTMLInputElement
  const formatado = formatarMoedaBlur(input.value)
  aoDigitarServico('preco', formatado)
}

function aoSairPrecoPacote(event: Event): void {
  const input = event.target as HTMLInputElement
  const formatado = formatarMoedaBlur(input.value)
  aoDigitarPacote('preco', formatado)
}

function aoSairDuracaoServico(event: Event): void {
  const input = event.target as HTMLInputElement
  const formatado = formatarDuracaoBlur(input.value)
  aoDigitarServico('duracao', formatado)
}

function aoSairDuracaoPacote(event: Event): void {
  const input = event.target as HTMLInputElement
  const formatado = formatarDuracaoBlur(input.value)
  aoDigitarPacote('duracao', formatado)
}

function atualizarColaboradoresServico(event: Event): void {
  const target = event.target as HTMLSelectElement
  const selecionados = Array.from(target.selectedOptions).map(option => Number(option.value))
  novoServico.value.colabIds = selecionados
  limparErroServico('colabIds')
}

function toggleColaboradorServico(id: number): void {
  const index = novoServico.value.colabIds.indexOf(id)
  if (index === -1) {
    novoServico.value.colabIds.push(id)
  } else {
    novoServico.value.colabIds.splice(index, 1)
  }
  limparErroServico('colabIds')
}

function toggleTodosColaboradoresServico(): void {
  if (novoServico.value.colabIds.length === colaboradores.value.length) {
    novoServico.value.colabIds = []
  } else {
    novoServico.value.colabIds = colaboradores.value.map(c => c.id)
  }
  limparErroServico('colabIds')
}

function toggleColaboradorPacote(id: number): void {
  const index = novoPacote.value.colabIds.indexOf(id)
  if (index === -1) {
    novoPacote.value.colabIds.push(id)
  } else {
    novoPacote.value.colabIds.splice(index, 1)
  }
  limparErroPacote('colabIds')
}

function toggleTodosColaboradoresPacote(): void {
  if (novoPacote.value.colabIds.length === colaboradores.value.length) {
    novoPacote.value.colabIds = []
  } else {
    novoPacote.value.colabIds = colaboradores.value.map(c => c.id)
  }
  limparErroPacote('colabIds')
}

function validarServico(): boolean {
  errosServico.value = {}

  // Sanitiza as strings de entrada contra XSS antes de validar/enviar
  novoServico.value.nome = sanitizeText(novoServico.value.nome)
  novoServico.value.tipo = sanitizeText(novoServico.value.tipo)
  novoServico.value.descricao = sanitizeFreeText(novoServico.value.descricao)

  const dto = {
    name: novoServico.value.nome,
    service_type: novoServico.value.tipo,
    description: novoServico.value.descricao,
    duration_minutes: converterDuracaoParaMinutos(novoServico.value.duracao),
    price: Number((novoServico.value.preco || '').toString().replace(/\./g, '').replace(',', '.')) || 0,
    employee_ids: novoServico.value.colabIds
  }

  const result = validateServiceDTO(dto)
  if (!result.isValid) {
    errosServico.value = result.errors
  }

  return Object.keys(errosServico.value).length === 0
}

function validarPacote(): boolean {
  errosPacote.value = {}

  // Sanitiza as strings de entrada contra XSS antes de validar/enviar
  novoPacote.value.nome = sanitizeText(novoPacote.value.nome)
  novoPacote.value.descricao = sanitizeFreeText(novoPacote.value.descricao)
  novoPacote.value.itens = sanitizeFreeText(novoPacote.value.itens)

  const dto = {
    name: novoPacote.value.nome,
    description: novoPacote.value.descricao,
    included_items: novoPacote.value.itens,
    duration_minutes: converterDuracaoParaMinutos(novoPacote.value.duracao),
    price: Number((novoPacote.value.preco || '').toString().replace(/\./g, '').replace(',', '.')) || 0,
    service_id: Number(novoPacote.value.serviceId) || 0,
    sessions_total: Number(novoPacote.value.sessionsTotal) || 0
  }

  const result = validateServicePackageDTO(dto)
  if (!result.isValid) {
    errosPacote.value = result.errors
  }

  if (
    usuarioLogado.value.tipo === 'boss' &&
    novoPacote.value.colabIds.length === 0
  ) {
    errosPacote.value.colabIds = 'Selecione pelo menos um profissional'
  }

  return Object.keys(errosPacote.value).length === 0
}

function fecharModalServicoComSeguranca(): void {
  ;(document.activeElement as HTMLElement | null)?.blur()

  setTimeout(() => {
    modalServicoInstance?.hide()
  }, 0)
}

function fecharModalPacoteComSeguranca(): void {
  ;(document.activeElement as HTMLElement | null)?.blur()

  setTimeout(() => {
    modalPacoteInstance?.hide()
  }, 0)
}

function mapearServiceDaApi(service: ServiceApiResponse): Servico {
  return {
    id: service.id,
    nome: service.name || '',
    descricao: service.description || '',
    tipo: service.service_type || '',
    duracao: converterMinutosParaDuracao(service.duration_minutes),
    preco: formatarMoedaBackend(service.price),
    colabIds: service.employees?.map(employee => employee.id) || []
  }
}

function mapearPacoteDaApi(servicePackage: ServicePackageApiResponse): Pacote {
  return {
    id: servicePackage.id,
    nome: servicePackage.name || '',
    descricao: servicePackage.description || '',
    itens: servicePackage.included_items || '',
    duracao: converterMinutosParaDuracao(servicePackage.duration_minutes),
    preco: formatarMoedaBackend(servicePackage.price),
    colabIds: servicePackage.employees?.map(e => e.id) || (servicePackage.user_id ? [servicePackage.user_id] : []),
    serviceId: servicePackage.service_id ?? null,
    sessionsTotal: servicePackage.sessions_total ?? 4
  }
}

async function carregarServicos(): Promise<void> {
  try {
    const response = await api.get('/services')
    servicos.value = (response.data || []).map((service: ServiceApiResponse) => mapearServiceDaApi(service))
  } catch (error) {
    console.error('Erro ao carregar serviços:', error)
  }
}

async function carregarPacotes(): Promise<void> {
  try {
    const response = await api.get('/service_packages')
    pacotes.value = (response.data || []).map((pkg: ServicePackageApiResponse) => mapearPacoteDaApi(pkg))
  } catch (error) {
    console.error('Erro ao carregar pacotes:', error)
  }
}

async function carregarColaboradores(): Promise<void> {
  try {
    const response = await api.get('/admin/team')
    const data = Array.isArray(response.data) ? response.data : []
    colaboradores.value = data
      .filter((m: any) => m.active && m.role === 'employee')
      .map((m: any) => ({
        id: m.user_id ?? m.id,
        nome: m.name || ''
      }))
  } catch (error) {
    console.error('Erro ao carregar colaboradores:', error)
    colaboradores.value = []
  }
}

async function abrirFormularioServico(): Promise<void> {
  ultimoElementoFocadoAntesModalServico = document.activeElement as HTMLElement | null

  editandoServicoIndex.value = null
  errosServico.value = {}
  novoServico.value = novoServicoPadrao()
  buscaProfissional.value = ''

  if (modoServico.value === 'funcionario' && usuarioLogado.value.tipo === 'funcionario' && usuarioLogado.value.colabId) {
    novoServico.value.colabIds = [usuarioLogado.value.colabId]
  }

  modalServicoInstance?.show()

  await nextTick()
  inputNovoServico.value?.focus()
}

async function abrirFormularioPacote(): Promise<void> {
  ultimoElementoFocadoAntesModalPacote = document.activeElement as HTMLElement | null

  editandoPacoteIndex.value = null
  errosPacote.value = {}
  novoPacote.value = novoPacotePadrao()

  if (modoServico.value === 'funcionario' && usuarioLogado.value.tipo === 'funcionario' && usuarioLogado.value.colabId) {
    novoPacote.value.colabIds = [usuarioLogado.value.colabId]
  }

  modalPacoteInstance?.show()

  await nextTick()
  inputNovoPacote.value?.focus()
}

function editarServico(index: number): void {
  ultimoElementoFocadoAntesModalServico = document.activeElement as HTMLElement | null

  const servicoSelecionado = servicosVisiveis.value[index]
  if (!servicoSelecionado) return

  const indiceReal = servicos.value.findIndex(item => item.id === servicoSelecionado.id)
  if (indiceReal === -1) return

  const original = servicos.value[indiceReal]
  if (!original) return

  editandoPacoteIndex.value = null
  errosPacote.value = {}
  novoPacote.value = novoPacotePadrao()

  editandoServicoIndex.value = indiceReal
  errosServico.value = {}
  buscaProfissional.value = ''
  novoServico.value = {
    id: original.id ?? null,
    nome: original.nome || '',
    descricao: original.descricao || '',
    tipo: original.tipo || '',
    duracao: original.duracao || '',
    preco: original.preco || '',
    colabIds: original.colabIds ? [...original.colabIds] : []
  }

  modalServicoInstance?.show()

  nextTick(() => {
    inputNovoServico.value?.focus()
  })
}

function editarPacote(index: number): void {
  ultimoElementoFocadoAntesModalPacote = document.activeElement as HTMLElement | null

  const pacoteSelecionado = pacotesVisiveis.value[index]
  if (!pacoteSelecionado) return

  const indiceReal = pacotes.value.findIndex(item => item.id === pacoteSelecionado.id)
  if (indiceReal === -1) return

  const original = pacotes.value[indiceReal]
  if (!original) return

  editandoServicoIndex.value = null
  errosServico.value = {}
  novoServico.value = novoServicoPadrao()

  editandoPacoteIndex.value = indiceReal
  errosPacote.value = {}
  novoPacote.value = {
    id: original.id ?? null,
    nome: original.nome || '',
    descricao: original.descricao || '',
    itens: original.itens || '',
    duracao: original.duracao || '',
    preco: original.preco || '',
    colabIds: original.colabIds ? [...original.colabIds] : [],
    serviceId: original.serviceId ?? null,
    sessionsTotal: original.sessionsTotal ?? 4
  }

  modalPacoteInstance?.show()

  nextTick(() => {
    inputNovoPacote.value?.focus()
  })
}

async function salvarNovoServico(): Promise<void> {
  if (loading.value) return
  if (!validarServico()) return

  try {
    loading.value = true

    const colabIdsFinais =
      usuarioLogado.value.tipo === 'funcionario' &&
      modoServico.value === 'funcionario' &&
      usuarioLogado.value.colabId
        ? [usuarioLogado.value.colabId]
        : [...novoServico.value.colabIds]

    const priceSanitized = Number((novoServico.value.preco || '').toString().replace(/\./g, '').replace(',', '.')) || 0

    const payload = {
      service: {
        name: novoServico.value.nome,
        description: novoServico.value.descricao,
        service_type: novoServico.value.tipo,
        duration_minutes: converterDuracaoParaMinutos(novoServico.value.duracao),
        price: priceSanitized,
        employee_ids: colabIdsFinais
      }
    }

    if (editandoServicoIndex.value !== null && novoServico.value.id) {
      await api.put(`/services/${novoServico.value.id}`, payload)
    } else {
      await api.post('/services', payload)
    }

    await carregarServicos()
    fecharModalServicoComSeguranca()
  } catch (error: any) {
    console.error('Erro ao salvar serviço:', error)
    const errorMsg = error?.response?.data?.error || error?.response?.data?.errors?.join(', ') || 'Erro ao processar serviço. Verifique os dados.'
    alert(errorMsg)
  } finally {
    loading.value = false
  }
}

async function salvarNovoPacote(): Promise<void> {
  if (loading.value) return
  if (!validarPacote()) return

  try {
    loading.value = true

    const priceSanitized = Number((novoPacote.value.preco || '').toString().replace(/\./g, '').replace(',', '.')) || 0

    const colabIdsFinais =
      usuarioLogado.value.tipo === 'funcionario' &&
      modoServico.value === 'funcionario' &&
      usuarioLogado.value.colabId
        ? [usuarioLogado.value.colabId]
        : [...novoPacote.value.colabIds]

    const payload = {
      service_package: {
        name: novoPacote.value.nome,
        description: novoPacote.value.descricao,
        included_items: novoPacote.value.itens,
        duration_minutes: converterDuracaoParaMinutos(novoPacote.value.duracao),
        price: priceSanitized,
        service_id: novoPacote.value.serviceId,
        sessions_total: novoPacote.value.sessionsTotal
      },
      employee_ids: colabIdsFinais
    }

    if (editandoPacoteIndex.value !== null && novoPacote.value.id) {
      await api.put(`/service_packages/${novoPacote.value.id}`, payload)
    } else {
      await api.post('/service_packages', payload)
    }

    await carregarPacotes()
    fecharModalPacoteComSeguranca()
  } catch (error: any) {
    console.error('Erro ao salvar pacote:', error)
    const errorMsg = error?.response?.data?.error || error?.response?.data?.errors?.join(', ') || 'Erro ao processar pacote. Verifique os dados.'
    alert(errorMsg)
  } finally {
    loading.value = false
  }
}

async function removerServico(index: number): Promise<void> {
  if (loading.value) return
  const servicoSelecionado = servicosVisiveis.value[index]
  if (!servicoSelecionado?.id) return

  const confirmado = window.confirm(`Deseja realmente remover o serviço "${servicoSelecionado.nome}"?`)
  if (!confirmado) return

  try {
    loading.value = true
    await api.delete(`/services/${servicoSelecionado.id}`)
    await carregarServicos()

    if (editandoServicoIndex.value !== null) {
      fecharModalServicoComSeguranca()
    }
  } catch (error: any) {
    console.error('Erro ao remover serviço:', error)
    alert(error?.response?.data?.error || 'Acesso negado ou erro ao remover o serviço.')
  } finally {
    loading.value = false
  }
}

async function removerPacote(index: number): Promise<void> {
  if (loading.value) return
  const pacoteSelecionado = pacotesVisiveis.value[index]
  if (!pacoteSelecionado?.id) return

  const confirmado = window.confirm(`Deseja realmente remover o pacote "${pacoteSelecionado.nome}"?`)
  if (!confirmado) return

  try {
    loading.value = true
    await api.delete(`/service_packages/${pacoteSelecionado.id}`)
    await carregarPacotes()

    if (editandoPacoteIndex.value !== null) {
      fecharModalPacoteComSeguranca()
    }
  } catch (error: any) {
    console.error('Erro ao remover pacote:', error)
    alert(error?.response?.data?.error || 'Acesso negado ou erro ao remover o pacote.')
  } finally {
    loading.value = false
  }
}

async function salvarServicos(): Promise<void> {
  await Promise.all([
    carregarServicos(),
    carregarPacotes()
  ])
}
</script>

<style scoped>
/* Ajuste de Layout Tela Cheia */
.page-content {
  max-width: 100% !important;
}

.table-glass-card {
  background: rgba(var(--bs-body-bg-rgb), 0.4);
  border: 1px solid var(--card-border);
  border-radius: 20px;
  padding: 1.25rem;
  backdrop-filter: blur(12px);
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

/* Header Premium */
.dashboard-header {
  background: rgba(var(--bs-body-bg-rgb), 0.4) !important;
  border: 1px solid var(--card-border) !important;
  backdrop-filter: blur(12px) !important;
  position: relative;
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
  border-radius: 20px;
  backdrop-filter: blur(15px);
  overflow: hidden;
}

.form-card {
  border-color: var(--card-border) !important;
  background: var(--bs-body-bg) !important;
}

.modal-custom {
  background: var(--glass-bg);
  border: 1px solid var(--card-border);
  border-radius: 24px;
  backdrop-filter: blur(18px);
  color: var(--bs-body-color);
}

.custom-input {
  border-radius: 12px;
  border: 1px solid var(--card-border);
  background: var(--bs-body-bg);
  color: var(--bs-body-color);
  font-weight: 600;
  min-height: 46px;
  box-shadow: none !important;
}

.custom-input:focus {
  border-color: var(--bs-primary);
  box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.15) !important;
}

.custom-input.is-invalid,
.form-select.custom-input.is-invalid {
  border-color: var(--bs-danger) !important;
  box-shadow: 0 0 0 0.25rem rgba(220, 53, 69, 0.10) !important;
}

.custom-addon {
  background: var(--bs-tertiary-bg);
  border: 1px solid var(--card-border);
  color: var(--bs-body-color);
  font-weight: 700;
}

.invalid-feedback {
  font-size: 0.82rem;
  font-weight: 600;
}

.custom-table {
  border-collapse: separate;
  border-spacing: 0 8px;
  width: 100%;
}

.custom-table th {
  background: transparent;
  font-size: 0.75rem;
  letter-spacing: 0.1em;
  padding: 8px 20px;
  color: var(--bs-secondary-color);
  font-weight: 700;
  border: none;
  vertical-align: middle;
}

.custom-table td {
  background: rgba(var(--bs-body-color-rgb), 0.015) !important;
  border-top: 1px solid var(--card-border) !important;
  border-bottom: 1px solid var(--card-border) !important;
  padding: 14px 20px !important;
  vertical-align: middle;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.custom-table td:first-child {
  border-left: 1px solid var(--card-border) !important;
  border-top-left-radius: 12px;
  border-bottom-left-radius: 12px;
}

.custom-table td:last-child {
  border-right: 1px solid var(--card-border) !important;
  border-top-right-radius: 12px;
  border-bottom-right-radius: 12px;
}

.servico-row {
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.servico-row:hover td {
  background: rgba(var(--bs-primary-rgb), 0.025) !important;
  border-color: rgba(var(--bs-primary-rgb), 0.2) !important;
}

.servico-row:hover {
  transform: translateY(-1px);
}

.cell-servico-principal {
  min-width: 0;
  width: auto;
}

.servico-card-info {
  display: flex;
  flex-direction: column;
  gap: 0;
  min-height: 40px;
  max-width: 100%;
}

.servico-nome-inline {
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--bs-body-color);
  white-space: normal;
  word-break: break-word;
  line-height: 1.3;
  margin-bottom: 8px;
}

.servico-meta-stack {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding-left: 12px;
  border-left: 2.5px solid var(--bs-primary);
}

.servico-meta-row {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.servico-meta-label {
  font-size: 0.68rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--bs-secondary-color);
  opacity: 0.7;
  line-height: 1.2;
}

.servico-meta-value {
  font-size: 0.82rem;
  font-weight: 500;
  color: var(--bs-body-color);
  line-height: 1.4;
  white-space: normal;
  word-break: break-word;
}

.servico-tipo-badge {
  display: inline-flex;
  align-items: center;
  padding: 3px 10px;
  border-radius: 6px;
  background: rgba(var(--bs-primary-rgb), 0.1);
  color: var(--bs-primary);
  font-size: 0.78rem;
  font-weight: 600;
  width: fit-content;
}

.servico-descricao-text {
  font-size: 0.82rem;
  font-weight: 400;
  color: var(--bs-secondary-color);
  line-height: 1.4;
}

.servico-info-text {
  font-size: 0.92rem;
  color: var(--bs-body-color);
  line-height: 1.3;
  word-break: break-word;
}

.servico-preco {
  font-size: 1rem;
  font-weight: 800;
  color: var(--bs-primary);
  white-space: nowrap;
}

.btn-action {
  width: 40px;
  height: 40px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  border: 1px solid var(--card-border);
  background-color: var(--bs-tertiary-bg);
  color: var(--bs-body-color);
  flex-shrink: 0;
}

.btn-action:hover:not(.btn-delete) {
  background-color: var(--bs-primary) !important;
  color: white !important;
  transform: translateY(-2px);
  border-color: var(--bs-primary);
  box-shadow: 0 .5rem 1rem rgba(13, 110, 253, .15) !important;
}

.btn-delete:hover {
  background-color: var(--bs-danger) !important;
  color: white !important;
  transform: translateY(-2px);
  border-color: var(--bs-danger);
  box-shadow: 0 .5rem 1rem rgba(220, 53, 69, .15) !important;
}

.custom-multiselect {
  min-height: 120px !important;
  padding-top: 10px;
  padding-bottom: 10px;
}

.profissionais-selector {
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 12px;
  background: var(--bs-body-bg);
}

.profissionais-selector.is-invalid {
  border-color: var(--bs-danger) !important;
  box-shadow: 0 0 0 0.25rem rgba(220, 53, 69, 0.10) !important;
}

.profissionais-list {
  max-height: 200px;
  overflow-y: auto;
  border: 1px solid var(--card-border);
  border-radius: 8px;
}

.profissional-item {
  padding: 8px 12px;
  cursor: pointer;
  transition: background 0.15s;
  border-bottom: 1px solid var(--card-border);
  margin: 0;
}

.profissional-item:last-child {
  border-bottom: none;
}

.profissional-item:hover {
  background: rgba(var(--bs-primary-rgb), 0.05);
}

.profissional-item.selected {
  background: rgba(var(--bs-primary-rgb), 0.1);
}

.profissional-item .form-check-input {
  cursor: pointer;
}

.profissional-item .form-check-label {
  cursor: pointer;
  font-weight: 600;
  font-size: 0.9rem;
  margin: 0;
}

.profissionais-actions .btn-link {
  font-size: 0.82rem;
}

.transition-all {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.hover-lift:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 15px rgba(0,0,0,0.1) !important;
}

.border-dashed {
  border-style: dashed !important;
  border-color: var(--card-border) !important;
  border-width: 2px !important;
}

.hide-scrollbar {
  scrollbar-width: none;
}

.hide-scrollbar::-webkit-scrollbar {
  display: none;
}

.tracking-wider {
  letter-spacing: 0.05em;
}

/* TABLET */
@media (max-width: 991.98px) {
  .admin-card,
  .form-card {
    padding: 1rem !important;
  }

  .pt-2.pb-3.mb-4.border-bottom.d-flex.justify-content-between.align-items-center.flex-wrap.gap-3 {
    gap: 0.85rem !important;
  }
}

/* MOBILE */
@media (max-width: 767.98px) {
  .servico-row:hover,
  .servico-row:active {
    background-color: transparent !important;
  }

  .admin-card,
  .form-card {
    padding: 0.95rem !important;
    border-radius: 18px;
  }

  .bg-primary.bg-opacity-10.px-4.py-2.rounded-pill.border.border-primary.border-opacity-25.d-flex.align-items-center.gap-2 {
    width: 100%;
    justify-content: flex-start;
    flex-wrap: wrap;
    padding: 0.85rem 1rem !important;
    border-radius: 18px !important;
  }

  .d-flex.justify-content-between.align-items-center.mb-4.pb-3.border-bottom.flex-wrap.gap-3 {
    gap: 0.9rem !important;
  }

  .d-flex.justify-content-between.align-items-center.mb-4.pb-3.border-bottom.flex-wrap.gap-3 > div:first-child {
    width: 100%;
  }

  .d-flex.justify-content-between.align-items-center.mb-4.pb-3.border-bottom.flex-wrap.gap-3 > button {
    width: 100%;
  }

  .btn-outline-primary.rounded-pill.fw-bold.px-4.py-2.transition-all.shadow-sm.hover-lift,
  .btn-primary.btn-lg.rounded-pill.px-5.py-3.fw-bold.shadow.transition-all.hover-lift {
    width: 100%;
    justify-content: center;
  }

  .custom-table,
  .custom-table thead,
  .custom-table tbody,
  .custom-table tr,
  .custom-table th,
  .custom-table td {
    display: block;
    width: 100%;
  }

  .custom-table thead {
    display: none;
  }

  .custom-table tbody {
    display: flex;
    flex-direction: column;
    gap: 14px;
  }

  .custom-table tr.servico-row {
    background: rgba(255, 255, 255, 0.02);
    border: 1px solid var(--card-border);
    border-radius: 18px;
    padding: 0.95rem;
    box-shadow: none;
  }

  .custom-table tr.servico-row td {
    border: 0 !important;
    padding: 0 !important;
    margin: 0 !important;
    width: 100% !important;
    min-width: 0 !important;
    text-align: left !important;
    white-space: normal !important;
    background: transparent !important;
  }

  .custom-table tr.servico-row td + td {
    margin-top: 0.8rem !important;
  }

  .cell-servico-principal {
    min-width: 0 !important;
    padding: 0 !important;
  }

  .servico-card-info {
    gap: 0;
    min-height: auto;
  }

  .servico-nome-inline {
    font-size: 0.95rem;
    line-height: 1.25;
    margin-bottom: 6px;
  }

  .servico-meta-stack {
    gap: 5px;
    padding-left: 10px;
  }

  .servico-meta-value {
    font-size: 0.8rem;
  }

  .servico-tipo-badge {
    font-size: 0.75rem;
    padding: 2px 8px;
  }

  .servico-descricao-text {
    font-size: 0.8rem;
    overflow: visible;
    text-overflow: initial;
    white-space: normal;
    max-width: 100%;
  }

  .servico-info-text,
  .servico-preco {
    font-size: 0.92rem;
  }

  .custom-table tbody tr td:nth-child(2)::before,
  .custom-table tbody tr td:nth-child(3)::before,
  .custom-table tbody tr td:nth-child(4)::before {
    display: block;
    margin-bottom: 0.35rem;
    font-size: 0.72rem;
    font-weight: 800;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--bs-secondary-color);
  }

  .custom-table tbody tr td:nth-child(2)::before {
    content: "Profissionais";
  }

  .custom-table tbody tr td:nth-child(3)::before {
    content: "Duração";
  }

  .custom-table tbody tr td:nth-child(4)::before {
    content: "Preço";
  }

  .custom-table tr.servico-row td:last-child {
    display: flex;
    align-items: center;
    justify-content: flex-start !important;
    gap: 0.7rem;
    flex-wrap: wrap;
  }

  .custom-table tr.servico-row td:last-child::before {
    content: "Ações";
    display: block;
    width: 100%;
    margin-bottom: 0.3rem;
    font-size: 0.72rem;
    font-weight: 800;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--bs-secondary-color);
  }

  .btn-action {
    width: 38px;
    height: 38px;
    margin: 0 !important;
  }

  .badge {
    font-size: 0.82rem !important;
    padding: 0.55rem 0.95rem !important;
  }

  .btn-lg {
    width: 100%;
    padding: 0.95rem 1rem !important;
    font-size: 0.95rem !important;
  }

  .d-flex.justify-content-end.align-items-center.mt-4.mb-5.border-top.pt-4 {
    justify-content: stretch !important;
  }

  .modal-dialog {
    margin: 0.6rem;
  }

  .modal-footer {
    flex-wrap: wrap;
    gap: 0.5rem;
  }

  .modal-footer .btn {
    width: 100%;
  }
}

/* IPHONE SE */
@media (max-width: 480px) {
  .admin-card,
  .form-card {
    padding: 0.85rem !important;
    border-radius: 16px;
  }

  .servico-nome-inline {
    font-size: 0.9rem;
  }

  .servico-meta-value,
  .servico-info-text,
  .servico-preco {
    font-size: 0.8rem;
  }

  .btn-action {
    width: 36px;
    height: 36px;
  }
}

@media (max-width: 767.98px) {
  :deep(.table td),
  :deep(.custom-table td) {
    background: transparent !important;
  }
}

:deep(.table tbody tr:hover),
:deep(.table tbody tr:active),
:deep(.table-hover tbody tr:hover),
:deep(.table td) {
  background: transparent !important;
}
</style>