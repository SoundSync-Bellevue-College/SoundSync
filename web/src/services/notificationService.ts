import api from './api'
import type { Notification } from '@/types/user'

export const notificationService = {
  async getNotifications(): Promise<Notification[]> {
    const { data } = await api.get<{ notifications: Notification[] }>('/users/me/notifications')
    return data.notifications
  },

  async markRead(id: string): Promise<void> {
    await api.patch(`/users/me/notifications/${id}/read`)
  },

  async markAllRead(): Promise<void> {
    await api.patch('/users/me/notifications/read-all')
  },
}
