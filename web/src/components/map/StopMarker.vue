<script setup lang="ts">
import { onMounted, onUnmounted, watch } from 'vue'
import type { Stop } from '@/types/transit'

const props = defineProps<{
  stop: Stop
  map: google.maps.Map | null
  hasAlert?: boolean
}>()

const emit = defineEmits<{ click: [] }>()

let marker: google.maps.Marker | null = null

function getMarkerIcon(hasAlert: boolean = false) {
  return {
    path: google.maps.SymbolPath.CIRCLE,
    scale: 5,
    fillColor: '#ffffff',
    fillOpacity: 1,
    strokeColor: hasAlert ? '#f59e0b' : '#3b82f6',
    strokeWeight: 2,
  }
}

onMounted(() => {
  if (!props.map) return
  marker = new google.maps.Marker({
    position: { lat: props.stop.lat, lng: props.stop.lng },
    map: props.map,
    icon: getMarkerIcon(props.hasAlert),
    title: props.stop.name,
  })
  marker.addListener('click', () => emit('click'))
})

watch(() => props.hasAlert, (newHasAlert) => {
  if (marker) {
    marker.setIcon(getMarkerIcon(newHasAlert))
  }
})

onUnmounted(() => {
  marker?.setMap(null)
  marker = null
})
</script>

<template></template>
