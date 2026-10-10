import axios, { type InternalAxiosRequestConfig } from 'axios'
import {
  getCustomerToken, getCustomerCsrfToken, getCustomerSlug, getCustomerSessionVersion,
  clearCustomerSession, updateAccessToken, isTokenExpiringSoon
} from '@/services/customerAuth'
import {
  clearStaffAccessToken, getStaffAccessToken, getStaffSessionVersion, setStaffAccessToken,
  getStaffCsrfToken, saveStaffSession
} from '@/services/staffAuth'
import { DEVICE_TOKEN_STORAGE_KEY } from '@/services/storageKeys'

// Em desenvolvimento o proxy Vite mantém página/API na mesma origem, inclusive
// ao abrir por IP LAN. Um VITE_API_URL legado com localhost não pode transformar
// o cookie SameSite=Strict em cookie de terceiro e quebrar a recuperação por F5.
const baseURL = import.meta.env.PROD ? (import.meta.env.VITE_API_URL || '/api') : '/api'
export const api = axios.create({
  baseURL, headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, withCredentials: true
})

type AuthRequest = InternalAxiosRequestConfig & {
  _staffVersion?: number
  _customerVersion?: number
  _retry?: boolean
}
const isCustomerRoute = (url: string) => /^\/(customer|customer_auth)\//.test(url)
const isCustomerProtected = (url: string) => url.startsWith('/customer/')
const isPublicAuth = (url: string) => url === '/owner_onboarding' ||
  /\/(sign_in|sign_up|forgot_password|reset_password|password)$/.test(url)

export const getOrCreateDeviceToken = (): string => {
  let token = localStorage.getItem(DEVICE_TOKEN_STORAGE_KEY)
  if (!token || !/^[a-zA-Z0-9_-]{8,64}$/.test(token)) {
    // getRandomValues também funciona nos testes LAN por HTTP.
    const bytes = crypto.getRandomValues(new Uint8Array(32))
    token = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('')
    localStorage.setItem(DEVICE_TOKEN_STORAGE_KEY, token)
  }
  return token
}

let refreshPromise: Promise<string> | null = null
let staffRestorePromise: Promise<boolean> | null = null
let staffRestoreVersion = -1

/** Recupera apenas a mesma identidade/aba, validada no servidor antes da rota. */
export function restoreStaffSession(): Promise<boolean> {
  if (getStaffAccessToken()) return Promise.resolve(true)
  const version = getStaffSessionVersion()
  if (staffRestorePromise && staffRestoreVersion === version) return staffRestorePromise
  const csrf = getStaffCsrfToken()
  const client = sessionStorage.getItem('client')
  const uid = sessionStorage.getItem('uid')
  if (!csrf || !client || !uid) return Promise.resolve(false)
  staffRestoreVersion = version
  const pending = axios.post(baseURL + '/devise_users/restore_session', {}, {
    headers: { 'X-CSRF-Token': csrf, 'X-Staff-Client': client, 'X-Staff-Uid': uid },
    withCredentials: true
  }).then((response) => {
    if (version !== getStaffSessionVersion()) throw new axios.CanceledError('Sessão encerrada')
    const token = String(response.headers['access-token'] || '').trim()
    const user = response.data?.data
    if (!token || response.headers['client'] !== client || response.headers['uid'] !== uid ||
        !user || !['owner', 'employee', 'super_admin'].includes(user.role)) {
      clearStaffAccessToken()
      return false
    }
    saveStaffSession(token, client, uid, user, csrf)
    return true
  }).catch((error) => {
    if (version === getStaffSessionVersion() && axios.isAxiosError(error) &&
        [401, 403].includes(error.response?.status || 0)) clearStaffAccessToken()
    // Erros de rede não removem as referências necessárias para tentar novamente.
    throw error
  })
  staffRestorePromise = pending
  const release = () => { if (staffRestorePromise === pending) staffRestorePromise = null }
  pending.then(release, release)
  return pending
}

let refreshVersion = -1
function refreshAccessToken(): Promise<string> {
  const version = getCustomerSessionVersion()
  if (refreshPromise && refreshVersion === version) return refreshPromise
  const slug = getCustomerSlug()
  const csrf = getCustomerCsrfToken()
  if (!slug || !csrf || !getCustomerToken()) return Promise.reject(new Error('Sessão indisponível'))
  refreshVersion = version
  const pending = axios.post(baseURL + '/customer_auth/' + encodeURIComponent(slug) + '/refresh', {}, {
    headers: { 'X-CSRF-Token': csrf }, withCredentials: true
  }).then(({ data }) => {
    if (version !== getCustomerSessionVersion()) throw new axios.CanceledError('Sessão encerrada')
    updateAccessToken(data.access_token, data.csrf_token, data.expires_in)
    return data.access_token as string
  })
  refreshPromise = pending
  const release = () => { if (refreshPromise === pending) refreshPromise = null }
  pending.then(release, release)
  return pending
}

function expireCustomerSession(): void {
  const slug = getCustomerSlug()
  clearCustomerSession()
  window.location.assign(slug ? '/empresa/' + encodeURIComponent(slug) + '/login' : '/cliente/login')
}

