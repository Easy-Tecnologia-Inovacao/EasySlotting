<template>
  <section class="single-profile-card border-0 shadow-sm rounded-4 p-4 mt-4" aria-labelledby="customer-devices-title">
    <h5 id="customer-devices-title">Dispositivos conectados</h5>
    <p>Você pode usar vários aparelhos. Encerre os acessos que não utiliza ou não reconhece.</p>
    <p v-if="error" class="text-danger" role="alert">{{ error }}</p>
    <p v-if="busy" role="status">Atualizando acessos…</p>
    <ul class="list-unstyled">
      <li v-for="session in sessions" :key="session.session_id" class="border rounded p-3 my-2 d-flex flex-wrap justify-content-between gap-2">
        <div>
          <strong>{{ session.is_current ? 'Este acesso' : 'Outro acesso' }}</strong>
          <div class="small">Iniciado em {{ formatDate(session.created_at) }} · Expira em {{ formatDate(session.expires_at) }}</div>
        </div>
        <button class="btn btn-outline-danger btn-sm" :disabled="busy" @click="revoke(session)">
          {{ session.is_current ? 'Sair deste aparelho' : 'Encerrar acesso' }}
        </button>
      </li>
    </ul>
    <div class="d-flex flex-wrap gap-2">
      <button class="btn btn-outline-primary btn-sm" :disabled="busy" @click="load(1)">Atualizar</button>
      <button v-if="page > 1" class="btn btn-outline-primary btn-sm" :disabled="busy" @click="load(page - 1)">Anterior</button>
      <button v-if="hasMore" class="btn btn-outline-primary btn-sm" :disabled="busy" @click="load(page + 1)">Próxima</button>
      <button class="btn btn-outline-danger btn-sm" :disabled="busy" @click="revokeOthers">Encerrar todos os outros acessos</button>
    </div>
  </section>
</template>
<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { api, logoutCustomer } from '@/services/api'
import { getCustomerSessionVersion, getCustomerSlug } from '@/services/customerAuth'

type Session = { session_id: string; created_at: string; expires_at: string; is_current: boolean }
const sessions = ref<Session[]>([])
const busy = ref(false)
const error = ref('')
const page = ref(1)
const hasMore = ref(false)
const version = getCustomerSessionVersion()
const isCurrent = () => getCustomerSessionVersion() === version
const formatDate = (value: string) => new Date(value).toLocaleString('pt-BR')

async function load(target = 1) {
  if (!isCurrent()) return
  busy.value = true
  error.value = ''
  try {
    const { data } = await api.get('/customer/sessions', { params: { page: target } })
    if (!isCurrent()) return
    sessions.value = data.sessions
    hasMore.value = data.has_more
    page.value = target
  } catch {
    if (isCurrent()) error.value = 'Não foi possível carregar os acessos.'
  } finally { busy.value = false }
}

async function revoke(session: Session) {
  if (busy.value || !isCurrent() || !window.confirm('Encerrar este acesso? Será necessário entrar novamente.')) return
  busy.value = true
  error.value = ''
  try {
    if (session.is_current) {
      const slug = getCustomerSlug()
      try { await logoutCustomer() } finally {
        if (getCustomerSessionVersion() === version + 1) window.location.assign('/empresa/' + encodeURIComponent(slug || '') + '/login')
      }
      return
    }
    await api.delete('/customer/sessions/' + encodeURIComponent(session.session_id))
    await load(1)
  } catch { if (isCurrent()) error.value = 'Não foi possível encerrar o acesso.' }
  finally { busy.value = false }
}

async function revokeOthers() {
  if (busy.value || !isCurrent() || !window.confirm('Encerrar todos os outros acessos da sua conta?')) return
  busy.value = true
  error.value = ''
  try {
    await api.delete('/customer/sessions/destroy_others')
    await load(1)
  } catch { if (isCurrent()) error.value = 'Não foi possível encerrar os outros acessos.' }
  finally { busy.value = false }
}

onMounted(() => load())
</script>
