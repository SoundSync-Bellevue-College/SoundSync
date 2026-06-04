<template>
  <div class="score-page">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">Route Scores</h1>
        <p class="page-subtitle">Reliability & crowd-sourced ratings by route</p>
      </div>
      <input
        v-model="search"
        class="search-input"
        type="text"
        placeholder="Search route…"
      />
    </div>

    <!-- Tab switcher -->
    <div class="tab-bar">
      <button class="tab-btn" :class="{ active: activeTab === 'reliability' }" @click="activeTab = 'reliability'">
        Reliability
      </button>
      <button class="tab-btn" :class="{ active: activeTab === 'crowdsource' }" @click="activeTab = 'crowdsource'">
        Crowd Source
      </button>
    </div>

    <!-- ══ RELIABILITY TAB ══ -->
    <template v-if="activeTab === 'reliability'">

    <!-- Summary cards -->
    <div class="summary-row" v-if="routes.length">
      <div class="summary-card">
        <span class="summary-value">{{ routes.length }}</span>
        <span class="summary-label">Routes tracked</span>
      </div>
      <div class="summary-card">
        <span class="summary-value" :class="scoreClass(avgScore)">{{ avgScore }}</span>
        <span class="summary-label">Avg score</span>
      </div>
      <div class="summary-card">
        <span class="summary-value green">{{ routeLabel(routes[0]?.route_id) }}</span>
        <span class="summary-label">Best route</span>
      </div>
      <div class="summary-card">
        <span class="summary-value red">{{ routeLabel(routes[routes.length - 1]?.route_id) }}</span>
        <span class="summary-label">Lowest route</span>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="state-msg">Loading scores…</div>

    <!-- No data -->
    <div v-else-if="!loading && routes.length === 0" class="state-msg muted">
      No reliability data available yet.<br />
      <small>Data is collected as the transit poller records arrivals.</small>
    </div>

    <!-- Table -->
    <div v-else class="table-wrap">
      <table class="score-table">
        <thead>
          <tr>
            <th class="col-rank">#</th>
            <th class="col-route">Route</th>
            <th class="col-score">Score</th>
            <th class="col-bar"></th>
            <th class="col-ontime">On-Time</th>
            <th class="col-delay">Avg Delay</th>
            <th class="col-samples">Samples</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(route, index) in filtered" :key="route.route_id" class="score-row">
            <td class="col-rank rank-num">{{ index + 1 }}</td>
            <td class="col-route">
              <span class="route-badge" :title="route.route_id">{{ routeLabel(route.route_id) }}</span>
              <span class="route-id-sub">{{ route.route_id }}</span>
            </td>
            <td class="col-score">
              <span class="score-num" :class="scoreClass(route.score)">
                {{ route.score.toFixed(1) }}
              </span>
            </td>
            <td class="col-bar">
              <div class="bar-track">
                <div
                  class="bar-fill"
                  :class="scoreClass(route.score)"
                  :style="{ width: route.score + '%' }"
                />
              </div>
            </td>
            <td class="col-ontime">{{ route.on_time_rate.toFixed(1) }}%</td>
            <td class="col-delay" :class="delayClass(route.avg_delay_seconds)">
              {{ formatDelay(route.avg_delay_seconds) }}
            </td>
            <td class="col-samples muted">{{ route.sample_count.toLocaleString() }}</td>
          </tr>
          <tr v-if="filtered.length === 0">
            <td colspan="7" class="state-msg muted">No routes match "{{ search }}"</td>
          </tr>
        </tbody>
      </table>
    </div>

    </template><!-- end reliability tab -->

    <!-- ══ CROWD SOURCE TAB ══ -->
    <template v-if="activeTab === 'crowdsource'">

      <!-- Summary cards -->
      <div class="summary-row" v-if="csRoutes.length">
        <div class="summary-card">
          <span class="summary-value">{{ csRoutes.length }}</span>
          <span class="summary-label">Routes rated</span>
        </div>
        <div class="summary-card">
          <span class="summary-value">{{ csTotalReports.toLocaleString() }}</span>
          <span class="summary-label">Total reports</span>
        </div>
        <div class="summary-card">
          <span class="summary-value" :class="starClass(csAvgCleanliness)">{{ csAvgCleanliness }}</span>
          <span class="summary-label">Avg cleanliness</span>
        </div>
        <div class="summary-card">
          <span class="summary-value" :class="crowdClass(csAvgCrowding)">{{ csAvgCrowding }}</span>
          <span class="summary-label">Avg crowding</span>
        </div>
      </div>

      <div v-if="csLoading" class="state-msg">Loading crowd source data…</div>
      <div v-else-if="!csLoading && csRoutes.length === 0" class="state-msg muted">
        No crowd-sourced reports yet.<br />
        <small>Submit ratings via the map when you board a vehicle.</small>
      </div>

      <div v-else class="table-wrap">
        <table class="score-table">
          <thead>
            <tr>
              <th class="col-rank">#</th>
              <th class="col-route">Route</th>
              <th class="col-cs">Cleanliness</th>
              <th class="col-cs">Crowding</th>
              <th class="col-cs">Delay Lvl</th>
              <th class="col-samples">Reports</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(r, index) in csFiltered" :key="r.route_id" class="score-row">
              <td class="col-rank rank-num">{{ index + 1 }}</td>
              <td class="col-route">
                <span class="route-badge" :title="r.route_id">{{ routeLabel(r.route_id) }}</span>
                <span class="route-id-sub">{{ r.route_id }}</span>
              </td>
              <td class="col-cs">
                <span v-if="r.avg_cleanliness > 0" :class="starClass(r.avg_cleanliness)">
                  {{ starBar(r.avg_cleanliness) }} {{ r.avg_cleanliness.toFixed(1) }}
                </span>
                <span v-else class="muted">—</span>
              </td>
              <td class="col-cs">
                <span v-if="r.avg_crowding > 0" :class="crowdClass(r.avg_crowding)">
                  {{ crowdLabel(r.avg_crowding) }} {{ r.avg_crowding.toFixed(1) }}
                </span>
                <span v-else class="muted">—</span>
              </td>
              <td class="col-cs">
                <span v-if="r.avg_delay > 0" :class="delayLvlClass(r.avg_delay)">
                  {{ delayLvlLabel(r.avg_delay) }} {{ r.avg_delay.toFixed(1) }}
                </span>
                <span v-else class="muted">—</span>
              </td>
              <td class="col-samples muted">{{ r.total_reports.toLocaleString() }}</td>
            </tr>
            <tr v-if="csFiltered.length === 0">
              <td colspan="6" class="state-msg muted">No routes match "{{ search }}"</td>
            </tr>
          </tbody>
        </table>
      </div>

    </template><!-- end crowdsource tab -->

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import api from '@/services/api'
import { getRouteLookup } from '@/services/routeLookup'

