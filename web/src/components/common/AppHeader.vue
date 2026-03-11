<template>
  <header class="app-header">
    <div class="header-brand">
      <RouterLink to="/" class="brand-link">
        <span class="brand-icon">🚌</span>
        <span class="brand-name">SoundSyncAI</span>
      </RouterLink>
    </div>

    <nav class="header-nav">
      <RouterLink to="/" class="nav-link">Map</RouterLink>
      <RouterLink v-if="auth.isLoggedIn" to="/account" class="nav-link">Account</RouterLink>
    </nav>

    <div class="header-actions">
      <template v-if="auth.isLoggedIn">
        <!-- Bell button -->
        <div class="bell-wrapper" ref="bellWrapper">
          <button class="bell-btn" @click="toggleDropdown" aria-label="Notifications">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
              <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
            </svg>
            <span v-if="notif.unreadCount > 0" class="badge">
              {{ notif.unreadCount > 9 ? '9+' : notif.unreadCount }}
            </span>
          </button>

          <!-- Dropdown -->
          <div v-if="dropdownOpen" class="notif-dropdown">
            <div class="notif-header">
              <span class="notif-title">Alerts</span>
              <button v-if="notif.unreadCount > 0" class="mark-all-btn" @click="handleMarkAllRead">
                Mark all read
              </button>
            </div>

            <div v-if="notif.notifications.length === 0" class="notif-empty">
              No alerts yet
            </div>

            <ul v-else class="notif-list">
              <li
                v-for="n in notif.notifications"
                :key="n.id"
                class="notif-item"
                :class="{ unread: !n.read }"
                @click="handleMarkRead(n.id)"
              >
                <div class="notif-message">{{ n.message }}</div>
                <div class="notif-time">{{ formatTime(n.createdAt) }}</div>
              </li>
            </ul>
          </div>
        </div>

        <span class="user-name">{{ auth.user?.displayName }}</span>
        <button class="btn-ghost" @click="handleLogout">Sign out</button>
      </template>
      <template v-else>
        <RouterLink to="/login" class="btn-ghost">Sign in</RouterLink>
        <RouterLink to="/register" class="btn-primary">Register</RouterLink>
      </template>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/authStore'
import { useNotificationStore } from '@/stores/notificationStore'
import { useRouter } from 'vue-router'

const auth = useAuthStore()
const notif = useNotificationStore()
const router = useRouter()

const dropdownOpen = ref(false)
const bellWrapper = ref<HTMLElement | null>(null)

function toggleDropdown() {
  dropdownOpen.value = !dropdownOpen.value
}

function handleClickOutside(e: MouseEvent) {
  if (bellWrapper.value && !bellWrapper.value.contains(e.target as Node)) {
    dropdownOpen.value = false
  }
}

onMounted(() => document.addEventListener('click', handleClickOutside))
onUnmounted(() => document.removeEventListener('click', handleClickOutside))

async function handleMarkRead(id: string) {
  await notif.markRead(id)
}

async function handleMarkAllRead() {
  await notif.markAllRead()
}

function handleLogout() {
  auth.logout()
  dropdownOpen.value = false
  router.push('/')
}

function formatTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime()
  const minutes = Math.floor(diff / 60_000)
  if (minutes < 1) return 'Just now'
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  return `${Math.floor(hours / 24)}d ago`
}
</script>

<style scoped>
.app-header {
  display: flex;
  align-items: center;
  height: 60px;
  padding: 0 1.5rem;
  background: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  gap: 1.5rem;
  z-index: 100;
  position: relative;
}

.header-brand {
  flex-shrink: 0;
}

.brand-link {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--color-text);
  font-weight: 700;
  font-size: 1.1rem;
  text-decoration: none;
}

.brand-icon {
  font-size: 1.3rem;
}

.header-nav {
  display: flex;
  gap: 1rem;
  flex: 1;
}

.nav-link {
  color: var(--color-text-muted);
  font-size: 0.9rem;
  padding: 0.25rem 0.5rem;
  border-radius: var(--radius-sm);
  transition: color 0.15s;
}

.nav-link:hover,
.nav-link.router-link-active {
  color: var(--color-text);
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-shrink: 0;
}

.user-name {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.btn-ghost {
  background: transparent;
  color: var(--color-text-muted);
  padding: 0.4rem 0.75rem;
  border-radius: var(--radius-sm);
  font-size: 0.875rem;
  transition: color 0.15s;
  text-decoration: none;
}

.btn-ghost:hover {
  color: var(--color-text);
}

.btn-primary {
  background: var(--color-primary);
  color: #fff;
  padding: 0.4rem 0.9rem;
  border-radius: var(--radius-sm);
  font-size: 0.875rem;
  text-decoration: none;
  transition: background 0.15s;
}

.btn-primary:hover {
  background: var(--color-primary-hover);
}

/* ─── Bell ─────────────────────────────────────────────────────────────────── */

.bell-wrapper {
  position: relative;
}

.bell-btn {
  position: relative;
  background: transparent;
  border: none;
  color: var(--color-text-muted);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.35rem;
  border-radius: var(--radius-sm);
  transition: color 0.15s;
}

.bell-btn:hover {
  color: var(--color-text);
}

.badge {
  position: absolute;
  top: -4px;
  right: -4px;
  background: #ef4444;
  color: #fff;
  font-size: 0.625rem;
  font-weight: 700;
  min-width: 16px;
  height: 16px;
  border-radius: 999px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 3px;
  line-height: 1;
}

/* ─── Dropdown ──────────────────────────────────────────────────────────────── */

.notif-dropdown {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  width: 320px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md, 8px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4);
  z-index: 200;
  overflow: hidden;
}

.notif-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--color-border);
}

.notif-title {
  font-size: 0.875rem;
  font-weight: 600;
}

.mark-all-btn {
  background: transparent;
  border: none;
  color: var(--color-primary, #3b82f6);
  font-size: 0.75rem;
  cursor: pointer;
  padding: 0;
}

.mark-all-btn:hover {
  text-decoration: underline;
}

.notif-empty {
  padding: 1.25rem 1rem;
  font-size: 0.875rem;
  color: var(--color-text-muted);
  text-align: center;
}

.notif-list {
  list-style: none;
  max-height: 320px;
  overflow-y: auto;
}

.notif-item {
  padding: 0.75rem 1rem;
  cursor: pointer;
  border-bottom: 1px solid var(--color-border);
  transition: background 0.12s;
}

.notif-item:last-child {
  border-bottom: none;
}

.notif-item:hover {
  background: rgba(255, 255, 255, 0.04);
}

.notif-item.unread {
  border-left: 3px solid #3b82f6;
  padding-left: calc(1rem - 3px);
}

.notif-message {
  font-size: 0.8125rem;
  color: var(--color-text);
  line-height: 1.4;
}

.notif-time {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.25rem;
}
</style>
