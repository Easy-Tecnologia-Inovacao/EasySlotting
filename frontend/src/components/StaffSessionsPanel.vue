<template>

    <div class="sessions-panel" :class="contained ? 'container-fluid' : 'page-content'">
      <slot name="header" :refresh="loadSessions" :disabled="loading || busy">
      <div class="sessions-header d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4 p-4 rounded-4 shadow-sm">
        <div class="sessions-heading d-flex align-items-center gap-3">
          <div>
            <h1 class="sessions-title h3 mb-1">Dispositivos conectados</h1>
            <p class="text-body-secondary mb-0">Acessos da sua conta. Encerre os que você não utiliza ou não reconhece.</p>
          </div>
        </div>
        <button class="btn btn-outline-primary rounded-pill d-inline-flex align-items-center gap-2" :disabled="loading || busy" @click="loadSessions">
          <i class="bi bi-arrow-clockwise" aria-hidden="true"></i>
          Atualizar
        </button>
      </div>
      </slot>

      <div v-if="errorMessage" class="alert alert-danger" role="alert">{{ errorMessage }}</div>
      <div v-if="successMessage" class="alert alert-success" role="status">{{ successMessage }}</div>
      <div v-if="hasLoaded" class="card sessions-card shadow-sm rounded-4 mb-4">
        <div class="card-body p-4">
          <p class="fw-semibold mb-2">{{ sessions.length }} de {{ limit }} sessões disponíveis em uso</p>
          <p class="text-body-secondary mb-0">O limite é definido para o seu perfil e plano. Entrar novamente no mesmo navegador substitui o acesso anterior. Fechar uma aba não encerra a sessão no servidor.</p>
        </div>
      </div>

      <p v-if="loading" role="status">Carregando dispositivos…</p>
      <button v-if="!loading && !hasLoaded && errorMessage" class="btn btn-outline-primary mb-4" :disabled="busy" @click="loadSessions">Tentar novamente</button>
      <div v-if="hasLoaded && !loading" class="row g-3">
        <div v-for="session in sessions" :key="session.client_id" class="col-12 col-lg-6">
          <div class="card sessions-card h-100 shadow-sm rounded-4">
            <div class="card-body p-4">
              <div class="d-flex flex-wrap align-items-center gap-2 mb-3">
                <i class="bi bi-laptop fs-4" aria-hidden="true"></i>
                <h2 class="h5 mb-0">{{ session.device }}</h2>
                <span v-if="session.is_current" class="badge text-bg-primary">Este acesso</span>
              </div>
              <dl class="row small mb-3">
                <dt class="col-5">IP observado</dt><dd class="col-7">{{ session.ip || 'Não disponível' }}</dd>
                <dt class="col-5">Última atividade</dt><dd class="col-7">{{ formatDate(session.last_seen_at) }}</dd>
                <dt class="col-5">Expiração atual</dt><dd class="col-7">{{ formatDate(session.expires_at) }}</dd>
              </dl>
              <button class="btn btn-outline-danger" :disabled="busy || loading" @click="revokeSession(session)">
                {{ session.is_current ? 'Sair deste aparelho' : 'Encerrar acesso' }}
              </button>
            </div>
          </div>
        </div>
        <p v-if="!sessions.length" class="text-body-secondary">Nenhum acesso disponível para exibir.</p>
      </div>

      <button v-if="hasLoaded && sessions.length > 1" class="btn btn-outline-danger mt-4" :disabled="busy || loading" @click="revokeOthers">
        Encerrar todos os outros acessos
      </button>
    </div>
</template>

<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, logoutStaff } from '@/services/api'
import { getStaffSessionVersion } from '@/services/staffAuth'

defineProps<{ contained?: boolean }>()

type Session = {
  client_id: string
  is_current: boolean
  device: string
  ip: string | null
  last_seen_at: string | null
  expires_at: string
}

const router = useRouter()
const sessions = ref<Session[]>([])
const limit = ref<number | null>(null)
const hasLoaded = ref(false)
const loading = ref(false)
const busy = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const version = getStaffSessionVersion()
let mounted = true
let generation = 0
const isCurrentAccount = () => mounted && version === getStaffSessionVersion()

function clearInventory() {
  hasLoaded.value = false
  sessions.value = []
  limit.value = null
}

function parseInventory(data: unknown): { sessions: Session[]; limit: number } {
  if (!data || typeof data !== 'object') throw new Error('Resposta inválida')
  const payload = data as Record<string, unknown>
  const count = payload.active_count
  const quota = payload.limit
  if (typeof quota !== 'number' || !Number.isInteger(quota) || quota < 1 || quota > 5 ||
      !Array.isArray(payload.sessions) || count !== payload.sessions.length || payload.sessions.length > quota) {
    throw new Error('Resposta inválida')
  }
  const ids = new Set<string>()
  const validDate = (value: unknown) => typeof value === 'string' && value.length <= 40 && Number.isFinite(Date.parse(value))
  const rows = payload.sessions.map((value: unknown) => {
    if (!value || typeof value !== 'object') throw new Error('Resposta inválida')
    const item = value as Record<string, unknown>
    if (typeof item.client_id !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(item.client_id) || ids.has(item.client_id) ||
        typeof item.is_current !== 'boolean' || typeof item.device !== 'string' || item.device.length > 200 ||
        !(item.ip === null || (typeof item.ip === 'string' && item.ip.length <= 45)) ||
        !(item.last_seen_at === null || validDate(item.last_seen_at)) || !validDate(item.expires_at)) {
      throw new Error('Resposta inválida')
    }
    ids.add(item.client_id)
    return { client_id: item.client_id, is_current: item.is_current, device: item.device,
      ip: item.ip as string | null, last_seen_at: item.last_seen_at as string | null, expires_at: item.expires_at as string }
  })
  if (rows.length && rows.filter(row => row.is_current).length !== 1) throw new Error('Resposta inválida')
  return { sessions: rows, limit: quota }
}