interface SummaryEntry {
  route_id: string
  score: number
  on_time_rate: number
  avg_delay_seconds: number
  sample_count: number
}

interface CSEntry {
  route_id: string
  avg_cleanliness: number
  avg_crowding: number
  avg_delay: number
  total_reports: number
}

const activeTab = ref<'reliability' | 'crowdsource'>('reliability')

// ── Reliability tab ──────────────────────────────────────────────────────────
const routes = ref<SummaryEntry[]>([])
const loading = ref(true)
const search = ref('')
const routeNames = ref<Map<string, string>>(new Map())

// ── Crowd source tab ─────────────────────────────────────────────────────────
const csRoutes = ref<CSEntry[]>([])
const csLoading = ref(true)

onMounted(async () => {
  try {
    const [reliabilityRes, csRes, lookup] = await Promise.all([
      api.get('/reliability/summary'),
      api.get('/crowdsource/summary'),
      getRouteLookup(),
    ])
    routes.value = reliabilityRes.data?.data?.routes ?? []
    csRoutes.value = csRes.data?.data?.routes ?? []
    lookup.forEach((info, id) => routeNames.value.set(id, info.shortName))
  } catch {
    routes.value = []
    csRoutes.value = []
  } finally {
    loading.value = false
    csLoading.value = false
  }
})

