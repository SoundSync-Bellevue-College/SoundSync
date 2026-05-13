<template>
  <div class="map-root">
    <div ref="mapEl" class="map-canvas" />
    <LoadingSpinner v-if="!mapReady" overlay label="Loading map…" />

    <!-- Map controls overlay -->
    <div class="map-overlay">

      <!-- Map type + Color legend link -->
      <div class="overlay-section-row">
        <span class="overlay-section-label">Map type</span>
        <button class="color-legend-link" @click="showLegend = !showLegend">Color</button>
      </div>
      <div class="map-type-grid">
        <button
          v-for="t in mapTypes"
          :key="t.id"
          class="map-type-btn"
          :class="{ active: mapStore.mapTypeId === t.id }"
          @click="mapStore.mapTypeId = t.id"
        >
          <span class="map-type-icon">{{ t.icon }}</span>
          <span>{{ t.label }}</span>
        </button>
      </div>

      <div class="overlay-divider" />

      <!-- Layers -->
      <div class="overlay-section-label">Layers</div>
      <label class="overlay-option">
        <input type="checkbox" v-model="mapStore.showTransitLayer" />
        Transit
      </label>
      <label class="overlay-option">
        <input type="checkbox" v-model="mapStore.showTrafficLayer" />
        Traffic
      </label>
      <label class="overlay-option">
        <input type="checkbox" v-model="mapStore.showBikingLayer" />
        Biking
      </label>

      <div class="overlay-divider" />

      <!-- Vehicle filter -->
      <div class="overlay-section-label">Vehicles</div>
      <label class="overlay-option">
        <input type="radio" name="vehicle-type" value="ALL" v-model="mapStore.vehicleTypeFilter" />
        All
      </label>
      <label class="overlay-option">
        <input type="radio" name="vehicle-type" value="BUS" v-model="mapStore.vehicleTypeFilter" />
        Bus only
      </label>
      <label class="overlay-option">
        <input type="radio" name="vehicle-type" value="RAIL" v-model="mapStore.vehicleTypeFilter" />
        Rail only
      </label>

      <div class="overlay-divider" />

      <label class="overlay-option" :class="{ disabled: !routeStore.directionsResult }">
        <input
          type="checkbox"
          :disabled="!routeStore.directionsResult"
          v-model="mapStore.showOnlyPlanned"
        />
        Planned trip only
        <span v-if="mapStore.showOnlyPlanned && plannedShortNames.size" class="route-pills">
          <span v-for="name in plannedShortNames" :key="name" class="pill">{{ name }}</span>
        </span>
      </label>

      <!-- Color legend popup — inside overlay so position:absolute is relative to it -->
      <Transition name="legend-fade">
        <div v-if="showLegend" class="color-legend">
          <div class="legend-header">
            <span class="legend-title">Color Legend</span>
            <button class="legend-close" @click="showLegend = false">✕</button>
          </div>
          <div class="legend-items">
            <div class="legend-item" v-for="item in colorLegend" :key="item.label">
              <span
                class="legend-swatch"
                :style="item.dashed
                  ? { background: 'transparent', border: `2px dashed ${item.color}` }
                  : { background: item.color }"
              />
              <span class="legend-label">{{ item.label }}</span>
              <span class="legend-desc">{{ item.desc }}</span>
            </div>
          </div>
        </div>
      </Transition>
    </div>

    <StopMarker
      v-for="stop in mapStore.nearbyStops"
      :key="stop.stopId"
      :stop="stop"
      :map="map"
      @click="onStopClick(stop)"
    />

    <VehicleMarker
      v-for="vehicle in displayedVehicles"
      :key="vehicle.vehicleId"
      :vehicle="vehicle"
      :map="map"
      @click="onVehicleClick"
    />

    <VehicleReportModal
      v-if="reportVehicle"
      :vehicle="reportVehicle"
      @close="reportVehicle = null"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useMapStore } from '@/stores/mapStore'
import { useRouteStore } from '@/stores/routeStore'
import { loadGoogleMaps, decodePolyline } from '@/services/mapsService'
import { getRouteLookup } from '@/services/routeLookup'
import api from '@/services/api'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import StopMarker from './StopMarker.vue'
import VehicleMarker from './VehicleMarker.vue'
import VehicleReportModal from '@/components/transit/VehicleReportModal.vue'
import type { VehiclePosition, Stop } from '@/types/transit'

