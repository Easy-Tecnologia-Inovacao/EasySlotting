// Mantém o access token de staff apenas em memória durante a aba atual.
let accessToken: string | null = null

export const getStaffAccessToken = (): string | null => accessToken
export const setStaffAccessToken = (token: string | null): void => {
  accessToken = token || null
}
export const clearStaffAccessToken = (): void => {
  accessToken = null
}
