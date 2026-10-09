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
                <i class="bi bi-people fs-3"></i>
              </div>
              <div>
                <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Gerenciar Equipe</h1>
                <p class="text-muted mb-0 small-text-responsive">Cadastre os profissionais da sua empresa para configurar permissões, serviços e regras financeiras.</p>
              </div>
            </div>
          </div>
        </div>

        <div class="admin-card shadow-sm p-4">
          <div class="d-flex justify-content-between align-items-center mb-4 pb-3 border-bottom flex-wrap gap-3">
            <div class="d-flex align-items-center gap-3">
              <h5 class="fw-bold mb-0 text-body">Profissionais Cadastrados</h5>
              <span class="badge bg-primary rounded-pill px-4 py-2 fs-6 shadow-sm fw-bold">
                {{ colaboradores.length }} Ativos
              </span>
            </div>

            <button
              v-if="canManageTeam"
              class="btn btn-outline-primary rounded-pill fw-bold px-4 py-2 transition-all shadow-sm hover-lift"
              @click="abrirFormulario"
            >
              <i class="bi bi-person-plus-fill me-2"></i>Novo Profissional
            </button>
          </div>

          <div v-if="carregandoLista" class="text-center py-5 text-muted">
            Carregando equipe...
          </div>

          <div v-else-if="colaboradores.length > 0" class="row g-3 mb-2">
            <div class="col-md-6 col-lg-4" v-for="(colab, index) in colaboradores" :key="colab.id ?? colab.user_id ?? index">
              <div class="colab-card card border-0 shadow-sm rounded-4 p-3 bg-body-tertiary h-100 transition-all">
                <div class="d-flex align-items-center justify-content-between gap-3">
                  <div class="d-flex align-items-center gap-3 overflow-hidden">
                    <div class="bg-primary bg-opacity-10 text-primary rounded-circle d-flex align-items-center justify-content-center border border-primary-subtle" style="width: 48px; height: 48px; min-width: 48px;">
                      <i class="bi bi-person-fill fs-4"></i>
                    </div>

                    <div class="overflow-hidden">
                      <h6 class="fw-bold mb-0 text-body text-truncate">{{ colab.nome }}</h6>
                      <span class="badge bg-primary bg-opacity-10 text-primary border border-primary-subtle rounded-pill px-2 py-0.5 mt-1" style="font-size: 0.72rem;">
                        {{ getTipoVinculoNome(colab.tipo_vinculo) }}
                      </span>
                    </div>
                  </div>

                  <div class="d-flex align-items-center gap-1">
                    <button
                      v-if="canManageTeam && isOwnerOrAdmin"
                      class="btn btn-sm btn-light text-primary rounded-circle btn-action shadow-sm"
                      @click="abrirModalPermissoes(index)"
                      title="Permissões"
                    >
                      <i class="bi bi-shield-lock"></i>
                    </button>

                    <button
                      v-if="canManageTeam"
                      class="btn btn-sm btn-light text-success rounded-circle btn-action shadow-sm"
                      @click="editarColaborador(index)"
                      title="Editar"
                    >
                      <i class="bi bi-pencil"></i>
                    </button>

                    <button
                      v-if="canManageTeam"
                      class="btn btn-sm btn-light text-danger rounded-circle btn-delete shadow-sm"
                      @click="removerColaborador(index)"
                      title="Remover"
                    >
                      <i class="bi bi-trash"></i>
                    </button>
                  </div>
                </div>

                <div class="mt-3 pt-3 border-top small text-muted d-flex flex-column gap-1">
                  <div>
                    <strong class="text-body">especialidade:</strong> {{ colab.especialidade || 'Sem especialidade' }}
                  </div>
                  <div>
                    <strong class="text-body">vínculo:</strong> {{ getTipoVinculoNome(colab.tipo_vinculo) }}
                  </div>
                  <div class="text-truncate">
                    <strong class="text-body">email:</strong> {{ colab.email || 'Não informado' }}
                  </div>
                  <div>
                    <strong class="text-body">telefone:</strong> {{ colab.telefone || 'Não informado' }}
                  </div>
                  <div>
                    <strong class="text-body">ganho:</strong>
                    <span v-if="colab.financeiro.modelo === 'porcentagem'" class="ms-1">{{ colab.financeiro.valor }}% sobre faturamento</span>
                    <span v-else-if="colab.financeiro.modelo === 'fixo_servico'" class="ms-1">
                      R$ {{ colab.financeiro.valor }} por atendimento
                      <span v-if="colab.financeiro.bonus_porcentagem && Number(colab.financeiro.bonus_porcentagem) > 0" class="text-primary fw-bold ms-1">
                        (+ {{ colab.financeiro.bonus_porcentagem }}% bônus)
                      </span>
                    </span>
                    <span v-else-if="colab.financeiro.modelo === 'diaria'" class="ms-1">
                      R$ {{ colab.financeiro.valor }} diária
                      <span v-if="colab.financeiro.bonus_porcentagem && Number(colab.financeiro.bonus_porcentagem) > 0" class="text-primary fw-bold ms-1">
                        (+ {{ colab.financeiro.bonus_porcentagem }}% bônus)
                      </span>
                    </span>
                    <span v-else class="ms-1">R$ {{ colab.financeiro.valor }}</span>
                  </div>
                  <div>
                    <strong class="text-body">pix:</strong> {{ colab.financeiro.pix || 'Não informado' }}
                  </div>

                  <!-- 🔥 AQUI -->
                  <div v-if="colab.orphan" class="badge bg-warning text-dark mt-2 align-self-start">
                    Funcionário sem vínculo
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-5 text-muted bg-body-tertiary rounded-4 border border-dashed my-2">
            <div class="bg-secondary bg-opacity-10 rounded-circle d-inline-flex p-4 mb-3">
              <i class="bi bi-people fs-1 opacity-75 text-secondary"></i>
            </div>
            <h5 class="fw-bold text-body">Nenhum profissional</h5>
            <p class="mb-0">Sua equipe está vazia. Clique em "Novo Profissional" para começar.</p>
          </div>
        </div>
      </div>
    </section>

    <div
      class="modal fade"
      id="modalColaborador"
      tabindex="-1"
      aria-hidden="true"
      data-bs-backdrop="static"
      data-bs-keyboard="false"
    >
      <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content border-0 shadow-lg rounded-4">
          <div class="modal-header border-bottom-0 pb-0">
            <h5 class="modal-title fw-bold text-body">
              {{ editandoIndex !== null ? 'Editar Profissional' : 'Novo Profissional' }}
            </h5>

            <button
              type="button"
              class="btn-close shadow-none"
              @click="cancelarFormulario"
            ></button>
          </div>

          <div class="modal-body pt-3">
            <div class="row g-3">
              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Nome completo</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': erros.nome }"
                  placeholder="Ex: João da Silva"
                  :value="novoColaborador.nome"
                  @input="atualizarCampo('nome', formatarNome(($event.target as HTMLInputElement).value))"
                  ref="inputNome"
                  maxlength="100"
                >
                <div v-if="erros.nome" class="invalid-feedback d-block">
                  {{ erros.nome }}
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  O nome completo do profissional que será exibido aos clientes no catálogo de agendamentos.
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">E-mail</label>
                <div style="position: relative;">
                  <input type="password" style="position: absolute; width: 0; height: 0; opacity: 0; border: none; padding: 0; margin: 0;" tabindex="-1" autocomplete="new-password">
                  <input
                    type="email"
                    class="form-control custom-input"
                    :class="{ 'is-invalid': erros.email }"
                    placeholder="joao@email.com"
                    :value="novoColaborador.email"
                    @input="atualizarCampo('email', formatarEmail(($event.target as HTMLInputElement).value))"
                    maxlength="100"
                  >
                </div>
                <div v-if="erros.email" class="invalid-feedback d-block">
                  {{ erros.email }}
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  E-mail utilizado pelo profissional para fazer login no sistema e receber avisos de novos agendamentos.
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Especialidade</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': erros.especialidade }"
                  placeholder="Ex: Barbeiro"
                  :value="novoColaborador.especialidade"
                  @input="atualizarCampo('especialidade', formatarTextoLivre(($event.target as HTMLInputElement).value))"
                  maxlength="80"
                >
                <div v-if="erros.especialidade" class="invalid-feedback d-block">
                  {{ erros.especialidade }}
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  A especialidade do profissional (Ex: Barbeiro, Manicure, Esteticista). Aparece no catálogo.
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Telefone</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': erros.telefone }"
                  placeholder="(47) 99999-9999"
                  :value="novoColaborador.telefone"
                  @input="atualizarCampo('telefone', formatarTelefone(($event.target as HTMLInputElement).value))"
                  maxlength="15"
                >
                <div v-if="erros.telefone" class="invalid-feedback d-block">
                  {{ erros.telefone }}
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  Número de contato do profissional para comunicações internas.
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Tipo de vínculo</label>
                <select
                  class="form-select custom-input"
                  v-model="novoColaborador.tipo_vinculo"
                >
                  <option value="autonomo">Autônomo</option>
                  <option value="mei">MEI (Microempreendedor)</option>
                  <option value="pj">PJ (Pessoa Jurídica)</option>
                  <option value="clt">CLT (Carteira Assinada)</option>
                  <option value="parceiro">Parceiro</option>
                </select>
                <div class="form-text small text-muted mt-1 ps-1">
                  Classificação operacional para controle e documentação de comissões.
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">Tipo de ganho</label>
                <select
                  class="form-select custom-input"
                  :class="{ 'is-invalid': erros.modelo }"
                  v-model="novoColaborador.financeiro.modelo"
                  @change="limparErro('modelo')"
                >
                  <option value="porcentagem">Comissão (%)</option>
                  <option value="fixo_servico">Valor fixo por serviço</option>
                  <option value="diaria">Aluguel / diária</option>
                </select>
                <div v-if="erros.modelo" class="invalid-feedback d-block">
                  {{ erros.modelo }}
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  O modelo de divisão financeira: se recebe comissão percentual, valor fixo ou diária.
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label fw-bold small text-muted">
                  {{ novoColaborador.financeiro.modelo === 'porcentagem' ? 'Comissão (%)' : 'Valor (R$)' }}
                </label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': erros.valor }"
                  :placeholder="novoColaborador.financeiro.modelo === 'porcentagem' ? '50' : '150,00'"
                  :value="novoColaborador.financeiro.valor"
                  @input="atualizarValorFinanceiro(($event.target as HTMLInputElement).value)"
                  maxlength="10"
                >
                <div v-if="erros.valor" class="invalid-feedback d-block">
                  {{ erros.valor }}
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  {{ novoColaborador.financeiro.modelo === 'porcentagem' 
                    ? 'Informe a porcentagem de comissão que o profissional receberá (Ex: 50 para 50%).' 
                    : 'Informe o valor fixo por serviço ou valor do aluguel/diária em reais.' }}
                </div>
              </div>

              <div class="col-md-6" v-if="novoColaborador.financeiro.modelo !== 'porcentagem'">
                <label class="form-label fw-bold small text-muted">
                  Comissão bônus (%) <span class="badge bg-secondary-subtle text-secondary ms-1">Opcional</span>
                </label>
                <input
                  type="text"
                  class="form-control custom-input"
                  placeholder="Ex: 10"
                  :value="novoColaborador.financeiro.bonus_porcentagem"
                  @input="atualizarBonusFinanceiro(($event.target as HTMLInputElement).value)"
                  maxlength="5"
                >
                <div class="form-text small text-muted mt-1 ps-1">
                  Adicione opcionalmente uma comissão extra (%) por atendimento sobre o valor do serviço.
                </div>
              </div>

              <div class="col-md-12">
                <label class="form-label fw-bold small text-muted">Chave PIX (opcional)</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  :class="{ 'is-invalid': erros.pix }"
                  placeholder="CPF, e-mail, telefone ou chave aleatória"
                  :value="novoColaborador.financeiro.pix"
                  @input="atualizarPix(($event.target as HTMLInputElement).value)"
                  autocomplete="new-password"
                  name="colab_pix_input_xr7"
                  readonly
                  @focus="($event.target as HTMLInputElement).removeAttribute('readonly')"
                  @blur="($event.target as HTMLInputElement).setAttribute('readonly', 'true')"
                  data-lpignore="true"
                  data-1p-ignore
                  data-bwignore="true"
                  maxlength="150"
                >
                <div v-if="erros.pix" class="invalid-feedback d-block">
                  {{ erros.pix }}
                </div>
                <div class="form-text small text-muted mt-1 ps-1">
                  A chave Pix do profissional para facilitação de transferências e acertos financeiros.
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer border-top-0 pt-0">
            <button class="btn btn-light rounded-pill px-4 fw-bold border" @click="cancelarFormulario">
              Fechar
            </button>
            <button
              class="btn btn-primary rounded-pill px-4 fw-bold shadow-sm"
              @click="salvarColaborador"
              :disabled="loading"
            >
              {{ loading ? 'Salvando...' : (editandoIndex !== null ? 'Salvar Alterações' : 'Adicionar Profissional') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de Permissões -->
    <div
      class="modal fade"
      id="modalPermissoes"
      tabindex="-1"
      aria-hidden="true"
      data-bs-backdrop="static"
      data-bs-keyboard="false"
    >
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg rounded-4">
          <div class="modal-header border-bottom-0 pb-0">
            <h5 class="modal-title fw-bold text-body">
              <i class="bi bi-shield-lock text-primary me-2"></i> Permissões de Acesso
            </h5>
            <button type="button" class="btn-close shadow-none" @click="cancelarPermissoes"></button>
          </div>

          <div class="modal-body pt-4">
            <p class="text-muted small mb-4">
              Defina exatamente o que <strong>{{ colabPermissoesSelecionado?.nome }}</strong> pode visualizar e configurar nesta empresa.
            </p>

            <div class="d-flex flex-column gap-3">
              <!-- Privacidade -->
              <label class="border rounded-4 p-3 d-flex align-items-start gap-3 cursor-pointer transition-all" :class="permissoesTemporarias.can_view_only_own_clients ? 'border-primary bg-primary bg-opacity-10' : 'bg-body-tertiary'">
                <div class="form-check form-switch mt-1">
                  <input class="form-check-input" type="checkbox" v-model="permissoesTemporarias.can_view_only_own_clients">
                </div>
                <div>
                  <h6 class="fw-bold mb-1 text-body">Privacidade de Clientes</h6>
                  <p class="small text-muted mb-0">Ativo: Visualiza apenas a própria carteira de clientes. Desligado: Vê todos.</p>
                </div>
              </label>

              <!-- Agenda -->
              <label class="border rounded-4 p-3 d-flex align-items-start gap-3 cursor-pointer transition-all" :class="permissoesTemporarias.can_manage_schedule ? 'border-primary bg-primary bg-opacity-10' : 'bg-body-tertiary'">
                <div class="form-check form-switch mt-1">
                  <input class="form-check-input" type="checkbox" v-model="permissoesTemporarias.can_manage_schedule">
                </div>
                <div>
                  <h6 class="fw-bold mb-1 text-body">Gestão da Agenda</h6>
                  <p class="small text-muted mb-0">Permite configurar horários e gerenciar todos os agendamentos da empresa.</p>
                </div>
              </label>

              <!-- Serviços -->
              <label class="border rounded-4 p-3 d-flex align-items-start gap-3 cursor-pointer transition-all" :class="permissoesTemporarias.can_manage_services ? 'border-primary bg-primary bg-opacity-10' : 'bg-body-tertiary'">
                <div class="form-check form-switch mt-1">
                  <input class="form-check-input" type="checkbox" v-model="permissoesTemporarias.can_manage_services">
                </div>
                <div>
                  <h6 class="fw-bold mb-1 text-body">Catálogo de Serviços</h6>
                  <p class="small text-muted mb-0">Permite criar, alterar preços e apagar serviços ou pacotes.</p>
                </div>
              </label>

              <!-- Financeiro -->
              <label class="border rounded-4 p-3 d-flex align-items-start gap-3 cursor-pointer transition-all" :class="permissoesTemporarias.can_manage_financial ? 'border-primary bg-primary bg-opacity-10' : 'bg-body-tertiary'">
                <div class="form-check form-switch mt-1">
                  <input class="form-check-input" type="checkbox" v-model="permissoesTemporarias.can_manage_financial">
                </div>
                <div>
                  <h6 class="fw-bold mb-1 text-body">Acesso Financeiro</h6>
                  <p class="small text-muted mb-0">Permite ver faturamento, relatórios de caixa e todas as comissões.</p>
                </div>
              </label>

              <!-- Equipe -->
              <label class="border rounded-4 p-3 d-flex align-items-start gap-3 cursor-pointer transition-all" :class="permissoesTemporarias.can_manage_team ? 'border-primary bg-primary bg-opacity-10' : 'bg-body-tertiary'">
                <div class="form-check form-switch mt-1">
                  <input class="form-check-input" type="checkbox" v-model="permissoesTemporarias.can_manage_team">
                </div>
                <div>
                  <h6 class="fw-bold mb-1 text-body">Gestão de Equipe</h6>
                  <p class="small text-muted mb-0">Permite adicionar, remover e gerenciar permissões de funcionários.</p>
                </div>
              </label>

              <!-- Estabelecimento e Aparência -->
              <label class="border rounded-4 p-3 d-flex align-items-start gap-3 cursor-pointer transition-all" :class="permissoesTemporarias.can_manage_establishment ? 'border-primary bg-primary bg-opacity-10' : 'bg-body-tertiary'">
                <div class="form-check form-switch mt-1">
                  <input class="form-check-input" type="checkbox" v-model="permissoesTemporarias.can_manage_establishment">
                </div>
                <div>
                  <h6 class="fw-bold mb-1 text-body">Configurações da Empresa</h6>
                  <p class="small text-muted mb-0">Permite alterar os dados do estabelecimento e a aparência do site.</p>
                </div>
              </label>

              <!-- Estoque -->
              <label class="border rounded-4 p-3 d-flex align-items-start gap-3 cursor-pointer transition-all" :class="permissoesTemporarias.can_manage_stock ? 'border-primary bg-primary bg-opacity-10' : 'bg-body-tertiary'">
                <div class="form-check form-switch mt-1">
                  <input class="form-check-input" type="checkbox" v-model="permissoesTemporarias.can_manage_stock">
                </div>
                <div>
                  <h6 class="fw-bold mb-1 text-body">Gestão de Estoque</h6>
                  <p class="small text-muted mb-0">Permite registrar e consumir itens do inventário.</p>
                </div>
              </label>
            </div>
          </div>

          <div class="modal-footer border-top-0 pt-0 mt-2">
            <button class="btn btn-light rounded-pill px-4 fw-bold border" @click="cancelarPermissoes">Cancelar</button>
            <button
              class="btn btn-primary rounded-pill px-4 fw-bold shadow-sm"
              @click="salvarPermissoes"
              :disabled="salvandoPermissoes"
            >
              {{ salvandoPermissoes ? 'Salvando...' : 'Salvar Permissões' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import { nextTick, onMounted, ref, computed } from 'vue'
import { api } from '@/services/api'
import { Modal } from 'bootstrap' 

type ModeloFinanceiro = 'porcentagem' | 'fixo_servico' | 'diaria'
type TipoVinculo = 'clt' | 'mei' | 'pj' | 'autonomo' | 'parceiro'

interface Financeiro {
  modelo: ModeloFinanceiro
  valor: string
  bonus_porcentagem?: string
  pix: string
}

interface Permissoes {
  can_view_only_own_clients: boolean
  can_manage_schedule: boolean
  can_manage_services: boolean
  can_manage_financial: boolean
  can_manage_team: boolean
  can_manage_establishment: boolean
  can_manage_stock: boolean
}

interface Colaborador {
  id: number | null
  user_id?: number | null
  orphan?: boolean
  nome: string
  email: string
  especialidade: string
  telefone: string
  tipo_vinculo: TipoVinculo
  financeiro: Financeiro
  permissoes: Permissoes
}

interface ErrosColaborador {
  nome?: string
  email?: string
  especialidade?: string
  telefone?: string
  modelo?: string
  valor?: string
  pix?: string
}

const loading = ref(false)
const salvandoPermissoes = ref(false)
const carregandoLista = ref(false)
const nomeModeloOperacao = ref('Equipe de Profissionais')
const colaboradores = ref<Colaborador[]>([])

// Dados do usuario e permissoes da sessao (OWASP/LGPD — UI-only, backend sempre valida)
const currentUser = computed(() => {
  try {
    const userStr = localStorage.getItem('user') || sessionStorage.getItem('user')
    return userStr ? JSON.parse(userStr) : null
  } catch {
    return null
  }
})

const isOwnerOrAdmin = computed(() => {
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

const canManageTeam = computed(() => {
  return isOwnerOrAdmin.value || !!permissions.value?.can_manage_team
})

// Campos financeiros/sensiveis editaveis apenas por owner/super_admin ou quem tem can_manage_financial
const canManageFinancial = computed(() => {
  return isOwnerOrAdmin.value || !!permissions.value?.can_manage_financial
})

const editandoIndex = ref<number | null>(null)
const inputNome = ref<HTMLInputElement | null>(null)
const erros = ref<ErrosColaborador>({})
let modalColaborador: Modal | null = null
let modalPermissoesInstance: Modal | null = null

const colabPermissoesSelecionado = ref<Colaborador | null>(null)
const permissoesTemporarias = ref<Permissoes>({
  can_view_only_own_clients: true,
  can_manage_schedule: false,
  can_manage_services: false,
  can_manage_financial: false,
  can_manage_team: false,
  can_manage_establishment: false,
  can_manage_stock: false
})

const colaboradorPadrao = (): Colaborador => ({
  id: null,
  user_id: null,
  nome: '',
  email: '',
  especialidade: '',
  telefone: '',
  tipo_vinculo: 'autonomo',
  financeiro: {
    modelo: 'porcentagem',
    valor: '',
    bonus_porcentagem: '',
    pix: ''
  },
  permissoes: {
    can_view_only_own_clients: true,
    can_manage_schedule: false,
    can_manage_services: false,
    can_manage_financial: false,
    can_manage_team: false,
    can_manage_establishment: false,
    can_manage_stock: false
  }
})

const novoColaborador = ref<Colaborador>(colaboradorPadrao())

onMounted(async () => {
  document.body.style.overflowY = 'auto'

  const salvo = localStorage.getItem('app_config')
  if (salvo) {
    const config = JSON.parse(salvo)

    if (config.modeloAtendimento === 'solo') {
      nomeModeloOperacao.value = 'Profissional Solo'
    } else if (config.modeloAtendimento === 'equipe') {
      nomeModeloOperacao.value = 'Equipe de Profissionais'
    } else {
      nomeModeloOperacao.value = 'Personalizado'
    }
  }

  await carregarEquipe()

  const modalElement = document.getElementById('modalColaborador')
  if (modalElement) {
    modalColaborador = new Modal(modalElement)
  }
  const modalPermissoesEl = document.getElementById('modalPermissoes')
  if (modalPermissoesEl) {
    modalPermissoesInstance = new Modal(modalPermissoesEl)
  }
})

function formatarNome(valor: string): string {
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

function formatarEmail(valor: string): string {
  return valor.trim().toLowerCase()
}

function formatarTelefone(valor: string): string {
  const numeros = valor.replace(/\D/g, '').slice(0, 11)

  if (numeros.length <= 2) return numeros
  if (numeros.length <= 7) return `(${numeros.slice(0, 2)}) ${numeros.slice(2)}`
  return `(${numeros.slice(0, 2)}) ${numeros.slice(2, 7)}-${numeros.slice(7)}`
}

function formatarMoeda(valor: string): string {
  const numeros = valor.replace(/\D/g, '')
  if (!numeros) return ''
  return (parseInt(numeros, 10) / 100).toFixed(2).replace('.', ',')
}

function formatarPorcentagem(valor: string): string {
  const numeros = valor.replace(/\D/g, '').slice(0, 3)
  if (!numeros) return ''

  const numero = parseInt(numeros, 10)
  if (numero > 100) return '100'
  return String(numero)
}

function atualizarCampo(campo: 'nome' | 'email' | 'especialidade' | 'telefone', valor: string): void {
  novoColaborador.value[campo] = valor
  limparErro(campo)
}

// Funções de sanitização e validação de segurança (Anti-XSS sem HTML entity encoding prematuro)
function sanitizeText(text: string): string {
  if (typeof text !== 'string') return ''
  return text
    .replace(/<[^>]*>/g, '')        // Remove tags HTML
    .replace(/[\x00-\x1f\x7f]/g, '') // Remove caracteres de controle
    .trim()
}

function sanitizeEmail(email: string): string {
  if (typeof email !== 'string') return ''
  return email
    .replace(/<[^>]*>/g, '')
    .replace(/[\x00-\x1f\x7f]/g, '')
    .trim()
    .toLowerCase()
}

function sanitizePhone(phone: string): string {
  return phone.replace(/[^\d()\-\s+]/g, '').trim()
}

function sanitizePix(pix: string): string {
  return sanitizeText(pix)
}

function sanitizeFinancialValue(val: string): string {
  return val.replace(/[^\d,.]/g, '').trim()
}

function validateEmail(email: string): boolean {
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
  return emailRegex.test(email)
}

function validatePhone(phone: string): boolean {
  const cleanPhone = phone.replace(/\D/g, '')
  return cleanPhone.length === 10 || cleanPhone.length === 11
}

function validatePix(pix: string): boolean {
  if (!pix) return true
  const clean = pix.trim()
  const isCpf = /^\d{11}$/.test(clean.replace(/\D/g, ''))
  const isPhone = /^\+?55\d{10,11}$/.test(clean.replace(/\D/g, '')) || /^\d{10,11}$/.test(clean.replace(/\D/g, ''))
  const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(clean)
  const isEvp = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(clean)
  return isCpf || isPhone || isEmail || isEvp
}

function atualizarValorFinanceiro(valor: string): void {
  const sanitized = sanitizeFinancialValue(valor)
  if (novoColaborador.value.financeiro.modelo === 'porcentagem') {
    novoColaborador.value.financeiro.valor = formatarPorcentagem(sanitized)
  } else {
    novoColaborador.value.financeiro.valor = formatarMoeda(sanitized)
  }
  limparErro('valor')
}

function atualizarBonusFinanceiro(valor: string): void {
  const sanitized = sanitizeFinancialValue(valor)
  novoColaborador.value.financeiro.bonus_porcentagem = formatarPorcentagem(sanitized)
}

function atualizarPix(valor: string): void {
  novoColaborador.value.financeiro.pix = sanitizePix(valor)
  limparErro('pix')
}

function limparErro(campo: keyof ErrosColaborador): void {
  if (erros.value[campo]) {
    delete erros.value[campo]
    erros.value = { ...erros.value }
  }
}

function emailValido(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

function telefoneValido(telefone: string): boolean {
  return telefone.replace(/\D/g, '').length >= 10
}

function pixValido(valor: string): boolean {
  if (!valor) return true
  return valor.length >= 3
}

function validarFormulario(): boolean {
  erros.value = {}

  const nomeSanitizado = sanitizeText(novoColaborador.value.nome)
  if (!nomeSanitizado || nomeSanitizado.length < 2 || nomeSanitizado.length > 120) {
    erros.value.nome = 'O nome do profissional deve ter entre 2 e 120 caracteres'
  }

  const emailSanitizado = sanitizeEmail(novoColaborador.value.email)
  if (!emailSanitizado) {
    erros.value.email = 'Informe o e-mail'
  } else if (!validateEmail(emailSanitizado)) {
    erros.value.email = 'Informe um e-mail válido'
  }

  const especialidadeSanitizada = sanitizeText(novoColaborador.value.especialidade)
  if (!especialidadeSanitizada || especialidadeSanitizada.length < 2 || especialidadeSanitizada.length > 80) {
    erros.value.especialidade = 'A especialidade deve ter entre 2 e 80 caracteres'
  }

  const telefoneSanitizado = sanitizePhone(novoColaborador.value.telefone)
  if (!telefoneSanitizado) {
    erros.value.telefone = 'Informe o telefone'
  } else if (!validatePhone(telefoneSanitizado)) {
    erros.value.telefone = 'Informe um telefone no formato (XX) XXXXX-XXXX ou (XX) XXXX-XXXX'
  }

  if (!novoColaborador.value.financeiro.modelo) {
    erros.value.modelo = 'Selecione o modelo de ganho'
  }

  const valorSanitizado = sanitizeFinancialValue(novoColaborador.value.financeiro.valor)
  if (!valorSanitizado) {
    erros.value.valor = 'Informe o valor'
  } else {
    const val = Number(valorSanitizado.replace(',', '.'))
    if (isNaN(val) || val < 0 || val > 999999) {
      erros.value.valor = 'Informe um valor financeiro válido'
    } else if (novoColaborador.value.financeiro.modelo === 'porcentagem' && val > 100) {
      erros.value.valor = 'A comissão não pode ser maior que 100%'
    }
  }

  const pixSanitizado = sanitizePix(novoColaborador.value.financeiro.pix)
  if (pixSanitizado && !validatePix(pixSanitizado)) {
    erros.value.pix = 'Informe uma chave PIX válida (CPF, E-mail, Celular ou Chave Aleatória EVP)'
  }

  return Object.keys(erros.value).length === 0
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

function mapApiColaborador(item: any): Colaborador {
  return {
    id: item.id ?? null,
    user_id: item.user_id ?? null,
    orphan: item.orphan ?? false,
    nome: item.name || '',
    email: item.email || '',
    especialidade: item.specialty || 'Sem especialidade',
    telefone: item.phone || '',
    tipo_vinculo: item.financial?.tipo_vinculo || 'autonomo',
    financeiro: {
      modelo: item.financial?.model || 'porcentagem',
      valor: item.financial?.value || '',
      bonus_porcentagem: item.financial?.commission_bonus_percentage || '',
      pix: item.financial?.pix || ''
    },
    permissoes: {
      can_view_only_own_clients: item.permissions?.can_view_only_own_clients ?? true,
      can_manage_schedule: item.permissions?.can_manage_schedule ?? false,
      can_manage_services: item.permissions?.can_manage_services ?? false,
      can_manage_financial: item.permissions?.can_manage_financial ?? false,
      can_manage_team: item.permissions?.can_manage_team ?? false,
      can_manage_establishment: item.permissions?.can_manage_establishment ?? false,
      can_manage_stock: item.permissions?.can_manage_stock ?? false
    }
  }
}

async function carregarEquipe(): Promise<void> {
  try {
    carregandoLista.value = true
    const response = await api.get('/admin/team')

    colaboradores.value = Array.isArray(response.data)
      ? response.data.map(mapApiColaborador)
      : []
  } catch (error: any) {
    alert(
      error?.response?.data?.error ||
      error?.response?.data?.errors?.join(', ') ||
      'Não foi possível carregar a equipe.'
    )
  } finally {
    carregandoLista.value = false
  }
}

async function abrirFormulario(): Promise<void> {
  editandoIndex.value = null
  erros.value = {}
  novoColaborador.value = colaboradorPadrao()

  modalColaborador?.show()

  await nextTick()
  inputNome.value?.focus()
}

function cancelarFormulario(): void {
  editandoIndex.value = null
  erros.value = {}
  novoColaborador.value = colaboradorPadrao()
  modalColaborador?.hide()
}

async function editarColaborador(index: number): Promise<void> {
  const original = colaboradores.value[index]
  if (!original) return

  editandoIndex.value = index
  erros.value = {}
  novoColaborador.value = {
    id: original.id ?? null,
    user_id: original.user_id ?? null,
    nome: original.nome || '',
    email: original.email || '',
    especialidade: original.especialidade || '',
    telefone: original.telefone || '',
    tipo_vinculo: original.tipo_vinculo || 'autonomo',
    financeiro: {
      modelo: original.financeiro.modelo,
      valor: original.financeiro.valor || '',
      bonus_porcentagem: original.financeiro.bonus_porcentagem || '',
      pix: original.financeiro.pix || ''
    },
    permissoes: { ...original.permissoes }
  }

  modalColaborador?.show()

  await nextTick()
  inputNome.value?.focus()
}

async function salvarColaborador(): Promise<void> {
  if (loading.value) return
  if (!validarFormulario()) return

  try {
    loading.value = true

    const payload = {
      employee: {
        name: formatarNome(sanitizeText(novoColaborador.value.nome)),
        email: formatarEmail(sanitizeEmail(novoColaborador.value.email)),
        phone: formatarTelefone(sanitizePhone(novoColaborador.value.telefone)),
        specialty: formatarTextoLivre(sanitizeText(novoColaborador.value.especialidade)),
        tipo_vinculo: novoColaborador.value.tipo_vinculo || 'autonomo',
        financial_model: novoColaborador.value.financeiro.modelo,
        financial_value:
          novoColaborador.value.financeiro.modelo === 'porcentagem'
            ? formatarPorcentagem(novoColaborador.value.financeiro.valor)
            : formatarMoeda(novoColaborador.value.financeiro.valor),
        commission_bonus_percentage:
          novoColaborador.value.financeiro.modelo !== 'porcentagem' && novoColaborador.value.financeiro.bonus_porcentagem
            ? formatarPorcentagem(novoColaborador.value.financeiro.bonus_porcentagem)
            : null,
        pix_key: sanitizePix(novoColaborador.value.financeiro.pix),
        can_view_only_own_clients: !!novoColaborador.value.permissoes.can_view_only_own_clients,
        can_manage_schedule: !!novoColaborador.value.permissoes.can_manage_schedule,
        can_manage_services: !!novoColaborador.value.permissoes.can_manage_services,
        can_manage_financial: !!novoColaborador.value.permissoes.can_manage_financial,
        can_manage_team: !!novoColaborador.value.permissoes.can_manage_team,
        can_manage_establishment: !!novoColaborador.value.permissoes.can_manage_establishment,
        can_manage_stock: !!novoColaborador.value.permissoes.can_manage_stock
      }
    }

    if (editandoIndex.value !== null && novoColaborador.value.id) {
      const response = await api.patch(`/admin/team/${novoColaborador.value.id}`, payload)
      const atualizado = mapApiColaborador(response.data.employee)
      colaboradores.value[editandoIndex.value] = atualizado
      alert(response.data.message || 'Funcionário atualizado com sucesso!')
    } else {
      const response = await api.post('/admin/team', payload)
      const criado = mapApiColaborador(response.data.employee)
      colaboradores.value.unshift(criado)
      // Achado 4.1: A senha temporária não é mais retornada pela API — instrução via e-mail apenas
      alert(response.data.message || 'Funcionário cadastrado com sucesso! A senha temporária foi enviada para o e-mail informado.')
    }

    cancelarFormulario()
  } catch (error: any) {
    console.error('Erro ao salvar colaborador:', error)

    const mensagens =
      error?.response?.data?.errors?.join(', ') ||
      error?.response?.data?.error ||
      'Não foi possível salvar o profissional.'

    alert(mensagens)
  } finally {
    loading.value = false
  }
}

async function removerColaborador(index: number): Promise<void> {
  if (loading.value) return
  const colaborador = colaboradores.value[index]
  if (!colaborador) return

  const confirmado = window.confirm(`Deseja remover ${colaborador.nome}?`)
  if (!confirmado) return

  try {
    loading.value = true

    let response

    // funcionário normal
    if (colaborador.id && !colaborador.orphan) {
      response = await api.delete(`/admin/team/${colaborador.id}`)
    }
    // funcionário órfão
    else if (colaborador.user_id) {
      response = await api.delete(`/admin/team/0`, {
        params: { user_id: colaborador.user_id }
      })
    } else {
      throw new Error('Colaborador inválido para exclusão')
    }

    colaboradores.value.splice(index, 1)

    if (editandoIndex.value === index) {
      cancelarFormulario()
    }

    alert(response.data?.message || 'Funcionário removido com sucesso!')
  } catch (error: any) {
    console.error('Erro ao remover colaborador:', error)
    console.error('STATUS:', error?.response?.status)
    console.error('DATA ERRO:', error?.response?.data)

    const mensagem =
      error?.response?.data?.error ||
      error?.response?.data?.errors?.join(', ') ||
      'Não foi possível remover o profissional.'

    alert(mensagem)
  } finally {
    loading.value = false
  }
}

function abrirModalPermissoes(index: number): void {
  const colab = colaboradores.value[index]
  if (!colab) return

  colabPermissoesSelecionado.value = colab
  permissoesTemporarias.value = { ...colab.permissoes }
  
  modalPermissoesInstance?.show()
}

function cancelarPermissoes(): void {
  colabPermissoesSelecionado.value = null
  modalPermissoesInstance?.hide()
}

async function salvarPermissoes(): Promise<void> {
  if (!colabPermissoesSelecionado.value || !colabPermissoesSelecionado.value.id) return

  try {
    salvandoPermissoes.value = true

    const payload = {
      employee: {
        name: colabPermissoesSelecionado.value.nome,
        email: colabPermissoesSelecionado.value.email,
        phone: colabPermissoesSelecionado.value.telefone,
        specialty: colabPermissoesSelecionado.value.especialidade,
        financial_model: colabPermissoesSelecionado.value.financeiro.modelo,
        financial_value: colabPermissoesSelecionado.value.financeiro.valor,
        pix_key: colabPermissoesSelecionado.value.financeiro.pix,
        can_view_only_own_clients: permissoesTemporarias.value.can_view_only_own_clients,
        can_manage_schedule: permissoesTemporarias.value.can_manage_schedule,
        can_manage_services: permissoesTemporarias.value.can_manage_services,
        can_manage_financial: permissoesTemporarias.value.can_manage_financial,
        can_manage_team: permissoesTemporarias.value.can_manage_team,
        can_manage_establishment: permissoesTemporarias.value.can_manage_establishment,
        can_manage_stock: permissoesTemporarias.value.can_manage_stock
      }
    }

    const response = await api.patch(`/admin/team/${colabPermissoesSelecionado.value.id}`, payload)
    
    // Atualiza o colaborador na lista
    const index = colaboradores.value.findIndex(c => c.id === colabPermissoesSelecionado.value?.id)
    if (index !== -1) {
      colaboradores.value[index] = mapApiColaborador(response.data.employee)
    }

    cancelarPermissoes()
    alert('Permissões atualizadas com sucesso!')
  } catch (error: any) {
    console.error('Erro ao salvar permissões:', error)
    alert(error?.response?.data?.error || 'Não foi possível salvar as permissões.')
  } finally {
    salvandoPermissoes.value = false
  }
}
</script>

<style scoped>
/* Ajuste de Layout Tela Cheia */
.page-content {
  max-width: 100% !important;
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
  border-radius: 24px;
  backdrop-filter: blur(15px);
}

.colab-card {
  background: rgba(var(--bs-body-color-rgb), 0.015) !important;
  border: 1px solid var(--card-border) !important;
  border-radius: 16px !important;
  padding: 1.25rem !important;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1) !important;
}

.colab-card:hover {
  background: rgba(var(--bs-primary-rgb), 0.025) !important;
  border-color: rgba(var(--bs-primary-rgb), 0.2) !important;
  transform: translateY(-3px) !important;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.04) !important;
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

.invalid-feedback {
  font-size: 0.82rem;
  font-weight: 600;
}

.btn-action,
.btn-delete {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0.8;
  transition: all 0.2s;
  border: 1px solid var(--card-border);
}

.btn-delete:hover {
  background-color: var(--bs-danger);
  color: white !important;
}

.btn-action:hover {
  background-color: var(--bs-success);
  color: white !important;
}

.hover-lift:hover {
  transform: translateY(-3px);
}

.border-dashed {
  border-style: dashed !important;
  border-color: var(--card-border) !important;
  border-width: 2px !important;
}

.tracking-wider {
  letter-spacing: 0.05em;
}

.transition-all {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
</style>