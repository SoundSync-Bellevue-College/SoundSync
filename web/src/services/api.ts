import axios from 'axios'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080'

const api = axios.create({
  baseURL: `${API_BASE_URL}/api/v1`,
  timeout: 10_000,
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('soundsync_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 && !error.config?.url?.includes('/auth/')) {
      localStorage.removeItem('soundsync_token')
      localStorage.removeItem('soundsync_user')
      window.location.href = '/login'
      return Promise.reject(new Error('Session expired. Please sign in again.'))
    }
    const message = error.response?.data?.message || error.message || 'Unknown error'
    return Promise.reject(new Error(message))
  },
)

export default api