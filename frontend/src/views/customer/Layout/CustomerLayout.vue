<template>
  <div
    :data-bs-theme="store.isDarkMode ? 'dark' : 'light'"
    class="app-wrapper min-vh-100 d-flex flex-column"
  >
    <nav class="navbar navbar-expand-lg sticky-top shadow-sm py-3 navbar-custom">
      <div class="container-fluid px-lg-5 px-3 d-flex align-items-center">
        <button
          class="btn btn-outline-primary border-0 d-md-none me-2"
          type="button"
          data-bs-toggle="offcanvas"
          data-bs-target="#clienteSidebarMenu"
          aria-controls="clienteSidebarMenu"
        >
          <i class="bi bi-list fs-4"></i>
        </button>

        <router-link class="navbar-brand fw-bold fs-3 text-primary m-0" :to="siteHomeRoute">
          {{ siteName }}
        </router-link>

        <div class="ms-auto d-flex align-items-center gap-3">
          <!-- Info do usuário (esquerda) -->
          <div class="dropdown">
            <button
              class="btn btn-sm btn-outline-secondary rounded-pill px-3 py-1 d-flex align-items-center gap-2"
              @click="userDropdownOpen = !userDropdownOpen"
              type="button"
            >
              <i class="bi bi-person-circle"></i>
              <span class="d-none d-md-inline small fw-bold">{{ customerName }}</span>
            </button>
            <ul v-show="userDropdownOpen" class="dropdown-menu border-0 shadow-lg mt-2 p-2 show" @click="userDropdownOpen = false" style="left: 0; right: auto;">
              <li>
                <span class="dropdown-item-text small text-muted px-3 py-1">
                  <i class="bi bi-person me-2"></i>{{ customerName }}
                </span>
              </li>
              <li><hr class="dropdown-divider"></li>
              <li>
                <router-link class="dropdown-item small" :to="currentSlug ? `/empresa/${currentSlug}/minha-conta` : '/empresa/minha-conta'">
                  <i class="bi bi-gear me-2"></i>Minha Conta
                </router-link>
              </li>
              <li>
                <button class="dropdown-item small text-danger" @click.stop="logout">
                  <i class="bi bi-box-arrow-left me-2"></i>Sair
                </button>
              </li>
            </ul>
          </div>

          <!-- Notificações (direita) -->
          <div class="dropdown">
            <button
              class="btn btn-notification-custom rounded-circle position-relative border d-flex align-items-center justify-content-center btn-icon"
              data-bs-toggle="dropdown"
              type="button"
              @click="fetchNotifications"
            >
              <i class="bi bi-bell"></i>
              <span
                v-if="unreadCount > 0"
                class="position-absolute top-0 start-100 translate-middle p-1 bg-danger border border-light rounded-circle"
              ></span>
            </button>

            <ul class="dropdown-menu dropdown-menu-end border-0 shadow-lg mt-3 p-2" style="width: 300px; max-height: 400px; overflow-y: auto;">
              <li><h6 class="dropdown-header fw-bold text-body mb-2">Notificações</h6></li>
              
              <li v-if="notifications.length === 0">
                <span class="dropdown-item-text text-muted small text-center py-3 d-block">Nenhuma notificação.</span>
              </li>
              
              <li v-for="notif in notifications" :key="notif.id">
                <div
                  class="dropdown-item small border-bottom py-2 rounded mb-1 d-flex flex-column gap-1"
                  :class="{ 'bg-light-subtle fw-semibold': !notif.read, 'opacity-75': notif.read }"
                  style="cursor: pointer; white-space: normal;"
                  @click="markAsRead(notif)"
                >
                  <div class="d-flex align-items-center justify-content-between">
                    <span class="text-primary fw-bold" style="font-size: 0.85rem;">{{ notif.title }}</span>
                    <span class="text-muted text-xs" style="font-size: 0.7rem;">{{ formatRelativeTime(notif.created_at) }}</span>
                  </div>
                  <p class="mb-0 text-secondary" style="font-size: 0.8rem; line-height: 1.3;">{{ notif.content }}</p>
                </div>
              </li>

              <li v-if="unreadCount > 0" class="mt-2">
                <button class="dropdown-item text-center text-primary small fw-bold py-1" @click="markAllAsRead">
                  Marcar todas como lidas
                </button>
              </li>
            </ul>
          </div>

          <!-- Theme toggle -->
          <div class="theme-switch-wrapper">
            <input
              type="checkbox"
              id="darkToggleCliente"
              class="visually-hidden-check"
              v-model="store.isDarkMode"
            >
            <label for="darkToggleCliente" class="theme-switch mb-0 shadow-sm">
              <div class="ball"></div>
              <i class="bi bi-sun-fill text-warning"></i>
              <i class="bi bi-moon-stars-fill text-secondary opacity-75"></i>
            </label>
          </div>
        </div>
      </div>
    </nav>

    <div class="container-fluid flex-grow-1 p-0">
      <div class="d-flex h-100">
        <nav
          ref="sidebarRef"
          class="sidebar offcanvas-md offcanvas-start shadow-sm"
          id="clienteSidebarMenu"
          tabindex="-1"
          aria-labelledby="clienteSidebarMenuLabel"
        >
          <div class="offcanvas-header d-md-none p-3 border-bottom">
            <h5 class="offcanvas-title fw-bold text-primary" id="clienteSidebarMenuLabel">
              Minha Conta
            </h5>
            <button
              type="button"
              class="btn-close"
              data-bs-dismiss="offcanvas"
              data-bs-target="#clienteSidebarMenu"
              aria-label="Close"
            ></button>
          </div>

          <div class="sidebar-header-title px-4 pt-4 pb-2">
            <p class="small text-muted mb-0 fw-bold text-uppercase tracking-wide">
              Área do Cliente
            </p>
          </div>

          <div class="offcanvas-body flex-column p-4 pt-2">
            <ul class="nav flex-column nav-admin w-100 gap-1 mt-2">
              <li class="nav-item">
                <router-link
                  class="nav-link-sidebar"
                  active-class="active"
                  :to="currentSlug ? `/empresa/${currentSlug}/minha-conta` : '/empresa/minha-conta'"
                  @click="closeSidebarOnMobile"
                >
                  <i class="bi bi-person-circle me-3"></i>
                  <span>Minha conta</span>
                </router-link>
              </li>

              <li class="nav-item">
                <router-link
                  class="nav-link-sidebar"
                  active-class="active"
                  :to="currentSlug ? `/empresa/${currentSlug}/meus-agendamentos` : '/empresa/meus-agendamentos'"
                  @click="closeSidebarOnMobile"
                >
                  <i class="bi bi-calendar-check me-3"></i>
                  <span>Meus agendamentos</span>
                </router-link>
              </li>

              <li class="nav-item">
                <router-link
                  class="nav-link-sidebar"
                  active-class="active"
                  :to="currentSlug ? `/empresa/${currentSlug}/meus-pacotes` : '/empresa/meus-pacotes'"
                  @click="closeSidebarOnMobile"
                >
                  <i class="bi bi-star me-3"></i>
                  <span>Meus Pacotes Mensais</span>
                </router-link>
              </li>

              <li class="nav-item">
                <router-link
                  class="nav-link-sidebar"
                  active-class="active"
                  :to="currentSlug ? `/empresa/${currentSlug}/historico` : '/empresa/historico'"
                  @click="closeSidebarOnMobile"
                >
                  <i class="bi bi-clock-history me-3"></i>
                  <span>Histórico</span>
                </router-link>
              </li>

              <li class="nav-item mt-3 pt-3 border-top">
                <router-link
                  class="nav-link-sidebar"
                  :to="siteHomeRoute"
                  @click="closeSidebarOnMobile"
                >
                  <i class="bi bi-arrow-left-circle me-3"></i>
                  <span>Voltar ao site</span>
                </router-link>
              </li>
            </ul>
          </div>
        </nav>

        <main class="content-area flex-grow-1 px-3 px-md-4 py-4">
          <slot />
        </main>
      </div>
    </div>

    <!-- MODAL OBRIGATÓRIO EXPIRAÇÃO DE SENHA CLIENTE -->
    <div
      class="modal fade"
      id="modalTrocaSenhaObrigatoriaCliente"
      tabindex="-1"
      aria-hidden="true"
      data-bs-backdrop="static"
      data-bs-keyboard="false"
    >
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg rounded-4">
          <div class="modal-header border-bottom-0 pb-0">
            <h5 class="modal-title fw-bold text-body">
              🔒 Sua senha expirou!
            </h5>
          </div>

          <div class="modal-body pt-3">
            <p class="text-muted small mb-4">
              Por motivos de segurança e para garantir a proteção da sua conta e das suas reservas, é obrigatório alterar sua senha a cada 90 dias. Agradecemos a compreensão.
            </p>

            <div class="mb-3">
              <label class="form-label fw-bold small text-muted">Nova senha</label>
              <input
                type="password"
                class="form-control custom-input"
                v-model="passwordForm.password"
                placeholder="Digite sua nova senha"
                autocomplete="new-password"
                maxlength="72"
              >
            </div>

            <!-- Medidor de Força da Senha -->
            <div v-if="passwordForm.password" class="mb-3 px-1">
              <div class="d-flex justify-content-between align-items-center mb-1">
                <span class="small fw-semibold text-muted">Força da Senha:</span>
                <span class="small fw-bold" :class="passwordStrengthLabel.colorClass">
                  {{ passwordStrengthLabel.label }}
                </span>
              </div>
              <div class="progress-bar-container">
                <div 
                  class="progress-bar-fill"
                  :style="{ width: passwordStrengthLabel.percent + '%', background: getStrengthGradient() }"
                ></div>
              </div>
            </div>

            <div class="mb-3">
              <label class="form-label fw-bold small text-muted">Confirmar nova senha</label>
              <input
                type="password"
                class="form-control custom-input"
                v-model="passwordForm.password_confirmation"
                placeholder="Confirme sua nova senha"
              >
            </div>

            <!-- Lista de requisitos da senha -->
            <div class="password-requirements mb-3 p-3 rounded-3 border bg-light-subtle">
              <p class="fw-bold small mb-2 text-body">Sua senha deve atender aos critérios:</p>
              
              <ul class="list-unstyled mb-0 d-flex flex-column gap-2">
                <li class="d-flex align-items-center gap-2 small">
                  <i 
                    class="bi" 
                    :class="passwordRules.hasMinLength ? 'bi-check-circle-fill text-success scale-up' : 'bi-circle text-muted'"
                  ></i>
                  <span :class="{ 'text-success fw-semibold': passwordRules.hasMinLength }">Mínimo de 8 caracteres</span>
                </li>

                <li class="d-flex align-items-center gap-2 small">
                  <i 
                    class="bi" 
                    :class="passwordRules.hasIdealLength ? 'bi-check-circle-fill text-success scale-up' : 'bi-circle text-muted'"
                  ></i>
                  <span :class="{ 'text-success fw-semibold': passwordRules.hasIdealLength }">Ideal: 20+ caracteres (altamente recomendado)</span>
                </li>

                <li class="d-flex align-items-center gap-2 small">
                  <i 
                    class="bi" 
                    :class="passwordRules.hasUppercase ? 'bi-check-circle-fill text-success scale-up' : 'bi-circle text-muted'"
                  ></i>
                  <span :class="{ 'text-success fw-semibold': passwordRules.hasUppercase }">Uma letra maiúscula</span>
                </li>

                <li class="d-flex align-items-center gap-2 small">
                  <i 
                    class="bi" 
                    :class="passwordRules.hasLowercase ? 'bi-check-circle-fill text-success scale-up' : 'bi-circle text-muted'"
                  ></i>
                  <span :class="{ 'text-success fw-semibold': passwordRules.hasLowercase }">Uma letra minúscula</span>
                </li>

                <li class="d-flex align-items-center gap-2 small">
                  <i 
                    class="bi" 
                    :class="passwordRules.hasNumber ? 'bi-check-circle-fill text-success scale-up' : 'bi-circle text-muted'"
                  ></i>
                  <span :class="{ 'text-success fw-semibold': passwordRules.hasNumber }">Um número</span>
                </li>

                <li class="d-flex align-items-center gap-2 small">
                  <i 
                    class="bi" 
                    :class="passwordRules.hasSymbol ? 'bi-check-circle-fill text-success scale-up' : 'bi-circle text-muted'"
                  ></i>
                  <span :class="{ 'text-success fw-semibold': passwordRules.hasSymbol }">Um caractere especial (ex: @, #, $, %)</span>
                </li>

                <li class="d-flex align-items-center gap-2 small">
                  <i 
                    class="bi" 
                    :class="(passwordForm.password && passwordRules.noObviousWords) ? 'bi-check-circle-fill text-success scale-up' : 'bi-circle text-muted'"
                  ></i>
                  <span :class="{ 'text-success fw-semibold': (passwordForm.password && passwordRules.noObviousWords) }">Sem palavras óbvias, partes do nome ou e-mail</span>
                </li>

                <li class="d-flex align-items-center gap-2 small">
                  <i 
                    class="bi" 
                    :class="passwordRules.passwordsMatch ? 'bi-check-circle-fill text-success scale-up' : 'bi-circle text-muted'"
                  ></i>
                  <span :class="{ 'text-success fw-semibold': passwordRules.passwordsMatch }">Confirmação de senha idêntica</span>
                </li>
              </ul>
            </div>

            <div v-if="passwordError" class="alert alert-danger py-2 small mb-0">
              {{ passwordError }}
            </div>
          </div>

          <div class="modal-footer border-top-0 pt-0">
            <button
              class="btn btn-primary rounded-pill px-4 fw-bold shadow-sm"
              @click="salvarNovaSenha"
              :disabled="savingPassword || !isPasswordValid"
            >
              {{ savingPassword ? 'Salvando...' : 'Salvar nova senha' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch, nextTick } from 'vue'
import { useThemeStore } from '@/stores/themeStore'
import { useRouter, useRoute } from 'vue-router'
import { Offcanvas, Modal, Dropdown } from 'bootstrap'
import { getCustomerData, clearCustomerSession } from '@/services/customerAuth'
import { api } from '@/services/api'

const store = useThemeStore()
const router = useRouter()
const route = useRoute()
const sidebarRef = ref<HTMLElement | null>(null)

const customer = ref<any>(null)
const userDropdownOpen = ref(false)

function carregarDadosDoCliente() {
  const raw = localStorage.getItem('customer-data') || sessionStorage.getItem('customer-data')
  if (!raw) {
    customer.value = null
    return
  }
  try {
    customer.value = JSON.parse(raw)
  } catch {
    customer.value = null
  }
}

// Inicializar na leitura
carregarDadosDoCliente()

const customerName = computed(() => customer.value?.name || 'Cliente')
const customerEmail = computed(() => customer.value?.email || 'cliente@email.com')

const currentSlug = computed(() => {
  return String(
    route.params.slug ||
    sessionStorage.getItem('site-slug') ||
    localStorage.getItem('site-slug') ||
    ''
  )
})

const siteName = computed(() => {
  return store.salonConfig?.nome || 'EasySloting'
})

const siteHomeRoute = computed(() => {
  return currentSlug.value ? `/empresa/${currentSlug.value}` : '/'
})

// ─── Notificações ──────────────────────────────────────────────────
const notifications = ref<any[]>([])
const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)

const fetchNotifications = async () => {
  try {
    const response = await api.get('/customer/notifications')
    notifications.value = response.data.notifications || []
  } catch {
    // Ignora erro — notificações são opcionais
  }
}

const markAsRead = async (notif: any) => {
  if (notif.read) return
  try {
    await api.patch(`/customer/notifications/${notif.id}/read`)
    notif.read = true
  } catch {
    // Ignora erro
  }
}

const markAllAsRead = async () => {
  try {
    await api.patch('/customer/notifications/read_all')
    notifications.value.forEach(n => { n.read = true })
  } catch {
    // Ignora erro
  }
}

const formatRelativeTime = (dateStr: string) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  
  if (diffMins < 1) return 'Agora'
  if (diffMins < 60) return `${diffMins}min`
  
  const diffHours = Math.floor(diffMins / 60)
  if (diffHours < 24) return `${diffHours}h`
  
  const diffDays = Math.floor(diffHours / 24)
  if (diffDays === 1) return 'Ontem'
  return `${diffDays}d`
}

