<template>
  <div
    class="login-page bg-body text-body min-vh-100 d-flex flex-column"
    :data-bs-theme="isDarkMode ? 'dark' : 'light'"
  >
    <!-- Theme toggle -->
    <div class="theme-switch-wrapper">
      <input type="checkbox" id="darkToggleSistema" class="visually-hidden-check" v-model="isDarkMode" />
      <label for="darkToggleSistema" class="theme-switch mb-0">
        <div class="ball"></div>
        <i class="bi bi-sun-fill text-warning" style="font-size: 14px;"></i>
        <i class="bi bi-moon-stars-fill text-secondary" style="font-size: 14px;"></i>
      </label>
    </div>

    <div class="container flex-grow-1 d-flex justify-content-center align-items-center py-5">
      <div class="login-card shadow-lg">

        <!-- Header -->
        <div class="text-center mb-4">
          <router-link to="/" class="text-decoration-none">
            <h2 class="fw-800 text-primary mb-1">EASYSLOTTING</h2>
          </router-link>
          <p class="text-secondary small fw-600">Acesse a área da empresa</p>
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
            <label class="form-label-custom" for="sistemaEmail">E-mail</label>
            <input
              id="sistemaEmail"
              type="email"
              class="form-control custom-input"
              placeholder="empresa@email.com"
              autocomplete="username"
              required
              v-model="form.email"
            />
          </div>

          <div class="mb-3">
            <div class="d-flex justify-content-between align-items-center">
              <label class="form-label-custom" for="sistemaPassword">Senha</label>
              <router-link to="/esqueci-senha" class="small text-decoration-none fw-bold text-primary">Esqueceu?</router-link>
            </div>
            <div class="position-relative">
              <input
                id="sistemaPassword"
                :type="showPassword ? 'text' : 'password'"
                class="form-control custom-input pe-5"
                placeholder="••••••••"
                autocomplete="current-password"
                required
                v-model="form.password"
              />
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
              <input class="form-check-input" type="checkbox" id="sistemaRemember" v-model="form.remember" />
              <label class="form-check-label small text-body fw-semibold" for="sistemaRemember">
                Lembrar este dispositivo
              </label>
              <div class="text-muted extra-small mt-1">
                Reconhece seu navegador mesmo se o IP rotativo do modem mudar.
              </div>
            </div>
          </div>

          <button
            type="submit"
            id="btnSistemaLogin"
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
              Quer cadastrar sua empresa?
              <router-link to="/sistema/criar-conta" class="fw-bold text-decoration-none text-primary">
                Criar conta
              </router-link>
            </p>
          </div>

          <!-- Conformidade LGPD & Segurança -->
          <div class="lgpd-container mt-4 pt-3 border-top text-center">
            <div class="d-flex align-items-center justify-content-center gap-1 text-success extra-small fw-bold mb-1">
              <i class="bi bi-shield-check"></i>
              <span>Ambiente Protegido & Conformidade LGPD</span>
            </div>
            <p class="text-muted extra-small mb-0 line-height-sm">
              Dados de conexão (IP e dispositivo) são tratados estritamente para segurança e prevenção a fraudes (Art. 7º, IX da Lei 13.709/2018).
            </p>
            <div class="mt-1">
              <a href="#" class="extra-small text-decoration-none text-primary fw-semibold" @click.prevent="showPrivacyModal = true">
                Saiba como protegemos seus dados
              </a>
            </div>
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

    <!-- Modal de Informações LGPD & Segurança -->
    <div class="modal-backdrop fade show" v-if="showPrivacyModal"></div>
    <div
      class="modal fade show d-block"
      tabindex="-1"
      v-if="showPrivacyModal"
      role="dialog"
      aria-modal="true"
    >
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content shadow-lg border-0 rounded-4">
          <div class="modal-header border-0 pb-0">
            <h5 class="modal-title fw-800 text-body d-flex align-items-center gap-2">
              <i class="bi bi-shield-check text-success"></i>
              Segurança & Proteção de Dados (LGPD)
            </h5>
            <button
              type="button"
              class="btn-close"
              @click="showPrivacyModal = false"
              aria-label="Fechar"
            ></button>
          </div>
          <div class="modal-body px-4 py-3 small text-secondary">
            <h6 class="fw-bold text-body mb-2">1. Dados de Conexão Coletados</h6>
            <p class="mb-3">
              Para proteger sua conta contra invasões e acessos não autorizados, registramos de forma segura seu <strong>endereço IP</strong>, <strong>tipo de dispositivo/navegador</strong> e <strong>horário de acesso</strong>, conforme previsto no Art. 7º, inciso IX da LGPD (Legítimo Interesse e Segurança do Titular) e Art. 15 do Marco Civil da Internet.
            </p>

            <h6 class="fw-bold text-body mb-2">2. Resiliência a IPs Rotativos & Dispositivo Confiável</h6>
            <p class="mb-3">
              Ao marcar "Lembrar este dispositivo", um identificador seguro (Device Token) é registrado para reconhecer seu navegador mesmo quando o modem reiniciar ou o IP rotativo da sua operadora mudar, evitando solicitações repetidas de autenticação em dois fatores.
            </p>

            <h6 class="fw-bold text-body mb-2">3. Boas Práticas OWASP</h6>
            <p class="mb-0">
              Nossa plataforma implementa criptografia de ponta a ponta para credenciais, bloqueio progressivo contra ataques de força bruta e logs de auditoria invioláveis.
            </p>
          </div>
          <div class="modal-footer border-0 pt-0 px-4 pb-4">
            <button
              type="button"
              class="btn btn-primary btn-sm rounded-pill px-4 fw-bold"
              @click="showPrivacyModal = false"
            >
              Entendido
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { api, getOrCreateDeviceToken } from '@/services/api'
import { clearStaffAccessToken, saveStaffSession } from '@/services/staffAuth'
import LoginVerificationModal from '@/components/LoginVerificationModal.vue'

