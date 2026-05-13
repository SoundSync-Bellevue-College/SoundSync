import { defineStore } from 'pinia'
import { ref, shallowRef } from 'vue'
import type { FavoriteRoute, CreateFavoritePayload } from '@/types/user'
import { routeService } from '@/services/routeService'

export const useRouteStore = defineStore('route', () => {
  // shallowRef so Vue doesn't try to deeply proxy the Google Maps object
  const directionsResult = shallowRef<google.maps.DirectionsResult | null>(null)
  const selectedRouteIndex = ref(0)
  const favorites = ref<FavoriteRoute[]>([])
  const planError = ref<string | null>(null)

  function setDirectionsResult(result: google.maps.DirectionsResult | null) {
    directionsResult.value = result
    selectedRouteIndex.value = 0
    planError.value = null
  }

  function setError(msg: string) {
    planError.value = msg
    directionsResult.value = null
  }

  function clearPlan() {
    directionsResult.value = null
    selectedRouteIndex.value = 0
    planError.value = null
  }

  async function loadFavorites() {
    favorites.value = await routeService.getFavorites()
  }

  async function addFavorite(payload: CreateFavoritePayload) {
    const created = await routeService.createFavorite(payload)
    favorites.value.unshift(created)
    return created
  }

  async function removeFavorite(id: string) {
    await routeService.deleteFavorite(id)
    favorites.value = favorites.value.filter((f) => f._id !== id)
  }

  return {
    directionsResult,
    selectedRouteIndex,
    favorites,
    planError,
    setDirectionsResult,
    setError,
    clearPlan,
    loadFavorites,
    addFavorite,
    removeFavorite,
  }
})