const mapEl = ref<HTMLElement | null>(null)
const mapReady = ref(false)
const map = ref<google.maps.Map | null>(null)
const mapStore = useMapStore()
const routeStore = useRouteStore()

const reportVehicle = ref<VehiclePosition | null>(null)
const showLegend = ref(false)

const colorLegend = [
  { label: 'Bus',            color: '#f97316', desc: 'Local & express buses',     dashed: false },
  { label: 'Subway',         color: '#a855f7', desc: 'Underground metro lines',   dashed: false },
  { label: 'Train / Rail',   color: '#f59e0b', desc: 'Heavy & commuter rail',     dashed: false },
  { label: 'Tram / LRT',     color: '#22c55e', desc: 'Light rail & streetcar',    dashed: false },
  { label: 'Ferry',          color: '#0ea5e9', desc: 'Water transit',             dashed: false },
  { label: 'Walking',        color: '#3b82f6', desc: 'Walk segments (dashed)',     dashed: true  },
]
let transitLayer: google.maps.TransitLayer | null = null
let trafficLayer: google.maps.TrafficLayer | null = null
let bikingLayer: google.maps.BicyclingLayer | null = null

const mapTypes = [
  { id: 'roadmap'   as const, label: 'Default',   icon: '🗺️' },
  { id: 'satellite' as const, label: 'Satellite',  icon: '🛰️' },
  { id: 'hybrid'    as const, label: 'Hybrid',     icon: '🌍' },
  { id: 'terrain'   as const, label: 'Terrain',    icon: '⛰️' },
]

function onVehicleClick(vehicle: VehiclePosition) {
  mapStore.selectVehicle(vehicle.vehicleId)
  reportVehicle.value = vehicle
}

function onStopClick(stop: Stop) {
  mapStore.selectStop(stop)
}

// route_id → short_name lookup (loaded once from CSV)
const routeMap = ref<Map<string, string>>(new Map())

let directionsRenderer: google.maps.DirectionsRenderer | null = null
let stepPolylines: google.maps.Polyline[] = []
let routeShapePolylines: google.maps.Polyline[] = []
let routeStopMarkers: google.maps.Marker[] = []

function clearRouteShape() {
  routeShapePolylines.forEach(p => p.setMap(null))
  routeShapePolylines = []
  routeStopMarkers.forEach(m => m.setMap(null))
  routeStopMarkers = []
}

interface RouteStop { id: string; name: string; code: string; lat: number; lng: number }

function buildStopIcon(color: string): google.maps.Icon {
  const svg = [
    `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14">`,
    `<circle cx="7" cy="7" r="5" fill="${color}" stroke="white" stroke-width="2"/>`,
    `</svg>`,
  ].join('')
  return {
    url: `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`,
    anchor: new google.maps.Point(7, 7),
    scaledSize: new google.maps.Size(14, 14),
  }
}

async function drawRouteShape(routeId: string) {
  clearRouteShape()
  if (!map.value) return

  // Try OBA agency prefixes in order; use first that returns data
  const candidates = [`1_${routeId}`, `40_${routeId}`, `3_${routeId}`, `29_${routeId}`]
  let encoded: string[] = []
  let stops: RouteStop[] = []

  for (const obaId of candidates) {
    try {
      const res = await api.get(`/routes/${encodeURIComponent(obaId)}/shape`)
      const lines: string[] = res.data?.polylines ?? []
      if (lines.length) {
        encoded = lines
        stops = res.data?.stops ?? []
        break
      }
    } catch { /* try next prefix */ }
  }

  if (!encoded.length) return

  // Look up the route's brand color from CSV
  const lookup = await getRouteLookup()
  const info = lookup.get(routeId)
  const color = info?.color ?? '#3b82f6'

  // Draw route path polylines
  for (const enc of encoded) {
    const path = await decodePolyline(enc)
    if (!path.length) continue
    const poly = new google.maps.Polyline({
      path,
      map: map.value,
      strokeColor: color,
      strokeWeight: 4,
      strokeOpacity: 0.85,
      zIndex: 5,
    })
    routeShapePolylines.push(poly)
  }

  // Draw stop markers
  const stopIcon = buildStopIcon(color)
  for (const stop of stops) {
    const marker = new google.maps.Marker({
      position: { lat: stop.lat, lng: stop.lng },
      map: map.value,
      icon: stopIcon,
      title: stop.name + (stop.code ? ` (${stop.code})` : ''),
      zIndex: 6,
    })
    routeStopMarkers.push(marker)
  }

  // Fit map to the shape
  if (routeShapePolylines.length && map.value) {
    const bounds = new google.maps.LatLngBounds()
    routeShapePolylines.forEach(p =>
      p.getPath().forEach(pt => bounds.extend(pt)),
    )
    map.value.fitBounds(bounds, 60)
  }
}

