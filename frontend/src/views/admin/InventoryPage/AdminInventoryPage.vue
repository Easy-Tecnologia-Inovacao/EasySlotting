<template>
  <AdminLayout>
    <section class="page-shell animate-fade-in">
      <div class="page-content">
        <!-- Header com visual premium -->
        <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
          <div class="header-overlay"></div>
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1">
            <div class="d-flex align-items-center gap-3">
              <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                <i class="bi bi-box-seam fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Gestão de Estoque</h1>
                <p class="text-muted mb-0 small-text-responsive">Monitore níveis de estoque, entrada de insumos e configure alertas inteligentes.</p>
              </div>
            </div>

            <div class="d-flex align-items-center gap-2">
              <button
                v-if="canManageStock"
                class="btn btn-action-secondary px-4 py-2.5 rounded-pill fw-bold transition-all d-inline-flex align-items-center gap-2"
                @click="abrirModalEntradaEstoque"
              >
                <i class="bi bi-box-arrow-in-down fs-5"></i>
                <span>Adicionar Estoque</span>
              </button>

              <button
                v-if="canManageStock"
                class="btn btn-action-primary px-4 py-2.5 rounded-pill fw-bold transition-all d-inline-flex align-items-center gap-2"
                @click="abrirModalNovo"
              >
                <i class="bi bi-plus-lg fs-5"></i>
                <span>Novo Produto</span>
              </button>
            </div>
          </div>
        </div>

        <!-- Seção Principal de Conteúdo -->
        <div class="admin-card mb-4 p-3 p-sm-4">
          <div class="section-header mb-4 border-bottom pb-3 d-flex justify-content-between align-items-center flex-wrap gap-3">
            <div class="d-flex flex-column gap-1 w-100">
              <div class="d-flex align-items-center gap-2">
                <span class="text-uppercase tracking-wider small fw-bold text-muted">Setor de Estoque:</span>
                <div
                  v-if="modeloEstoque === 'individual'"
                  class="estoque-switch-container d-flex align-items-center bg-body-tertiary px-3 py-1.5 rounded-pill border"
                >
                  <i class="bi bi-funnel text-primary me-2"></i>
                  <select
                    class="form-select form-select-sm border-0 bg-transparent fw-bold text-primary pe-4 cursor-pointer shadow-none select-clean"
                    v-model="estoqueAtivoSelecionado"
                  >
                    <option value="loja">Estoque Geral (Loja)</option>
                    <optgroup label="Profissionais">
                      <option v-for="c in colaboradores" :key="c.id" :value="c.id">{{ c.nome }}</option>
                    </optgroup>
                  </select>
                </div>
                <span v-else class="badge bg-primary-subtle text-primary border border-primary-subtle px-3 py-2 rounded-pill fw-bold">
                  Estoque Geral
                </span>
              </div>
              <div class="form-text small text-muted ps-1">
                {{ modeloEstoque === 'individual' 
                  ? 'Você está no modo de estoque individual. Selecione se deseja gerenciar o estoque geral da loja ou o estoque consignado a um profissional específico.' 
                  : 'Você está no modo de estoque geral/único. Todos os produtos pertencem e são geridos centralizadamente pela loja.' }}
              </div>
            </div>
          </div>

          <!-- Cards de Alertas Resumidos -->
          <div class="row g-3 mb-4">
            <div class="col-12 col-lg-6">
              <div class="alert-glass-card border-glow-danger h-100">
                <div class="d-flex align-items-center justify-content-between mb-3 pb-2 border-bottom border-danger-subtle border-opacity-25">
                  <div class="d-flex align-items-center gap-2">
                    <div class="alert-icon bg-danger-glow text-danger d-flex align-items-center justify-content-center rounded-circle">
                      <i class="bi bi-exclamation-octagon-fill"></i>
                    </div>
                    <div>
                      <h6 class="fw-bold mb-0 text-body">Crítico: Sem Estoque</h6>
                      <p class="small text-muted mb-0 font-11">Produtos com quantidade zerada.</p>
                    </div>
                  </div>
                  <span class="badge badge-glow-danger px-3 py-2">
                    {{ itensSemEstoque.length }}
                  </span>
                </div>

                <div v-if="itensSemEstoque.length > 0" class="alert-list custom-scroll">
                  <div
                    v-for="item in itensSemEstoque"
                    :key="`zero-${item.id}`"
                    class="alert-list-item border-start border-danger border-3 shadow-sm"
                  >
                    <div class="d-flex align-items-center justify-content-between gap-3">
                      <div>
                        <div class="fw-bold text-body font-14">{{ item.nome }}</div>
                        <div class="small text-muted font-12">
                          Mínimo Recomendado: {{ item.estoque_minimo }} un. •
                          R$ {{ Number(item.preco).toFixed(2).replace('.', ',') }}
                        </div>
                      </div>

                      <span class="badge badge-glow-danger px-2.5 py-1.5 font-12">
                        0 un.
                      </span>
                    </div>
                  </div>
                </div>

                <div v-else class="small text-muted fw-semibold py-4 text-center">
                  <i class="bi bi-check-circle-fill text-success me-2 fs-5"></i>Nenhum item com estoque zerado.
                </div>
              </div>
            </div>

            <div class="col-12 col-lg-6">
              <div class="alert-glass-card border-glow-warning h-100">
                <div class="d-flex align-items-center justify-content-between mb-3 pb-2 border-bottom border-warning-subtle border-opacity-25">
                  <div class="d-flex align-items-center gap-2">
                    <div class="alert-icon bg-warning-glow text-warning d-flex align-items-center justify-content-center rounded-circle">
                      <i class="bi bi-exclamation-triangle-fill"></i>
                    </div>
                    <div>
                      <h6 class="fw-bold mb-0 text-body">Atenção: Baixo Estoque</h6>
                      <p class="small text-muted mb-0 font-11">Produtos abaixo ou no limite mínimo.</p>
                    </div>
                  </div>
                  <span class="badge badge-glow-warning px-3 py-2">
                    {{ itensBaixoEstoque.length }}
                  </span>
                </div>

                <div v-if="itensBaixoEstoque.length > 0" class="alert-list custom-scroll">
                  <div
                    v-for="item in itensBaixoEstoque"
                    :key="`baixo-${item.id}`"
                    class="alert-list-item border-start border-warning border-3 shadow-sm"
                  >
                    <div class="d-flex align-items-center justify-content-between gap-3">
                      <div>
                        <div class="fw-bold text-body font-14">{{ item.nome }}</div>
                        <div class="small text-muted font-12">
                          Atual: {{ item.estoque }} un. • Mínimo: {{ item.estoque_minimo }} un.
                        </div>
                      </div>

                      <span class="badge badge-glow-warning px-2.5 py-1.5 font-12">
                        Alerta
                      </span>
                    </div>
                  </div>
                </div>

                <div v-else class="small text-muted fw-semibold py-4 text-center">
                  <i class="bi bi-check-circle-fill text-success me-2 fs-5"></i>Nenhum item com estoque baixo.
                </div>
              </div>
            </div>
          </div>

          <!-- Mensagem de Erro Global -->
          <div v-if="erroGlobal" class="alert-glass-danger d-flex align-items-center mb-4 p-3 rounded-4 shadow-sm border border-danger border-opacity-25" role="alert">
            <i class="bi bi-exclamation-triangle-fill fs-4 me-3 text-danger"></i>
            <div class="fw-medium text-danger">{{ erroGlobal }}</div>
          </div>

          <!-- Loader de Produtos -->
          <div v-if="carregandoProdutos" class="loader-glass text-center py-5 my-3 rounded-4 border">
            <div class="spinner-grow text-primary shadow-sm" role="status" style="width: 3.5rem; height: 3.5rem;">
              <span class="visually-hidden">Carregando...</span>
            </div>
            <p class="text-muted mt-3 fw-bold tracking-wide">Carregando estoque do inventário...</p>
          </div>

          <!-- Tabela de Itens de Estoque -->
          <div v-else-if="produtosFiltrados.length > 0" class="table-responsive hide-scrollbar table-glass-card shadow-sm">
            <table class="table align-middle mb-0 custom-table">
              <thead>
                <tr class="small text-muted tracking-widest text-uppercase fw-bold border-bottom">
                  <th class="ps-4 py-3 border-0">Produto</th>
                  <th class="border-0 text-center py-3">Quantidade em Estoque</th>
                  <th class="border-0 text-center py-3">Nível Mínimo</th>
                  <th class="border-0 py-3">Preço Unitário</th>
                  <th class="text-end pe-4 border-0 py-3">Opções</th>
                </tr>
              </thead>

              <tbody>
                <tr
                  v-for="prod in produtosFiltrados"
                  :key="prod.id"
                  class="stock-row transition-all"
                >
                  <td class="ps-4 pe-3">
                    <div class="d-flex align-items-center gap-3 produto-cell">
                      <div class="produto-icon bg-body-tertiary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                        <i class="bi bi-box-seam fs-5 text-primary opacity-75"></i>
                      </div>

                      <div class="produto-info">
                        <div class="fw-bold text-body fs-6 tracking-tight">{{ prod.nome }}</div>
                        <div class="small text-muted">
                          <span class="badge bg-secondary-subtle text-muted rounded-pill px-2.5 py-1 text-uppercase font-10">
                            {{ prod.dono === 'loja' ? 'Estoque Geral' : `Profissional: ${nomeEstoqueAtivo}` }}
                          </span>
                        </div>
                      </div>
                    </div>
                  </td>

                  <td class="text-center">
                    <span
                      class="badge badge-glow px-3 py-2.5 font-14"
                      :class="getEstoqueBadgeClass(prod)"
                    >
                      <span class="badge-dot me-2"></span>{{ prod.estoque }} un.
                    </span>
                  </td>

                  <td class="text-center">
                    <span class="fw-bold text-warning-custom px-3 py-1 bg-warning bg-opacity-10 border border-warning border-opacity-25 rounded-pill font-13 shadow-sm">
                      {{ prod.estoque_minimo }} un.
                    </span>
                  </td>

                  <td>
                    <span class="fw-extrabold text-success fs-6 text-gradient-success">
                      R$ {{ Number(prod.preco).toFixed(2).replace('.', ',') }}
                    </span>
                  </td>

                  <td class="text-end text-nowrap pe-4">
                    <button
                      v-if="podeEditarOuExcluir(prod)"
                      class="btn btn-action-table rounded-circle me-2 shadow-sm btn-action-edit"
                      @click="abrirModalEditar(prod)"
                      title="Editar produto"
                    >
                      <i class="bi bi-pencil-fill"></i>
                    </button>

                    <button
                      v-if="podeEditarOuExcluir(prod)"
                      class="btn btn-action-table rounded-circle shadow-sm btn-action-delete"
                      @click="removerProduto(prod.id)"
                      title="Excluir produto"
                    >
                      <i class="bi bi-trash-fill"></i>
                    </button>

                    <span v-else class="badge bg-secondary-subtle text-muted font-11 px-2.5 py-1 rounded-pill">
                      Apenas leitura
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Estado Vazio -->
          <div
            v-else
            class="text-center py-5 text-muted glass-empty-state rounded-4 border my-2 transition-all empty-state px-3"
          >
            <div class="empty-state-glow bg-primary bg-opacity-10 rounded-circle d-inline-flex p-4 mb-3 text-primary shadow-sm">
              <i class="bi bi-box-seam-fill fs-1 opacity-75"></i>
            </div>
            <h5 class="fw-extrabold text-body tracking-tight">Inventário sem produtos</h5>
            <p class="mb-0 fw-semibold opacity-75 max-width-350 mx-auto">Não encontramos nenhum item neste setor do estoque. Clique em "Novo Produto" para cadastrar!</p>
          </div>
        </div>
      </div>
    </section>

    <!-- MODAL PRODUTO -->
    <div
      class="modal fade"
      id="modalProduto"
      tabindex="-1"
      aria-hidden="true"
      ref="modalProdutoRef"
    >
      <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content modal-custom border shadow-lg">
          <div class="modal-header border-0 pb-0">
            <div>
              <h5 class="modal-title fw-extrabold tracking-tight">
                {{ isEditando ? 'Editar Produto' : 'Novo Produto' }}
              </h5>
              <p class="text-muted small mb-0">
                Preencha as informações do produto.
              </p>
            </div>

            <button
              type="button"
              class="btn-close"
              @click="fecharModalProduto"
              aria-label="Close"
            ></button>
          </div>

          <div class="modal-body pt-3">
            <!-- Erro Local -->
            <div v-if="erroModal" class="alert alert-danger d-flex align-items-center mb-3 border-0 shadow-sm rounded-3 py-2 px-3 small animate-fade-in">
              <i class="bi bi-exclamation-circle-fill me-2 text-danger"></i>
              <div>{{ erroModal }}</div>
            </div>

            <div class="row g-3">
              <div class="col-12 col-md-6">
                <label class="form-label fw-bold small text-muted">Nome do produto</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  v-model="formProduto.nome"
                  placeholder="Ex: Pomada Modeladora"
                  autocomplete="off"
                  name="product_name_input"
                  data-lpignore="true"
                  data-1p-ignore
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  O nome identificador do produto ou insumo utilizado nos serviços (Ex: Pomada Modeladora Efeito Matte).
                </div>
              </div>

              <div class="col-12 col-md-6">
                <label class="form-label fw-bold small text-muted">Estoque de destino</label>
                <input
                  type="text"
                  class="form-control custom-input disabled-highlight"
                  :value="estoqueAtivoSelecionado === 'loja' ? 'Estoque Geral (Loja)' : nomeEstoqueAtivo"
                  disabled
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  Indica em qual setor do estoque o produto será alocado com base no setor selecionado na tela principal.
                </div>
              </div>

              <!-- Preço de venda -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-bold small text-muted">Preço de venda</label>
                <div class="input-group elegant-input-group shadow-sm">
                  <span class="input-group-text custom-addon">R$</span>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    class="form-control custom-input"
                    v-model.number="formProduto.preco"
                    placeholder="0,00"
                    autocomplete="off"
                    name="product_price_input"
                    data-lpignore="true"
                    data-1p-ignore
                  >
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  Valor cobrado do cliente final na venda deste produto ou uso associado.
                </div>
              </div>

              <!-- Quantidade em Estoque -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-bold small text-muted">Quantidade em Estoque</label>
                <div class="input-group elegant-input-group shadow-sm">
                  <input
                    type="number"
                    min="0"
                    class="form-control custom-input"
                    v-model.number="formProduto.estoque"
                    placeholder="0"
                    autocomplete="off"
                    name="product_stock_input"
                    data-lpignore="true"
                    data-1p-ignore
                  >
                  <span class="input-group-text custom-addon">un.</span>
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  Saldo físico atual em unidades que está disponível no inventário deste produto.
                </div>
              </div>

              <!-- Estoque mínimo -->
              <div class="col-12 col-md-4">
                <label class="form-label fw-bold small text-muted">Estoque mínimo</label>
                <div class="input-group elegant-input-group shadow-sm">
                  <input
                    type="number"
                    min="0"
                    class="form-control custom-input"
                    v-model.number="formProduto.estoque_minimo"
                    placeholder="1"
                    autocomplete="off"
                    name="product_min_stock_input"
                    data-lpignore="true"
                    data-1p-ignore
                  >
                  <span class="input-group-text custom-addon">un.</span>
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  Limite mínimo recomendado. Quando o estoque atingir ou ficar abaixo deste valor, alertas de reposição serão ativados.
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer border-0 pt-0 flex-wrap gap-2">
            <button
              type="button"
              class="btn btn-action-secondary px-4 py-2.5 rounded-pill fw-bold border"
              @click="fecharModalProduto"
            >
              Cancelar
            </button>

            <button
              type="button"
              class="btn btn-action-primary px-4 py-2.5 rounded-pill fw-bold shadow-sm"
              @click="salvarProduto"
              :disabled="loading"
            >
              <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
              {{ loading ? 'Salvando...' : (isEditando ? 'Salvar Alterações' : 'Adicionar Produto') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL ENTRADA DE ESTOQUE -->
    <!-- Honeypot: engana gerenciadores de senha do navegador -->
    <div style="position:absolute;width:0;height:0;overflow:hidden;opacity:0;pointer-events:none;" aria-hidden="true">
      <input type="text" name="fake_email_hpot" tabindex="-1" autocomplete="username">
      <input type="password" name="fake_pass_hpot" tabindex="-1" autocomplete="current-password">
    </div>

    <div
      class="modal fade"
      id="modalEntradaEstoque"
      tabindex="-1"
      aria-hidden="true"
      ref="modalEntradaEstoqueRef"
    >
      <div class="modal-dialog modal-lg modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content modal-custom border shadow-lg">
          <div class="modal-header border-0 pb-0">
            <div>
              <h5 class="modal-title fw-extrabold tracking-tight">Adicionar ao Estoque</h5>
              <p class="text-muted small mb-0">
                Selecione um produto cadastrado e informe a quantidade da nova entrada.
              </p>
            </div>

            <button
              type="button"
              class="btn-close"
              @click="fecharModalEntradaEstoque"
              aria-label="Close"
            ></button>
          </div>

          <div class="modal-body pt-3">
            <!-- Erro Local -->
            <div v-if="erroModal" class="alert alert-danger d-flex align-items-center mb-3 border-0 shadow-sm rounded-3 py-2 px-3 small animate-fade-in">
              <i class="bi bi-exclamation-circle-fill me-2 text-danger"></i>
              <div>{{ erroModal }}</div>
            </div>

            <div class="row g-3 mb-3">
              <div class="col-12 col-md-8">
                <label class="form-label fw-bold small text-muted">Pesquisar produto</label>
                <div class="input-group elegant-input-group shadow-sm">
                  <span class="input-group-text custom-addon bg-transparent"><i class="bi bi-search text-muted"></i></span>
                  <input
                    type="text"
                    class="form-control custom-input border-start-0"
                    :value="buscaEntradaEstoque"
                    @input="handleBuscaInput($event.target.value)"
                    placeholder="Digite o nome do produto"
                    autocomplete="new-password"
                    name="estoque_busca_xr7"
                    readonly
                    @focus="$event.target.removeAttribute('readonly')"
                    @blur="$event.target.setAttribute('readonly', true)"
                    data-lpignore="true"
                    data-1p-ignore
                    data-bwignore="true"
                  >
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  Busque o nome do produto cadastrado na lista abaixo e selecione-o para registrar a reposição.
                </div>
              </div>

              <div class="col-12 col-md-4">
                <label class="form-label fw-bold small text-muted">Quantidade de entrada</label>
                <div class="input-group elegant-input-group shadow-sm">
                  <input
                    type="number"
                    min="1"
                    class="form-control custom-input"
                    :value="quantidadeEntradaEstoque"
                    @input="quantidadeEntradaEstoque = Number($event.target.value)"
                    placeholder="0"
                    autocomplete="new-password"
                    name="estoque_qtd_xr7"
                    readonly
                    @focus="$event.target.removeAttribute('readonly')"
                    @blur="$event.target.setAttribute('readonly', true)"
                    data-lpignore="true"
                    data-1p-ignore
                    data-bwignore="true"
                  >
                  <span class="input-group-text custom-addon">un.</span>
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  Quantidade a ser adicionada (somada) ao estoque atual do produto selecionado.
                </div>
              </div>
            </div>

            <div class="lista-itens-modal border rounded-4 p-2 shadow-inner custom-scroll">
              <div
                v-if="itensPesquisaEntrada.length > 0"
                class="d-flex flex-column gap-2"
              >
                <button
                  v-for="item in itensPesquisaEntrada"
                  :key="`entrada-${item.id}`"
                  type="button"
                  class="item-estoque-button text-start"
                  :class="{ active: itemSelecionadoEntrada?.id === item.id }"
                  @click="selecionarItemEntrada(item)"
                >
                  <div class="d-flex align-items-center justify-content-between gap-3">
                    <div>
                      <div class="fw-bold text-body font-15">{{ item.nome }}</div>
                      <div class="small text-muted">
                        Qtd. Atual: <span class="fw-bold text-primary">{{ item.estoque }} un.</span> • Estoque Mínimo: {{ item.estoque_minimo }} un.
                      </div>
                    </div>

                    <div class="text-end">
                      <div class="fw-extrabold text-success font-15">
                        R$ {{ Number(item.preco).toFixed(2).replace('.', ',') }}
                      </div>
                    </div>
                  </div>
                </button>
              </div>

              <div v-else class="text-center text-muted py-5 small fw-semibold">
                <i class="bi bi-search-heart fs-3 d-block mb-2 text-muted opacity-50"></i>
                Nenhum produto correspondente encontrado.
              </div>
            </div>
          </div>

          <div class="modal-footer border-0 pt-0 flex-wrap gap-2">
            <button
              type="button"
              class="btn btn-action-secondary px-4 py-2.5 rounded-pill fw-bold border"
              @click="fecharModalEntradaEstoque"
            >
              Cancelar
            </button>

            <button
              type="button"
              class="btn btn-action-primary px-4 py-2.5 rounded-pill fw-bold shadow-sm"
              @click="salvarEntradaEstoque"
              :disabled="loading || !itemSelecionadoEntrada || !quantidadeEntradaEstoque || quantidadeEntradaEstoque < 1"
            >
              <span v-if="loading" class="spinner-border spinner-border-sm me-2"></span>
              {{ loading ? 'Salvando...' : 'Adicionar ao Estoque' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import { api } from '@/services/api'
import { ref, computed, onMounted } from 'vue'
import { Modal } from 'bootstrap'

const modeloEstoque = ref('unico')
const colaboradores = ref([])
const carregandoColaboradores = ref(false)

// Dados do usuário e permissões da sessão (OWASP/LGPD)
const currentUser = computed(() => {
  try {
    const userStr = localStorage.getItem('user') || sessionStorage.getItem('user')
    return userStr ? JSON.parse(userStr) : null
  } catch {
    return null
  }
})

const isOwner = computed(() => {
  const role = currentUser.value?.role
  return role === 'owner' || role === 'super_admin'
})

const permissions = computed(() => {
  try {
    return JSON.parse(localStorage.getItem('establishment-permissions') || '{}')
  } catch {
    return {}
  }
})

const canManageStock = computed(() => {
  return isOwner.value || !!permissions.value?.can_manage_stock
})

function podeEditarOuExcluir(item) {
  if (isOwner.value) return true
  if (canManageStock.value) {
    if (item.dono === 'loja') return true
    return Number(item.donoId) === Number(currentUser.value?.id)
  }
  return false
}

const todosProdutos = ref([])
const estoqueAtivoSelecionado = ref('loja')
const isEditando = ref(false)
const loading = ref(false)
const carregandoProdutos = ref(true)
const erroGlobal = ref('')
const erroModal = ref('')

const modalProdutoRef = ref(null)
const modalEntradaEstoqueRef = ref(null)

let modalProdutoInstance = null
let modalEntradaEstoqueInstance = null

const buscaEntradaEstoque = ref('')
const buscaDebounced = ref('')
let debounceTimeout = null

// Busca dinâmica de colaboradores do estabelecimento (Anti-Mock)
async function carregarColaboradores() {
  try {
    carregandoColaboradores.value = true
    const res = await api.get('/admin/team')
    if (Array.isArray(res.data)) {
      colaboradores.value = res.data
        .filter(m => m.active !== false && m.user_id)
        .map(m => ({
          id: m.user_id,
          nome: m.name || `Profissional #${m.user_id}`
        }))
    }
  } catch (err) {
    console.error('Erro ao carregar colaboradores do estabelecimento:', err)
  } finally {
    carregandoColaboradores.value = false
  }
}

// Funções de sanitização e validação de segurança (Anti-XSS sem codificação HTML prematura)
function sanitizeText(text) {
  if (typeof text !== 'string') return ''
  return text
    .replace(/<[^>]*>/g, '') // Remove tags HTML
    .replace(/[\x00-\x1f\x7f]/g, '') // Remove caracteres de controle
    .trim()
}

function sanitizeNumber(val) {
  const num = Number(val)
  return isNaN(num) ? 0 : num
}

function validateProductName(name) {
  const cleanName = (name || '').trim()
  return cleanName.length >= 2 && cleanName.length <= 120
}

function validatePrice(price) {
  const val = Number(price)
  return !isNaN(val) && val >= 0 && val <= 999999
}

function validateStock(qty) {
  const val = Number(qty)
  return !isNaN(val) && Number.isInteger(val) && val >= 0 && val <= 999999
}

function handleBuscaInput(val) {
  buscaEntradaEstoque.value = sanitizeText(val)
  if (debounceTimeout) clearTimeout(debounceTimeout)
  debounceTimeout = setTimeout(() => {
    buscaDebounced.value = buscaEntradaEstoque.value
  }, 300)
}

const quantidadeEntradaEstoque = ref(1)
const itemSelecionadoEntrada = ref(null)

const formProdutoPadrao = () => ({
  id: null,
  nome: '',
  preco: 0,
  estoque: 0,
  estoque_minimo: 1
})

const formProduto = ref(formProdutoPadrao())

const produtosFiltrados = computed(() => {
  return estoqueAtivoSelecionado.value === 'loja'
    ? todosProdutos.value.filter(p => p.dono === 'loja')
    : todosProdutos.value.filter(
        p => p.dono === 'funcionario' && Number(p.donoId) === Number(estoqueAtivoSelecionado.value)
      )
})

const itensSemEstoque = computed(() => {
  return produtosFiltrados.value.filter(item => Number(item.estoque) === 0)
})

const itensBaixoEstoque = computed(() => {
  return produtosFiltrados.value.filter(item => {
    const qtd = Number(item.estoque)
    const minimo = Number(item.estoque_minimo || 0)
    return qtd > 0 && qtd <= minimo
  })
})

const itensPesquisaEntrada = computed(() => {
  const termo = buscaDebounced.value.trim().toLowerCase()

  const base =
    estoqueAtivoSelecionado.value === 'loja'
      ? todosProdutos.value.filter(p => p.dono === 'loja')
      : todosProdutos.value.filter(
          p => p.dono === 'funcionario' && Number(p.donoId) === Number(estoqueAtivoSelecionado.value)
        )

  if (!termo) return base

  return base.filter(item => item.nome.toLowerCase().includes(termo))
})

const nomeEstoqueAtivo = computed(() => {
  if (estoqueAtivoSelecionado.value === 'loja') return 'Estoque Geral'
  return colaboradores.value.find(c => Number(c.id) === Number(estoqueAtivoSelecionado.value))?.nome || 'Profissional'
})

// Mapeia classes de badges premium e brilhantes com glows modernos
function getEstoqueBadgeClass(prod) {
  const qtd = Number(prod.estoque)
  const minimo = Number(prod.estoque_minimo || 0)

  if (qtd === 0) return 'badge-glow-danger'
  if (qtd <= minimo) return 'badge-glow-warning'
  return 'badge-glow-success'
}

function limparBackdropsModal() {
  document.querySelectorAll('.modal-backdrop').forEach(b => b.remove());
  document.body.classList.remove('modal-open');
  document.body.style.overflow = '';
  document.body.style.paddingRight = '';
}

function abrirModalNovo() {
  isEditando.value = false
  formProduto.value = formProdutoPadrao()
  erroModal.value = ''
  modalProdutoInstance?.show()
}

function abrirModalEditar(prod) {
  isEditando.value = true
  formProduto.value = {
    id: prod.id,
    nome: prod.nome,
    preco: Number(prod.preco),
    estoque: Number(prod.estoque),
    estoque_minimo: Number(prod.estoque_minimo || 1)
  }
  erroModal.value = ''
  modalProdutoInstance?.show()
}

function fecharModalProduto() {
  erroModal.value = ''
  ;(document.activeElement)?.blur()
  modalProdutoInstance?.hide()
  setTimeout(limparBackdropsModal, 300)
}

function abrirModalEntradaEstoque() {
  buscaEntradaEstoque.value = ''
  quantidadeEntradaEstoque.value = 1
  itemSelecionadoEntrada.value = null
  erroModal.value = ''
  modalEntradaEstoqueInstance?.show()
}

function fecharModalEntradaEstoque() {
  erroModal.value = ''
  ;(document.activeElement)?.blur()
  modalEntradaEstoqueInstance?.hide()
  setTimeout(limparBackdropsModal, 300)
}

function selecionarItemEntrada(item) {
  itemSelecionadoEntrada.value = item
}

async function carregarProdutos() {
  try {
    carregandoProdutos.value = true
    erroGlobal.value = ''
    const response = await api.get('/stock_items')
    todosProdutos.value = response.data || []
  } catch (error) {
    console.error('Erro ao carregar produtos:', error)
    erroGlobal.value = 'Não foi possível carregar os produtos. Tente novamente mais tarde.'
  } finally {
    carregandoProdutos.value = false
  }
}

async function salvarProduto() {
  if (loading.value) return
  erroModal.value = ''
  
  const nomeSanitizado = sanitizeText(formProduto.value.nome)
  if (!validateProductName(nomeSanitizado)) {
    erroModal.value = 'O nome do produto deve conter de 2 a 120 caracteres.'
    return
  }

  const precoVal = sanitizeNumber(formProduto.value.preco)
  if (!validatePrice(precoVal)) {
    erroModal.value = 'O preço de venda deve ser um número válido entre R$ 0,00 e R$ 999.999,00.'
    return
  }

  const estoqueVal = sanitizeNumber(formProduto.value.estoque)
  if (!validateStock(estoqueVal)) {
    erroModal.value = 'A quantidade em estoque deve ser um número inteiro válido de 0 a 999.999.'
    return
  }

  const minimoVal = sanitizeNumber(formProduto.value.estoque_minimo)
  if (!validateStock(minimoVal)) {
    erroModal.value = 'O estoque mínimo deve ser um número inteiro válido de 0 a 999.999.'
    return
  }

  try {
    loading.value = true

    const donoTipo = estoqueAtivoSelecionado.value === 'loja' ? 'loja' : 'funcionario'
    const donoIdVal = estoqueAtivoSelecionado.value === 'loja' ? null : Number(estoqueAtivoSelecionado.value)

    const payload = {
      stock_item: {
        name: nomeSanitizado,
        sale_price: precoVal,
        quantity: estoqueVal,
        minimum_stock: minimoVal,
        stock_scope: donoTipo,
        owner_user_id: donoIdVal
      }
    }

    if (isEditando.value && formProduto.value.id) {
      const parsedId = Number(formProduto.value.id)
      if (isNaN(parsedId) || parsedId <= 0) throw new Error('ID do produto inválido.')
      await api.put(`/stock_items/${parsedId}`, payload)
    } else {
      await api.post('/stock_items', payload)
    }

    await carregarProdutos()
    fecharModalProduto()
  } catch (error) {
    console.error('Erro ao salvar produto:', error)
    erroModal.value = error.response?.data?.error || (error.response?.data?.errors ? error.response.data.errors.join(', ') : null) || error.response?.data?.message || error.message || 'Erro ao salvar o produto. Verifique os dados.'
  } finally {
    loading.value = false
  }
}

async function salvarEntradaEstoque() {
  if (loading.value) return
  erroModal.value = ''
  if (!itemSelecionadoEntrada.value) {
    erroModal.value = 'Selecione um produto primeiro.'
    return
  }

  const qtdEntrada = sanitizeNumber(quantidadeEntradaEstoque.value)
  if (!validateStock(qtdEntrada) || qtdEntrada < 1) {
    erroModal.value = 'A quantidade de entrada deve ser um número inteiro válido maior que zero (máx. 999.999).'
    return
  }

  try {
    loading.value = true

    const item = itemSelecionadoEntrada.value
    const parsedId = Number(item.id)
    if (isNaN(parsedId) || parsedId <= 0) throw new Error('ID do produto inválido.')

    // Entrada atômica no backend com lock pessimista FOR UPDATE (Anti-Race Condition)
    await api.post(`/stock_items/${parsedId}/add_stock`, { quantity: qtdEntrada })

    await carregarProdutos()
    fecharModalEntradaEstoque()
  } catch (error) {
    console.error('Erro ao adicionar estoque:', error)
    erroModal.value = error.response?.data?.error || error.response?.data?.message || error.message || 'Erro ao registrar entrada de estoque.'
  } finally {
    loading.value = false
  }
}

async function removerProduto(id) {
  const parsedId = Number(id)
  if (isNaN(parsedId) || parsedId <= 0) {
    erroGlobal.value = 'Identificador de produto inválido.'
    return
  }

  if (loading.value) return
  if (!confirm('Deseja excluir este produto?')) return

  try {
    loading.value = true
    await api.delete(`/stock_items/${parsedId}`)
    await carregarProdutos()
  } catch (error) {
    console.error('Erro ao remover produto:', error)
    erroGlobal.value = 'Não foi possível remover o produto. Operação não autorizada.'
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  document.body.style.overflowY = 'auto'

  const salvo = localStorage.getItem('app_config')
  if (salvo) {
    const config = JSON.parse(salvo)

    if (config.modeloEstoque) {
      modeloEstoque.value = config.modeloEstoque
      if (modeloEstoque.value === 'unico') {
        estoqueAtivoSelecionado.value = 'loja'
      }
    }
  }

  if (modalProdutoRef.value) {
    modalProdutoInstance = new Modal(modalProdutoRef.value)

    modalProdutoRef.value.addEventListener('hidden.bs.modal', () => {
      isEditando.value = false
      formProduto.value = formProdutoPadrao()
    })
  }

  if (modalEntradaEstoqueRef.value) {
    modalEntradaEstoqueInstance = new Modal(modalEntradaEstoqueRef.value)

    modalEntradaEstoqueRef.value.addEventListener('hidden.bs.modal', () => {
      buscaEntradaEstoque.value = ''
      quantidadeEntradaEstoque.value = 1
      itemSelecionadoEntrada.value = null
    })
  }

  await Promise.all([
    carregarProdutos(),
    carregarColaboradores()
  ])
})
</script>

<style scoped>
/* Ajuste de Layout Tela Cheia */
.page-content {
  max-width: 100% !important;
}

/* Efeitos Globais e Animações */
.animate-fade-in {
  animation: fadeIn 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
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
}

.text-gradient {
  background: linear-gradient(135deg, var(--logo-color), #00c6ff);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  font-weight: 800;
}

/* Botões Modernos */
.btn-action-primary {
  background: linear-gradient(135deg, var(--button-bg), var(--button-hover));
  border: none;
  color: white !important;
  box-shadow: 0 4px 12px rgba(13, 110, 253, 0.18);
  border-radius: 50px;
}

.btn-action-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 18px rgba(13, 110, 253, 0.28);
  filter: brightness(1.05);
}

.btn-action-primary:active {
  transform: translateY(0);
}

.btn-action-secondary {
  background: rgba(128, 128, 128, 0.06);
  border: 1px solid var(--card-border);
  color: var(--bs-body-color) !important;
  border-radius: 50px;
}

.btn-action-secondary:hover {
  background: rgba(128, 128, 128, 0.12);
  transform: translateY(-2px);
}

/* Switch de Seleção de Estoque */
.estoque-switch-container {
  background: rgba(var(--bs-body-color-rgb), 0.03);
  min-height: 40px;
}

.select-clean {
  font-size: 0.9rem;
  padding-right: 2.2rem !important;
  background-size: 10px 10px;
}

/* Cards de Alerta de Vidro */
.alert-glass-card {
  background: rgba(var(--bs-body-bg-rgb), 0.4);
  border: 1px solid var(--card-border);
  border-radius: 20px;
  padding: 1.25rem;
  backdrop-filter: blur(12px);
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.border-glow-danger {
  border-color: rgba(220, 53, 69, 0.25);
  box-shadow: 0 10px 30px -15px rgba(220, 53, 69, 0.15);
}

.border-glow-danger:hover {
  border-color: rgba(220, 53, 69, 0.45);
  box-shadow: 0 12px 35px -10px rgba(220, 53, 69, 0.25);
}

.border-glow-warning {
  border-color: rgba(255, 193, 7, 0.25);
  box-shadow: 0 10px 30px -15px rgba(255, 193, 7, 0.15);
}

.border-glow-warning:hover {
  border-color: rgba(255, 193, 7, 0.45);
  box-shadow: 0 12px 35px -10px rgba(255, 193, 7, 0.25);
}

.alert-icon {
  width: 40px;
  height: 40px;
  font-size: 1.15rem;
}

.bg-danger-glow {
  background: rgba(220, 53, 69, 0.12);
  box-shadow: 0 0 15px rgba(220, 53, 69, 0.1);
}

.bg-warning-glow {
  background: rgba(255, 193, 7, 0.12);
  box-shadow: 0 0 15px rgba(255, 193, 7, 0.1);
}

.alert-list {
  display: flex;
  flex-direction: column;
  gap: 0.65rem;
  max-height: 250px;
  overflow-y: auto;
  padding-right: 4px;
}

.alert-list-item {
  border: 1px solid var(--card-border);
  border-radius: 12px;
  padding: 0.75rem 0.9rem;
  background: rgba(var(--bs-body-color-rgb), 0.015);
  transition: all 0.2s ease;
}

.alert-list-item:hover {
  background: rgba(var(--bs-body-color-rgb), 0.03);
  transform: translateX(3px);
}

/* Personalização do Scrollbar nos alertas */
.custom-scroll::-webkit-scrollbar {
  width: 5px;
}
.custom-scroll::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scroll::-webkit-scrollbar-thumb {
  background: rgba(var(--bs-body-color-rgb), 0.15);
  border-radius: 10px;
}
.custom-scroll::-webkit-scrollbar-thumb:hover {
  background: rgba(var(--bs-body-color-rgb), 0.25);
}

/* Card Principal e Tabela */
.admin-card {
  background: var(--glass-bg);
  border: 1px solid var(--card-border);
  border-radius: 24px;
  backdrop-filter: blur(18px);
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.03) !important;
}

.table-glass-card {
  background: rgba(var(--bs-body-bg-rgb), 0.4);
  border: 1px solid var(--card-border);
  border-radius: 20px;
  padding: 1.25rem;
  backdrop-filter: blur(12px);
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.custom-table {
  border-collapse: separate;
  border-spacing: 0 8px;
}

.custom-table th {
  background: transparent;
  font-size: 0.75rem;
  letter-spacing: 0.1em;
  padding: 8px 20px;
  color: var(--bs-secondary-color);
  font-weight: 700;
  border: none;
}

.custom-table td {
  background: rgba(var(--bs-body-color-rgb), 0.015);
  border-top: 1px solid var(--card-border);
  border-bottom: 1px solid var(--card-border);
  padding: 14px 20px;
  vertical-align: middle;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.custom-table td:first-child {
  border-left: 1px solid var(--card-border);
  border-top-left-radius: 12px;
  border-bottom-left-radius: 12px;
}

.custom-table td:last-child {
  border-right: 1px solid var(--card-border);
  border-top-right-radius: 12px;
  border-bottom-right-radius: 12px;
}

.stock-row {
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}

.stock-row:hover td {
  background: rgba(var(--bs-primary-rgb), 0.025) !important;
  border-color: rgba(var(--bs-primary-rgb), 0.2) !important;
}

.stock-row:hover {
  transform: translateY(-1px);
}

/* Badge Glow Moderno */
.badge-glow {
  border-radius: 50px;
  display: inline-flex;
  align-items: center;
  font-weight: 700;
  border: 1px solid transparent;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.02);
}

.badge-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  display: inline-block;
}

.badge-glow-success {
  background: rgba(25, 135, 84, 0.08) !important;
  color: #198754 !important;
  border-color: rgba(25, 135, 84, 0.25) !important;
}
.badge-glow-success .badge-dot {
  background-color: #198754;
  box-shadow: 0 0 8px #198754;
}

.badge-glow-warning {
  background: rgba(255, 193, 7, 0.08) !important;
  color: #f1a80a !important;
  border-color: rgba(255, 193, 7, 0.25) !important;
}
.badge-glow-warning .badge-dot {
  background-color: #f1a80a;
  box-shadow: 0 0 8px #f1a80a;
}

.badge-glow-danger {
  background: rgba(220, 53, 69, 0.08) !important;
  color: #dc3545 !important;
  border-color: rgba(220, 53, 69, 0.25) !important;
}
.badge-glow-danger .badge-dot {
  background-color: #dc3545;
  box-shadow: 0 0 8px #dc3545;
}

.text-warning-custom {
  color: #f1a80a;
}

.text-gradient-success {
  background: linear-gradient(135deg, #198754, #10b981);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* Ações na Tabela */
.btn-action-table {
  width: 36px;
  height: 36px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  border: 1px solid var(--card-border);
  background: rgba(var(--bs-body-color-rgb), 0.03);
  color: var(--bs-secondary-color);
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
}

.btn-action-edit:hover {
  background-color: rgba(var(--bs-primary-rgb), 0.1) !important;
  color: var(--bs-primary) !important;
  border-color: rgba(var(--bs-primary-rgb), 0.3);
  transform: scale(1.1);
}

.btn-action-delete:hover {
  background-color: rgba(220, 53, 69, 0.1) !important;
  color: #dc3545 !important;
  border-color: rgba(220, 53, 69, 0.3);
  transform: scale(1.1);
}

/* Modais de Vidro Premium */
.modal-custom {
  background: rgba(var(--bs-body-bg-rgb), 0.85);
  border: 1px solid var(--card-border);
  border-radius: 28px;
  backdrop-filter: blur(25px);
  color: var(--bs-body-color);
  box-shadow: 0 30px 70px rgba(0, 0, 0, 0.25);
  overflow: hidden;
}

.modal-header {
  border-bottom: 1px solid rgba(var(--bs-body-color-rgb), 0.05) !important;
  padding: 1.5rem 2rem 1.25rem 2rem;
}

.modal-body {
  padding: 1.5rem 2rem;
}

.modal-footer {
  border-top: 1px solid rgba(var(--bs-body-color-rgb), 0.05) !important;
  padding: 1.25rem 2rem 1.5rem 2rem;
}

/* Inputs Elegantes */
.elegant-input-group {
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid var(--card-border);
  background-color: var(--bs-body-bg);
  transition: all 0.25s ease;
}

.elegant-input-group:focus-within {
  border-color: var(--bs-primary);
  box-shadow: 0 0 0 3px rgba(var(--bs-primary-rgb), 0.12) !important;
}

.elegant-input-group .custom-input {
  border: none !important;
  box-shadow: none !important;
}

.custom-input {
  border-radius: 16px;
  padding: 12px 16px;
  border: 1px solid var(--card-border);
  background-color: var(--bs-body-bg);
  color: var(--bs-body-color);
  transition: all 0.25s ease;
  font-weight: 600;
  min-height: 48px;
  box-shadow: none !important;
}

.custom-input:focus {
  border-color: var(--bs-primary);
  box-shadow: 0 0 0 3px rgba(var(--bs-primary-rgb), 0.12) !important;
}

.custom-input:disabled {
  background: rgba(var(--bs-body-color-rgb), 0.04);
  color: var(--bs-secondary-color);
  opacity: 0.85;
}

.disabled-highlight {
  border-style: dashed;
  background: rgba(var(--bs-body-color-rgb), 0.02) !important;
  color: var(--bs-primary) !important;
}

.custom-addon {
  background: rgba(var(--bs-body-color-rgb), 0.03);
  border: none;
  border-right: 1px solid var(--card-border);
  color: var(--bs-secondary-color);
  font-weight: 700;
  padding-left: 15px;
  padding-right: 15px;
}

/* Lista de Itens no Modal Entrada */
.lista-itens-modal {
  background: rgba(var(--bs-body-color-rgb), 0.015);
  border-color: var(--card-border) !important;
  max-height: 280px;
  overflow-y: auto;
  border-radius: 16px;
}

.item-estoque-button {
  width: 100%;
  border: 1px solid var(--card-border);
  background: var(--bs-body-bg);
  border-radius: 14px;
  padding: 0.9rem 1.1rem;
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  color: var(--bs-body-color);
}

.item-estoque-button:hover {
  border-color: var(--bs-primary);
  background: rgba(var(--bs-primary-rgb), 0.05);
  transform: translateY(-1px);
}

.item-estoque-button.active {
  border-color: var(--bs-primary);
  background: rgba(var(--bs-primary-rgb), 0.08);
  box-shadow: inset 3px 0 0 var(--bs-primary);
}

/* Empty States e Loaders */
.loader-glass {
  background: rgba(var(--bs-body-bg-rgb), 0.4);
  border: 1px solid var(--card-border);
  backdrop-filter: blur(8px);
}

.glass-empty-state {
  background: rgba(var(--bs-body-bg-rgb), 0.3);
  border-style: dashed !important;
  border-width: 2px !important;
  border-color: var(--card-border) !important;
  backdrop-filter: blur(8px);
  padding: 3rem 2rem;
}

.empty-state-glow {
  box-shadow: 0 0 30px rgba(var(--bs-primary-rgb), 0.15);
}

.max-width-350 {
  max-width: 350px;
}

/* Utilitários Extras */
.font-11 { font-size: 11px; }
.font-12 { font-size: 12px; }
.font-13 { font-size: 13px; }
.font-14 { font-size: 14px; }
.font-15 { font-size: 15px; }
.fw-extrabold { font-weight: 800; }
.tracking-tight { letter-spacing: -0.02em; }
.tracking-widest { letter-spacing: 0.15em; }

@media (max-width: 767.98px) {
  .dashboard-header {
    padding: 1.25rem !important;
  }

  .small-text-responsive {
    font-size: 0.8rem;
  }

  .admin-card {
    padding: 1rem !important;
    border-radius: 20px;
  }

  .produto-cell {
    min-width: 200px;
  }

  .modal-dialog {
    margin: 0.5rem;
  }

  .modal-footer {
    gap: 0.5rem;
  }

  .modal-footer .btn {
    width: 100%;
  }
}
</style>