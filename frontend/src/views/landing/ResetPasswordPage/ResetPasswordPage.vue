<template>
  <div
    class="reset-page bg-body text-body min-vh-100 d-flex flex-column"
    :data-bs-theme="isDarkMode ? 'dark' : 'light'"
  >
    <!-- Theme toggle -->
    <div class="theme-switch-wrapper">
      <input type="checkbox" id="darkToggleReset" class="visually-hidden-check" v-model="isDarkMode" />
      <label for="darkToggleReset" class="theme-switch mb-0">
        <div class="ball"></div>
        <i class="bi bi-sun-fill text-warning" style="font-size: 14px;"></i>
        <i class="bi bi-moon-stars-fill text-secondary" style="font-size: 14px;"></i>
      </label>
    </div>

    <div class="container flex-grow-1 d-flex justify-content-center align-items-center py-5">
      <div class="reset-card shadow-lg">

        <!-- Token inválido / ausente -->
        <template v-if="!hasToken">
          <div class="text-center">
            <router-link to="/" class="text-decoration-none">
              <h2 class="fw-800 text-primary mb-1">EASYSLOTTING</h2>
            </router-link>
            <div class="my-4">
              <i class="bi bi-shield-lock text-danger" style="font-size: 3rem;"></i>
            </div>
            <h5 class="fw-bold mb-2">Link inválido</h5>
            <p class="text-muted small mb-4">
              O link de redefinição de senha é inválido ou expirou. Solicite um novo link.
            </p>
            <router-link
              to="/esqueci-senha"
              class="btn btn-primary rounded-pill fw-bold px-4"
            >
              Solicitar novo link
            </router-link>
          </div>
        </template>

        <!-- Sucesso -->
        <template v-else-if="resetSuccess">
          <div class="text-center">
            <router-link to="/" class="text-decoration-none">
              <h2 class="fw-800 text-primary mb-1">EASYSLOTTING</h2>
            </router-link>
            <div class="success-icon my-4">
              <i class="bi bi-check-circle-fill text-success" style="font-size: 3rem;"></i>
            </div>
            <h5 class="fw-bold mb-2">Senha redefinida!</h5>
            <p class="text-muted small mb-4">
              Sua senha foi alterada com sucesso. Você já pode acessar o sistema com a nova senha.
            </p>
            <router-link
              to="/sistema/login"
              class="btn btn-primary rounded-pill fw-bold px-4"
            >
              Ir para o login
            </router-link>
          </div>
        </template>

        <!-- Formulário de redefinição -->
        <template v-else>
          <!-- Header -->
          <div class="text-center mb-4">
            <router-link to="/" class="text-decoration-none">
              <h2 class="fw-800 text-primary mb-1">EASYSLOTTING</h2>
            </router-link>
            <p class="text-secondary small fw-600">Redefinir senha</p>
          </div>

          <!-- Erro inline -->
          <div v-if="errorMsg" class="alert-inline alert-inline--error mb-3">
            <i class="bi bi-exclamation-circle-fill me-2"></i>{{ errorMsg }}
          </div>

          <form @submit.prevent="handleResetPassword" novalidate>
            <div class="mb-3">
              <label class="form-label-custom" for="resetPassword">Nova senha</label>
              <div class="input-group">
                <input
                  id="resetPassword"
                  :type="showPassword ? 'text' : 'password'"
                  class="form-control custom-input"
                  placeholder="••••••••"
                  autocomplete="new-password"
                  required
                  v-model="form.password"
                />
                <button
                  type="button"
                  class="btn btn-outline-secondary custom-input-btn"
                  @click="showPassword = !showPassword"
                  tabindex="-1"
                >
                  <i :class="showPassword ? 'bi bi-eye-slash' : 'bi bi-eye'"></i>
                </button>
              </div>
              <div class="password-requirements mt-2" v-if="form.password">
                <div class="req" :class="{ met: form.password.length >= 8 }">
                  <i :class="form.password.length >= 8 ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                  Mínimo 8 caracteres
                </div>
                <div class="req" :class="{ met: /[A-Z]/.test(form.password) }">
                  <i :class="/[A-Z]/.test(form.password) ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                  Uma letra maiúscula
                </div>
                <div class="req" :class="{ met: /[a-z]/.test(form.password) }">
                  <i :class="/[a-z]/.test(form.password) ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                  Uma letra minúscula
                </div>
                <div class="req" :class="{ met: /[0-9]/.test(form.password) }">
                  <i :class="/[0-9]/.test(form.password) ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                  Um número
                </div>
                <div class="req" :class="{ met: /[^A-Za-z0-9]/.test(form.password) }">
                  <i :class="/[^A-Za-z0-9]/.test(form.password) ? 'bi bi-check-circle-fill text-success' : 'bi bi-circle'"></i>
                  Um caractere especial
                </div>
              </div>
            </div>

            <div class="mb-4">
              <label class="form-label-custom" for="resetPasswordConfirm">Confirmar nova senha</label>
              <input
                id="resetPasswordConfirm"
                type="password"
                class="form-control custom-input"
                placeholder="••••••••"
                autocomplete="new-password"
                required
                v-model="form.password_confirmation"
              />
              <div
                v-if="form.password_confirmation && form.password !== form.password_confirmation"
                class="text-danger small mt-1 fw-semibold"
              >
                <i class="bi bi-exclamation-triangle-fill me-1"></i>As senhas não coincidem
              </div>
            </div>

            <button
              type="submit"
              class="btn btn-primary w-100 py-2-5 rounded-pill fw-bold shadow-sm"
              :disabled="loading || !isFormValid"
            >
              <span v-if="loading" class="spinner-border spinner-border-sm me-2" role="status"></span>
              {{ loading ? 'Redefinindo...' : 'REDEFINIR SENHA' }}
            </button>
          </form>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '@/services/api'

