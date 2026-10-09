<template>
  <div class="login-page bg-body text-body min-vh-100 d-flex flex-column" :data-bs-theme="isDarkMode ? 'dark' : 'light'">

    <!-- Theme toggle -->
    <div class="theme-switch-wrapper">
      <input type="checkbox" id="darkToggleCliente" class="visually-hidden-check" v-model="isDarkMode">
      <label for="darkToggleCliente" class="theme-switch mb-0">
        <div class="ball"></div>
        <i class="bi bi-sun-fill text-warning" style="font-size: 14px;"></i>
        <i class="bi bi-moon-stars-fill text-secondary" style="font-size: 14px;"></i>
      </label>
    </div>

    <div class="container flex-grow-1 d-flex justify-content-center align-items-center py-5">
      <div class="login-card shadow-lg">

        <!-- Header -->
        <div class="text-center mb-4">
          <router-link :to="backRoute" class="text-decoration-none">
            <h2 class="fw-800 text-primary mb-1">
              {{ establishmentName }}
            </h2>
          </router-link>
          <p class="text-secondary small fw-600">Bem-vindo de volta!</p>
        </div>

        <!-- Erro inline -->
        <div v-if="errorMsg" class="alert-inline alert-inline--error mb-3">
          <i class="bi bi-exclamation-circle-fill me-2"></i>{{ errorMsg }}
        </div>

        <!-- Sucesso inline -->
        <div v-if="successMsg" class="alert-inline alert-inline--success mb-3">
          <i class="bi bi-check-circle-fill me-2"></i>{{ successMsg }}
        </div>

        <form @submit.prevent="() => handleLogin()" novalidate>
          <div class="mb-3">
            <label class="form-label-custom" for="clienteEmail">E-mail</label>
            <input
              id="clienteEmail"
              type="email"
              class="form-control custom-input"
              placeholder="seu@email.com"
              autocomplete="username"
              required
              v-model="form.email"
            >
          </div>

          <div class="mb-3">
            <div class="d-flex justify-content-between align-items-center">
              <label class="form-label-custom" for="clientePassword">Senha</label>
              <router-link :to="forgotRoute" class="small text-decoration-none fw-bold text-primary">Esqueceu?</router-link>
            </div>
            <div class="position-relative">
              <input
                id="clientePassword"
                :type="showPassword ? 'text' : 'password'"
                class="form-control custom-input pe-5"
                placeholder="••••••••"
                autocomplete="current-password"
                required
                v-model="form.password"
              >
              <button
                type="button"
                class="btn-toggle-password"
                @click="showPassword = !showPassword"
                :aria-label="showPassword ? 'Ocultar senha' : 'Exibir senha'"
                tabindex="-1"
              >
                <i :class="showPassword ? 'bi bi-eye-slash-fill' : 'bi bi-eye-fill'"></i>
              </button>
            </div>
          </div>

          <div class="mb-4">
            <div class="form-check">
              <input class="form-check-input" type="checkbox" id="clienteRemember" v-model="form.remember">
              <label class="form-check-label small text-body fw-semibold" for="clienteRemember">
                Lembrar este dispositivo
              </label>
              <div class="text-muted extra-small mt-1">
                Reconhece seu navegador com segurança mesmo se o IP do seu modem mudar.
              </div>
            </div>
          </div>

          <button
            type="submit"
            id="btnClienteLogin"
            class="btn btn-primary w-100 py-2-5 rounded-pill fw-bold shadow-sm"
            :disabled="loading || isLocked"
            :class="{ 'btn-danger': isLocked }"
          >
            <span v-if="loading" class="spinner-border spinner-border-sm me-2" role="status"></span>
            <span v-if="isLocked">
              <i class="bi bi-lock-fill me-2"></i>Aguarde {{ lockCountdown }}s
            </span>
            <span v-else>{{ loading ? 'Entrando...' : 'ENTRAR' }}</span>
          </button>

          <div class="text-center mt-3">
            <p class="small text-muted mb-0">
              Novo por aqui?
              <router-link :to="registerRoute" class="fw-bold text-decoration-none text-primary">
                Criar conta
              </router-link>
            </p>
          </div>

          <div class="text-center mt-2">
            <router-link :to="backRoute" class="small text-decoration-none text-secondary">
              <i class="bi bi-arrow-left me-1"></i> Voltar ao site
            </router-link>
          </div>

          <!-- Conformidade LGPD & Segurança -->
          <div class="lgpd-container mt-4 pt-3 border-top text-center">
            <div class="d-flex align-items-center justify-content-center gap-1 text-success extra-small fw-bold mb-1">
              <i class="bi bi-shield-check"></i>
              <span>Ambiente Seguro & Conformidade LGPD</span>
            </div>
            <p class="text-muted extra-small mb-1 line-height-sm">
              Ao acessar, você concorda com os
              <router-link :to="termsRoute" class="text-primary text-decoration-none fw-semibold">Termos de Uso</router-link>
              e
              <router-link :to="privacyRoute" class="text-primary text-decoration-none fw-semibold">Política de Privacidade</router-link>.
            </p>
            <p class="text-secondary extra-small mb-0">
              Dados de acesso são tratados para proteção da sua conta (Art. 7º, IX da Lei 13.709/2018).
            </p>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal de Verificação de Novo Dispositivo (Estilo Discord / E-mail / 2FA) -->
    <LoginVerificationModal
      :show="showVerificationModal"
      :email-masked="maskedEmail"
      :error-msg="verificationError"
      @verify="handleVerifyOtp"
      @cancel="showVerificationModal = false"
      @resend="handleResendOtp"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { api, getOrCreateDeviceToken } from '@/services/api'
