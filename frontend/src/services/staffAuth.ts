// Mantém o access token de staff apenas em memória durante a aba atual.
let accessToken: string | null = null
let sessionVersion = 0

export const getStaffAccessToken = (): string | null => accessToken
export const getStaffSessionVersion = (): number => sessionVersion
export const setStaffAccessToken = (token: string | null): void => {
  accessToken = token?.trim() || null
}
export const getStaffCsrfToken = (): string | null => sessionStorage.getItem('staff-csrf-token')

export function saveStaffSession(token: string, client: string, uid: string,
  user: Record<string, unknown>, csrf?: string): void {
  setStaffAccessToken(token)
  sessionStorage.setItem('client', client)
  sessionStorage.setItem('uid', uid)
  sessionStorage.setItem('user', JSON.stringify(user))
  sessionStorage.setItem('role', String(user.role || ''))
  if (csrf) sessionStorage.setItem('staff-csrf-token', csrf)
}

export const clearStaffAccessToken = (): void => {
  sessionVersion++
  accessToken = null
  const keys = ['access-token', 'client', 'uid', 'user', 'role', 'token-type',
    'establishment-permissions', 'establishment-data', 'salon-config', 'staff-csrf-token']
  for (const storage of [localStorage, sessionStorage]) {
    for (const key of keys) storage.removeItem(key)
  }
}
