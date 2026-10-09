<template>
  <div
    v-if="show"
    class="modal fade show d-block legal-editor-modal-backdrop"
    tabindex="-1"
    role="dialog"
    aria-modal="true"
  >
    <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable modal-ultrawide">
      <div class="modal-content border-0 shadow-lg rounded-4 overflow-hidden bg-body text-body">
        
        <!-- Header -->
        <div class="modal-header border-bottom px-4 py-3 bg-body-tertiary d-flex flex-wrap align-items-center justify-content-between gap-3">
          <div class="d-flex align-items-center gap-3">
            <div class="icon-circle bg-primary bg-opacity-10 text-primary p-2 rounded-3 d-flex align-items-center justify-content-center" style="width: 42px; height: 42px;">
              <i :class="activePageIcon" class="fs-4"></i>
            </div>
            <div>
              <h5 class="modal-title fw-extrabold mb-0 flex-grow-1 fs-5">
                Editor de Páginas Legais & LGPD
              </h5>
              <span class="small text-muted" style="font-size: 0.78rem;">
                Edição rica estilo GitHub + Pré-visualização em tempo real
              </span>
            </div>
          </div>

          <!-- Seletor de Páginas & Controles de Modo (Dark Mode Optimized) -->
          <div class="d-flex align-items-center gap-2 flex-wrap ms-auto">
            <select
              v-model="currentPageKey"
              class="form-select form-select-sm rounded-pill fw-bold shadow-sm"
              style="min-width: 210px; background-color: var(--bs-tertiary-bg, #f1f3f5) !important; color: var(--bs-body-color) !important; border-color: var(--bs-border-color) !important;"
            >
              <option v-for="(title, key) in pageTitles" :key="key" :value="key">
                {{ title }}
              </option>
            </select>

            <!-- Mode Switch (Split / Editor / Preview) -->
            <div class="btn-group btn-group-sm rounded-pill p-1 mode-switch-group shadow-sm" role="group">
              <button
                type="button"
                class="btn rounded-pill border-0 px-3 fw-bold small mode-switch-btn"
                :class="{ 'active': viewMode === 'split' }"
                @click="viewMode = 'split'"
                title="Exibir Editor e Preview Lado a Lado"
              >
                <i class="bi bi-layout-split me-1"></i>Split
              </button>
              <button
                type="button"
                class="btn rounded-pill border-0 px-3 fw-bold small mode-switch-btn"
                :class="{ 'active': viewMode === 'editor' }"
                @click="viewMode = 'editor'"
                title="Expandir Apenas Editor"
              >
                <i class="bi bi-pencil-square me-1"></i>Editor
              </button>
              <button
                type="button"
                class="btn rounded-pill border-0 px-3 fw-bold small mode-switch-btn"
                :class="{ 'active': viewMode === 'preview' }"
                @click="viewMode = 'preview'"
                title="Expandir Apenas Preview"
              >
                <i class="bi bi-eye me-1"></i>Preview
              </button>
            </div>

            <button
              type="button"
              class="btn-close shadow-none ms-2"
              @click="closeModal"
            ></button>
          </div>
        </div>

        <!-- Body Split View -->
        <div class="modal-body p-0 overflow-hidden d-flex flex-column flex-lg-row min-vh-50">
          
          <!-- LADO ESQUERDO: EDITOR -->
          <div
            v-show="viewMode === 'split' || viewMode === 'editor'"
            class="editor-pane p-3 p-md-4 d-flex flex-column border-end flex-fill"
            :class="{ 'w-lg-50': viewMode === 'split', 'w-100': viewMode === 'editor' }"
          >
            <!-- Banner Explicativo (Como Usar) -->
            <div class="explanation-box rounded-3 p-3 mb-3 d-flex align-items-start gap-3 shadow-sm">
              <i class="bi bi-lightbulb-fill text-warning fs-4 flex-shrink-0 mt-1"></i>
              <div class="small">
                <strong class="d-block text-body mb-1">Como personalizar suas Páginas Legais:</strong>
                <span class="text-secondary">
                  Use a <strong>Barra de Formatação Estilo GitHub</strong> para títulos, negritos e listas.
                  Clique nos <strong>Atalhos de Cláusulas (Ctrl+F)</strong> para pular direto para cada seção.
                  O botão <strong>"Modelo Padrão LGPD"</strong> restaura o texto jurídico recomendado.
                </span>
              </div>
            </div>

            <!-- Atalhos Rápidos: Localizar Marcadores no Texto (Ctrl+F dinâmico) -->
            <div class="mb-3">
              <div class="d-flex align-items-center justify-content-between mb-2">
                <span class="fw-bold small text-secondary text-uppercase tracking-wider">
                  <i class="bi bi-cursor-text me-1 text-warning"></i>Localizar Marcadores para Substituir
                </span>
                <div class="d-flex gap-1">
                  <button
                    type="button"
                    class="btn btn-xs btn-outline-primary rounded-pill px-2 py-1 small fw-bold"
                    @click="loadDefaultTemplate"
                    title="Carregar Modelo Padrão LGPD com todas as cláusulas"
                  >
                    <i class="bi bi-arrow-counterclockwise me-1"></i>Modelo Padrão LGPD
                  </button>
                  <button
                    type="button"
                    class="btn btn-xs btn-outline-danger rounded-pill px-2 py-1 small"
                    @click="clearText"
                    title="Limpar texto do editor"
                  >
                    <i class="bi bi-trash"></i>
                  </button>
                </div>
              </div>

              <!-- Botões dinâmicos gerados pelos marcadores encontrados no texto -->
              <div v-if="foundPlaceholders.length > 0" class="d-flex flex-wrap gap-2 section-jump-container">
                <button
                  v-for="ph in foundPlaceholders"
                  :key="ph.key"
                  type="button"
                  class="btn btn-xs rounded-pill placeholder-jump-btn d-flex align-items-center gap-1"
                  @click="jumpToPlaceholder(ph.key)"
                  :title="`Clique para ir até: ${ph.label} (${ph.count} ocorrência${ph.count > 1 ? 's' : ''})`"
                >
                  <i class="bi bi-arrow-right-circle-fill opacity-75"></i>
                  <span>{{ ph.label }}</span>
                  <span class="badge rounded-pill bg-warning text-dark" style="font-size:0.68rem;">{{ ph.count }}x</span>
                </button>
              </div>
              <div v-else class="small text-muted fst-italic">
                <i class="bi bi-check-circle-fill text-success me-1"></i>
                Nenhum marcador encontrado — texto já está personalizado!
              </div>
            </div>

            <!-- BARRA DE FORMATAÇÃO ESTILO GITHUB ISSUES -->
            <div class="github-toolbar p-2 rounded-top-3 border border-bottom-0 bg-body-tertiary d-flex flex-wrap gap-1 align-items-center">
              <!-- Headers -->
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('h2')" title="Título Principal (H2)">
                <strong>H2</strong>
              </button>
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('h3')" title="Subtítulo (H3)">
                <strong>H3</strong>
              </button>
              
              <div class="vr mx-1 my-auto" style="height: 18px;"></div>

              <!-- Formatting -->
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('bold')" title="Negrito (**texto**)">
                <i class="bi bi-type-bold"></i>
              </button>
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('italic')" title="Itálico (*texto*)">
                <i class="bi bi-type-italic"></i>
              </button>

              <div class="vr mx-1 my-auto" style="height: 18px;"></div>

              <!-- Lists -->
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('ul')" title="Lista com Marcadores (•)">
                <i class="bi bi-list-ul"></i>
              </button>
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('ol')" title="Lista Numerada (1.)">
                <i class="bi bi-list-ol"></i>
              </button>
              
              <div class="vr mx-1 my-auto" style="height: 18px;"></div>

              <!-- Elements -->
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('quote')" title="Citação / Destaque (>)">
                <i class="bi bi-quote"></i>
              </button>
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('link')" title="Inserir Link ([Texto](url))">
                <i class="bi bi-link-45deg"></i>
              </button>
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('table')" title="Inserir Tabela">
                <i class="bi bi-table"></i>
              </button>
              <button type="button" class="btn btn-sm btn-ghost-editor" @click="applyFormatting('hr')" title="Linha Divisória (---)">
                <i class="bi bi-hr"></i>
              </button>
            </div>

            <!-- Textarea Editor -->
            <div class="flex-grow-1 position-relative d-flex flex-column">
              <textarea
                ref="editorTextarea"
                v-model="currentContent"
                class="flex-grow-1 rounded-bottom-3 p-3 font-monospace legal-editor-textarea"
                rows="14"
                placeholder="Escreva ou edite a página legal aqui..."
                style="resize: none; font-size: 0.88rem; line-height: 1.65; width: 100%; background-color: var(--bs-tertiary-bg, #f1f3f5) !important; color: var(--bs-body-color) !important; border: 1px solid var(--bs-border-color) !important; outline: none;"
              ></textarea>
              
              <div class="d-flex justify-content-between align-items-center mt-2 px-1 text-muted small" style="font-size: 0.75rem;">
                <span>
                  <i class="bi bi-shield-check text-success me-1"></i>Formatado com Markdown & HTML seguro
                </span>
                <span>{{ currentContent.length }} caracteres</span>
              </div>
            </div>
          </div>

          <!-- LADO DIREITO: LIVE PREVIEW -->
          <div
            v-show="viewMode === 'split' || viewMode === 'preview'"
            class="preview-pane p-3 p-md-4 overflow-auto bg-body-tertiary flex-fill"
            :class="{ 'w-lg-50': viewMode === 'split', 'w-100': viewMode === 'preview' }"
          >
            <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-3">
              <span class="fw-bold small text-secondary text-uppercase tracking-wider">
                <i class="bi bi-eye-fill me-1 text-primary"></i>Pré-visualização no Site do Cliente
              </span>
              <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 rounded-pill px-3 py-1">
                <i class="bi bi-check-circle-fill me-1"></i>Formatação LGPD Ativa
              </span>
            </div>

            <!-- Card de Simulação da Página Pública -->
            <div class="preview-card bg-body border rounded-4 p-4 p-md-5 shadow-sm">
              <div class="legal-header mb-4">
                <h1 class="fw-800 text-body mb-2">{{ activePageTitle }}</h1>
                <p class="text-muted small mb-0">
                  Última atualização: {{ currentDateString }}
                </p>
              </div>

              <!-- Renderização com Sanidade e Destaque de Marcadores -->
              <div class="legal-body" v-html="renderedPreviewContent"></div>

              <div class="mt-5 pt-4 border-top text-center text-muted small" style="font-size: 0.8rem;">
                © {{ new Date().getFullYear() }} {{ establishmentName || '[ NOME DO SEU ESTABELECIMENTO ]' }} - Todos os direitos reservados.
              </div>
            </div>
          </div>

        </div>

        <!-- Footer -->
        <div class="modal-footer border-top px-4 py-3 bg-body-tertiary d-flex align-items-center justify-content-between">
          <div class="small text-muted d-none d-md-block">
            <i class="bi bi-info-circle me-1 text-primary"></i>
            Personalize as cláusulas conforme as regras do seu estabelecimento.
          </div>

          <div class="d-flex align-items-center gap-2 ms-auto">
            <button
              type="button"
              class="btn btn-light rounded-pill px-4 fw-bold border shadow-sm"
              @click="closeModal"
            >
              Cancelar
            </button>
            <button
              type="button"
              class="btn btn-primary rounded-pill px-4 fw-bold shadow-sm"
              @click="saveChanges"
            >
              <i class="bi bi-check-lg me-1"></i>Salvar Páginas Legais
            </button>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick, onUnmounted } from 'vue'
