<script setup lang="ts">
import { onMounted, onUnmounted, watch } from 'vue'

const props = defineProps<{
  path: google.maps.LatLngLiteral[]
  map: google.maps.Map | null
  color?: string
  weight?: number
}>()

let polyline: google.maps.Polyline | null = null

onMounted(() => {
  if (!props.map) return
  polyline = new google.maps.Polyline({
    path: props.path,
    map: props.map,
    strokeColor: props.color ?? '#3b82f6',
    strokeWeight: props.weight ?? 4,
    strokeOpacity: 0.85,
  })
})

onUnmounted(() => {
  polyline?.setMap(null)
  polyline = null
})

watch(
  () => props.path,
  (p) => polyline?.setPath(p),
)
</script>

<template></template>
