<template>
  <div class="modal-backdrop fade show" v-if="show"></div>
  <div
    class="modal fade show d-block"
    tabindex="-1"
    v-if="show"
    role="dialog"
    aria-modal="true"
  >
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content verification-modal shadow-lg border-0">
        <!-- Header -->
        <div class="modal-header border-0 pb-0 text-center flex-column position-relative">
          <button
            type="button"
            class="btn-close position-absolute top-0 end-0 m-3"
            @click="handleCancel"
            aria-label="Close"
          ></button>
          <div class="icon-circle mb-2">
            <i class="bi bi-shield-lock-fill text-primary" style="font-size: 28px;"></i>
          </div>
          <h5 class="modal-title fw-800 text-body">Novo Acesso Detectado</h5>
          <p class="text-secondary small mb-0 mt-1">
            Detectamos um acesso de um novo IP ou navegador. Escolha o método para liberar sua entrada:
          </p>
        </div>

        <div class="modal-body px-4 py-3">
          <!-- Seleção de Métodos -->
          <div class="methods-list mb-3">
            <!-- Método 1: E-mail (Ativo) -->
            <div
              class="method-card active mb-2 p-3 rounded-3 border d-flex align-items-center cursor-pointer"
              :class="{ 'selected': selectedMethod === 'email' }"
              @click="selectedMethod = 'email'"
            >
              <div class="method-icon me-3 text-primary">
                <i class="bi bi-envelope-check-fill fs-4"></i>
              </div>
              <div class="flex-grow-1">
                <div class="fw-bold small text-body">Código via E-mail</div>
                <div class="text-muted extra-small">
                  Enviado para <strong class="text-primary">{{ emailMasked }}</strong>
                </div>
              </div>
              <div class="method-badge">
                <span class="badge bg-success-subtle text-success border border-success-subtle rounded-pill small">
                  Ativo
                </span>
              </div>
            </div>

            <!-- Método 2: 2FA Autenticador (Layout Pré-Pronto) -->
            <div
              class="method-card disabled p-3 rounded-3 border d-flex align-items-center opacity-75"
              style="background-color: var(--bs-tertiary-bg); cursor: not-allowed;"
            >
              <div class="method-icon me-3 text-secondary">
                <i class="bi bi-phone-vibrate-fill fs-4"></i>
              </div>
              <div class="flex-grow-1">
                <div class="fw-bold small text-body">Aplicativo Autenticador (2FA)</div>
                <div class="text-muted extra-small">Google Authenticator / Authy</div>
              </div>
              <div class="method-badge">
                <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle rounded-pill extra-small">
                  Em breve
                </span>
              </div>
            </div>
          </div>

          <!-- Formulário de Código de 6 Dígitos -->
          <div v-if="selectedMethod === 'email'" class="otp-section mt-3">
            <label class="form-label small fw-bold text-secondary mb-2">
              Digite o código de 6 dígitos enviado por e-mail:
            </label>

            <!-- Erro Inline -->
            <div v-if="errorMsg" class="alert alert-danger py-2 px-3 small mb-2 rounded-3">
              <i class="bi bi-exclamation-triangle-fill me-1"></i>{{ errorMsg }}
            </div>

            <div class="otp-input-wrapper mb-3">
              <input
                ref="otpInputRef"
                type="text"
                class="form-control form-control-lg text-center otp-input fw-bold letter-spacing-lg"
                placeholder="000000"
                maxlength="6"
                v-model="otpCode"
                @keyup.enter="submitVerification"
                autocomplete="one-time-code"
              />
            </div>

            <div class="d-flex justify-content-between align-items-center small">
              <button
                type="button"
                class="btn btn-link p-0 text-decoration-none extra-small fw-bold"
                :disabled="resendCooldown > 0 || resending"
                @click="resendCode"
              >
                <span v-if="resending" class="spinner-border spinner-border-sm me-1"></span>
                <span v-if="resendCooldown > 0">Reenviar e-mail em {{ resendCooldown }}s</span>
                <span v-else><i class="bi bi-arrow-clockwise me-1"></i>Reenviar código</span>
              </button>
              <span class="text-muted extra-small">Válido por 10 minutos</span>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="modal-footer border-0 pt-0 px-4 pb-4">
          <button
            type="button"
            class="btn btn-outline-secondary btn-sm rounded-pill px-3"
            @click="handleCancel"
          >
            Cancelar
          </button>
          <button
            type="button"
            class="btn btn-primary btn-sm rounded-pill px-4 fw-bold shadow-sm"
            :disabled="otpCode.length < 6 || loading"
            @click="submitVerification"
          >
            <span v-if="loading" class="spinner-border spinner-border-sm me-1" role="status"></span>
            <span>{{ loading ? 'Verificando...' : 'Confirmar e Logar' }}</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'

const props = defineProps<{
  show: boolean
  emailMasked: string
  errorMsg?: string
}>()

const emit = defineEmits<{
  (e: 'verify', code: string): void
  (e: 'cancel'): void
  (e: 'resend'): void
}>()

const selectedMethod = ref<'email' | 'totp'>('email')
const otpCode = ref('')
const loading = ref(false)
const resending = ref(false)
const resendCooldown = ref(0)
const otpInputRef = ref<HTMLInputElement | null>(null)
let cooldownTimer: any = null

watch(() => props.show, (newVal) => {
  if (newVal) {
    otpCode.value = ''
    nextTick(() => {
      otpInputRef.value?.focus()
    })
  }
})

const submitVerification = () => {
  if (otpCode.value.length === 6) {
    loading.value = true
    emit('verify', otpCode.value.trim())
  }
}

const handleCancel = () => {
  otpCode.value = ''
  loading.value = false
  emit('cancel')
}

const resendCode = () => {
  if (resendCooldown.value > 0 || resending.value) return
  resending.value = true
  emit('resend')

  resendCooldown.value = 60
  if (cooldownTimer) clearInterval(cooldownTimer)
  cooldownTimer = setInterval(() => {
    resendCooldown.value--
    if (resendCooldown.value <= 0) {
      clearInterval(cooldownTimer)
    }
  }, 1000)

  setTimeout(() => {
    resending.value = false
  }, 1000)
}
</script>

<style scoped>
.verification-modal {
  border-radius: 24px;
  background: var(--bs-body-bg);
}

.icon-circle {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  background: rgba(13, 110, 253, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto;
}

.method-card {
  transition: all 0.2s ease;
}

.method-card.active.selected {
  border-color: var(--bs-primary) !important;
  background-color: rgba(13, 110, 253, 0.05);
}

.otp-input {
  letter-spacing: 0.5rem;
  font-size: 1.5rem;
  border-radius: 12px;
}

.extra-small {
  font-size: 0.75rem;
}

.fw-800 {
  font-weight: 800;
}
</style>
