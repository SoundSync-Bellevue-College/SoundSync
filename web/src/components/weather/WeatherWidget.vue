<template>
  <div class="weather-widget">
    <!-- Header row -->
    <div class="weather-header">
      <span class="weather-title">Hourly Forecast</span>
      <span v-if="store.hourly" class="weather-city">{{ store.hourly.cityName }}</span>
      <span v-if="store.locationGranted === false" class="weather-location-note">(Seattle default)</span>
    </div>

    <!-- Loading -->
    <LoadingSpinner v-if="store.isLoading" size="20px" />

    <!-- Error -->
    <p v-else-if="store.error" class="weather-err">{{ store.error }}</p>

    <!-- Horizontal hourly scroll -->
    <div
      v-else-if="store.hourly"
      ref="scrollEl"
      class="hourly-scroll"
      @wheel.prevent="onWheel"
    >
      <div
        v-for="period in store.hourly.periods"
        :key="period.number"
        class="hourly-card"
        :class="cardClass(period.shortForecast, period.isDaytime)"
      >
        <span class="hourly-time">{{ formatHour(period.startTime) }}</span>
        <span class="hourly-emoji">{{ weatherEmoji(period.shortForecast, period.isDaytime) }}</span>
        <span class="hourly-temp">{{ displayTemp(period.temperature) }}</span>
        <span class="hourly-desc">{{ period.shortForecast }}</span>
        <span class="hourly-wind">💨 {{ period.windSpeed }}</span>
      </div>
    </div>

    <span v-else class="weather-err">—</span>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useWeatherStore } from '@/stores/weatherStore'
import { useAuthStore } from '@/stores/authStore'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'

const store = useWeatherStore()
const auth = useAuthStore()

function displayTemp(tempF: number): string {
  if (auth.tempUnit === 'C') return Math.round((tempF - 32) * 5 / 9) + '°C'
  return Math.round(tempF) + '°F'
}
const scrollEl = ref<HTMLElement | null>(null)

function onWheel(e: WheelEvent) {
  if (scrollEl.value) {
    scrollEl.value.scrollLeft += e.deltaY
  }
}

function formatHour(iso: string): string {
  const d = new Date(iso)
  return d.toLocaleTimeString([], { hour: 'numeric', hour12: true })
}

type RainLevel = 'drizzle' | 'light' | 'moderate' | 'heavy' | 'storm' | null

function rainLevel(f: string): RainLevel {
  if (f.includes('thunder') || f.includes('storm'))                          return 'storm'
  if (f.includes('heavy rain') || f.includes('heavy shower'))                return 'heavy'
  if (f.includes('rain') && (f.includes('slight') || f.includes('chance'))) return 'light'
  if (f.includes('drizzle'))                                                 return 'drizzle'
  if (f.includes('rain') || f.includes('shower') || f.includes('sleet'))    return 'moderate'
  return null
}

function weatherEmoji(forecast: string, isDaytime: boolean): string {
  const f = forecast.toLowerCase()
  const rain = rainLevel(f)
  if (rain === 'storm')    return '⛈️'
  if (rain === 'heavy')    return '🌊'
  if (rain === 'moderate') return '🌧️'
  if (rain === 'light')    return '🌦️'
  if (rain === 'drizzle')  return '🌂'
  if (f.includes('blizzard'))                                                return '🌨️'
  if (f.includes('snow') || f.includes('flurr'))                             return '❄️'
  if (f.includes('freezing'))                                                return '🧊'
  if (f.includes('fog') || f.includes('haz'))                                return '🌫️'
  if (f.includes('wind') || f.includes('breezy') || f.includes('blustery')) return '💨'
  if (f.includes('mostly sunny') || f.includes('mostly clear'))              return isDaytime ? '🌤️' : '🌙'
  if (f.includes('partly') || f.includes('partial'))                         return isDaytime ? '⛅' : '🌛'
  if (f.includes('mostly cloudy') || f.includes('overcast'))                 return '☁️'
  if (f.includes('cloud'))                                                   return isDaytime ? '🌥️' : '☁️'
  if (f.includes('sunny') || f.includes('clear'))                            return isDaytime ? '☀️' : '🌙'
  return isDaytime ? '🌤️' : '🌙'
}

