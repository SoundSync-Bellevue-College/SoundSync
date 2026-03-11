import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Notification } from '@/types/user'
import { notificationService } from '@/services/notificationService'

export const useNotificationStore = defineStore('notifications', () => {
  const notifications = ref<Notification[]>([])
  const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)

  let pollingTimer: ReturnType<typeof setInterval> | null = null

  async function fetchNotifications() {
    try {
      // useAuthStore called inside action to avoid circular import
      const { useAuthStore } = await import('@/stores/authStore')
      const auth = useAuthStore()
      if (!auth.isLoggedIn) return
      notifications.value = await notificationService.getNotifications()
    } catch {
      // silently ignore — backend may be offline
    }
  }

  async function markRead(id: string) {
    // optimistic update
    const n = notifications.value.find(n => n.id === id)
    if (n) n.read = true
    try {
      await notificationService.markRead(id)
    } catch {
      // revert on error
      if (n) n.read = false
    }
  }

  async function markAllRead() {
    // optimistic update
    notifications.value.forEach(n => { n.read = true })
    try {
      await notificationService.markAllRead()
    } catch {
      // re-fetch to reconcile
      await fetchNotifications()
    }
  }

  function startPolling() {
    fetchNotifications()
    if (!pollingTimer) {
      pollingTimer = setInterval(fetchNotifications, 30_000)
    }
  }

  function stopPolling() {
    if (pollingTimer) {
      clearInterval(pollingTimer)
      pollingTimer = null
    }
    notifications.value = []
  }

  return { notifications, unreadCount, fetchNotifications, markRead, markAllRead, startPolling, stopPolling }
})
