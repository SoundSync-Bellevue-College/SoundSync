<template>
  <div class="route-summary">

    <!-- Route option tabs (only shown when > 1 route) -->
    <div v-if="result.routes.length > 1" class="route-tabs">
      <button
        v-for="(route, i) in result.routes"
        :key="i"
        class="route-tab"
        :class="{ active: routeStore.selectedRouteIndex === i }"
        @click="routeStore.selectedRouteIndex = i"
      >
        Option {{ i + 1 }}
        <span class="tab-duration">{{ route.legs[0]?.duration?.text }}</span>
      </button>
    </div>

    <!-- Clickable card body -->
    <div class="summary-body" role="button" tabindex="0" title="Click for full details" @click="$emit('detail')" @keydown.enter="$emit('detail')">
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

    </div><!-- end summary-body -->

    <!-- Fare breakdown -->
    <div v-if="fareBreakdown" class="fare-section">
      <div class="fare-title">Estimated Fare (ORCA)</div>
      <div class="fare-rows">
        <div v-if="fareBreakdown.busCost > 0" class="fare-line">
          <span class="fare-mode">
            <span class="fare-dot" style="background:#f97316"></span>Bus
          </span>
          <span class="fare-amount">${{ fareBreakdown.busCost.toFixed(2) }}</span>
        </div>
        <div v-if="fareBreakdown.railCost > 0" class="fare-line">
          <span class="fare-mode">
            <span class="fare-dot" style="background:#a855f7"></span>Rail / LRT
          </span>
          <span class="fare-amount">${{ fareBreakdown.railCost.toFixed(2) }}</span>
        </div>
        <div v-if="fareBreakdown.ferryCost > 0" class="fare-line">
          <span class="fare-mode">
            <span class="fare-dot" style="background:#0ea5e9"></span>Ferry
          </span>
          <span class="fare-amount">${{ fareBreakdown.ferryCost.toFixed(2) }}</span>
        </div>
        <div class="fare-line fare-total">
          <span class="fare-mode">Total</span>
          <span class="fare-amount">${{ fareBreakdown.total.toFixed(2) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouteStore } from '@/stores/routeStore'

const props = defineProps<{
  result: google.maps.DirectionsResult
}>()

defineEmits<{ detail: [] }>()

const routeStore = useRouteStore()

const leg = computed(() => props.result.routes[routeStore.selectedRouteIndex]?.legs[0])

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

// Puget Sound ORCA per-boarding estimates
const FARE: Record<string, number> = {
  BUS:            2.75,
  SUBWAY:         2.75,
  TRAM:           3.25,
  LIGHT_RAIL:     3.25,
  MONORAIL:       3.25,
  HEAVY_RAIL:     5.00,
  COMMUTER_TRAIN: 5.00,
  FERRY:          7.70,
}

const fareBreakdown = computed(() => {
  const route = props.result.routes[routeStore.selectedRouteIndex]
  if (!route) return null

  let busCost = 0, railCost = 0, ferryCost = 0

  for (const leg of route.legs) {
    for (const step of leg.steps) {
      if (step.travel_mode !== 'TRANSIT' || !step.transit) continue
      const type = step.transit.line?.vehicle?.type ?? 'BUS'
      const rate = FARE[type] ?? 2.75
      if (type === 'FERRY') ferryCost += rate
      else if (type === 'HEAVY_RAIL' || type === 'COMMUTER_TRAIN') railCost += rate
      else if (type === 'TRAM' || type === 'LIGHT_RAIL' || type === 'MONORAIL' || type === 'SUBWAY') railCost += rate
      else busCost += rate
    }
  }

  const total = busCost + railCost + ferryCost
  if (total === 0) return null
  return { busCost, railCost, ferryCost, total }
})
</script>

<style scoped>
.route-summary {
  background: var(--color-bg);
  border-radius: var(--radius-md);
  margin-top: 0.25rem;
  display: flex;
  flex-direction: column;
  border: 1px solid var(--color-border);
  overflow: hidden;
}

/* Route option tabs */
.route-tabs {
  display: flex;
  border-bottom: 1px solid var(--color-border);
}

.route-tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.1rem;
  padding: 0.4rem 0.5rem;
  background: transparent;
  border: none;
  border-right: 1px solid var(--color-border);
  color: var(--color-text-muted);
  font-size: 0.72rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.12s, color 0.12s;
}

.route-tab:last-child {
  border-right: none;
}

.route-tab:hover {
  background: rgba(255, 255, 255, 0.04);
  color: var(--color-text);
}

.route-tab.active {
  background: rgba(59, 130, 246, 0.15);
  color: #93c5fd;
  border-bottom: 2px solid #3b82f6;
}

.tab-duration {
  font-size: 0.68rem;
  font-weight: 400;
  color: inherit;
  opacity: 0.8;
}

/* Clickable body */
.summary-body {
  padding: 0.85rem;
  display: flex;
  flex-direction: column;
  gap: 0.65rem;
  cursor: pointer;
  transition: background 0.12s;
}

.summary-body:hover {
  background: rgba(255, 255, 255, 0.03);
}

.summary-body::after {
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

.fare-section {
  border-top: 1px solid var(--color-border);
  padding: 0.5rem 0.85rem 0.75rem;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.fare-title {
  font-size: 0.68rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.fare-rows {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}

.fare-line {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 0.8rem;
  color: var(--color-text-muted);
}

.fare-mode {
  display: flex;
  align-items: center;
  gap: 0.35rem;
}

.fare-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.fare-amount {
  font-variant-numeric: tabular-nums;
}

.fare-total {
  border-top: 1px solid var(--color-border);
  margin-top: 0.15rem;
  padding-top: 0.2rem;
  font-weight: 700;
  color: var(--color-text);
}
</style>
