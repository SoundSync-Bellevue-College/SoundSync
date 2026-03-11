<template>
  <div class="spinner-wrapper" :class="{ overlay }">
    <div class="spinner" :style="{ width: size, height: size }" />
    <span v-if="label" class="spinner-label">{{ label }}</span>
  </div>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    size?: string
    label?: string
    overlay?: boolean
  }>(),
  { size: '32px', overlay: false },
)
</script>

<style scoped>
.spinner-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
}

.spinner-wrapper.overlay {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.6);
  z-index: 50;
}

.spinner {
  border: 3px solid var(--color-border);
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

.spinner-label {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
