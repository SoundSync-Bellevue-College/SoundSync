<template>
  <Teleport to="body">
    <div class="toast-container">
      <TransitionGroup name="toast">
        <div
          v-for="toast in toasts"
          :key="toast.id"
          class="toast"
          :class="toast.type"
          @click="remove(toast.id)"
        >
          <span class="toast-icon">{{ iconFor(toast.type) }}</span>
          <span class="toast-message">{{ toast.message }}</span>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref } from 'vue'

interface Toast {
  id: number
  type: 'success' | 'error' | 'info' | 'warning'
  message: string
}

const toasts = ref<Toast[]>([])
let nextId = 0

function iconFor(type: Toast['type']) {
  return { success: '✓', error: '✕', info: 'ℹ', warning: '⚠' }[type]
}

function add(type: Toast['type'], message: string, duration = 4000) {
  const id = nextId++
  toasts.value.push({ id, type, message })
  setTimeout(() => remove(id), duration)
}

function remove(id: number) {
  toasts.value = toasts.value.filter((t) => t.id !== id)
}

// Expose so parent components can trigger toasts
defineExpose({ add })
</script>

<style scoped>
.toast-container {
  position: fixed;
  bottom: 1.5rem;
  right: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  z-index: 9999;
}

.toast {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.75rem 1rem;
  border-radius: var(--radius-md);
  font-size: 0.875rem;
  cursor: pointer;
  min-width: 240px;
  max-width: 360px;
  box-shadow: var(--shadow-md);
}

.toast.success {
  background: #166534;
  color: #bbf7d0;
}
.toast.error {
  background: #7f1d1d;
  color: #fecaca;
}
.toast.info {
  background: #1e3a5f;
  color: #bfdbfe;
}
.toast.warning {
  background: #78350f;
  color: #fde68a;
}

.toast-enter-active,
.toast-leave-active {
  transition: all 0.25s ease;
}
.toast-enter-from {
  opacity: 0;
  transform: translateX(40px);
}
.toast-leave-to {
  opacity: 0;
  transform: translateX(40px);
}
</style>