import { saveCustomerSession, clearCustomerSession } from '@/services/customerAuth'
import { useThemeStore } from '@/stores/themeStore'
import LoginVerificationModal from '@/components/LoginVerificationModal.vue'

const router = useRouter()
const route  = useRoute()
const store  = useThemeStore()

const isDarkMode   = ref(localStorage.getItem('easysloting_theme') === 'dark')
const loading      = ref(false)
const errorMsg     = ref('')
const successMsg   = ref('')

const showPassword = ref(false)

// ─── Verification State (Novo Dispositivo / IP - Estilo Discord) ──────────────
const showVerificationModal = ref(false)
const maskedEmail = ref('')
const verificationError = ref('')

// ─── Rate limiting frontend ───────────────────────────────────────────────────
const MAX_ATTEMPTS    = 5
const LOCKOUT_SECONDS = 30
const failedAttempts  = ref(0)
const lockedUntil     = ref<number | null>(null)
const lockCountdown   = ref(0)
let countdownTimer: ReturnType<typeof setInterval> | null = null

const isLocked = computed(() => !!lockedUntil.value && Date.now() < lockedUntil.value)

const startLockoutCountdown = () => {
  if (countdownTimer) clearInterval(countdownTimer)
  lockCountdown.value = LOCKOUT_SECONDS
  countdownTimer = setInterval(() => {
    lockCountdown.value--
    if (lockCountdown.value <= 0) {
      clearInterval(countdownTimer!)
      lockedUntil.value    = null
      failedAttempts.value = 0
      errorMsg.value       = ''
    }
  }, 1000)
}

const form = reactive({
  email:    '',
  password: '',
  remember: false
})

// Slug vem da rota /empresa/:slug/login
const currentSlug = computed(() =>
  String(route.params.slug || '') ||
  sessionStorage.getItem('site-slug') ||
  localStorage.getItem('site-slug') ||
  ''
)

const establishmentName = computed(() => store.salonConfig?.nome || 'EasySlotting')

const backRoute = computed(() =>
  currentSlug.value ? `/empresa/${currentSlug.value}` : '/'
)

const registerRoute = computed(() => {
  const base = currentSlug.value
    ? `/empresa/${currentSlug.value}/cadastro`
    : '/cliente/cadastro'
  return route.query.redirect
    ? `${base}?redirect=${encodeURIComponent(String(route.query.redirect))}`
    : base
})

const forgotRoute = computed(() =>
  currentSlug.value
    ? `/empresa/${currentSlug.value}/esqueci-senha`
    : '/esqueci-senha'
)

const termsRoute = computed(() =>
  currentSlug.value ? `/empresa/${currentSlug.value}/terms_of_use` : '#'
)

const privacyRoute = computed(() =>
  currentSlug.value ? `/empresa/${currentSlug.value}/privacy_policy` : '#'
)

watch(
  isDarkMode,
  (newVal) => {
    const theme = newVal ? 'dark' : 'light'
    document.documentElement.setAttribute('data-bs-theme', theme)
    localStorage.setItem('easysloting_theme', theme)
    store.isDarkMode = newVal
  },
  { immediate: true }
)

onMounted(async () => {
  if (route.params.slug) {
    const slug = String(route.params.slug)
    sessionStorage.setItem('site-slug', slug)
    localStorage.setItem('site-slug', slug)

    if (!store.salonConfig?.nome) {
      try {
        const res = await api.get(`/public/establishments/${slug}`)
        if (res.data?.name) {
          store.setSalonConfig({
            nome: res.data.name,
            descricao: res.data.description,
            ...res.data
          })
        }
      } catch {
        // Fallback gracioso caso a API ainda não responda
      }
    }
  }
})