import DOMPurify from 'dompurify'

const props = defineProps({
  show: { type: Boolean, default: false },
  initialPage: { type: String, default: 'privacy_policy' },
  legalPages: { type: Object, default: () => ({}) },
  establishmentName: { type: String, default: '' },
  establishmentEmail: { type: String, default: '' },
  establishmentPhone: { type: String, default: '' }
})

const emit = defineEmits(['update:legalPages', 'close', 'save'])

const currentPageKey = ref(props.initialPage)

// Bloqueia o scroll do body quando o modal está aberto
function lockBodyScroll() {
  const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth
  document.body.style.overflow = 'hidden'
  document.body.style.paddingRight = scrollbarWidth + 'px'
}

function unlockBodyScroll() {
  document.body.style.overflow = ''
  document.body.style.paddingRight = ''
}

// Garante limpeza se o componente for desmontado com modal aberto
onUnmounted(() => unlockBodyScroll())
const viewMode = ref<'split' | 'editor' | 'preview'>('split')
const editorTextarea = ref<HTMLTextAreaElement | null>(null)

// Local copy of all legal pages
const pagesData = ref<Record<string, string>>({
  privacy_policy: '',
  terms_of_use: '',
  cookie_policy: '',
  about_us: '',
  faq: '',
  contact_info: ''
})