const limparBackdropsModal = () => {
  document.body.classList.remove('modal-open')
  document.body.style.overflow = ''
  document.body.style.overflowY = ''
  document.body.style.paddingRight = ''
  document.querySelectorAll('.modal-backdrop').forEach((el) => el.remove())
}

const resetOffcanvasState = () => {
  document.body.classList.remove('modal-open')
  document.body.style.overflow = ''
  document.body.style.overflowY = ''
  document.body.style.paddingRight = ''

  document.querySelectorAll('.offcanvas-backdrop').forEach((el) => el.remove())
  limparBackdropsModal()
}

const closeSidebarOnMobile = () => {
  if (window.innerWidth < 768 && sidebarRef.value) {
    const instance = Offcanvas.getOrCreateInstance(sidebarRef.value)
    instance.hide()

    setTimeout(() => {
      resetOffcanvasState()
    }, 350)
  }
}

const logout = async () => {
  try {
    // Invalida o refresh token no backend
    await api.delete(`/customer_auth/${currentSlug.value}/sign_out`)
  } catch {
    // Ignora erro — limpa local mesmo assim
  }

  // Limpa TODOS os dados da sessão
  clearCustomerSession()

  // Limpa dados do estabelecimento
  localStorage.removeItem('site-slug')
  sessionStorage.removeItem('site-slug')

  // Limpa permissões
  localStorage.removeItem('establishment-permissions')
  sessionStorage.removeItem('establishment-permissions')

  // Limpa dados do customer
  localStorage.removeItem('customer-data')
  sessionStorage.removeItem('customer-data')

  closeSidebarOnMobile()
  router.push(siteHomeRoute.value)
}

