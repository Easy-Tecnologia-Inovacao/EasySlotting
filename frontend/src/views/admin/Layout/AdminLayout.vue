<template>
  <div :data-bs-theme="store.isDarkMode ? 'dark' : 'light'" class="app-wrapper min-vh-100 d-flex flex-column">
    <nav class="navbar navbar-expand-lg sticky-top shadow-sm py-3 navbar-custom">
      <div class="container-fluid px-lg-5 px-3 d-flex align-items-center">
        <button
          class="btn btn-outline-primary border-0 d-md-none me-2"
          type="button"
          data-bs-toggle="offcanvas"
          data-bs-target="#sidebarMenu"
          aria-controls="sidebarMenu"
        >
          <i class="bi bi-list fs-4"></i>
        </button>

        <router-link class="navbar-brand fw-bold fs-3 text-primary m-0" to="/">
          EASYSLOTING
        </router-link>

        <div class="ms-auto d-flex align-items-center gap-4">
          <div class="dropdown">
            <button
              class="btn btn-notification-custom rounded-circle position-relative border d-flex align-items-center justify-content-center btn-icon"
              data-bs-toggle="dropdown"
              @click="carregarNotificacoes"
            >
              <i class="bi bi-bell"></i>
              <span v-if="temNaoLidas" class="position-absolute top-0 start-100 translate-middle p-1 bg-danger border border-light rounded-circle"></span>
            </button>

            <ul class="dropdown-menu dropdown-menu-end border-0 shadow-lg mt-3 p-2" style="width: 300px; max-height: 400px; overflow-y: auto;">
              <li><h6 class="dropdown-header fw-bold text-body mb-2">Notificações</h6></li>
              
              <li v-if="notifications.length === 0">
                <span class="dropdown-item-text text-muted small text-center py-3 d-block">Nenhuma notificação por enquanto.</span>
              </li>
              
              <li v-for="notif in notifications" :key="notif.id">
                <div
                  class="dropdown-item small border-bottom py-2 rounded mb-1 d-flex flex-column gap-1"
                  :class="{ 'bg-light-subtle fw-semibold': !notif.read, 'opacity-75': notif.read }"
                  style="cursor: pointer; white-space: normal;"
                  @click="marcarComoLida(notif)"
                >
                  <div class="d-flex align-items-center justify-content-between">
                    <span class="text-primary fw-bold" style="font-size: 0.85rem;">{{ notif.title }}</span>
                    <span class="text-muted text-xs" style="font-size: 0.7rem;">{{ formatarDataRelativa(notif.created_at) }}</span>
                  </div>
                  <p class="mb-0 text-secondary" style="font-size: 0.8rem; line-height: 1.3;">{{ notif.content }}</p>
                  <span class="text-muted text-xs d-block mt-1" style="font-size: 0.65rem; font-style: italic;">Detalhes completos enviados por e-mail.</span>
                </div>
              </li>

              <li v-if="temNaoLidas" class="mt-2">
                <button class="dropdown-item text-center text-primary small fw-bold py-1" @click="marcarTodasComoLidas">
                  Marcar todas como lidas
                </button>
              </li>
            </ul>
          </div>

          <div class="theme-switch-wrapper">
            <input type="checkbox" id="darkToggle" class="visually-hidden" v-model="store.isDarkMode">
            <label for="darkToggle" class="theme-switch mb-0 shadow-sm">
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
          id="sidebarMenu"
          tabindex="-1"
          aria-labelledby="sidebarMenuLabel"
        >
          <div class="offcanvas-header d-md-none p-3 border-bottom">
            <h5 class="offcanvas-title fw-bold text-primary" id="sidebarMenuLabel">Menu</h5>
            <button
              type="button"
              class="btn-close"
              data-bs-dismiss="offcanvas"
              data-bs-target="#sidebarMenu"
              aria-label="Close"
            ></button>
          </div>

          <div class="sidebar-header-title px-4 pt-4 pb-2">
            <p class="small text-muted mb-0 fw-bold text-uppercase tracking-wide">Portal do Parceiro</p>
          </div>

          <div class="offcanvas-body flex-column p-4 pt-2">
            <ul class="nav flex-column nav-admin w-100 gap-1">
              <li class="nav-item" v-if="user?.role === 'owner' || permissions?.can_manage_establishment">
                <router-link class="nav-link-sidebar" active-class="active" to="/admin/estabelecimento" @click="closeSidebarOnMobile">
                  <i class="bi bi-shop me-3"></i><span>Estabelecimento</span>
                </router-link>
              </li>

              <li class="nav-item" v-if="user?.role === 'owner' || permissions?.can_manage_services">
                <router-link class="nav-link-sidebar" active-class="active" to="/admin/servicos" @click="closeSidebarOnMobile">
                  <i class="bi bi-window-stack me-3"></i><span>Serviços</span>
                </router-link>
              </li>

              <li class="nav-item" v-if="user?.role === 'owner' || permissions?.can_manage_stock">
                <router-link class="nav-link-sidebar" active-class="active" to="/admin/estoque" @click="closeSidebarOnMobile">
                  <i class="bi bi-box-seam me-3"></i><span>Estoque</span>
                </router-link>
              </li>

              <li class="nav-item" v-if="user?.role === 'owner' || permissions?.can_manage_team">
                <router-link class="nav-link-sidebar" active-class="active" to="/admin/equipe" @click="closeSidebarOnMobile">
                  <i class="bi bi-people me-3"></i><span>Equipe</span>
                </router-link>
              </li>

              <li class="nav-item" v-if="user?.role === 'owner' || permissions?.can_manage_schedule">
                <router-link class="nav-link-sidebar" active-class="active" to="/admin/horarios" @click="closeSidebarOnMobile">
                  <i class="bi bi-clock-history me-3"></i><span>Horários</span>
                </router-link>
              </li>

              <li class="nav-item">
                <router-link class="nav-link-sidebar" active-class="active" to="/admin/agendamentos" @click="closeSidebarOnMobile">
                  <i class="bi bi-calendar-check me-3"></i><span>Agendamentos</span>
                </router-link>
              </li>

              <li class="nav-item" v-if="user?.role === 'owner' || permissions?.can_manage_financial">
                <button
                  type="button"
                  class="nav-link-sidebar nav-link-sidebar-collapse w-100 border-0 bg-transparent text-start"
                  :class="{ active: financeiroAberto || isFinanceiroRoute }"
                  @click="toggleFinanceiro"
                >
                  <span class="d-flex align-items-center">
                    <i class="bi bi-wallet2 me-3"></i>
                    <span>Financeiro</span>
                  </span>
                  <i class="bi" :class="financeiroAberto ? 'bi-chevron-up' : 'bi-chevron-down'"></i>
                </button>

                <div v-show="financeiroAberto" class="submenu-wrapper">
                  <router-link
                    class="nav-sublink-sidebar"
                    active-class="active"
                    to="/admin/financeiro/dashboard"
                    @click="closeSidebarOnMobile"
                  >
                    <i class="bi bi-bar-chart-line me-2"></i>
                    <span>Dashboard</span>
                  </router-link>

                  <router-link
                    class="nav-sublink-sidebar"
                    active-class="active"
                    to="/admin/financeiro/relatorios"
                    @click="closeSidebarOnMobile"
                  >
                    <i class="bi bi-file-earmark-text me-2"></i>
                    <span>Relatórios</span>
                  </router-link>

                  <router-link
                    class="nav-sublink-sidebar"
                    active-class="active"
                    to="/admin/financeiro/comissoes"
                    @click="closeSidebarOnMobile"
                  >
                    <i class="bi bi-file-earmark-lock me-2"></i>
                    <span>Fechamento</span>
                  </router-link>

                  <router-link
                    class="nav-sublink-sidebar"
                    active-class="active"
                    to="/admin/financeiro/pacotes"
                    @click="closeSidebarOnMobile"
                  >
                    <i class="bi bi-stars me-2"></i>
                    <span>Pacotes</span>
                  </router-link>

                  <router-link
                    class="nav-sublink-sidebar"
                    active-class="active"
                    to="/admin/financeiro/servicos"
                    @click="closeSidebarOnMobile"
                  >
                    <i class="bi bi-scissors me-2"></i>
                    <span>Serviços</span>
                  </router-link>
                </div>
              </li>

              <li class="nav-item" v-if="user?.role === 'owner'">
                <router-link class="nav-link-sidebar" active-class="active" to="/admin/planos" @click="closeSidebarOnMobile">
                  <i class="bi bi-stars me-3"></i><span>Planos</span>
                </router-link>
              </li>

              <li class="nav-item mt-2 pt-3 border-top" v-if="user?.role === 'owner'">
                <span class="small text-muted fw-bold text-uppercase px-3 d-block tracking-wide mb-1" style="font-size: 0.7rem;">
                  Customização
                </span>
              </li>

              <li class="nav-item" v-if="user?.role === 'owner'">
                <router-link class="nav-link-sidebar" active-class="active" to="/admin/aparencia" @click="closeSidebarOnMobile">
                  <i class="bi bi-palette me-3"></i><span>Aparência</span>
                </router-link>
              </li>

              <li class="nav-item mt-4 border-top pt-3" v-if="user?.role === 'owner'">
                <button
                  type="button"
                  class="nav-link-sidebar text-success w-100 border-0 bg-transparent text-start"
                  @click="handleOpenSite"
                >
                  <i class="bi bi-eye me-3"></i><span>Ver meu site</span>
                </button>
              </li>

              <li class="nav-item">
                <button
                  type="button"
                  class="nav-link-sidebar text-danger hover-danger w-100 border-0 bg-transparent text-start"
                  @click="handleLogout"
                >
                  <i class="bi bi-box-arrow-left me-3"></i><span>Sair do painel</span>
                </button>
              </li>
            </ul>
          </div>
        </nav>

        <main class="content-area flex-grow-1 px-3 px-md-5 py-4">
          <slot />
        </main>
      </div>
    </div>

    <!-- MODAL OBRIGATÓRIO PRIMEIRO ACESSO -->
    <div
      class="modal fade"
      id="modalTrocaSenhaObrigatoria"
      tabindex="-1"
      aria-hidden="true"
      data-bs-backdrop="static"
      data-bs-keyboard="false"
    >
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow-lg rounded-4">
          <div class="modal-header border-bottom-0 pb-0">
            <h5 class="modal-title fw-bold text-body">
              {{ isExpiredState ? '🔒 Sua senha expirou!' : 'Defina sua nova senha' }}
            </h5>
          </div>

          <div class="modal-body pt-3">
            <p class="text-muted small mb-4">
              {{ isExpiredState 
                ? 'Por motivos de segurança e para proteger a integridade dos dados da empresa e do seu próprio acesso, é obrigatório alterar sua senha a cada 90 dias.' 
                : 'Por segurança, no seu primeiro acesso você precisa criar uma nova senha para continuar usando o sistema.' 
              }}
            </p>

            <div class="mb-3">
              <label class="form-label fw-bold small text-muted">Nova senha</label>
              <input
                type="password"
                class="form-control custom-input"
                v-model="passwordForm.password"
                placeholder="Digite sua nova senha"
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
                maxlength="72"
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

