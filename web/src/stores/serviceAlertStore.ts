import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { serviceAlertService } from '@/services/serviceAlertService'
import type { ServiceAlert } from '@/types/serviceAlert'

export const useServiceAlertStore = defineStore('serviceAlerts', () => {
  const alerts = ref<ServiceAlert[]>([])
  let pollInterval: ReturnType<typeof setInterval> | null = null

  const count = computed(() => alerts.value.length)

  async function fetchAlerts() {
    try {
      alerts.value = await serviceAlertService.getAlerts()
    } catch {
      // silently ignore — don't disrupt the UI if the alerts feed is unavailable
    }
  }

  function startPolling() {
    fetchAlerts()
    pollInterval = setInterval(fetchAlerts, 2 * 60 * 1000)
  }

  function stopPolling() {
    if (pollInterval) {
      clearInterval(pollInterval)
      pollInterval = null
    }
  }

  function getAlertsForStop(stopId: string, routeIds: string[]): ServiceAlert[] {
    return alerts.value.filter(alert => {
      const entities = alert.informedEntities
      if (!entities || entities.length === 0) return false
      return entities.some(
        e => e.stop_id === stopId || (e.route_id != null && routeIds.includes(e.route_id))
      )
    })
  }

  return { alerts, count, fetchAlerts, startPolling, stopPolling, getAlertsForStop }
})
