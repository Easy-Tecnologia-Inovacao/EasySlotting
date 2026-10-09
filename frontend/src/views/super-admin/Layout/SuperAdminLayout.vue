<template>
  <div :data-bs-theme="store.isDarkMode ? 'dark' : 'light'" class="app-wrapper min-vh-100 d-flex flex-column">
    <nav class="navbar navbar-expand-lg sticky-top shadow-sm py-3 navbar-custom">
      <div class="container-fluid px-lg-5 px-3 d-flex align-items-center">
        <button
          class="btn btn-outline-primary border-0 d-md-none me-2"
          type="button"
          data-bs-toggle="offcanvas"
          data-bs-target="#superAdminSidebarMenu"
          aria-controls="superAdminSidebarMenu"
        >
          <i class="bi bi-list fs-4"></i>
        </button>

        <router-link class="navbar-brand fw-bold fs-3 text-primary m-0" to="/super-admin/dashboard">
          <i class="bi bi-shield-lock-fill me-2 fs-4"></i>EasySloting
        </router-link>

        <div class="ms-auto d-flex align-items-center gap-3">
          <!-- Badge Super Admin -->
          <span class="badge bg-primary bg-opacity-10 text-primary fw-bold px-3 py-2 rounded-pill d-none d-md-inline-flex">
            <i class="bi bi-shield-check me-1"></i> Super Admin
          </span>

          <!-- Dark Mode Toggle -->
          <div class="theme-switch-wrapper">
            <input
              type="checkbox"
              id="superAdminDarkToggle"
              class="visually-hidden"
              v-model="store.isDarkMode"
            >
            <label for="superAdminDarkToggle" class="theme-switch mb-0 shadow-sm">
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
          id="superAdminSidebarMenu"
          tabindex="-1"
          aria-labelledby="superAdminSidebarMenuLabel"
        >
          <div class="offcanvas-header d-md-none p-3 border-bottom">
            <h5 class="offcanvas-title fw-bold text-primary" id="superAdminSidebarMenuLabel">
              <i class="bi bi-shield-lock-fill me-2"></i>Super Admin
            </h5>
            <button
              type="button"
              class="btn-close"
              data-bs-dismiss="offcanvas"
              data-bs-target="#superAdminSidebarMenu"
              aria-label="Close"
            ></button>
          </div>

          <div class="sidebar-header-title px-4 pt-4 pb-2">
            <p class="small text-muted mb-0 fw-bold text-uppercase tracking-wide mb-3">
              Painel Master
            </p>
            <div class="d-flex align-items-center gap-2 pb-3 border-bottom">
              <div class="avatar-circle bg-primary bg-opacity-10 text-primary fw-bold">
                <i class="bi bi-person-fill"></i>
              </div>
              <div class="overflow-hidden">
                <p class="small fw-bold mb-0 text-truncate">{{ userEmail }}</p>
                <p class="x-small text-muted mb-0">Super Administrador</p>
              </div>
            </div>
          </div>

          <div class="offcanvas-body flex-column p-4 pt-2">
            <ul class="nav flex-column nav-admin w-100 gap-1">
              <!-- Dashboard -->
              <li class="nav-item">
                <router-link
                  class="nav-link-sidebar"
                  active-class="active"
                  to="/super-admin/dashboard"
                  @click="closeSidebarOnMobile"
                >
                  <i class="bi bi-speedometer2 me-3"></i>
                  <span>Dashboard</span>
                </router-link>
              </li>

              <!-- Gerenciar Planos -->
              <li class="nav-item">
                <router-link
                  class="nav-link-sidebar"
                  active-class="active"
                  to="/super-admin/planos"
                  @click="closeSidebarOnMobile"
                >
                  <i class="bi bi-stars me-3"></i>
                  <span>Gerenciar Planos</span>
                </router-link>
              </li>

              <!-- Logs de Segurança -->
              <li class="nav-item">
                <router-link
                  class="nav-link-sidebar"
                  active-class="active"
                  to="/super-admin/logs-seguranca"
                  @click="closeSidebarOnMobile"
                >
                  <i class="bi bi-shield-lock me-3"></i>
                  <span>Logs de Segurança</span>
                </router-link>
              </li>

              <!-- Separador + Voltar ao site -->
              <li class="nav-item mt-4 border-top pt-3">
                <button
                  type="button"
                  class="nav-link-sidebar w-100 border-0 bg-transparent text-start"
                  @click="handleGoToSite"
                >
                  <i class="bi bi-house-door me-3"></i>
                  <span>Voltar ao site</span>
                </button>
              </li>

              <!-- Sair (encerra sessão) -->
              <li class="nav-item mt-1">
                <button
                  type="button"
                  class="nav-link-sidebar text-danger hover-danger w-100 border-0 bg-transparent text-start"
                  @click="handleLogout"
                >
                  <i class="bi bi-box-arrow-left me-3"></i>
                  <span>Encerrar sessão</span>
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
  </div>
