import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { WeatherData, HourlyForecast } from '@/types/weather'
import { weatherService } from '@/services/weatherService'

const SEATTLE = { lat: 47.6062, lng: -122.3321 }

export const useWeatherStore = defineStore('weather', () => {
  const weather = ref<WeatherData | null>(null)
  const hourly = ref<HourlyForecast | null>(null)
  const userLat = ref<number>(SEATTLE.lat)
  const userLng = ref<number>(SEATTLE.lng)
  const locationGranted = ref<boolean | null>(null) // null = not asked yet
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  async function fetchWeather(lat: number, lng: number) {
    try {
      isLoading.value = true
      error.value = null
      weather.value = await weatherService.getWeather(lat, lng)
    } catch (e) {
      error.value = 'Failed to load weather'
      console.error(e)
    } finally {
      isLoading.value = false
    }
  }

  async function fetchHourly(lat: number, lng: number) {
    try {
      isLoading.value = true
      error.value = null
      hourly.value = await weatherService.getHourlyForecast(lat, lng)
    } catch (e) {
      error.value = 'Failed to load hourly forecast'
      console.error(e)
    } finally {
      isLoading.value = false
    }
  }

  function requestLocationAndFetch() {
    if (!navigator.geolocation) {
      locationGranted.value = false
      fetchHourly(SEATTLE.lat, SEATTLE.lng)
      return
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        locationGranted.value = true
        userLat.value = pos.coords.latitude
        userLng.value = pos.coords.longitude
        fetchHourly(userLat.value, userLng.value)
      },
      () => {
        locationGranted.value = false
        fetchHourly(SEATTLE.lat, SEATTLE.lng)
      },
      { timeout: 8000, maximumAge: 300_000 },
    )
  }

  return {
    weather,
    hourly,
    userLat,
    userLng,
    locationGranted,
    isLoading,
    error,
    fetchWeather,
    fetchHourly,
    requestLocationAndFetch,
  }
})
