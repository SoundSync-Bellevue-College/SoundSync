<template>
  <div v-if="alerts.length > 0" class="alert-banner">
    <div class="banner-title">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3.05h16.94a2 2 0 0 0 1.71-3.05L13.71 3.86a2 2 0 0 0-3.42 0z" />
        <line x1="12" y1="9" x2="12" y2="13" />
        <line x1="12" y1="17" x2="12.01" y2="17" />
      </svg>
      <span>Active Alerts</span>
    </div>

    <div class="alerts-list">
      <div v-for="alert in alerts" :key="alert.alertId" class="alert-row">
        <div class="alert-main">
          <div class="alert-text">{{ alert.headerText }}</div>
          <div v-if="alert.effect" class="alert-effect">{{ alert.effect }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { ServiceAlert } from '@/types/serviceAlert'

defineProps<{
  alerts: ServiceAlert[]
}>()
</script>

<style scoped>
.alert-banner {
  margin-bottom: 1rem;
  padding: 0.75rem 1rem;
  background: rgba(245, 158, 11, 0.1);
  border: 1px solid var(--color-warning, #f59e0b);
  border-left: 3px solid var(--color-warning, #f59e0b);
  border-radius: var(--radius-sm);
}

.banner-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.banner-title svg {
  color: var(--color-warning, #f59e0b);
}

.alerts-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.alert-row {
  padding: 0.5rem;
  background: rgba(255, 255, 255, 0.02);
  border-radius: var(--radius-sm);
  border-left: 2px solid var(--color-warning, #f59e0b);
  padding-left: 0.75rem;
}

.alert-main {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.alert-text {
  font-size: 0.75rem;
  color: var(--color-text);
  font-weight: 500;
  line-height: 1.3;
}

.alert-effect {
  font-size: 0.7rem;
  color: var(--color-text-muted);
  line-height: 1.2;
}
</style>
