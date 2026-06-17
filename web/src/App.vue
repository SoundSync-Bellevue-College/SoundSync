<template>
  <div id="app-root">
    <AppHeader />
    <main class="main-content">
      <RouterView />
    </main>
    <NotificationToast />
  </div>
</template>

<script setup lang="ts">
import { watch, onMounted } from 'vue'
import AppHeader from '@/components/common/AppHeader.vue'
import NotificationToast from '@/components/common/NotificationToast.vue'
import { useAuthStore } from '@/stores/authStore'
import { useNotificationStore } from '@/stores/notificationStore'
import { useServiceAlertStore } from '@/stores/serviceAlertStore'
import { useThemeStore } from '@/stores/themeStore'

const auth = useAuthStore()
const notif = useNotificationStore()
const serviceAlerts = useServiceAlertStore()
const themeStore = useThemeStore()

onMounted(() => {
  themeStore.init()
  serviceAlerts.startPolling()
})

watch(
  () => auth.isLoggedIn,
  (loggedIn) => {
    if (loggedIn) {
      notif.startPolling()
    } else {
      notif.stopPolling()
    }
  },
  { immediate: true },
)
</script>

<style>
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html,
body,
#app-root {
  height: 100%;
  overflow-x: hidden;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background-color: var(--color-bg);
  color: var(--color-text);
  transition: background-color 0.2s, color 0.2s;
}

.main-content {
  height: calc(100vh - 60px);
  overflow-y: auto;
}
</style>
