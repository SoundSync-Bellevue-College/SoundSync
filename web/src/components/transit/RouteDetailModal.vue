<template>
  <Teleport to="body">
    <div class="modal-backdrop" @click.self="$emit('close')">
      <div class="modal" role="dialog" aria-modal="true" aria-label="Route details">

        <!-- Header -->
        <div class="modal-header">
          <div class="modal-title-block">
            <h2 class="modal-title">Route Details</h2>
            <p class="modal-subtitle">
              {{ leg.start_address?.split(',')[0] }}
              <span class="arrow">→</span>
              {{ leg.end_address?.split(',')[0] }}
              <span class="dot">·</span>
              <strong>{{ leg.duration?.text }}</strong>
            </p>
          </div>
          <button class="btn-close" @click="$emit('close')" aria-label="Close">✕</button>
        </div>

        <!-- Timeline -->
        <div class="timeline">

          <!-- Departure pin -->
          <div class="tl-row tl-pin">
            <div class="tl-time">{{ leg.departure_time?.text }}</div>
            <div class="tl-dot origin"></div>
            <div class="tl-content tl-address">{{ leg.start_address }}</div>
          </div>

          <template v-for="(step, i) in leg.steps" :key="i">

            <!-- ── Walking step ── -->
            <template v-if="step.travel_mode === 'WALKING'">
              <div class="tl-row">
                <div class="tl-time"></div>
                <div class="tl-line walk-line"></div>
                <div class="tl-content walk-content">
                  <div class="step-header">
                    <span class="mode-badge walk">🚶 Walk</span>
                    <span class="step-meta">{{ step.distance?.text }} · {{ step.duration?.text }}</span>
                    <!-- Weather chip for this walk segment -->
                    <span v-if="stepWeathers.get(i)" class="weather-chip">
                      <span class="wx-icon">{{ weatherEmoji(stepWeathers.get(i)!.shortForecast) }}</span>
                      <span class="wx-temp">{{ displayTemp(stepWeathers.get(i)!.temperature) }}</span>
                      <span class="wx-desc">{{ stepWeathers.get(i)!.shortForecast }}</span>
                      <span class="wx-wind">{{ stepWeathers.get(i)!.windSpeed }}</span>
                    </span>
                    <span v-else-if="loadingWeather" class="weather-chip weather-loading">
                      Loading weather…
                    </span>
                  </div>
                  <!-- Sub-steps (turn-by-turn) -->
                  <ol v-if="step.steps?.length" class="substeps">
                    <li
                      v-for="(sub, j) in step.steps"
                      :key="j"
                      class="substep"
                      v-html="sub.instructions"
                    ></li>
                  </ol>
                  <p v-else class="step-instruction" v-html="step.instructions"></p>
                </div>
              </div>
            </template>

            <!-- ── Transit step ── -->
            <template v-else-if="step.travel_mode === 'TRANSIT' && step.transit">
              <!-- Board stop -->
              <div class="tl-row tl-pin">
                <div class="tl-time">{{ step.transit.departure_time?.text }}</div>
                <div class="tl-dot stop"></div>
                <div class="tl-content tl-stop-name">{{ step.transit.departure_stop?.name }}</div>
              </div>
              <!-- Transit segment -->
              <div class="tl-row">
                <div class="tl-time"></div>
                <div
                  class="tl-line transit-line"
                  :style="{ borderColor: step.transit.line?.color ?? '#3b82f6' }"
                ></div>
                <div class="tl-content transit-content">
                  <div class="transit-top">
                    <span class="line-badge" :style="lineBadgeStyle(step.transit)">
                      {{ transitIcon(step.transit) }}
                      {{ step.transit.line?.short_name || step.transit.line?.name }}
                    </span>
                    <span v-if="step.transit.headsign" class="headsign">
                      toward {{ step.transit.headsign }}
                    </span>
                  </div>
                  <div class="transit-details">
                    <span>{{ step.transit.num_stops }} stop{{ step.transit.num_stops === 1 ? '' : 's' }}</span>
                    <span class="dot">·</span>
                    <span>{{ step.duration?.text }}</span>
                    <template v-if="step.transit.line?.agencies?.[0]">
                      <span class="dot">·</span>
                      <span class="agency">{{ step.transit.line.agencies[0].name }}</span>
                    </template>
                  </div>
                </div>
              </div>
              <!-- Alight stop -->
              <div class="tl-row tl-pin">
                <div class="tl-time">{{ step.transit.arrival_time?.text }}</div>
                <div class="tl-dot stop"></div>
                <div class="tl-content tl-stop-name">{{ step.transit.arrival_stop?.name }}</div>
              </div>
            </template>

          </template>

          <!-- Arrival pin -->
          <div class="tl-row tl-pin">
            <div class="tl-time">{{ leg.arrival_time?.text }}</div>
            <div class="tl-dot dest"></div>
            <div class="tl-content tl-address">{{ leg.end_address }}</div>
          </div>
        </div>

        <!-- Footer: fare -->
        <div v-if="result.routes[0]?.fare" class="modal-footer">
          <span class="fare-label">Estimated fare</span>
          <span class="fare-value">{{ result.routes[0].fare?.currency }} {{ result.routes[0].fare?.value }}</span>
        </div>

      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { weatherService } from '@/services/weatherService'
