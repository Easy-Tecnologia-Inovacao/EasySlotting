import axios from 'axios'
import {
  getCustomerToken,
  getCustomerCsrfToken,
  getCustomerSlug,
  clearCustomerSession,
  updateAccessToken,
  isTokenExpiringSoon
} from '@/services/customerAuth'

// Utiliza variável de ambiente para a URL da API.
// Em desenvolvimento, se não houver VITE_API_URL, detecta o host atual para facilitar acesso via IP/Mobile.
const host = window.location.hostname
const isLocal = host === 'localhost' || host === '127.0.0.1' || host === '0.0.0.0' || host === '::1'
const defaultURL = isLocal
  ? 'http://localhost:3000/api'
  : `${window.location.protocol}//${host}:3000/api`

const baseURL = import.meta.env.VITE_API_URL || defaultURL

export const api = axios.create({
  baseURL,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json'
  },
  withCredentials: true // Necessário para enviar cookies httpOnly
})

// ─── Fila de requests durante refresh ────────────────────────────────────────
let isRefreshing = false
let failedQueue: Array<{
  resolve: (token: string) => void
  reject: (error: any) => void
}> = []

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach((prom) => {
    if (error) {
      prom.reject(error)
    } else {
      prom.resolve(token!)
    }
  })
  failedQueue = []
}

// ─── Device Token (OWASP Trusted Device / Resiliência a IP Rotativo) ─────────
export const getOrCreateDeviceToken = (): string => {
  let token = localStorage.getItem('easysloting_device_token')
  if (!token) {
    token = typeof crypto !== 'undefined' && crypto.randomUUID
      ? crypto.randomUUID()
      : 'dt_' + Math.random().toString(36).substring(2, 15) + Date.now().toString(36)
    localStorage.setItem('easysloting_device_token', token)
  }
  return token
}

// ─── Request: injeta token correto por rota ───────────────────────────────────
api.interceptors.request.use(async (config) => {
  const url = config.url || ''

  // Rotas de customer usam Bearer JWT (token próprio por estabelecimento)
  const isCustomerRoute =
    url.includes('/customer/') ||
    url.includes('/customer_auth/')

  if (isCustomerRoute) {
    // Verifica se o token está expirando e tenta refresh antes de fazer a request
    if (isTokenExpiringSoon() && !url.includes('/customer_auth/refresh')) {
      try {
        await refreshAccessToken()
      } catch {
        // Se o refresh falhar, deixa a request seguir (será tratada no response)
      }
    }

    const customerToken = getCustomerToken()
    if (customerToken) {
      config.headers = config.headers ?? axios.AxiosHeaders.from({})
      config.headers.set('Authorization', `Bearer ${customerToken}`)
    }
    return config
  }

  // Rotas staff usam Devise Token Auth via headers (cookies httpOnly para refresh)
  const accessToken =
    localStorage.getItem('access-token') ||
    sessionStorage.getItem('access-token') ||
    ''

  const client =
    localStorage.getItem('client') ||
    sessionStorage.getItem('client') ||
    ''

  const uid =
    localStorage.getItem('uid') ||
    sessionStorage.getItem('uid') ||
    ''

  config.headers = config.headers ?? axios.AxiosHeaders.from({})

  if (accessToken) config.headers.set('access-token', accessToken)
  if (client)      config.headers.set('client', client)
  if (uid)         config.headers.set('uid', uid)

  return config
})

