<template>
  <section class="hero-card mb-4">
    <div class="row align-items-center g-4">
      <div class="col-12 col-xl-8">
        <span class="eyebrow-badge mb-3">
          <i v-if="icon" class="bi me-1" :class="icon" aria-hidden="true"></i>
          {{ eyebrow }}
        </span>
        <h1 class="page-title mb-2">{{ title }}</h1>
        <p class="page-subtitle mb-0">{{ subtitle }}</p>
      </div>
      <div v-if="$slots.actions" class="col-12 col-xl-4 text-xl-end">
        <slot name="actions" />
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
defineProps<{ eyebrow: string; icon?: string; title: string; subtitle: string }>()
</script>

<style scoped>
.hero-card {
  background:
    radial-gradient(circle at top left, rgba(13, 110, 253, 0.18), transparent 35%),
    linear-gradient(135deg, rgba(13, 110, 253, 0.08), rgba(13, 110, 253, 0.02));
  border: 1px solid var(--bs-border-color-translucent);
  border-radius: 24px;
  padding: 2rem;
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.08);
}

.eyebrow-badge {
  display: inline-flex;
  align-items: center;
  padding: 0.45rem 0.9rem;
  border-radius: 999px;
  background: rgba(13, 110, 253, 0.12);
  color: var(--bs-primary);
  font-size: 0.8rem;
  font-weight: 700;
}

.page-title {
  font-size: clamp(1.9rem, 2vw, 2.7rem);
  font-weight: 800;
  letter-spacing: -0.02em;
}

.page-subtitle {
  color: var(--bs-secondary-color);
  max-width: 760px;
  font-size: 1rem;
}
</style>
