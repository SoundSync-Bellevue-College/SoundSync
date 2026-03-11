<template>
  <div class="account-view">
    <!-- Header -->
    <div class="account-header">
      <div class="avatar">{{ initials }}</div>
      <div>
        <h1 class="account-title">{{ auth.user?.displayName }}</h1>
        <p class="account-email">{{ auth.user?.email }}</p>
      </div>
    </div>

    <!-- Tab bar -->
    <div class="tab-bar">
      <button class="tab-btn" :class="{ active: activeTab === 'settings' }" @click="activeTab = 'settings'">Settings</button>
      <button class="tab-btn" :class="{ active: activeTab === 'reports' }" @click="switchToReports">My Reports</button>
    </div>

    <!-- ── Settings tab ─────────────────────────────────────────────────── -->
    <template v-if="activeTab === 'settings'">

      <!-- Saved Routes -->
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">Saved Routes</h2>
        </div>

        <LoadingSpinner v-if="loadingFavorites" size="28px" />

        <p v-else-if="!routeStore.favorites.length" class="empty-state">
          No saved routes yet. Plan a trip and save it for quick access.
        </p>

        <div v-else class="favorites-list">
          <FavoriteRouteCard
            v-for="fav in routeStore.favorites"
            :key="fav._id"
            :favorite="fav"
            @remove="removeFavorite"
          />
        </div>
      </section>

      <!-- Display Preferences -->
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">Display Preferences</h2>
        </div>

        <div class="settings-stack">
          <div class="setting-row">
            <div class="setting-label">
              <span class="setting-name">Temperature Unit</span>
              <span class="setting-desc">How temperatures are shown in the weather widget</span>
            </div>
            <div class="pill-group">
              <button class="pill-btn" :class="{ active: auth.tempUnit === 'F' }" @click="saveSetting({ tempUnit: 'F' })">°F</button>
              <button class="pill-btn" :class="{ active: auth.tempUnit === 'C' }" @click="saveSetting({ tempUnit: 'C' })">°C</button>
            </div>
          </div>

          <div class="setting-row">
            <div class="setting-label">
              <span class="setting-name">Distance Unit</span>
              <span class="setting-desc">How distances are shown in route results</span>
            </div>
            <div class="pill-group">
              <button class="pill-btn" :class="{ active: auth.distanceUnit === 'mi' }" @click="saveSetting({ distanceUnit: 'mi' })">mi</button>
              <button class="pill-btn" :class="{ active: auth.distanceUnit === 'km' }" @click="saveSetting({ distanceUnit: 'km' })">km</button>
            </div>
          </div>
        </div>
      </section>

      <!-- Notification Settings -->
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">Notification Settings</h2>
        </div>

        <div class="setting-row">
          <div class="setting-label">
            <span class="setting-name">Route Alerts</span>
            <span class="setting-desc">Receive in-app alerts when a report is filed on one of your saved routes</span>
          </div>
          <label class="toggle">
            <input
              type="checkbox"
              :checked="auth.user?.notificationsEnabled ?? true"
              @change="handleNotificationsToggle"
            />
            <span class="toggle-track">
              <span class="toggle-thumb" />
            </span>
          </label>
        </div>
      </section>

      <!-- Delete Account -->
      <section class="section">
        <div class="setting-row danger-row">
          <div class="setting-label">
            <span class="setting-name">Delete Account</span>
            <span class="setting-desc">Permanently deactivate your account and sign out</span>
          </div>
          <button class="danger-btn" @click="openDeleteModal">Delete Account</button>
        </div>
      </section>
    </template>

    <!-- ── My Reports tab ───────────────────────────────────────────────── -->
    <template v-else>
      <section class="section">
        <LoadingSpinner v-if="loadingReports" size="28px" />

        <p v-else-if="reportsError" class="empty-state error-text">{{ reportsError }}</p>

        <p v-else-if="!reports.length" class="empty-state">
          You haven't submitted any vehicle reports yet.
        </p>

        <div v-else class="reports-list">
          <div v-for="r in reports" :key="r.id" class="report-card">
            <div class="report-icon">{{ categoryIcon(r.type) }}</div>
            <div class="report-body">
              <div class="report-top">
                <span class="report-type">{{ categoryLabel(r.type) }}</span>
                <span class="report-meta">Route {{ routeShortName(r.routeId) }} · Vehicle {{ r.vehicleId }}</span>
              </div>
              <div class="report-bottom">
                <span class="level-dots">
                  <span
                    v-for="n in 5"
                    :key="n"
                    class="dot"
                    :class="dotClass(r.level, n)"
                  >{{ n <= r.level ? '●' : '○' }}</span>
                </span>
                <span class="report-time">{{ relativeTime(r.createdAt) }}</span>
              </div>
            </div>
            <button
              class="delete-report-btn"
              :title="`Delete report`"
              @click="confirmDeleteReport(r)"
            >🗑</button>
          </div>
        </div>
      </section>
    </template>

    <!-- ── Delete Account modal ────────────────────────────────────────── -->
    <dialog ref="deleteDialog" class="confirm-dialog" @click.self="closeDeleteModal">
      <div class="dialog-content">
        <h3 class="dialog-title">Delete Account?</h3>
        <p class="dialog-body">Your account will be deactivated and you will be signed out. This cannot be undone.</p>
        <div class="dialog-actions">
          <button class="btn-cancel" @click="closeDeleteModal">Cancel</button>
          <button class="btn-confirm-danger" :disabled="deletingAccount" @click="confirmDeleteAccount">
            {{ deletingAccount ? 'Deleting…' : 'Delete Account' }}
          </button>
        </div>
      </div>
    </dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/authStore'
