import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User, LoginPayload, RegisterPayload } from '@/types/user'
import { authService } from '@/services/authService'

const TOKEN_KEY = 'soundsync_token'
const USER_KEY = 'soundsync_user'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem(TOKEN_KEY))
  const user = ref<User | null>(JSON.parse(localStorage.getItem(USER_KEY) || 'null'))

  const isLoggedIn    = computed(() => !!token.value && !!user.value)
  const tempUnit      = computed((): 'F' | 'C'     => user.value?.tempUnit     ?? 'F')
  const distanceUnit  = computed((): 'mi' | 'km'   => user.value?.distanceUnit ?? 'mi')

  function persist(newToken: string, newUser: User) {
    token.value = newToken
    user.value = newUser
    localStorage.setItem(TOKEN_KEY, newToken)
    localStorage.setItem(USER_KEY, JSON.stringify(newUser))
  }

  async function login(payload: LoginPayload) {
    const response = await authService.login(payload)
    persist(response.token, response.user)
    return response.user
  }

  async function register(payload: RegisterPayload) {
    const response = await authService.register(payload)
    persist(response.token, response.user)
    return response.user
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
  }

  async function deleteAccount() {
    await authService.deleteAccount()
    token.value = null
    user.value = null
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
  }

  async function getMe() {
    const freshUser = await authService.getMe()
    user.value = freshUser
    localStorage.setItem(USER_KEY, JSON.stringify(freshUser))
    return freshUser
  }

  async function updateSettings(settings: Partial<Pick<User, 'notificationsEnabled' | 'tempUnit' | 'distanceUnit'>>) {
    await authService.updateSettings(settings)
    if (user.value) {
      user.value = { ...user.value, ...settings }
      localStorage.setItem(USER_KEY, JSON.stringify(user.value))
    }
  }

  return { token, user, isLoggedIn, tempUnit, distanceUnit, login, register, logout, getMe, updateSettings, deleteAccount }
})
