<template>
  <div class="landing-page min-vh-100 bg-body text-body" :data-bs-theme="store.isDarkMode ? 'dark' : 'light'">

    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg py-3 sticky-top navbar-glass">
      <div class="container">
        <router-link to="/" class="navbar-brand fw-800 fs-3 text-primary d-flex align-items-center gap-2">
          <i class="bi bi-calendar-check-fill"></i> EASYSLOTTING
        </router-link>

        <div class="ms-auto d-flex align-items-center gap-2 gap-md-3 navbar-actions">
          <div class="d-flex align-items-center">
            <input type="checkbox" id="darkToggle" class="visually-hidden" v-model="store.isDarkMode">
            <label for="darkToggle" class="theme-switch mb-0 shadow-sm">
              <div class="ball"></div>
              <i class="bi bi-sun-fill text-warning"></i>
              <i class="bi bi-moon-stars-fill text-secondary opacity-75"></i>
            </label>
          </div>

          <template v-if="isAuthenticated">
            <router-link :to="myAccountRoute" class="btn btn-primary rounded-pill fw-bold px-4 py-2 shadow-sm">
              Minha conta
            </router-link>
            <button type="button" class="btn btn-outline-primary rounded-pill fw-bold px-4 py-2" @click="logout">
              Sair
            </button>
          </template>
          <template v-else>
            <router-link to="/sistema/criar-conta" class="btn btn-primary rounded-pill fw-bold px-4 py-2 shadow-sm">
              Criar conta
            </router-link>
            <router-link to="/sistema/login" class="btn btn-outline-primary rounded-pill fw-bold px-4 py-2">
              Entrar
            </router-link>
          </template>
        </div>
      </div>
    </nav>

    <!-- Hero -->
    <section class="hero-section">
      <div class="container py-5">
        <div class="row align-items-center g-5">
          <div class="col-lg-6">
            <span class="badge rounded-pill text-bg-primary px-3 py-2 fw-bold mb-3">
              <i class="bi bi-stars me-1"></i> Plataforma para agendamentos
            </span>
            <h1 class="display-4 fw-800 lh-sm mb-3">
              Crie o site do seu estabelecimento e gerencie tudo em um só lugar
            </h1>
            <p class="lead text-secondary mb-4">
              Organize agenda, equipe, serviços, horários, financeiro e a página do seu negócio
              com uma experiência moderna para você e para seus clientes.
            </p>
            <div class="d-flex flex-wrap gap-3">
              <router-link
                :to="isAuthenticated ? myAccountRoute : '/sistema/criar-conta'"
                class="btn btn-primary btn-lg rounded-pill fw-bold px-5 py-3 shadow-sm"
              >
                <i class="bi bi-rocket-takeoff me-2"></i>
                {{ isAuthenticated ? 'Minha conta' : 'Começar agora' }}
              </router-link>
              <a href="#planos" class="btn btn-outline-secondary btn-lg rounded-pill fw-bold px-5 py-3">
                Ver planos
              </a>
            </div>

            <div class="hero-stats row g-3 mt-4">
              <div class="col-sm-4">
                <div class="info-card h-100">
                  <i class="bi bi-calendar-check fs-4 text-primary mb-2 d-block"></i>
                  <strong class="d-block fw-800">Agenda</strong>
                  <span class="text-secondary small">Controle de horários e atendimentos</span>
                </div>
              </div>
              <div class="col-sm-4">
                <div class="info-card h-100">
                  <i class="bi bi-people fs-4 text-primary mb-2 d-block"></i>
                  <strong class="d-block fw-800">Equipe</strong>
                  <span class="text-secondary small">Cadastre funcionários e permissões</span>
                </div>
              </div>
              <div class="col-sm-4">
                <div class="info-card h-100">
                  <i class="bi bi-globe2 fs-4 text-primary mb-2 d-block"></i>
                  <strong class="d-block fw-800">Site</strong>
                  <span class="text-secondary small">Página pronta para o seu negócio</span>
                </div>
              </div>
            </div>
          </div>

          <div class="col-lg-6">
            <div class="showcase-card shadow-lg">
              <div class="showcase-topbar">
                <span></span><span></span><span></span>
              </div>
              <div class="p-4 p-md-5">
                <div class="mini-panel mb-3">
                  <div class="d-flex justify-content-between align-items-center">
                    <div>
                      <h5 class="fw-800 mb-1">Painel da Empresa</h5>
                      <p class="small text-secondary mb-0">Tudo centralizado no admin</p>
                    </div>
                    <span class="badge bg-success-subtle text-success border border-success-subtle rounded-pill px-3 py-2">Online</span>
                  </div>
                </div>
                <div class="row g-3">
                  <div class="col-6">
                    <div class="mini-box">
                      <i class="bi bi-calendar-check fs-4 text-primary"></i>
                      <h6 class="fw-bold mt-3 mb-1">Agendamentos</h6>
                      <p class="small text-secondary mb-0">Visualize reservas e horários.</p>
                    </div>
                  </div>
                  <div class="col-6">
                    <div class="mini-box">
                      <i class="bi bi-people fs-4 text-primary"></i>
                      <h6 class="fw-bold mt-3 mb-1">Equipe</h6>
                      <p class="small text-secondary mb-0">Adicione e gerencie profissionais.</p>
                    </div>
                  </div>
                  <div class="col-6">
                    <div class="mini-box">
                      <i class="bi bi-scissors fs-4 text-primary"></i>
                      <h6 class="fw-bold mt-3 mb-1">Serviços</h6>
                      <p class="small text-secondary mb-0">Configure preço e duração.</p>
                    </div>
                  </div>
                  <div class="col-6">
                    <div class="mini-box">
                      <i class="bi bi-palette fs-4 text-primary"></i>
                      <h6 class="fw-bold mt-3 mb-1">Aparência</h6>
                      <p class="small text-secondary mb-0">Personalize a página da empresa.</p>
                    </div>
                  </div>
                </div>
                <div class="cta-box mt-4">
                  <div>
                    <h6 class="fw-800 mb-1">Pronto para começar?</h6>
                    <p class="small text-secondary mb-0">Crie sua conta e configure seu estabelecimento.</p>
                  </div>
                  <router-link :to="isAuthenticated ? myAccountRoute : '/sistema/criar-conta'" class="btn btn-primary rounded-pill fw-bold px-4">
                    {{ isAuthenticated ? 'Minha conta' : 'Criar conta' }}
                  </router-link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Como funciona -->
    <section id="como-funciona" class="py-5 section-alt">
      <div class="container">
        <div class="text-center mb-5">
          <span class="badge rounded-pill text-bg-light border px-3 py-2 fw-bold mb-3">Como funciona</span>
          <h2 class="fw-800 mb-2">Seu negócio online em poucos passos</h2>
          <p class="text-secondary mb-0">Um fluxo simples para você vender mais e organizar sua operação.</p>
        </div>
        <div class="row g-4">
          <div class="col-md-4">
            <div class="step-card h-100">
              <div class="step-number">1</div>
              <h5 class="fw-bold mb-2">Crie sua conta</h5>
              <p class="text-secondary mb-0">Cadastre seu negócio com nome, CNPJ, categoria e acesso do proprietário.</p>
            </div>
          </div>
          <div class="col-md-4">
            <div class="step-card h-100">
              <div class="step-number">2</div>
              <h5 class="fw-bold mb-2">Configure o estabelecimento</h5>
              <p class="text-secondary mb-0">Preencha horários, serviços, equipe, aparência e informações da empresa.</p>
            </div>
          </div>
          <div class="col-md-4">
            <div class="step-card h-100">
              <div class="step-number">3</div>
              <h5 class="fw-bold mb-2">Receba agendamentos</h5>
              <p class="text-secondary mb-0">Seus clientes acessam sua página, fazem login e reservam horários online.</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Planos -->
    <section id="planos" class="py-5">
      <div class="container">
        <div class="text-center mb-5">
          <span class="badge rounded-pill text-bg-light border px-3 py-2 fw-bold mb-3">
            <i class="bi bi-stars me-1"></i> Planos e Preços
          </span>
          <h2 class="fw-800 mb-2">Escolha o plano ideal para o seu negócio</h2>
          <p class="text-secondary mb-0">Sem taxas ocultas. Cancele quando quiser.</p>
        </div>

        <!-- Loading -->
        <div v-if="loadingPlans" class="text-center py-5">
          <div class="spinner-border text-primary" role="status"></div>
          <p class="mt-3 text-secondary small">Carregando planos...</p>
        </div>

        <!-- Erro -->
        <div v-else-if="plansError" class="alert alert-warning rounded-4 text-center">
          <i class="bi bi-exclamation-circle me-2"></i>{{ plansError }}
        </div>

        <!-- Cards de planos -->
        <div v-else class="row g-4 justify-content-center">
          <div
            v-for="plan in plans"
            :key="plan.id"
            class="col-md-6 col-lg-4"
          >
            <div class="plan-card h-100" :class="{ 'plan-card-highlight': plan.highlight }">
              <!-- Badge destaque -->
              <div v-if="plan.highlight" class="plan-badge">
                <i class="bi bi-lightning-charge-fill me-1"></i> Mais popular
              </div>

              <div class="plan-header">
                <h4 class="fw-800 mb-1">{{ plan.name }}</h4>
                <p class="text-secondary small mb-0">{{ plan.description }}</p>
              </div>

              <div class="plan-price-block">
                <!-- Preço riscado se houver promoção -->
                <div v-if="plan.promotion_active && plan.promotional_price !== null" class="mb-1">
                  <span class="text-secondary text-decoration-line-through small me-2">
                    R$ {{ formatPrice(plan.price) }}
                  </span>
                  <span class="badge bg-danger bg-opacity-10 text-danger fw-bold rounded-pill px-2">
                    -{{ plan.discount_percentage }}%
                  </span>
                </div>

                <div class="d-flex align-items-end gap-1">
                  <span class="plan-currency">R$</span>
                  <span class="plan-price">{{ formatPrice(plan.effective_price) }}</span>
                  <span class="text-secondary small mb-1">/mês</span>
                </div>
              </div>

              <ul class="plan-features">
                <li>
                  <i class="bi bi-check2 text-success me-2"></i>
                  Até <strong>{{ plan.max_owner_sessions ?? 1 }}</strong> aparelho{{ (plan.max_owner_sessions ?? 1) > 1 ? 's' : '' }} conectado{{ (plan.max_owner_sessions ?? 1) > 1 ? 's' : '' }} por conta do proprietário ou funcionário
                </li>
                <li v-if="plan.max_employees">
                  <i class="bi bi-people-fill text-primary"></i>
                  Até <strong>{{ plan.max_employees }}</strong> profissional{{ plan.max_employees > 1 ? 'is' : '' }}
                </li>
                <li v-if="plan.max_services">
                  <i class="bi bi-scissors text-primary"></i>
                  Até <strong>{{ plan.max_services }}</strong> serviço{{ plan.max_services > 1 ? 's' : '' }}
                </li>
                <li v-if="plan.max_appointments_per_month">
                  <i class="bi bi-calendar-check text-primary"></i>
                  Até <strong>{{ plan.max_appointments_per_month }}</strong> agendamentos/mês
                </li>
                <li v-if="!plan.max_appointments_per_month">
                  <i class="bi bi-infinity text-primary"></i>
                  Agendamentos <strong>ilimitados</strong>
                </li>
                <li>
                  <i class="bi bi-globe2 text-primary"></i>
                  Site personalizado do estabelecimento
                </li>
                <li>
                  <i class="bi bi-bar-chart-fill text-primary"></i>
                  Relatórios financeiros
                </li>
                <li>
                  <i class="bi bi-headset text-primary"></i>
                  Suporte incluso
                </li>
              </ul>

              <router-link
                :to="isAuthenticated ? myAccountRoute : '/sistema/criar-conta'"
                class="btn rounded-pill fw-bold w-100 plan-btn"
                :class="plan.highlight ? 'btn-primary' : 'btn-outline-primary'"
              >
                {{ isAuthenticated ? 'Minha conta' : 'Começar agora' }}
              </router-link>
            </div>
          </div>
        </div>

        <p class="text-center text-secondary small mt-4">
          <i class="bi bi-shield-check me-1 text-success"></i>
          Pagamento seguro · Cancele quando quiser · Sem fidelidade
        </p>
      </div>
    </section>

    <!-- CTA Final -->
    <section class="pb-5 section-alt">
      <div class="container">
        <div class="final-cta text-center">
          <h2 class="fw-800 mb-3">Leve seu estabelecimento para o próximo nível</h2>
          <p class="text-secondary mb-4">Crie sua conta agora e comece a montar o seu sistema.</p>
          <router-link
            :to="isAuthenticated ? myAccountRoute : '/sistema/criar-conta'"
            class="btn btn-primary btn-lg rounded-pill fw-bold px-5 py-3 shadow-sm"
          >
            <i class="bi bi-rocket-takeoff me-2"></i>
            {{ isAuthenticated ? 'Minha conta' : 'Criar conta grátis' }}
          </router-link>
        </div>
      </div>
    </section>

    <!-- Footer mínimo -->
    <footer class="py-4 border-top text-center text-secondary small">
      © {{ new Date().getFullYear() }} EasySlotting. Todos os direitos reservados.
    </footer>

  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, watch, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useThemeStore } from '@/stores/themeStore'
