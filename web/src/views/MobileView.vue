<template>
  <div class="mobile-page">
    <div class="mobile-inner">

      <!-- Hero: left = info, right = download badges -->
      <div class="hero">
        <!-- Left -->
        <div class="hero-left">
          <img src="/icon.png" alt="SoundSync" class="app-icon" />
          <h1 class="app-title">SoundSync</h1>

          <!-- Download badges — above the description -->
          <p class="download-label">Download the app</p>
          <div class="store-badges">
            <a
              href="https://play.google.com/store/apps/details?id=live.soundsync.app"
              target="_blank"
              rel="noopener noreferrer"
              class="store-badge android"
            >
              <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true">
                <path fill="#34A853" d="M3.18 23.76c.3.17.64.22.98.15l12.23-7.07-2.67-2.67-10.54 9.59z"/>
                <path fill="#4285F4" d="M.5 1.4C.19 1.72 0 2.22 0 2.89v18.22c0 .67.19 1.17.5 1.49l.08.07 10.21-10.2v-.24L.58 1.33.5 1.4z"/>
                <path fill="#FBBC04" d="M20.27 10.3l-2.91-1.68-3 2.99 3 3 2.94-1.7c.84-.48.84-1.27-.03-1.61z"/>
                <path fill="#EA4335" d="M4.16.24L16.39 7.3 13.72 10 3.18.41A1.2 1.2 0 0 1 4.16.24z"/>
              </svg>
              <div class="badge-text">
                <span class="badge-sub">Get it on</span>
                <span class="badge-main">Google Play</span>
              </div>
            </a>
            <div class="store-badge ios coming-soon">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <div class="badge-text">
                <span class="badge-sub">Coming soon on</span>
                <span class="badge-main">App Store</span>
              </div>
              <span class="coming-soon-chip">Soon</span>
            </div>
          </div>

          <p class="app-subtitle">Real-time King County transit — now in your pocket.</p>

          <ul class="feature-list">
            <li>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              Live bus &amp; train positions
            </li>
            <li>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              Stop arrival boards
            </li>
            <li>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              Route reliability scores
            </li>
            <li>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              Service alerts &amp; delay notifications
            </li>
          </ul>
        </div>

        <!-- Right: QR code -->
        <div class="hero-right">
          <div class="qr-box">
            <img v-if="qrDataUrl" :src="qrDataUrl" alt="Scan to download on Google Play" class="qr-img" />
            <div v-else class="qr-loading">Generating QR…</div>
            <span class="qr-label">Scan to download</span>
            <span class="qr-sub">Google Play Store</span>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import QRCode from 'qrcode'

const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=live.soundsync.app'
const qrDataUrl = ref('')

onMounted(async () => {
  qrDataUrl.value = await QRCode.toDataURL(PLAY_STORE_URL, {
    width: 200,
    margin: 2,
    color: { dark: '#1e293b', light: '#ffffff' },
  })
})
</script>

<style scoped>
.mobile-page {
  height: 100%;
  overflow-y: auto;
}

.mobile-inner {
  max-width: 900px;
  margin: 0 auto;
  padding: 3rem 2rem 4rem;
}

/* ── Hero two-column layout ── */
.hero {
  display: grid;
  grid-template-columns: 1fr 300px;
  gap: 3rem;
  align-items: start;
}

/* Left column */
.hero-left {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.app-icon {
  width: 80px;
  height: 80px;
  border-radius: 18px;
  margin-bottom: 1.25rem;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}

.app-title {
  font-size: 2.5rem;
  font-weight: 800;
  color: var(--color-text);
  margin-bottom: 0.5rem;
  line-height: 1.1;
}

.app-subtitle {
  font-size: 1rem;
  color: var(--color-text-muted);
  line-height: 1.6;
  margin-top: 1.5rem;
  margin-bottom: 1.25rem;
}

.feature-list {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 0.7rem;
}

.feature-list li {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  font-size: 0.9rem;
  color: var(--color-text-muted);
}

.feature-list li svg {
  color: var(--color-primary);
  flex-shrink: 0;
}

/* Right column */
.hero-right {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  align-items: stretch;
}

.download-label {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.06em;
  margin-bottom: 0.25rem;
}

.store-badges {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 0;
}

.store-badge {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  border-radius: 12px;
  border: 1px solid var(--color-border);
  background: var(--color-surface);
  text-decoration: none;
  color: var(--color-text);
  transition: border-color 0.15s, box-shadow 0.15s, transform 0.15s;
  position: relative;
}

.store-badge.android:hover {
  border-color: #34a853;
  box-shadow: 0 4px 16px rgba(52, 168, 83, 0.25);
  transform: translateY(-2px);
}

.store-badge.ios.coming-soon {
  opacity: 0.55;
  cursor: default;
}

.badge-text {
  display: flex;
  flex-direction: column;
}

.badge-sub {
  font-size: 0.62rem;
  color: var(--color-text-muted);
  line-height: 1.2;
}

.badge-main {
  font-size: 0.95rem;
  font-weight: 700;
  line-height: 1.2;
}

.coming-soon-chip {
  position: absolute;
  top: -8px;
  right: 10px;
  background: var(--color-primary);
  color: #fff;
  font-size: 0.6rem;
  font-weight: 700;
  padding: 0.1rem 0.45rem;
  border-radius: 999px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

/* QR */
.qr-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  border: 1px solid var(--color-border);
  border-radius: 16px;
  padding: 1.25rem;
  background: var(--color-surface);
}

.qr-img {
  width: 160px;
  height: 160px;
  border-radius: 8px;
  display: block;
}

.qr-loading {
  width: 160px;
  height: 160px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;
  color: var(--color-text-muted);
}

.qr-label {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--color-text);
}

.qr-sub {
  font-size: 0.68rem;
  color: var(--color-text-muted);
}

/* ── Mobile: stack columns ── */
@media (max-width: 620px) {
  .mobile-inner {
    padding: 1.5rem 1rem 3rem;
  }

  .hero {
    grid-template-columns: 1fr;
    gap: 2rem;
  }

  .hero-left {
    align-items: center;
    text-align: center;
  }

  .app-icon {
    align-self: center;
  }

  .app-title {
    font-size: 1.8rem;
    text-align: center;
  }

  .download-label {
    text-align: center;
  }

  .store-badges {
    flex-direction: column;
    align-items: center;
    width: 100%;
  }

  .store-badge {
    width: 100%;
    max-width: 260px;
    justify-content: center;
  }

  .app-subtitle {
    text-align: center;
  }

  .feature-list {
    align-items: center;
  }

  .hero-right {
    display: none;
  }
}
</style>