// 🔒 Expiração de Senha do Cliente (90 dias)
const savingPassword = ref(false)
const passwordError = ref('')
const passwordForm = ref({
  password: '',
  password_confirmation: ''
})
let modalTrocaSenhaInstance: any = null

function getStoredCustomer() {
  const raw = localStorage.getItem('customer-data') || sessionStorage.getItem('customer-data')
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch {
    return null
  }
}

function updateStoredCustomer(updatedCustomer: any) {
  if (localStorage.getItem('customer-data')) {
    localStorage.setItem('customer-data', JSON.stringify(updatedCustomer))
  }
  if (sessionStorage.getItem('customer-data')) {
    sessionStorage.setItem('customer-data', JSON.stringify(updatedCustomer))
  }
}

const passwordRules = computed(() => {
  const p = passwordForm.value.password || ''
  const hasMinLength = p.length >= 8
  const hasIdealLength = p.length >= 20
  const hasUppercase = /[A-Z]/.test(p)
  const hasLowercase = /[a-z]/.test(p)
  const hasNumber = /[0-9]/.test(p)
  const hasSymbol = /[^A-Za-z0-9]/.test(p)

  // Palavras óbvias
  const obviousWords = ['admin', 'senha', 'password', '123456', 'easysloting', 'agendamento', 'barbearia']
  let noObviousWords = true
  const lowerP = p.toLowerCase()
  for (const word of obviousWords) {
    if (lowerP.includes(word)) {
      noObviousWords = false
    }
  }

  // Verificar se contem partes do email ou nome
  const cust = getStoredCustomer()
  if (cust) {
    if (cust.email) {
      const emailPrefix = cust.email.split('@')[0]
      if (emailPrefix.length >= 4 && lowerP.includes(emailPrefix.toLowerCase())) {
        noObviousWords = false
      }
    }
    if (cust.name) {
      const firstName = cust.name.split(' ')[0]
      if (firstName.length >= 4 && lowerP.includes(firstName.toLowerCase())) {
        noObviousWords = false
      }
    }
  }

  const passwordsMatch = p === passwordForm.value.password_confirmation && passwordForm.value.password_confirmation.length > 0

  return {
    hasMinLength,
    hasIdealLength,
    hasUppercase,
    hasLowercase,
    hasNumber,
    hasSymbol,
    noObviousWords,
    passwordsMatch
  }
})

