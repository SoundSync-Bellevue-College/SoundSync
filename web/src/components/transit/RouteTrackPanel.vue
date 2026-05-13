<template>
  <div class="track-panel">
    <div class="track-header">
      <span class="track-title">Track a Route</span>
    </div>

    <!-- Active tracking badge -->
    <div v-if="mapStore.trackedRouteId" class="active-track">
      <span class="active-dot"></span>
      <span class="active-label">Tracking <strong>{{ mapStore.trackedShortName }}</strong></span>
      <button class="clear-btn" @click="clearTracking">✕ Clear</button>
    </div>

    <!-- Search input -->
    <div v-else class="search-wrap">
      <input
        ref="inputEl"
        v-model="query"
        class="track-input"
        type="text"
        placeholder="Route number or name…"
        autocomplete="off"
        @focus="showDropdown = true"
        @blur="onBlur"
        @keydown.escape="showDropdown = false"
        @keydown.enter="selectFirst"
        @keydown.down.prevent="moveDown"
        @keydown.up.prevent="moveUp"
      />
      <div v-if="showDropdown && filtered.length" class="dropdown">
        <button
          v-for="(route, i) in filtered"
          :key="route.id"
          class="dropdown-item"
          :class="{ highlighted: i === highlightIdx }"
          @mousedown.prevent="selectRoute(route)"
        >
          <span class="route-pill" :style="{ background: route.color, color: route.textColor }">
            {{ route.shortName }}
          </span>
          <span class="route-type-label">{{ routeTypeName(route.routeType) }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useMapStore } from '@/stores/mapStore'
import { getRouteLookup } from '@/services/routeLookup'

interface RouteOption {
  id: string        // numeric OBA id e.g. "100001"
  shortName: string
  color: string
  textColor: string
  routeType: number
}

const mapStore = useMapStore()
const query = ref('')
const showDropdown = ref(false)
const highlightIdx = ref(0)
const inputEl = ref<HTMLInputElement | null>(null)

// Load all routes from the CSV into a flat list
const allRoutes = ref<RouteOption[]>([])
getRouteLookup().then(lookup => {
  allRoutes.value = Array.from(lookup.entries()).map(([id, info]) => ({
    id,
    shortName: info.shortName,
    color: info.color,
    textColor: info.textColor,
    routeType: info.routeType,
  })).sort((a, b) => a.shortName.localeCompare(b.shortName, undefined, { numeric: true }))
})

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return allRoutes.value.slice(0, 8)
  return allRoutes.value
    .filter(r => r.shortName.toLowerCase().includes(q) || r.id.includes(q))
    .slice(0, 8)
})

function routeTypeName(type: number): string {
  if (type === 0) return 'Tram / LRT'
  if (type === 1) return 'Subway'
  if (type === 2) return 'Rail'
  if (type === 4) return 'Ferry'
  return 'Bus'
}

function selectRoute(route: RouteOption) {
  mapStore.trackedRouteId = route.id
  mapStore.trackedShortName = route.shortName
  query.value = ''
  showDropdown.value = false
}

function selectFirst() {
  const idx = Math.min(highlightIdx.value, filtered.value.length - 1)
  if (filtered.value[idx]) selectRoute(filtered.value[idx])
}

function moveDown() {
  highlightIdx.value = Math.min(highlightIdx.value + 1, filtered.value.length - 1)
}

function moveUp() {
  highlightIdx.value = Math.max(highlightIdx.value - 1, 0)
}

function onBlur() {
  setTimeout(() => { showDropdown.value = false }, 150)
}

function clearTracking() {
  mapStore.trackedRouteId = null
  mapStore.trackedShortName = null
}
</script>

<style scoped>
.track-panel {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 0.9rem 1.1rem;
  display: flex;
  flex-direction: column;
  gap: 0.55rem;
  box-shadow: var(--shadow-md);
}

.track-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.track-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text);
}

/* Active tracking */
.active-track {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: rgba(59, 130, 246, 0.1);
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: var(--radius-sm);
  padding: 0.45rem 0.7rem;
}

.active-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #3b82f6;
  animation: pulse 1.5s ease-in-out infinite;
  flex-shrink: 0;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

.active-label {
  flex: 1;
  font-size: 0.82rem;
  color: var(--color-text);
}

.clear-btn {
  background: transparent;
  border: none;
  color: var(--color-text-muted);
  font-size: 0.75rem;
  cursor: pointer;
  padding: 0.1rem 0.3rem;
  border-radius: 4px;
  transition: color 0.15s;
  white-space: nowrap;
}

.clear-btn:hover {
  color: var(--color-danger, #ef4444);
}

/* Search */
.search-wrap {
  position: relative;
}

.track-input {
  width: 100%;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.45rem 0.75rem;
  color: var(--color-text);
  font-size: 0.875rem;
  transition: border-color 0.15s;
  box-sizing: border-box;
}

.track-input:focus {
  outline: none;
  border-color: var(--color-primary);
}

.dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  box-shadow: 0 8px 24px rgba(0,0,0,0.3);
  z-index: 50;
  overflow: hidden;
  max-height: 280px;
  overflow-y: auto;
}

.dropdown-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.5rem 0.75rem;
  background: transparent;
  border: none;
  cursor: pointer;
  text-align: left;
  transition: background 0.1s;
}

.dropdown-item:hover,
.dropdown-item.highlighted {
  background: rgba(255,255,255,0.06);
}

.route-pill {
  padding: 0.1rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 700;
  white-space: nowrap;
  min-width: 40px;
  text-align: center;
}

.route-type-label {
  font-size: 0.78rem;
  color: var(--color-text-muted);
}
</style>