// Color per transit vehicle type — matches VehicleMarker colors
function stepColor(step: google.maps.DirectionsStep): string {
  if (step.travel_mode !== 'TRANSIT' || !step.transit) return '#3b82f6' // walking — blue
  switch (step.transit.line?.vehicle?.type) {
    case 'SUBWAY':                          return '#a855f7' // purple
    case 'HEAVY_RAIL':
    case 'COMMUTER_TRAIN':                  return '#f59e0b' // amber
    case 'LIGHT_RAIL':
    case 'TRAM':
    case 'MONORAIL':                        return '#22c55e' // green
    case 'FERRY':                           return '#0ea5e9' // cyan
    default:                               return '#f97316' // orange — bus
  }
}

function clearStepPolylines() {
  stepPolylines.forEach(p => p.setMap(null))
  stepPolylines = []
}

function drawStepPolylines(result: google.maps.DirectionsResult, routeIndex = 0) {
  clearStepPolylines()
  if (!map.value) return
  const route = result.routes[routeIndex]
  if (!route) return
  for (const leg of route.legs) {
      for (const step of leg.steps) {
        const isWalk = step.travel_mode === 'WALKING'
        const color  = stepColor(step)
        const polyline = new google.maps.Polyline({
          path: step.path,
          map: map.value,
          strokeColor:   color,
          strokeWeight:  isWalk ? 3 : 5,
          strokeOpacity: isWalk ? 0 : 0.9,
          // dashed line for walking segments
          ...(isWalk ? {
            icons: [{ icon: { path: 'M 0,-1 0,1', strokeOpacity: 0.7, scale: 3 }, offset: '0', repeat: '12px' }],
          } : {}),
        })
        stepPolylines.push(polyline)
      }
  }
}

onMounted(async () => {
  await loadGoogleMaps()
  if (!mapEl.value) return

  map.value = new google.maps.Map(mapEl.value, {
    center: mapStore.center,
    zoom: mapStore.zoom,
    mapTypeId: 'hybrid',
    renderingType: google.maps.RenderingType.RASTER,
    styles: mapStore.mapTypeId === 'roadmap' ? darkMapStyles : [],
    disableDefaultUI: false,
    zoomControl: true,
    mapTypeControl: false,
    streetViewControl: false,
    fullscreenControl: false,
  })

  transitLayer = new google.maps.TransitLayer()
  trafficLayer = new google.maps.TrafficLayer()
  bikingLayer = new google.maps.BicyclingLayer()

  directionsRenderer = new google.maps.DirectionsRenderer({
    suppressMarkers: false,
    suppressPolylines: true, // we draw per-step colored polylines ourselves
  })
  directionsRenderer.setMap(map.value)

  // Fetch nearby stops whenever the map finishes panning/zooming
  map.value.addListener('idle', () => {
    const center = map.value?.getCenter()
    const zoom = map.value?.getZoom() ?? 0
    if (center && zoom >= 13) {
      mapStore.fetchNearbyStops(center.lat(), center.lng(), 600)
    } else {
      mapStore.nearbyStops = []
    }
  })

  mapReady.value = true
  mapStore.startPolling()

  // Load route lookup for filtering
  const lookup = await getRouteLookup()
  const shortNameMap = new Map<string, string>()
  lookup.forEach((info, routeId) => shortNameMap.set(routeId, info.shortName))
  routeMap.value = shortNameMap
})