const passwordStrengthScore = computed(() => {
  const rules = passwordRules.value
  let score = 0
  if (rules.hasMinLength) score++
  if (rules.hasUppercase) score++
  if (rules.hasLowercase) score++
  if (rules.hasNumber) score++
  if (rules.hasSymbol) score++
  if (rules.noObviousWords && (passwordForm.value.password || '').length > 0) score++
  return score
})

const passwordStrengthLabel = computed(() => {
  const p = passwordForm.value.password || ''
  if (p.length === 0) return { label: 'Em branco', colorClass: 'text-muted', percent: 0 }
  
  const score = passwordStrengthScore.value
  const rules = passwordRules.value

  if (score <= 2) {
    return { label: 'Muito Fraca ⛔', colorClass: 'text-danger', percent: 20 }
  } else if (score <= 4) {
    return { label: 'Fraca ⚠️', colorClass: 'text-warning', percent: 45 }
  } else if (score === 5) {
    return { label: 'Média ⚡', colorClass: 'text-info', percent: 70 }
  } else if (score === 6) {
    if (rules.hasIdealLength) {
      return { label: 'Excelente! ✨🔒 (Ideal)', colorClass: 'text-success fw-bold text-glow', percent: 100 }
    }
    return { label: 'Forte 💪', colorClass: 'text-success fw-bold', percent: 85 }
  }
  return { label: 'Em branco', colorClass: 'text-muted', percent: 0 }
})

