<template>
  <div class="alert-wrapper" ref="warnWrapper">
    <button class="alert-btn" @click="toggleDropdown" aria-label="Service Alerts">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      >
        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3.05h16.94a2 2 0 0 0 1.71-3.05L13.71 3.86a2 2 0 0 0-3.42 0z" />
        <line x1="12" y1="9" x2="12" y2="13" />
        <line x1="12" y1="17" x2="12.01" y2="17" />
      </svg>
      <span v-if="serviceAlerts.count > 0" class="badge">
        {{ serviceAlerts.count > 9 ? '9+' : serviceAlerts.count }}
      </span>
    </button>

    <!-- Dropdown -->
    <div v-if="dropdownOpen" class="alert-dropdown">
      <div class="alert-header">
        <span class="alert-title">Service Alerts</span>
      </div>

      <div v-if="serviceAlerts.alerts.length === 0" class="alert-empty">
        No active alerts
      </div>

      <ul v-else class="alert-list">
        <li
          v-for="alert in serviceAlerts.alerts"
          :key="alert.alertId"
          class="alert-item"
          :class="getSeverityClass(alert.severityLevel)"
        >
          <div class="alert-icon">⚠️</div>
          <div class="alert-content">
            <div class="alert-agencies">
              <span class="agency-badge" :class="alert.agency">
                {{ agencyLabel(alert.agency) }}
              </span>
            </div>
            <div class="alert-header-text">{{ alert.headerText }}</div>
            <div v-if="alert.effect" class="alert-effect">{{ alert.effect }}</div>
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useServiceAlertStore } from '@/stores/serviceAlertStore'

const serviceAlerts = useServiceAlertStore()
const dropdownOpen = ref(false)
const warnWrapper = ref<HTMLElement | null>(null)

function toggleDropdown() {
  dropdownOpen.value = !dropdownOpen.value
}

function handleClickOutside(e: MouseEvent) {
  if (warnWrapper.value && !warnWrapper.value.contains(e.target as Node)) {
    dropdownOpen.value = false
  }
}

function getSeverityClass(severity?: string): string {
  if (!severity) return ''
  const lower = severity.toLowerCase()
  if (lower.includes('emergency') || lower.includes('critical')) return 'severity-critical'
  if (lower.includes('maintenance')) return 'severity-maintenance'
  return ''
}

function agencyLabel(agency: 'sound_transit' | 'king_county_metro'): string {
  return agency === 'sound_transit' ? 'ST' : 'KCM'
}

onMounted(() => document.addEventListener('click', handleClickOutside))
onUnmounted(() => document.removeEventListener('click', handleClickOutside))
</script>

<style scoped>
.alert-wrapper {
  position: relative;
}

.alert-btn {
  position: relative;
  background: transparent;
  border: none;
  color: var(--color-text-muted);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.35rem;
  border-radius: var(--radius-sm);
  transition: color 0.15s;
}

.alert-btn:hover {
  color: var(--color-text);
}

.badge {
  position: absolute;
  top: -4px;
  right: -4px;
  background: #f59e0b;
  color: #000;
  font-size: 0.625rem;
  font-weight: 700;
  min-width: 16px;
  height: 16px;
  border-radius: 999px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 3px;
  line-height: 1;
}

/* ─── Dropdown ──────────────────────────────────────────────────────────────── */

.alert-dropdown {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  width: 340px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md, 8px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  z-index: 200;
  overflow: hidden;
}

.alert-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--color-border);
}

.alert-title {
  font-size: 0.875rem;
  font-weight: 600;
}

.alert-empty {
  padding: 1.25rem 1rem;
  font-size: 0.875rem;
  color: var(--color-text-muted);
  text-align: center;
}

.alert-list {
  list-style: none;
  max-height: 400px;
  overflow-y: auto;
}

.alert-item {
  display: flex;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--color-border);
  transition: background 0.12s;
  border-left: 3px solid var(--color-warning, #f59e0b);
}

.alert-item:last-child {
  border-bottom: none;
}

.alert-item:hover {
  background: rgba(255, 255, 255, 0.04);
}

.alert-item.severity-critical {
  border-left-color: #ef4444;
}

.alert-item.severity-maintenance {
  border-left-color: #f59e0b;
}

.alert-icon {
  flex-shrink: 0;
  font-size: 1.2rem;
}

.alert-content {
  flex: 1;
  min-width: 0;
}

.alert-agencies {
  margin-bottom: 0.25rem;
}

.agency-badge {
  display: inline-block;
  font-size: 0.625rem;
  font-weight: 700;
  background: rgba(255, 255, 255, 0.1);
  padding: 0.25rem 0.5rem;
  border-radius: 3px;
  text-transform: uppercase;
}

.alert-header-text {
  font-size: 0.8125rem;
  color: var(--color-text);
  font-weight: 500;
  line-height: 1.3;
  margin-bottom: 0.25rem;
}

.alert-effect {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  line-height: 1.3;
}
</style>
