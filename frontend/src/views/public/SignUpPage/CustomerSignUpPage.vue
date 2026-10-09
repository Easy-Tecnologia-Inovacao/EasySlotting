<template>
  <div class="register-page bg-body text-body min-vh-100 d-flex flex-column position-relative" :data-bs-theme="isDarkMode ? 'dark' : 'light'">

    <!-- Theme toggle idêntico ao login -->
    <div class="theme-switch-wrapper">
      <input type="checkbox" id="darkToggleClienteCadastro" class="visually-hidden-check" v-model="isDarkMode">
      <label for="darkToggleClienteCadastro" class="theme-switch mb-0">
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
          <p class="text-secondary small fw-600 mb-0">Crie sua conta para agendar serviços</p>
        </div>

        <div class="account-type-banner p-2 rounded-4 mb-4 text-center fw-bold">
          <i class="bi bi-person me-2"></i>
          Conta para cliente
        </div>

        <!-- Erro inline -->
        <div v-if="errorMsg" class="alert-inline alert-inline--error mb-3">
          <i class="bi bi-exclamation-circle-fill me-2"></i>{{ errorMsg }}
        </div>

        <!-- Sucesso inline -->
        <div v-if="successMsg" class="alert-inline alert-inline--success mb-3">
          <i class="bi bi-check-circle-fill me-2"></i>{{ successMsg }}
        </div>

        <form @submit.prevent="handleRegister" novalidate>
          <!-- Nome Completo -->
          <div class="mb-3">
            <label class="form-label-custom" for="clienteNome">Nome Completo</label>
            <input
              id="clienteNome"
              type="text"
              class="form-control custom-input"
              placeholder="Seu nome completo"
              autocomplete="name"
              required
              v-model="form.name"
            >
          </div>

          <!-- E-mail -->
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

          <!-- Celular e Telefone (WhatsApp e contato) -->
          <div class="row g-2 mb-3">
            <div class="col-6">
              <label class="form-label-custom" for="clienteCelular">
                Celular <span class="text-primary">(WhatsApp)</span>
              </label>
              <input
                id="clienteCelular"
                type="tel"
                class="form-control custom-input"
                placeholder="(11) 99999-9999"
                autocomplete="tel"
                maxlength="15"
                required
                v-model="form.cellphone"
              >
            </div>

            <div class="col-6">
              <label class="form-label-custom" for="clienteTelefone">
                Telefone <span class="text-muted fw-normal">(opcional)</span>
              </label>
              <input
                id="clienteTelefone"
                type="tel"
                class="form-control custom-input"
                placeholder="(11) 3333-4444"
                autocomplete="tel"
                maxlength="15"
                v-model="form.phone"
              >
            </div>
          </div>

          <!-- Senha e Confirmação -->
          <div class="row g-2 mb-2">
            <div class="col-6">
              <label class="form-label-custom" for="clienteSenha">Senha</label>
              <div class="position-relative">
                <input
                  id="clienteSenha"
                  :type="showPassword ? 'text' : 'password'"
                  class="form-control custom-input pe-5"
                  placeholder="••••••••"
                  autocomplete="new-password"
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

            <div class="col-6">
              <label class="form-label-custom" for="clienteConfirmaSenha">Confirmar</label>
              <div class="position-relative">
                <input
                  id="clienteConfirmaSenha"
                  :type="showConfirmPassword ? 'text' : 'password'"
                  class="form-control custom-input pe-5"
                  placeholder="••••••••"
                  autocomplete="new-password"
                  required
                  v-model="form.confirmPassword"
                >
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
            </div>
          </div>

          <!-- Indicador de força da senha -->
          <div v-if="form.password" class="mb-3 px-1">
            <div class="password-strength-bar mb-1">
              <div class="password-strength-fill" :style="{ width: Math.max(10, 100 - passwordErrors.length * 20) + '%' }"></div>
            </div>
            <ul v-if="passwordErrors.length > 0" class="list-unstyled mb-0 extra-small">
              <li v-for="(err, i) in passwordErrors" :key="i" class="text-danger">
                <i class="bi bi-x-circle me-1"></i>{{ err }}
              </li>
            </ul>
            <p v-else class="text-success extra-small mb-0 fw-semibold">
              <i class="bi bi-check-circle me-1"></i>Senha atende a todos os requisitos
            </p>
          </div>

          <!-- Termos e LGPD Checkboxes -->
          <div class="mb-4 pt-1">
            <div class="form-check mb-2">
              <input
                class="form-check-input"
                type="checkbox"
                id="clienteConsentTerms"
                v-model="form.consentTerms"
                required
              >
              <label class="form-check-label small text-body fw-semibold" for="clienteConsentTerms">
                Li e aceito os
                <router-link :to="termsRoute" target="_blank" class="text-primary text-decoration-none fw-bold">
                  Termos de Uso
                </router-link>
              </label>
            </div>

            <div class="form-check">
              <input
                class="form-check-input"
                type="checkbox"
                id="clienteConsentPrivacy"
                v-model="form.consentPrivacy"
                required
              >
              <label class="form-check-label small text-body fw-semibold" for="clienteConsentPrivacy">
                Concordo com a
                <router-link :to="privacyRoute" target="_blank" class="text-primary text-decoration-none fw-bold">
                  Política de Privacidade
                </router-link>
              </label>
            </div>
          </div>

          <button
            type="submit"
            id="btnClienteCadastro"
            class="btn btn-primary w-100 py-2-5 rounded-pill fw-bold shadow-sm"
            :disabled="loading || !form.consentTerms || !form.consentPrivacy"
          >
            <span v-if="loading" class="spinner-border spinner-border-sm me-2" role="status"></span>
            <span>{{ loading ? 'Criando conta...' : 'CRIAR CONTA' }}</span>
          </button>

          <div class="text-center mt-3">
            <p class="small text-muted mb-0">
              Já tem uma conta?
              <router-link :to="loginRoute" class="fw-bold text-decoration-none text-primary">
                Fazer Login
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
            <p class="text-secondary extra-small mb-0">
              Seus dados pessoais são protegidos com sigilo e criptografia conforme a Lei 13.709/2018 (LGPD).
            </p>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { api, getOrCreateDeviceToken } from '@/services/api'
