<template>
  <div class="search-panel">
    <h2 class="panel-title">Plan a Trip</h2>

    <!-- From field -->
    <div class="field">
      <label class="field-label">From</label>
      <div class="input-wrap">
        <span class="input-icon">📍</span>
        <input
          ref="originInputEl"
          class="field-input"
          type="text"
          :placeholder="locating ? 'Detecting location…' : 'Starting point…'"
          autocomplete="off"
        />
      </div>
    </div>

    <!-- Swap button -->
    <button class="btn-swap" title="Swap" @click="swapPlaces">⇅</button>

    <!-- To field -->
    <div class="field">
      <label class="field-label">To</label>
      <div class="input-wrap">
        <span class="input-icon">🏁</span>
        <input
          ref="destInputEl"
          class="field-input"
          type="text"
          placeholder="Destination…"
          autocomplete="off"
        />
      </div>
    </div>

    <!-- Time options -->
    <div class="time-section">
      <!-- Depart / Arrive toggle — hidden when Leave now is checked -->
      <div v-if="!leaveNow" class="time-toggle">
        <button
          class="toggle-btn"
          :class="{ active: timeType === 'depart' }"
          @click="timeType = 'depart'"
        >Depart at</button>
        <button
          class="toggle-btn"
          :class="{ active: timeType === 'arrive' }"
          @click="timeType = 'arrive'"
        >Arrive by</button>
      </div>

      <!-- Date + time row — hidden when Leave now is checked -->
      <div v-if="!leaveNow" class="datetime-row">
        <!-- Date selector -->
        <div class="date-pill" @click="openDatePicker" title="Select date">
          <span class="date-pill-text">{{ formattedDate }}</span>
          <span class="pill-arrow">▾</span>
          <!-- Native date input hidden beneath the pill; triggered by click -->
          <input
            ref="dateInputEl"
            class="hidden-date-input"
            type="date"
            v-model="selectedDate"
            :min="todayStr"
          />
        </div>

        <!-- Time selector -->
        <div class="time-pill">
          <select class="time-select" v-model="selectedHour" aria-label="Hour">
            <option v-for="h in hours" :key="h" :value="h">{{ h }}</option>
          </select>
          <span class="time-colon">:</span>
          <select class="time-select" v-model="selectedMinute" aria-label="Minute">
            <option v-for="m in minutes" :key="m" :value="m">{{ m }}</option>
          </select>
          <div class="ampm-toggle">
            <button
              class="ampm-btn"
              :class="{ active: selectedAmPm === 'AM' }"
              @click="selectedAmPm = 'AM'"
            >AM</button>
            <button
              class="ampm-btn"
              :class="{ active: selectedAmPm === 'PM' }"
              @click="selectedAmPm = 'PM'"
            >PM</button>
          </div>
        </div>
      </div>

      <!-- Leave now checkbox — always below the date/time inputs -->
      <label class="leave-now-label">
        <input type="checkbox" v-model="leaveNow" />
        Leave now
      </label>
    </div>

    <button class="btn-plan" :disabled="isPlanning" @click="planRoute">
      <span v-if="isPlanning">Planning…</span>
      <span v-else>Get Directions</span>
    </button>

    <p v-if="routeStore.planError" class="error-msg">{{ routeStore.planError }}</p>

    <RouteSummaryCard
      v-if="routeStore.directionsResult"
      :result="routeStore.directionsResult"
      @detail="showDetail = true"
    />

    <RouteDetailModal
      v-if="showDetail && routeStore.directionsResult"
      :result="routeStore.directionsResult"
      @close="showDetail = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouteStore } from '@/stores/routeStore'
import { useAuthStore } from '@/stores/authStore'
import { loadGoogleMaps } from '@/services/mapsService'
import RouteSummaryCard from './RouteSummaryCard.vue'
import RouteDetailModal from './RouteDetailModal.vue'

const routeStore = useRouteStore()
const auth = useAuthStore()
const isPlanning = ref(false)
const locating = ref(false)
const showDetail = ref(false)

const originInputEl = ref<HTMLInputElement | null>(null)
const destInputEl = ref<HTMLInputElement | null>(null)

// ── Time selection state ──────────────────────────────────────────────────────

type TimeType = 'depart' | 'arrive'
const timeType = ref<TimeType>('depart')
const leaveNow = ref(false)

// Date — default to today
const todayStr = new Date().toISOString().slice(0, 10)
const selectedDate = ref(todayStr)

// Time — initialize to next 15-min increment from now
function initTime(): { hour: string; minute: string; ampm: 'AM' | 'PM' } {
  const now = new Date()
  let h = now.getHours()
  let m = Math.ceil(now.getMinutes() / 15) * 15
  if (m === 60) { m = 0; h++ }
  if (h >= 24) h = 0
  const ampm: 'AM' | 'PM' = h >= 12 ? 'PM' : 'AM'
  const hour12 = h % 12 || 12
  return { hour: String(hour12), minute: String(m).padStart(2, '0'), ampm }
}

