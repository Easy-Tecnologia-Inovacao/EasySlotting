import { createRouter, createWebHistory } from 'vue-router'
import { isCustomerLoggedIn, getCustomerSlug } from '@/services/customerAuth'
import { getStaffAccessToken } from '@/services/staffAuth'

// MAIN SISTEMA (LANDING)
import LandingPage from '@/views/landing/LandingPage/LandingPage.vue'
import SignUpPage from '@/views/landing/SignUpPage/SignUpPage.vue'
import LoginPage from '@/views/landing/LoginPage/LoginPage.vue'
import ForgotPasswordPage from '@/views/landing/ForgotPasswordPage/ForgotPasswordPage.vue'
import ResetPasswordPage from '@/views/landing/ResetPasswordPage/ResetPasswordPage.vue'
import CustomerForgotPasswordPage from '@/views/landing/CustomerForgotPasswordPage/CustomerForgotPasswordPage.vue'
import CustomerResetPasswordPage from '@/views/landing/CustomerResetPasswordPage/CustomerResetPasswordPage.vue'

// PUBLIC (ESTABLISHMENT)
import PublicHomePage from '@/views/public/HomePage/PublicHomePage.vue'
import PublicBookingPage from '@/views/public/BookingPage/PublicBookingPage.vue'
import CustomerSignUpPage from '@/views/public/SignUpPage/CustomerSignUpPage.vue'
import CustomerLoginPage from '@/views/public/LoginPage/CustomerLoginPage.vue'
import LegalPage from '@/views/public/LegalPage/LegalPage.vue'

// CUSTOMER PORTAL
import CustomerProfilePage from '@/views/customer/ProfilePage/CustomerProfilePage.vue'
import CustomerAppointmentsPage from '@/views/customer/AppointmentsPage/CustomerAppointmentsPage.vue'
import CustomerHistoryPage from '@/views/customer/HistoryPage/CustomerHistoryPage.vue'
import CustomerPlansPage from '@/views/customer/PlansPage/CustomerPlansPage.vue'

// ADMIN PORTAL (ESTABLISHMENT ADMIN)
import AdminEstablishmentPage from '@/views/admin/EstablishmentPage/AdminEstablishmentPage.vue'
import AdminServicesPage from '@/views/admin/ServicesPage/AdminServicesPage.vue'
import AdminInventoryPage from '@/views/admin/InventoryPage/AdminInventoryPage.vue'
import AdminTeamPage from '@/views/admin/TeamPage/AdminTeamPage.vue'
import AdminWorkingHoursPage from '@/views/admin/WorkingHoursPage/AdminWorkingHoursPage.vue'
import AdminAppointmentsPage from '@/views/admin/AppointmentsPage/AdminAppointmentsPage.vue'
import AdminPlansPage from '@/views/admin/PlansPage/AdminPlansPage.vue'
import AdminSessionsPage from '@/views/admin/SessionsPage/AdminSessionsPage.vue'
import AdminAppearancePage from '@/views/admin/AppearancePage/AdminAppearancePage.vue'

// FINANCIAL
import AdminFinancialDashboardPage from '@/views/admin/Financial/DashboardPage/AdminFinancialDashboardPage.vue'
import AdminFinancialReportsPage from '@/views/admin/Financial/ReportsPage/AdminFinancialReportsPage.vue'
import AdminFinancialCommissionsPage from '@/views/admin/Financial/CommissionsPage/AdminFinancialCommissionsPage.vue'
import AdminFinancialPackagesPage from '@/views/admin/Financial/PackagesPage/AdminFinancialPackagesPage.vue'
import AdminFinancialServicesPage from '@/views/admin/Financial/ServicesPage/AdminFinancialServicesPage.vue'

