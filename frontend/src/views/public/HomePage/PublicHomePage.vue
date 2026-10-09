<template>
  <div
    v-if="loadingEmpresa"
    class="d-flex justify-content-center align-items-center"
    style="min-height: 100vh;"
  >
    <div class="text-center">
      <div class="spinner-border text-primary mb-3" role="status"></div>
      <p class="mb-0">Carregando site...</p>
    </div>
  </div>

  <div
    v-else
    class="home-page"
    style="padding-top: 74px;"
    :data-bs-theme="store.isDarkMode ? 'dark' : 'light'"
    :style="pageThemeVars"
  >
    <nav class="navbar navbar-expand-lg fixed-top">
      <div class="container d-flex align-items-center">
        <router-link :to="`/empresa/${route.params.slug}`" class="navbar-brand fw-bold fs-3 custom-logo m-0">
          {{ store.salonConfig?.nome || 'EasySlotting' }}
        </router-link>

        <div class="collapse navbar-collapse" id="navContent">
          <ul class="navbar-nav me-auto"></ul>

          <div class="d-flex flex-wrap align-items-center gap-2 gap-lg-3 mt-3 mt-lg-0">
            <div v-if="!isAuthenticated" class="d-flex flex-wrap align-items-center gap-2">
              <router-link
                :to="{ path: `/empresa/${currentSlug}/login`, query: { redirect: route.fullPath } }"
                class="btn btn-link text-decoration-none fw-bold small dynamic-text"
              >
                Entrar
              </router-link>

              <router-link
                :to="`/empresa/${currentSlug}/cadastro`"
                class="btn btn-sm rounded-pill fw-bold px-3 py-2 border-2 custom-outline-btn"
              >
                Criar conta
              </router-link>
            </div>

            <div v-else class="d-flex flex-wrap align-items-center gap-2">
              <button
                type="button"
                class="btn btn-sm rounded-pill fw-bold px-4 py-2 custom-btn"
                @click="goToMyAccount"
              >
                Minha Conta
              </button>

              <button
                type="button"
                class="btn btn-sm rounded-pill fw-bold px-3 py-2 border-2 custom-outline-btn"
                @click="logout"
              >
                Sair
              </button>
            </div>
          </div>
        </div>

        <div class="d-flex align-items-center gap-3 ms-auto ms-lg-4">
          <input
            type="checkbox"
            id="darkToggle"
            class="d-none"
            v-model="store.isDarkMode"
          >

          <label for="darkToggle" class="theme-switch mb-0">
            <div class="ball"></div>
            <i class="bi bi-sun-fill text-warning"></i>
            <i class="bi bi-moon-stars-fill text-secondary"></i>
          </label>

          <button
            class="navbar-toggler border-0 shadow-none p-0"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#navContent"
          >
            <i class="bi bi-list fs-2 dynamic-text"></i>
          </button>
        </div>
      </div>
    </nav>

    <section
      class="hero-section d-flex align-items-center justify-content-center"
      :style="{
        backgroundImage: `url(${store.salonConfig?.imagens?.capaUrl || getDefaultBannerUrl()})`
      }"
    >
      <div class="container text-center hero-content">
        <h1 class="display-3 fw-bold text-white">
          {{ store.salonConfig?.nome || 'EasySlotting' }}
        </h1>
      
        <p class="lead fw-semibold text-white mb-4">
          {{ store.salonConfig?.descricao || '' }}
        </p>
      
        <router-link
          :to="heroConfig.buttonLink || `/empresa/${route.params.slug}/agendamento`"
          class="btn btn-primary btn-lg rounded-pill fw-bold px-5 py-3 shadow text-decoration-none custom-btn"
        >
          <i class="bi bi-calendar-check me-2"></i>
          {{ heroConfig.buttonText }}
        </router-link>
      </div>
    </section>

    <div class="container search-container">
      <div class="featured-panel position-relative">
        <div class="d-flex justify-content-between align-items-center mb-4">
          <h4 class="fw-bold m-0 dynamic-text">O que nossos clientes dizem</h4>
        </div>

        <button
          type="button"
          aria-label="Voltar depoimentos"
          class="shadow-sm position-absolute z-3 carousel-nav-btn carousel-nav-left"
          @click="scrollManual(-1)"
        >
          <i class="bi bi-chevron-left fw-bold"></i>
        </button>
        
        <button
          type="button"
          aria-label="Avançar depoimentos"
          class="shadow-sm position-absolute z-3 carousel-nav-btn carousel-nav-right"
          @click="scrollManual(1)"
        >
          <i class="bi bi-chevron-right fw-bold"></i>
        </button>

        <div class="testimonial-viewport">
          <div
            ref="scrollContainer"
            class="testimonial-track"
            @mouseenter="pauseAutoScroll"
            @mouseleave="resumeAfterInteraction"
            @touchstart="handleTouchStart"
            @touchend="handleTouchEnd"
          >
            <div
              v-for="(testimonial, index) in carouselTestimonials"
              :key="`${testimonial.id}-${index}`"
              class="carousel-item-custom"
            >
              <div class="company-card p-4 d-flex flex-column align-items-center text-center">
                <img
                  :src="testimonial.image"
                  class="rounded-circle mb-3 shadow-sm"
                  style="width: 90px; height: 90px; object-fit: cover;"
                  :alt="testimonial.name"
                >

                <h5 class="fw-bold mb-1 dynamic-text">
                  {{ testimonial.name }}
                </h5>

                <p class="small mb-3 dynamic-text" style="opacity: 0.8;">
                  {{ testimonial.serviceCompleted }}
                </p>

                <div class="mb-3 text-warning">
                  <i
                    v-for="i in Math.floor(testimonial.rating)"
                    :key="`full-${index}-${i}`"
                    class="bi bi-star-fill"
                  ></i>

                  <i
                    v-if="testimonial.rating % 1 !== 0"
                    class="bi bi-star-half"
                  ></i>

                  <i
                    v-for="i in (5 - Math.ceil(testimonial.rating))"
                    :key="`empty-${index}-${i}`"
                    class="bi bi-star"
                  ></i>
                </div>

                <p class="small fst-italic dynamic-text testimonial-text" style="opacity: 0.7;">
                  {{ testimonial.text }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <footer
      class="mt-5 py-5"
      style="background: var(--glass-bg); backdrop-filter: blur(15px); border-top: 1px solid rgba(0,0,0,0.05); transition: background 0.4s;"
    >
      <div class="container">
        <!-- Primeira fileira: Logo + Informações + Facilidades -->
        <div class="row g-4">
          <div class="col-lg-4 col-md-6">
            <router-link :to="`/empresa/${route.params.slug}`" class="fw-bold fs-4 custom-logo text-decoration-none d-block text-wrap text-break mb-2">
              {{ store.salonConfig?.nome || 'EasySlotting' }}
            </router-link>

            <p class="mt-3 dynamic-text" style="max-width: 300px; opacity: 0.8;">
              {{ store.salonConfig?.descricao || '' }}
            </p>

            <div class="d-flex gap-3 mt-4">
              <a
                :href="'https://instagram.com/' + (store.salonConfig?.contato?.instagram || '')"
                target="_blank"
                class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
              >
                <i class="bi bi-instagram"></i>
              </a>

              <a
                :href="store.salonConfig?.contato?.facebook || '#'"
                target="_blank"
                class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
              >
                <i class="bi bi-facebook"></i>
              </a>

              <a
                :href="'https://wa.me/55' + (store.salonConfig?.contato?.whatsapp ? store.salonConfig.contato.whatsapp.replace(/\D/g, '') : '')"
                target="_blank"
                class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
              >
                <i class="bi bi-whatsapp"></i>
              </a>
            </div>
          </div>

          <div class="col-lg-4 col-md-6">
            <h6 class="fw-bold mb-4 dynamic-text">Informações</h6>

            <ul class="list-unstyled d-grid gap-2">
              <li>
                <span class="small dynamic-text" style="opacity: 0.8;">
                  <i class="bi bi-geo-alt-fill me-2 custom-icon"></i>
                  {{ store.salonConfig?.contato?.endereco || '' }}
                </span>
              </li>

              <li>
                <span class="small dynamic-text" style="opacity: 0.8;">
                  <i class="bi bi-telephone-fill me-2 custom-icon"></i>
                  {{ store.salonConfig?.contato?.telefone || '' }}
                </span>
              </li>

              <li>
                <span class="small dynamic-text" style="opacity: 0.8;">
                  <i class="bi bi-whatsapp me-2 custom-icon"></i>
                  {{ store.salonConfig?.contato?.whatsapp || '' }}
                </span>
              </li>

              <li>
                <span class="small dynamic-text" style="opacity: 0.8;">
                  <i class="bi bi-clock-fill me-2 custom-icon"></i>
                  {{ store.salonConfig?.funcionamento?.horariosTexto || '' }}
                </span>
              </li>
            </ul>
          </div>

          <div class="col-lg-4 col-md-12">
            <h6 class="fw-bold mb-4 dynamic-text">Facilidades</h6>

            <div class="d-flex flex-wrap gap-2 mb-4">
              <span
                v-for="(amenity, index) in (store.salonConfig?.facilidades?.comodidades || [])"
                :key="index"
                class="badge bg-secondary bg-opacity-10 dynamic-text border"
                style="opacity: 0.8;"
              >
                {{ amenity }}
              </span>
            </div>

            <h6 class="fw-bold mb-3 small dynamic-text">Aceitamos</h6>
            <div class="d-flex gap-3 opacity-75">
              <i
                v-if="store.salonConfig?.facilidades?.pagamentos?.includes('pix')"
                class="bi bi-qr-code fs-4 custom-icon"
                title="Pix"
              ></i>

              <i
                v-if="store.salonConfig?.facilidades?.pagamentos?.includes('cartao')"
                class="bi bi-credit-card fs-4 custom-icon"
                title="Cartão de Crédito"
              ></i>

              <i
                v-if="store.salonConfig?.facilidades?.pagamentos?.includes('dinheiro')"
                class="bi bi-cash fs-4 custom-icon"
                title="Dinheiro"
              ></i>
            </div>
          </div>
        </div>

        <!-- Segunda fileira: Links Legais -->
        <div class="row mt-4 pt-4 border-top">
          <div class="col-12">
            <div class="d-flex flex-wrap justify-content-center gap-3 gap-lg-4">
              <router-link v-if="legalPages.privacy_policy" :to="`/empresa/${route.params.slug}/privacy_policy`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-shield-lock me-1"></i>Política de Privacidade
              </router-link>
              <router-link v-if="legalPages.terms_of_use" :to="`/empresa/${route.params.slug}/terms_of_use`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-file-earmark-text me-1"></i>Termos de Uso
              </router-link>
              <router-link v-if="legalPages.cookie_policy" :to="`/empresa/${route.params.slug}/cookie_policy`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-cookie me-1"></i>Política de Cookies
              </router-link>
              <router-link v-if="legalPages.about_us" :to="`/empresa/${route.params.slug}/about_us`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-info-circle me-1"></i>Quem Somos
              </router-link>
              <router-link v-if="legalPages.faq" :to="`/empresa/${route.params.slug}/faq`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-question-circle me-1"></i>Perguntas Frequentes
              </router-link>
              <router-link v-if="legalPages.contact_info" :to="`/empresa/${route.params.slug}/contact_info`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-envelope me-1"></i>Contato
              </router-link>
            </div>
          </div>
        </div>

        <hr class="my-4 opacity-10">

        <p class="text-center small mb-0 dynamic-text" style="opacity: 0.7;">
          © 2026 {{ store.salonConfig?.nome || 'EasySlotting' }} - Todos os direitos reservados. Feito com EasySlotting.
        </p>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { api, logoutCustomer } from '@/services/api'
import { ref, onMounted, onUnmounted, computed, nextTick, watch } from 'vue'
import { useThemeStore } from '@/stores/themeStore'
import { useRouter, useRoute } from 'vue-router'
import { isCustomerLoggedIn, clearCustomerSession } from '@/services/customerAuth'

const store = useThemeStore()
const router = useRouter()
const route = useRoute()

const loadingEmpresa = ref(true)

const pageThemeVars = computed(() => ({
  '--logo-color': store.themeConfig.logoColor,
  '--button-bg': store.themeConfig.buttonBg,
  '--button-hover': store.themeConfig.buttonHover,
  '--icon-color': store.themeConfig.iconColor,
  '--custom-font': store.themeConfig.fontFamily,
  '--glass-bg': store.isDarkMode ? store.themeConfig.navbarDark : store.themeConfig.navbarLight,
  '--bs-tertiary-bg': store.isDarkMode ? store.themeConfig.backgroundDark : store.themeConfig.backgroundLight,
  '--card-bg': store.isDarkMode ? 'rgba(255, 255, 255, 0.035)' : 'var(--bs-tertiary-bg)',
  '--card-border': store.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
  '--custom-text-color': store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight,
  fontFamily: store.themeConfig.fontFamily,
  fontSize: store.themeConfig.fontSize,
  backgroundColor: store.isDarkMode ? store.themeConfig.backgroundDark : store.themeConfig.backgroundLight,
  color: store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight
}))

const isAuthenticated = ref(false)

const syncAuthState = () => {
  isAuthenticated.value = isCustomerLoggedIn()
}

const currentSlug = computed(() => String(route.params.slug || ''))

const legalPages = computed(() => store.salonConfig?.legal_pages || {})

const myAccountRoute = computed(() =>
  `/empresa/${currentSlug.value}/minha-conta`
)

const goToMyAccount = () => {
  router.push(myAccountRoute.value)
}

const logout = async () => {
  try {
    await logoutCustomer()
  } catch {
    // Ignora erro — limpa local mesmo assim
  }

  clearCustomerSession()
  store.clearSalonConfig()

  const slug = currentSlug.value
  if (slug) {
    localStorage.removeItem(`public-establishment-${slug}`)
  }

  syncAuthState()
  router.push(slug ? `/empresa/${slug}` : '/')
}

const heroConfig = ref({
  buttonText: 'AGENDAR HORÁRIO',
  buttonLink: '',
  backgroundImage: ''
})

const testimonials = ref([
  { id: 1, name: 'Carlos Mendes', serviceCompleted: 'Corte Degradê (Fade)', image: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200', rating: 5, text: '"Melhor fade da cidade! Atendimento excelente, ambiente top e o aplicativo facilita demais na hora de marcar."' },
  { id: 2, name: 'Lucas Ferreira', serviceCompleted: 'Corte e Barba', image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200', rating: 5, text: '"Faço cabelo e barba toda semana. O serviço de toalha quente é sensacional. Profissionais de primeira!"' },
  { id: 3, name: 'Rafael Souza', serviceCompleted: 'Barboterapia', image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200', rating: 4.5, text: '"Fui dar um trato na barba e curti muito. O esquema de agendar pelo celular e chegar na hora certa não tem preço."' },
  { id: 4, name: 'Marcos Silva', serviceCompleted: 'Corte Clássico na Tesoura', image: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200', rating: 5, text: '"Difícil achar quem corte bem na tesoura hoje em dia, mas aqui os caras manjam muito. E a cerveja é sempre gelada."' },
  { id: 5, name: 'Thiago Alves', serviceCompleted: 'Platinado / Nevou', image: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200', rating: 5, text: '"Mandei o nevou pro final de ano e o resultado ficou insano. Os produtos que usam são muito bons, não estragou meu cabelo."' }
])

const scrollContainer = ref<HTMLElement | null>(null)

const AUTO_SCROLL_TIME = 8000
let autoScrollInterval: ReturnType<typeof setInterval> | null = null
let scrollStopTimeout: ReturnType<typeof setTimeout> | null = null

const isUserInteracting = ref(false)
const isAdjustingPosition = ref(false)

const visibleCards = computed(() => {
  if (typeof window === 'undefined') return 3
  if (window.innerWidth <= 767) return 1
  if (window.innerWidth <= 991) return 2
  return 3
})

const cloneCount = computed(() => {
  return Math.min(visibleCards.value, testimonials.value.length)
})

const carouselTestimonials = computed(() => {
  if (!testimonials.value.length) return []

  const startClones = testimonials.value.slice(-cloneCount.value)
  const endClones = testimonials.value.slice(0, cloneCount.value)

  return [...startClones, ...testimonials.value, ...endClones]
})

function getApiBaseUrl() {
  return (api.defaults.baseURL || '').replace(/\/api\/?$/, '')
}

function buildFileUrl(path: string) {
  if (!path) return ''
  if (path.startsWith('http://') || path.startsWith('https://')) return path
  return `${getApiBaseUrl()}${path}`
}

function getDefaultAvatarUrl() {
  return `${getApiBaseUrl()}/uploads/establishments/Avatar-Padrao.jpg`
}

function getDefaultBannerUrl() {
  return `${getApiBaseUrl()}/uploads/establishments/Capa-Padrao.jpg`
}

function getGap(): number {
  return 24
}

function getCardWidth(): number {
  if (!scrollContainer.value) return 0
  const card = scrollContainer.value.querySelector('.carousel-item-custom') as HTMLElement | null
  return card ? card.offsetWidth : 0
}

function getStep(): number {
  const width = getCardWidth()
  if (!width) return 0
  return width + getGap()
}

function getCenterOffset(): number {
  const el = scrollContainer.value
  if (!el) return 0

  const cardWidth = getCardWidth()
  if (!cardWidth) return 0

  return Math.max((el.clientWidth - cardWidth) / 2, 0)
}

function getCenteredPosition(index: number): number {
  return (getStep() * index) - getCenterOffset()
}

function getInitialOffset(): number {
  return getCenteredPosition(cloneCount.value)
}

function setScrollInstant(position: number) {
  const el = scrollContainer.value
  if (!el) return

  isAdjustingPosition.value = true
  el.style.scrollBehavior = 'auto'
  el.scrollLeft = position

  requestAnimationFrame(() => {
    if (!el) return
    el.style.scrollBehavior = 'smooth'
    isAdjustingPosition.value = false
  })
}

function normalizeInfiniteScroll() {
  const el = scrollContainer.value
  if (!el || isAdjustingPosition.value) return

  const step = getStep()
  if (!step) return

  const current = el.scrollLeft
  const tolerance = step * 0.5

  const firstRealIndex = cloneCount.value
  const afterLastRealIndex = cloneCount.value + testimonials.value.length

  const realStart = getCenteredPosition(firstRealIndex)
  const realEnd = getCenteredPosition(afterLastRealIndex)

  if (current <= realStart - tolerance) {
    const adjusted = current + (step * testimonials.value.length)
    setScrollInstant(adjusted)
    return
  }

  if (current >= realEnd - tolerance) {
    const adjusted = current - (step * testimonials.value.length)
    setScrollInstant(adjusted)
  }
}

function scrollByCards(direction: number) {
  const container = scrollContainer.value
  if (!container || isAdjustingPosition.value) return

  const step = getStep()
  if (!step) return

  const start = container.scrollLeft
  const target = start + step * direction
  const duration = 550

  let startTime: number | null = null

  function easeInOut(t: number) {
    return t < 0.5
      ? 2 * t * t
      : 1 - Math.pow(-2 * t + 2, 2) / 2
  }

  function animate(currentTime: number) {
    if (!startTime) startTime = currentTime
    const progress = Math.min((currentTime - startTime) / duration, 1)

    const eased = easeInOut(progress)
    container!.scrollLeft = start + (target - start) * eased

    if (progress < 1) {
      requestAnimationFrame(animate)
    }
  }

  requestAnimationFrame(animate)
}

function moveNext() {
  if (isUserInteracting.value) return
  scrollByCards(1)
}

function startAutoScroll() {
  if (autoScrollInterval || testimonials.value.length <= visibleCards.value) return

  autoScrollInterval = setInterval(() => {
    moveNext()
  }, AUTO_SCROLL_TIME)
}

function pauseAutoScroll() {
  if (autoScrollInterval) {
    clearInterval(autoScrollInterval)
    autoScrollInterval = null
  }
}

function resumeAfterInteraction() {
  pauseAutoScroll()
  window.setTimeout(() => {
    if (!isUserInteracting.value) {
      startAutoScroll()
    }
  }, 1200)
}

function scrollManual(direction: number) {
  pauseAutoScroll()
  scrollByCards(direction)
  resumeAfterInteraction()
}

function handleTouchStart() {
  isUserInteracting.value = true
  pauseAutoScroll()
}

function handleTouchEnd() {
  window.setTimeout(() => {
    isUserInteracting.value = false
    normalizeInfiniteScroll()
    resumeAfterInteraction()
  }, 260)
}

function handleMouseDown() {
  isUserInteracting.value = true
  pauseAutoScroll()
}

function handleMouseUp() {
  window.setTimeout(() => {
    isUserInteracting.value = false
    normalizeInfiniteScroll()
    resumeAfterInteraction()
  }, 260)
}

function handleScroll() {
  if (scrollStopTimeout) {
    clearTimeout(scrollStopTimeout)
  }

  scrollStopTimeout = setTimeout(() => {
    normalizeInfiniteScroll()
  }, 120)
}

function resetCarouselPosition() {
  nextTick(() => {
    const step = getStep()
    if (!step) return
    setScrollInstant(getInitialOffset())
  })
}

function handleResize() {
  resetCarouselPosition()
}

const formatarEmpresa = (data: any) => {
  return {
    nome: data.name || '',
    descricao: data.description || '',
    imagens: {
      avatarUrl: data.logo
        ? buildFileUrl(data.logo)
        : getDefaultAvatarUrl(),
      capaUrl: data.banner
        ? buildFileUrl(data.banner)
        : getDefaultBannerUrl()
    },
    contato: {
      endereco: [
        data.address?.street,
        data.address?.number,
        data.address?.neighborhood,
        data.address?.city,
        data.address?.state
      ].filter(Boolean).join(', '),
      telefone: data.phone || '',
      whatsapp: data.whatsapp || '',
      instagram: data.instagram || '',
      facebook: data.facebook || ''
    },
    funcionamento: {
      horariosTexto: data.public_settings?.horarios_texto || ''
    },
    facilidades: {
      comodidades: data.amenities || [],
      pagamentos: data.payment_methods || []
    },
    depoimentos: data.testimonials || [],
    servicos: data.services || [],
    theme: data.public_settings?.theme || null,
    booking_mode: data.booking_mode || 'time',
    legal_pages: data.legal_pages || {}
  }
}

const carregarEmpresa = async () => {
  try {
    loadingEmpresa.value = true

    const slug = currentSlug.value
    if (!slug) {
      loadingEmpresa.value = false
      return
    }

    const cacheKey = `public-establishment-${slug}`
    const cache = localStorage.getItem(cacheKey)

    if (cache) {
      try {
        const empresaCache = JSON.parse(cache)
        store.setSalonConfig(empresaCache)
        heroConfig.value.buttonLink = `/empresa/${slug}/agendamento`
      } catch {
        localStorage.removeItem(cacheKey)
      }
    }

    testimonials.value = []

    const response = await api.get(`/public/establishments/${slug}`)
    const data = response.data

    const empresaFormatada = formatarEmpresa(data)

    store.setSalonConfig(empresaFormatada)
    localStorage.setItem(cacheKey, JSON.stringify(empresaFormatada))

    heroConfig.value.buttonLink = `/empresa/${slug}/agendamento`

    if (Array.isArray(data.testimonials) && data.testimonials.length > 0) {
      testimonials.value = data.testimonials
        .filter((item: any) => {
          // Exibe o depoimento a menos que exibirNaHome seja explicitamente false
          const exibir = item.exibirNaHome
          return exibir !== false && exibir !== 'false'
        })
        .map((item: any) => ({
          id:               item.id,
          name:             item.nome         || 'Cliente',
          serviceCompleted: item.servico       || '',
          image:            item.foto ? buildFileUrl(item.foto) : `https://ui-avatars.com/api/?name=${encodeURIComponent(item.nome || 'C')}&background=random&size=80`,
          rating:           Number(item.rating) || 5,
          text:             item.texto ? `"${item.texto}"` : `"${item.comment || ''}"`
        }))
        .filter((t: any) => t.text && t.text.length > 3)  // ignora feedbacks sem texto
    }
  } catch (error) {
    console.error('Erro ao carregar site:', error)
  } finally {
    loadingEmpresa.value = false
  }
}

onMounted(async () => {
  syncAuthState()
  await carregarEmpresa()

  nextTick(() => {
    resetCarouselPosition()

    const el = scrollContainer.value
    if (!el) return

    el.addEventListener('scroll', handleScroll, { passive: true })
    el.addEventListener('mousedown', handleMouseDown)
    window.addEventListener('mouseup', handleMouseUp)
    window.addEventListener('resize', handleResize)

    startAutoScroll()
  })

  const navContent = document.getElementById('navContent')
  if (navContent) {
    navContent.addEventListener('shown.bs.collapse', () => {
      document.body.style.overflow = 'hidden'
    })
    navContent.addEventListener('hidden.bs.collapse', () => {
      document.body.style.overflow = ''
    })
  }
})

watch(() => route.params.slug, async () => {
  syncAuthState()
  await carregarEmpresa()
})

onUnmounted(() => {
  pauseAutoScroll()

  if (scrollStopTimeout) {
    clearTimeout(scrollStopTimeout)
  }

  const el = scrollContainer.value
  if (el) {
    el.removeEventListener('scroll', handleScroll)
    el.removeEventListener('mousedown', handleMouseDown)
  }

  window.removeEventListener('mouseup', handleMouseUp)
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
.custom-logo {
  color: var(--logo-color) !important;
  transition: color 0.3s;
}

.custom-icon {
  color: var(--icon-color) !important;
  transition: color 0.3s;
}

.dynamic-text {
  color: var(--custom-text-color) !important;
  transition: color 0.3s;
}

.custom-btn {
  background-color: var(--button-bg) !important;
  border-color: var(--button-bg) !important;
  color: #fff !important;
  transition: background-color 0.3s, border-color 0.3s;
}

.custom-btn:hover {
  background-color: var(--button-hover) !important;
  border-color: var(--button-hover) !important;
}

.custom-outline-btn {
  color: var(--button-bg) !important;
  border-color: var(--button-bg) !important;
  background-color: transparent !important;
  transition: background-color 0.3s, color 0.3s, border-color 0.3s;
}

.custom-outline-btn:hover {
  background-color: var(--button-hover) !important;
  border-color: var(--button-hover) !important;
  color: #fff !important;
}

.custom-icon-btn {
  color: var(--icon-color) !important;
  border-color: var(--icon-color) !important;
  transition: all 0.3s;
}

.custom-icon-btn:hover {
  background-color: var(--icon-color) !important;
  color: #fff !important;
}

.navbar { 
  backdrop-filter: blur(15px); 
  background: var(--glass-bg); 
  padding: 12px 0; 
  border-bottom: 1px solid rgba(0,0,0,0.05);
  z-index: 1030;
  box-shadow: 0 4px 12px rgba(0,0,0,0.05);
  transition: background 0.4s;
}

.nav-link { 
  font-weight: 700; 
  padding: 8px 20px !important;
  border-radius: 50px;
  transition: 0.3s;
}

@media (max-width: 991px) {
  .navbar-collapse {
    max-height: 80vh;
    overflow-y: auto;
    scrollbar-width: none;
    padding-bottom: 15px;
  }

  .navbar-collapse::-webkit-scrollbar {
    display: none;
  }
}

.hero-section {
  position: relative;
  overflow: hidden;
  height: 600px;
  border-radius: 0 0 40px 40px;
  background-size: cover !important;
  background-position: center center;
  background-repeat: no-repeat !important;
}

.hero-section::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to bottom,
    rgba(0,0,0,0.4),
    rgba(0,0,0,0.7)
  );
  z-index: 1;
}

.hero-content {
  position: relative;
  z-index: 2;
}

.search-container {
  margin-top: -55px;
  position: relative;
  z-index: 100;
}

.featured-panel {
  margin-top: 70px;
  padding: 0 119px 60px;
  position: relative;
}

.testimonial-viewport {
  overflow: hidden;
  width: 100%;
}

.testimonial-track {
  display: flex;
  gap: 24px;
  overflow-x: hidden;
  scrollbar-width: none;
  scroll-behavior: smooth;
  padding: 12px 2px;
  box-sizing: border-box;
  scroll-snap-type: x proximity;
  -webkit-overflow-scrolling: touch;
  overscroll-behavior-x: contain;
  overscroll-behavior-y: contain;
  cursor: default;
  user-select: none;
  overscroll-behavior-y: auto;
}

.testimonial-track:active {
  cursor: grabbing;
}

.testimonial-track::-webkit-scrollbar {
  display: none;
}

.carousel-item-custom {
  flex: 0 0 calc((100% - 48px) / 3);
  min-width: calc((100% - 48px) / 3);
  box-sizing: border-box;
  display: flex;
  scroll-snap-align: center;
}

@media (max-width: 991px) {
  .carousel-item-custom {
    flex: 0 0 calc((100% - 24px) / 2);
    min-width: calc((100% - 24px) / 2);
  }
}

@media (max-width: 767px) {
  .carousel-item-custom {
    flex: 0 0 100%;
    min-width: 100%;
  }
}

.company-card {
  width: 100%;
  box-shadow: 0 4px 20px rgba(0,0,0,0.04);
  border-radius: 25px;
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-sizing: border-box;
  transform: none;
}

.testimonial-text {
  max-width: 95%;
  line-height: 1.6;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 4;
  line-clamp: 4;
  -webkit-box-orient: vertical;
}

.theme-switch {
  width: 55px;
  height: 28px;
  background: #333;
  border-radius: 50px;
  position: relative;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-around;
}

.theme-switch .ball {
  width: 22px;
  height: 22px;
  background: white;
  border-radius: 50%;
  position: absolute;
  left: 3px;
  transition: 0.4s;
}

#darkToggle:checked + .theme-switch .ball {
  transform: translateX(27px);
}

.carousel-nav-btn {
  width: 48px;
  height: 48px;
  padding: 0;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: absolute;
  top: 50%;
  transform: translateY(-50%) !important;
  appearance: none;
  -webkit-appearance: none;
  border: 1px solid var(--card-border);
  background: rgba(255, 255, 255, 0.92);
  color: #1f2937;
  backdrop-filter: blur(8px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
  transition: background 0.3s ease, color 0.3s ease, border-color 0.3s ease, box-shadow 0.3s ease, opacity 0.3s ease;
  cursor: pointer;
}

.carousel-nav-btn i {
  font-size: 1.2rem;
  line-height: 1;
  pointer-events: none;
}

.carousel-nav-btn:hover,
.carousel-nav-btn:focus,
.carousel-nav-btn:focus-visible,
.carousel-nav-btn:active {
  transform: translateY(-50%) !important;
  top: 50% !important;
  margin-top: 0 !important;
  outline: none !important;
  box-shadow: 0 8px 24px rgba(0,0,0,0.16);
}

.carousel-nav-btn:active i,
.carousel-nav-btn:focus i,
.carousel-nav-btn:hover i {
  transform: none !important;
}

.carousel-nav-btn::before,
.carousel-nav-btn::after {
  transform: none !important;
}

.carousel-nav-left {
  left: 34px;
}

.carousel-nav-right {
  right: 34px;
}

[data-bs-theme="dark"] .carousel-nav-btn {
  background: rgba(25, 25, 25, 0.88);
  color: #f8f9fa;
  border-color: rgba(255,255,255,0.12);
  box-shadow: 0 8px 24px rgba(0,0,0,0.35);
}

@media (hover: hover) and (pointer: fine) {
  .company-card:hover {
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.12);
    transform: translateY(-4px);
    border-color: var(--button-bg);
  }

  .carousel-nav-btn:hover {
    transform: translateY(-50%) !important;
    opacity: 1;
  }
}

@media (hover: none), (pointer: coarse) {
  .company-card:hover {
    box-shadow: 0 2px 6px rgba(0,0,0,0.04) !important;
    transform: none !important;
  }

  .carousel-nav-btn:hover {
    transform: translateY(-50%) !important;
  }
}
</style>