const { hour: initHour, minute: initMinute, ampm: initAmPm } = initTime()
const selectedHour   = ref(initHour)
const selectedMinute = ref(initMinute)
const selectedAmPm   = ref<'AM' | 'PM'>(initAmPm)

const hours   = Array.from({ length: 12 }, (_, i) => String(i + 1))
const minutes = ['00', '05', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55']

const dateInputEl = ref<HTMLInputElement | null>(null)

function openDatePicker() {
  // showPicker() is supported in modern browsers; fallback to focus+click
  const el = dateInputEl.value
  if (!el) return
  if (typeof el.showPicker === 'function') {
    el.showPicker()
  } else {
    el.focus()
    el.click()
  }
}

// "Mon, Mar 10" — localised, no timezone shift
const formattedDate = computed(() => {
  const d = new Date(selectedDate.value + 'T00:00:00')
  return d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })
})

function buildTransitTime(): Date {
  if (leaveNow.value) return new Date()
  const d = new Date(selectedDate.value + 'T00:00:00')
  let h = parseInt(selectedHour.value, 10)
  if (selectedAmPm.value === 'PM' && h !== 12) h += 12
  if (selectedAmPm.value === 'AM' && h === 12) h = 0
  d.setHours(h, parseInt(selectedMinute.value, 10), 0, 0)
  return d
}

// ── Google Maps autocomplete setup ───────────────────────────────────────────

let originPlace: google.maps.places.PlaceResult | null = null
let destPlace:   google.maps.places.PlaceResult | null = null
let originAC:    google.maps.places.Autocomplete | null = null
let destAC:      google.maps.places.Autocomplete | null = null

const AC_OPTIONS: google.maps.places.AutocompleteOptions = {
  fields: ['geometry', 'name', 'formatted_address'],
  componentRestrictions: { country: 'us' },
}

onMounted(async () => {
  await loadGoogleMaps()

  if (originInputEl.value) {
    originAC = new google.maps.places.Autocomplete(originInputEl.value, AC_OPTIONS)
    originAC.addListener('place_changed', () => { originPlace = originAC!.getPlace() })
  }

  if (destInputEl.value) {
    destAC = new google.maps.places.Autocomplete(destInputEl.value, AC_OPTIONS)
    destAC.addListener('place_changed', () => { destPlace = destAC!.getPlace() })
  }

  // Pre-fill From with the user's current location if they haven't typed anything
  if ('geolocation' in navigator) {
    locating.value = true
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        locating.value = false
        // Only fill in if the user hasn't typed anything yet
        if (originInputEl.value?.value) return
        const latlng = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude)
        const geocoder = new google.maps.Geocoder()
        geocoder.geocode({ location: latlng }, (results, status) => {
          if (status !== 'OK' || !results?.length) return
          // Skip pure plus-codes; prefer street-level results
          const best = results.find(r => r.types.includes('street_address') || r.types.includes('premise')) ?? results[0]
          if (originInputEl.value && !originInputEl.value.value) {
            originInputEl.value.value = best.formatted_address
            originPlace = {
              geometry: { location: latlng },
              formatted_address: best.formatted_address,
              name: best.formatted_address,
            }
          }
        })
      },
      () => { locating.value = false }, // permission denied or error — silently skip
      { timeout: 8000, maximumAge: 60000 },
    )
  }
})

function swapPlaces() {
  if (!originInputEl.value || !destInputEl.value) return
  const tmp = originInputEl.value.value
  originInputEl.value.value = destInputEl.value.value
  destInputEl.value.value = tmp
  const tmpPlace = originPlace
  originPlace = destPlace
  destPlace = tmpPlace
}

function planRoute() {
  if (!originPlace?.geometry?.location || !destPlace?.geometry?.location) {
    routeStore.setError('Please select both locations from the autocomplete dropdown.')
    return
  }

  isPlanning.value = true
  routeStore.clearPlan()

  const transitTime = buildTransitTime()
  const transitOptions: google.maps.TransitOptions = {
    modes: [google.maps.TransitMode.BUS, google.maps.TransitMode.RAIL],
    routingPreference: google.maps.TransitRoutePreference.FEWER_TRANSFERS,
    ...(timeType.value === 'depart'
      ? { departureTime: transitTime }
      : { arrivalTime: transitTime }),
  }

  const service = new google.maps.DirectionsService()
  service.route(
    {
      origin: originPlace.geometry.location,
      destination: destPlace.geometry.location,
      travelMode: google.maps.TravelMode.TRANSIT,
      transitOptions,
      unitSystem: auth.distanceUnit === 'km'
        ? google.maps.UnitSystem.METRIC
        : google.maps.UnitSystem.IMPERIAL,
    },
    (result, status) => {
      isPlanning.value = false
      if (status === google.maps.DirectionsStatus.OK && result) {
        routeStore.setDirectionsResult(result)
      } else {
        routeStore.setError(
          status === google.maps.DirectionsStatus.ZERO_RESULTS
            ? 'No transit route found between these locations.'
            : 'Could not get directions. Please try again.',
        )
      }
    },
  )
}
</script>

