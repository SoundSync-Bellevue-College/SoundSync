<template>
  <div class="modal-backdrop" @click.self="$emit('close')">
    <div class="modal">
      <button class="modal-close" @click="$emit('close')">✕</button>
      <h2 class="modal-title">Sign In</h2>

      <form class="form" @submit.prevent="submit">
        <div class="field">
          <label class="field-label">Email</label>
          <input v-model="form.email" class="field-input" type="email" required autocomplete="email" />
        </div>
        <div class="field">
          <label class="field-label">Password</label>
          <input
            v-model="form.password"
            class="field-input"
            type="password"
            required
            autocomplete="current-password"
          />
        </div>

        <p v-if="error" class="error-msg">{{ error }}</p>

        <button class="btn-submit" type="submit" :disabled="loading">
          {{ loading ? 'Signing in…' : 'Sign In' }}
        </button>
      </form>

      <p class="modal-footer">
        No account?
        <button class="link-btn" @click="$emit('switch', 'register')">Register</button>
      </p>

      <p class="tony-signature">— Tony</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useAuthStore } from '@/stores/authStore'

defineEmits<{ close: []; switch: [mode: string] }>()

const auth = useAuthStore()
const form = reactive({ email: '', password: '' })
const loading = ref(false)
const error = ref('')

async function submit() {
  loading.value = true
  error.value = ''
  try {
    await auth.login(form)
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Login failed'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 2rem;
  width: 100%;
  max-width: 400px;
  position: relative;
  box-shadow: var(--shadow-md);
}

.modal-close {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: transparent;
  color: var(--color-text-muted);
  font-size: 1rem;
}

.modal-title {
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 1.5rem;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.field-label {
  font-size: 0.8rem;
  color: var(--color-text-muted);
}

.field-input {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.6rem 0.75rem;
  color: var(--color-text);
  font-size: 0.9rem;
}

.field-input:focus {
  border-color: var(--color-primary);
}

.error-msg {
  font-size: 0.8rem;
  color: var(--color-danger);
}

.btn-submit {
  background: var(--color-primary);
  color: #fff;
  padding: 0.65rem;
  border-radius: var(--radius-sm);
  font-size: 0.9rem;
  font-weight: 500;
  transition: background 0.15s;
}

.btn-submit:hover:not(:disabled) {
  background: var(--color-primary-hover);
}

.btn-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.modal-footer {
  text-align: center;
  margin-top: 1rem;
  font-size: 0.85rem;
  color: var(--color-text-muted);
}

.link-btn {
  background: transparent;
  color: var(--color-primary);
  font-size: 0.85rem;
}

.tony-signature {
  text-align: right;
  margin-top: 1rem;
  font-size: 0.8rem;
  font-style: italic;
  color: var(--color-text-muted);
}
</style>