const pageTitles: Record<string, string> = {
  privacy_policy: 'Política de Privacidade',
  terms_of_use: 'Termos de Uso',
  cookie_policy: 'Política de Cookies',
  about_us: 'Quem Somos',
  faq: 'Perguntas Frequentes',
  contact_info: 'Informações de Contato'
}

const pageIcons: Record<string, string> = {
  privacy_policy: 'bi bi-shield-lock',
  terms_of_use: 'bi bi-file-earmark-text',
  cookie_policy: 'bi bi-cookie',
  about_us: 'bi bi-info-circle',
  faq: 'bi bi-question-circle',
  contact_info: 'bi bi-telephone'
}

// Definição dos marcadores conhecidos e seus labels amigáveis
const KNOWN_PLACEHOLDERS = [
  { key: 'NOME DO SEU ESTABELECIMENTO', label: '[ NOME DO ESTABELECIMENTO ]', pattern: /\[\s*NOME DO SEU ESTABELECIMENTO\s*\]/gi },
  { key: 'SEU ESTABELECIMENTO',         label: '[ SEU ESTABELECIMENTO ]',        pattern: /\[\s*SEU ESTABELECIMENTO\s*\]/gi },
  { key: 'EMAIL DO ESTABELECIMENTO',    label: '[ EMAIL DO ESTABELECIMENTO ]',   pattern: /\[\s*EMAIL DO ESTABELECIMENTO\s*\]/gi },
  { key: 'TELEFONE / CONTATO',          label: '[ TELEFONE / CONTATO ]',         pattern: /\[\s*TELEFONE \/ CONTATO\s*\]/gi },
  { key: 'CIDADE / UF',                 label: '[ CIDADE / UF ]',                pattern: /\[\s*CIDADE \/ UF\s*\]/gi },
  { key: 'DATA DE ATUALIZAÇÃO',         label: '[ DATA DE ATUALIZAÇÃO ]',        pattern: /\[\s*DATA DE ATUALIZAÇÃO\s*\]/gi },
]

// Rastreia qual ocorrência (índice) de cada placeholder foi visitada por último
const placeholderCursors = ref<Record<string, number>>({})