const handleLogin = async (otpCode?: string | null) => {
  errorMsg.value   = ''
  successMsg.value = ''
  verificationError.value = ''

  if (isLocked.value) {
    errorMsg.value = `Muitas tentativas. Aguarde ${lockCountdown.value}s.`
    return
  }

  if (!form.email.trim() || !form.password.trim()) {
    errorMsg.value = 'Preencha o e-mail e a senha.'
    return
  }

  if (!currentSlug.value) {
    errorMsg.value = 'Estabelecimento não identificado. Acesse pelo link correto.'
    return
  }

  try {
    loading.value = true

    const payload: any = {
      email:        form.email.trim().toLowerCase(),
      password:     form.password,
      device_token: getOrCreateDeviceToken()
    }
    if (typeof otpCode === 'string' && otpCode.trim().length > 0) {
      payload.otp_code = otpCode.trim()
    }

    const response = await api.post(`/customer_auth/${currentSlug.value}/sign_in`, payload)

    // 🔒 Verificação de Novo Dispositivo / IP (Estilo Discord)
    if (response.data?.requires_verification) {
      maskedEmail.value = response.data.email_masked || form.email
      showVerificationModal.value = true
      return
    }

    const { access_token, expires_in, csrf_token, customer } = response.data

    // Limpa qualquer sessão antiga antes de salvar a nova
    clearCustomerSession()
    saveCustomerSession(access_token, customer, currentSlug.value, form.remember, expires_in, csrf_token)

    // Zera tentativas em sucesso
    failedAttempts.value = 0
    showVerificationModal.value = false
    successMsg.value     = 'Login realizado! Redirecionando...'

    const redirectQuery = typeof route.query.redirect === 'string' ? route.query.redirect.trim() : ''
    const hasExpired = customer?.password_expired === true

    // Validação estrita de redirecionamento seguro (contra Open Redirect e Cross-Tenant)
    const isSafeRedirect =
      redirectQuery.length > 0 &&
      !redirectQuery.startsWith('//') &&
      !redirectQuery.startsWith('/\\') &&
      !redirectQuery.includes('://') &&
      (redirectQuery === `/empresa/${currentSlug.value}` || redirectQuery.startsWith(`/empresa/${currentSlug.value}/`))

    const redirectTo =
      hasExpired
        ? `/empresa/${currentSlug.value}/minha-conta`
        : (isSafeRedirect ? redirectQuery : `/empresa/${currentSlug.value}/minha-conta`)

    setTimeout(() => router.push(redirectTo), 600)

  } catch (err: any) {
    failedAttempts.value++

    if (failedAttempts.value >= MAX_ATTEMPTS) {
      lockedUntil.value = Date.now() + LOCKOUT_SECONDS * 1000
      startLockoutCountdown()
      errorMsg.value = `Acesso bloqueado por ${LOCKOUT_SECONDS}s após muitas tentativas.`
    } else {
      const remaining = MAX_ATTEMPTS - failedAttempts.value

      if (err.response?.status === 429) {
        lockedUntil.value = Date.now() + LOCKOUT_SECONDS * 1000
        startLockoutCountdown()
        errorMsg.value = 'Muitas tentativas detectadas. Aguarde antes de tentar novamente.'
      } else if (showVerificationModal.value) {
        verificationError.value = err.response?.data?.error || 'Código de verificação inválido ou expirado.'
      } else {
        const serverMsg =
          err.response?.data?.error ||
          (err.message === 'Network Error' ? 'Erro de conexão com o servidor. Verifique se a API está em execução.' : 'E-mail ou senha incorretos.')
        errorMsg.value  = `${serverMsg} (${remaining} tentativa${remaining === 1 ? '' : 's'} restante${remaining === 1 ? '' : 's'})`
      }
    }
  } finally {
    loading.value = false
  }
}

const handleVerifyOtp = async (code: string) => {
  verificationError.value = ''
  await handleLogin(code)
}

