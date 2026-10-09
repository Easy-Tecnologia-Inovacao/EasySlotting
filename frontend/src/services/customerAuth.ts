// src/services/customerAuth.ts
// Serviço de autenticação para customers (token JWT próprio, separado do Devise).
// Access token: curta duração (15min), armazenado em memory/sessionStorage.
// Refresh token: longa duração (7 dias), armazenado em httpOnly cookie (inacessível via JS).
// CSRF token: httponly cookie, enviado como header em requests de refresh.

const CUSTOMER_ACCESS_TOKEN_KEY  = 'customer-access-token'
const CUSTOMER_DATA_KEY          = 'customer-data'
const CUSTOMER_SLUG_KEY          = 'customer-slug'
const CUSTOMER_TOKEN_EXPIRES_KEY = 'customer-token-expires'
const CUSTOMER_CSRF_TOKEN_KEY    = 'customer-csrf-token'

export interface CustomerData {
  id:               number
  name:             string
  email:            string
  phone?:           string
  cellphone?:       string
  image?:           string
  establishment_id: number
  password_expired?: boolean
}

// ─── Persistência ────────────────────────────────────────────────────────────

/**
 * Salva o access token, dados do customer e CSRF token.
 * O refresh token é salvo automaticamente pelo backend em httpOnly cookie.
 */
export function saveCustomerSession(
  accessToken: string,
  data:        CustomerData,
  slug:        string,
  remember     = false,
  expiresIn    = 900, // 15 minutos por padrão
  csrfToken?:  string
): void {
  // O access token nunca deve sobreviver ao fechamento do navegador.
  // O refresh token permanece protegido no cookie HttpOnly do backend.
  const storage = sessionStorage
  const expiresAt = Date.now() + (expiresIn * 1000)

  // LGPD: Minimização de dados — apenas campos necessários para UI ficam no storage
  const minimalData = {
    id: data.id,
    name: data.name,
    image: data.image,
    establishment_id: data.establishment_id,
    password_expired: data.password_expired ?? false
  }

  storage.setItem(CUSTOMER_ACCESS_TOKEN_KEY,  accessToken)
  storage.setItem(CUSTOMER_DATA_KEY,          JSON.stringify(minimalData))
  storage.setItem(CUSTOMER_SLUG_KEY,          slug)
  storage.setItem(CUSTOMER_TOKEN_EXPIRES_KEY, String(expiresAt))

  // CSRF token para double-submit pattern (comparado com cookie httponly no backend)
  if (csrfToken) {
    storage.setItem(CUSTOMER_CSRF_TOKEN_KEY, csrfToken)
  }
}

/** Remove a sessão do customer de todas as storages */
export function clearCustomerSession(): void {
  ;[localStorage, sessionStorage].forEach((s) => {
    s.removeItem(CUSTOMER_ACCESS_TOKEN_KEY)
    s.removeItem(CUSTOMER_DATA_KEY)
    s.removeItem(CUSTOMER_SLUG_KEY)
    s.removeItem(CUSTOMER_TOKEN_EXPIRES_KEY)
    s.removeItem(CUSTOMER_CSRF_TOKEN_KEY)
  })
}

/** Retorna o access token JWT do customer ou null */
export function getCustomerToken(): string | null {
  return sessionStorage.getItem(CUSTOMER_ACCESS_TOKEN_KEY) || null
}

/** Retorna o CSRF token para requests de refresh */
export function getCustomerCsrfToken(): string | null {
  return sessionStorage.getItem(CUSTOMER_CSRF_TOKEN_KEY) || null
}

/** Retorna os dados do customer ou null */
export function getCustomerData(): CustomerData | null {
  const raw =
    localStorage.getItem(CUSTOMER_DATA_KEY) ||
    sessionStorage.getItem(CUSTOMER_DATA_KEY) ||
    null

  if (!raw) return null

  try {
    return JSON.parse(raw) as CustomerData
  } catch {
    return null
  }
}

/** Retorna o slug do estabelecimento da sessão do customer */
export function getCustomerSlug(): string | null {
  return (
    localStorage.getItem(CUSTOMER_SLUG_KEY) ||
    sessionStorage.getItem(CUSTOMER_SLUG_KEY) ||
    null
  )
}

/** Verifica se há uma sessão de customer ativa */
export function isCustomerLoggedIn(): boolean {
  return !!getCustomerToken()
}

/** Verifica se o access token está expirado ou vai expirar em breve */
export function isTokenExpiringSoon(): boolean {
  const expiresAt = sessionStorage.getItem(CUSTOMER_TOKEN_EXPIRES_KEY)
  if (!expiresAt) return false

  // Considera expirado se faltam menos de 60 segundos
  return Date.now() >= (Number(expiresAt) - 60000)
}

/** Retorna o storage que contém os dados do customer (localStorage ou sessionStorage) */
function getActiveStorage(): Storage | null {
  return sessionStorage.getItem(CUSTOMER_ACCESS_TOKEN_KEY) ? sessionStorage : null
}

/** Atualiza apenas o access token e CSRF token (após refresh) */
export function updateAccessToken(accessToken: string, csrfToken: string, expiresIn: number = 900): void {
  const storage = getActiveStorage()
  if (!storage) return

  const expiresAt = Date.now() + (expiresIn * 1000)
  storage.setItem(CUSTOMER_ACCESS_TOKEN_KEY, accessToken)
  storage.setItem(CUSTOMER_TOKEN_EXPIRES_KEY, String(expiresAt))
  storage.setItem(CUSTOMER_CSRF_TOKEN_KEY, csrfToken)
}

// ─── Header para Axios ───────────────────────────────────────────────────────

/** Retorna o header Authorization com Bearer token para chamadas autenticadas */
export function getCustomerAuthHeader(): Record<string, string> {
  const token = getCustomerToken()
  if (!token) return {}
  return { Authorization: `Bearer ${token}` }
}
