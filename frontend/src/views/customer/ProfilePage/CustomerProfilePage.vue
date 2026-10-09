<template>
  <CustomerLayout>
    <div
      class="minha-conta-page"
      :data-bs-theme="store.isDarkMode ? 'dark' : 'light'"
      :style="pageThemeVars"
    >
      <div class="container-fluid px-0">
        <div class="page-header-card mb-4">
          <div class="d-flex justify-content-between align-items-center flex-wrap gap-3">
            <div>
              <span class="section-kicker">Área do cliente</span>
              <h2 class="fw-800 mb-1 dynamic-text">Minha Conta</h2>
              <p class="dynamic-text opacity-75 mb-0">
                Atualize seus dados pessoais e mantenha seu perfil completo.
              </p>
            </div>

            <div class="header-status-badge">
              <i class="bi bi-shield-check me-2"></i>
              Perfil do cliente
            </div>
          </div>
        </div>

        <div class="single-profile-card border-0 shadow-sm rounded-4 p-4 p-lg-5">
          <div class="profile-top-section text-center mb-5">
            <div class="profile-avatar-wrapper mx-auto mb-3">
              <div class="avatar-circle overflow-hidden">
                <img
                  v-if="form.image"
                  :src="buildImageUrl(form.image)"
                  alt="Foto do perfil"
                  class="avatar-image"
                >
                <i v-else class="bi bi-person-fill avatar-icon"></i>
              </div>

              <input
                ref="fileInputRef"
                type="file"
                accept="image/png,image/jpeg,image/jpg,image/webp"
                class="d-none"
                @change="handleImageChange"
              />
            </div>

            <div class="mt-2 mb-3">
              <p class="small text-muted mb-1">Formato quadrado (1:1)</p>
              <p class="small text-muted mb-0">PNG, JPG ou WEBP (Max: 5MB)</p>
            </div>

            <button
              type="button"
              class="btn btn-outline-primary rounded-pill fw-bold px-4 py-2 shadow-sm transition-all hover-lift mb-4"
              @click="triggerFileInput"
              :disabled="uploadingImage || saving"
            >
              <span v-if="uploadingImage" class="spinner-border spinner-border-sm me-2"></span>
              <i v-else class="bi bi-upload me-2"></i>
              {{ uploadingImage ? 'Enviando...' : 'Trocar Foto' }}
            </button>

            <h3 class="fw-bold dynamic-text mb-1">{{ form.name || 'Cliente' }}</h3>
            <p class="dynamic-text opacity-75 mb-0">{{ form.email || '-' }}</p>
          </div>

          <div class="form-header d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
            <div>
              <h5 class="fw-bold dynamic-text mb-1">Dados do perfil</h5>
              <p class="dynamic-text opacity-75 mb-0 small">
                Edite suas informações principais.
              </p>
            </div>

            <span class="form-chip">
              <i class="bi bi-person-vcard me-2"></i>
              Cadastro do cliente
            </span>
          </div>

          <form @submit.prevent="saveProfile">
            <div class="row g-4">
              <div class="col-md-6">
                <label class="form-label custom-label">Nome</label>
                <div class="input-icon-group">
                  <i class="bi bi-person input-icon"></i>
                  <input
                    v-model="form.name"
                    type="text"
                    class="form-control custom-input with-icon"
                    :class="{ 'is-invalid': errors.name }"
                    placeholder="Digite seu nome"
                  />
                  <div class="invalid-feedback" v-if="errors.name">{{ errors.name }}</div>
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label custom-label">E-mail</label>
                <div class="input-icon-group">
                  <i class="bi bi-envelope input-icon"></i>
                  <input
                    v-model="form.email"
                    type="email"
                    class="form-control custom-input with-icon"
                    :class="{ 'is-invalid': errors.email }"
                    placeholder="Digite seu e-mail"
                  />
                  <div class="invalid-feedback" v-if="errors.email">{{ errors.email }}</div>
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label custom-label">Telefone</label>
                <div class="input-icon-group">
                  <i class="bi bi-telephone input-icon"></i>
                  <input
                    v-model="form.phone"
                    type="text"
                    class="form-control custom-input with-icon"
                    :class="{ 'is-invalid': errors.phone }"
                    placeholder="Ex: (11) 3333-4444"
                  />
                  <div class="invalid-feedback" v-if="errors.phone">{{ errors.phone }}</div>
                </div>
              </div>

              <div class="col-md-6">
                <label class="form-label custom-label">Celular</label>
                <div class="input-icon-group">
                  <i class="bi bi-phone input-icon"></i>
                  <input
                    v-model="form.cellphone"
                    type="text"
                    class="form-control custom-input with-icon"
                    :class="{ 'is-invalid': errors.cellphone }"
                    placeholder="Ex: (11) 99999-9999"
                  />
                  <div class="invalid-feedback" v-if="errors.cellphone">{{ errors.cellphone }}</div>
                </div>
              </div>
            </div>

            <div class="form-actions mt-5 d-flex flex-wrap gap-2">
              <button
                type="submit"
                class="btn custom-btn rounded-pill fw-bold px-4 action-btn"
                :disabled="saving"
              >
                <span v-if="saving">
                  <span class="spinner-border spinner-border-sm me-2"></span>
                  Salvando...
                </span>
                <span v-else>
                  <i class="bi bi-check2-circle me-2"></i>
                  Salvar alterações
                </span>
              </button>
            </div>
          </form>
        </div>

        <!-- Seção: Trocar Senha -->
        <div class="single-profile-card border-0 shadow-sm rounded-4 p-4 p-lg-5 mt-4">
          <div class="form-header d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
            <div>
              <h5 class="fw-bold dynamic-text mb-1"><i class="bi bi-lock me-2"></i>Trocar Senha</h5>
              <p class="dynamic-text opacity-75 mb-0 small">
                Altere sua senha para manter sua conta segura.
              </p>
            </div>
            <span class="form-chip">
              <i class="bi bi-shield-lock me-2"></i>Segurança
            </span>
          </div>

          <form @submit.prevent="changePassword">
            <div class="row g-4">
              <div class="col-md-4">
                <label class="form-label custom-label">Senha Atual</label>
                <div class="position-relative">
                  <input
                    v-model="passwordForm.current_password"
                    :type="showCurrentPassword ? 'text' : 'password'"
                    class="form-control custom-input pe-5"
                    placeholder="••••••••"
                    autocomplete="current-password"
                  />
                  <button
                    type="button"
                    class="btn-toggle-password"
                    @click="showCurrentPassword = !showCurrentPassword"
                    :aria-label="showCurrentPassword ? 'Ocultar senha' : 'Exibir senha'"
                    tabindex="-1"
                  >
                    <i :class="showCurrentPassword ? 'bi bi-eye-slash-fill' : 'bi bi-eye-fill'"></i>
                  </button>
                </div>
              </div>
              <div class="col-md-4">
                <label class="form-label custom-label">Nova Senha</label>
                <div class="position-relative">
                  <input
                    v-model="passwordForm.password"
                    :type="showNewPassword ? 'text' : 'password'"
                    class="form-control custom-input pe-5"
                    placeholder="••••••••"
                    autocomplete="new-password"
                    maxlength="72"
                  />
                  <button
                    type="button"
                    class="btn-toggle-password"
                    @click="showNewPassword = !showNewPassword"
                    :aria-label="showNewPassword ? 'Ocultar senha' : 'Exibir senha'"
                    tabindex="-1"
                  >
                    <i :class="showNewPassword ? 'bi bi-eye-slash-fill' : 'bi bi-eye-fill'"></i>
                  </button>
                </div>
                <div class="password-requirements mt-2" v-if="passwordForm.password">
                  <div class="req" :class="{ met: passwordForm.password.length >= 8 }">
                    <i :class="passwordForm.password.length >= 8 ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                    Mínimo 8 caracteres
                  </div>
                  <div class="req" :class="{ met: /[A-Z]/.test(passwordForm.password) }">
                    <i :class="/[A-Z]/.test(passwordForm.password) ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                    Uma letra maiúscula
                  </div>
                  <div class="req" :class="{ met: /[a-z]/.test(passwordForm.password) }">
                    <i :class="/[a-z]/.test(passwordForm.password) ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                    Uma letra minúscula
                  </div>
                  <div class="req" :class="{ met: /[0-9]/.test(passwordForm.password) }">
                    <i :class="/[0-9]/.test(passwordForm.password) ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                    Um número
                  </div>
                  <div class="req" :class="{ met: /[^A-Za-z0-9]/.test(passwordForm.password) }">
                    <i :class="/[^A-Za-z0-9]/.test(passwordForm.password) ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                    Um caractere especial
                  </div>
                </div>
              </div>
              <div class="col-md-4">
                <label class="form-label custom-label">Confirmar Nova Senha</label>
                <div class="position-relative">
                  <input
                    v-model="passwordForm.password_confirmation"
                    :type="showConfirmPassword ? 'text' : 'password'"
                    class="form-control custom-input pe-5"
                    placeholder="••••••••"
                    autocomplete="new-password"
                  />
                  <button
                    type="button"
                    class="btn-toggle-password"
                    @click="showConfirmPassword = !showConfirmPassword"
                    :aria-label="showConfirmPassword ? 'Ocultar senha' : 'Exibir senha'"
                    tabindex="-1"
                  >
                    <i :class="showConfirmPassword ? 'bi bi-eye-slash-fill' : 'bi bi-eye-fill'"></i>
                  </button>
                </div>
                <div v-if="passwordForm.password_confirmation && passwordForm.password !== passwordForm.password_confirmation" class="text-danger small mt-1">
                  <i class="bi bi-exclamation-triangle-fill me-1"></i>As senhas não coincidem
                </div>
              </div>
            </div>

            <div class="form-actions mt-4">
              <button
                type="submit"
                class="btn btn-outline-primary rounded-pill fw-bold px-4"
                :disabled="changingPassword || !isPasswordFormValid"
              >
                <span v-if="changingPassword" class="spinner-border spinner-border-sm me-2"></span>
                {{ changingPassword ? 'Alterando...' : 'Alterar Senha' }}
              </button>
            </div>
          </form>
        </div>

        <!-- Seção: Sessões Recentes -->
        <CustomerSessionsPanel />
        <div class="single-profile-card border-0 shadow-sm rounded-4 p-4 p-lg-5 mt-4">
          <div class="form-header d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
            <div>
              <h5 class="fw-bold dynamic-text mb-1"><i class="bi bi-clock-history me-2"></i>Atividade Recente</h5>
              <p class="dynamic-text opacity-75 mb-0 small">
                Últimos acessos à sua conta.
              </p>
            </div>
            <span class="form-chip">
              <i class="bi bi-eye me-2"></i>Monitoramento
            </span>
          </div>

          <div v-if="loadingSessions" class="text-center py-3">
            <div class="spinner-border spinner-border-sm text-primary"></div>
          </div>

          <div v-else-if="recentSessions.length === 0" class="text-center py-3">
            <p class="dynamic-text opacity-50 mb-0 small">Nenhum acesso registrado.</p>
          </div>

          <div v-else class="table-responsive">
            <table class="table table-sm align-middle mb-0">
              <thead>
                <tr>
                  <th class="small fw-bold text-uppercase text-muted">Ação</th>
                  <th class="small fw-bold text-uppercase text-muted">IP</th>
                  <th class="small fw-bold text-uppercase text-muted">Dispositivo</th>
                  <th class="small fw-bold text-uppercase text-muted">Data</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(session, idx) in recentSessions" :key="idx">
                  <td>
                    <span class="badge rounded-pill" :class="session.action === 'login_success' ? 'text-bg-success' : 'text-bg-danger'">
                      {{ session.action === 'login_success' ? 'Login OK' : 'Falha' }}
                    </span>
                  </td>
                  <td class="small">{{ session.ip || '-' }}</td>
                  <td class="small">{{ session.device || '-' }}</td>
                  <td class="small">{{ formatDateTime(session.created_at) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Seção: Privacidade & Conformidade LGPD -->
        <div class="single-profile-card border-0 shadow-sm rounded-4 p-4 p-lg-5 mt-4">
          <div class="form-header d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
            <div>
              <h5 class="fw-bold dynamic-text mb-1"><i class="bi bi-shield-check me-2 text-success"></i>Privacidade & Direitos LGPD</h5>
              <p class="dynamic-text opacity-75 mb-0 small">
                Transparência e controle sobre seus dados pessoais conforme a Lei Geral de Proteção de Dados (Lei 13.709/2018).
              </p>
            </div>
            <span class="form-chip text-success border-success border-opacity-25 bg-success bg-opacity-10">
              <i class="bi bi-shield-lock-fill me-2"></i>Lei 13.709/2018
            </span>
          </div>

          <div class="row g-4">
            <div class="col-md-6">
              <div class="p-3 rounded-4 h-100 border d-flex flex-column justify-content-between" style="background: var(--bs-tertiary-bg); border-color: var(--card-border) !important;">
                <div>
                  <h6 class="fw-bold dynamic-text mb-1">
                    <i class="bi bi-file-earmark-arrow-down me-2 text-primary"></i>Portabilidade dos Dados (Art. 18, V)
                  </h6>
                  <p class="text-secondary small mb-3">
                    Baixe uma cópia completa de todos os seus dados cadastrais, histórico de atendimentos e pacotes em formato legível (JSON).
                  </p>
                </div>
                <button
                  type="button"
                  class="btn btn-outline-primary rounded-pill fw-bold btn-sm px-3 align-self-start"
                  @click="exportMyData"
                  :disabled="exportingData"
                >
                  <span v-if="exportingData" class="spinner-border spinner-border-sm me-1"></span>
                  <i v-else class="bi bi-download me-1"></i>
                  {{ exportingData ? 'Exportando...' : 'Exportar Meus Dados' }}
                </button>
              </div>
            </div>

            <div class="col-md-6">
              <div class="p-3 rounded-4 h-100 border d-flex flex-column justify-content-between" style="background: var(--bs-tertiary-bg); border-color: var(--card-border) !important;">
                <div>
                  <h6 class="fw-bold dynamic-text mb-1">
                    <i class="bi bi-shield-x me-2 text-warning"></i>Revogação do Consentimento (Art. 8º, §5º)
                  </h6>
                  <p class="text-secondary small mb-3">
                    Você pode revogar a qualquer momento o consentimento para tratamento de dados. Sua conta será desativada e agendamentos cancelados.
                  </p>
                </div>
                <button
                  type="button"
                  class="btn btn-outline-warning rounded-pill fw-bold btn-sm px-3 align-self-start"
                  @click="revokeConsent"
                  :disabled="revokingConsent"
                >
                  <span v-if="revokingConsent" class="spinner-border spinner-border-sm me-1"></span>
                  <i v-else class="bi bi-x-octagon me-1"></i>
                  {{ revokingConsent ? 'Revogando...' : 'Revogar Consentimento' }}
                </button>
              </div>
            </div>
          </div>

          <div class="d-flex align-items-center flex-wrap gap-3 mt-4 pt-3 border-top small" style="border-color: var(--card-border) !important;">
            <span class="text-secondary">Documentos legais da empresa:</span>
            <router-link :to="termsRoute" target="_blank" class="text-primary text-decoration-none fw-semibold">
              <i class="bi bi-file-text me-1"></i>Termos de Uso
            </router-link>
            <span class="text-secondary">•</span>
            <router-link :to="privacyRoute" target="_blank" class="text-primary text-decoration-none fw-semibold">
              <i class="bi bi-shield-check me-1"></i>Política de Privacidade
            </router-link>
          </div>
        </div>

        <!-- Seção: Excluir Conta -->
        <div class="single-profile-card border-0 shadow-sm rounded-4 p-4 p-lg-5 mt-4" style="border-left: 4px solid #dc3545 !important;">
          <div class="form-header d-flex justify-content-between align-items-center flex-wrap gap-2 mb-4">
            <div>
              <h5 class="fw-bold text-danger mb-1"><i class="bi bi-trash me-2"></i>Excluir Conta</h5>
              <p class="dynamic-text opacity-75 mb-0 small">
                Esta ação é irreversível. Seu acesso será encerrado e os dados do seu perfil serão anonimizados.
              </p>
            </div>
            <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25">
              <i class="bi bi-exclamation-triangle me-1"></i>Permanente
            </span>
          </div>

          <div class="p-3 rounded-3 mb-3" style="background: rgba(220,53,69,0.05); border: 1px solid rgba(220,53,69,0.15);">
            <p class="small mb-2"><strong>Ao excluir sua conta, você perderá:</strong></p>
            <ul class="small mb-0" style="color: #6b7280;">
              <li>Agendamentos futuros serão cancelados</li>
              <li>Pacotes mensais ativos serão cancelados</li>
              <li>Você perderá o acesso ao histórico; registros de atendimento e financeiros serão preservados</li>
              <li>Nome, e-mail, telefones e foto do seu perfil serão removidos ou substituídos</li>
              <li>Suas credenciais e dispositivos confiáveis serão invalidados</li>
            </ul>
          </div>

          <div class="row g-3 align-items-end">
            <div class="col-md-6">
              <label class="form-label custom-label text-danger">
                Digite seu e-mail para confirmar: <strong>{{ form.email }}</strong>
              </label>
              <input
                v-model="deleteConfirmEmail"
                type="email"
                class="form-control custom-input"
                :placeholder="form.email"
                autocomplete="off"
                maxlength="254"
              />
            </div>
            <div class="col-md-6">
              <label for="delete-current-password" class="form-label custom-label text-danger">Senha atual</label>
              <input
                id="delete-current-password"
                v-model="deleteCurrentPassword"
                type="password"
                class="form-control custom-input"
                autocomplete="current-password"
                maxlength="128"
              />
            </div>
            <div class="col-12">
              <button
                class="btn btn-danger rounded-pill fw-bold px-4"
                @click="confirmDeleteAccount"
                :disabled="!canDeleteAccount || deletingAccount"
              >
                <span v-if="deletingAccount" class="spinner-border spinner-border-sm me-2"></span>
                {{ deletingAccount ? 'Excluindo...' : 'Excluir Minha Conta' }}
              </button>
            </div>
          </div>
        </div>

        <transition name="fade-up">
          <div
            v-if="message"
            class="alert custom-success-alert mt-4 rounded-4 border-0 shadow-sm d-flex align-items-center gap-2"
          >
            <i class="bi bi-check-circle-fill"></i>
            <span>{{ message }}</span>
          </div>
        </transition>

        <transition name="fade-up">
          <div
            v-if="errorMessage"
            class="alert custom-error-alert mt-4 rounded-4 border-0 shadow-sm d-flex align-items-center gap-2"
          >
            <i class="bi bi-exclamation-triangle-fill"></i>
            <span>{{ errorMessage }}</span>
          </div>
        </transition>
      </div>
    </div>
  </CustomerLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, onMounted, watch } from 'vue'
import { useThemeStore } from '@/stores/themeStore'
import CustomerLayout from '@/views/customer/Layout/CustomerLayout.vue'
import CustomerSessionsPanel from '@/components/CustomerSessionsPanel.vue'
import { api, deleteCustomerAccount } from '@/services/api'
import { getCustomerData, getCustomerSlug, updateCustomerData, getCustomerToken, getCustomerCsrfToken, clearCustomerSession } from '@/services/customerAuth'

const store = useThemeStore()
const message = ref('')
const errorMessage = ref('')
const saving = ref(false)
const fileInputRef = ref<HTMLInputElement | null>(null)
const selectedImageFile = ref<File | null>(null)

// ─── Troca de Senha ─────────────────────────────────────────────────
const showCurrentPassword = ref(false)
const showNewPassword = ref(false)
const showConfirmPassword = ref(false)

const changingPassword = ref(false)
const passwordForm = ref({
  current_password: '',
  password: '',
  password_confirmation: ''
})

const isPasswordFormValid = computed(() => {
  const p = passwordForm.value.password
  const obviousWords = ['admin', 'senha', 'password', '123456', 'easyslotting', 'agendamento', 'barbearia']
  const hasObviousWord = obviousWords.some(w => p.toLowerCase().includes(w))

  return (
    passwordForm.value.current_password.length > 0 &&
    p.length >= 8 &&
    /[A-Z]/.test(p) &&
    /[a-z]/.test(p) &&
    /[0-9]/.test(p) &&
    /[^A-Za-z0-9]/.test(p) &&
    !hasObviousWord &&
    p === passwordForm.value.password_confirmation &&
    p !== passwordForm.value.current_password
  )
})

const changePassword = async () => {
  if (!isPasswordFormValid.value) return

  changingPassword.value = true
  errorMessage.value = ''
  message.value = ''

  try {
    await api.post('/customer/profile/change_password', {
      current_password: passwordForm.value.current_password,
      password: passwordForm.value.password,
      password_confirmation: passwordForm.value.password_confirmation
    })

    message.value = 'Senha alterada com sucesso! Faça login novamente.'
    passwordForm.value = { current_password: '', password: '', password_confirmation: '' }

    const slug = getCustomerSlug() || ''
    clearCustomerSession()
    setTimeout(() => {
      window.location.href = slug ? `/empresa/${slug}/login` : '/cliente/login'
    }, 3000)
  } catch (error: any) {
    const serverMsg = error.response?.data?.error || error.response?.data?.errors?.[0] || 'Erro ao alterar senha.'
    errorMessage.value = serverMsg
    setTimeout(() => (errorMessage.value = ''), 5000)
  } finally {
    changingPassword.value = false
  }
}

// ─── Sessões Recentes ───────────────────────────────────────────────
const recentSessions = ref<any[]>([])
const loadingSessions = ref(false)

const fetchSessions = async () => {
  loadingSessions.value = true
  try {
    const response = await api.get('/customer/profile/sessions')
    recentSessions.value = response.data.sessions || []
  } catch (error) {
    console.error('Erro ao buscar sessões:', error)
  } finally {
    loadingSessions.value = false
  }
}

// ─── Exclusão de Conta ──────────────────────────────────────────────
const deleteConfirmEmail = ref('')
const deleteCurrentPassword = ref('')
const deletingAccount = ref(false)
const canDeleteAccount = computed(() =>
  deleteConfirmEmail.value.trim().toLowerCase() === form.email.trim().toLowerCase() &&
  deleteCurrentPassword.value.length > 0
)

const confirmDeleteAccount = async () => {
  if (!canDeleteAccount.value || deletingAccount.value) return

  if (!window.confirm('Tem certeza absoluta? Esta ação é IRREVERSÍVEL.')) return

  deletingAccount.value = true
  errorMessage.value = ''
  message.value = ''

  try {
    const destination = await deleteCustomerAccount(deleteConfirmEmail.value, deleteCurrentPassword.value)
    window.location.assign(destination)
  } catch (error: any) {
    const serverMsg = error.response?.data?.error || 'Erro ao excluir conta.'
    errorMessage.value = serverMsg
    setTimeout(() => (errorMessage.value = ''), 5000)
  } finally {
    deleteCurrentPassword.value = ''
    deletingAccount.value = false
  }
}

// ─── Direitos LGPD ──────────────────────────────────────────────────
const termsRoute = computed(() => {
  const slug = getCustomerSlug() || ''
  return slug ? `/empresa/${slug}/terms_of_use` : '#'
})

const privacyRoute = computed(() => {
  const slug = getCustomerSlug() || ''
  return slug ? `/empresa/${slug}/privacy_policy` : '#'
})

const exportingData = ref(false)
const exportMyData = async () => {
  exportingData.value = true
  errorMessage.value = ''
  try {
    const res = await api.get('/customer/profile/export')
    const blob = new Blob([JSON.stringify(res.data, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    const safeName = (form.name || 'cliente').toLowerCase().replace(/[^a-z0-9]/g, '_')
    a.download = `meus-dados-lgpd-${safeName}.json`
    a.click()
    URL.revokeObjectURL(url)
    message.value = 'Seus dados foram exportados com sucesso!'
    setTimeout(() => (message.value = ''), 3000)
  } catch (error: any) {
    errorMessage.value = error.response?.data?.error || 'Erro ao exportar dados.'
    setTimeout(() => (errorMessage.value = ''), 4000)
  } finally {
    exportingData.value = false
  }
}

const revokingConsent = ref(false)
const revokeConsent = async () => {
  if (!window.confirm('Atenção: Ao revogar seu consentimento, seus dados serão anonimizados e sua conta será desativada conforme a LGPD. Deseja continuar?')) {
    return
  }

  revokingConsent.value = true
  errorMessage.value = ''
  try {
    await api.patch('/customer/profile/revoke_consent')
    message.value = 'Consentimento revogado. Sua conta foi desativada.'
    setTimeout(() => {
      clearCustomerSession()
      const slug = getCustomerSlug() || ''
      window.location.href = slug ? `/empresa/${slug}` : '/'
    }, 2000)
  } catch (error: any) {
    errorMessage.value = error.response?.data?.error || 'Erro ao revogar consentimento.'
    setTimeout(() => (errorMessage.value = ''), 4000)
  } finally {
    revokingConsent.value = false
  }
}

// ─── Helpers ────────────────────────────────────────────────────────
const formatDateTime = (dateStr: string) => {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  return d.toLocaleString('pt-BR', { timeZone: 'America/Sao_Paulo' })
}

const initialForm = {
  name: '',
  email: '',
  phone: '',
  cellphone: '',
  image: ''
}

const form = reactive({ ...initialForm })

const errors = reactive({
  name: '',
  email: '',
  phone: '',
  cellphone: ''
})

const applyPhoneMask = (value: string) => {
  if (!value) return ''
  let v = value.replace(/\D/g, '')
  if (v.length <= 10) {
    v = v.replace(/^(\d{2})(\d)/g, '($1) $2')
    v = v.replace(/(\d{4})(\d)/, '$1-$2')
  } else {
    v = v.replace(/^(\d{2})(\d)/g, '($1) $2')
    v = v.replace(/(\d{5})(\d)/, '$1-$2')
  }
  return v.substring(0, 15)
}

watch(() => form.phone, (newVal) => {
  form.phone = applyPhoneMask(newVal)
})

watch(() => form.cellphone, (newVal) => {
  form.cellphone = applyPhoneMask(newVal)
})

const validateForm = () => {
  let isValid = true
  errors.name = ''
  errors.email = ''
  errors.phone = ''
  errors.cellphone = ''
  errorMessage.value = ''

  if (!form.name || form.name.trim().length < 2) {
    errors.name = 'O nome deve ter pelo menos 2 caracteres.'
    isValid = false
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!form.email || !emailRegex.test(form.email)) {
    errors.email = 'E-mail inválido.'
    isValid = false
  }

  // Permite vazio, mas se preenchido valida formato aproximado (xx) xxxx-xxxx ou similar numérico
  const phoneRegex = /^\(?\d{2}\)?\s?(?:9\d{4}|\d{4})-?\d{4}$/
  
  if (form.phone && form.phone.trim() !== '' && !phoneRegex.test(form.phone)) {
    errors.phone = 'Telefone inválido. Formato esperado: (99) 9999-9999'
    isValid = false
  }

  if (form.cellphone && form.cellphone.trim() !== '' && !phoneRegex.test(form.cellphone)) {
    errors.cellphone = 'Celular inválido. Formato esperado: (99) 99999-9999'
    isValid = false
  }

  return isValid
}

function getApiBaseUrl() {
  return (api.defaults.baseURL || '').replace(/\/api\/?$/, '')
}

function buildImageUrl(path: string) {
  if (!path) return ''
  if (path.startsWith('http')) return path
  return `${getApiBaseUrl()}${path}`
}

const updateStorage = (updatedCustomer: any) => {
  updateCustomerData(updatedCustomer)
}

const loadUserFromAPI = async () => {
  try {
    const response = await api.get('/customer/profile')
    const customer = response.data.customer

    form.name      = customer.name      || ''
    form.email     = customer.email     || ''
    form.phone     = customer.phone     || ''
    form.cellphone = customer.cellphone || ''
    form.image     = customer.image     || ''

    Object.assign(initialForm, {
      name:      form.name,
      email:     form.email,
      phone:     form.phone,
      cellphone: form.cellphone,
      image:     form.image
    })

    updateStorage(customer)
  } catch (error) {
    console.error('Erro ao carregar perfil:', error)
  }
}

onMounted(() => {
  loadUserFromAPI()
  fetchSessions()
})

const pageThemeVars = computed(() => ({
  '--button-bg': store.themeConfig.buttonBg,
  '--button-hover': store.themeConfig.buttonHover,
  '--icon-color': store.themeConfig.iconColor,
  '--custom-text-color': store.isDarkMode
    ? store.themeConfig.textDark
    : store.themeConfig.textLight,
  '--glass-bg': store.isDarkMode
    ? store.themeConfig.navbarDark
    : store.themeConfig.navbarLight,
  '--bs-tertiary-bg': store.isDarkMode
    ? store.themeConfig.cardDark
    : store.themeConfig.cardLight,
  '--card-border': store.isDarkMode
    ? 'rgba(255,255,255,0.1)'
    : 'rgba(0,0,0,0.08)'
}))

const uploadingImage = ref(false)

const triggerFileInput = () => {
  fileInputRef.value?.click()
}

const handleImageChange = async (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]

  if (!file) return

  // Frontend security best practices: Check file size (5MB max) and file types
  if (file.size > 5 * 1024 * 1024) {
    errorMessage.value = 'A imagem é muito grande. O tamanho máximo permitido é 5MB.'
    setTimeout(() => (errorMessage.value = ''), 4000)
    target.value = ''
    return
  }
  
  const validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
  if (!validTypes.includes(file.type)) {
    errorMessage.value = 'Formato inválido. Envie apenas PNG, JPG ou WEBP.'
    setTimeout(() => (errorMessage.value = ''), 4000)
    target.value = ''
    return
  }

  try {
    uploadingImage.value = true
    const formData = new FormData()
    formData.append('image', file)

    const response = await api.post('/customer/profile/upload_image', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })

    form.image = response.data.image

    const currentCustomer = getCustomerData() || {}
    updateStorage({ ...currentCustomer, image: form.image })

    message.value = 'Foto atualizada com sucesso!'
    setTimeout(() => (message.value = ''), 2500)
  } catch (error: any) {
    console.error(error)
    if (error.response?.data?.errors) {
      errorMessage.value = error.response.data.errors.join(', ')
    } else if (error.response?.data?.error) {
      errorMessage.value = error.response.data.error
    } else {
      errorMessage.value = 'Erro ao enviar imagem'
    }
    setTimeout(() => (errorMessage.value = ''), 4000)
  } finally {
    uploadingImage.value = false
    if (fileInputRef.value) fileInputRef.value.value = ''
  }
}

const saveProfile = async () => {
  if (!validateForm()) return

  saving.value = true
  errorMessage.value = ''

  try {
    const response = await api.put('/customer/profile', {
      customer: {
        name:      form.name,
        email:     form.email,
        phone:     form.phone,
        cellphone: form.cellphone
      }
    })

    const customer = response.data.customer

    const currentCustomer = getCustomerData() || {}
    updateStorage({ ...currentCustomer, ...customer })

    Object.assign(initialForm, {
      name:      customer.name,
      email:     customer.email,
      phone:     customer.phone,
      cellphone: customer.cellphone,
      image:     customer.image
    })

    message.value = 'Perfil atualizado com sucesso!'
    setTimeout(() => (message.value = ''), 2500)
  } catch (error: any) {
    console.error(error)
    if (error.response?.data?.errors) {
      errorMessage.value = error.response.data.errors.join(', ')
    } else {
      errorMessage.value = 'Erro ao salvar perfil. Tente novamente mais tarde.'
    }
    setTimeout(() => (errorMessage.value = ''), 4000)
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
.minha-conta-page {
  background: var(--bs-body-bg);
}

.page-header-card {
  background: rgba(var(--bs-body-bg-rgb, 255, 255, 255), 0.4) !important;
  border: 1px solid var(--card-border) !important;
  backdrop-filter: blur(12px) !important;
  position: relative;
  border-radius: 20px !important;
  padding: 1.5rem 2rem;
  overflow: hidden;
}

.page-header-card::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at top right, rgba(13, 110, 253, 0.08), transparent 70%);
  pointer-events: none;
}

.section-kicker {
  display: inline-block;
  font-size: 0.78rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--button-bg);
  margin-bottom: 0.35rem;
}

.header-status-badge {
  display: inline-flex;
  align-items: center;
  padding: 0.72rem 1rem;
  border-radius: 999px;
  background: color-mix(in srgb, var(--button-bg) 10%, transparent);
  color: var(--button-bg);
  font-weight: 700;
  border: 1px solid color-mix(in srgb, var(--button-bg) 18%, transparent);
}

.single-profile-card {
  background: var(--glass-bg, #ffffff) !important;
  border: 1px solid var(--card-border) !important;
  border-radius: 20px !important;
  backdrop-filter: blur(15px) !important;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06) !important;
}

.profile-top-section {
  padding-bottom: 2rem;
  border-bottom: 1px solid var(--card-border);
}

.profile-avatar-wrapper {
  width: fit-content;
  position: relative;
}

.avatar-circle {
  width: 116px;
  height: 116px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: color-mix(in srgb, var(--icon-color) 14%, transparent);
  color: var(--icon-color);
  border: 4px solid color-mix(in srgb, var(--button-bg) 12%, transparent);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
}

.avatar-icon {
  font-size: 2.4rem;
}

.avatar-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-edit-btn {
  position: absolute;
  right: -2px;
  bottom: 2px;
  width: 38px;
  height: 38px;
  border-radius: 50%;
  border: 0;
  background: var(--button-bg);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
}

.avatar-edit-btn:hover {
  background: var(--button-hover);
}

.form-header {
  padding-top: 2rem;
}

.form-chip {
  display: inline-flex;
  align-items: center;
  padding: 0.5rem 0.85rem;
  border-radius: 999px;
  border: 1px solid var(--card-border);
  background: color-mix(in srgb, var(--bs-body-bg) 55%, transparent);
  color: var(--custom-text-color);
  font-size: 0.82rem;
  font-weight: 700;
}

.custom-label {
  font-size: 0.78rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--custom-text-color);
  opacity: 0.78;
  margin-bottom: 0.55rem;
}