const route = useRoute()

const isDarkMode = ref(localStorage.getItem('easysloting_theme') === 'dark')
const loading = ref(false)
const errorMsg = ref('')
const resetSuccess = ref(false)
const showPassword = ref(false)

const form = reactive({
  password: '',
  password_confirmation: ''
})

const hasToken = computed(() => {
  return !!route.query.reset_password_token
})

const isFormValid = computed(() => {
  return (
    form.password.length >= 8 &&
    /[A-Z]/.test(form.password) &&
    /[a-z]/.test(form.password) &&
    /[0-9]/.test(form.password) &&
    /[^A-Za-z0-9]/.test(form.password) &&
    form.password === form.password_confirmation
  )
})

watch(
  isDarkMode,
  (newVal) => {
    const theme = newVal ? 'dark' : 'light'
    document.documentElement.setAttribute('data-bs-theme', theme)
    localStorage.setItem('easysloting_theme', theme)
  },
  { immediate: true }
)

const handleResetPassword = async () => {
  errorMsg.value = ''

  if (!form.password || !form.password_confirmation) {
    errorMsg.value = 'Preencha todos os campos.'
    return
  }

  if (form.password !== form.password_confirmation) {
    errorMsg.value = 'As senhas não coincidem.'
    return
  }

  if (!isFormValid.value) {
    errorMsg.value = 'A senha não atende aos requisitos de segurança.'
    return
  }

  try {
    loading.value = true

    await api.put('/devise_users/password', {
      reset_password_token: route.query.reset_password_token,
      password: form.password,
      password_confirmation: form.password_confirmation
    })

    resetSuccess.value = true
  } catch (err) {
    const serverMsg =
      err.response?.data?.errors?.[0] ||
      err.response?.data?.message ||
      (err.message === 'Network Error'
        ? 'Erro de conexão com o servidor.'
        : 'Erro ao redefinir senha. O link pode ter expirado.')

    errorMsg.value = serverMsg
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.reset-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  transition: background 0.4s ease;
}

.reset-card {
  background: var(--bs-body-tertiary);
  backdrop-filter: blur(15px);
  border: 1px solid rgba(0, 0, 0, 0.08);
  border-radius: 28px;
  padding: 2.5rem;
  width: 100%;
  max-width: 420px;
}

[data-bs-theme='dark'] .reset-card {
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3) !important;
}

.custom-input {
  border-radius: 12px;
  padding: 12px 15px;
  font-size: 0.9rem;
  transition: all 0.25s ease;
}

.custom-input-btn {
  border-radius: 12px !important;
  border: 1px solid rgba(0, 0, 0, 0.6) !important;
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

#darkToggleReset:checked + .theme-switch .ball {
  transform: translateX(27px);
}

@media (max-width: 576px) {
  .reset-card {
    padding: 2rem;
    border-radius: 0;
    border: none;
    background: transparent;
    box-shadow: none !important;
  }
}
</style>
