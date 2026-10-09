// src/stores/themeStore.ts
import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

const SALON_CONFIG_KEY = 'salon-config'

const defaultSalonConfig = {
  nome: 'EasySlotting',
  descricao: '',
  booking_mode: 'time',

  imagens: {
    avatarUrl: '',
    capaUrl: '',
  },

  contato: {
    endereco: '',
    telefone: '',
    whatsapp: '',
    instagram: '',
    facebook: '',
  },

  funcionamento: {
    horariosTexto: '',
  },

  facilidades: {
    comodidades: [],
    pagamentos: [],
  },

  depoimentos: [],

  legal_pages: {
    privacy_policy: '',
    terms_of_use: '',
    cookie_policy: '',
    about_us: '',
    faq: '',
    contact_info: '',
  },
}

function loadSalonConfig() {
  try {
    const raw = localStorage.getItem(SALON_CONFIG_KEY)
    if (raw) {
      const parsed = JSON.parse(raw)
      return { ...defaultSalonConfig, ...parsed }
    }
  } catch { /* ignore */ }
  return { ...defaultSalonConfig }
}

export const useThemeStore = defineStore('theme', () => {
  const salonConfig = ref(loadSalonConfig())

  const themeConfig = ref({
    logoColor: '#0d6efd',
    buttonBg: '#0d6efd',
    buttonHover: '#0b5ed7',
    iconColor: '#0d6efd',
    fontFamily: "'Plus Jakarta Sans', sans-serif",
    fontSize: '16px',

    backgroundLight: '#f8f9fa',
    textLight: '#212529',
    navbarLight: 'rgba(255, 255, 255, 0.9)',
    cardLight: '#ffffff',

    backgroundDark: '#212529',
    textDark: '#f8f9fa',
    navbarDark: 'rgba(33, 37, 41, 0.95)',
    cardDark: '#2b3035',
  })

  const isDarkMode = ref(localStorage.getItem('easysloting_theme') === 'dark')

  watch(
    isDarkMode,
    (newVal) => {
      const theme = newVal ? 'dark' : 'light'
      document.documentElement.setAttribute('data-bs-theme', theme)
      localStorage.setItem('easysloting_theme', theme)
    },
    { immediate: true }
  )

  function setSalonConfig(data: any) {
    if (!data) return

    // Atualiza dados da empresa
    if (data.nome !== undefined) salonConfig.value.nome = data.nome
    if (data.descricao !== undefined) salonConfig.value.descricao = data.descricao
    if (data.booking_mode !== undefined) salonConfig.value.booking_mode = data.booking_mode
    if (data.imagens) salonConfig.value.imagens = { ...salonConfig.value.imagens, ...data.imagens }
    if (data.contato) salonConfig.value.contato = { ...salonConfig.value.contato, ...data.contato }
    if (data.funcionamento) salonConfig.value.funcionamento = { ...salonConfig.value.funcionamento, ...data.funcionamento }
    if (data.facilidades) salonConfig.value.facilidades = { ...salonConfig.value.facilidades, ...data.facilidades }
    if (data.depoimentos) salonConfig.value.depoimentos = data.depoimentos
    if (data.legal_pages) salonConfig.value.legal_pages = { ...salonConfig.value.legal_pages, ...data.legal_pages }

    // Carrega tema dinamicamente se vier no payload original (para admin) ou via formatador
    const themeToLoad = data.public_settings?.theme || data.theme
    if (themeToLoad && typeof themeToLoad === 'object') {
      themeConfig.value = { ...themeConfig.value, ...themeToLoad }
    }

    // Persiste no localStorage para sobreviver a refreshes de página
    try {
      localStorage.setItem(SALON_CONFIG_KEY, JSON.stringify(salonConfig.value))
    } catch { /* ignore quota errors */ }
  }

  function setLogoColor(color: string) {
    themeConfig.value.logoColor = color
  }

  function setButtonColor(bg: string, hover: string) {
    themeConfig.value.buttonBg = bg
    themeConfig.value.buttonHover = hover
  }

  function setIconColor(color: string) {
    themeConfig.value.iconColor = color
  }

  function setFont(font: string) {
    themeConfig.value.fontFamily = font
  }

  function setFontSize(size: string) {
    themeConfig.value.fontSize = size
  }

  function setTextColor(lightHex: string, darkHex: string) {
    themeConfig.value.textLight = lightHex
    themeConfig.value.textDark = darkHex
  }

  function setBackground(type: string) {
    if (type === 'strongGreen') {
      themeConfig.value.backgroundLight = '#198754'
      themeConfig.value.textLight = '#ffffff'
      themeConfig.value.navbarLight = 'rgba(25, 135, 84, 0.95)'
      themeConfig.value.cardLight = '#146c43'
    } else if (type === 'strongBlue') {
      themeConfig.value.backgroundLight = '#0d6efd'
      themeConfig.value.textLight = '#ffffff'
      themeConfig.value.navbarLight = 'rgba(13, 110, 253, 0.95)'
      themeConfig.value.cardLight = '#0b5ed7'
    } else if (type === 'red') {
      themeConfig.value.backgroundLight = '#8b0000'
      themeConfig.value.textLight = '#ffffff'
      themeConfig.value.navbarLight = 'rgba(139, 0, 0, 0.95)'
      themeConfig.value.cardLight = '#660000'
    } else {
      themeConfig.value.backgroundLight = '#f8f9fa'
      themeConfig.value.textLight = '#212529'
      themeConfig.value.navbarLight = 'rgba(255, 255, 255, 0.9)'
      themeConfig.value.cardLight = '#ffffff'
    }
  }

  function resetStandard() {
    themeConfig.value = {
      logoColor: '#0d6efd',
      buttonBg: '#0d6efd',
      buttonHover: '#0b5ed7',
      iconColor: '#0d6efd',
      fontFamily: "'Plus Jakarta Sans', sans-serif",
      fontSize: '16px',
      backgroundLight: '#f8f9fa',
      textLight: '#212529',
      navbarLight: 'rgba(255, 255, 255, 0.9)',
      cardLight: '#ffffff',
      backgroundDark: '#212529',
      textDark: '#f8f9fa',
      navbarDark: 'rgba(33, 37, 41, 0.95)',
      cardDark: '#2b3035',
    }
  }

  function clearSalonConfig() {
    salonConfig.value = { ...defaultSalonConfig }
    try {
      localStorage.removeItem(SALON_CONFIG_KEY)
    } catch { /* ignore */ }
  }

  return {
    salonConfig,
    themeConfig,
    isDarkMode,
    setSalonConfig,
    clearSalonConfig,
    setLogoColor,
    setButtonColor,
    setIconColor,
    setFont,
    setFontSize,
    setTextColor,
    setBackground,
    resetStandard,
  }
})