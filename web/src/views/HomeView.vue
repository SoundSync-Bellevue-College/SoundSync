<template>
  <div class="home-view">
    <!-- Sidebar (desktop) / Bottom sheet (mobile) -->
    <aside
      class="sidebar"
      :class="{ 'sheet-open': sheetOpen, 'sheet-half': sheetHalf && !sheetOpen, 'has-stop': !!mapStore.selectedStop, 'is-dragging': dragging }"
      :style="dragging ? { transform: `translateY(${dragY}px)` } : {}"
    >
      <!-- Mobile drag handle -->
      <div
        class="sheet-handle"
        @click="onHandleTap"
        @touchstart.passive="onDragStart"
        @touchmove.passive="onDragMove"
        @touchend.passive="onDragEnd"
      >
        <span class="handle-bar"></span>
      </div>

      <!-- Tabs -->
      <div class="tab-bar">
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'plan' }"
          @click="activeTab = 'plan'"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"
            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
          </svg>
          Plan
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'track' }"
          @click="activeTab = 'track'; sheetHalf = true"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"
            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="1" y="3" width="15" height="13" rx="2"/><path d="M16 8h4l3 3v5h-7V8z"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/>
          </svg>
          Track
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'weather' }"
          @click="activeTab = 'weather'"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"
            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9z"/>
          </svg>
          Weather
        </button>
      </div>

      <!-- Tab content -->
      <div class="tab-content">
        <RouteSearchPanel v-show="activeTab === 'plan'" @view-on-map="sheetOpen = false" />
        <RouteTrackPanel  v-show="activeTab === 'track'" />
        <WeatherWidget    v-show="activeTab === 'weather'" />
      </div>

      <!-- Stop panel — always shown when a stop is selected -->
      <div v-if="mapStore.selectedStop" class="stop-panel">
        <div class="stop-panel-header">
          <span class="stop-icon">🚏</span>
          <span class="stop-name">{{ mapStore.selectedStop.name }}</span>
          <button class="stop-close" @click="mapStore.selectStop(null)">✕</button>
        </div>
        <StopAlertBanner :alerts="stopAlerts" />
        <ArrivalBoard
          :stop-id="mapStore.selectedStop.stopId"
          :stop-name="mapStore.selectedStop.name"
        />
      </div>
    </aside>

    <!-- Map fills remaining space -->
    <div class="map-area">
      <MapContainer />
    </div>

    <!-- Mobile FAB to toggle bottom sheet -->
    <button class="fab" @click="sheetOpen = !sheetOpen; sheetHalf = false" aria-label="Toggle panel">
      <svg v-if="!sheetOpen" xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24"
        fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
      </svg>
      <svg v-else xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24"
        fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
      </svg>
    </button>

    <!-- Backdrop (mobile only) -->
    <div v-if="sheetOpen" class="sheet-backdrop" @click="sheetOpen = false"></div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import MapContainer from '@/components/map/MapContainer.vue'
import RouteSearchPanel from '@/components/transit/RouteSearchPanel.vue'
import RouteTrackPanel from '@/components/transit/RouteTrackPanel.vue'
import WeatherWidget from '@/components/weather/WeatherWidget.vue'
import ArrivalBoard from '@/components/transit/ArrivalBoard.vue'
import StopAlertBanner from '@/components/transit/StopAlertBanner.vue'
import { useMapStore } from '@/stores/mapStore'
import { useServiceAlertStore } from '@/stores/serviceAlertStore'

const mapStore = useMapStore()
const serviceAlertStore = useServiceAlertStore()
const sheetOpen = ref(false)
const sheetHalf = ref(false)
const activeTab = ref<'plan' | 'track' | 'weather'>('plan')

// ── Drag to resize bottom sheet ───────────────────────────────────────────
const dragging = ref(false)
const dragY = ref(0)
let dragStartTouchY = 0
let dragStartTranslateY = 0

function sheetTranslateY(): number {
  const vh = window.innerHeight
  const sheetH = vh * 0.8
  if (sheetOpen.value) return 0
  if (sheetHalf.value) return vh * 0.3
  return sheetH - 36
}

function onDragStart(e: TouchEvent) {
  if (window.innerWidth > 768) return
  dragging.value = true
  dragStartTouchY = e.touches[0].clientY
  dragStartTranslateY = sheetTranslateY()
  dragY.value = dragStartTranslateY
}

function onDragMove(e: TouchEvent) {
  if (!dragging.value) return
  const delta = e.touches[0].clientY - dragStartTouchY
  const vh = window.innerHeight
  const max = vh * 0.8 - 36
  dragY.value = Math.max(0, Math.min(max, dragStartTranslateY + delta))
}

function onDragEnd() {
  if (!dragging.value) return
  dragging.value = false
  const vh = window.innerHeight
  const peekY = vh * 0.8 - 36
  const halfY = vh * 0.3
  const fullY = 0
  const snapPoints = [fullY, halfY, peekY]
  const nearest = snapPoints.reduce((a, b) =>
    Math.abs(b - dragY.value) < Math.abs(a - dragY.value) ? b : a
  )
  if (nearest === fullY) { sheetOpen.value = true;  sheetHalf.value = false }
  else if (nearest === halfY) { sheetOpen.value = false; sheetHalf.value = true }
  else { sheetOpen.value = false; sheetHalf.value = false }
}

