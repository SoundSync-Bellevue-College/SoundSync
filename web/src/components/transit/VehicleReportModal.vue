<template>
  <Teleport to="body">
    <div class="modal-backdrop" @click.self="$emit('close')">
      <div class="modal" role="dialog" aria-modal="true">

        <!-- Header -->
        <div class="modal-header">
          <div>
            <h2 class="modal-title">Report Vehicle</h2>
            <p class="modal-sub">
              Vehicle #{{ vehicle.vehicleId }}
              <template v-if="vehicle.routeId">
                <span class="dot">·</span> Route {{ routeShortName ?? vehicle.routeId }}
              </template>
            </p>
          </div>
          <button class="btn-close" @click="$emit('close')" aria-label="Close">✕</button>
        </div>

        <!-- Not signed in -->
        <div v-if="!authStore.isLoggedIn" class="not-signed-in">
          <p>You must be signed in to submit a report.</p>
          <button class="btn-primary" @click="$emit('close')">Close</button>
        </div>

        <!-- Report form -->
        <template v-else>
          <!-- Type tabs -->
          <div class="type-tabs">
            <button
              v-for="t in reportTypes"
              :key="t.key"
              class="type-tab"
              :class="{ active: activeType === t.key }"
              @click="activeType = t.key; selectedLevel = 0"
            >
              <span class="tab-icon">{{ t.icon }}</span>
              {{ t.label }}
            </button>
          </div>

          <!-- Level selector -->
          <div class="level-section">
            <p class="level-question">{{ currentType.question }}</p>
            <div class="level-row">
              <button
                v-for="n in 5"
                :key="n"
                class="level-btn"
                :class="{ selected: selectedLevel === n }"
                @click="selectedLevel = n"
              >{{ n }}</button>
            </div>
            <div class="level-labels">
              <span>{{ currentType.labelLow }}</span>
              <span>{{ currentType.labelHigh }}</span>
            </div>
          </div>

          <!-- Success message -->
          <p v-if="submitted" class="success-msg">✓ Report submitted! Thank you.</p>
          <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>

          <!-- Actions -->
          <div class="modal-actions">
            <button class="btn-secondary" @click="$emit('close')">Cancel</button>
            <button
              class="btn-primary"
              :disabled="selectedLevel === 0 || submitting"
              @click="submit"
            >
              <span v-if="submitting">Submitting…</span>
              <span v-else>Submit Report</span>
            </button>
          </div>
        </template>

      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/authStore'
import api from '@/services/api'
import type { VehiclePosition } from '@/types/transit'
import { getRouteLookup } from '@/services/routeLookup'

const props = defineProps<{ vehicle: VehiclePosition }>()
defineEmits<{ close: [] }>()

const routeShortName = ref<string | null>(null)
onMounted(async () => {
  const lookup = await getRouteLookup()
  routeShortName.value = lookup.get(props.vehicle.routeId)?.shortName ?? null
})

const authStore = useAuthStore()

// ── Report type config ────────────────────────────────────────────────────────

type ReportTypeKey = 'cleanliness' | 'crowding' | 'delay'

const reportTypes: Array<{
  key: ReportTypeKey
  icon: string
  label: string
  question: string
  labelLow: string
  labelHigh: string
}> = [
  {
    key: 'cleanliness',
    icon: '🧹',
    label: 'Cleanliness',
    question: 'How clean is this vehicle?',
    labelLow: '1 — Very dirty',
    labelHigh: '5 — Very clean',
  },
  {
    key: 'crowding',
    icon: '👥',
    label: 'Crowding',
    question: 'How crowded is this vehicle?',
    labelLow: '1 — Empty',
    labelHigh: '5 — Packed',
  },
  {
    key: 'delay',
    icon: '⏱️',
    label: 'Delay',
    question: 'How delayed is this vehicle?',
    labelLow: '1 — On time',
    labelHigh: '5 — Very delayed',
  },
]

const activeType = ref<ReportTypeKey>('cleanliness')
const selectedLevel = ref(0)
const submitting = ref(false)
const submitted = ref(false)
const errorMsg = ref('')

const currentType = computed(() => reportTypes.find(t => t.key === activeType.value)!)