// Computed: escaneia o texto atual e retorna apenas os marcadores presentes com contagem
const foundPlaceholders = computed(() => {
  const text = currentContent.value || ''
  const result: Array<{ key: string; label: string; count: number }> = []

  for (const ph of KNOWN_PLACEHOLDERS) {
    const matches = [...text.matchAll(ph.pattern)]
    if (matches.length > 0) {
      result.push({ key: ph.key, label: ph.label, count: matches.length })
    }
  }

  return result
})
const activePageTitle = computed(() => pageTitles[currentPageKey.value] || 'Página Legal')
const activePageIcon = computed(() => pageIcons[currentPageKey.value] || 'bi bi-file-earmark-text')

const currentDateString = computed(() => {
  const d = new Date()
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`
})

const currentContent = computed({
  get: () => pagesData.value[currentPageKey.value] || '',
  set: (val: string) => {
    pagesData.value[currentPageKey.value] = val
  }
})

watch(
  () => props.show,
  (isShown) => {
    if (isShown) {
      lockBodyScroll()
      currentPageKey.value = props.initialPage || 'privacy_policy'
      // Sempre carrega os modelos padrão LGPD ao abrir o modal
      // O dono substitui os marcadores pelo nome real do estabelecimento
      pagesData.value = {
        privacy_policy: defaultTemplates.privacy_policy || '',
        terms_of_use: defaultTemplates.terms_of_use || '',
        cookie_policy: defaultTemplates.cookie_policy || '',
        about_us: defaultTemplates.about_us || '',
        faq: defaultTemplates.faq || '',
        contact_info: defaultTemplates.contact_info || ''
      }
    } else {
      unlockBodyScroll()
    }
  },
  { immediate: true }
)

watch(
  () => props.initialPage,
  (newPage) => {
    if (newPage) currentPageKey.value = newPage
  }
)

// Pula para a próxima ocorrência do marcador no editor (cicla entre todas as ocorrências)
function jumpToPlaceholder(key: string) {
  const el = editorTextarea.value
  const text = currentContent.value || ''
  if (!el || !text) return

  const ph = KNOWN_PLACEHOLDERS.find(p => p.key === key)
  if (!ph) return

  // Coleta todas as posições de ocorrência
  const matches = [...text.matchAll(ph.pattern)]
  if (matches.length === 0) return

  // Avança o cursor (cicla entre ocorrências)
  const currentIdx = placeholderCursors.value[key] ?? 0
  const nextIdx = currentIdx % matches.length
  placeholderCursors.value[key] = nextIdx + 1

  const match = matches[nextIdx]
  if (!match) return
  const start = match.index ?? 0
  const end = start + (match[0]?.length ?? 0)

  el.focus()
  el.setSelectionRange(start, end)

  // Rola o textarea até a ocorrência
  const lineCount = text.substring(0, start).split('\n').length
  const lineHeight = 22
  el.scrollTop = Math.max(0, (lineCount - 3) * lineHeight)
}

// Formatação estilo GitHub Issues
function applyFormatting(type: string) {
  const el = editorTextarea.value
  if (!el) return

  const start = el.selectionStart
  const end = el.selectionEnd
  const selectedText = currentContent.value.substring(start, end)
  let replacement = ''

  switch (type) {
    case 'h2':
      replacement = `\n<h2>${selectedText || 'Novo Título'}</h2>\n`
      break
    case 'h3':
      replacement = `\n<h3>${selectedText || 'Subtítulo'}</h3>\n`
      break
    case 'bold':
      replacement = `**${selectedText || 'texto em negrito'}**`
      break
    case 'italic':
      replacement = `*${selectedText || 'texto em itálico'}*`
      break
    case 'ul':
      replacement = `\n• ${selectedText || 'Item da lista 1'}\n• Item da lista 2\n`
      break
    case 'ol':
      replacement = `\n1. ${selectedText || 'Primeiro item'}\n2. Segundo item\n`
      break
    case 'quote':
      replacement = `\n> ${selectedText || 'Citação ou nota de destaque'}\n`
      break
    case 'link':
      replacement = `[${selectedText || 'Texto do link'}](https://exemplo.com)`
      break
    case 'table':
      replacement = `\n| Item | Descrição |\n| --- | --- |\n| Exemplo 1 | Informação 1 |\n`
      break
    case 'hr':
      replacement = `\n---\n`
      break
  }

  currentContent.value =
    currentContent.value.substring(0, start) + replacement + currentContent.value.substring(end)

  nextTick(() => {
    el.focus()
  })
}

function clearText() {
  if (confirm('Deseja limpar todo o texto desta página legal?')) {
    currentContent.value = ''
  }
}

function loadDefaultTemplate() {
  const template = defaultTemplates[currentPageKey.value]
  if (template) {
    if (currentContent.value && !confirm('Isso irá substituir o conteúdo atual pelo modelo padrão LGPD. Deseja continuar?')) {
      return
    }
    currentContent.value = template
  }
}

function textToHtml(text: string): string {
  if (!text) return ''

  let html = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

  html = html.replace(/^(\d+\..+)$/gm, '<h2>$1</h2>')
  html = html.replace(/^###\s+(.+)$/gm, '<h3>$1</h3>')
  html = html.replace(/^##\s+(.+)$/gm, '<h2>$1</h2>')
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  html = html.replace(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/g, '<em>$1</em>')
  html = html.replace(/^(\s*)([•\-])\s+(.+)$/gm, '<li>$3</li>')
  html = html.replace(/(<li>.*<\/li>\n?)+/g, '<ul>$&</ul>')
  html = html.replace(/\n\n+/g, '</p><p>')
  html = '<p>' + html + '</p>'
  html = html.replace(/<p>\s*<\/p>/g, '')
  html = html.replace(/<p>\s*(<h2>|<h3>|<ul>)/g, '$1')
  html = html.replace(/(<\/h2>|<\/h3>|<\/ul>)\s*<\/p>/g, '$1')
  html = html.replace(/\n/g, '<br>')
  html = html.replace(/<br>\s*(<h2>|<h3>|<ul>|<\/ul>)/g, '$1')

  return html
}

const renderedPreviewContent = computed(() => {
  const raw = currentContent.value || ''
  if (!raw) return '<p class="text-muted italic">Nenhum conteúdo inserido ainda...</p>'

  let formatted = ''
  const isHtml = /<[a-z][\s\S]*>/i.test(raw)
  const baseHtml = isHtml ? raw : textToHtml(raw)

  formatted = DOMPurify.sanitize(baseHtml, {
    ALLOWED_TAGS: [
      'h1','h2','h3','h4','h5','h6','p','br','ul','ol','li','strong',
      'em','b','i','u','s','strike','a','span','div','blockquote',
      'table','thead','tbody','tr','th','td','hr','mark'
    ],
    ALLOWED_ATTR: ['href','title','class','target','rel'],
    ALLOW_DATA_ATTR: false
  })

  // Destaque visual para marcadores de lugar no preview
  formatted = formatted.replace(
    /\[\s*SEU ESTABELECIMENTO\s*\]|\[\s*NOME DO SEU ESTABELECIMENTO\s*\]/gi,
    `<span class="placeholder-highlight">[ NOME DO SEU ESTABELECIMENTO ]</span>`
  )
  formatted = formatted.replace(
    /\[\s*EMAIL DO ESTABELECIMENTO\s*\]/gi,
    `<span class="placeholder-highlight">[ EMAIL DO ESTABELECIMENTO ]</span>`
  )
  formatted = formatted.replace(
    /\[\s*TELEFONE \/ CONTATO\s*\]/gi,
    `<span class="placeholder-highlight">[ TELEFONE / CONTATO ]</span>`
  )
  formatted = formatted.replace(
    /\[\s*CIDADE \/ UF\s*\]/gi,
    `<span class="placeholder-highlight">[ CIDADE / UF ]</span>`
  )

  return formatted
})

function closeModal() {
  unlockBodyScroll()
  emit('close')
}

function saveChanges() {
  unlockBodyScroll()
  emit('update:legalPages', { ...pagesData.value })
  emit('save')
  emit('close')
}

const defaultTemplates: Record<string, string> = {
  privacy_policy: `<h2>1. Controlador dos Dados</h2>
<p>O controlador dos dados pessoais é o estabelecimento parceiro <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong> onde você realizou seu cadastro. A EasySloting atua como operadora de dados, processando informações em nome do estabelecimento.</p>

<h2>2. Dados Coletados</h2>
<p>Coletamos as seguintes informações durante o uso dos nossos serviços:</p>
<ul>
  <li><strong>Dados de cadastro:</strong> Nome, e-mail, telefone e celular</li>
  <li><strong>Dados de agendamento:</strong> Data, horário, serviço selecionado e profissional</li>
  <li><strong>Dados de navegação:</strong> Informações de acesso (IP, dispositivo, navegador) para fins de segurança</li>
  <li><strong>Feedbacks:</strong> Avaliações e comentários (sempre anônimos)</li>
</ul>

<h2>3. Finalidade do Tratamento</h2>
<p>Seus dados são utilizados para:</p>
<ul>
  <li>Processar e confirmar agendamentos no <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong></li>
  <li>Enviar notificações sobre seus atendimentos</li>
  <li>Gerenciar pacotes mensais e assinaturas</li>
  <li>Garantir a segurança da sua conta</li>
  <li>Melhorar a qualidade dos serviços</li>
  <li>Cumprir obrigações legais e fiscais</li>
</ul>

<h2>4. Base Legal</h2>
<p>O tratamento dos seus dados é realizado com base em:</p>
<ul>
  <li><strong>Execução de contrato:</strong> Prestação dos serviços de agendamento</li>
  <li><strong>Consentimento:</strong> Para comunicações de marketing (quando aplicável)</li>
  <li><strong>Legítimo interesse:</strong> Para segurança e melhoria dos serviços</li>
</ul>

<h2>5. Compartilhamento de Dados</h2>
<p>Não compartilhamos seus dados pessoais com terceiros para fins de marketing. Seus dados podem ser compartilhados apenas quando:</p>
<ul>
  <li>Necessário para cumprir obrigação legal ou regulatória</li>
  <li>Autorizado por você de forma expressa</li>
  <li>Necessário para a prestação do serviço contratado (ex: profissional do estabelecimento)</li>
  <li>Proteção dos direitos do estabelecimento ou da EasySloting</li>
</ul>

<h2>6. Segurança dos Dados</h2>
<p>Implementamos medidas de segurança técnicas e organizacionais robustas:</p>
<ul>
  <li>Criptografia de dados em trânsito (HTTPS/TLS)</li>
  <li>Senhas armazenadas com hash bcrypt (irrecuperáveis)</li>
  <li>Controle de acesso por autenticação JWT</li>
  <li>Registro de auditoria de todas as ações sensíveis</li>
  <li>Rate limiting para prevenir abusos</li>
</ul>

<h2>7. Retenção dos Dados</h2>
<p>Seus dados são mantidos pelo tempo necessário para cumprir as finalidades descritas nesta política, salvo quando houver obrigação legal de retenção superior.</p>

<h2>8. Seus Direitos (LGPD)</h2>
<p>Conforme a Lei Geral de Proteção de Dados, você tem direito a:</p>
<ul>
  <li><strong>Confirmação:</strong> Saber se tratamos seus dados</li>
  <li><strong>Acesso:</strong> Obter cópia dos seus dados</li>
  <li><strong>Correção:</strong> Corrigir dados incompletos ou desatualizados</li>
  <li><strong>Anonimização/Bloqueio/Exclusão:</strong> De dados desnecessários ou excessivos</li>
  <li><strong>Portabilidade:</strong> Solicitar transferência dos seus dados</li>
  <li><strong>Eliminação:</strong> Solicitar a exclusão dos dados tratados com consentimento</li>
  <li><strong>Revogação:</strong> Revogar o consentimento a qualquer momento</li>
  <li><strong>Oposição:</strong> Opor-se ao tratamento em certas hipóteses</li>
</ul>

<h2>9. Cookies</h2>
<p>Utilizamos cookies essenciais para o funcionamento do site. Para mais detalhes, consulte nossa Política de Cookies.</p>

<h2>10. Transferência Internacional</h2>
<p>Seus dados não são transferidos para fora do Brasil, salvo quando estritamente necessário e com as garantias legais exigidas pela LGPD.</p>

<h2>11. Menores de Idade</h2>
<p>Nossos serviços são destinados a maiores de 18 anos. Em caso de necessidade de tratamento de dados de menores, o consentimento deverá ser dado pelo responsável legal.</p>

<h2>12. Alterações nesta Política</h2>
<p>Esta Política de Privacidade pode ser atualizada periodicamente. Recomendamos que você consulte esta página regularmente.</p>

<h2>13. Canal de Comunicação</h2>
<p>Para exercer seus direitos ou esclarecer dúvidas sobre esta política, entre em contato diretamente com o <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong> pelo e-mail <strong>[ EMAIL DO ESTABELECIMENTO ]</strong> ou telefone <strong>[ TELEFONE / CONTATO ]</strong>.</p>

<p><em>Última atualização: [ DATA DE ATUALIZAÇÃO ]</em></p>
<p><em>Política gerenciada pela plataforma EasySloting em conformidade com a LGPD.</em></p>`,

  terms_of_use: `<h2>1. Definições</h2>
<ul>
  <li><strong>Plataforma:</strong> Sistema EasySloting de agendamento online</li>
  <li><strong>Estabelecimento:</strong> <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong></li>
  <li><strong>Cliente:</strong> Usuário que realiza cadastro e agendamentos</li>
  <li><strong>Serviço:</strong> Atendimento oferecido pelo <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong></li>
</ul>

<h2>2. Cadastro</h2>
<ul>
  <li>Para utilizar a plataforma, é necessário criar uma conta com informações verdadeiras e atualizadas</li>
  <li>O cliente é responsável por manter a confidencialidade de sua senha</li>
  <li>É proibido o cadastro com dados falsos ou de terceiros</li>
  <li>O <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong> pode recusar ou cancelar cadastros que violem estes termos</li>
</ul>

<h2>3. Agendamentos</h2>
<ul>
  <li>Agendamentos estão sujeitos à disponibilidade de horários e profissionais</li>
  <li>A confirmação do agendamento é enviada por e-mail após a conclusão</li>
  <li>O cliente deve chegar no horário agendado. Atrasos superiores a 15 minutos podem resultar no cancelamento</li>
  <li>Em caso de não comparecimento (no-show), o <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong> poderá aplicar restrições futuras</li>
</ul>

<h2>4. Cancelamentos e Reagendamentos</h2>
<ul>
  <li>O cliente pode cancelar ou reagendar pela plataforma</li>
  <li>Cancelamentos devem ser feitos com antecedência mínima de 2 horas</li>
</ul>

<h2>5. Pagamentos</h2>
<ul>
  <li>Os preços são definidos pelo <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong> e podem ser alterados sem aviso prévio</li>
  <li>O pagamento é realizado diretamente no estabelecimento na data do atendimento</li>
</ul>

<h2>6. Legislação Aplicável</h2>
<p>Estes termos são regidos pelas leis do Brasil. Fica eleito o foro da comarca de <strong>[ CIDADE / UF ]</strong> para dirimir quaisquer questões.</p>

<p><em>Última atualização: [ DATA DE ATUALIZAÇÃO ]</em></p>`,

  cookie_policy: `<h2>1. O que são Cookies?</h2>
<p>Cookies são pequenos arquivos de texto armazenados no seu dispositivo ao navegar no site do <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong>.</p>

<h2>2. Cookies que Utilizamos</h2>
<ul>
  <li><strong>Cookies Essenciais:</strong> Necessários para login, navegação e segurança da sua conta</li>
  <li><strong>Cookies de Preferências:</strong> Armazenam suas escolhas (ex: tema claro ou escuro)</li>
</ul>

<h2>3. Como Gerenciar Cookies</h2>
<p>Você pode desativar os cookies no seu navegador a qualquer momento.</p>

<p><em>Última atualização: [ DATA DE ATUALIZAÇÃO ]</em></p>`,

  about_us: `<h2>Sobre o [ NOME DO SEU ESTABELECIMENTO ]</h2>
<p>Bem-vindo ao <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong>! Somos dedicados a oferecer os melhores serviços com excelência e conforto.</p>

<h2>Nossa Missão</h2>
<p>Proporcionar um atendimento de altíssima qualidade com agilidade no agendamento e transparência.</p>

<h2>Entre em Contato</h2>
<p>Fale conosco pelo e-mail <strong>[ EMAIL DO ESTABELECIMENTO ]</strong> ou telefone <strong>[ TELEFONE / CONTATO ]</strong>.</p>`,

  faq: `<h2>Perguntas Frequentes - [ NOME DO SEU ESTABELECIMENTO ]</h2>

<h2>1. Como realizo um agendamento?</h2>
<p>Basta escolher o serviço, o profissional desejado, selecionar o melhor dia e horário disponível e confirmar o agendamento.</p>

<h2>2. Posso cancelar meu agendamento?</h2>
<p>Sim! Você pode cancelar ou reagendar diretamente pelo painel do cliente com até 2 horas de antecedência.</p>

<h2>3. Quais são as formas de pagamento?</h2>
<p>O pagamento é feito diretamente no <strong>[ NOME DO SEU ESTABELECIMENTO ]</strong> no momento do atendimento.</p>`,

  contact_info: `<h2>Canais de Atendimento - [ NOME DO SEU ESTABELECIMENTO ]</h2>
<ul>
  <li><strong>Empresa:</strong> [ NOME DO SEU ESTABELECIMENTO ]</li>
  <li><strong>E-mail:</strong> [ EMAIL DO ESTABELECIMENTO ]</li>
  <li><strong>Telefone / WhatsApp:</strong> [ TELEFONE / CONTATO ]</li>
  <li><strong>Localização:</strong> [ CIDADE / UF ]</li>
</ul>`
}
</script>

<style scoped>
.legal-editor-modal-backdrop {
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(5px);
  z-index: 1065;
}

.modal-ultrawide {
  max-width: 96vw !important;
  width: 96vw !important;
  margin: 1.5vh auto !important;
}

.modal-content {
  height: 94vh !important;
}

/* Banner de Explicação */
.explanation-box {
  background-color: rgba(13, 110, 253, 0.06);
  border: 1px solid rgba(13, 110, 253, 0.2);
}

/* Atalhos de Seções (Section Jump Buttons) */
.section-jump-container {
  max-height: 90px;
  overflow-y: auto;
}

.placeholder-jump-btn {
  font-size: 0.73rem;
  font-weight: 700;
  background-color: rgba(234, 179, 8, 0.1);
  color: #92400e;
  border: 1px solid rgba(234, 179, 8, 0.4);
  transition: all 0.2s ease;
}

.placeholder-jump-btn:hover {
  background-color: rgba(234, 179, 8, 0.25);
  border-color: #ca8a04 !important;
  color: #78350f;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(234, 179, 8, 0.3);
}

/* GitHub Style Toolbar */
.github-toolbar {
  font-size: 0.85rem;
}

.btn-ghost-editor {
  padding: 3px 8px;
  border-radius: 6px;
  color: var(--bs-body-color);
  transition: background-color 0.15s ease;
}

.btn-ghost-editor:hover {
  background-color: rgba(13, 110, 253, 0.15);
  color: var(--bs-primary);
}

.main-editor-textarea {
  background-color: var(--bs-body);
  color: var(--bs-body-color);
  border-color: rgba(0, 0, 0, 0.15);
}

.editor-pane,
.preview-pane {
  min-height: 500px;
}

.preview-card {
  max-width: 1000px;
  margin: 0 auto;
}

/* Select de páginas — fundo neutro igual ao modal */
.form-select-page {
  background-color: var(--bs-tertiary-bg) !important;
  color: var(--bs-body-color) !important;
  border-color: var(--bs-border-color) !important;
}

/* Textarea — fundo neutro cinza igual ao modal, sem o azul padrão do Bootstrap */
.main-editor-textarea {
  background-color: var(--bs-tertiary-bg) !important;
  color: var(--bs-body-color) !important;
  border-color: var(--bs-border-color) !important;
}

.main-editor-textarea:focus {
  background-color: var(--bs-secondary-bg) !important;
  color: var(--bs-body-color) !important;
  border-color: var(--bs-primary) !important;
  box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.15) !important;
}

/* Modo Escuro (Dark Mode High Contrast Fixes) */
[data-bs-theme="dark"] .mode-switch-group {
  background-color: rgba(255, 255, 255, 0.06) !important;
  border: 1px solid rgba(255, 255, 255, 0.15) !important;
}

[data-bs-theme="dark"] .mode-switch-btn {
  color: rgba(255, 255, 255, 0.7) !important;
  background-color: transparent !important;
}

[data-bs-theme="dark"] .mode-switch-btn.active {
  background-color: #0d6efd !important;
  color: #ffffff !important;
  box-shadow: 0 2px 8px rgba(13, 110, 253, 0.4) !important;
}

[data-bs-theme="dark"] .form-select-page {
  background-color: rgba(255, 255, 255, 0.08) !important;
  color: #f8f9fa !important;
  border-color: rgba(255, 255, 255, 0.2) !important;
}

[data-bs-theme="dark"] .placeholder-jump-btn {
  background-color: rgba(234, 179, 8, 0.12) !important;
  color: #fde68a !important;
  border-color: rgba(234, 179, 8, 0.3) !important;
}

[data-bs-theme="dark"] .placeholder-jump-btn:hover {
  background-color: rgba(234, 179, 8, 0.25) !important;
  color: #fbbf24 !important;
  border-color: #d97706 !important;
}

[data-bs-theme="dark"] .explanation-box {
  background-color: rgba(13, 110, 253, 0.12) !important;
  border-color: rgba(13, 110, 253, 0.3) !important;
}

[data-bs-theme="dark"] .main-editor-textarea {
  background-color: #1e293b !important;
  color: #f1f5f9 !important;
  border-color: rgba(255, 255, 255, 0.15) !important;
}

@media (max-width: 991px) {
  .modal-ultrawide {
    max-width: 98vw !important;
    width: 98vw !important;
    margin: 10px auto !important;
  }

  .modal-content {
    height: auto !important;
  }
}
</style>

<style>
/* CSS Global para Renderização da Pré-visualização com Espaçamentos Flush (Pixel Perfect) */
.legal-body h2 {
  font-size: 1.25rem;
  font-weight: 800;
  color: var(--bs-primary, #0d6efd);
  margin-top: 2rem;
  margin-bottom: 0.85rem;
  padding-bottom: 0.4rem;
  border-bottom: 2px solid var(--bs-primary, #0d6efd);
}

.legal-body h3 {
  font-size: 1.05rem;
  font-weight: 700;
  color: var(--bs-body-color);
  margin-top: 1.35rem;
  margin-bottom: 0.5rem;
}

.legal-body p {
  margin-bottom: 1.1rem;
  color: var(--bs-secondary-color, #6c757d);
  line-height: 1.75;
  font-size: 0.95rem;
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
  color: var(--bs-secondary-color, #6c757d);
  line-height: 1.65;
  font-size: 0.93rem;
}

.legal-body li strong {
  color: var(--bs-body-color);
}

.legal-body strong {
  font-weight: 700;
  color: var(--bs-body-color);
}

.legal-body a {
  color: var(--bs-primary, #0d6efd);
  text-decoration: none;
  font-weight: 600;
}

.legal-body a:hover {
  text-decoration: underline;
}

.legal-body em {
  font-style: italic;
  opacity: 0.85;
}

.legal-body .placeholder-highlight {
  background: #fef08a !important;
  color: #854d0e !important;
  border: 1px dashed #ca8a04 !important;
  border-radius: 6px !important;
  padding: 2px 6px !important;
  font-family: monospace !important;
  font-size: 0.85rem !important;
  font-weight: 700 !important;
  display: inline-block !important;
}

[data-bs-theme="dark"] .legal-body .placeholder-highlight {
  background: #713f12 !important;
  color: #fef08a !important;
  border-color: #eab308 !important;
}

/* Textarea do editor legal — substitui form-control com bg neutro */
textarea.legal-editor-textarea {
  display: block;
  background-color: var(--bs-tertiary-bg, #f1f3f5) !important;
  color: var(--bs-body-color) !important;
  border: 1px solid var(--bs-border-color, #dee2e6) !important;
  border-radius: 0 0 0.5rem 0.5rem !important;
  box-shadow: none !important;
  transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
}

textarea.legal-editor-textarea:focus {
  background-color: var(--bs-secondary-bg, #e9ecef) !important;
  color: var(--bs-body-color) !important;
  border-color: #86b7fe !important;
  box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.18) !important;
  outline: 0 !important;
}

/* Dark mode: textarea */
[data-bs-theme="dark"] textarea.legal-editor-textarea {
  background-color: #1e293b !important;
  color: #f1f5f9 !important;
  border-color: rgba(255, 255, 255, 0.15) !important;
}

[data-bs-theme="dark"] textarea.legal-editor-textarea:focus {
  background-color: #1a2234 !important;
  border-color: #3b82f6 !important;
  box-shadow: 0 0 0 0.2rem rgba(59, 130, 246, 0.25) !important;
}

/* Dark mode: select do modal */
[data-bs-theme="dark"] .modal .form-select.rounded-pill {
  background-color: rgba(255, 255, 255, 0.08) !important;
  color: #f8f9fa !important;
  border-color: rgba(255, 255, 255, 0.2) !important;
}
</style>