import { useAuthStore } from '@/stores/authStore'
import type { HourlyPeriod } from '@/types/weather'

const auth = useAuthStore()

function displayTemp(tempF: number): string {
  if (auth.tempUnit === 'C') return Math.round((tempF - 32) * 5 / 9) + '°C'
  return tempF + '°F'
}

const props = defineProps<{
  result: google.maps.DirectionsResult
}>()

defineEmits<{ close: [] }>()

const leg = computed(() => props.result.routes[0].legs[0])

// ── Weather per walk step (keyed by step index) ───────────────────────────────

const stepWeathers = ref(new Map<number, HourlyPeriod>())
const loadingWeather = ref(false)

onMounted(async () => {
  const l = leg.value
  // departure_time.value is Unix seconds; fall back to now
  const departureValue = l.departure_time?.value

  const baseMs =
    typeof departureValue === 'number'
      ? departureValue * 1000
      : Date.now()

let elapsedMs = 0


  // Collect walk steps with their computed absolute start time + coordinates
  const walkFetches: Array<{ index: number; lat: number; lng: number; timeMs: number }> = []

  for (let i = 0; i < l.steps.length; i++) {
    const step = l.steps[i]
    const stepTimeMs = baseMs + elapsedMs
    elapsedMs += (step.duration?.value ?? 0) * 1000

    if (step.travel_mode !== 'WALKING') continue

    const loc = step.start_location
    walkFetches.push({
      index: i,
      lat: typeof loc.lat === 'function' ? loc.lat() : (loc.lat as unknown as number),
      lng: typeof loc.lng === 'function' ? loc.lng() : (loc.lng as unknown as number),
      timeMs: stepTimeMs,
    })
  }

  if (!walkFetches.length) return

  loadingWeather.value = true
  await Promise.all(
    walkFetches.map(async ({ index, lat, lng, timeMs }) => {
      try {
        const forecast = await weatherService.getHourlyForecast(lat, lng)
        const period = matchPeriod(forecast.periods, new Date(timeMs))
        if (period) stepWeathers.value.set(index, period)
      } catch {
        // silently skip — weather is supplemental info
      }
    }),
  )
  loadingWeather.value = false
})

/** Find the hourly period whose 1-hour window contains `time`; fallback to first. */
function matchPeriod(periods: HourlyPeriod[], time: Date): HourlyPeriod | null {
  for (const p of periods) {
    const start = new Date(p.startTime)
    const end   = new Date(start.getTime() + 3_600_000)
    if (time >= start && time < end) return p
  }
  return periods[0] ?? null
}

/** Map a short forecast string to a representative emoji. */
function weatherEmoji(forecast: string): string {
  const f = forecast.toLowerCase()
  if (f.includes('thunder'))                                return '⛈️'
  if (f.includes('blizzard') || f.includes('heavy snow'))  return '🌨️'
  if (f.includes('snow') || f.includes('flurr'))           return '❄️'
  if (f.includes('sleet') || f.includes('freezing rain'))  return '🌨️'
  if (f.includes('rain') || f.includes('shower') || f.includes('drizzle')) return '🌧️'
  if (f.includes('fog') || f.includes('mist') || f.includes('haze'))       return '🌫️'
  if (f.includes('mostly cloudy') || f.includes('overcast'))               return '☁️'
  if (f.includes('partly cloudy') || f.includes('partly sunny'))           return '⛅'
  if (f.includes('mostly sunny') || f.includes('mostly clear'))            return '🌤️'
  if (f.includes('sunny') || f.includes('clear'))                          return '☀️'
  return '🌡️'
}

function transitIcon(transit: google.maps.TransitDetails): string {
  const type = transit.line?.vehicle?.type
  if (type === 'SUBWAY' || type === 'METRO_RAIL' || type === 'TRAM') return '🚇'
  if (type === 'RAIL' || type === 'HEAVY_RAIL' || type === 'COMMUTER_TRAIN') return '🚆'
  if (type === 'FERRY') return '⛴️'
  return '🚌'
}

function lineBadgeStyle(transit: google.maps.TransitDetails): Record<string, string> {
  return {
    background: transit.line?.color ?? '#1d4ed8',
    color: transit.line?.text_color ?? '#ffffff',
  }
}
</script>

<style scoped>
/* ── Backdrop ── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

/* ── Modal shell ── */
.modal {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  width: 100%;
  max-width: 520px;
  max-height: 85vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* ── Header ── */
.modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  padding: 1.1rem 1.25rem 0.9rem;
  border-bottom: 1px solid var(--color-border);
  flex-shrink: 0;
}

