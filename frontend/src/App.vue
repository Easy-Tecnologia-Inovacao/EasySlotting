<script setup lang="ts">
import { RouterView } from 'vue-router'
import { useThemeStore } from '@/stores/themeStore'

// Conecta o App principal ao banco de dados global (Pinia)
const store = useThemeStore()
</script>

<template>
  <div id="app-wrapper" 
       class="bg-body text-body min-vh-100"
       :style="{ 
         '--logo-color': store.themeConfig.logoColor,
         '--button-bg': store.themeConfig.buttonBg,
         '--button-hover': store.themeConfig.buttonHover,
         '--icon-color': store.themeConfig.iconColor,
         '--custom-font': store.themeConfig.fontFamily,
         '--bs-body-bg': store.isDarkMode ? store.themeConfig.backgroundDark : store.themeConfig.backgroundLight,
         '--custom-text-color': store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight,
         '--glass-bg': store.isDarkMode ? store.themeConfig.navbarDark : store.themeConfig.navbarLight,
         '--bs-tertiary-bg': store.isDarkMode ? store.themeConfig.cardDark : store.themeConfig.cardLight
       }"
       :data-bs-theme="store.isDarkMode ? 'dark' : 'light'">
    
    <RouterView />
    
  </div>
</template>

<style>
/* Estilos globais */
body {
  margin: 0;
  padding: 0;
  /* A fonte agora é dinâmica e pega em todo o site */
  font-family: var(--custom-font) !important;
  transition: background 0.4s, color 0.4s; 
}

/* Desabilita autocomplete e autofill do navegador em todos os campos */
input, select, textarea {
  autocomplete: none !important;
  -webkit-autofill: none !important;
  -moz-autofill: none !important;
  -ms-autofill: none !important;
}

/* Campo fantasma para bloquear gerenciador de senhas do Chrome/Brave */
input:-webkit-autofill {
  -webkit-box-shadow: 0 0 0 30px white inset !important;
  -webkit-text-fill-color: inherit !important;
  transition: background-color 5000s ease-in-out 0s;
}

input[type="text"],
input[type="email"],
input[type="search"],
input:not([type]) {
  autocomplete: new-password !important;
}

/* Força o navegador a ignorar campos de pesquisa */
[data-lpignore="true"],
[data-1p-ignore="true"],
[data-bwignore="true"] {
  autocomplete: new-password !important;
}

/* ==============================================
   CLASSES GLOBAIS DE CUSTOMIZAÇÃO (White Label)
   Use essas classes em qualquer página do site!
   ============================================== */
.custom-logo { color: var(--logo-color) !important; transition: color 0.3s; }
.custom-icon { color: var(--icon-color) !important; transition: color 0.3s; }
.btn-nav-custom { color: var(--icon-color) !important; transition: color 0.3s; }
.dynamic-text { color: var(--custom-text-color) !important; transition: color 0.3s; }

/* Botões Principais */
.custom-btn {
    background-color: var(--button-bg) !important;
    border-color: var(--button-bg) !important;
    color: white !important;
    transition: background-color 0.3s, border-color 0.3s;
}
.custom-btn:hover {
    background-color: var(--button-hover) !important;
    border-color: var(--button-hover) !important;
}

/* Botões com Borda (Ex: Criar Conta) */
.custom-outline-btn {
    color: var(--button-bg) !important;
    border-color: var(--button-bg) !important;
    background-color: transparent !important;
    transition: background-color 0.3s, color 0.3s;
}
.custom-outline-btn:hover {
    background-color: var(--button-hover) !important;
    border-color: var(--button-hover) !important;
    color: #ffffff !important;
}

/* Botões de Ícones (Ex: Redes Sociais) */
.custom-icon-btn {
    color: var(--icon-color) !important;
    border-color: var(--icon-color) !important;
    transition: all 0.3s;
}
.custom-icon-btn:hover {
    background-color: var(--icon-color) !important;
    color: #fff !important;
}
</style>