const router = useRouter()
const route = useRoute()

const isDarkMode = ref(localStorage.getItem('easyslotting_theme') === 'dark')
const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

const showPassword = ref(false)
const showPrivacyModal = ref(false)

// ─── Verification State (Novo Dispositivo / IP - Estilo Discord) ──────────────
const showVerificationModal = ref(false)
const maskedEmail = ref('')
const verificationError = ref('')

// ─── Rate limiting frontend ──────────────────────────────────────────────────
const MAX_ATTEMPTS = 5
const LOCKOUT_SECONDS = 30
const failedAttempts = ref(0)
const lockedUntil = ref(null)
const lockCountdown = ref(0)
let countdownTimer = null

const isLocked = computed(() => {
  return lockedUntil.value && Date.now() < lockedUntil.value
})

const startLockoutCountdown = () => {
  if (countdownTimer) clearInterval(countdownTimer)
  lockCountdown.value = LOCKOUT_SECONDS
  countdownTimer = setInterval(() => {
    lockCountdown.value--
    if (lockCountdown.value <= 0) {
      clearInterval(countdownTimer)
      lockedUntil.value = null
      failedAttempts.value = 0
      errorMsg.value = ''
    }
  }, 1000)
}

const form = reactive({
  email: '',
  password: '',
  remember: false
})

watch(
  isDarkMode,
  (newVal) => {
    const theme = newVal ? 'dark' : 'light'
    document.documentElement.setAttribute('data-bs-theme', theme)
    localStorage.setItem('easyslotting_theme', theme)
  },
  { immediate: true }
)

const clearSession = () => {
  ;['access-token', 'client', 'uid', 'user', 'role', 'establishment-permissions', 'site-slug', 'salon-config', 'establishment-data'].forEach((key) => {
    localStorage.removeItem(key)
    sessionStorage.removeItem(key)
  })
  ;['customer-access-token', 'customer-data', 'customer-slug', 'customer-token-expires', 'customer-csrf-token'].forEach((key) => {
    localStorage.removeItem(key)
    sessionStorage.removeItem(key)
  })
  clearStaffAccessToken()
}