import { useThemeStore } from '@/stores/themeStore'

const router = useRouter()
const route  = useRoute()
const store  = useThemeStore()

const isDarkMode = ref(localStorage.getItem('easyslotting_theme') === 'dark')
const loading    = ref(false)
const errorMsg   = ref('')
const successMsg = ref('')

const showPassword        = ref(false)
const showConfirmPassword = ref(false)

const form = reactive({
  name:            '',
  email:           '',
  phone:           '',
  cellphone:       '',
  password:        '',
  confirmPassword: '',
  consentTerms:    false,
  consentPrivacy:  false
})

// Máscara brasileira de telefone/celular
const applyPhoneMask = (value: string): string => {
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

// Validação de senha forte (mesmas regras do backend)
const passwordErrors = ref<string[]>([])
function validatePasswordStrength(password: string): string[] {
  const errors: string[] = []
  if (password.length < 8) errors.push('Mínimo 8 caracteres')
  if (!/[A-Z]/.test(password)) errors.push('Pelo menos 1 letra maiúscula')
  if (!/[a-z]/.test(password)) errors.push('Pelo menos 1 letra minúscula')
  if (!/[0-9]/.test(password)) errors.push('Pelo menos 1 número')
  if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) errors.push('Pelo menos 1 caractere especial')
  const obviousWords = ['admin', 'senha', 'password', '123456', 'easyslotting', 'agendamento', 'barbearia']
  const lowerPass = password.toLowerCase()
  for (const word of obviousWords) {
    if (lowerPass.includes(word)) errors.push(`Não pode conter "${word}"`)
  }
  return errors
}

