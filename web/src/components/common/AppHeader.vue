<template>
  <header class="app-header">
    <!-- Left: logo + hamburger -->
    <div class="header-left">
      <RouterLink to="/" class="brand-link">
        <img class="brand-icon" src="/icon.png" alt="SoundSync" />
      </RouterLink>

      <!-- Hamburger (mobile only) -->
      <div class="hamburger-wrap">
        <button class="hamburger-btn" @click.stop="menuOpen = !menuOpen" aria-label="Menu">
          <svg v-if="!menuOpen" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"
            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/>
          </svg>
          <svg v-else xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24"
            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>

        <div v-if="menuOpen" class="hamburger-menu">
          <RouterLink to="/" class="menu-link" @click="menuOpen = false">
            <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
            Map
          </RouterLink>
          <RouterLink to="/score" class="menu-link" @click="menuOpen = false">
            <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
            Score
          </RouterLink>
          <RouterLink to="/about" class="menu-link" @click="menuOpen = false">
            <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            About
          </RouterLink>
        </div>
      </div>
    </div>

    <!-- Desktop nav (middle) -->
    <nav class="header-nav">
      <RouterLink to="/" class="nav-link">Map</RouterLink>
      <RouterLink to="/score" class="nav-link">Score</RouterLink>
      <RouterLink to="/about" class="nav-link">About</RouterLink>
      <RouterLink to="/mobile" class="nav-link mobile-link">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24"
          fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="2" width="14" height="20" rx="2" ry="2"/>
          <line x1="12" y1="18" x2="12.01" y2="18"/>
        </svg>
        Mobile
      </RouterLink>
    </nav>

    <!-- Right actions -->
    <div class="header-actions">
      <!-- Mobile tab (right side on mobile) -->
      <RouterLink to="/mobile" class="mobile-tab-btn">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"
          fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="5" y="2" width="14" height="20" rx="2" ry="2"/>
          <line x1="12" y1="18" x2="12.01" y2="18"/>
        </svg>
        Mobile
      </RouterLink>
      <!-- Theme toggle -->
      <button class="theme-toggle-btn" @click="themeStore.toggle()" :aria-label="themeStore.theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'">
        <!-- Sun (shown in dark mode) -->
        <svg v-if="themeStore.theme === 'dark'" xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24"
          fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="5"/>
          <line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/>
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
          <line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/>
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
        </svg>
        <!-- Moon (shown in light mode) -->
        <svg v-else xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24"
          fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
        </svg>
      </button>

      <!-- Service Alert Dropdown (visible to all users) -->
      <ServiceAlertDropdown />

      <template v-if="auth.isLoggedIn">
        <!-- Account icon -->
        <RouterLink to="/account" class="account-icon-btn" aria-label="Account">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24"
            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
            <circle cx="12" cy="7" r="4"/>
          </svg>
        </RouterLink>

        <!-- Bell button -->
        <div class="bell-wrapper">
          <button class="bell-btn" @click.stop="toggleDropdown" aria-label="Notifications">
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
        <button class="btn-ghost sign-out-btn" @click="handleLogout">Sign out</button>
      </template>
      <template v-else>
        <!-- Desktop: text buttons -->
        <RouterLink to="/login" class="btn-ghost auth-desktop">Sign in</RouterLink>
        <RouterLink to="/register" class="btn-primary auth-desktop">Register</RouterLink>

        <!-- Mobile: user icon + dropdown -->
        <div class="auth-menu-wrap" @click.stop>
          <button class="account-icon-btn" @click.stop="authMenuOpen = !authMenuOpen" aria-label="Sign in">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24"
              fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
          </button>
          <div v-if="authMenuOpen" class="auth-dropdown">
            <RouterLink to="/login" class="menu-link" @click="authMenuOpen = false">Sign in</RouterLink>
            <RouterLink to="/register" class="menu-link" @click="authMenuOpen = false">Register</RouterLink>
          </div>
        </div>
      </template>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/authStore'
import { useNotificationStore } from '@/stores/notificationStore'
import { useThemeStore } from '@/stores/themeStore'
import { useRouter } from 'vue-router'
import ServiceAlertDropdown from './ServiceAlertDropdown.vue'

const auth = useAuthStore()
const notif = useNotificationStore()
const themeStore = useThemeStore()
const router = useRouter()

const dropdownOpen = ref(false)
const menuOpen = ref(false)
const authMenuOpen = ref(false)

function toggleDropdown() {
  dropdownOpen.value = !dropdownOpen.value
}

function handleClickOutside() {
  dropdownOpen.value = false
  menuOpen.value = false
  authMenuOpen.value = false
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
  position: sticky;
  top: 0;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}

.brand-link {
  display: flex;
  align-items: center;
  text-decoration: none;
}

.brand-icon {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  object-fit: cover;
  flex-shrink: 0;
}

/* Always hidden */
.brand-name {
  display: none;
}

/* Mobile tab — hidden on desktop, visible on mobile */
.mobile-tab-btn {
  display: none;
}

