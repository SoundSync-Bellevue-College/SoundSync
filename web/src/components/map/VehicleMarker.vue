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

function buildIcon(label: string, color: string, textColor: string, bearing: number): google.maps.Icon {
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

async function makeIcon(vehicle: VehiclePosition): Promise<google.maps.Icon> {
  const lookup = await getRouteLookup()
  const info = lookup.get(vehicle.routeId)
  const label = info?.shortName ?? vehicle.routeId
  const color = info?.color ?? '#3b82f6'
  const textColor = info?.textColor ?? '#ffffff'
  return buildIcon(label, color, textColor, vehicle.bearing ?? 0)
}

onMounted(async () => {
  if (!props.map) return
  const icon = await makeIcon(props.vehicle)
  marker = new google.maps.Marker({
    position: { lat: props.vehicle.lat, lng: props.vehicle.lng },
    map: props.map,
    icon,
    title: `Route ${props.vehicle.routeId} — Vehicle ${props.vehicle.vehicleId}`,
  })
  marker.addListener('click', () => emit('click', props.vehicle))
})

onUnmounted(() => {
  marker?.setMap(null)
  marker = null
})

watch(
  () => props.vehicle,
  async (v) => {
    marker?.setPosition({ lat: v.lat, lng: v.lng })
    marker?.setIcon(await makeIcon(v))
  },
  { deep: true },
)
</script>

<template></template>