const isPasswordValid = computed(() => {
  const rules = passwordRules.value
  return (
    rules.hasMinLength &&
    rules.hasUppercase &&
    rules.hasLowercase &&
    rules.hasNumber &&
    rules.hasSymbol &&
    rules.noObviousWords &&
    passwordForm.value.password === passwordForm.value.password_confirmation
  )
})

function getStrengthGradient() {
  const score = passwordStrengthScore.value
  const rules = passwordRules.value
  if (score <= 2) return 'linear-gradient(90deg, #ea4335, #f44336)' // red
  if (score <= 4) return 'linear-gradient(90deg, #fbbc05, #ff9800)' // orange/amber
  if (score === 5) return 'linear-gradient(90deg, #4285f4, #00bcd4)' // cyan/blue
  if (score === 6) {
    if (rules.hasIdealLength) return 'linear-gradient(90deg, #34a853, #4caf50)' // emerald green
    return 'linear-gradient(90deg, #0f9d58, #8bc34a)' // strong green
  }
  return 'transparent'
}

const isExpiredState = computed(() => {
  return customer.value?.password_expired === true
})

async function abrirModalTrocaSenhaSeNecessario() {
  if (!isExpiredState.value) return

  await nextTick()

  const modalElement = document.getElementById('modalTrocaSenhaObrigatoriaCliente')
  if (!modalElement) return

  if (!modalTrocaSenhaInstance) {
    modalTrocaSenhaInstance = Modal.getOrCreateInstance(modalElement)
  }
  modalTrocaSenhaInstance.show()
}

