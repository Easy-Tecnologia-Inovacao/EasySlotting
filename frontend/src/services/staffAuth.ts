// Mantém o access token de staff apenas em memória durante a aba atual.
let accessToken: string | null = null
let sessionVersion = 0

export const getStaffAccessToken = (): string | null => accessToken
export const getStaffSessionVersion = (): number => sessionVersion
export const setStaffAccessToken = (token: string | null): void => {
  accessToken = token?.trim() || null
}
export const clearStaffAccessToken = (): void => {
  sessionVersion++
  accessToken = null
  const keys = ['access-token', 'client', 'uid', 'user', 'role', 'token-type',
    'establishment-permissions', 'establishment-data', 'salon-config']
  for (const storage of [localStorage, sessionStorage]) {
    for (const key of keys) storage.removeItem(key)
  }
}
