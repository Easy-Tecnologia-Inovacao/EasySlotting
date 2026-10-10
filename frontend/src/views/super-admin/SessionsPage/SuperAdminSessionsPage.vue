<template>
  <SuperAdminLayout>
    <StaffSessionsPanel contained class="super-admin-sessions">
      <template #header="{ refresh, disabled }">
        <SuperAdminPageHeader
          eyebrow="Controle de acessos"
          icon="bi-laptop"
          title="Dispositivos conectados"
          subtitle="Acessos da sua conta. Encerre os que você não utiliza ou não reconhece."
        >
          <template #actions>
            <button class="btn btn-primary rounded-3 fw-semibold px-4 py-2 shadow-sm" :disabled="disabled" @click="refresh">
              Atualizar
            </button>
          </template>
        </SuperAdminPageHeader>
      </template>
    </StaffSessionsPanel>
  </SuperAdminLayout>
</template>
<script setup lang="ts">
import SuperAdminLayout from '@/views/super-admin/Layout/SuperAdminLayout.vue'
import StaffSessionsPanel from '@/components/StaffSessionsPanel.vue'
import SuperAdminPageHeader from '@/components/super-admin/SuperAdminPageHeader.vue'
</script>

<style scoped>
.super-admin-sessions :deep(.sessions-card) {
  background: var(--bs-body-bg);
  box-shadow: none !important;
}
</style>