.input-icon-group {
  position: relative;
}

.input-icon {
  position: absolute;
  top: 50%;
  left: 14px;
  transform: translateY(-50%);
  color: var(--icon-color);
  opacity: 0.85;
  pointer-events: none;
}

.custom-input {
  border-radius: 16px;
  padding: 13px 14px;
  background: var(--bs-tertiary-bg);
  color: var(--custom-text-color);
  border: 1.5px solid #d1d5db !important;
  box-shadow: none !important;
}

[data-bs-theme='dark'] .custom-input {
  border-color: rgba(255, 255, 255, 0.15) !important;
}

.custom-input.with-icon {
  padding-left: 2.6rem;
}

.custom-input:focus {
  border-color: color-mix(in srgb, var(--button-bg) 45%, var(--card-border));
  box-shadow: 0 0 0 0.2rem color-mix(in srgb, var(--button-bg) 12%, transparent) !important;
}

.form-actions {
  border-top: 1px solid var(--card-border);
  padding-top: 1.25rem;
}

.action-btn {
  min-width: 220px;
}

.custom-btn {
  background-color: var(--button-bg) !important;
  border-color: var(--button-bg) !important;
  color: #fff !important;
  box-shadow: 0 10px 22px color-mix(in srgb, var(--button-bg) 24%, transparent);
}