async function salvarNovaSenha() {
  passwordError.value = ''

  if (!isPasswordValid.value) {
    passwordError.value = 'Por favor, atenda a todos os requisitos de segurança da senha antes de prosseguir.'
    return
  }

  try {
    savingPassword.value = true

    await api.post('/customer/profile/change_password', {
      password: passwordForm.value.password,
      password_confirmation: passwordForm.value.password_confirmation
    })

    const cust = getStoredCustomer()
    if (cust) {
      cust.password_expired = false
      updateStoredCustomer(cust)
    }

    modalTrocaSenhaInstance?.hide()
    limparBackdropsModal()

    setTimeout(() => {
      limparBackdropsModal()
    }, 350)

    alert('Sua senha foi alterada com sucesso! Para sua segurança, continue mantendo sua senha atualizada.')
  } catch (error: any) {
    passwordError.value =
      error.response?.data?.errors?.join(', ') ||
      error.response?.data?.error ||
      'Não foi possível alterar sua senha.'
    console.error(error)
  } finally {
    savingPassword.value = false
  }
}

watch(
  () => store.isDarkMode,
  (newVal) => {
    const theme = newVal ? 'dark' : 'light'
    document.documentElement.setAttribute('data-bs-theme', theme)
    localStorage.setItem('easysloting_theme', theme)
  },
  { immediate: true }
)