<script setup>
import { watch, onMounted, ref, computed, nextTick } from 'vue'
import { useThemeStore } from '@/stores/themeStore'
import { useRouter, useRoute } from 'vue-router'
import { api } from '@/services/api'
import { clearStaffAccessToken, getStaffAccessToken } from '@/services/staffAuth'
import { Offcanvas, Modal } from 'bootstrap'

const store = useThemeStore()
const router = useRouter()
const route = useRoute()
const sidebarRef = ref(null)

const siteSlug = ref(localStorage.getItem('site-slug') || '')
const user = ref(null)
const financeiroAberto = ref(false)
const permissions = ref({})

try {
  const savedUser = localStorage.getItem('user') || sessionStorage.getItem('user')
  user.value = savedUser ? JSON.parse(savedUser) : null
} catch {
  user.value = null
}

// Inicializa permissões imediatamente do cache para evitar flash visual
try {
  const savedPerms = localStorage.getItem('establishment-permissions') || sessionStorage.getItem('establishment-permissions')
  permissions.value = savedPerms ? JSON.parse(savedPerms) : {}
} catch {
  permissions.value = {}
}


const isFinanceiroRoute = computed(() => route.path.startsWith('/admin/financeiro'))

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

const carregarSlug = async () => {
  try {
    const accessToken = getStaffAccessToken()

    const client =
      localStorage.getItem('client') ||
      sessionStorage.getItem('client')

    const uid =
      localStorage.getItem('uid') ||
      sessionStorage.getItem('uid')

    if (!accessToken || !client || !uid) {
      return ''
    }

    const response = await api.get('/admin/establishment')

    const slug =
      response.data?.slug ||
      response.data?.establishment?.slug ||
      ''

    const perm =
      response.data?.permissions ||
      response.data?.establishment?.permissions ||
      {}
    permissions.value = perm
    localStorage.setItem('establishment-permissions', JSON.stringify(perm))
    sessionStorage.setItem('establishment-permissions', JSON.stringify(perm))

    if (slug) {
      siteSlug.value = slug
      localStorage.setItem('site-slug', slug)
    }

    return slug
  } catch (error) {
    console.warn('Erro ao buscar slug:', error?.response?.status || error)

    const slugSalvo = localStorage.getItem('site-slug') || ''
    if (slugSalvo) {
      siteSlug.value = slugSalvo
      return slugSalvo
    }

    return ''
  }
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

const toggleFinanceiro = () => {
  financeiroAberto.value = !financeiroAberto.value
}

const abrirMeuSite = async () => {
  const slugAtual = await carregarSlug()

  if (!slugAtual) {
    alert('Não foi possível carregar o slug do estabelecimento.')
    return
  }

  const routeData = router.resolve({ path: `/empresa/${slugAtual}` })
  window.open(routeData.href, '_blank', 'noopener,noreferrer')
}

const handleOpenSite = async () => {
  closeSidebarOnMobile()
  await abrirMeuSite()
}

const logout = async () => {
  const accessToken = getStaffAccessToken() || ''

  const client =
    localStorage.getItem('client') ||
    sessionStorage.getItem('client') ||
    ''

  const uid =
    localStorage.getItem('uid') ||
    sessionStorage.getItem('uid') ||
    ''

  try {
    await api.delete('/devise_users/sign_out', {
      headers: {
        'access-token': accessToken,
        client,
        uid
      }
    })
  } catch (error) {
    console.error('Erro logout:', error?.response?.data || error)
  } finally {
    // Restaura tokens do localStorage
    localStorage.removeItem('establishment-data')
    clearStaffAccessToken()
    localStorage.removeItem('client')
    localStorage.removeItem('uid')
    localStorage.removeItem('user')
    localStorage.removeItem('role')
    localStorage.removeItem('site-slug')
    localStorage.removeItem('establishment-permissions')
    localStorage.removeItem('salon-config')

    clearStaffAccessToken()
    sessionStorage.removeItem('client')
    sessionStorage.removeItem('uid')
    sessionStorage.removeItem('user')
    sessionStorage.removeItem('role')
    sessionStorage.removeItem('establishment-permissions')

    store.clearSalonConfig()

    router.push('/')
  }
}

const handleLogout = async () => {
  closeSidebarOnMobile()
  await logout()
}

// 🔒 Senha Obrigatória Primeiro Acesso
const savingPassword = ref(false)
const passwordError = ref('')
const passwordForm = ref({
  password: '',
  password_confirmation: ''
})
let modalTrocaSenhaInstance = null

function getStoredUser() {
  const rawUser = localStorage.getItem('user') || sessionStorage.getItem('user')
  if (!rawUser) return null
  try {
    return JSON.parse(rawUser)
  } catch {
    return null
  }
}

function updateStoredUser(updatedUser) {
  if (localStorage.getItem('user')) {
    localStorage.setItem('user', JSON.stringify(updatedUser))
  }
  if (sessionStorage.getItem('user')) {
    sessionStorage.setItem('user', JSON.stringify(updatedUser))
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
  const userObj = getStoredUser()
  if (userObj) {
    if (userObj.email) {
      const emailPrefix = userObj.email.split('@')[0]
      if (emailPrefix.length >= 4 && lowerP.includes(emailPrefix.toLowerCase())) {
        noObviousWords = false
      }
    }
    if (userObj.name) {
      const firstName = userObj.name.split(' ')[0]
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

function shouldForcePasswordChange() {
  const isFirstAccess = route.query.first_access === '1' && user.value?.role === 'employee' && user.value?.allow_password_change === false
  const isExpired = user.value?.password_expired === true
  return isFirstAccess || isExpired
}

const isExpiredState = computed(() => {
  return user.value?.password_expired === true
})

async function abrirModalTrocaSenhaSeNecessario() {
  if (!shouldForcePasswordChange()) return

  await nextTick()

  const modalElement = document.getElementById('modalTrocaSenhaObrigatoria')
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

    await api.patch('/me/change_password', {
      password: passwordForm.value.password,
      password_confirmation: passwordForm.value.password_confirmation
    })

    const userObj = getStoredUser()
    if (userObj) {
      userObj.allow_password_change = true
      userObj.password_expired = false
      updateStoredUser(userObj)
    }

    modalTrocaSenhaInstance?.hide()
    limparBackdropsModal()

    setTimeout(() => {
      limparBackdropsModal()
    }, 350)

    alert('Senha alterada com sucesso! Agora você já pode usar o sistema normalmente.')
  } catch (error) {
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
  async (newPath) => {
    if (newPath.startsWith('/admin/financeiro')) {
      financeiroAberto.value = true
    }

    const saved = localStorage.getItem('user') || sessionStorage.getItem('user')
    user.value = saved ? JSON.parse(saved) : null
    await abrirModalTrocaSenhaSeNecessario()
  }
)

const notifications = ref([])

const temNaoLidas = computed(() => {
  return notifications.value.some(n => !n.read)
})

const carregarNotificacoes = async () => {
  try {
    const response = await api.get('/admin/notifications')
    notifications.value = response.data || []
  } catch (error) {
    console.warn('Erro ao carregar notificações:', error)
  }
}

const marcarComoLida = async (notif) => {
  if (notif.read) return
  try {
    await api.patch(`/admin/notifications/${notif.id}/read`)
    notif.read = true
  } catch (error) {
    console.error('Erro ao marcar notificação como lida:', error)
  }
}

const marcarTodasComoLidas = async () => {
  try {
    await api.patch('/admin/notifications/read_all')
    notifications.value.forEach(n => {
      n.read = true
    })
  } catch (error) {
    console.error('Erro ao marcar todas notificações como lidas:', error)
  }
}

const formatarDataRelativa = (dateStr) => {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now - date
  const diffMins = Math.floor(diffMs / 60000)
  
  if (diffMins < 1) return 'Agora mesmo'
  if (diffMins < 60) return `Há ${diffMins} min`
  
  const diffHours = Math.floor(diffMins / 60)
  if (diffHours < 24) return `Há ${diffHours} h`
  
  const diffDays = Math.floor(diffHours / 24)
  if (diffDays === 1) return 'Ontem'
  return `Há ${diffDays} dias`
}

onMounted(async () => {
  resetOffcanvasState()

  const savedTheme = localStorage.getItem('easysloting_theme')
  store.isDarkMode = savedTheme === 'dark'

  document.documentElement.setAttribute(
    'data-bs-theme',
    store.isDarkMode ? 'dark' : 'light'
  )

  if (isFinanceiroRoute.value) {
    financeiroAberto.value = true
  }

  const slugSalvo = localStorage.getItem('site-slug') || ''
  if (slugSalvo) {
    siteSlug.value = slugSalvo
  }
  
  await carregarSlug()
  await abrirModalTrocaSenhaSeNecessario()
  await carregarNotificacoes()
})
</script>

<style>
html {
  scrollbar-gutter: stable;
}

body {
  overflow-x: hidden;
}

.navbar-custom {
  background: #ffffff;
  transition: background 0.3s;
  z-index: 1040 !important;
}

[data-bs-theme="dark"] .navbar-custom {
  background: #212529;
}

[data-bs-theme="light"] {
  --glass-bg: #ffffff;
  --card-border: rgba(0, 0, 0, 0.08);
}

[data-bs-theme="dark"] {
  --glass-bg: #212529;
  --card-border: rgba(255, 255, 255, 0.1);
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

/* Scrollbar customizado para a sidebar para ficar visível */
.offcanvas-body::-webkit-scrollbar {
  width: 6px;
}
.offcanvas-body::-webkit-scrollbar-track {
  background: transparent;
}
.offcanvas-body::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.15);
  border-radius: 10px;
}
[data-bs-theme="dark"] .offcanvas-body::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.15);
}
.offcanvas-body::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.3);
}
[data-bs-theme="dark"] .offcanvas-body::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.3);
}

