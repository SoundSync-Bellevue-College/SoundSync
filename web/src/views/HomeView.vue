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
        @touchmove.prevent="onDragMove"
        @touchend.passive="onDragEnd"
      >
        <span class="handle-bar"></span>
      </div>

      <!-- Tabs -->
      <div class="tab-bar">
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
      <div class="tab-content" ref="tabContentEl" @scroll.passive="onTabScroll" @touchstart.passive="onContentTouchStart" @touchmove="onContentTouchMove">
        <RouteSearchPanel v-show="activeTab === 'plan'" @view-on-map="sheetOpen = false" :pending-destination="pendingDestination" @destination-applied="pendingDestination = null" />
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
      <MapContainer @set-destination="handleSetDestination" />
    </div>

    <!-- Tutorial spotlight overlay -->
    <Transition name="tutorial-fade">
      <div v-if="showTutorial" class="tutorial-overlay"></div>
    </Transition>

    <!-- Route detail FAB (mobile only, visible when a route result exists) -->
    <Transition name="fab-pop">
      <button
        v-if="routeStore.directionsResult && !showTutorial"
        class="fab fab-route"
        @click="showRouteDetail = true"
        aria-label="View route details"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"
          fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="6" cy="19" r="2"/><circle cx="18" cy="5" r="2"/>
          <path d="M6 17V9a6 6 0 0 1 6-6h1"/><path d="M18 7v8a6 6 0 0 1-6 6h-1"/>
        </svg>
      </button>
    </Transition>

    <!-- Route detail modal triggered from FAB -->
    <RouteDetailModal
      v-if="showRouteDetail && routeStore.directionsResult"
      :result="routeStore.directionsResult"
      @close="showRouteDetail = false"
      @select="showRouteDetail = false; sheetOpen = false"
    />

    <!-- Mobile FAB to toggle bottom sheet -->
    <button class="fab" :class="{ 'fab-spotlight': showTutorial }" @click="sheetOpen = !sheetOpen; sheetHalf = false; onFabTutorialClick()" aria-label="Toggle panel">
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

    <!-- Transit assistant chatbot -->
    <ChatBot />

    <!-- First-time tutorial callout -->
    <Transition name="tutorial-fade">
      <div v-if="showTutorial" class="tutorial-callout">
        <p class="tutorial-text">{{ tutorialStep === 1 ? 'Search routes for your trip.' : 'Close the Trip Planner.' }}</p>
        <svg class="tutorial-arrow" viewBox="0 0 60 60" width="60" height="60" xmlns="http://www.w3.org/2000/svg">
          <path d="M10 10 Q50 10 50 50" stroke="currentColor" stroke-width="2.5" fill="none" stroke-linecap="round"/>
          <polygon points="44,54 56,44 50,50" fill="currentColor"/>
        </svg>
        <span class="tutorial-dismiss">Press the button to continue</span>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import MapContainer from '@/components/map/MapContainer.vue'
import RouteSearchPanel from '@/components/transit/RouteSearchPanel.vue'
import RouteTrackPanel from '@/components/transit/RouteTrackPanel.vue'
import WeatherWidget from '@/components/weather/WeatherWidget.vue'
import ArrivalBoard from '@/components/transit/ArrivalBoard.vue'
import StopAlertBanner from '@/components/transit/StopAlertBanner.vue'
import RouteDetailModal from '@/components/transit/RouteDetailModal.vue'
import ChatBot from '@/components/common/ChatBot.vue'
import { useMapStore } from '@/stores/mapStore'
import { useServiceAlertStore } from '@/stores/serviceAlertStore'
import { useRouteStore } from '@/stores/routeStore'

const mapStore = useMapStore()
const serviceAlertStore = useServiceAlertStore()
const routeStore = useRouteStore()
const showRouteDetail = ref(false)
const sheetOpen = ref(false)
const sheetHalf = ref(false)
const activeTab = ref<'plan' | 'track' | 'weather'>('plan')
const pendingDestination = ref<{ name: string; lat: number; lng: number } | null>(null)
const tabContentEl = ref<HTMLElement | null>(null)

const tutorialStep = ref(0)
const showTutorial = computed(() => tutorialStep.value > 0)

onMounted(() => {
  if (window.innerWidth <= 768 && !localStorage.getItem('soundsync_tutorial_seen')) {
    tutorialStep.value = 1
  }
})

function onFabTutorialClick() {
  if (tutorialStep.value === 1) {
    tutorialStep.value = 2
  } else if (tutorialStep.value === 2) {
    tutorialStep.value = 0
    localStorage.setItem('soundsync_tutorial_seen', '1')
  }
}

function dismissTutorial() {
  tutorialStep.value = 0
  localStorage.setItem('soundsync_tutorial_seen', '1')
}