watch(
  () => route.path,
  async () => {
    carregarDadosDoCliente()
    await abrirModalTrocaSenhaSeNecessario()
  }
)

onMounted(async () => {
  resetOffcanvasState()

  // Fecha dropdown ao clicar fora
  document.addEventListener('click', (e) => {
    const target = e.target as HTMLElement
    if (!target.closest('.dropdown')) {
      userDropdownOpen.value = false
    }
  })

  const savedTheme = localStorage.getItem('easysloting_theme')
  store.isDarkMode = savedTheme === 'dark'

  document.documentElement.setAttribute(
    'data-bs-theme',
    store.isDarkMode ? 'dark' : 'light'
  )

  const slug = currentSlug.value
  if (slug) {
    localStorage.setItem('site-slug', slug)
    
    // Tentativa 1: Cache local
    const cacheKey = `public-establishment-${slug}`
    const cache = localStorage.getItem(cacheKey)
    if (cache) {
      try {
        const empresaCache = JSON.parse(cache)
        store.setSalonConfig(empresaCache)
      } catch (e) {
        // Ignora erro de JSON
      }
    } else {
      // Tentativa 2: Buscar da API se não houver cache para não exibir o mockup
      try {
        const response = await api.get(`/public/establishments/${slug}`)
        if (response.data) {
          store.setSalonConfig({
            nome: response.data.name,
            public_settings: response.data.public_settings
          })
        }
      } catch (e) {
        console.error('Erro ao buscar configuração básica da empresa no layout:', e)
      }
    }
  }

  await abrirModalTrocaSenhaSeNecessario()
})
</script>

<style>
html {
  scrollbar-gutter: stable;
}

body {
  overflow-x: hidden;
}

[data-bs-theme='light'] {
  --glass-bg: #ffffff;
  --card-border: rgba(0, 0, 0, 0.08);
}

[data-bs-theme='dark'] {
  --glass-bg: #212529;
  --card-border: rgba(255, 255, 255, 0.1);
}

.navbar-custom {
  background: #ffffff;
  transition: background 0.3s;
  z-index: 1030;
}

.navbar-custom .dropdown {
  position: relative;
}

.navbar-custom .dropdown-menu {
  z-index: 1050;
  position: absolute;
  right: 0;
}

[data-bs-theme='dark'] .navbar-custom {
  background: #212529;
}

.app-wrapper {
  background-color: var(--bs-body-bg);
  color: var(--bs-body-color);
}

.sidebar {
  background: var(--glass-bg);
  backdrop-filter: blur(15px);
  border-right: 1px solid var(--card-border);
  width: 280px;
  min-width: 280px;
  display: flex;
  flex-direction: column;
  z-index: 1045;
}