.custom-btn:hover {
  background-color: var(--button-hover) !important;
  border-color: var(--button-hover) !important;
}

.custom-success-alert {
  background: color-mix(in srgb, #198754 12%, transparent);
  color: #198754;
}

.custom-error-alert {
  background: color-mix(in srgb, #dc3545 12%, transparent);
  color: #dc3545;
}

.dynamic-text {
  color: var(--custom-text-color) !important;
}

.fade-up-enter-active,
.fade-up-leave-active {
  transition: all 0.25s ease;
}

.fade-up-enter-from,
.fade-up-leave-to {
  opacity: 0;
  transform: translateY(8px);
}

.password-requirements {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.password-requirements .req {
  font-size: 0.75rem;
  color: var(--bs-secondary-color);
  display: flex;
  align-items: center;
  gap: 6px;
  transition: color 0.2s ease;
}

.password-requirements .req.met {
  color: #198754;
}

[data-bs-theme='dark'] .password-requirements .req.met {
  color: #6fcf97;
}

.btn-toggle-password {
  position: absolute;
  right: 14px;
  top: 50%;
  transform: translateY(-50%);
  background: transparent;
  border: none;
  color: var(--custom-text-color);
  opacity: 0.6;
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.15rem;
  transition: opacity 0.2s ease, color 0.2s ease;
  z-index: 5;
}

.btn-toggle-password:hover {
  opacity: 1;
  color: var(--button-bg);
}
</style>