const handleResendOtp = async () => {
  verificationError.value = ''
  try {
    await api.post(`/customer_auth/${currentSlug.value}/sign_in`, {
      email: form.email.trim().toLowerCase(),
      password: form.password,
      device_token: getOrCreateDeviceToken()
    })
  } catch (err: any) {
    verificationError.value = err.response?.data?.error || 'Erro ao reenviar código de verificação.'
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.login-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  transition: background 0.4s ease;
}

.login-card {
  background: var(--bs-body-tertiary);
  backdrop-filter: blur(15px);
  border: 1px solid rgba(0, 0, 0, 0.08);
  border-radius: 28px;
  padding: 2.5rem;
  width: 100%;
  max-width: 450px;
}

[data-bs-theme='dark'] .login-card {
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3) !important;
}

.custom-input {
  border-radius: 12px;
  padding: 12px 15px;
  font-size: 0.9rem;
  transition: all 0.25s ease;
}

[data-bs-theme='light'] .custom-input {
  background: #ffffff !important;
  border: 1.5px solid rgba(0, 0, 0, 0.6) !important;
  color: #111827 !important;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

[data-bs-theme='dark'] .custom-input {
  background: rgba(255, 255, 255, 0.04) !important;
  border: 1px solid rgba(255, 255, 255, 0.14) !important;
  color: #f8f9fa !important;
}

/* Autocomplete autofill fix */
.custom-input:-webkit-autofill,
.custom-input:-webkit-autofill:hover,
.custom-input:-webkit-autofill:focus {
  -webkit-text-fill-color: #111827 !important;
  -webkit-box-shadow: 0 0 0 1000px #ffffff inset !important;
  transition: background-color 5000s ease-in-out 0s;
}

[data-bs-theme='dark'] .custom-input:-webkit-autofill,
[data-bs-theme='dark'] .custom-input:-webkit-autofill:hover,
[data-bs-theme='dark'] .custom-input:-webkit-autofill:focus {
  -webkit-text-fill-color: #f8f9fa !important;
  -webkit-box-shadow: 0 0 0 1000px #212529 inset !important;
}

.custom-input::placeholder { color: rgba(108, 117, 125, 0.85); }
[data-bs-theme='dark'] .custom-input::placeholder { color: rgba(255, 255, 255, 0.45); }

[data-bs-theme='light'] .custom-input:focus {
  background: #ffffff !important;
  border-color: var(--bs-primary) !important;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
}

[data-bs-theme='dark'] .custom-input:focus {
  background: rgba(255, 255, 255, 0.06) !important;
  border-color: var(--bs-primary) !important;
  box-shadow: 0 0 0 3px rgba(74, 111, 165, 0.15);
}

.form-label-custom {
  font-size: 0.7rem;
  font-weight: 800;
  margin-bottom: 5px;
  color: var(--bs-secondary-color);
  text-transform: uppercase;
  letter-spacing: 0.8px;
}

/* Alertas inline */
.alert-inline {
  border-radius: 12px;
  padding: 10px 14px;
  font-size: 0.85rem;
  font-weight: 600;
  display: flex;
  align-items: center;
}

.alert-inline--error {
  background: rgba(220, 53, 69, 0.1);
  border: 1px solid rgba(220, 53, 69, 0.25);
  color: #dc3545;
}

[data-bs-theme='dark'] .alert-inline--error {
  background: rgba(220, 53, 69, 0.15);
  color: #f88;
}

.alert-inline--success {
  background: rgba(25, 135, 84, 0.1);
  border: 1px solid rgba(25, 135, 84, 0.25);
  color: #198754;
}

[data-bs-theme='dark'] .alert-inline--success {
  background: rgba(25, 135, 84, 0.15);
  color: #6fcf97;
}

/* Theme switch */
.theme-switch-wrapper {
  position: absolute;
  top: 25px;
  right: 25px;
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

.theme-switch {
  width: 55px;
  height: 28px;
  background: #333;
  border-radius: 50px;
  position: relative;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-around;
}

.theme-switch .ball {
  width: 22px;
  height: 22px;
  background: white;
  border-radius: 50%;
  position: absolute;
  left: 3px;
  transition: 0.4s;
}

#darkToggleCliente:checked + .theme-switch .ball {
  transform: translateX(27px);
}

@media (max-width: 576px) {
  .login-card {
    padding: 2rem;
    border-radius: 0;
    border: none;
    background: transparent;
    box-shadow: none !important;
  }
}

.btn-toggle-password {
  position: absolute;
  right: 14px;
  top: 50%;
  transform: translateY(-50%);
  background: transparent;
  border: none;
  color: var(--bs-secondary);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.15rem;
  transition: color 0.2s ease;
  z-index: 5;
}

.btn-toggle-password:hover {
  color: var(--bs-primary);
}

.extra-small {
  font-size: 0.75rem;
}

.line-height-sm {
  line-height: 1.35;
}
</style>