// SUPER ADMIN
import SuperAdminPlansPage from '@/views/super-admin/PlansPage/SuperAdminPlansPage.vue'
import SuperAdminDashboardPage from '@/views/super-admin/DashboardPage/SuperAdminDashboardPage.vue'
import SuperAdminSecurityLogsPage from '@/views/super-admin/SecurityLogsPage/SuperAdminSecurityLogsPage.vue'
import SuperAdminSessionsPage from '@/views/super-admin/SessionsPage/SuperAdminSessionsPage.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // MAIN SISTEMA
    {
      path: '/',
      name: 'landing-sistema',
      component: LandingPage
    },
    {
      path: '/sistema/criar-conta',
      name: 'cadastro-sistema',
      component: SignUpPage
    },
    {
      path: '/sistema/login',
      name: 'login-sistema',
      component: LoginPage
    },
    {
      path: '/esqueci-senha',
      name: 'esqueci-senha',
      component: ForgotPasswordPage
    },
    {
      path: '/redefinir-senha',
      name: 'redefinir-senha',
      component: ResetPasswordPage
    },


    // ÁREA DO CLIENTE — legado sem slug (antes de /empresa/:slug para evitar conflito!)
    {
      path: '/empresa/minha-conta',
      name: 'cliente-minha-conta',
      component: CustomerProfilePage
    },
    {
      path: '/empresa/meus-agendamentos',
      name: 'cliente-meus-agendamentos',
      component: CustomerAppointmentsPage
    },
    {
      path: '/empresa/historico',
      name: 'cliente-historico-agendamentos',
      component: CustomerHistoryPage
    },

    // EMPRESA (SITE PÚBLICO POR SLUG) — fica depois das rotas estáticas
    {
      path: '/empresa/:slug',
      name: 'home-empresa',
      component: PublicHomePage
    },
    {
      path: '/empresa/:slug/agendamento',
      name: 'agendamento',
      component: PublicBookingPage
    },
    {
      path: '/empresa/:slug/:page(privacy_policy|terms_of_use|cookie_policy|about_us|faq|contact_info)',
      name: 'legal-page',
      component: LegalPage
    },

    // CLIENTE - AUTH (com slug do estabelecimento)
    {
      path: '/empresa/:slug/cadastro',
      name: 'cadastro-cliente-slug',
      component: CustomerSignUpPage
    },
    {
      path: '/empresa/:slug/login',
      name: 'login-cliente-slug',
      component: CustomerLoginPage
    },
    {
      path: '/empresa/:slug/esqueci-senha',
      name: 'esqueci-senha-cliente',
      component: CustomerForgotPasswordPage
    },
    {
      path: '/empresa/:slug/redefinir-senha',
      name: 'redefinir-senha-cliente',
      component: CustomerResetPasswordPage
    },

    // Rotas legadas sem slug (mantidas por compatibilidade)
    {
      path: '/cliente/cadastro',
      name: 'cadastro-cliente',
      component: CustomerSignUpPage
    },
    {
      path: '/cliente/login',
      name: 'login-cliente',
      component: CustomerLoginPage
    },

    // ÁREA DO CLIENTE — com slug (rota principal)
    {
      path: '/empresa/:slug/minha-conta',
      name: 'cliente-minha-conta-slug',
      component: CustomerProfilePage
    },
    {
      path: '/empresa/:slug/meus-agendamentos',
      name: 'cliente-meus-agendamentos-slug',
      component: CustomerAppointmentsPage
    },
    {
      path: '/empresa/:slug/historico',
      name: 'cliente-historico-slug',
      component: CustomerHistoryPage
    },
    {
      path: '/empresa/:slug/meus-pacotes',
      name: 'cliente-meus-pacotes-slug',
      component: CustomerPlansPage
    },
    
    // Rotas legadas (sem slug) para a área de pacotes
    {
      path: '/empresa/meus-pacotes',
      name: 'cliente-meus-pacotes',
      component: CustomerPlansPage
    },

    // ADMIN EMPRESA
    {
      path: '/admin/estabelecimento',
      name: 'admin-estabelecimento',
      component: AdminEstablishmentPage
    },
    {
      path: '/admin/servicos',
      name: 'admin-servicos',
      component: AdminServicesPage
    },
    {
      path: '/admin/estoque',
      name: 'admin-estoque',
      component: AdminInventoryPage
    },
    {
      path: '/admin/equipe',
      name: 'admin-equipe',
      component: AdminTeamPage
    },
    {
      path: '/admin/horarios',
      name: 'admin-horarios',
      component: AdminWorkingHoursPage
    },
    {
      path: '/admin/agendamentos',
      name: 'admin-agendamentos',
      component: AdminAppointmentsPage
    },

    // FINANCEIRO
    {
      path: '/admin/financeiro',
      redirect: '/admin/financeiro/dashboard'
    },
    {
      path: '/admin/financeiro/dashboard',
      name: 'admin-financeiro-dashboard',
      component: AdminFinancialDashboardPage
    },
    {
      path: '/admin/financeiro/relatorios',
      name: 'admin-financeiro-relatorios',
      component: AdminFinancialReportsPage
    },
    {
      path: '/admin/financeiro/comissoes',
      name: 'admin-financeiro-comissoes',
      component: AdminFinancialCommissionsPage
    },
    {
      path: '/admin/financeiro/pacotes',
      name: 'admin-financeiro-pacotes',
      component: AdminFinancialPackagesPage
    },
    {
      path: '/admin/financeiro/servicos',
      name: 'admin-financeiro-servicos',
      component: AdminFinancialServicesPage
    },

    {
      path: '/admin/planos',
      name: 'admin-planos',
      component: AdminPlansPage
    },
    {
      path: '/admin/dispositivos',
      name: 'admin-dispositivos',
      component: AdminSessionsPage
    },
    {
      path: '/admin/aparencia',
      name: 'admin-aparencia',
      component: AdminAppearancePage
    },

    // SUPER ADMIN
    {
      path: '/super-admin/dispositivos',
      name: 'super-admin-dispositivos',
      component: SuperAdminSessionsPage
    },
    {
      path: '/super-admin/dashboard',
      name: 'super-admin-dashboard',
      component: SuperAdminDashboardPage
    },
    {
      path: '/super-admin/planos',
      name: 'super-admin-planos',
      component: SuperAdminPlansPage
    },
    {
      path: '/super-admin/logs-seguranca',
      name: 'super-admin-security-logs',
      component: SuperAdminSecurityLogsPage
    }
  ]
})