import { useRouteStore } from '@/stores/routeStore'
import api from '@/services/api'
import type { VehicleReport } from '@/types/user'
import { getRouteLookup } from '@/services/routeLookup'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import FavoriteRouteCard from '@/components/user/FavoriteRouteCard.vue'

const auth = useAuthStore()
const routeStore = useRouteStore()
const router = useRouter()

// ── Tabs ──────────────────────────────────────────────────────────────────────
const activeTab = ref<'settings' | 'reports'>('settings')

// ── Avatar initials ───────────────────────────────────────────────────────────
const initials = computed(() => {
  const name = auth.user?.displayName ?? auth.user?.email ?? '?'
  return name
    .split(' ')
    .map((w: string) => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
})

// ── Favorites ─────────────────────────────────────────────────────────────────
const loadingFavorites = ref(true)

onMounted(async () => {
  try {
    await routeStore.loadFavorites()
  } finally {
    loadingFavorites.value = false
  }
})

async function removeFavorite(id: string) {
  await routeStore.removeFavorite(id)
}

// ── Settings ──────────────────────────────────────────────────────────────────
async function handleNotificationsToggle(e: Event) {
  const checked = (e.target as HTMLInputElement).checked
  await auth.updateSettings({ notificationsEnabled: checked })
}

async function saveSetting(patch: Parameters<typeof auth.updateSettings>[0]) {
  await auth.updateSettings(patch)
}

// ── Reports ───────────────────────────────────────────────────────────────────
const reports = ref<VehicleReport[]>([])
const loadingReports = ref(false)
const reportsError = ref('')
const routeLookup = ref<Map<string, { shortName: string; color: string; textColor: string }> | null>(null)

function routeShortName(routeId: string): string {
  return routeLookup.value?.get(routeId)?.shortName ?? routeId
}

async function loadReports() {
  loadingReports.value = true
  reportsError.value = ''
  try {
    const [{ data }, lookup] = await Promise.all([
      api.get<{ reports: VehicleReport[] }>('/users/me/vehicle-reports'),
      getRouteLookup(),
    ])
    reports.value = data.reports
    routeLookup.value = lookup
  } catch {
    reportsError.value = 'Could not load reports.'
  } finally {
    loadingReports.value = false
  }
}

function switchToReports() {
  activeTab.value = 'reports'
}

watch(activeTab, (tab) => {
  if (tab === 'reports' && !reports.value.length && !loadingReports.value && !reportsError.value) {
    loadReports()
  }
})

async function deleteReport(type: string, id: string) {
  await api.delete(`/users/me/vehicle-reports/${type}/${id}`)
  reports.value = reports.value.filter(r => r.id !== id)
}

function confirmDeleteReport(r: VehicleReport) {
  if (confirm(`Delete this ${categoryLabel(r.type)} report?`)) {
    deleteReport(r.type, r.id)
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function categoryIcon(type: VehicleReport['type']): string {
  return { cleanliness: '🧹', crowding: '👥', delay: '⏱' }[type] ?? '📋'
}

function categoryLabel(type: VehicleReport['type']): string {
  return { cleanliness: 'Cleanliness', crowding: 'Crowding', delay: 'Delay' }[type] ?? type
}

function dotClass(level: number, n: number): string {
  if (n > level) return 'dot-empty'
  if (level <= 2) return 'dot-green'
  if (level === 3) return 'dot-yellow'
  return 'dot-red'
}

function relativeTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  const days = Math.floor(hrs / 24)
  return `${days}d ago`
}

// ── Delete Account modal ──────────────────────────────────────────────────────
const deleteDialog = ref<HTMLDialogElement | null>(null)
const deletingAccount = ref(false)

function openDeleteModal() {
  deleteDialog.value?.showModal()
}

function closeDeleteModal() {
  deleteDialog.value?.close()
}

async function confirmDeleteAccount() {
  deletingAccount.value = true
  try {
    await auth.deleteAccount()
    router.push('/login')
  } finally {
    deletingAccount.value = false
  }
}
</script>

<style scoped>
.account-view {
  max-width: 720px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

/* Header */
.account-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.75rem;
}

.avatar {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: var(--color-primary);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
  font-weight: 700;
  flex-shrink: 0;
}

.account-title {
  font-size: 1.25rem;
  font-weight: 700;
}

.account-email {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  margin-top: 0.2rem;
}

/* Tab bar */
.tab-bar {
  display: flex;
  border-bottom: 1px solid var(--color-border);
  margin-bottom: 1.75rem;
}

.tab-btn {
  padding: 0.6rem 1.25rem;
  font-size: 0.9rem;
  font-weight: 600;
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: color 0.15s, border-color 0.15s;
  margin-bottom: -1px;
}

.tab-btn.active {
  color: var(--color-primary);
  border-bottom-color: var(--color-primary);
}

/* Sections */
.section {
  margin-bottom: 2rem;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.section-title {
  font-size: 1rem;
  font-weight: 600;
}

.empty-state {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  padding: 1rem 0;
}

.error-text {
  color: #ef4444;
}

.favorites-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

/* Settings shared */
.settings-stack {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.setting-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md, 8px);
}

.setting-label {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.setting-name {
  font-size: 0.9rem;
  font-weight: 500;
}

.setting-desc {
  font-size: 0.8rem;
  color: var(--color-text-muted);
}

/* Pill toggle */
.pill-group {
  display: flex;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  overflow: hidden;
  flex-shrink: 0;
}

.pill-btn {
  padding: 0.3rem 0.85rem;
  font-size: 0.82rem;
  font-weight: 600;
  background: var(--color-bg);
  color: var(--color-text-muted);
  border: none;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
}

.pill-btn.active {
  background: var(--color-primary);
  color: #fff;
}

/* CSS toggle switch */
.toggle {
  position: relative;
  flex-shrink: 0;
  cursor: pointer;
}

.toggle input {
  position: absolute;
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-track {
  display: block;
  width: 44px;
  height: 24px;
  background: var(--color-border, #334155);
  border-radius: 999px;
  transition: background 0.2s;
  position: relative;
}

.toggle input:checked ~ .toggle-track {
  background: #3b82f6;
}

.toggle-thumb {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 18px;
  height: 18px;
  background: #fff;
  border-radius: 50%;
  transition: transform 0.2s;
}

.toggle input:checked ~ .toggle-track .toggle-thumb {
  transform: translateX(20px);
}

/* Danger row (delete account) */
.danger-row {
  border-color: #7f1d1d33;
}

.danger-btn {
  padding: 0.4rem 1rem;
  font-size: 0.85rem;
  font-weight: 600;
  color: #ef4444;
  background: transparent;
  border: 1px solid #ef4444;
  border-radius: var(--radius-sm, 6px);
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.15s, color 0.15s;
}

.danger-btn:hover {
  background: #ef4444;
  color: #fff;
}

/* Reports list */
.reports-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  max-height: 60vh;
  overflow-y: auto;
  padding-right: 0.25rem;
}

.report-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1rem;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md, 8px);
}

.report-icon {
  font-size: 1.4rem;
  flex-shrink: 0;
}

.report-body {
  flex: 1;
  min-width: 0;
}

.report-top {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.report-type {
  font-size: 0.9rem;
  font-weight: 600;
}

.report-meta {
  font-size: 0.8rem;
  color: var(--color-text-muted);
}

.report-bottom {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-top: 0.35rem;
}

.level-dots {
  display: flex;
  gap: 2px;
  font-size: 0.85rem;
}

.dot { transition: color 0.1s; }
.dot-empty { color: var(--color-border, #475569); }
.dot-green  { color: #22c55e; }
.dot-yellow { color: #eab308; }
.dot-red    { color: #ef4444; }

.report-time {
  font-size: 0.78rem;
  color: var(--color-text-muted);
}

.delete-report-btn {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.4);
  color: #ef4444;
  cursor: pointer;
  font-size: 1rem;
  padding: 0.3rem 0.5rem;
  border-radius: 6px;
  transition: background 0.15s, border-color 0.15s;
  flex-shrink: 0;
  line-height: 1;
}

.delete-report-btn:hover {
  background: #ef4444;
  border-color: #ef4444;
}

/* Confirm dialog */
.confirm-dialog {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md, 10px);
  background: var(--color-surface);
  color: inherit;
  padding: 0;
  max-width: 400px;
  width: 90%;
}

.confirm-dialog::backdrop {
  background: rgba(0, 0, 0, 0.6);
}

.dialog-content {
  padding: 1.5rem;
}

.dialog-title {
  font-size: 1.1rem;
  font-weight: 700;
  margin-bottom: 0.75rem;
}

.dialog-body {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  margin-bottom: 1.5rem;
  line-height: 1.5;
}

.dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}

.btn-cancel {
  padding: 0.45rem 1rem;
  font-size: 0.875rem;
  font-weight: 600;
  background: var(--color-bg);
  color: inherit;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm, 6px);
  cursor: pointer;
}

.btn-confirm-danger {
  padding: 0.45rem 1rem;
  font-size: 0.875rem;
  font-weight: 600;
  background: #ef4444;
  color: #fff;
  border: none;
  border-radius: var(--radius-sm, 6px);
  cursor: pointer;
  transition: opacity 0.15s;
}

.btn-confirm-danger:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
