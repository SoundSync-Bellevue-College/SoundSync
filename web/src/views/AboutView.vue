<template>
  <div class="about-page">

    <!-- Hero -->
    <section class="hero">
      <div class="hero-inner">
        <div class="hero-badge">Bellevue College · Senior Capstone Project</div>
        <h1 class="hero-title">Improving Public Transit<br>in King County</h1>
        <p class="hero-desc">
          SoundSyncAI is a student-built platform created by four Bellevue College students
          passionate about making public transportation more accessible, transparent, and
          data-driven for everyone in the King County area. We combine real-time transit data,
          crowdsourced reporting, and predictive analytics to help riders make smarter decisions
          every day.
        </p>
      </div>
    </section>

    <!-- Mission cards -->
    <section class="mission-section">
      <div class="mission-grid">
        <div class="mission-card" v-for="m in mission" :key="m.title">
          <span class="mission-icon">{{ m.icon }}</span>
          <h3 class="mission-title">{{ m.title }}</h3>
          <p class="mission-body">{{ m.body }}</p>
        </div>
      </div>
    </section>

    <!-- Team -->
    <section class="team-section">
      <h2 class="section-heading">Meet the Team</h2>
      <div class="team-grid">
        <div class="member-card" v-for="member in team" :key="member.name">

          <!-- Photo -->
          <div class="member-photo-wrap">
            <img
              :src="member.photo"
              :alt="member.name"
              class="member-photo"
            />
          </div>

          <!-- Info -->
          <div class="member-info">
            <div class="member-name-row">
              <h3 class="member-name">{{ member.name }}</h3>
              <span class="member-pronouns">{{ member.pronouns }}</span>
            </div>
            <p class="member-role">{{ member.role }}</p>
            <blockquote class="member-quote">"{{ member.quote }}"</blockquote>
            <p class="member-desc">{{ member.description }}</p>

            <!-- Social links -->
            <div class="member-socials">
              <a
                v-if="member.linkedin"
                :href="member.linkedin"
                target="_blank"
                rel="noopener noreferrer"
                class="social-link linkedin"
                title="LinkedIn"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064 0 1 1 2.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                </svg>
                LinkedIn
              </a>
              <a
                v-if="member.github"
                :href="member.github"
                target="_blank"
                rel="noopener noreferrer"
                class="social-link github"
                title="GitHub"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>
                </svg>
                GitHub
              </a>
              <a
                v-if="member.instagram"
                :href="member.instagram"
                target="_blank"
                rel="noopener noreferrer"
                class="social-link instagram"
                title="Instagram"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324zM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.406-11.845a1.44 1.44 0 1 0 0 2.881 1.44 1.44 0 0 0 0-2.881z"/>
                </svg>
                Instagram
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer note -->
    <section class="footer-note">
      <p>Built with ❤️ at <strong>Bellevue College</strong> · King County, WA</p>
      <p class="footer-links">
        <RouterLink to="/privacy" class="footer-link">Privacy Policy</RouterLink>
      </p>
    </section>

  </div>
</template>

<script setup lang="ts">
import abshiraPhoto from '@/assets/team/abshira.jpg'
import tonyPhoto from '@/assets/team/tony.jpg'
import nolanPhoto from '@/assets/team/nolan.jpg'
import waynePhoto from '@/assets/team/wayne.jpg'

const mission = [
  {
    icon: '🚌',
    title: 'Real-Time Awareness',
    body: 'Live vehicle positions, arrival predictions, and delay tracking across King County Metro and Sound Transit routes.',
  },
  {
    icon: '📊',
    title: 'Reliability Insights',
    body: 'Historical on-time data and time-of-day breakdowns so riders know when their bus actually shows up.',
  },
  {
    icon: '🤝',
    title: 'Community Reporting',
    body: 'Crowdsourced cleanliness, crowding, and delay reports that keep fellow riders informed in real time.',
  },
]

const team = [
  {
    name: 'Abshira',
    pronouns: 'she/her',
    role: 'UI Front End & Mobile',
    photo: abshiraPhoto,
    quote: 'Add your personal quote here.',
    description: 'Add a short description of your responsibilities and contributions to the project here.',
    linkedin: 'https://www.linkedin.com/in/abshira-salat-ba1829260/',
    github: 'https://github.com/AbshiraSalat',
    instagram: '',
  },
  {
    name: 'Tony',
    pronouns: 'he/him',
    role: 'System DevOps, Authentication & Security',
    photo: tonyPhoto,
    quote: 'Add your personal quote here.',
    description: 'Add a short description of your responsibilities and contributions to the project here.',
    linkedin: 'https://www.linkedin.com/in/anye-che-b59624202/',
    github: 'https://github.com/cheTonyA',
    instagram: '',
  },
  {
    name: 'Nolan',
    pronouns: 'he/him',
    role: 'Performance Metrics, AI Prediction Model & LLM Integration',
    photo: nolanPhoto,
    quote: 'Add your personal quote here.',
    description: 'Add a short description of your responsibilities and contributions to the project here.',
    linkedin: 'https://www.linkedin.com/in/nolan-ngo-2b3304203/',
    github: 'https://github.com/nolngo',
    instagram: '',
  },
  {
    name: 'Wayne',
    pronouns: 'he/him',
    role: 'Backend, Testing, API & Database Management',
    photo: waynePhoto,
    quote: 'Add your personal quote here.',
    description: 'Add a short description of your responsibilities and contributions to the project here.',
    linkedin: 'https://www.linkedin.com/in/thu-san/',
    github: 'https://github.com/waynesan41',
    instagram: '',
  },
]
</script>