import { api, logoutStaff } from '@/services/api'
import { getStaffAccessToken } from '@/services/staffAuth'

const router = useRouter()
const store  = useThemeStore()
const authVersion = ref(0)

// ─── Planos do banco ──────────────────────────────────────────────────────────
const plans       = ref([])
const loadingPlans = ref(false)
const plansError   = ref('')

const fetchPlans = async () => {
  loadingPlans.value = true
  plansError.value   = ''
  try {
    const response = await api.get('/plans')
    plans.value = response.data
  } catch (err) {
    console.error('Erro ao carregar planos:', err)
    plansError.value = 'Não foi possível carregar os planos. Tente novamente mais tarde.'
  } finally {
    loadingPlans.value = false
  }
}

const formatPrice = (value) =>
  Number(value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

// ─── Autenticação ─────────────────────────────────────────────────────────────
const refreshAuthState = () => { authVersion.value++ }

const getToken = () => getStaffAccessToken() || ''

const getStoredUser = () => {
  authVersion.value
  try {
    const raw = localStorage.getItem('user') || sessionStorage.getItem('user') || 'null'
    return JSON.parse(raw)
  } catch { return null }
}

const currentUser    = computed(() => getStoredUser())
const isAuthenticated = computed(() => { authVersion.value; return !!getToken() })

const myAccountRoute = computed(() => {
  const role = currentUser.value?.role
  if (role === 'owner') return '/admin/estabelecimento'
  if (role === 'employee') return '/admin/agendamentos'
  if (role === 'super_admin') return '/super-admin/dashboard'
  if (role === 'customer')    return '/empresa/minha-conta'
  return '/sistema/login'
})

const logout = async () => {
  try {
    await logoutStaff()
  } catch {
    // A sessão local já foi encerrada mesmo quando a rede está indisponível.
  } finally {
    refreshAuthState()
    router.push('/')
  }
}

// ─── Tema ─────────────────────────────────────────────────────────────────────
onMounted(() => {
  const savedTheme = localStorage.getItem('easyslotting_theme')
  store.isDarkMode = savedTheme === 'dark'
  refreshAuthState()
  window.addEventListener('storage', refreshAuthState)
  window.addEventListener('focus',   refreshAuthState)
  fetchPlans()
})

onUnmounted(() => {
  window.removeEventListener('storage', refreshAuthState)
  window.removeEventListener('focus',   refreshAuthState)
})

watch(
  () => store.isDarkMode,
  (newVal) => {
    const theme = newVal ? 'dark' : 'light'
    document.documentElement.setAttribute('data-bs-theme', theme)
    localStorage.setItem('easyslotting_theme', theme)
  },
  { immediate: true }
)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.landing-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  overflow-x: hidden;
}