const formatDate = (value: string | null) => value ? new Date(value).toLocaleString('pt-BR') : 'Não disponível'

async function loadSessions() {
  if (loading.value || busy.value || !isCurrentAccount()) return
  successMessage.value = ''
  await fetchInventory()
}

// Chamado pelas mutações somente depois da resposta do DELETE. Nenhum GET
// anterior pode estar em voo: os handlers serializam carga e escrita.
async function fetchInventory() {
  const requestGeneration = ++generation
  loading.value = true
  clearInventory()
  errorMessage.value = ''
  try {
    const { data } = await api.get('/me/sessions')
    if (!isCurrentAccount() || requestGeneration !== generation) return
    const inventory = parseInventory(data)
    sessions.value = inventory.sessions
    limit.value = inventory.limit
    hasLoaded.value = true
  } catch {
    if (isCurrentAccount() && requestGeneration === generation) errorMessage.value = 'Não foi possível carregar os acessos. Tente novamente.'
  } finally {
    if (isCurrentAccount() && requestGeneration === generation) loading.value = false
  }
}

async function revokeSession(session: Session) {
  if (busy.value || loading.value || !hasLoaded.value || !isCurrentAccount()) return
  const target = sessions.value.find(item => item.client_id === session.client_id)
  if (!target || !window.confirm(target.is_current ? 'Sair da conta neste aparelho?' : 'Encerrar este acesso? O aparelho precisará entrar novamente.')) return
  busy.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    if (target.is_current) {
      try {
        await logoutStaff()
      } finally {
        // O helper limpa a interface mesmo se a revogação remota falhar.
        if (mounted && getStaffSessionVersion() === version + 1) await router.replace('/sistema/login')
      }
      return
    }
    await api.delete(`/me/sessions/${encodeURIComponent(target.client_id)}`)
    if (!isCurrentAccount()) return
    successMessage.value = 'Acesso encerrado. Uma vaga está disponível.'
    await fetchInventory()
  } catch {
    if (isCurrentAccount()) {
      clearInventory()
      errorMessage.value = 'Não foi possível confirmar o encerramento. Atualize a lista e tente novamente.'
    }
  } finally {
    busy.value = false
  }
}

async function revokeOthers() {
  if (busy.value || loading.value || !hasLoaded.value || sessions.value.length < 2 || !isCurrentAccount() || !window.confirm('Encerrar todos os outros acessos da sua conta?')) return
  busy.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await api.delete('/me/sessions')
    if (!isCurrentAccount()) return
    successMessage.value = 'Os outros acessos foram encerrados.'
    await fetchInventory()
  } catch {
    if (isCurrentAccount()) {
      clearInventory()
      errorMessage.value = 'Não foi possível confirmar o encerramento dos acessos. Atualize a lista e tente novamente.'
    }
  } finally {
    busy.value = false
  }
}

onMounted(loadSessions)
onBeforeUnmount(() => { mounted = false; generation++ })
</script>

<style scoped>
.sessions-panel {
  --sessions-card-bg: var(--glass-bg, var(--bs-body-bg));
  max-width: 100%;
  color: var(--bs-body-color);
}

.sessions-header {
  background:
    radial-gradient(circle at top right, rgba(var(--bs-primary-rgb), 0.08), transparent 70%),
    var(--sessions-card-bg);
  border: 1px solid var(--card-border, var(--bs-border-color));
}

.sessions-heading {
  min-width: 0;
}

.sessions-title {
  background: linear-gradient(135deg, var(--logo-color, var(--bs-primary)), #00c6ff);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-weight: 800;
  letter-spacing: -0.025em;
}

.sessions-card {
  background: var(--sessions-card-bg);
  border: 1px solid var(--card-border, var(--bs-border-color));
  color: var(--bs-body-color);
}

.sessions-card dd {
  color: var(--bs-secondary-color);
  overflow-wrap: anywhere;
}

[data-bs-theme='dark'] .sessions-panel {
  --sessions-card-bg: var(--bs-tertiary-bg, #2b3035);
}

[data-bs-theme='dark'] .sessions-panel .btn-outline-primary {
  --bs-btn-color: var(--bs-primary-text-emphasis);
  --bs-btn-border-color: var(--bs-primary-text-emphasis);
}

[data-bs-theme='dark'] .sessions-panel .btn-outline-danger {
  --bs-btn-color: var(--bs-danger-text-emphasis);
  --bs-btn-border-color: var(--bs-danger-text-emphasis);
}

@media (forced-colors: active) {
  .sessions-title {
    background: none;
    color: CanvasText;
    -webkit-text-fill-color: currentColor;
  }
}
</style>
