import api from './api'
import type { LoginPayload, RegisterPayload, AuthResponse, User } from '@/types/user'

export const authService = {
  async login(payload: LoginPayload): Promise<AuthResponse> {
    const { data } = await api.post<AuthResponse>('/auth/login', payload)
    return data
  },

  async register(payload: RegisterPayload): Promise<AuthResponse> {
    const { data } = await api.post<AuthResponse>('/auth/register', payload)
    return data
  },

  async getMe(): Promise<User> {
    const { data } = await api.get<User>('/users/me')
    return data
  },

  async updateSettings(settings: Partial<Pick<User, 'notificationsEnabled' | 'tempUnit' | 'distanceUnit'>>): Promise<void> {
    await api.patch('/users/me/settings', settings)
  },

  async deleteAccount(): Promise<void> {
    await api.delete('/users/me')
  },
}
