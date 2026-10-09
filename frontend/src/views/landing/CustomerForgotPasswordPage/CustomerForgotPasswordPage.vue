<template>
  <div
    class="forgot-page bg-body text-body min-vh-100 d-flex flex-column"
    :data-bs-theme="isDarkMode ? 'dark' : 'light'"
  >
    <div class="theme-switch-wrapper">
      <input type="checkbox" id="darkToggleCForgot" class="visually-hidden-check" v-model="isDarkMode" />
      <label for="darkToggleCForgot" class="theme-switch mb-0">
        <div class="ball"></div>
        <i class="bi bi-sun-fill text-warning" style="font-size: 14px;"></i>
        <i class="bi bi-moon-stars-fill text-secondary" style="font-size: 14px;"></i>
      </label>
    </div>

    <div class="container flex-grow-1 d-flex justify-content-center align-items-center py-5">
      <div class="forgot-card shadow-lg">

        <div class="text-center mb-4">
          <router-link :to="backRoute" class="text-decoration-none">
            <h2 class="fw-800 text-primary mb-1">{{ establishmentName }}</h2>
          </router-link>
          <p class="text-secondary small fw-600">Recupere sua senha</p>
        </div>

        <template v-if="!emailSent">
          <p class="text-muted small mb-3 text-center">
            Informe o e-mail associado à sua conta e enviaremos um link para redefinir sua senha.
          </p>

          <div v-if="errorMsg" class="alert-inline alert-inline--error mb-3">
            <i class="bi bi-exclamation-circle-fill me-2"></i>{{ errorMsg }}
          </div>

          <form @submit.prevent="handleRequestReset" novalidate>
            <div class="mb-4">
              <label class="form-label-custom" for="forgotEmail">E-mail</label>
              <div style="position: relative;">
                <input type="password" style="position: absolute; width: 0; height: 0; opacity: 0; border: none; padding: 0; margin: 0;" tabindex="-1" autocomplete="new-password">
                <input
                  id="forgotEmail"
                  type="email"
                  class="form-control custom-input"
                  placeholder="seu@email.com"
                  required
                  v-model="form.email"
                />
              </div>
            </div>

            <button
              type="submit"
              class="btn btn-primary w-100 py-2-5 rounded-pill fw-bold shadow-sm"
              :disabled="loading"
            >
              <span v-if="loading" class="spinner-border spinner-border-sm me-2" role="status"></span>
              {{ loading ? 'Enviando...' : 'ENVIAR LINK DE RECUPERAÇÃO' }}
            </button>
          </form>
        </template>

        <template v-else>
          <div class="text-center">
            <div class="success-icon mb-3">
              <i class="bi bi-envelope-check-fill text-success" style="font-size: 3rem;"></i>
            </div>
            <h5 class="fw-bold mb-2">E-mail enviado!</h5>
            <p class="text-muted small mb-4">
              Enviamos um link de redefinição de senha para
              <strong>{{ form.email }}</strong>. Verifique sua caixa de entrada e também a pasta de spam.
            </p>
            <p class="text-muted small mb-4">
              O link expira em <strong>30 minutos</strong>.
            </p>

            <div class="d-flex flex-column gap-2">
              <button
                class="btn btn-outline-primary rounded-pill fw-bold"
                @click="resetState"
              >
                <i class="bi bi-arrow-left me-2"></i>Voltar
              </button>
              <router-link
                :to="loginRoute"
                class="btn btn-link text-decoration-none fw-bold"
              >
                Ir para o login
              </router-link>
            </div>
          </div>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '@/services/api'
import { useThemeStore } from '@/stores/themeStore'

const route = useRoute()
const store = useThemeStore()

const isDarkMode = ref(localStorage.getItem('easysloting_theme') === 'dark')
const loading = ref(false)
const errorMsg = ref('')
const emailSent = ref(false)

const form = reactive({ email: '' })

const currentSlug = computed(() =>
  String(route.params.slug || '') ||
  sessionStorage.getItem('site-slug') ||
  localStorage.getItem('site-slug') ||
  ''
)

const establishmentName = computed(() => store.salonConfig?.nome || 'EasySloting')

const backRoute = computed(() =>
  currentSlug.value ? `/empresa/${currentSlug.value}` : '/'
)

const loginRoute = computed(() =>
  currentSlug.value ? `/empresa/${currentSlug.value}/login` : '/sistema/login'
)

onMounted(() => {
  if (route.params.slug) {
    const slug = String(route.params.slug)
    sessionStorage.setItem('site-slug', slug)
    localStorage.setItem('site-slug', slug)
  }
})

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

const resetState = () => {
  emailSent.value = false
  errorMsg.value = ''
  form.email = ''
}

const handleRequestReset = async () => {
  errorMsg.value = ''

  if (!form.email.trim()) {
    errorMsg.value = 'Informe o e-mail da sua conta.'
    return
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailRegex.test(form.email.trim())) {
    errorMsg.value = 'E-mail inválido.'
    return
  }

  if (!currentSlug.value) {
    errorMsg.value = 'Estabelecimento não identificado.'
    return
  }

  try {
    loading.value = true

    await api.post(`/customer_auth/${currentSlug.value}/forgot_password`, {
      email: form.email.trim().toLowerCase()
    })

    emailSent.value = true
  } catch (err) {
    const serverMsg =
      err.response?.data?.errors?.[0] ||
      err.response?.data?.message ||
      (err.message === 'Network Error'
        ? 'Erro de conexão com o servidor.'
        : 'Erro ao enviar o e-mail. Tente novamente.')

    errorMsg.value = serverMsg
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.forgot-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
  transition: background 0.4s ease;
}

.forgot-card {
  background: var(--bs-body-tertiary);
  backdrop-filter: blur(15px);
  border: 1px solid rgba(0, 0, 0, 0.08);
  border-radius: 28px;
  padding: 2.5rem;
  width: 100%;
  max-width: 420px;
}

[data-bs-theme='dark'] .forgot-card {
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

#darkToggleCForgot:checked + .theme-switch .ball {
  transform: translateX(27px);
}

@media (max-width: 576px) {
  .forgot-card {
    padding: 2rem;
    border-radius: 0;
    border: none;
    background: transparent;
    box-shadow: none !important;
  }
}
</style>