/* ─── Navbar ─────────────────────────────── */
.navbar-glass {
  background: rgba(var(--bs-body-bg-rgb, 255,255,255), 0.85);
  backdrop-filter: blur(16px);
  border-bottom: 1px solid rgba(0,0,0,0.06);
  z-index: 1030;
}
[data-bs-theme="dark"] .navbar-glass {
  background: rgba(33,37,41,0.88);
  border-bottom: 1px solid rgba(255,255,255,0.06);
}

/* ─── Hero ───────────────────────────────── */
.hero-section { padding: 2rem 0 3rem; }

.info-card,
.step-card,
.mini-box,
.mini-panel {
  background: var(--bs-tertiary-bg);
  border: 1px solid rgba(0,0,0,0.07);
  border-radius: 20px;
  padding: 1.25rem;
  transition: transform 0.2s, box-shadow 0.2s;
}
.info-card:hover, .step-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 28px rgba(0,0,0,0.08);
}

.showcase-card {
  background: var(--bs-tertiary-bg);
  border: 1px solid rgba(0,0,0,0.07);
  border-radius: 28px;
  overflow: hidden;
}
.showcase-topbar {
  display: flex; gap: 8px; padding: 14px 18px;
  border-bottom: 1px solid rgba(0,0,0,0.07);
}
.showcase-topbar span {
  width: 12px; height: 12px; border-radius: 50%;
  background: rgba(108,117,125,0.35);
}
.cta-box {
  background: rgba(13,110,253,0.07);
  border: 1px solid rgba(13,110,253,0.12);
  border-radius: 18px; padding: 1rem;
  display: flex; gap: 1rem;
  justify-content: space-between; align-items: center;
}