function onTabScroll() {
  if (window.innerWidth > 768) return
  const el = tabContentEl.value
  if (!el) return
  const atBottom = el.scrollTop + el.clientHeight >= el.scrollHeight - 8
  if (atBottom) {
    sheetOpen.value = false
    sheetHalf.value = false
  }
}

let contentTouchStartY = 0

function onContentTouchStart(e: TouchEvent) {
  contentTouchStartY = e.touches[0].clientY
}

function onContentTouchMove(e: TouchEvent) {
  if (window.innerWidth > 768) return
  const el = tabContentEl.value
  if (!el) return
  const atTop = el.scrollTop <= 0
  const swipingDown = e.touches[0].clientY > contentTouchStartY
  if (atTop && swipingDown) {
    e.preventDefault()
    sheetOpen.value = false
    sheetHalf.value = false
  }
}

function handleSetDestination(payload: { name: string; lat: number; lng: number }) {
  pendingDestination.value = payload
  activeTab.value = 'plan'
  sheetOpen.value = true
  sheetHalf.value = false
}

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
  const swipingUp = dragY.value < dragStartTranslateY
  if (swipingUp) {
    sheetOpen.value = true
    sheetHalf.value = false
  } else {
    sheetOpen.value = false
    sheetHalf.value = false
  }
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

// ── Android back-gesture / browser back button support for bottom sheet ───
let sheetHistoryPushed = false

function onSheetPopState() {
  sheetHistoryPushed = false
  window.removeEventListener('popstate', onSheetPopState)
  sheetOpen.value = false
  sheetHalf.value = false
}

watch(sheetOpen, (isOpen) => {
  if (window.innerWidth > 768) return
  if (isOpen && !sheetHistoryPushed) {
    history.pushState({ sheetOpen: true }, '')
    sheetHistoryPushed = true
    window.addEventListener('popstate', onSheetPopState)
  } else if (!isOpen && sheetHistoryPushed) {
    sheetHistoryPushed = false
    window.removeEventListener('popstate', onSheetPopState)
    history.back()
  }
})

onUnmounted(() => {
  window.removeEventListener('popstate', onSheetPopState)
  if (sheetHistoryPushed) {
    sheetHistoryPushed = false
    history.back()
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
  overscroll-behavior: none;
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

/* Desktop: hide tabs when stop is selected, let stop panel scroll */
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
    overscroll-behavior: none;
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
    touch-action: none;
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

  /* Route detail FAB — sits above the main search FAB */
  .fab-route {
    bottom: 130px;
    background: var(--color-surface);
    color: var(--color-primary);
    border: 2px solid var(--color-primary);
  }

  .fab-route:hover {
    background: color-mix(in srgb, var(--color-primary) 12%, var(--color-surface));
    transform: scale(1.05);
  }

  /* Pop in/out animation for route FAB */
  .fab-pop-enter-active,
  .fab-pop-leave-active {
    transition: opacity 0.2s ease, transform 0.2s ease;
  }

  .fab-pop-enter-from,
  .fab-pop-leave-to {
    opacity: 0;
    transform: scale(0.7);
  }

  /* ── Tutorial overlay (greys out everything incl. header) ── */
  .tutorial-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.65);
    z-index: 110;
    pointer-events: all;
  }

  /* FAB lifted above overlay during tutorial */
  .fab-spotlight {
    z-index: 115 !important;
    box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.65);
    animation: fab-breathe 0.9s ease-in-out infinite;
  }

  @keyframes fab-breathe {
    0%, 100% { filter: brightness(1); transform: scale(1); }
    50%       { filter: brightness(1.45); transform: scale(1.08); }
  }

  /* ── Tutorial callout ── */
  .tutorial-callout {
    z-index: 116 !important;
    pointer-events: none;
    position: fixed;
    bottom: 130px;
    right: 0.75rem;
    z-index: 20;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 4px;
    cursor: pointer;
    pointer-events: all;
  }

  .tutorial-text {
    background: var(--color-surface);
    color: var(--color-text);
    border: 1px solid var(--color-border);
    border-radius: 12px;
    padding: 10px 14px;
    font-size: 0.82rem;
    font-weight: 500;
    line-height: 1.4;
    max-width: 200px;
    text-align: right;
    box-shadow: 0 4px 16px rgba(0,0,0,0.3);
  }

  .tutorial-arrow {
    color: var(--color-primary);
    margin-right: 12px;
  }

  .tutorial-dismiss {
    font-size: 0.68rem;
    color: var(--color-text-muted);
    margin-right: 4px;
  }

  .tutorial-fade-enter-active,
  .tutorial-fade-leave-active {
    transition: opacity 0.4s ease, transform 0.4s ease;
  }

  .tutorial-fade-enter-from,
  .tutorial-fade-leave-to {
    opacity: 0;
    transform: translateY(10px);
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