</template>

<script setup>
import { watch, onMounted, ref, computed } from 'vue'
import { useThemeStore } from '@/stores/themeStore'
import { useRouter } from 'vue-router'
import { api } from '@/services/api'
import { getStaffAccessToken } from '@/services/staffAuth'
import { Offcanvas } from 'bootstrap'

const store  = useThemeStore()
const router = useRouter()
const sidebarRef = ref(null)

// E-mail do usuário logado (exibido no rodapé da sidebar)
const userEmail = computed(() => {
  const raw = localStorage.getItem('user') || sessionStorage.getItem('user')
  if (!raw) return 'super@admin.com'
  try { return JSON.parse(raw)?.email || 'super@admin.com' } catch { return 'super@admin.com' }
})

// ─── Offcanvas helpers ─────────────────────────────────────────────────────────
const resetOffcanvasState = () => {
  document.body.classList.remove('modal-open')
  document.body.style.overflow = ''
  document.body.style.overflowY = ''
  document.body.style.paddingRight = ''
  document.querySelectorAll('.offcanvas-backdrop').forEach((el) => el.remove())
}

const closeSidebarOnMobile = () => {
  if (window.innerWidth < 768 && sidebarRef.value) {
    const instance = Offcanvas.getOrCreateInstance(sidebarRef.value)
    instance.hide()
    setTimeout(() => resetOffcanvasState(), 350)
  }
}

// ─── Theme ────────────────────────────────────────────────────────────────────
onMounted(() => {
  resetOffcanvasState()
  const savedTheme = localStorage.getItem('easysloting_theme')
  store.isDarkMode = savedTheme === 'dark'
  document.documentElement.setAttribute('data-bs-theme', store.isDarkMode ? 'dark' : 'light')
})

watch(
  () => store.isDarkMode,
  (newVal) => {
    const theme = newVal ? 'dark' : 'light'
    document.documentElement.setAttribute('data-bs-theme', theme)
    localStorage.setItem('easysloting_theme', theme)
  },
  { immediate: true }
)

// ─── Navegação ────────────────────────────────────────────────────────────────
// Voltar ao site (landing page) sem encerrar sessão
const handleGoToSite = () => {
  closeSidebarOnMobile()
  router.push('/')
}

// ─── Logout ───────────────────────────────────────────────────────────────────
const clearSession = () => {
  const keys = [
    'access-token', 'client', 'uid', 'user', 'establishment-data', 'site-slug',
    'establishment-permissions', 'salon-config', 'customer-access-token',
    'customer-data', 'customer-slug', 'customer-token-expires', 'customer-csrf-token'
  ]
  keys.forEach((k) => {
    localStorage.removeItem(k)
    sessionStorage.removeItem(k)
  })
}

const logout = async () => {
  const headers = {
    'access-token': getStaffAccessToken() || '',
    'client':       sessionStorage.getItem('client')       || '',
    'uid':          sessionStorage.getItem('uid')          || ''
  }

  try {
    await api.delete('/devise_users/sign_out', { headers })
  } catch (error) {
    // Sessão já inválida — apenas limpa localmente
    console.warn('Logout remoto falhou (sessão já expirada):', error?.response?.status)
  } finally {
    clearSession()
    router.push('/')
  }
}

const handleLogout = async () => {
  closeSidebarOnMobile()
  await logout()
}
</script>

<style scoped>
html {
  scrollbar-gutter: stable;
}

body {
  overflow-x: hidden;
}

.navbar-custom {
  background: #ffffff;
  transition: background 0.3s;
  z-index: 1030;
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

#superAdminDarkToggle:checked + .theme-switch .ball {
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

@media (min-width: 768px) {
  .sidebar {
    height: auto;
    min-height: calc(100vh - 75px);
    z-index: 1020; /* Menor que a navbar (1030) */
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

/* ─── Rodapé da sidebar ─────────────────────────────────────── */
.sidebar-footer {
  flex-shrink: 0;
}

.avatar-circle {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
  flex-shrink: 0;
}

.x-small {
  font-size: 0.72rem;
}
</style>