const stopAlerts = computed(() => {
  if (!mapStore.selectedStop) return []
  return serviceAlertStore.getAlertsForStop(
    mapStore.selectedStop.stopId,
    mapStore.selectedStop.routes,
  )
})

function onHandleTap() {
  if (mapStore.selectedStop) {
    mapStore.selectStop(null)
  } else {
    sheetOpen.value = !sheetOpen.value
    if (sheetOpen.value) sheetHalf.value = false
  }
}

// Auto-open sheet fully when a stop is tapped on mobile
watch(() => mapStore.selectedStop, (stop) => {
  if (window.innerWidth > 768) return
  if (stop) {
    sheetOpen.value = true
    sheetHalf.value = false
  }
})

// Half-open for Track only if sheet is currently at peek
watch(activeTab, (tab) => {
  if (window.innerWidth > 768) return
  if (tab === 'track' && !sheetOpen.value && !sheetHalf.value) {
    sheetHalf.value = true
  }
})
</script>

<style scoped>
.home-view {
  display: flex;
  height: 100%;
  overflow: hidden;
  position: relative;
}

.sidebar {
  width: 380px;
  flex-shrink: 0;
  background: var(--color-bg);
  border-right: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  overflow: clip;
}

/* ── Tabs ── */
.tab-bar {
  display: flex;
  border-bottom: 1px solid var(--color-border);
  flex-shrink: 0;
  padding: 0.5rem 0.75rem 0;
  gap: 0.25rem;
}

.tab-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  padding: 0.45rem 0.5rem;
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  color: var(--color-text-muted);
  font-size: 0.8rem;
  font-weight: 500;
  cursor: pointer;
  transition: color 0.15s, border-color 0.15s;
  white-space: nowrap;
  margin-bottom: -1px;
}

.tab-btn:hover {
  color: var(--color-text);
}

.tab-btn.active {
  color: var(--color-primary);
  border-bottom-color: var(--color-primary);
}

.tab-content {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
}

.map-area {
  flex: 1;
  position: relative;
  overflow: hidden;
}

/* ── Stop panel ── */
.stop-panel {
  border-top: 1px solid var(--color-border);
  padding-top: 0.75rem;
}

.stop-panel-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
}

.stop-icon {
  font-size: 1rem;
}

.stop-name {
  flex: 1;
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.stop-close {
  background: none;
  border: none;
  color: var(--color-text-muted);
  font-size: 0.85rem;
  cursor: pointer;
  padding: 0.1rem 0.3rem;
  border-radius: 4px;
  transition: color 0.15s;
}

.stop-close:hover {
  color: var(--color-text);
}

/* Hide mobile-only elements on desktop */
.sheet-handle,
.fab,
.sheet-backdrop {
  display: none;
}

/* ── Mobile ── */
@media (max-width: 768px) {
  .home-view {
    flex-direction: column;
  }

  /* Map fills the whole screen */
  .map-area {
    position: absolute;
    inset: 0;
    z-index: 0;
  }

  /* Sidebar becomes a bottom sheet */
  .sidebar {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    width: 100%;
    height: 80vh;
    border-right: none;
    border-top: 1px solid var(--color-border);
    border-radius: 16px 16px 0 0;
    padding: 0;
    z-index: 10;
    transform: translateY(calc(80vh - 36px));
    transition: transform 0.3s ease;
    box-shadow: 0 -4px 24px rgba(0, 0, 0, 0.4);
  }

  .sidebar.sheet-open {
    transform: translateY(0);
  }

  .sidebar.is-dragging {
    transition: none;
    user-select: none;
  }

  .sidebar.sheet-half {
    transform: translateY(30vh);
  }

  .tab-bar {
    padding: 0.4rem 0.75rem 0;
  }

  .tab-content {
    padding: 0.75rem;
  }

  /* Stop view — hides tabs, stop panel fills the sheet */
  .sidebar.has-stop .tab-bar,
  .sidebar.has-stop .tab-content {
    display: none;
  }

  .sidebar.has-stop .stop-panel {
    flex: 1;
    overflow-y: auto;
    padding: 0.75rem 1rem 1.5rem;
    border-top: none;
  }

  /* Drag handle */
  .sheet-handle {
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 0.6rem 0 0.4rem;
    cursor: pointer;
    flex-shrink: 0;
  }

  .handle-bar {
    width: 40px;
    height: 4px;
    background: var(--color-border);
    border-radius: 999px;
  }

  /* FAB */
  .fab {
    display: flex;
    align-items: center;
    justify-content: center;
    position: fixed;
    bottom: 68px;
    right: 1rem;
    width: 48px;
    height: 48px;
    border-radius: 50%;
    background: var(--color-primary);
    color: #fff;
    border: none;
    cursor: pointer;
    z-index: 11;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.4);
    transition: background 0.15s, transform 0.15s;
  }

  .fab:hover {
    background: var(--color-primary-hover);
    transform: scale(1.05);
  }

  /* Backdrop */
  .sheet-backdrop {
    display: block;
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.4);
    z-index: 9;
  }
}
</style>