.modal-title {
  font-size: 1rem;
  font-weight: 700;
  color: var(--color-text);
  margin: 0 0 0.2rem;
}

.modal-subtitle {
  font-size: 0.8rem;
  color: var(--color-text-muted);
  margin: 0;
}

.modal-subtitle .arrow { margin: 0 0.25rem; color: var(--color-primary); }
.modal-subtitle .dot   { margin: 0 0.3rem; opacity: 0.4; }

.btn-close {
  background: none;
  border: none;
  font-size: 0.95rem;
  color: var(--color-text-muted);
  cursor: pointer;
  padding: 0.1rem 0.3rem;
  line-height: 1;
  transition: color 0.15s;
  flex-shrink: 0;
  margin-left: 0.5rem;
}
.btn-close:hover { color: var(--color-text); }

/* ── Timeline ── */
.timeline {
  overflow-y: auto;
  padding: 1rem 1.25rem;
  display: flex;
  flex-direction: column;
}

.tl-row {
  display: grid;
  grid-template-columns: 4.5rem 1.5rem 1fr;
  align-items: flex-start;
}

.tl-time {
  font-size: 0.72rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-align: right;
  padding-right: 0.6rem;
  padding-top: 0.1rem;
  white-space: nowrap;
}

/* Dots */
.tl-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  margin: 0.15rem auto 0;
  flex-shrink: 0;
}
.tl-dot.origin { background: var(--color-primary); }
.tl-dot.dest   { background: var(--color-danger); }
.tl-dot.stop   { background: var(--color-surface-raised); border: 2px solid var(--color-border); }

/* Vertical lines */
.tl-line {
  width: 2px;
  min-height: 2.5rem;
  margin: 0 auto;
  border-left: 2px solid var(--color-border);
}
.tl-line.walk-line    { border-left-style: dashed; border-color: #475569; }
.tl-line.transit-line { border-left-style: solid; border-width: 3px; }

/* Content */
.tl-content {
  padding: 0 0 0.9rem 0.65rem;
}
.tl-address   { font-size: 0.78rem; color: var(--color-text-muted); padding-bottom: 0.5rem; }
.tl-stop-name { font-size: 0.82rem; font-weight: 600; color: var(--color-text); }

/* ── Walk step ── */
.walk-content { padding-bottom: 0.75rem; }

.step-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
  margin-bottom: 0.35rem;
}

.mode-badge {
  padding: 0.1rem 0.4rem;
  border-radius: 4px;
  font-size: 0.68rem;
  font-weight: 700;
  white-space: nowrap;
}
.mode-badge.walk { background: #475569; color: #e2e8f0; }

.step-meta {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  white-space: nowrap;
}

/* ── Weather chip ── */
.weather-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  background: var(--color-surface-raised);
  border: 1px solid var(--color-border);
  border-radius: 20px;
  padding: 0.1rem 0.55rem 0.1rem 0.4rem;
  font-size: 0.72rem;
  color: var(--color-text-muted);
  white-space: nowrap;
}

.wx-icon { font-size: 0.85rem; line-height: 1; }
.wx-temp { font-weight: 700; color: var(--color-text); }
.wx-desc { color: var(--color-text-muted); }
.wx-wind { color: var(--color-text-muted); opacity: 0.8; }
.wx-wind::before { content: '·'; margin-right: 0.2rem; opacity: 0.4; }

.weather-loading {
  font-style: italic;
  opacity: 0.6;
  background: transparent;
  border-color: transparent;
}

/* Sub-steps */
.step-instruction {
  font-size: 0.78rem;
  color: var(--color-text-muted);
  margin: 0;
  line-height: 1.4;
}
.substeps {
  list-style: decimal;
  padding-left: 1.1rem;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}
.substep {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  line-height: 1.4;
}

/* ── Transit step ── */
.transit-content { padding-bottom: 0.75rem; }

.transit-top {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
  margin-bottom: 0.3rem;
}

.line-badge {
  padding: 0.15rem 0.55rem;
  border-radius: 4px;
  font-size: 0.72rem;
  font-weight: 700;
  white-space: nowrap;
}

.headsign {
  font-size: 0.78rem;
  color: var(--color-text-muted);
  font-style: italic;
}

.transit-details {
  display: flex;
  align-items: center;
  gap: 0.3rem;
  font-size: 0.73rem;
  color: var(--color-text-muted);
  flex-wrap: wrap;
}

.dot    { opacity: 0.4; }
.agency { color: var(--color-text-muted); }

/* ── Footer ── */
.modal-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1.25rem;
  border-top: 1px solid var(--color-border);
  flex-shrink: 0;
}
.fare-label { font-size: 0.78rem; color: var(--color-text-muted); }
.fare-value { font-size: 0.9rem; font-weight: 700; color: var(--color-text); }
</style>