async function submit() {
  if (selectedLevel.value === 0) return
  submitting.value = true
  errorMsg.value = ''
  submitted.value = false

  try {
    await api.post(
      `/transit/vehicles/${props.vehicle.vehicleId}/report/${activeType.value}`,
      { routeId: props.vehicle.routeId ?? '', level: selectedLevel.value },
    )
    submitted.value = true
    selectedLevel.value = 0
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : 'Failed to submit report. Please try again.'
  } finally {
    submitting.value = false
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
  z-index: 1100;
  padding: 1rem;
}

.modal {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  width: 100%;
  max-width: 400px;
  display: flex;
  flex-direction: column;
  gap: 0;
  overflow: hidden;
}

/* ── Header ── */
.modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 1.1rem 1.25rem 0.9rem;
  border-bottom: 1px solid var(--color-border);
}

.modal-title {
  font-size: 1rem;
  font-weight: 700;
  color: var(--color-text);
  margin: 0 0 0.15rem;
}

.modal-sub {
  font-size: 0.78rem;
  color: var(--color-text-muted);
  margin: 0;
}

.dot { margin: 0 0.3rem; opacity: 0.4; }

.btn-close {
  background: none;
  border: none;
  font-size: 0.95rem;
  color: var(--color-text-muted);
  cursor: pointer;
  padding: 0.1rem 0.3rem;
  transition: color 0.15s;
}
.btn-close:hover { color: var(--color-text); }

/* ── Not signed in ── */
.not-signed-in {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 2rem 1.25rem;
  text-align: center;
  color: var(--color-text-muted);
  font-size: 0.88rem;
}

/* ── Type tabs ── */
.type-tabs {
  display: flex;
  border-bottom: 1px solid var(--color-border);
}

.type-tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.2rem;
  padding: 0.65rem 0.25rem;
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--color-text-muted);
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  cursor: pointer;
  transition: color 0.15s, border-color 0.15s;
}

.type-tab.active {
  color: var(--color-primary);
  border-bottom-color: var(--color-primary);
}

.tab-icon { font-size: 1.15rem; }

/* ── Level selector ── */
.level-section {
  padding: 1.2rem 1.25rem 0.75rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.level-question {
  font-size: 0.88rem;
  font-weight: 500;
  color: var(--color-text);
  margin: 0;
}

.level-row {
  display: flex;
  gap: 0.5rem;
}

.level-btn {
  flex: 1;
  aspect-ratio: 1;
  background: var(--color-bg);
  border: 2px solid var(--color-border);
  border-radius: var(--radius-md);
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: background 0.12s, border-color 0.12s, color 0.12s;
}

.level-btn:hover {
  border-color: var(--color-primary);
  color: var(--color-primary);
}

.level-btn.selected {
  background: var(--color-primary);
  border-color: var(--color-primary);
  color: #fff;
}

.level-labels {
  display: flex;
  justify-content: space-between;
  font-size: 0.68rem;
  color: var(--color-text-muted);
}

/* ── Messages ── */
.success-msg {
  margin: 0 1.25rem;
  padding: 0.5rem 0.75rem;
  background: rgba(34, 197, 94, 0.12);
  border: 1px solid var(--color-success);
  border-radius: var(--radius-sm);
  font-size: 0.8rem;
  color: var(--color-success);
}

.error-msg {
  margin: 0 1.25rem;
  font-size: 0.8rem;
  color: var(--color-danger);
}

/* ── Actions ── */
.modal-actions {
  display: flex;
  gap: 0.6rem;
  padding: 0.85rem 1.25rem 1.1rem;
  justify-content: flex-end;
}

.btn-primary {
  background: var(--color-primary);
  color: #fff;
  padding: 0.5rem 1.1rem;
  border-radius: var(--radius-sm);
  font-size: 0.875rem;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}
.btn-primary:hover:not(:disabled) { background: var(--color-primary-hover); }
.btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }

.btn-secondary {
  background: transparent;
  color: var(--color-text-muted);
  padding: 0.5rem 0.9rem;
  border-radius: var(--radius-sm);
  font-size: 0.875rem;
  border: 1px solid var(--color-border);
  cursor: pointer;
  transition: color 0.15s;
}
.btn-secondary:hover { color: var(--color-text); }
</style>
