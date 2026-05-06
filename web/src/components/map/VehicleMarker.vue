<script setup lang="ts">
/**
 * VehicleMarker — renders a Google Maps marker for a real-time vehicle.
 * This is a renderless component: it manages its own google.maps.Marker
 * lifecycle and emits clicks back to the parent.
 */
import { onMounted, onUnmounted, watch } from 'vue'
import type { VehiclePosition } from '@/types/transit'
import { getRouteLookup } from '@/services/routeLookup'

const props = defineProps<{
  vehicle: VehiclePosition
  map: google.maps.Map | null
}>()

const emit = defineEmits<{ click: [vehicle: VehiclePosition] }>()

let marker: google.maps.Marker | null = null
let alive = true // guards against ghost markers when unmounted during async icon build

function buildBusIcon(label: string, color: string, textColor: string, bearing: number): google.maps.Icon {
  const charWidth = 8
  const padX = 10
  const badgeW = Math.max(36, label.length * charWidth + padX * 2)
  const badgeH = 22
  const arrowH = 7
  const totalH = badgeH + arrowH
  const cx = badgeW / 2

  const svg = [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${badgeW}" height="${totalH}"`,
    ` style="transform-origin:${cx}px ${totalH}px;transform:rotate(${bearing}deg)">`,
    `<rect x="1" y="1" width="${badgeW - 2}" height="${badgeH - 2}" rx="4"`,
    ` fill="${color}" stroke="white" stroke-width="1.5"/>`,
    `<text x="${cx}" y="${badgeH / 2 + 1}" font-family="Arial,sans-serif"`,
    ` font-size="11" font-weight="bold" fill="${textColor}"`,
    ` text-anchor="middle" dominant-baseline="middle">${label}</text>`,
    `<polygon points="${cx - 5},${badgeH} ${cx + 5},${badgeH} ${cx},${totalH}" fill="${color}"/>`,
    `</svg>`,
  ].join('')

  return {
    url: `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`,
    anchor: new google.maps.Point(cx, totalH),
    scaledSize: new google.maps.Size(badgeW, totalH),
  }
}

function buildRailIcon(label: string, color: string, textColor: string): google.maps.Icon {
  const charWidth = 8
  const padX = 12
  const badgeW = Math.max(44, label.length * charWidth + padX * 2)
  const badgeH = 26
  const cx = badgeW / 2
  const cy = badgeH / 2

  // Diamond shape around the label
  const svg = [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${badgeW}" height="${badgeH}">`,
    `<polygon points="${cx},2 ${badgeW - 2},${cy} ${cx},${badgeH - 2} 2,${cy}"`,
    ` fill="${color}" stroke="white" stroke-width="2"/>`,
    `<text x="${cx}" y="${cy + 1}" font-family="Arial,sans-serif"`,
    ` font-size="10" font-weight="bold" fill="${textColor}"`,
    ` text-anchor="middle" dominant-baseline="middle">${label}</text>`,
    `</svg>`,
  ].join('')

  return {
    url: `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`,
    anchor: new google.maps.Point(cx, cy),
    scaledSize: new google.maps.Size(badgeW, badgeH),
  }
}

function buildFerryIcon(label: string, color: string, textColor: string): google.maps.Icon {
  const charWidth = 8
  const padX = 10
  const badgeW = Math.max(40, label.length * charWidth + padX * 2)
  const badgeH = 24
  const cx = badgeW / 2

  // Rounded pill shape
  const svg = [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${badgeW}" height="${badgeH}">`,
    `<rect x="1" y="1" width="${badgeW - 2}" height="${badgeH - 2}" rx="12"`,
    ` fill="${color}" stroke="white" stroke-width="2"/>`,
    `<text x="${cx}" y="${badgeH / 2 + 1}" font-family="Arial,sans-serif"`,
    ` font-size="10" font-weight="bold" fill="${textColor}"`,
    ` text-anchor="middle" dominant-baseline="middle">${label}</text>`,
    `</svg>`,
  ].join('')

  return {
    url: `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`,
    anchor: new google.maps.Point(cx, badgeH / 2),
    scaledSize: new google.maps.Size(badgeW, badgeH),
  }
}

// Returns a short vehicle suffix for differentiating buses on the same route.
// Uses the last 3 characters of the vehicleId (e.g. "9301" → "301", "L101" → "101").
function vehicleSuffix(vehicleId: string): string {
  const id = vehicleId.replace(/\D/g, '') // digits only
  return id.length > 0 ? id.slice(-3) : vehicleId.slice(-3)
}

async function makeIcon(vehicle: VehiclePosition): Promise<google.maps.Icon> {
  const lookup = await getRouteLookup()
  const info = lookup.get(vehicle.routeId)
  const routeName = info?.shortName ?? vehicle.routeId
  const suffix = vehicleSuffix(vehicle.vehicleId)
  const label = `${routeName}·${suffix}`

  const routeType = vehicle.routeType ?? (info?.routeType === 0 || info?.routeType === 1 || info?.routeType === 2 ? 'RAIL' : 'BUS')

  if (routeType === 'RAIL' || routeType === 'STREETCAR') {
    const color = info?.color ?? '#5C7BA2'
    const textColor = info?.textColor ?? '#ffffff'
    return buildRailIcon(label, color, textColor)
  }

  if (routeType === 'FERRY') {
    const color = info?.color ?? '#0ea5e9'
    const textColor = info?.textColor ?? '#ffffff'
    return buildFerryIcon(label, color, textColor)
  }

  const color = info?.color ?? '#3b82f6'
  const textColor = info?.textColor ?? '#ffffff'
  return buildBusIcon(label, color, textColor, vehicle.bearing ?? 0)
}

onMounted(async () => {
  if (!props.map) return
  const icon = await makeIcon(props.vehicle)
  if (!alive) return // unmounted while icon was loading — skip creating the marker
  marker = new google.maps.Marker({
    position: { lat: props.vehicle.lat, lng: props.vehicle.lng },
    map: props.map,
    icon,
    title: `Route ${props.vehicle.routeId} — Vehicle ${props.vehicle.vehicleId}`,
  })
  marker.addListener('click', () => emit('click', props.vehicle))
})

onUnmounted(() => {
  alive = false
  marker?.setMap(null)
  marker = null
})

watch(
  () => props.vehicle,
  async (v) => {
    marker?.setPosition({ lat: v.lat, lng: v.lng })
    const icon = await makeIcon(v)
    if (alive) marker?.setIcon(icon)
  },
  { deep: true },
)
</script>

<template></template>
