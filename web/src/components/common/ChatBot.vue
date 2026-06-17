<template>
  <div class="chatbot-wrapper">
    <!-- Chat window -->
    <Transition name="chat-slide">
      <div v-if="isOpen" class="chat-window">
        <div class="chat-header">
          <span class="chat-header-icon">🚌</span>
          <div class="chat-header-text">
            <span class="chat-title">Transit Assistant</span>
            <span class="chat-subtitle">Powered by Claude Haiku</span>
          </div>
          <button class="chat-close" @click="isOpen = false">✕</button>
        </div>

        <div class="chat-messages" ref="messagesEl">
          <div v-if="messages.length === 0" class="chat-empty">
            <p>Hi! I can help you plan trips around the Seattle/Bellevue area.</p>
            <p class="chat-example">Try: <em>"I need to go to Seattle Center from Bellevue College today"</em></p>
          </div>
          <div
            v-for="(msg, i) in messages"
            :key="i"
            :class="['chat-msg', msg.role === 'user' ? 'chat-msg--user' : 'chat-msg--assistant']"
          >
            <span class="chat-msg-text">{{ msg.content }}</span>
          </div>
          <div v-if="loading" class="chat-msg chat-msg--assistant chat-msg--loading">
            <span class="dot" /><span class="dot" /><span class="dot" />
          </div>
        </div>

        <form class="chat-input-row" @submit.prevent="send">
          <input
            v-model="draft"
            class="chat-input"
            placeholder="Ask about transit routes..."
            :disabled="loading"
            autocomplete="off"
          />
          <button class="chat-send" :disabled="loading || !draft.trim()" type="submit">
            ➤
          </button>
        </form>
      </div>
    </Transition>

    <!-- Floating button -->
    <button class="chat-fab" @click="isOpen = !isOpen" :class="{ 'chat-fab--open': isOpen }">
      <span v-if="!isOpen">🚌</span>
      <span v-else>✕</span>
    </button>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue'
import api from '@/services/api'
import { geocodeAddress } from '@/services/mapsService'

interface Message {
  role: 'user' | 'assistant'
  content: string
}

interface RoutePayload {
  origin: { name: string; lat: number; lng: number }
  destination: { name: string; lat: number; lng: number }
}

const emit = defineEmits<{ 'plan-route': [RoutePayload] }>()

const isOpen = ref(false)
const draft = ref('')
const loading = ref(false)
const messages = ref<Message[]>([])
const messagesEl = ref<HTMLElement | null>(null)

async function scrollToBottom() {
  await nextTick()
  if (messagesEl.value) {
    messagesEl.value.scrollTop = messagesEl.value.scrollHeight
  }
}

async function send() {
  const text = draft.value.trim()
  if (!text || loading.value) return

  messages.value.push({ role: 'user', content: text })
  draft.value = ''
  loading.value = true
  await scrollToBottom()

  try {
    const { data } = await api.post('/chat', { messages: messages.value })
    messages.value.push({ role: 'assistant', content: data.message })

    if (data.route) {
      const [originCoords, destCoords] = await Promise.all([
        geocodeAddress(data.route.origin),
        geocodeAddress(data.route.destination),
      ])
      if (originCoords && destCoords) {
        emit('plan-route', {
          origin: { name: data.route.origin, ...originCoords },
          destination: { name: data.route.destination, ...destCoords },
        })
      }
    }
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Something went wrong. Please try again.'
    messages.value.push({ role: 'assistant', content: msg })
  } finally {
    loading.value = false
    await scrollToBottom()
  }
}
</script>

<style scoped>
.chatbot-wrapper {
  position: fixed;
  bottom: 1.5rem;
  right: 4rem;
  z-index: 1000;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.75rem;
}

/* FAB */
.chat-fab {
  width: 3.25rem;
  height: 3.25rem;
  border-radius: 50%;
  border: none;
  background: #7fdbff;
  color: #0d1b2a;
  font-size: 1.4rem;
  cursor: pointer;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.15s, background 0.15s;
}
.chat-fab:hover {
  transform: scale(1.08);
  background: #5ecef7;
}
.chat-fab--open {
  background: #122340;
  color: #7fdbff;
  border: 1.5px solid #7fdbff44;
}

