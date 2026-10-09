<template>
  <div class="register-page bg-body text-body min-vh-100" :data-bs-theme="isDarkMode ? 'dark' : 'light'">
    <div class="theme-switch-wrapper">
      <input type="checkbox" id="darkToggle" class="d-none" v-model="isDarkMode">
      <label for="darkToggle" class="theme-switch mb-0">
        <div class="ball"></div>
        <i class="bi bi-sun-fill text-warning" style="font-size: 14px;"></i>
        <i class="bi bi-moon-stars-fill text-secondary" style="font-size: 14px;"></i>
      </label>
    </div>

    <div class="page-content">
      <div class="container d-flex justify-content-center align-items-center py-5">
        <div class="login-card shadow-lg">
          <div class="text-center mb-4">
            <router-link to="/" class="text-decoration-none">
              <h2 class="fw-800 text-primary mb-1">EASYSLOTTING</h2>
            </router-link>
            <p class="text-secondary small fw-600">Crie sua conta empresarial em 2 etapas</p>
          </div>

          <!-- Step Progress Indicator -->
          <div class="d-flex justify-content-center mb-4">
            <div class="step-indicator" :class="{ active: currentStep >= 1 }">1</div>
            <div class="step-line" :class="{ active: currentStep >= 2 }"></div>
            <div class="step-indicator" :class="{ active: currentStep >= 2 }">2</div>
          </div>

          <div class="account-type-banner p-2 rounded-4 mb-4 text-center fw-bold">
            <i class="bi bi-buildings me-2"></i>
            {{ currentStep === 1 ? 'Dados da Empresa e Acesso' : 'Dados da Home e Agendamento' }}
          </div>

          <form @submit.prevent="handleSubmit">
            <!-- STEP 1: Basic Info -->
            <div v-if="currentStep === 1">
              <div class="mb-3">
                <label class="form-label-custom">Nome do Proprietário</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  placeholder="Seu nome completo"
                  required
                  v-model="form.owner_name"
                  @input="sanitizeField('owner_name')"
                >
              </div>

              <div class="mb-3">
                <label class="form-label-custom">E-mail de Acesso</label>
                <div style="position: relative;">
                  <input type="password" style="position: absolute; width: 0; height: 0; opacity: 0; border: none; padding: 0; margin: 0;" tabindex="-1" autocomplete="new-password">
                  <input
                    type="email"
                    class="form-control custom-input"
                    placeholder="empresa@email.com"
                    required
                    v-model="form.email"
                  >
                </div>
              </div>

              <div class="row g-2">
                <div class="col-md-7 mb-3">
                  <label class="form-label-custom">CNPJ</label>
                  <input
                    type="text"
                    class="form-control custom-input"
                    placeholder="00.000.000/0001-00"
                    required
                    v-model="form.cnpj"
                    @input="onCNPJInput"
                  >
                </div>

                <div class="col-md-5 mb-3">
                  <label class="form-label-custom">Ramo</label>
                  <select
                    class="form-select custom-input"
                    required
                    v-model="form.category"
                  >
                    <option value="" disabled>Selecione</option>
                    <option>Barbearia</option>
                    <option>Salão</option>
                    <option>Estética</option>
                    <option>Clínica</option>
                    <option value="Outro">Outro</option>
                  </select>
                </div>
              </div>

              <transition name="fade">
                <div class="mb-3" v-if="form.category === 'Outro'">
                  <label class="form-label-custom">Especifique o Ramo</label>
                  <input
                    type="text"
                    class="form-control custom-input"
                    placeholder="Ex: Petshop, Consultório, etc."
                    required
                    v-model="form.custom_category"
                    @input="sanitizeField('custom_category')"
                    maxlength="50"
                  >
                </div>
              </transition>

              <div class="row g-2">
                <div class="col-6 mb-3">
                  <label class="form-label-custom">Senha</label>
                  <input
                    type="password"
                    class="form-control custom-input"
                    placeholder="••••••"
                    required
                    v-model="form.password"
                    minlength="6"
                  >
                </div>

                <div class="col-6 mb-3">
                  <label class="form-label-custom">Confirmar</label>
                  <input
                    type="password"
                    class="form-control custom-input"
                    placeholder="••••••"
                    required
                    v-model="form.password_confirmation"
                  >
                </div>
              </div>

              <button
                type="button"
                @click="nextStep"
                class="btn btn-primary w-100 mt-2 py-2-5 rounded-pill fw-bold shadow-sm"
              >
                PRÓXIMO PASSO <i class="bi bi-arrow-right ms-2"></i>
              </button>
            </div>

            <!-- STEP 2: Home & Scheduling Info -->
            <div v-if="currentStep === 2">
              <div class="mb-3">
                <label class="form-label-custom">Nome do Estabelecimento</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  placeholder="Nome fantasia que aparecerá no agendamento"
                  required
                  v-model="form.business_name"
                  @input="sanitizeField('business_name')"
                >
              </div>

              <div class="mb-3">
                <label class="form-label-custom">Endereço Completo</label>
                <input
                  type="text"
                  class="form-control custom-input"
                  placeholder="Rua, Número, Bairro, Cidade - UF"
                  required
                  v-model="form.address"
                  @input="sanitizeField('address')"
                >
              </div>

              <div class="row g-2">
                <div class="col-md-6 mb-3">
                  <label class="form-label-custom">Telefone Fixo</label>
                  <input
                    type="text"
                    class="form-control custom-input"
                    placeholder="(00) 0000-0000"
                    v-model="form.fixed_phone"
                    @input="onFixedPhoneInput"
                  >
                </div>

                <div class="col-md-6 mb-3">
                  <label class="form-label-custom">WhatsApp</label>
                  <input
                    type="text"
                    class="form-control custom-input"
                    placeholder="(00) 00000-0000"
                    required
                    v-model="form.whatsapp"
                    @input="onWhatsappInput"
                  >
                </div>
              </div>

              <div class="d-flex gap-2">
                <button
                  type="button"
                  @click="currentStep = 1"
                  class="btn btn-outline-secondary w-50 py-2-5 rounded-pill fw-bold"
                >
                  VOLTAR
                </button>
                <button
                  type="submit"
                  class="btn btn-primary w-50 py-2-5 rounded-pill fw-bold shadow-sm"
                  :disabled="loading"
                >
                  {{ loading ? 'Criando...' : 'FINALIZAR' }}
                </button>
              </div>
            </div>

            <div class="text-center mt-4">
              <p class="small text-muted mb-0">
                Já tem uma conta?
                <router-link to="/sistema/login" class="fw-bold text-decoration-none text-primary">
                  Fazer Login
                </router-link>
              </p>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/services/api'