router.beforeEach((to) => {
  if (to.params.slug) {
    localStorage.setItem('site-slug', String(to.params.slug))
    sessionStorage.setItem('site-slug', String(to.params.slug))
  }

  const token = getStaffAccessToken()

  const rawUser =
    localStorage.getItem('user') ||
    sessionStorage.getItem('user')

  let user = null

  try {
    user = rawUser ? JSON.parse(rawUser) : null
  } catch {
    user = null
  }

  const role = user?.role

  // 🔒 BLOQUEIO DE SEGURANÇA: EXPIROU A SENHA (NIST/OWASP)

  // 1. Para Colaboradores (Dono / Funcionários)
  if (token && user?.password_expired === true) {
    const isLoginRoute = to.path === '/sistema/login'
    const isAdminRoute = to.path.startsWith('/admin')
    const isSuperAdminRoute = to.path.startsWith('/super-admin')

    // Super admin não fica preso em loop — deixa acessar seu painel normalmente
    if (!isLoginRoute && !isAdminRoute && !isSuperAdminRoute) {
      return role === 'owner' ? '/admin/estabelecimento' : '/admin/agendamentos'
    }
  }

  // 2. Para Clientes (Customers)
  if (isCustomerLoggedIn()) {
    const rawCustomer = localStorage.getItem('customer-data') || sessionStorage.getItem('customer-data')
    let customerObj = null
    try {
      customerObj = rawCustomer ? JSON.parse(rawCustomer) : null
    } catch {
      customerObj = null
    }

    if (customerObj?.password_expired === true) {
      const slug = (to.params.slug as string) || localStorage.getItem('site-slug') || sessionStorage.getItem('site-slug') || ''
      const loginRoute = slug ? `/empresa/${slug}/login` : '/cliente/login'
      const accountRoute = slug ? `/empresa/${slug}/minha-conta` : '/empresa/minha-conta'
      
      const isLoginRoute = to.path === loginRoute || to.path === '/cliente/login'
      const isAccountRoute = to.path === accountRoute || to.path === '/empresa/minha-conta'
      
      if (!isLoginRoute && !isAccountRoute) {
        return accountRoute
      }
    }
  }

  // SUPER ADMIN
  if (to.path.startsWith('/super-admin')) {
    if (!token) return '/sistema/login'

    if (role !== 'super_admin') {
      if (role === 'owner') return '/admin/estabelecimento'
      if (role === 'employee') return '/admin/agendamentos'
      if (role === 'customer') return '/empresa/minha-conta'
      return '/sistema/login'
    }
  }

  // ADMIN EMPRESA
  if (to.path.startsWith('/admin')) {
    if (!token) return '/sistema/login'

    if (role !== 'owner' && role !== 'employee') {
      if (role === 'super_admin') return '/super-admin/dashboard'
      if (role === 'customer') return '/empresa/minha-conta'
      return '/sistema/login'
    }

    // Proteção Granular para Funcionários baseada em permissões
    // NOTA: Permissões do client são UI-only — a verificação real é server-side
    // (require_*_management! no ApplicationController). Se o usuário editar
    // o localStorage, o backend rejeita a request com 403.
    if (role === 'employee') {
      const rawPerms = localStorage.getItem('establishment-permissions') || sessionStorage.getItem('establishment-permissions')
      let permissions = null
      try {
        permissions = rawPerms ? JSON.parse(rawPerms) : null
      } catch {
        permissions = null
      }

      // 1. Estabelecimento (apenas owner pode acessar Aparência e Planos)
      if (to.path === '/admin/aparencia' || to.path === '/admin/planos') {
        return '/admin/agendamentos'
      }

      // 2. Estabelecimento (dados gerais)
      if (to.path === '/admin/estabelecimento') {
        if (!permissions?.can_manage_establishment) {
          return '/admin/agendamentos'
        }
      }

      // 3. Serviços
      if (to.path === '/admin/servicos') {
        if (!permissions?.can_manage_services) {
          return '/admin/agendamentos'
        }
      }
      // 3. Estoque
      if (to.path === '/admin/estoque') {
        if (!permissions?.can_manage_stock) {
          return '/admin/agendamentos'
        }
      }

      // 4. Equipe
      if (to.path.startsWith('/admin/equipe')) {
        if (!permissions?.can_manage_team) {
          return '/admin/agendamentos'
        }
      }

      // 5. Horários de Funcionamento
      if (to.path === '/admin/horarios') {
        if (!permissions?.can_manage_schedule) {
          return '/admin/agendamentos'
        }
      }

      // 6. Financeiro
      if (to.path.startsWith('/admin/financeiro')) {
        if (!permissions?.can_manage_financial) {
          return '/admin/agendamentos'
        }
      }
    }
  }

  // CLIENTE - ÁREA LOGADA
  // Guard usa o token JWT do customer (customerAuth), não o token Devise
  if (
    to.path.startsWith('/empresa/minha-conta') ||
    to.path.startsWith('/empresa/meus-agendamentos') ||
    to.path.startsWith('/empresa/historico') ||
    to.path.startsWith('/empresa/meus-pacotes') ||
    to.path.match(/^\/empresa\/[^/]+\/(minha-conta|meus-agendamentos|historico|meus-pacotes)/)
  ) {
    if (!isCustomerLoggedIn() || (to.params.slug && to.params.slug !== getCustomerSlug())) {
      const slug =
        (to.params.slug as string) ||
        localStorage.getItem('site-slug') ||
        sessionStorage.getItem('site-slug') ||
        ''
      return slug ? `/empresa/${slug}/login` : '/cliente/login'
    }
  }

  // BLOQUEIO LOGIN SISTEMA (staff)
  if (to.path === '/sistema/login' && token) {
    if (role === 'owner') return '/admin/estabelecimento'
    if (role === 'employee') return '/admin/agendamentos'
    if (role === 'super_admin') return '/super-admin/dashboard'
  }

  // BLOQUEIO LOGIN CLIENTE — usa token JWT do customer (não Devise)
  if (to.path === '/cliente/login' || to.path.match(/\/empresa\/[^/]+\/login$/)) {
    if (isCustomerLoggedIn() && (!to.params.slug || to.params.slug === getCustomerSlug())) {
      const slug =
        localStorage.getItem('site-slug') ||
        sessionStorage.getItem('site-slug') ||
        ''
      return slug ? `/empresa/${slug}/minha-conta` : '/empresa/minha-conta'
    }
  }

  return true
})

export default router