function cardClass(forecast: string, isDaytime: boolean): string {
  const f = forecast.toLowerCase()
  const rain = rainLevel(f)
  if (rain === 'storm')    return 'card-storm'
  if (rain === 'heavy')    return 'card-rain-heavy'
  if (rain === 'moderate') return 'card-rain-moderate'
  if (rain === 'light')    return 'card-rain-light'
  if (rain === 'drizzle')  return 'card-drizzle'
  if (f.includes('snow') || f.includes('blizzard') || f.includes('flurr')) return 'card-snow'
  if (f.includes('freezing'))                                                return 'card-ice'
  if (f.includes('fog') || f.includes('haz'))                                return 'card-fog'
  if (f.includes('cloudy') || f.includes('overcast'))                        return 'card-cloudy'
  if (f.includes('partly') || f.includes('mostly sunny') || f.includes('mostly clear')) return 'card-partly'
  if (f.includes('sunny') || f.includes('clear'))                            return isDaytime ? 'card-sunny' : 'card-night'
  return isDaytime ? 'card-partly' : 'card-night'
}

onMounted(() => {
  store.requestLocationAndFetch()
})
</script>

<style scoped>
.weather-widget {
  background: var(--color-surface);
  border-radius: var(--radius-sm);
  padding: 0.65rem 0.75rem;
  width: 100%;
}

.weather-header {
  display: flex;
  align-items: baseline;
  gap: 0.4rem;
  margin-bottom: 0.6rem;
}

.weather-title {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text);
}

.weather-city {
  font-size: 0.7rem;
  color: var(--color-text-muted);
}

.weather-location-note {
  font-size: 0.65rem;
  color: var(--color-text-muted);
  font-style: italic;
}

/* Horizontal scroll container */
.hourly-scroll {
  display: flex;
  flex-direction: row;
  gap: 0.5rem;
  overflow-x: auto;
  overflow-y: hidden;
  padding-bottom: 0.4rem;
  scrollbar-width: thin;
  scrollbar-color: rgba(0, 0, 0, 0.18) transparent;
  /* prevent the vertical scroll from propagating to the sidebar */
  overscroll-behavior-x: contain;
}

.hourly-scroll::-webkit-scrollbar {
  height: 4px;
}
.hourly-scroll::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.18);
  border-radius: 2px;
}

/* Individual hour card */
.hourly-card {
  flex: 0 0 72px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.22rem;
  padding: 0.5rem 0.3rem;
  border-radius: 10px;
  font-size: 0.7rem;
  color: #fff;
  text-align: center;
  cursor: default;
  transition: transform 0.15s;
}

.hourly-card:hover {
  transform: translateY(-2px);
}

.hourly-time {
  font-size: 0.65rem;
  opacity: 0.9;
  white-space: nowrap;
}

.hourly-emoji {
  font-size: 1.6rem;
  line-height: 1;
}

.hourly-temp {
  font-size: 0.85rem;
  font-weight: 700;
}

.hourly-desc {
  font-size: 0.6rem;
  opacity: 0.88;
  line-height: 1.2;
  max-width: 68px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.hourly-wind {
  font-size: 0.6rem;
  opacity: 0.8;
  white-space: nowrap;
}

/* ── Card color themes ── */

/* Rain intensity — light → dark blue as rain gets heavier */
.card-drizzle      { background: linear-gradient(160deg, #89c4e1, #6a9fb5); }
.card-rain-light   { background: linear-gradient(160deg, #5b8fa8, #3d6b82); }
.card-rain-moderate{ background: linear-gradient(160deg, #4b79a1, #283e51); }
.card-rain-heavy   { background: linear-gradient(160deg, #1c3b5a, #0a1a2e); }
.card-storm        { background: linear-gradient(160deg, #373b44, #4286f4); }

/* Snow / ice */
.card-snow { background: linear-gradient(160deg, #83a4d4, #b6fbff); color: #1e3a5f; }
.card-ice  { background: linear-gradient(160deg, #a8d8ea, #d6f0f8); color: #1e3a5f; }

/* Clear / sun */
.card-sunny  { background: linear-gradient(160deg, #f7b733, #fc4a1a); }
.card-partly { background: linear-gradient(160deg, #56ccf2, #2f80ed); }
.card-night  { background: linear-gradient(160deg, #1a1a2e, #16213e); }

/* Overcast */
.card-cloudy { background: linear-gradient(160deg, #757f9a, #d7dde8); color: #2a2a3d; }
.card-fog    { background: linear-gradient(160deg, #a8a8a8, #d3d3d3); color: #333; }

.weather-err {
  font-size: 0.8rem;
  color: var(--color-text-muted);
}
</style>