onUnmounted(() => {
  mapStore.stopPolling()
  clearStepPolylines()
  clearRouteShape()
})

watch(
  () => mapStore.trackedRouteId,
  (id) => {
    if (id) drawRouteShape(id)
    else clearRouteShape()
  },
)

watch(
  () => mapStore.center,
  (c) => map.value?.panTo(c),
)

watch(
  () => mapStore.showTransitLayer,
  (show) => transitLayer?.setMap(show ? map.value : null),
)

watch(
  () => mapStore.showTrafficLayer,
  (show) => trafficLayer?.setMap(show ? map.value : null),
)

watch(
  () => mapStore.showBikingLayer,
  (show) => bikingLayer?.setMap(show ? map.value : null),
)

watch(
  () => mapStore.mapTypeId,
  (typeId) => {
    if (!map.value) return
    map.value.setMapTypeId(typeId)
    // Custom dark styles only apply on roadmap; clear them for other types
    map.value.setOptions({ styles: typeId === 'roadmap' ? darkMapStyles : [] })
  },
)

watch(
  () => routeStore.directionsResult,
  (result) => {
    // Auto-show planned vehicles when a direction search is done; hide all when cleared
    if (!result) {
      mapStore.showOnlyPlanned = false
    } else {
      mapStore.showOnlyPlanned = true
      // Exit route tracking mode when directions are active
      mapStore.trackedRouteId = null
      mapStore.trackedShortName = null
      clearRouteShape()
    }

    if (!directionsRenderer) return
    if (result) {
      directionsRenderer.setDirections(result)
      drawStepPolylines(result, routeStore.selectedRouteIndex)
      const bounds = result.routes[routeStore.selectedRouteIndex]?.bounds
      if (bounds && map.value) map.value.fitBounds(bounds)
    } else {
      directionsRenderer.setDirections({ routes: [] } as unknown as google.maps.DirectionsResult)
      clearStepPolylines()
    }
  },
)

watch(
  () => routeStore.selectedRouteIndex,
  (idx) => {
    const result = routeStore.directionsResult
    if (!result) return
    drawStepPolylines(result, idx)
    const bounds = result.routes[idx]?.bounds
    if (bounds && map.value) map.value.fitBounds(bounds)
  },
)

// Extract short names of transit lines in the planned trip
const plannedShortNames = computed<Set<string>>(() => {
  const result = routeStore.directionsResult
  if (!result) return new Set()
  const names = new Set<string>()
  for (const route of result.routes) {
    for (const leg of route.legs) {
      for (const step of leg.steps) {
        if (step.travel_mode === 'TRANSIT' && step.transit) {
          const sn = step.transit.line?.short_name
          if (sn) names.add(sn)
        }
      }
    }
  }
  return names
})

// Vehicles to render on the map
const displayedVehicles = computed(() => {
  let vehicles = mapStore.vehicles ?? []

  // Route tracking mode — show only vehicles on the tracked route
  if (mapStore.trackedRouteId) {
    const numericId = mapStore.trackedRouteId
    return vehicles.filter(v =>
      v.routeId === numericId ||
      v.routeId.endsWith('_' + numericId),
    )
  }

  // Hide all vehicles until the user searches for directions
  if (!routeStore.directionsResult) return []

  // Filter by vehicle type
  if (mapStore.vehicleTypeFilter !== 'ALL') {
    vehicles = vehicles.filter((v) => {
      const type = v.routeType ?? 'BUS'
      if (mapStore.vehicleTypeFilter === 'RAIL') return type === 'RAIL' || type === 'STREETCAR'
      return type === 'BUS' || type === 'FERRY'
    })
  }

  // Filter to planned trip vehicles only
  if (mapStore.showOnlyPlanned && plannedShortNames.value.size > 0) {
    vehicles = vehicles.filter((v) => {
      const shortName = routeMap.value.get(v.routeId)
      return shortName !== undefined && plannedShortNames.value.has(shortName)
    })
  }

  return vehicles
})

