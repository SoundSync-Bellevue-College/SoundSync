<template>
  <div class="auth-page">
    <div class="auth-card">
      <div class="auth-brand">
        <span class="brand-icon">🚌</span>
        <span class="brand-name">SoundSync</span>
      </div>

      <h1 class="auth-title">Sign In</h1>

      <form class="auth-form" @submit.prevent="submit">
        <div class="field">
          <label class="field-label">Email</label>
          <input v-model="form.email" class="field-input" type="email" required autocomplete="email" />
        </div>
        <div class="field">
          <label class="field-label">Password</label>
          <div class="input-wrap">
            <input
              v-model="form.password"
              class="field-input"
              :type="showPassword ? 'text' : 'password'"
              required
              autocomplete="current-password"
            />
            <button type="button" class="eye-btn" @click="showPassword = !showPassword" :aria-label="showPassword ? 'Hide password' : 'Show password'">
              <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
              </svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/>
              </svg>
            </button>
          </div>
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
const showPassword = ref(false)

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

.input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.field-input {
  width: 100%;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.65rem 2.25rem 0.65rem 0.75rem;
  color: var(--color-text);
  font-size: 0.9rem;
}

.field-input:focus {
  outline: none;
  border-color: var(--color-primary);
}

.eye-btn {
  position: absolute;
  right: 0.6rem;
  background: none;
  border: none;
  color: var(--color-text-muted);
  cursor: pointer;
  display: flex;
  align-items: center;
  padding: 0;
  transition: color 0.15s;
}

.eye-btn:hover {
  color: var(--color-text);
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

</style>
