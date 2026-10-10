<template>
  <div
    class="legal-page bg-body text-body min-vh-100"
    :data-bs-theme="isDarkMode ? 'dark' : 'light'"
  >
    <!-- Header -->
    <nav class="navbar navbar-expand-lg fixed-top shadow-sm py-3" style="background: var(--glass-bg); backdrop-filter: blur(15px); z-index: 1030;">
      <div class="container">
        <router-link :to="`/empresa/${slug}`" class="navbar-brand fw-bold fs-3 text-primary m-0">
          {{ establishmentName || 'EasySlotting' }}
        </router-link>
        <router-link :to="`/empresa/${slug}`" class="btn btn-sm btn-outline-primary rounded-pill">
          <i class="bi bi-arrow-left me-1"></i>Voltar ao site
        </router-link>
      </div>
    </nav>

    <!-- Conteúdo -->
    <div class="container py-5 mt-5" style="max-width: 800px;">
      <!-- Loading -->
      <div v-if="loading" class="text-center py-5">
        <div class="spinner-border text-primary" role="status"></div>
        <p class="mt-3 text-muted">Carregando...</p>
      </div>

      <!-- Erro -->
      <div v-else-if="error" class="text-center py-5">
        <i class="bi bi-exclamation-circle text-warning" style="font-size: 3rem;"></i>
        <h4 class="fw-bold mt-3">{{ error }}</h4>
        <router-link :to="`/empresa/${slug}`" class="btn btn-primary rounded-pill mt-3">
          Voltar ao site
        </router-link>
      </div>

      <!-- Conteúdo -->
      <div v-else class="legal-content">
        <div class="legal-header mb-5">
          <h1 class="fw-800">{{ pageTitle }}</h1>
          <p class="text-muted small mb-0">Última atualização: 21/06/2026</p>
        </div>

        <div class="legal-body" v-html="sanitizedContent"></div>

        <div class="mt-5 pt-4 border-top text-center">
          <p class="small text-muted mb-0">
            © {{ new Date().getFullYear() }} {{ establishmentName }} - Todos os direitos reservados.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '@/services/api'
import DOMPurify from 'dompurify'

const route = useRoute()

const slug = computed(() => String(route.params.slug || ''))
const pageType = computed(() => String(route.params.page || ''))

const loading = ref(true)
const error = ref('')
const content = ref('')
const establishmentName = ref('')
const isDarkMode = ref(localStorage.getItem('easyslotting_theme') === 'dark')

const pageTitles: Record<string, string> = {
  privacy_policy: 'Política de Privacidade',
  terms_of_use: 'Termos de Uso',
  cookie_policy: 'Política de Cookies',
  about_us: 'Quem Somos',
  faq: 'Perguntas Frequentes',
  contact_info: 'Informações de Contato'
}

const pageTitle = computed(() => pageTitles[pageType.value] || 'Página')

// Converte texto puro em HTML formatado
function textToHtml(text: string): string {
  if (!text) return ''

  let html = text
    // Escape HTML entities
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

  // Títulos: linhas que começam com número + ponto (ex: "1. Título")
  html = html.replace(/^(\d+\..+)$/gm, '<h2>$1</h2>')

  // Negrito: texto entre ** (ex: "**Negrito**")
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')

  // Itálico: texto entre * (ex: "*Itálico*")
  html = html.replace(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/g, '<em>$1</em>')

  // Listas: linhas que começam com • ou -
  html = html.replace(/^(\s*)([•\-])\s+(.+)$/gm, '<li>$3</li>')
  // Agrupa <li> consecutivos em <ul>
  html = html.replace(/(<li>.*<\/li>\n?)+/g, '<ul>$&</ul>')

  // Parágrafos: linhas duplas viram parágrafo
  html = html.replace(/\n\n+/g, '</p><p>')
  html = '<p>' + html + '</p>'

  // Limpa parágrafos vazios
  html = html.replace(/<p>\s*<\/p>/g, '')
  html = html.replace(/<p>\s*(<h2>)/g, '$1')
  html = html.replace(/(<\/h2>)\s*<\/p>/g, '$1')
  html = html.replace(/<p>\s*(<ul>)/g, '$1')
  html = html.replace(/(<\/ul>)\s*<\/p>/g, '$1')

  // Quebras de linha simples viram <br>
  html = html.replace(/\n/g, '<br>')

  // Limpa <br> antes de títulos e listas
  html = html.replace(/<br>\s*(<h2>)/g, '$1')
  html = html.replace(/<br>\s*(<ul>)/g, '$1')
  html = html.replace(/<br>\s*(<\/ul>)/g, '$1')

  return html
}

