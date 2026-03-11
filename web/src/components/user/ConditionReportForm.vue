<template>
  <form class="report-form" @submit.prevent="submit">
    <h3 class="form-title">Report a Condition</h3>

    <div class="field">
      <label class="field-label">Type</label>
      <select v-model="form.type" class="field-select">
        <option value="delay">Delay</option>
        <option value="cleanliness">Cleanliness</option>
        <option value="crowding">Crowding</option>
        <option value="other">Other</option>
      </select>
    </div>

    <div class="field">
      <label class="field-label">Severity</label>
      <div class="radio-group">
        <label v-for="s in ['low', 'medium', 'high']" :key="s" class="radio-label">
          <input v-model="form.severity" type="radio" :value="s" />
          {{ s }}
        </label>
      </div>
    </div>

    <div class="field">
      <label class="field-label">Description (optional)</label>
      <textarea
        v-model="form.description"
        class="field-textarea"
        rows="3"
        placeholder="Details…"
      />
    </div>

    <p v-if="error" class="error-msg">{{ error }}</p>
    <p v-if="success" class="success-msg">Report submitted!</p>

    <button class="btn-submit" type="submit" :disabled="loading">
      {{ loading ? 'Submitting…' : 'Submit Report' }}
    </button>
  </form>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import api from '@/services/api'
import type { CreateReportPayload } from '@/types/transit'

const props = defineProps<{ routeId: string; vehicleId?: string }>()

const form = reactive<Omit<CreateReportPayload, 'routeId' | 'vehicleId'>>({
  type: 'delay',
  severity: 'medium',
  description: '',
})

const loading = ref(false)
const error = ref('')
const success = ref(false)

async function submit() {
  loading.value = true
  error.value = ''
  success.value = false
  try {
    const payload: CreateReportPayload = {
      routeId: props.routeId,
      vehicleId: props.vehicleId,
      ...form,
    }
    await api.post('/reports', payload)
    success.value = true
    form.description = ''
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'Failed to submit report'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.report-form {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.85rem;
}

.form-title {
  font-size: 0.95rem;
  font-weight: 600;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.field-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.field-select,
.field-textarea {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.5rem 0.75rem;
  color: var(--color-text);
  font-size: 0.875rem;
}

.radio-group {
  display: flex;
  gap: 1rem;
}

.radio-label {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.875rem;
  color: var(--color-text);
  cursor: pointer;
  text-transform: capitalize;
}

.error-msg {
  font-size: 0.8rem;
  color: var(--color-danger);
}

.success-msg {
  font-size: 0.8rem;
  color: var(--color-success);
}

.btn-submit {
  background: var(--color-primary);
  color: #fff;
  padding: 0.6rem;
  border-radius: var(--radius-sm);
  font-size: 0.875rem;
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
</style>
