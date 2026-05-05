<template>
  <div class="route-summary" role="button" tabindex="0" title="Click for full details" @click="$emit('detail')" @keydown.enter="$emit('detail')"  >
    <!-- Header: total time + depart/arrive -->
    <div class="summary-header">
      <span class="summary-duration">{{ leg.duration?.text }}</span>
      <span class="summary-times">{{ leg.departure_time?.text }} → {{ leg.arrival_time?.text }}</span>
    </div>

    <!-- Step-by-step legs -->
    <ol class="leg-list">
      <li v-for="(step, i) in leg.steps" :key="i" class="leg-row">

        <!-- WALKING step -->
        <template v-if="step.travel_mode === 'WALKING'">
          <span class="mode-badge walk">🚶 Walk</span>
          <div class="leg-body">
            <span class="leg-desc">{{ step.distance?.text }}</span>
            <span class="leg-time">{{ step.duration?.text }}</span>
          </div>
        </template>

        <!-- TRANSIT step -->
        <template v-else-if="step.travel_mode === 'TRANSIT' && step.transit">
          <span
            class="mode-badge transit"
            :style="transitBadgeStyle(step.transit)"
          >
            {{ transitIcon(step.transit) }} {{ step.transit.line?.short_name || step.transit.line?.name }}
          </span>
          <div class="leg-body">
            <div class="transit-stops">
              <span class="stop-name">{{ step.transit.departure_stop?.name }}</span>
              <span class="stop-arrow">→</span>
              <span class="stop-name">{{ step.transit.arrival_stop?.name }}</span>
            </div>
            <div class="transit-meta">
              <span>{{ step.transit.departure_time?.text }}</span>
              <span class="dot">·</span>
              <span>{{ step.transit.num_stops }} stop{{ step.transit.num_stops === 1 ? '' : 's' }}</span>
              <span class="dot">·</span>
              <span>{{ step.duration?.text }}</span>
            </div>
            <div v-if="step.transit.headsign" class="transit-headsign">
              toward {{ step.transit.headsign }}
            </div>
          </div>
        </template>

      </li>
    </ol>

    <!-- Fare if available -->
    <div v-if="result.routes[0]?.fare" class="fare-row">
      <span>
        Fare: {{ result.routes[0].fare?.currency }} {{ result.routes[0].fare?.value }}
      </span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  result: google.maps.DirectionsResult
}>()

defineEmits<{ detail: [] }>()

// Use the first route's first leg
const leg = computed(() => props.result.routes[0]?.legs[0])

function transitIcon(transit: google.maps.TransitDetails): string {
  const type = transit.line?.vehicle?.type
  if (type === 'SUBWAY' || type === 'METRO_RAIL' || type === 'TRAM') return '🚇'
  if (type === 'RAIL' || type === 'HEAVY_RAIL' || type === 'COMMUTER_TRAIN') return '🚆'
  if (type === 'FERRY') return '⛴️'
  return '🚌' // BUS default
}

function transitBadgeStyle(transit: google.maps.TransitDetails): Record<string, string> {
  const bg = transit.line?.color ?? '#1d4ed8'
  const text = transit.line?.text_color ?? '#ffffff'
  return { background: bg, color: text }
}
</script>

<style scoped>
.route-summary {
  background: var(--color-bg);
  border-radius: var(--radius-md);
  padding: 0.85rem;
  margin-top: 0.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.65rem;
  cursor: pointer;
  border: 1px solid transparent;
  transition: border-color 0.15s;
}

.route-summary:hover {
  border-color: var(--color-primary);
}

.route-summary::after {
  content: 'Tap for full details →';
  font-size: 0.68rem;
  color: var(--color-primary);
  text-align: right;
  opacity: 0.7;
}

.summary-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

.summary-duration {
  font-size: 1.15rem;
  font-weight: 700;
  color: var(--color-text);
}

.summary-times {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.leg-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 0.55rem;
}

.leg-row {
  display: flex;
  gap: 0.6rem;
  align-items: flex-start;
}

/* Mode badge */
.mode-badge {
  flex-shrink: 0;
  padding: 0.15rem 0.45rem;
  border-radius: 4px;
  font-size: 0.7rem;
  font-weight: 700;
  white-space: nowrap;
  min-width: 52px;
  text-align: center;
  margin-top: 0.05rem;
}

.mode-badge.walk {
  background: #475569;
  color: #e2e8f0;
}

.mode-badge.transit {
  /* background + color set inline from line color */
}

/* Leg body */
.leg-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
  min-width: 0;
}

.leg-desc {
  font-size: 0.82rem;
  color: var(--color-text-muted);
}

.leg-time {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

/* Transit-specific */
.transit-stops {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  flex-wrap: wrap;
}

.stop-name {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--color-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 140px;
}

.stop-arrow {
  color: var(--color-text-muted);
  font-size: 0.75rem;
}

.transit-meta {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.72rem;
  color: var(--color-text-muted);
}

.dot {
  opacity: 0.4;
}

.transit-headsign {
  font-size: 0.7rem;
  color: var(--color-text-muted);
  font-style: italic;
}

.fare-row {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  border-top: 1px solid var(--color-border);
  padding-top: 0.4rem;
}
</style>
