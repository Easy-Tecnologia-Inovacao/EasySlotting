/**
 * Utilitários de Segurança, Sanitização e Validação do Módulo de Serviços e Pacotes
 */
import DOMPurify from 'dompurify'

// ─── DTOs de Entrada / Saída ──────────────────────────────────────────────

export interface ServiceCreateDTO {
  name: string
  description: string
  service_type: string
  duration_minutes: number
  price: number
  employee_ids: number[]
}

export interface ServiceUpdateDTO {
  id: number
  name: string
  description: string
  service_type: string
  duration_minutes: number
  price: number
  employee_ids: number[]
}

export interface ServicePackageCreateDTO {
  name: string
  description: string
  included_items: string
  duration_minutes: number
  price: number
  service_id: number
  user_id: number | null
  sessions_total: number
}

export interface ServicePackageUpdateDTO {
  id: number
  name: string
  description: string
  included_items: string
  duration_minutes: number
  price: number
  service_id: number
  user_id: number | null
  sessions_total: number
}

// ─── Sanitização de Entradas (XSS Protection) ──────────────────────────────

/**
 * Remove qualquer tag HTML/XML de uma string para evitar XSS básico.
 */
export function sanitizeText(text: string): string {
  if (!text) return ''
  return text
    .replace(/<[^>]*>/g, '') // remove tags HTML
    .replace(/[&<>"']/g, (match) => { // escape HTML entities
      switch (match) {
        case '&': return '&amp;'
        case '<': return '&lt;'
        case '>': return '&gt;'
        case '"': return '&quot;'
        case "'": return '&#x27;'
        default: return match
      }
    })
    .trim()
}

/**
 * 🔒 Higieniza o texto livre eliminando qualquer tag ou atributo perigoso,
 * garantindo texto limpo e seguro contra XSS.
 */
export function sanitizeFreeText(text: string): string {
  if (!text) return ''
  return DOMPurify.sanitize(text, {
    ALLOWED_TAGS: [],
    ALLOWED_ATTR: []
  }).trim()
}

// ─── Type Guards para Respostas da API ──────────────────────────────────────

export interface ServiceApiResponse {
  id: number
  name: string
  description?: string
  service_type: string
  duration_minutes: number
  price: string | number
  employees?: Array<{ id: number; name: string }>
}

export interface ServicePackageApiResponse {
  id: number
  name: string
  description?: string
  included_items?: string
  duration_minutes: number
  price: string | number
  user_id?: number | null
  user?: { id: number; name: string } | null
  service_id?: number | null
  sessions_total?: number | null
}

export function isServiceApiResponse(data: any): data is ServiceApiResponse {
  return (
    data &&
    typeof data.id === 'number' &&
    typeof data.name === 'string' &&
    typeof data.service_type === 'string' &&
    typeof data.duration_minutes === 'number' &&
    (typeof data.price === 'string' || typeof data.price === 'number')
  )
}

export function isServicePackageApiResponse(data: any): data is ServicePackageApiResponse {
  return (
    data &&
    typeof data.id === 'number' &&
    typeof data.name === 'string' &&
    typeof data.duration_minutes === 'number' &&
    (typeof data.price === 'string' || typeof data.price === 'number')
  )
}

// ─── Validação de Formulários (Frontend Defense) ────────────────────────────

export interface ValidationResult {
  isValid: boolean
  errors: Record<string, string>
}

export function validateServiceDTO(dto: Partial<ServiceCreateDTO>): ValidationResult {
  const errors: Record<string, string> = {}

  if (!dto.name || !dto.name.trim()) {
    errors.name = 'O nome do serviço é obrigatório.'
  } else if (dto.name.length > 100) {
    errors.name = 'O nome do serviço não pode exceder 100 caracteres.'
  }

  if (!dto.service_type || !dto.service_type.trim()) {
    errors.service_type = 'O tipo do serviço é obrigatório.'
  } else if (dto.service_type.length > 50) {
    errors.service_type = 'O tipo do serviço não pode exceder 50 caracteres.'
  }

  if (dto.description && dto.description.length > 500) {
    errors.description = 'A descrição não pode exceder 500 caracteres.'
  }

  if (dto.duration_minutes === undefined || dto.duration_minutes <= 0) {
    errors.duration_minutes = 'A duração deve ser maior que 0 minutos.'
  } else if (dto.duration_minutes > 1440) {
    errors.duration_minutes = 'A duração não pode exceder 24 horas (1440 minutos).'
  }

  if (dto.price === undefined || dto.price < 0) {
    errors.price = 'O preço não pode ser menor que zero.'
  } else if (dto.price >= 1000000) {
    errors.price = 'O preço deve ser menor que R$ 1.000.000,00.'
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors
  }
}

export function validateServicePackageDTO(dto: Partial<ServicePackageCreateDTO>): ValidationResult {
  const errors: Record<string, string> = {}

  if (!dto.name || !dto.name.trim()) {
    errors.name = 'O nome do pacote é obrigatório.'
  } else if (dto.name.length > 100) {
    errors.name = 'O nome do pacote não pode exceder 100 caracteres.'
  }

  if (dto.description && dto.description.length > 500) {
    errors.description = 'A descrição não pode exceder 500 caracteres.'
  }

  if (!dto.included_items || !dto.included_items.trim()) {
    errors.included_items = 'Os itens inclusos no pacote são obrigatórios.'
  } else if (dto.included_items.length > 1000) {
    errors.included_items = 'Os itens inclusos não podem exceder 1000 caracteres.'
  }

  if (dto.duration_minutes === undefined || dto.duration_minutes <= 0) {
    errors.duration_minutes = 'A duração deve ser maior que 0 minutos.'
  } else if (dto.duration_minutes > 1440) {
    errors.duration_minutes = 'A duração não pode exceder 24 horas (1440 minutos).'
  }

  if (dto.price === undefined || dto.price < 0) {
    errors.price = 'A mensalidade não pode ser menor que zero.'
  } else if (dto.price >= 1000000) {
    errors.price = 'A mensalidade deve ser menor que R$ 1.000.000,00.'
  }

  if (!dto.service_id) {
    errors.service_id = 'Selecione um serviço vinculado.'
  }

  if (dto.sessions_total === undefined || dto.sessions_total <= 0) {
    errors.sessions_total = 'A quantidade de sessões deve ser no mínimo 1.'
  } else if (dto.sessions_total > 100) {
    errors.sessions_total = 'A quantidade máxima permitida de sessões é 100.'
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors
  }
}