.sidebar-header-title {
  flex-shrink: 0;
}

.offcanvas-body {
  flex-grow: 1;
  overflow-y: auto;
}

.content-area {
  min-width: 0;
  flex-grow: 1;
}

.visually-hidden-check {
  position: absolute !important;
  width: 1px !important;
  height: 1px !important;
  padding: 0 !important;
  margin: -1px !important;
  overflow: hidden !important;
  clip: rect(0, 0, 0, 0) !important;
  white-space: nowrap !important;
  border: 0 !important;
}

.visually-hidden {
  position: absolute !important;
  width: 1px !important;
  height: 1px !important;
  padding: 0 !important;
  margin: -1px !important;
  overflow: hidden !important;
  clip: rect(0, 0, 0, 0) !important;
  white-space: nowrap !important;
  border: 0 !important;
}

.theme-switch {
  width: 60px;
  height: 32px;
  background: var(--bs-tertiary-bg);
  border-radius: 50px;
  border: 1px solid var(--card-border);
  position: relative;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-around;
}

.theme-switch .ball {
  width: 24px;
  height: 24px;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  border-radius: 50%;
  position: absolute;
  left: 4px;
  transition: 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 2;
}

#darkToggleCliente:checked + .theme-switch .ball {
  transform: translateX(28px);
}

.btn-icon,
.btn-notification-custom {
  width: 42px;
  height: 42px;
}

.btn-notification-custom {
  background: var(--bs-tertiary-bg);
  color: var(--bs-body-color);
  border-color: var(--card-border) !important;
}

.btn-notification-custom:hover {
  background: var(--bs-secondary-bg);
}

.nav-link-sidebar {
  color: var(--bs-body-color);
  font-weight: 600;
  padding: 12px 16px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  text-decoration: none;
  margin-bottom: 4px;
  transition: background 0.2s;
}

.nav-link-sidebar.active {
  background: rgba(13, 110, 253, 0.1);
  color: var(--bs-primary);
}

.nav-link-sidebar:hover:not(.active) {
  background: rgba(0, 0, 0, 0.03);
}

[data-bs-theme='dark'] .nav-link-sidebar:hover:not(.active) {
  background: rgba(255, 255, 255, 0.05);
}

@media (min-width: 768px) {
  .sidebar {
    position: sticky;
    top: 76px;
    height: calc(100vh - 76px);
  }

  .offcanvas-md.offcanvas-start {
    transform: none !important;
    visibility: visible !important;
  }

  .offcanvas-backdrop {
    display: none !important;
  }
}

@media (max-width: 767.98px) {
  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    max-width: 280px;
    border-right: 1px solid var(--card-border);
  }

  .content-area {
    width: 100%;
  }
}

.custom-input {
  border-radius: 12px;
  padding: 10px 14px;
  border: 1px solid var(--card-border, #e9ecef);
  background-color: var(--bs-body-bg);
  color: var(--bs-body-color);
  transition: all 0.2s;
}

.custom-input:focus {
  border-color: var(--bs-primary);
  box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.15);
}

.progress-bar-container {
  height: 6px;
  border-radius: 10px;
  background-color: var(--card-border);
  overflow: hidden;
  position: relative;
  width: 100%;
}

.progress-bar-fill {
  height: 100%;
  border-radius: 10px;
  width: 0%;
  transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1), background 0.4s ease;
}

.password-requirements {
  background-color: rgba(var(--bs-light-rgb), 0.05);
  transition: all 0.3s ease;
}

.scale-up {
  transform: scale(1.1);
  display: inline-block;
  animation: checkPop 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.text-glow {
  text-shadow: 0 0 10px rgba(52, 168, 83, 0.3);
}

@keyframes checkPop {
  0% { transform: scale(0.5); opacity: 0; }
  100% { transform: scale(1.1); opacity: 1; }
}
</style>