function routeLabel(id: string): string {
  if (!id) return id
  // OBA stores route IDs with agency prefix e.g. "1_100001" — strip it for CSV lookup
  const stripped = id.includes('_') ? id.substring(id.indexOf('_') + 1) : id
  return routeNames.value.get(stripped) ?? routeNames.value.get(id) ?? id
}

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return routes.value
  return routes.value.filter(r =>
    routeLabel(r.route_id).toLowerCase().includes(q) ||
    r.route_id.toLowerCase().includes(q)
  )
})

const avgScore = computed(() => {
  if (!routes.value.length) return '—'
  const avg = routes.value.reduce((s, r) => s + r.score, 0) / routes.value.length
  return avg.toFixed(1)
})

function scoreClass(score: number | string): string {
  const n = typeof score === 'string' ? parseFloat(score) : score
  if (isNaN(n)) return ''
  if (n >= 75) return 'green'
  if (n >= 50) return 'amber'
  return 'red'
}

function delayClass(sec: number): string {
  if (sec > 60) return 'red'
  if (sec < -30) return 'amber'
  return 'green'
}

function formatDelay(sec: number): string {
  if (Math.abs(sec) < 60) return `${Math.round(sec)}s`
  const m = (sec / 60).toFixed(1)
  return sec >= 0 ? `+${m}m` : `${m}m`
}

// ── Crowd source helpers ──────────────────────────────────────────────────────

const csFiltered = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return csRoutes.value
  return csRoutes.value.filter(r =>
    routeLabel(r.route_id).toLowerCase().includes(q) ||
    r.route_id.toLowerCase().includes(q),
  )
})

const csTotalReports = computed(() =>
  csRoutes.value.reduce((s, r) => s + r.total_reports, 0),
)

const csAvgCleanliness = computed(() => {
  const valid = csRoutes.value.filter(r => r.avg_cleanliness > 0)
  if (!valid.length) return '—'
  return (valid.reduce((s, r) => s + r.avg_cleanliness, 0) / valid.length).toFixed(1)
})

const csAvgCrowding = computed(() => {
  const valid = csRoutes.value.filter(r => r.avg_crowding > 0)
  if (!valid.length) return '—'
  return (valid.reduce((s, r) => s + r.avg_crowding, 0) / valid.length).toFixed(1)
})

// Cleanliness: 1=dirty → 5=clean; higher is better (green)
function starClass(val: number | string): string {
  const n = typeof val === 'string' ? parseFloat(val) : val
  if (isNaN(n)) return ''
  if (n >= 4) return 'green'
  if (n >= 3) return 'amber'
  return 'red'
}

function starBar(val: number): string {
  const filled = Math.round(val)
  return '★'.repeat(filled) + '☆'.repeat(5 - filled)
}

// Crowding: 1=empty → 5=packed; lower is better (green)
function crowdClass(val: number | string): string {
  const n = typeof val === 'string' ? parseFloat(val) : val
  if (isNaN(n)) return ''
  if (n <= 2) return 'green'
  if (n <= 3.5) return 'amber'
  return 'red'
}

function crowdLabel(val: number): string {
  if (val <= 1.5) return '😌'
  if (val <= 2.5) return '🙂'
  if (val <= 3.5) return '😐'
  if (val <= 4.5) return '😬'
  return '😰'
}

// Delay level: 1=on-time → 5=very delayed; lower is better (green)
function delayLvlClass(val: number): string {
  if (val <= 2) return 'green'
  if (val <= 3.5) return 'amber'
  return 'red'
}

function delayLvlLabel(val: number): string {
  if (val <= 1.5) return '✅'
  if (val <= 2.5) return '🟡'
  if (val <= 3.5) return '🟠'
  return '🔴'
}
</script>

<style scoped>
.score-page {
  height: 100%;
  overflow-y: auto;
  padding: 1.5rem 2rem;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  background: var(--color-bg, #0f172a);
}

/* ── Header ── */
.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
}

