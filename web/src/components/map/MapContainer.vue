<template>
  <div class="map-root">
    <div ref="mapEl" class="map-canvas" />
    <LoadingSpinner v-if="!mapReady" overlay label="Loading map…" />

    <!-- Map controls overlay -->
    <div class="map-overlay">

      <!-- Map type -->
      <div class="overlay-section-label">Map type</div>
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
import { loadGoogleMaps } from '@/services/mapsService'
import { getRouteLookup } from '@/services/routeLookup'
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

onMounted(async () => {
  await loadGoogleMaps()
  if (!mapEl.value) return

  map.value = new google.maps.Map(mapEl.value, {
    center: mapStore.center,
    zoom: mapStore.zoom,
    mapTypeId: 'roadmap',
    renderingType: google.maps.RenderingType.RASTER,
    styles: darkMapStyles,
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
    polylineOptions: {
      strokeColor: '#9333ea',
      strokeWeight: 5,
      strokeOpacity: 0.85,
    },
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
})

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
    // When plan is cleared, revert to show all
    if (!result) mapStore.showOnlyPlanned = false

    if (!directionsRenderer) return
    if (result) {
      directionsRenderer.setDirections(result)
      const bounds = result.routes[0]?.bounds
      if (bounds && map.value) map.value.fitBounds(bounds)
    } else {
      directionsRenderer.setDirections({ routes: [] } as unknown as google.maps.DirectionsResult)
    }
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