/* ─── Steps ──────────────────────────────── */
.step-number {
  width: 44px; height: 44px; border-radius: 50%;
  background: var(--bs-primary); color: #fff;
  font-weight: 800; font-size: 1.1rem;
  display: inline-flex; align-items: center; justify-content: center;
  margin-bottom: 1rem;
}

/* ─── Seção alternada ────────────────────── */
.section-alt {
  background: var(--bs-tertiary-bg);
}

/* ─── Planos ─────────────────────────────── */
.plan-card {
  position: relative;
  background: var(--bs-body-bg);
  border: 1.5px solid rgba(0,0,0,0.09);
  border-radius: 24px;
  padding: 2rem;
  display: flex; flex-direction: column;
  transition: transform 0.25s, box-shadow 0.25s;
}
.plan-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 20px 40px rgba(0,0,0,0.10);
}
.plan-card-highlight {
  border-color: var(--bs-primary);
  box-shadow: 0 0 0 3px rgba(13,110,253,0.12), 0 16px 40px rgba(13,110,253,0.14);
}
.plan-badge {
  position: absolute;
  top: -14px; left: 50%; transform: translateX(-50%);
  background: var(--bs-primary); color: #fff;
  border-radius: 999px; padding: 4px 14px;
  font-size: 0.78rem; font-weight: 700; white-space: nowrap;
}
.plan-header {
  margin-bottom: 1.25rem;
  padding-bottom: 1.25rem;
  border-bottom: 1px solid rgba(0,0,0,0.07);
}
.plan-price-block { margin-bottom: 1.5rem; }
.plan-currency {
  font-size: 1.3rem; font-weight: 800;
  color: var(--bs-body-color); line-height: 1; padding-bottom: 6px;
}
.plan-price {
  font-size: 3rem; font-weight: 800; letter-spacing: -0.03em;
  line-height: 1; color: var(--bs-primary);
}
.plan-features {
  list-style: none; padding: 0; margin: 0 0 1.5rem;
  display: flex; flex-direction: column; gap: 0.65rem; flex: 1;
}
.plan-features li {
  display: flex; align-items: center; gap: 0.6rem;
  font-size: 0.92rem;
}
.plan-features i { font-size: 1rem; flex-shrink: 0; }
.plan-btn { padding: 0.75rem; font-size: 0.95rem; }