api.interceptors.request.use(async (input) => {
  const config = input as AuthRequest
  const url = config.url || ''
  if (isPublicAuth(url)) {
    // Credenciais de outra conta não acompanham login/cadastro/recuperação.
    for (const header of ['Authorization', 'access-token', 'client', 'uid']) config.headers.delete(header)
    return config
  }
  if (isCustomerRoute(url)) {
    if (config._customerVersion !== undefined && config._customerVersion !== getCustomerSessionVersion()) {
      throw new axios.CanceledError('Sessão encerrada')
    }
    config._customerVersion = getCustomerSessionVersion()
    if (isCustomerProtected(url) && getCustomerToken() && isTokenExpiringSoon()) {
      try { await refreshAccessToken() } catch (error) {
        if (config._customerVersion !== getCustomerSessionVersion()) throw new axios.CanceledError('Sessão encerrada')
        // Falha de rede não apaga uma sessão ainda válida; o servidor valida o access token.
        if (axios.isAxiosError(error) && [401, 403].includes(error.response?.status || 0)) {
          expireCustomerSession()
          throw error
        }
      }
    }
    if (config._customerVersion !== getCustomerSessionVersion()) throw new axios.CanceledError('Sessão encerrada')
    const token = getCustomerToken()
    if (token) config.headers.set('Authorization', 'Bearer ' + token)
    if (getCustomerCsrfToken()) config.headers.set('X-CSRF-Token', getCustomerCsrfToken()!)
    return config
  }
  config._staffVersion = getStaffSessionVersion()
  const token = getStaffAccessToken()
  if (token) {
    config.headers.set('access-token', token)
    config.headers.set('client', sessionStorage.getItem('client') || '')
    config.headers.set('uid', sessionStorage.getItem('uid') || '')
  }
  return config
})

api.interceptors.response.use((response) => {
  const config = response.config as AuthRequest
  // Uma resposta atrasada não pode recriar a sessão após logout ou troca de conta.
  if (!isCustomerRoute(config.url || '') && !isPublicAuth(config.url || '') &&
      config._staffVersion === getStaffSessionVersion() && getStaffAccessToken()) {
    const token = String(response.headers['access-token'] || '').trim()
    const client = response.headers['client']
    const uid = response.headers['uid']
    if (token && client && uid) {
      setStaffAccessToken(token)
      sessionStorage.setItem('client', client)
      sessionStorage.setItem('uid', uid)
    }
  }
  return response
}, async (error) => {
  const config = error.config as AuthRequest | undefined
  if (!config || error.response?.status !== 401 || isPublicAuth(config.url || '')) return Promise.reject(error)
  if (isCustomerRoute(config.url || '')) {
    if (config._customerVersion !== getCustomerSessionVersion() || !getCustomerToken()) return Promise.reject(error)
    if (isCustomerProtected(config.url || '') && !config._retry) {
      config._retry = true
      try {
        const token = await refreshAccessToken()
        config.headers.set('Authorization', 'Bearer ' + token)
        return api.request(config)
      } catch (refreshError) {
        if (config._customerVersion === getCustomerSessionVersion() &&
            axios.isAxiosError(refreshError) && [401, 403].includes(refreshError.response?.status || 0)) expireCustomerSession()
        return Promise.reject(refreshError)
      }
    }
    expireCustomerSession()
  } else if (config._staffVersion === getStaffSessionVersion() && getStaffAccessToken()) {
    clearStaffAccessToken()
    window.location.assign('/sistema/login')
  }
  return Promise.reject(error)
})

/** Captura as credenciais e encerra a sessão local antes de aguardar a rede. */
export async function logoutStaff(): Promise<void> {
  const headers = {
    'access-token': getStaffAccessToken() || '', client: sessionStorage.getItem('client') || '',
    uid: sessionStorage.getItem('uid') || '', 'X-CSRF-Token': getStaffCsrfToken() || ''
  }
  clearStaffAccessToken()
  await axios.delete(baseURL + '/devise_users/sign_out', { headers, withCredentials: true })
}

export async function logoutCustomer(): Promise<void> {
  const slug = getCustomerSlug()
  const token = getCustomerToken()
  const csrf = getCustomerCsrfToken()
  clearCustomerSession()
  if (!slug) return
  await axios.delete(baseURL + '/customer_auth/' + encodeURIComponent(slug) + '/sign_out', {
    headers: { Authorization: token ? 'Bearer ' + token : '', 'X-CSRF-Token': csrf || '' }, withCredentials: true
  })
}

/** Exclui a própria conta e limpa a sessão antes de sair da página. */
export async function deleteCustomerAccount(confirmation: string, currentPassword: string): Promise<string> {
  const version = getCustomerSessionVersion()
  const slug = getCustomerSlug()
  await api.delete('/customer/profile', { data: { confirmation, current_password: currentPassword } })
  if (version !== getCustomerSessionVersion()) throw new axios.CanceledError('Sessão encerrada')
  clearCustomerSession()
  return slug ? '/empresa/' + encodeURIComponent(slug) : '/'
}
