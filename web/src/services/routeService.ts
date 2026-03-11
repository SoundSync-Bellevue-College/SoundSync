import api from './api'
import type { RoutePlan, Route, LatLng } from '@/types/transit'
import type { FavoriteRoute, CreateFavoritePayload } from '@/types/user'

export const routeService = {
  async planRoute(origin: LatLng, destination: LatLng): Promise<RoutePlan> {
    const { data } = await api.get<RoutePlan>('/routes/plan', {
      params: {
        origin: `${origin.lat},${origin.lng}`,
        dest: `${destination.lat},${destination.lng}`,
      },
    })
    return data
  },

  async getRoute(routeId: string): Promise<Route> {
    const { data } = await api.get<Route>(`/routes/${routeId}`)
    return data
  },

  async getFavorites(): Promise<FavoriteRoute[]> {
    const { data } = await api.get<{ favorites: FavoriteRoute[] }>('/users/me/favorites')
    return data.favorites
  },

  async createFavorite(payload: CreateFavoritePayload): Promise<FavoriteRoute> {
    const { data } = await api.post<FavoriteRoute>('/users/me/favorites', payload)
    return data
  },

  async deleteFavorite(id: string): Promise<void> {
    await api.delete(`/users/me/favorites/${id}`)
  },
}