const sanitizedContent = computed(() => {
  if (!content.value) return ''

  let text = content.value

  // Substitui dinamicamente os marcadores não editados pelos dados reais do estabelecimento
  if (establishmentName.value) {
    text = text.replace(/\[\s*SEU ESTABELECIMENTO\s*\]|\[\s*NOME DO SEU ESTABELECIMENTO\s*\]/gi, establishmentName.value)
  }

  const hasHtml = /<[a-z][\s\S]*>/i.test(text)
  const rawHtml = hasHtml ? text : textToHtml(text)

  return DOMPurify.sanitize(rawHtml, {
    ALLOWED_TAGS: [
      'h1','h2','h3','h4','h5','h6','p','br','ul','ol','li','strong','em',
      'b','i','u','s','strike','a','span','div','blockquote','pre','code',
      'table','thead','tbody','tr','th','td','hr','mark'
    ],
    ALLOWED_ATTR: ['href','title','class','target','rel'],
    ALLOW_DATA_ATTR: false
  })
})

const fetchLegalPage = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await api.get(`/public/establishments/${slug.value}/legal_page`, {
      params: { page: pageType.value }
    })

    content.value = response.data.content
    establishmentName.value = response.data.establishment_name
  } catch (err: any) {
    if (err.response?.status === 404) {
      error.value = 'Esta página não foi configurada pelo estabelecimento.'
    } else {
      error.value = 'Erro ao carregar a página.'
    }
  } finally {
    loading.value = false
  }
}

onMounted(fetchLegalPage)

watch(() => route.params.page, fetchLegalPage)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

.legal-page {
  font-family: 'Plus Jakarta Sans', sans-serif;
}

.legal-header h1 {
  font-size: 2rem;
  font-weight: 800;
  color: var(--bs-body-color);
  margin-bottom: 0.5rem;
}
</style>

<style>
/* CSS global para conteúdo HTML renderizado via v-html */
.legal-body h2 {
  font-size: 1.35rem;
  font-weight: 700;
  color: #0d6efd;
  margin-top: 2.5rem;
  margin-bottom: 1rem;
  padding-bottom: 0.6rem;
  border-bottom: 2px solid #0d6efd;
}

.legal-body h3 {
  font-size: 1.1rem;
  font-weight: 600;
  color: #212529;
  margin-top: 1.5rem;
  margin-bottom: 0.5rem;
}

.legal-body p {
  margin-bottom: 1.1rem;
  color: var(--bs-body-color);
  line-height: 1.75;
}

.legal-body ul,
.legal-body ol {
  margin-top: 0.4rem;
  margin-bottom: 1.35rem;
  padding-left: 1.5rem;
  list-style-position: outside;
}

.legal-body li {
  margin-bottom: 0.5rem;
  padding-left: 0.25rem;
  color: var(--bs-body-color);
  line-height: 1.65;
}

.legal-body strong {
  font-weight: 700;
  color: #212529;
}

.legal-body a {
  color: #0d6efd;
  text-decoration: none;
  font-weight: 500;
}

.legal-body a:hover {
  text-decoration: underline;
}

.legal-body em {
  font-style: italic;
  color: #6c757d;
}

.legal-body blockquote {
  border-left: 4px solid #0d6efd;
  padding: 0.75rem 1rem;
  margin: 1rem 0;
  background: rgba(13, 110, 253, 0.05);
  border-radius: 0 8px 8px 0;
}

.legal-body table {
  width: 100%;
  border-collapse: collapse;
  margin: 1rem 0;
}

.legal-body th,
.legal-body td {
  padding: 0.75rem;
  border: 1px solid #dee2e6;
  text-align: left;
  font-size: 0.9rem;
}

.legal-body th {
  background: #f8f9fa;
  font-weight: 600;
}

.legal-body hr {
  border: none;
  border-top: 1px solid #dee2e6;
  margin: 2rem 0;
}
</style>