watch(() => form.password, (val) => {
  passwordErrors.value = val ? validatePasswordStrength(val) : []
})

// Slug da rota /empresa/:slug/cadastro
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

const loginRoute = computed(() => {
  const base = currentSlug.value
    ? `/empresa/${currentSlug.value}/login`
    : '/cliente/login'
  return route.query.redirect
    ? `${base}?redirect=${encodeURIComponent(String(route.query.redirect))}`
    : base
})

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
    localStorage.setItem('easyslotting_theme', theme)
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
        // Fallback gracioso
      }
    }
  }
})

const handleRegister = async () => {
  errorMsg.value   = ''
  successMsg.value = ''

  if (!form.name.trim() || !form.email.trim() || !form.password.trim()) {
    errorMsg.value = 'Preencha o nome completo, e-mail e a senha.'
    return
  }

  if (!form.cellphone.trim()) {
    errorMsg.value = 'Informe seu número de celular para contato e avisos de agendamento.'
    return
  }

  // Validação de formato de celular (10 ou 11 dígitos)
  const cellDigits = form.cellphone.replace(/\D/g, '')
  if (cellDigits.length < 10 || cellDigits.length > 11) {
    errorMsg.value = 'Número de celular inválido. Formato esperado: (99) 99999-9999'
    return
  }

  if (form.password !== form.confirmPassword) {
    errorMsg.value = 'As senhas não coincidem.'
    return
  }

  passwordErrors.value = validatePasswordStrength(form.password)
  if (passwordErrors.value.length > 0) {
    errorMsg.value = 'A senha não atende aos requisitos de segurança.'
    return
  }

  if (!form.consentTerms) {
    errorMsg.value = 'Você precisa aceitar os Termos de Uso para criar sua conta.'
    return
  }

  if (!form.consentPrivacy) {
    errorMsg.value = 'Você precisa concordar com a Política de Privacidade.'
    return
  }

  if (!currentSlug.value) {
    errorMsg.value = 'Estabelecimento não identificado. Acesse pelo link correto.'
    return
  }

  try {
    loading.value = true

    const payload = {
      name:                  form.name.trim(),
      email:                 form.email.trim().toLowerCase(),
      phone:                 form.phone.trim(),
      cellphone:             form.cellphone.trim(),
      password:              form.password,
      password_confirmation: form.confirmPassword,
      consent_terms:         form.consentTerms,
      consent_privacy:       form.consentPrivacy,
      device_token:          getOrCreateDeviceToken()
    }

    const response = await api.post(`/customer_auth/${currentSlug.value}/sign_up`, payload)

    successMsg.value = 'Conta criada com sucesso! Faça login para continuar.'
    setTimeout(() => router.push('/empresa/' + encodeURIComponent(currentSlug.value) + '/login'), 600)

  } catch (error: any) {
    const errs = error.response?.data?.errors
    errorMsg.value = Array.isArray(errs)
      ? errs.join(', ')
      : (error.response?.data?.error || 'Erro ao realizar o cadastro. Tente novamente.')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.register-page {
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

.account-type-banner {
  background: rgba(13, 110, 253, 0.08);
  border: 1px solid rgba(13, 110, 253, 0.12);
  color: var(--bs-primary);
  font-size: 0.85rem;
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

.password-strength-bar {
  height: 4px;
  background: #e9ecef;
  border-radius: 2px;
  overflow: hidden;
}

[data-bs-theme='dark'] .password-strength-bar {
  background: rgba(255, 255, 255, 0.1);
}

.password-strength-fill {
  height: 100%;
  background: linear-gradient(90deg, #dc3545, #fd7e14, #ffc107, #28a745);
  border-radius: 2px;
  transition: width 0.3s ease;
}

/* Theme switch idêntico ao login */
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

#darkToggleClienteCadastro:checked + .theme-switch .ball {
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

.extra-small {
  font-size: 0.75rem;
}
</style>