.content-area {
  min-width: 0;
  flex-grow: 1;
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

#darkToggle:checked + .theme-switch .ball {
  transform: translateX(28px);
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

[data-bs-theme="dark"] .nav-link-sidebar:hover:not(.active) {
  background: rgba(255, 255, 255, 0.05);
}

.nav-link-sidebar-collapse {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.submenu-wrapper {
  padding-left: 0.85rem;
  margin: 0.35rem 0 0.5rem 1rem;
  border-left: 2px solid var(--card-border);
}

.nav-sublink-sidebar {
  color: var(--bs-secondary-color);
  font-weight: 600;
  padding: 10px 14px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  text-decoration: none;
  margin: 4px 0;
  font-size: 0.92rem;
}

.nav-sublink-sidebar:hover {
  background: rgba(13, 110, 253, 0.06);
  color: var(--bs-primary);
}

.nav-sublink-sidebar.active {
  background: rgba(13, 110, 253, 0.14);
  color: var(--bs-primary);
  font-weight: 700;
}

.nav-sublink-sidebar.active i {
  color: var(--bs-primary);
}

@media (min-width: 768px) {
  .sidebar {
    height: auto;
    min-height: calc(100vh - 76px);
    z-index: 1020;
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
</style>

<style>
.page-shell {
  width: 100%;
  min-width: 100%;
  max-width: 100%;
  display: block;
}
.page-content {
  padding: 2rem;
  width: 100%;
  max-width: 1400px;
  margin: 0 auto;
}
@media (max-width: 767.98px) {
  .page-content {
    padding: 1rem;
  }
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  flex-wrap: wrap;
  border-bottom: 1px solid var(--card-border);
  padding-bottom: 1rem;
}

.admin-card {
  background: var(--glass-bg, #ffffff);
  border: 1px solid var(--card-border, #e9ecef);
  border-radius: 22px;
  padding: 1.5rem;
  backdrop-filter: blur(15px);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
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

/* Estilos do Medidor de Senha Premium */
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
