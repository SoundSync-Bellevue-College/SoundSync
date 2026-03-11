<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import type { Stop } from '@/types/transit'

const props = defineProps<{
  stop: Stop
  map: google.maps.Map | null
}>()

const emit = defineEmits<{ click: [] }>()

let marker: google.maps.Marker | null = null

onMounted(() => {
  if (!props.map) return
  marker = new google.maps.Marker({
    position: { lat: props.stop.lat, lng: props.stop.lng },
    map: props.map,
    icon: {
      path: google.maps.SymbolPath.CIRCLE,
      scale: 5,
      fillColor: '#ffffff',
      fillOpacity: 1,
      strokeColor: '#3b82f6',
      strokeWeight: 2,
    },
    title: props.stop.name,
  })
  marker.addListener('click', () => emit('click'))
})

onUnmounted(() => {
  marker?.setMap(null)
  marker = null
})
</script>

<template></template>