<style scoped>
.search-panel {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  box-shadow: var(--shadow-md);
  min-width: 340px;
}

.panel-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.field-label {
  font-size: 0.7rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 0.55rem;
  font-size: 0.85rem;
  pointer-events: none;
}

.field-input {
  width: 100%;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.5rem 0.75rem 0.5rem 2rem;
  color: var(--color-text);
  font-size: 0.875rem;
  transition: border-color 0.15s;
}

.field-input:focus {
  outline: none;
  border-color: var(--color-primary);
}

.btn-swap {
  align-self: flex-end;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0.2rem 0.6rem;
  font-size: 1rem;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: color 0.15s;
  margin-top: -0.2rem;
}

.btn-swap:hover {
  color: var(--color-primary);
}

/* ── Time section ────────────────────────────────────────────────────────── */

.time-section {
  display: flex;
  flex-direction: column;
  gap: 0.45rem;
}

/* Depart / Arrive toggle */
.time-toggle {
  display: flex;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.toggle-btn {
  flex: 1;
  padding: 0.35rem 0.5rem;
  font-size: 0.8rem;
  font-weight: 500;
  background: var(--color-bg);
  color: var(--color-text-muted);
  border: none;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
}

.toggle-btn.active {
  background: var(--color-primary);
  color: #fff;
}

/* Date + time pill row */
.datetime-row {
  display: flex;
  gap: 0.4rem;
  align-items: center;
}

/* ── Date pill ── */
.date-pill {
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.38rem 0.6rem;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: border-color 0.15s;
  white-space: nowrap;
  flex-shrink: 0;
}

.date-pill:hover {
  border-color: var(--color-primary);
}

.date-pill-text {
  font-size: 0.82rem;
  font-weight: 500;
  color: var(--color-text);
}

.pill-arrow {
  font-size: 0.65rem;
  color: var(--color-text-muted);
  line-height: 1;
}

/* Hidden native date input that sits over the pill to capture the picker */
.hidden-date-input {
  position: absolute;
  inset: 0;
  opacity: 0;
  width: 100%;
  height: 100%;
  cursor: pointer;
  /* Keep it in the tab order but visually invisible */
  border: none;
  padding: 0;
  margin: 0;
}

/* ── Time pill ── */
.time-pill {
  display: flex;
  align-items: center;
  gap: 0.15rem;
  padding: 0.3rem 0.45rem;
  background: #1e293b;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  flex: 1;
}

.time-select {
  background: #1e293b;
  border: none;
  color: #f1f5f9;
  font-size: 0.82rem;
  font-weight: 500;
  cursor: pointer;
  appearance: none;
  -webkit-appearance: none;
  text-align: center;
  width: 2rem;
  padding: 0;
}

.time-select:focus {
  outline: none;
}

.time-select option {
  background: #1e293b;
  color: #f1f5f9;
}

.time-colon {
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--color-text);
  line-height: 1;
  margin: 0 0.05rem;
}

/* AM / PM micro toggle */
.ampm-toggle {
  display: flex;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  overflow: hidden;
  margin-left: 0.3rem;
}

.ampm-btn {
  padding: 0.15rem 0.35rem;
  font-size: 0.72rem;
  font-weight: 600;
  background: var(--color-bg);
  color: var(--color-text-muted);
  border: none;
  cursor: pointer;
  transition: background 0.12s, color 0.12s;
  letter-spacing: 0.02em;
}

.ampm-btn.active {
  background: var(--color-primary);
  color: #fff;
}

/* Leave now checkbox */
.leave-now-label {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.8rem;
  color: var(--color-text-muted);
  cursor: pointer;
  user-select: none;
}

/* ── Plan button ─────────────────────────────────────────────────────────── */

.btn-plan {
  background: var(--color-primary);
  color: #fff;
  padding: 0.6rem;
  border-radius: var(--radius-sm);
  font-size: 0.9rem;
  font-weight: 500;
  transition: background 0.15s;
  margin-top: 0.15rem;
}

.btn-plan:hover:not(:disabled) {
  background: var(--color-primary-hover);
}

.btn-plan:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error-msg {
  font-size: 0.8rem;
  color: var(--color-danger);
}
</style>
