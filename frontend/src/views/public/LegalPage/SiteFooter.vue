<template>
  <footer class="site-footer mt-5 py-5" style="background: var(--glass-bg); backdrop-filter: blur(15px); border-top: 1px solid rgba(0,0,0,0.05);">
    <div class="container">
      <div class="row g-4">
        <!-- Info do estabelecimento -->
        <div class="col-lg-4 col-md-6">
          <router-link :to="`/empresa/${slug}`" class="fw-bold fs-4 text-decoration-none d-block mb-2" style="color: var(--button-bg);">
            {{ establishmentName || 'EasySloting' }}
          </router-link>
          <p class="mt-3 small opacity-75 dynamic-text" style="max-width: 300px;">
            {{ establishmentDescription || '' }}
          </p>
        </div>

        <!-- Links legais -->
        <div class="col-lg-4 col-md-6">
          <h6 class="fw-bold mb-4 dynamic-text">Links Úteis</h6>
          <ul class="list-unstyled d-grid gap-2">
            <li v-if="legalPages?.privacy_policy">
              <router-link :to="`/empresa/${slug}/privacy_policy`" class="small text-decoration-none dynamic-text" style="opacity: 0.8;">
                <i class="bi bi-shield-lock me-2"></i>Política de Privacidade
              </router-link>
            </li>
            <li v-if="legalPages?.terms_of_use">
              <router-link :to="`/empresa/${slug}/terms_of_use`" class="small text-decoration-none dynamic-text" style="opacity: 0.8;">
                <i class="bi bi-file-earmark-text me-2"></i>Termos de Uso
              </router-link>
            </li>
            <li v-if="legalPages?.cookie_policy">
              <router-link :to="`/empresa/${slug}/cookie_policy`" class="small text-decoration-none dynamic-text" style="opacity: 0.8;">
                <i class="bi bi-cookie me-2"></i>Política de Cookies
              </router-link>
            </li>
            <li v-if="legalPages?.about_us">
              <router-link :to="`/empresa/${slug}/about_us`" class="small text-decoration-none dynamic-text" style="opacity: 0.8;">
                <i class="bi bi-info-circle me-2"></i>Quem Somos
              </router-link>
            </li>
            <li v-if="legalPages?.faq">
              <router-link :to="`/empresa/${slug}/faq`" class="small text-decoration-none dynamic-text" style="opacity: 0.8;">
                <i class="bi bi-question-circle me-2"></i>Perguntas Frequentes
              </router-link>
            </li>
            <li v-if="legalPages?.contact_info">
              <router-link :to="`/empresa/${slug}/contact_info`" class="small text-decoration-none dynamic-text" style="opacity: 0.8;">
                <i class="bi bi-envelope me-2"></i>Contato
              </router-link>
            </li>
          </ul>
        </div>

        <!-- Redes sociais -->
        <div class="col-lg-4 col-md-12 text-lg-end">
          <h6 class="fw-bold mb-4 dynamic-text">Redes Sociais</h6>
          <div class="d-flex gap-3" :class="{ 'justify-content-lg-end': true }">
            <a v-if="instagram" :href="`https://instagram.com/${instagram}`" target="_blank" class="btn btn-outline-primary btn-sm rounded-circle" style="width: 38px; height: 38px; display: flex; align-items: center; justify-content: center;">
              <i class="bi bi-instagram"></i>
            </a>
            <a v-if="facebook" :href="facebook" target="_blank" class="btn btn-outline-primary btn-sm rounded-circle" style="width: 38px; height: 38px; display: flex; align-items: center; justify-content: center;">
              <i class="bi bi-facebook"></i>
            </a>
            <a v-if="whatsapp" :href="`https://wa.me/55${whatsapp.replace(/\D/g, '')}`" target="_blank" class="btn btn-outline-primary btn-sm rounded-circle" style="width: 38px; height: 38px; display: flex; align-items: center; justify-content: center;">
              <i class="bi bi-whatsapp"></i>
            </a>
          </div>
        </div>
      </div>

      <hr class="my-4 opacity-10">

      <p class="text-center small mb-0 dynamic-text" style="opacity: 0.7;">
        © {{ new Date().getFullYear() }} {{ establishmentName || 'EasySloting' }} - Todos os direitos reservados.
      </p>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useThemeStore } from '@/stores/themeStore'

const props = defineProps<{
  slug: string
  establishmentName?: string
  establishmentDescription?: string
  legalPages?: Record<string, string>
  instagram?: string
  facebook?: string
  whatsapp?: string
}>()

const store = useThemeStore()
</script>

<style scoped>
.dynamic-text {
  color: var(--custom-text-color, inherit) !important;
}
</style>
