<template>
  <div class="auth-page">
    <div class="auth-card">
      <div class="auth-brand">
        <span class="brand-icon">🚌</span>
        <span class="brand-name">SoundSyncAI</span>
      </div>

      <h1 class="auth-title">Sign In</h1>

      <form class="auth-form" @submit.prevent="submit">
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

      <p class="auth-footer">
        No account?
        <RouterLink to="/register">Register here</RouterLink>
      </p>

      <p class="tony-signature">— Tony</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/authStore'

const auth = useAuthStore()
const router = useRouter()
const route = useRoute()
const form = reactive({ email: '', password: '' })
const loading = ref(false)
const error = ref('')

async function submit() {
  loading.value = true
  error.value = ''
  try {
    await auth.login(form)
    const redirect = (route.query.redirect as string) || '/'
    router.push(redirect)
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Login failed'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background: var(--color-bg);
}

.auth-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 2.5rem;
  width: 100%;
  max-width: 420px;
  box-shadow: var(--shadow-md);
}

.auth-brand {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
  font-weight: 700;
  font-size: 1.1rem;
}

.brand-icon {
  font-size: 1.4rem;
}

.auth-title {
  font-size: 1.4rem;
  font-weight: 700;
  margin-bottom: 1.5rem;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.field-label {
  font-size: 0.8rem;
  color: var(--color-text-muted);
}

.field-input {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.65rem 0.75rem;
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
  padding: 0.7rem;
  border-radius: var(--radius-sm);
  font-size: 0.9rem;
  font-weight: 500;
  transition: background 0.15s;
  margin-top: 0.25rem;
}

.btn-submit:hover:not(:disabled) {
  background: var(--color-primary-hover);
}

.btn-submit:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.auth-footer {
  text-align: center;
  margin-top: 1.25rem;
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.tony-signature {
  text-align: right;
  margin-top: 1rem;
  font-size: 0.8rem;
  font-style: italic;
  color: var(--color-text-muted);
}
</style>
