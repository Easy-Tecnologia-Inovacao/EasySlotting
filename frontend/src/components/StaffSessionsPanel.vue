<template>

    <div class="container-fluid py-4">
      <div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
        <div>
          <h1 class="h3 mb-2">Dispositivos conectados</h1>
          <p class="text-body-secondary mb-0">Acessos da sua conta. Encerre os que você não utiliza ou não reconhece.</p>
        </div>
        <button class="btn btn-outline-primary" :disabled="loading || busy" @click="loadSessions">Atualizar</button>
      </div>

      <div v-if="errorMessage" class="alert alert-danger" role="alert">{{ errorMessage }}</div>
      <div v-if="successMessage" class="alert alert-success" role="status">{{ successMessage }}</div>
      <div class="card border-0 shadow-sm rounded-4 mb-4">
        <div class="card-body p-4">
          <p class="fw-semibold mb-2">{{ sessions.length }} de {{ limit }} sessões disponíveis em uso</p>
          <p class="text-body-secondary mb-0">O limite é definido para o seu perfil e plano. Entrar novamente no mesmo navegador substitui o acesso anterior. Fechar uma aba não encerra a sessão no servidor.</p>
        </div>
      </div>

      <p v-if="loading" role="status">Carregando dispositivos…</p>
      <div v-else class="row g-3">
        <div v-for="session in sessions" :key="session.client_id" class="col-12 col-lg-6">
          <div class="card h-100 border-0 shadow-sm rounded-4">
            <div class="card-body p-4">
              <div class="d-flex align-items-center gap-2 mb-3">
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

      <button v-if="sessions.length > 1" class="btn btn-outline-danger mt-4" :disabled="busy || loading" @click="revokeOthers">
        Encerrar todos os outros acessos
      </button>
    </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, logoutStaff } from '@/services/api'
import { getStaffSessionVersion } from '@/services/staffAuth'


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
const limit = ref(1)
const loading = ref(false)
const busy = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const version = getStaffSessionVersion()
const isCurrentAccount = () => version === getStaffSessionVersion()

const formatDate = (value: string | null) => value ? new Date(value).toLocaleString('pt-BR') : 'Não disponível'

async function loadSessions() {
  if (!isCurrentAccount()) return
  loading.value = true
  errorMessage.value = ''
  try {
    const { data } = await api.get('/me/sessions')
    if (!isCurrentAccount()) return
    sessions.value = data.sessions
    limit.value = data.limit ?? 1
  } catch {
    if (isCurrentAccount()) errorMessage.value = 'Não foi possível carregar os acessos. Tente novamente.'
  } finally {
    loading.value = false
  }
}

async function revokeSession(session: Session) {
  if (busy.value || !isCurrentAccount()) return
  if (!window.confirm(session.is_current ? 'Sair da conta neste aparelho?' : 'Encerrar este acesso? O aparelho precisará entrar novamente.')) return
  busy.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    if (session.is_current) {
      try {
        await logoutStaff()
      } finally {
        // O helper limpa a interface mesmo se a revogação remota falhar.
        if (getStaffSessionVersion() === version + 1) await router.replace('/sistema/login')
      }
      return
    }
    await api.delete(`/me/sessions/${encodeURIComponent(session.client_id)}`)
    if (!isCurrentAccount()) return
    successMessage.value = 'Acesso encerrado. Uma vaga está disponível.'
    await loadSessions()
  } catch {
    if (isCurrentAccount()) errorMessage.value = 'Não foi possível encerrar o acesso. Atualize a lista e tente novamente.'
  } finally {
    busy.value = false
  }
}

async function revokeOthers() {
  if (busy.value || !isCurrentAccount() || !window.confirm('Encerrar todos os outros acessos da sua conta?')) return
  busy.value = true
  errorMessage.value = ''
  successMessage.value = ''
  try {
    await api.delete('/me/sessions')
    if (!isCurrentAccount()) return
    successMessage.value = 'Os outros acessos foram encerrados.'
    await loadSessions()
  } catch {
    if (isCurrentAccount()) errorMessage.value = 'Não foi possível encerrar os acessos. Tente novamente.'
  } finally {
    busy.value = false
  }
}

onMounted(loadSessions)
</script>