const handleLogin = async (otpCode = null) => {
  errorMsg.value = ''
  successMsg.value = ''
  verificationError.value = ''

  // 🔒 Bloqueio por tentativas excessivas
  if (isLocked.value) {
    errorMsg.value = `Muitas tentativas. Aguarde ${lockCountdown.value}s antes de tentar novamente.`
    return
  }

  if (!form.email.trim() || !form.password.trim()) {
    errorMsg.value = 'Preencha o e-mail e a senha.'
    return
  }

  try {
    loading.value = true

    const payload = {
      email: form.email.trim().toLowerCase(),
      password: form.password,
      device_token: getOrCreateDeviceToken()
    }
    if (typeof otpCode === 'string' && otpCode.trim().length > 0) {
      payload.otp_code = otpCode.trim()
    }

    const response = await api.post('/devise_users/sign_in', payload)

    // 🔒 Verificação de Novo Dispositivo / IP (Estilo Discord)
    if (response.data?.requires_verification) {
      maskedEmail.value = response.data.email_masked || form.email
      showVerificationModal.value = true
      return
    }

    const accessToken = response.headers['access-token']
    const client = response.headers['client']
    const uid = response.headers['uid']
    const user = response.data?.data || {}

    if (!accessToken || !client || !uid) {
      errorMsg.value = 'Erro de autenticação. Tente novamente.'
      return
    }

    const role = user?.role

    // 🔒 Apenas owner, employee e super_admin podem acessar o sistema
    if (role !== 'owner' && role !== 'employee' && role !== 'super_admin') {
      failedAttempts.value++
      if (failedAttempts.value >= MAX_ATTEMPTS) {
        lockedUntil.value = Date.now() + LOCKOUT_SECONDS * 1000
        startLockoutCountdown()
        errorMsg.value = `Acesso bloqueado por ${LOCKOUT_SECONDS}s após muitas tentativas.`
      } else {
        const remaining = MAX_ATTEMPTS - failedAttempts.value
        errorMsg.value = `Este acesso é exclusivo para empresas. Use o login do cliente. (${remaining} tentativa${remaining === 1 ? '' : 's'} restante${remaining === 1 ? '' : 's'})`
      }
      return
    }

    // Login bem-sucedido — zera tentativas e fecha modal
    failedAttempts.value = 0
    showVerificationModal.value = false
    clearSession()
    saveStaffSession(accessToken, client, uid, user, response.data?.staff_csrf_token)

    successMsg.value = 'Login realizado com sucesso! Redirecionando...'

    if (role === 'employee' && user?.allow_password_change === false) {
      setTimeout(() => {
        router.push({ name: 'admin-agendamentos', query: { first_access: '1' } })
      }, 600)
      return
    }

    const redirectQuery = route.query.redirect
    let redirectTo

    if (
      typeof redirectQuery === 'string' &&
      redirectQuery.trim() !== '' &&
      redirectQuery.startsWith('/') &&
      !redirectQuery.startsWith('//') &&
      !redirectQuery.startsWith('/\\') &&
      !redirectQuery.includes('://')
    ) {
      redirectTo = redirectQuery
    } else if (role === 'super_admin') {
      redirectTo = '/super-admin/dashboard'
    } else if (role === 'employee') {
      redirectTo = '/admin/agendamentos'
    } else {
      redirectTo = '/admin/estabelecimento'
    }

    setTimeout(() => router.push(redirectTo), 600)

  } catch (err) {
    if (['OWNER_SESSION_LIMIT_REACHED', 'STAFF_SESSION_LIMIT_REACHED'].includes(err.response?.data?.code)) {
      showVerificationModal.value = false
      errorMsg.value = err.response.data.errors?.[0] || 'Limite de aparelhos conectados atingido. Encerre uma sessão em outro aparelho para entrar.'
      return
    }
    failedAttempts.value++

    if (failedAttempts.value >= MAX_ATTEMPTS) {
      lockedUntil.value = Date.now() + LOCKOUT_SECONDS * 1000
      startLockoutCountdown()
      errorMsg.value = `Acesso bloqueado por ${LOCKOUT_SECONDS}s após muitas tentativas.`
    } else {
      const remaining = MAX_ATTEMPTS - failedAttempts.value
      const serverMsg =
        err.response?.data?.errors?.[0] ||
        err.response?.data?.message ||
        (err.message === 'Network Error' ? 'Erro de conexão com o servidor. Verifique se a API está em execução.' : 'E-mail ou senha incorretos.')

      if (err.response?.status === 429) {
        lockedUntil.value = Date.now() + LOCKOUT_SECONDS * 1000
        startLockoutCountdown()
        errorMsg.value = 'Muitas tentativas detectadas pelo servidor. Aguarde antes de tentar novamente.'
      } else if (showVerificationModal.value) {
        verificationError.value = serverMsg
      } else if (!err.response) {
        errorMsg.value = serverMsg
      } else {
        errorMsg.value = `${serverMsg} (${remaining} tentativa${remaining === 1 ? '' : 's'} restante${remaining === 1 ? '' : 's'})`
      }
    }
  } finally {
    loading.value = false
  }
}

const handleVerifyOtp = async (code) => {
  verificationError.value = ''
  await handleLogin(code)
}

const handleResendOtp = async () => {
  verificationError.value = ''
  try {
    await api.post('/devise_users/sign_in', {
      email: form.email.trim().toLowerCase(),
      password: form.password,
      device_token: getOrCreateDeviceToken()
    })
  } catch (err) {
    verificationError.value = err.response?.data?.errors?.[0] || 'Não foi possível reenviar o código.'
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
  max-width: 420px;
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

#darkToggleSistema:checked + .theme-switch .ball {
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