// ─── Response: atualiza tokens e trata erros globais ──────────────────────────
api.interceptors.response.use(
  (response) => {
    // Atualiza tokens rotativos (Devise Token Auth)
    const url = response.config.url || ''
    const isCustomerRoute =
      url.includes('/customer/') || url.includes('/customer_auth/')

    // Apenas para rotas que NÃO são de cliente (pois clientes usam JWT fixo)
    if (!isCustomerRoute) {
      const accessToken = response.headers['access-token'] || response.headers['Access-Token']
      const client      = response.headers['client']       || response.headers['Client']
      const uid         = response.headers['uid']          || response.headers['Uid']

      if (accessToken && client && uid) {
        const isLocal = !!localStorage.getItem('uid') || !!localStorage.getItem('access-token')
        const storage = isLocal ? localStorage : sessionStorage

        storage.setItem('access-token', accessToken)
        storage.setItem('client', client)
        storage.setItem('uid', uid)
      }
    }

    return response
  },
  async (error) => {
    const originalRequest = error.config
    const url = error.config?.url || ''

    // ─── Tratamento 401 para rotas de customer ────────────────────────────────
    const isCustomerRoute =
      url.includes('/customer/') || url.includes('/customer_auth/')

    if (error.response?.status === 401 && isCustomerRoute) {
      // Se já estamos tentando refresh, cola na fila
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject })
        }).then((token) => {
          originalRequest.headers.Authorization = `Bearer ${token}`
          return api(originalRequest)
        })
      }

      // Se é a rota de refresh que falhou, limpa sessão
      if (url.includes('/customer_auth/') && url.includes('/refresh')) {
        clearCustomerSession()
        const slug = getCustomerSlug() || ''
        window.location.href = slug ? `/empresa/${slug}/login` : '/sistema/login'
        return Promise.reject(error)
      }

      // Se é a rota de login que falhou, não faz refresh
      if (url.includes('/customer_auth/') && url.includes('/sign_in')) {
        return Promise.reject(error)
      }

      // Se tem access token, tenta fazer refresh (o cookie httpOnly vai automaticamente)
      if (!originalRequest._retry) {
        originalRequest._retry = true
        isRefreshing = true

        try {
          const newTokens = await refreshAccessToken()
          processQueue(null, newTokens.access_token)

          originalRequest.headers.Authorization = `Bearer ${newTokens.access_token}`
          return api(originalRequest)
        } catch (refreshError) {
          processQueue(refreshError, null)
          clearCustomerSession()
          const slug = getCustomerSlug() || ''
          window.location.href = slug ? `/empresa/${slug}/login` : '/sistema/login'
          return Promise.reject(refreshError)
        } finally {
          isRefreshing = false
        }
      }

      // Sem possibilidade de refresh — limpa sessão
      clearCustomerSession()
      const slug = getCustomerSlug() || ''
      window.location.href = slug ? `/empresa/${slug}/login` : '/sistema/login'
    }

    // ─── Tratamento 401 para rotas de staff (Devise) ─────────────────────────
    if (error.response?.status === 401 && !isCustomerRoute) {
      const accessToken = error.config?.headers?.['access-token'] || ''

      // Se for falha no próprio login, não redireciona
      if (url.includes('sign_in')) {
        return Promise.reject(error)
      }

      let role = localStorage.getItem('role') || sessionStorage.getItem('role')
      if (!role) {
        const userStr = localStorage.getItem('user') || sessionStorage.getItem('user')
        if (userStr) {
          try { role = JSON.parse(userStr).role } catch { role = '' }
        }
      }

      const keys = ['access-token', 'client', 'uid', 'role', 'token-type', 'user', 'site-slug']
      keys.forEach((key) => {
        localStorage.removeItem(key)
        sessionStorage.removeItem(key)
      })

      if (!role || role === 'customer') {
        const urlMatch = window.location.pathname.match(/\/empresa\/([^/]+)/)
        const urlSlug  = urlMatch ? urlMatch[1] : ''
        window.location.href = urlSlug ? `/empresa/${urlSlug}/login` : '/sistema/login'
      } else {
        window.location.href = '/sistema/login'
      }
    }

    return Promise.reject(error)
  }
)

// ─── Refresh Token Helper ────────────────────────────────────────────────────

async function refreshAccessToken(): Promise<{ access_token: string }> {
  const slug = getCustomerSlug()
  const csrfToken = getCustomerCsrfToken()

  if (!slug) {
    throw new Error('No establishment slug available')
  }

  // O cookie httpOnly é enviado automaticamente com withCredentials: true
  const response = await axios.post(
    `${baseURL}/customer_auth/${slug}/refresh`,
    {},
    {
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken || ''
      },
      withCredentials: true
    }
  )

  const { access_token, csrf_token, expires_in } = response.data

  // Atualiza o access token e CSRF token no storage
  updateAccessToken(access_token, csrf_token, expires_in)

  return { access_token }
}
