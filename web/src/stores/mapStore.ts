import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { VehiclePosition, LatLng } from '@/types/transit'
import { transitService } from '@/services/transitService'

const POLL_INTERVAL_MS = 15_000

export const useMapStore = defineStore('map', () => {
  const vehicles = ref<VehiclePosition[]>([])
  const center = ref<LatLng>({ lat: 47.6062, lng: -122.3321 }) // Seattle
  const zoom = ref(12)
  const selectedVehicleId = ref<string | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  const showOnlyPlanned = ref(false)

  let pollTimer: ReturnType<typeof setInterval> | null = null

  async function fetchVehicles() {
    try {
      isLoading.value = true
      error.value = null
      vehicles.value = await transitService.getVehicles()
    } catch (e) {
      error.value = 'Failed to load vehicle positions'
      console.error(e)
    } finally {
      isLoading.value = false
    }
  }

  function startPolling() {
    fetchVehicles()
    pollTimer = setInterval(fetchVehicles, POLL_INTERVAL_MS)
  }

  function stopPolling() {
    if (pollTimer !== null) {
      clearInterval(pollTimer)
      pollTimer = null
    }
  }

  function selectVehicle(vehicleId: string | null) {
    selectedVehicleId.value = vehicleId
  }

  function setCenter(latLng: LatLng, newZoom?: number) {
    center.value = latLng
    if (newZoom !== undefined) zoom.value = newZoom
  }

  return {
    vehicles,
    center,
    zoom,
    selectedVehicleId,
    isLoading,
    error,
    showOnlyPlanned,
    fetchVehicles,
    startPolling,
    stopPolling,
    selectVehicle,
    setCenter,
  }
})