/* ─── Final CTA ──────────────────────────── */
.final-cta {
  background: var(--bs-tertiary-bg);
  border: 1px solid rgba(0,0,0,0.07);
  border-radius: 28px;
  padding: 3rem 2rem;
}

/* ─── Tema escuro ────────────────────────── */
[data-bs-theme="dark"] .info-card,
[data-bs-theme="dark"] .step-card,
[data-bs-theme="dark"] .mini-box,
[data-bs-theme="dark"] .mini-panel,
[data-bs-theme="dark"] .showcase-card,
[data-bs-theme="dark"] .plan-card,
[data-bs-theme="dark"] .final-cta {
  border-color: rgba(255,255,255,0.08);
  box-shadow: 0 20px 40px rgba(0,0,0,0.25);
}
[data-bs-theme="dark"] .plan-header {
  border-bottom-color: rgba(255,255,255,0.07);
}

/* ─── Toggle tema ────────────────────────── */
.visually-hidden {
  position: absolute !important; width: 1px !important; height: 1px !important;
  padding: 0 !important; margin: -1px !important; overflow: hidden !important;
  clip: rect(0,0,0,0) !important; white-space: nowrap !important; border: 0 !important;
}
.theme-switch {
  width: 60px; height: 32px;
  background: var(--bs-tertiary-bg);
  border-radius: 50px; border: 1px solid rgba(0,0,0,0.08);
  position: relative; cursor: pointer;
  display: flex; align-items: center; justify-content: space-around; flex-shrink: 0;
}
.theme-switch .ball {
  width: 24px; height: 24px; background: var(--bs-primary);
  border-radius: 50%; position: absolute; left: 4px;
  transition: 0.3s cubic-bezier(0.4,0,0.2,1); z-index: 2;
}
#darkToggle:checked + .theme-switch .ball { transform: translateX(28px); }

/* ─── Responsivo ─────────────────────────── */
@media (max-width: 576px) {
  .hero-section { padding-top: 2rem; }
  .navbar-actions { gap: 0.5rem !important; flex-wrap: nowrap; }
  .navbar-actions .btn { padding-left: 0.9rem !important; padding-right: 0.9rem !important; white-space: nowrap; }
  .cta-box { flex-direction: column; align-items: stretch; }
  .plan-price { font-size: 2.4rem; }
}
</style>