const darkMapStyles: google.maps.MapTypeStyle[] = [
  { elementType: 'geometry', stylers: [{ color: '#1e293b' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#94a3b8' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#1e293b' }] },
  { featureType: 'road', elementType: 'geometry', stylers: [{ color: '#334155' }] },
  { featureType: 'road.highway', elementType: 'geometry', stylers: [{ color: '#475569' }] },
  { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#0f2744' }] },
  { featureType: 'transit', elementType: 'geometry', stylers: [{ color: '#3b82f6' }] },
  { featureType: 'poi', stylers: [{ visibility: 'off' }] },
]
</script>

<style scoped>
.map-root {
  position: relative;
  width: 100%;
  height: 100%;
}

.map-canvas {
  width: 100%;
  height: 100%;
}

.map-overlay {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  background: rgba(15, 23, 42, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 0.6rem 0.85rem;
  display: flex;
  flex-direction: column;
  gap: 0.45rem;
  z-index: 10;
  backdrop-filter: blur(4px);
  overflow: visible;
}

.overlay-section-label {
  font-size: 0.7rem;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.1rem;
}

.map-type-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.3rem;
}

.map-type-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.15rem;
  padding: 0.35rem 0.4rem;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  color: #94a3b8;
  font-size: 0.72rem;
  cursor: pointer;
  transition: background 0.15s, color 0.15s, border-color 0.15s;
  white-space: nowrap;
}

.map-type-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #e2e8f0;
}

.map-type-btn.active {
  background: rgba(59, 130, 246, 0.25);
  border-color: #3b82f6;
  color: #93c5fd;
}

.map-type-icon {
  font-size: 1rem;
  line-height: 1;
}

.overlay-divider {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  margin: 0.3rem 0;
}

.overlay-option {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.82rem;
  color: #e2e8f0;
  cursor: pointer;
  white-space: nowrap;
  user-select: none;
}

.overlay-option.disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.overlay-option input[type='radio'],
.overlay-option input[type='checkbox'] {
  accent-color: #3b82f6;
  width: 14px;
  height: 14px;
  cursor: pointer;
}

.overlay-option.disabled input[type='radio'],
.overlay-option.disabled input[type='checkbox'] {
  cursor: not-allowed;
}

/* ── Color legend link + popup ─────────────────────────────────────────── */

.overlay-section-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.color-legend-link {
  font-size: 0.68rem;
  font-weight: 600;
  color: #60a5fa;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
  text-decoration: underline;
  text-underline-offset: 2px;
  transition: color 0.15s;
}

.color-legend-link:hover {
  color: #93c5fd;
}

.color-legend {
  position: absolute;
  top: 0.75rem;
  right: calc(100% + 0.5rem);
  background: rgba(15, 23, 42, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 8px;
  padding: 0.65rem 0.8rem;
  z-index: 20;
  backdrop-filter: blur(6px);
  min-width: 210px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.4);
}

.legend-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.5rem;
}

.legend-title {
  font-size: 0.72rem;
  font-weight: 700;
  color: #e2e8f0;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.legend-close {
  background: none;
  border: none;
  color: #64748b;
  font-size: 0.75rem;
  cursor: pointer;
  padding: 0;
  line-height: 1;
  transition: color 0.15s;
}

.legend-close:hover {
  color: #e2e8f0;
}

.legend-items {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.legend-swatch {
  width: 28px;
  height: 10px;
  border-radius: 3px;
  flex-shrink: 0;
}

.legend-label {
  font-size: 0.78rem;
  font-weight: 600;
  color: #e2e8f0;
  white-space: nowrap;
  min-width: 80px;
}

.legend-desc {
  font-size: 0.7rem;
  color: #64748b;
  white-space: nowrap;
}

/* Transition */
.legend-fade-enter-active,
.legend-fade-leave-active {
  transition: opacity 0.15s, transform 0.15s;
}
.legend-fade-enter-from,
.legend-fade-leave-to {
  opacity: 0;
  transform: translateX(6px);
}

.route-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
  margin-left: 0.2rem;
}

.pill {
  background: #3b82f6;
  color: #fff;
  font-size: 0.7rem;
  font-weight: 600;
  padding: 0.1rem 0.4rem;
  border-radius: 99px;
}
</style>