<style scoped>
/* Root scrolls within the fixed-height main-content container */
.about-page {
  height: 100%;
  overflow-y: auto;
}

.about-inner {
  max-width: 1100px;
  margin: 0 auto;
  padding: 2rem 1.5rem 4rem;
  display: flex;
  flex-direction: column;
  gap: 3rem;
}

/* ── Hero ────────────────────────────────────────────────────────────────── */

.hero {
  text-align: center;
  padding: 2.5rem 1rem 0.5rem;
}

.hero-badge {
  display: inline-block;
  background: color-mix(in srgb, var(--color-primary) 15%, transparent);
  color: var(--color-primary);
  border: 1px solid color-mix(in srgb, var(--color-primary) 30%, transparent);
  border-radius: 999px;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.04em;
  padding: 0.3rem 1rem;
  margin-bottom: 1rem;
  text-transform: uppercase;
}

.hero-title {
  font-size: clamp(1.1rem, 2.5vw, 1.6rem);
  font-weight: 800;
  color: var(--color-text);
  line-height: 1.2;
  margin-bottom: 1rem;
}

.hero-desc {
  max-width: 660px;
  margin: 0 auto;
  font-size: 0.95rem;
  color: var(--color-text-muted);
  line-height: 1.7;
}

/* ── Mission ─────────────────────────────────────────────────────────────── */

.mission-section {
  margin-top: 2.5rem;
}

.mission-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
  max-width: 800px;
  margin: 0 auto;
  padding: 0 1rem;
}

.mission-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.mission-icon { font-size: 1.6rem; line-height: 1; }

.mission-title {
  font-size: 0.9rem;
  font-weight: 700;
  color: var(--color-text);
}

.mission-body {
  font-size: 0.82rem;
  color: var(--color-text-muted);
  line-height: 1.6;
}

/* ── Team ────────────────────────────────────────────────────────────────── */

.section-heading {
  font-size: 2rem;
  font-weight: 800;
  color: var(--color-text);
  margin-bottom: 1.25rem;
  text-align: center;
}

.team-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.25rem;
  max-width: 700px;
  margin: 0 auto;
}

.member-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: transform 0.2s, box-shadow 0.2s;
}

.member-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.member-photo-wrap {
  width: 100%;
  aspect-ratio: 1;
  overflow: hidden;
  background: var(--color-bg);
  flex-shrink: 0;
}

.member-photo {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: top;
  display: block;
}

.member-info {
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  flex: 1;
}

.member-name-row {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
}

.member-name {
  font-size: 1rem;
  font-weight: 700;
  color: var(--color-text);
}

.member-pronouns {
  font-size: 0.7rem;
  color: var(--color-text-muted);
}

.member-role {
  font-size: 0.72rem;
  font-weight: 600;
  color: var(--color-primary);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.member-quote {
  font-size: 0.78rem;
  color: var(--color-text-muted);
  font-style: italic;
  border-left: 2px solid var(--color-primary);
  padding-left: 0.6rem;
  margin: 0.2rem 0;
  line-height: 1.5;
}

.member-desc {
  font-size: 0.8rem;
  color: var(--color-text-muted);
  line-height: 1.6;
  flex: 1;
}

/* ── Social links ────────────────────────────────────────────────────────── */

.member-socials {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  margin-top: 0.4rem;
}

.social-link {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.2rem 0.5rem;
  border-radius: 999px;
  font-size: 0.7rem;
  font-weight: 600;
  text-decoration: none;
  border: 1px solid var(--color-border);
  color: var(--color-text-muted);
  background: var(--color-bg);
  transition: color 0.15s, border-color 0.15s;
}

.social-link.linkedin:hover  { color: #0a66c2; border-color: #0a66c2; }
.social-link.github:hover    { color: #e6edf3; border-color: #e6edf3; }
.social-link.instagram:hover { color: #e1306c; border-color: #e1306c; }

/* ── Footer note ─────────────────────────────────────────────────────────── */

.footer-note {
  text-align: center;
  font-size: 0.82rem;
  color: var(--color-text-muted);
  padding-top: 1rem;
  padding-bottom: 3rem;
  border-top: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.footer-links {
  display: flex;
  justify-content: center;
  gap: 1.25rem;
}

.footer-link {
  color: var(--color-text-muted);
  font-size: 0.8rem;
  text-decoration: none;
  transition: color 0.15s;
}

.footer-link:hover {
  color: var(--color-primary);
}

/* ── Tablet (≤ 900px) ────────────────────────────────────────────────────── */

@media (max-width: 900px) {
  .mission-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

/* ── Mobile (≤ 580px) ────────────────────────────────────────────────────── */

@media (max-width: 580px) {
  .about-inner {
    padding: 1.25rem 1rem 3rem;
    gap: 2rem;
  }

  .hero {
    padding: 1.25rem 0 0;
  }

  .hero-title br { display: none; }

  .mission-grid {
    grid-template-columns: 1fr;
  }

  /* Horizontal card layout on mobile */
  .team-grid {
    grid-template-columns: 1fr;
    gap: 0.875rem;
  }

  .member-card {
    flex-direction: row;
  }

  .member-photo-wrap {
    width: 110px;
    aspect-ratio: unset;
    height: auto;
    min-height: 110px;
  }

  .member-info {
    padding: 0.875rem;
  }

  .member-name { font-size: 0.95rem; }
  .member-quote { display: none; }
}
</style>
