import api from '@/services/api'
import type { ServiceAlert } from '@/types/serviceAlert'

export const serviceAlertService = {
  async getAlerts(agency?: string): Promise<ServiceAlert[]> {
    const params = agency ? { agency } : {}
    const { data } = await api.get<{ alerts: ServiceAlert[] }>('/service-alerts', { params })
    return data.alerts
  },
}