.header-nav {
  display: flex;
  gap: 1rem;
  flex: 1;
}

.nav-link {
  color: var(--color-text-muted);
  font-size: 0.875rem;
  font-weight: 500;
  padding: 0.3rem 0.75rem;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border);
  transition: color 0.15s, border-color 0.15s, background 0.15s;
  text-decoration: none;
}

.nav-link:hover {
  color: var(--color-text);
  border-color: color-mix(in srgb, var(--color-primary) 50%, transparent);
  background: color-mix(in srgb, var(--color-primary) 8%, transparent);
}

.nav-link.router-link-active {
  color: var(--color-primary);
  border-color: var(--color-primary);
  background: color-mix(in srgb, var(--color-primary) 10%, transparent);
}

/* About link glow animation */
.nav-link[href="/about"] {
  animation: about-glow 2.5s ease-in-out infinite;
}

@keyframes about-glow {
  0%, 100% {
    border-color: var(--color-border);
    box-shadow: none;
    color: var(--color-text-muted);
  }
  50% {
    border-color: var(--color-primary);
    box-shadow: 0 0 8px color-mix(in srgb, var(--color-primary) 50%, transparent);
    color: var(--color-primary);
  }
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

.theme-toggle-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: 1px solid var(--color-border);
  background: transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: color 0.15s, border-color 0.15s, background 0.15s;
  flex-shrink: 0;
}

.theme-toggle-btn:hover {
  color: var(--color-text);
  border-color: var(--color-text-muted);
  background: color-mix(in srgb, var(--color-text) 8%, transparent);
}

.mobile-link {
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

/* ─── Hamburger ─────────────────────────────────────────────────────────────── */

.hamburger-wrap {
  display: none;
  position: relative;
}

.hamburger-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--color-border);
  background: transparent;
  color: var(--color-text-muted);
  cursor: pointer;
  transition: color 0.15s, border-color 0.15s;
}

.hamburger-btn:hover {
  color: var(--color-text);
  border-color: var(--color-text-muted);
}

.hamburger-menu {
  position: absolute;
  top: calc(100% + 8px);
  left: 0;
  min-width: 180px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-md);
  z-index: 200;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.menu-link {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.75rem 1rem;
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--color-text-muted);
  text-decoration: none;
  border-bottom: 1px solid var(--color-border);
  transition: background 0.12s, color 0.12s;
}

.menu-link:last-child {
  border-bottom: none;
}

.menu-link:hover {
  background: color-mix(in srgb, var(--color-primary) 8%, transparent);
  color: var(--color-text);
}

.menu-link.router-link-active {
  color: var(--color-primary);
  background: color-mix(in srgb, var(--color-primary) 10%, transparent);
}

/* ─── Account icon ──────────────────────────────────────────────────────────── */

.account-icon-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: 1px solid var(--color-border);
  color: var(--color-text-muted);
  background: transparent;
  text-decoration: none;
  transition: color 0.15s, border-color 0.15s, background 0.15s;
  flex-shrink: 0;
}

.account-icon-btn:hover,
.account-icon-btn.router-link-active {
  color: var(--color-primary);
  border-color: var(--color-primary);
  background: color-mix(in srgb, var(--color-primary) 10%, transparent);
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

@media (max-width: 600px) {
  .notif-dropdown {
    position: fixed;
    top: 68px;
    left: 0.75rem;
    right: 0.75rem;
    width: auto;
  }
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

/* ─── Auth menu (mobile user icon + dropdown) ───────────────────────────────── */

.auth-menu-wrap {
  display: none;
  position: relative;
}

.auth-dropdown {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  min-width: 140px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-md);
  z-index: 200;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* ── Mobile ─────────────────────────────────────────────────────────────────── */

@media (max-width: 600px) {
  .app-header {
    padding: 0 0.75rem;
    gap: 0.5rem;
  }

  .header-nav {
    display: none;
  }

  .hamburger-wrap {
    display: block;
  }

  .mobile-tab-btn {
    display: flex;
    align-items: center;
    gap: 0.3rem;
    font-size: 0.78rem;
    font-weight: 500;
    color: var(--color-text-muted);
    text-decoration: none;
    padding: 0.3rem 0.5rem;
    border-radius: var(--radius-sm);
    border: 1px solid var(--color-border);
    transition: color 0.15s, border-color 0.15s;
  }

  .mobile-tab-btn:hover,
  .mobile-tab-btn.router-link-active {
    color: var(--color-primary);
    border-color: var(--color-primary);
  }

  .user-name {
    display: none;
  }

  .sign-out-btn {
    display: none;
  }

  .btn-ghost {
    font-size: 0.75rem;
    padding: 0.3rem 0.5rem;
  }

  .btn-primary {
    font-size: 0.75rem;
    padding: 0.3rem 0.5rem;
  }

  .header-actions {
    gap: 0.4rem;
    margin-left: auto;
  }

  .auth-desktop {
    display: none;
  }

  .auth-menu-wrap {
    display: block;
  }
}
</style>
