import api from './api'
import type { WeatherData, HourlyForecast } from '@/types/weather'

export const weatherService = {
  async getWeather(lat: number, lng: number): Promise<WeatherData> {
    const { data } = await api.get<WeatherData>('/weather', { params: { lat, lng } })
    return data
  },

  async getHourlyForecast(lat: number, lng: number): Promise<HourlyForecast> {
    const { data } = await api.get<HourlyForecast>('/weather/hourly', { params: { lat, lng } })
    return data
  },
}