import { setStaffAccessToken } from '@/services/staffAuth'

const router = useRouter()
const isDarkMode = ref(localStorage.getItem('easysloting_theme') === 'dark')
const loading = ref(false)
const currentStep = ref(1)

const form = reactive({
  owner_name: '',
  email: '',
  password: '',
  password_confirmation: '',
  cnpj: '',
  category: '',
  custom_category: '',
  business_name: '',
  address: '',
  fixed_phone: '',
  whatsapp: ''
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

const nextStep = () => {
  // Validações básicas do passo 1 antes de avançar
  if (!form.owner_name.trim() || !form.email.trim() || !form.cnpj || !form.category || !form.password) {
    alert('Por favor, preencha todos os campos obrigatórios do Passo 1.')
    return
  }
  if (form.category === 'Outro' && !form.custom_category.trim()) {
    alert('Por favor, especifique o seu ramo de atuação.')
    return
  }
  if (form.password !== form.password_confirmation) {
    alert('As senhas não coincidem.')
    return
  }

  // Validação de força da senha (mesmas regras do backend)
  const p = form.password
  const errors = []
  if (p.length < 8) errors.push('mínimo 8 caracteres')
  if (!/[A-Z]/.test(p)) errors.push('pelo menos uma letra maiúscula')
  if (!/[a-z]/.test(p)) errors.push('pelo menos uma letra minúscula')
  if (!/[0-9]/.test(p)) errors.push('pelo menos um número')
  if (!/[^A-Za-z0-9]/.test(p)) errors.push('pelo menos um caractere especial')

  const obviousWords = ['admin', 'senha', 'password', '123456', 'easysloting', 'agendamento', 'barbearia']
  for (const word of obviousWords) {
    if (p.toLowerCase().includes(word)) {
      errors.push(`não pode conter termos óbvios como '${word}'`)
      break
    }
  }

  if (errors.length > 0) {
    alert('Senha fraca: ' + errors.join(', ') + '.')
    return
  }

  currentStep.value = 2
}

const formatCNPJ = (value) => {
  const val = value.replace(/\D/g, '')
  return val
    .replace(/^(\d{2})(\d)/, '$1.$2')
    .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/\.(\d{3})(\d)/, '.$1/$2')
    .replace(/(\d{4})(\d)/, '$1-$2')
    .substring(0, 18)
}

const formatPhone = (value) => {
  const val = value.replace(/\D/g, '')
  if (val.length <= 10) {
    return val
      .replace(/^(\d{2})(\d)/, '($1) $2')
      .replace(/(\d{4})(\d)/, '$1-$2')
      .substring(0, 14)
  }
  return val
    .replace(/^(\d{2})(\d)/, '($1) $2')
    .replace(/(\d{5})(\d)/, '$1-$2')
    .substring(0, 15)
}

const onCNPJInput = (e) => {
  form.cnpj = formatCNPJ(e.target.value)
}

const onFixedPhoneInput = (e) => {
  form.fixed_phone = formatPhone(e.target.value)
}

const onWhatsappInput = (e) => {
  form.whatsapp = formatPhone(e.target.value)
}

const sanitizeField = (field) => {
  if (form[field]) {
    // Remove caracteres perigosos sem cortar o espaço que o usuário acabou de digitar.
    // O trim das extremidades acontece na validação/envio do formulário.
    form[field] = form[field].replace(/[<>]/g, '')
  }
}

const slugify = (value) =>
  value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')

const onlyDigits = (value) => value ? value.replace(/\D/g, '') : ''

const handleSubmit = async () => {
  const payload = {
    user: {
      name: form.owner_name.trim(),
      email: form.email.trim(),
      password: form.password,
      password_confirmation: form.password_confirmation
    },
    establishment: {
      name: form.business_name.trim(),
      slug: slugify(form.business_name),
      cnpj: onlyDigits(form.cnpj),
      category: (form.category === 'Outro' ? form.custom_category : form.category).trim(),
      phone: onlyDigits(form.fixed_phone),
      whatsapp: onlyDigits(form.whatsapp),
      address: form.address.trim()
    }
  }

  try {
    loading.value = true
    const response = await api.post('/owner_onboarding', payload)

    const accessToken = response.headers['access-token'] || ''
    const client = response.headers['client'] || ''
    const uid = response.headers['uid'] || ''
    const user = response.data?.user || response.data?.data?.user || {}

    setStaffAccessToken(accessToken)
    sessionStorage.setItem('client', client)
    sessionStorage.setItem('uid', uid)
    localStorage.setItem('user', JSON.stringify(user))
    localStorage.setItem('role', user?.role || '')

    alert(response.data?.message || 'Conta empresarial criada com sucesso!')
    router.push('/sistema/login')
  } catch (error) {
    console.error('ERRO:', error?.response?.data)
    const message =
      error?.response?.data?.errors?.full_messages?.join(', ') ||
      error?.response?.data?.errors?.join(', ') ||
      error?.response?.data?.message ||
      'Erro ao criar conta empresarial'
    alert(message)
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
  position: relative;
}

.page-content {
  padding-top: 2rem;
}

.login-card {
  background: var(--bs-body-tertiary);
  backdrop-filter: blur(15px);
  border: 1px solid rgba(0,0,0,0.08);
  border-radius: 28px;
  padding: 2.5rem;
  width: 100%;
  max-width: 550px;
}

[data-bs-theme="dark"] .login-card {
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 20px 40px rgba(0,0,0,0.3) !important;
}

.account-type-banner {
  background: rgba(13, 110, 253, 0.08);
  border: 1px solid rgba(13, 110, 253, 0.12);
  color: var(--bs-primary);
  font-size: 0.9rem;
}

.step-indicator {
  width: 35px;
  height: 35px;
  border-radius: 50%;
  background: var(--bs-secondary-bg);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  color: var(--bs-secondary-color);
  transition: all 0.3s ease;
}

.step-indicator.active {
  background: var(--bs-primary);
  color: white;
  box-shadow: 0 0 15px rgba(13, 110, 253, 0.3);
}

.step-line {
  width: 60px;
  height: 2px;
  background: var(--bs-secondary-bg);
  align-self: center;
  margin: 0 10px;
}

.step-line.active {
  background: var(--bs-primary);
}

/* Borda sempre visível — aplicada na classe base, não depende do tema */
.custom-input {
  border-radius: 12px;
  padding: 12px 15px;
  font-size: 0.9rem;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
  border: 2px solid #9aa2b8 !important;
  background: #ffffff !important;
  color: #111827 !important;
}

.custom-input:hover:not(:focus) {
  border-color: #5c6480 !important;
}

.custom-input:focus {
  border-color: #0d6efd !important;
  box-shadow: 0 0 0 3px rgba(13, 110, 253, 0.18) !important;
  outline: none !important;
}

/* ── Dark mode: sobrescreve apenas fundo e cor do texto ── */
[data-bs-theme="dark"] .custom-input {
  background: rgba(255, 255, 255, 0.05) !important;
  border-color: rgba(255, 255, 255, 0.28) !important;
  color: #f8f9fa !important;
}

[data-bs-theme="dark"] .custom-input:hover:not(:focus) {
  border-color: rgba(255, 255, 255, 0.5) !important;
}

[data-bs-theme="dark"] .custom-input:focus {
  border-color: rgba(13, 110, 253, 0.85) !important;
  box-shadow: 0 0 0 3px rgba(13, 110, 253, 0.22) !important;
  outline: none !important;
}

/* ── Select <option>: fundo igual ao dos campos de input ── */
/* Light mode (padrão): fundo branco = mesmo dos inputs */
.custom-input option {
  background-color: #ffffff;
  color: #111827;
}

/* Dark mode: fundo escuro = mesmo tom dos inputs dark */
[data-bs-theme="dark"] .custom-input option {
  background-color: #2d3037;
  color: #f8f9fa;
}

/* Opção desabilitada (placeholder "Selecione") */
.custom-input option:disabled,
.custom-input option[disabled] {
  color: #9ca3af;
  background-color: #ffffff;
}

[data-bs-theme="dark"] .custom-input option:disabled,
[data-bs-theme="dark"] .custom-input option[disabled] {
  color: #6b7280;
  background-color: #2d3037;
}

/* Autocomplete autofill fix */
.custom-input:-webkit-autofill,
.custom-input:-webkit-autofill:hover,
.custom-input:-webkit-autofill:focus {
  -webkit-text-fill-color: #111827 !important;
  -webkit-box-shadow: 0 0 0 1000px #ffffff inset !important;
  transition: background-color 5000s ease-in-out 0s;
}

[data-bs-theme="dark"] .custom-input:-webkit-autofill,
[data-bs-theme="dark"] .custom-input:-webkit-autofill:hover,
[data-bs-theme="dark"] .custom-input:-webkit-autofill:focus {
  -webkit-text-fill-color: #f8f9fa !important;
  -webkit-box-shadow: 0 0 0 1000px #1e2433 inset !important;
}

.form-label-custom {
  font-size: 0.7rem;
  font-weight: 800;
  margin-bottom: 5px;
  margin-left: 5px;
  color: var(--bs-secondary-color);
  text-transform: uppercase;
  letter-spacing: 0.8px;
}

.theme-switch-wrapper {
  position: absolute;
  top: 25px;
  right: 25px;
  z-index: 5;
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

#darkToggle:checked + .theme-switch .ball {
  transform: translateX(27px);
}

.py-2-5 {
  padding-top: 0.75rem;
  padding-bottom: 0.75rem;
}

@media (max-width: 576px) {
  .login-card {
    padding: 1.5rem;
  }
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease, transform 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>

<!-- Bloco global (sem scoped) para garantir que as bordas dos campos
     sobrescrevam o CSS do Bootstrap carregado globalmente em main.ts -->
<style>
.register-page .custom-input,
.register-page .form-control.custom-input,
.register-page .form-select.custom-input {
  border: 2px solid #9aa2b8 !important;
  background-color: #ffffff !important;
  color: #111827 !important;
}

.register-page .custom-input:hover:not(:focus),
.register-page .form-control.custom-input:hover:not(:focus),
.register-page .form-select.custom-input:hover:not(:focus) {
  border-color: #5c6480 !important;
}

.register-page .custom-input:focus,
.register-page .form-control.custom-input:focus,
.register-page .form-select.custom-input:focus {
  border-color: #0d6efd !important;
  box-shadow: 0 0 0 3px rgba(13, 110, 253, 0.18) !important;
  outline: none !important;
}

/* Dark mode */
[data-bs-theme="dark"] .register-page .custom-input,
[data-bs-theme="dark"] .register-page .form-control.custom-input,
[data-bs-theme="dark"] .register-page .form-select.custom-input {
  border-color: rgba(255, 255, 255, 0.28) !important;
  background-color: rgba(255, 255, 255, 0.05) !important;
  color: #f8f9fa !important;
}

[data-bs-theme="dark"] .register-page .custom-input:hover:not(:focus) {
  border-color: rgba(255, 255, 255, 0.5) !important;
}

[data-bs-theme="dark"] .register-page .custom-input:focus {
  border-color: rgba(13, 110, 253, 0.85) !important;
  box-shadow: 0 0 0 3px rgba(13, 110, 253, 0.22) !important;
}
</style>