/* Window */
.chat-window {
  width: 340px;
  max-height: 500px;
  background: #0d1b2a;
  border: 1px solid #1e3a5f;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Header */
.chat-header {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.75rem 1rem;
  background: #122340;
  border-bottom: 1px solid #1e3a5f;
}
.chat-header-icon {
  font-size: 1.25rem;
}
.chat-header-text {
  flex: 1;
  display: flex;
  flex-direction: column;
}
.chat-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: #e8f4fd;
}
.chat-subtitle {
  font-size: 0.7rem;
  color: #7fdbff88;
}
.chat-close {
  background: none;
  border: none;
  color: #7a9bbf;
  cursor: pointer;
  font-size: 0.85rem;
  padding: 0.2rem 0.4rem;
  border-radius: 4px;
}
.chat-close:hover {
  color: #e8f4fd;
}

/* Messages */
.chat-messages {
  flex: 1;
  overflow-y: auto;
  padding: 0.75rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.chat-empty {
  color: #7a9bbf;
  font-size: 0.82rem;
  line-height: 1.5;
  padding: 0.5rem;
}
.chat-example {
  margin-top: 0.5rem;
  color: #7fdbff88;
}

.chat-msg {
  max-width: 85%;
  padding: 0.5rem 0.75rem;
  border-radius: 10px;
  font-size: 0.83rem;
  line-height: 1.5;
  white-space: pre-wrap;
  word-break: break-word;
}
.chat-msg--user {
  align-self: flex-end;
  background: #7fdbff;
  color: #0d1b2a;
  border-bottom-right-radius: 3px;
}
.chat-msg--assistant {
  align-self: flex-start;
  background: #122340;
  color: #c8dff0;
  border-bottom-left-radius: 3px;
  border: 1px solid #1e3a5f;
}

/* Loading dots */
.chat-msg--loading {
  display: flex;
  gap: 4px;
  padding: 0.6rem 0.75rem;
  align-items: center;
}
.dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #7fdbff;
  animation: bounce 1s infinite;
}
.dot:nth-child(2) { animation-delay: 0.15s; }
.dot:nth-child(3) { animation-delay: 0.3s; }
@keyframes bounce {
  0%, 80%, 100% { transform: translateY(0); opacity: 0.6; }
  40% { transform: translateY(-5px); opacity: 1; }
}

/* Input */
.chat-input-row {
  display: flex;
  gap: 0.4rem;
  padding: 0.6rem 0.75rem;
  border-top: 1px solid #1e3a5f;
  background: #0d1b2a;
}
.chat-input {
  flex: 1;
  background: #122340;
  border: 1px solid #1e3a5f;
  border-radius: 8px;
  color: #e8f4fd;
  font-size: 0.82rem;
  padding: 0.45rem 0.7rem;
  outline: none;
}
.chat-input::placeholder {
  color: #4a6a8a;
}
.chat-input:focus {
  border-color: #7fdbff55;
}
.chat-send {
  background: #7fdbff;
  border: none;
  border-radius: 8px;
  color: #0d1b2a;
  cursor: pointer;
  font-size: 0.95rem;
  padding: 0.45rem 0.7rem;
  transition: background 0.15s;
}
.chat-send:hover:not(:disabled) {
  background: #5ecef7;
}
.chat-send:disabled {
  opacity: 0.4;
  cursor: default;
}

@media (max-width: 768px) {
  .chatbot-wrapper {
    right: auto;
    left: 1rem;
    bottom: auto;
    top: 70px;
    z-index: 50;
    align-items: flex-start;
    flex-direction: column-reverse;
  }

  .chat-window {
    width: calc(100vw - 2rem);
    max-height: 60vh;
  }
}

/* Slide transition */
.chat-slide-enter-active,
.chat-slide-leave-active {
  transition: opacity 0.2s, transform 0.2s;
}
.chat-slide-enter-from,
.chat-slide-leave-to {
  opacity: 0;
  transform: translateY(10px) scale(0.97);
}
</style>