.page-title {
  font-size: 1.4rem;
  font-weight: 700;
  color: var(--color-text, #f1f5f9);
}

.page-subtitle {
  font-size: 0.82rem;
  color: var(--color-text-muted, #64748b);
  margin-top: 0.2rem;
}

.search-input {
  background: var(--color-surface, #1e293b);
  border: 1px solid var(--color-border, #334155);
  border-radius: 6px;
  padding: 0.45rem 0.85rem;
  color: var(--color-text, #f1f5f9);
  font-size: 0.875rem;
  width: 220px;
  transition: border-color 0.15s;
}

.search-input:focus {
  outline: none;
  border-color: #3b82f6;
}

/* ── Summary cards ── */
.summary-row {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.summary-card {
  background: var(--color-surface, #1e293b);
  border: 1px solid var(--color-border, #334155);
  border-radius: 8px;
  padding: 0.85rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  min-width: 130px;
}

.summary-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text, #f1f5f9);
}

.summary-label {
  font-size: 0.72rem;
  color: var(--color-text-muted, #64748b);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

/* ── Table ── */
.table-wrap {
  background: var(--color-surface, #1e293b);
  border: 1px solid var(--color-border, #334155);
  border-radius: 10px;
  overflow: hidden;
}

.score-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.875rem;
}

.score-table thead tr {
  background: rgba(255, 255, 255, 0.04);
  border-bottom: 1px solid var(--color-border, #334155);
}

.score-table th {
  padding: 0.65rem 1rem;
  text-align: left;
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--color-text-muted, #64748b);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  white-space: nowrap;
}

.score-row {
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  transition: background 0.12s;
}

.score-row:last-child {
  border-bottom: none;
}

.score-row:hover {
  background: rgba(255, 255, 255, 0.03);
}

.score-table td {
  padding: 0.6rem 1rem;
  color: var(--color-text, #f1f5f9);
  white-space: nowrap;
}

/* Column widths */
.col-rank   { width: 48px; }
.col-route  { width: 160px; }
.col-score  { width: 72px; }
.col-bar    { width: 180px; }
.col-ontime { width: 90px; }
.col-delay  { width: 90px; }
.col-samples { width: 90px; }

.rank-num {
  color: var(--color-text-muted, #64748b);
  font-size: 0.8rem;
}

.col-route td, td.col-route {
  display: flex;
  flex-direction: column;
  gap: 0.15rem;
}

.route-id-sub {
  font-size: 0.68rem;
  color: var(--color-text-muted, #64748b);
}

.route-badge {
  background: rgba(59, 130, 246, 0.15);
  color: #93c5fd;
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: 4px;
  padding: 0.15rem 0.5rem;
  font-size: 0.8rem;
  font-weight: 600;
}

.score-num {
  font-size: 1rem;
  font-weight: 700;
}

/* Score bar */
.bar-track {
  height: 6px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 99px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  border-radius: 99px;
  transition: width 0.4s ease;
}

/* Color classes */
.green { color: #22c55e; }
.amber { color: #f59e0b; }
.red   { color: #ef4444; }
.muted { color: var(--color-text-muted, #64748b); }

.bar-fill.green { background: #22c55e; }
.bar-fill.amber { background: #f59e0b; }
.bar-fill.red   { background: #ef4444; }

/* ── Tabs ── */
.tab-bar {
  display: flex;
  border-bottom: 2px solid var(--color-border, #334155);
  gap: 0;
}

.tab-btn {
  padding: 0.5rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  background: transparent;
  border: none;
  color: var(--color-text-muted, #64748b);
  cursor: pointer;
  border-bottom: 2px solid transparent;
  margin-bottom: -2px;
  transition: color 0.15s, border-color 0.15s;
}

.tab-btn:hover {
  color: var(--color-text, #f1f5f9);
}

.tab-btn.active {
  color: #3b82f6;
  border-bottom-color: #3b82f6;
}

/* Crowd source column */
.col-cs { width: 110px; }

/* States */
.state-msg {
  text-align: center;
  padding: 3rem 1rem;
  color: var(--color-text, #f1f5f9);
  font-size: 0.9rem;
  line-height: 1.8;
}

.state-msg.muted {
  color: var(--color-text-muted, #64748b);
}
</style>
