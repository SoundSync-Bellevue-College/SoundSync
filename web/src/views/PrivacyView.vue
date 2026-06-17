<template>
  <div class="privacy-page">
    <div class="privacy-inner">

      <div class="page-header">
        <div class="page-badge">Legal</div>
        <h1 class="page-title">Privacy Policy</h1>
        <p class="page-meta">Effective date: May 25, 2025 &nbsp;·&nbsp; SoundSync · King County, WA</p>
      </div>

      <div class="toc">
        <p class="toc-label">On this page</p>
        <ol class="toc-list">
          <li v-for="s in sections" :key="s.id">
            <a :href="`#${s.id}`">{{ s.title }}</a>
          </li>
        </ol>
      </div>

      <section v-for="s in sections" :key="s.id" :id="s.id" class="policy-section">
        <h2 class="section-title">{{ s.title }}</h2>
        <div class="section-body" v-html="s.body" />
      </section>

      <div class="contact-card">
        <h3 class="contact-title">Questions or requests?</h3>
        <p class="contact-body">
          This is a student capstone project built at Bellevue College. If you have questions about
          your data or this policy, reach out via the project's
          <a href="https://github.com/SoundSync-Bellevue-College" target="_blank" rel="noopener noreferrer">
            GitHub organisation
          </a>.
        </p>
      </div>

      <p class="back-link-row">
        <RouterLink to="/about" class="back-link">← Back to About</RouterLink>
      </p>

    </div>
  </div>
</template>

<script setup lang="ts">
const sections = [
  {
    id: 'overview',
    title: '1. Overview',
    body: `
      <p>SoundSync ("we", "us", "our") is a student-built transit companion for King County,
      Washington. This policy explains what personal information we collect when you use
      <strong>soundsync.live</strong> or the SoundSync mobile app, how we use it, and the
      choices you have.</p>
      <p>We collect the minimum data needed to operate the service. We do not sell your data,
      serve advertisements, or share your information with third-party marketers.</p>
    `,
  },
  {
    id: 'what-we-collect',
    title: '2. Information We Collect',
    body: `
      <h4>Account data</h4>
      <p>When you register, we store your <strong>display name</strong>, <strong>email address</strong>,
      and a <strong>bcrypt password hash</strong>. We never store your plaintext password.</p>

      <h4>Location data</h4>
      <p>If you grant location permission, we use your device's coordinates to show nearby bus stops
      and current weather. Location is sent to our server only for that request and is not stored
      or logged.</p>

      <h4>Transit activity</h4>
      <p>We store the <strong>favorite routes</strong> you save and any <strong>crowdsourced reports</strong>
      you submit (vehicle cleanliness, crowding, or delay). Reports are linked to your account so
      you can view and delete them later.</p>

      <h4>Notifications</h4>
      <p>If notifications are enabled, we store in-app alert records tied to your account. No
      device push tokens are collected at this time.</p>

      <h4>Usage logs</h4>
      <p>Our server logs standard HTTP request metadata (timestamp, path, response status). These
      logs are used for debugging and are not linked to individual accounts.</p>

      <h4>No tracking or analytics</h4>
      <p>We do not use cookies, fingerprinting, or third-party analytics scripts.</p>
    `,
  },
  {
    id: 'how-we-use',
    title: '3. How We Use Your Information',
    body: `
      <ul>
        <li>Authenticate your session and keep you signed in via a JWT token stored in your browser.</li>
        <li>Display your saved favorites and notification history.</li>
        <li>Attribute crowdsourced reports to your account so you can manage them.</li>
        <li>Retrieve nearby transit stops and weather based on your location (not stored).</li>
        <li>Improve reliability predictions using aggregated, anonymised arrival data.</li>
      </ul>
      <p>We do not use your data for profiling, targeted advertising, or any automated
      decision-making that produces legal or significant effects.</p>
    `,
  },
  {
    id: 'data-sharing',
    title: '4. Data Sharing',
    body: `
      <p>We do not sell or rent your personal data. Data is shared only in these limited cases:</p>
      <ul>
        <li><strong>Infrastructure providers:</strong> The app runs on AWS Amplify and MongoDB Atlas.
        These providers process data on our behalf under their own privacy and security programmes.</li>
        <li><strong>Transit APIs:</strong> Route-planning and real-time vehicle requests are forwarded
        to the OneBusAway / King County Metro API. We do not include your account identifier in
        those requests.</li>
        <li><strong>Weather API:</strong> Your coordinates are sent to a third-party weather service
        to retrieve current conditions. No account data is included.</li>
        <li><strong>Legal requirements:</strong> We may disclose data if required by law or to
        protect the rights and safety of users.</li>
      </ul>
    `,
  },
  {
    id: 'data-retention',
    title: '5. Data Retention',
    body: `
      <p>Account data and associated records are kept for as long as your account is active.
      You can delete your account at any time from the <strong>Account → Settings</strong> page,
      which permanently removes your profile, favorites, and reports.</p>
      <p>Server access logs are retained for up to 30 days and then automatically purged.</p>
    `,
  },
  {
    id: 'your-rights',
    title: '6. Your Rights',
    body: `
      <p>You have the right to:</p>
      <ul>
        <li><strong>Access</strong> — request a copy of the personal data we hold about you.</li>
        <li><strong>Correction</strong> — update your display name or email from the Account page.</li>
        <li><strong>Deletion</strong> — delete your account and all associated data at any time.</li>
        <li><strong>Portability</strong> — request an export of your reports and favorites.</li>
        <li><strong>Opt-out of notifications</strong> — toggle notifications off in Account Settings.</li>
      </ul>
      <p>To exercise rights beyond what the app UI provides, contact us via GitHub (see below).</p>
    `,
  },
  {
    id: 'security',
    title: '7. Security',
    body: `
      <p>Passwords are hashed with bcrypt before storage. API sessions use short-lived signed JWTs.
      All traffic between your browser and our servers is encrypted with TLS.</p>
      <p>As a student project, this service does not have a dedicated security team. If you discover
      a vulnerability, please report it responsibly via our GitHub repository.</p>
    `,
  },
  {
    id: 'children',
    title: '8. Children\'s Privacy',
    body: `
      <p>SoundSync is not directed at children under 13. We do not knowingly collect personal
      information from children. If we become aware that a child under 13 has provided us with
      personal data, we will delete it promptly.</p>
    `,
  },
  {
    id: 'changes',
    title: '9. Changes to This Policy',
    body: `
      <p>We may update this policy as the service evolves. When we make material changes we will
      update the effective date at the top of this page. Continued use of the service after changes
      are posted constitutes acceptance of the revised policy.</p>
    `,
  },
]
</script>

<style scoped>
.privacy-page {
  height: 100%;
  overflow-y: auto;
}

.privacy-inner {
  max-width: 760px;
  margin: 0 auto;
  padding: 2.5rem 1.5rem 5rem;
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

/* ── Header ──────────────────────────────────────────────────────────────── */

.page-header {
  text-align: center;
  padding-bottom: 0.5rem;
}

.page-badge {
  display: inline-block;
  background: color-mix(in srgb, var(--color-primary) 15%, transparent);
  color: var(--color-primary);
  border: 1px solid color-mix(in srgb, var(--color-primary) 30%, transparent);
  border-radius: 999px;
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.06em;
  padding: 0.25rem 0.9rem;
  margin-bottom: 0.75rem;
  text-transform: uppercase;
}

.page-title {
  font-size: clamp(1.6rem, 3vw, 2.2rem);
  font-weight: 800;
  color: var(--color-text);
  margin-bottom: 0.4rem;
}

.page-meta {
  font-size: 0.8rem;
  color: var(--color-text-muted);
}

/* ── Table of contents ───────────────────────────────────────────────────── */

.toc {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 1.25rem 1.5rem;
}

.toc-label {
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--color-text-muted);
  margin-bottom: 0.75rem;
}

.toc-list {
  padding-left: 1.2rem;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.toc-list li a {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  text-decoration: none;
  transition: color 0.15s;
}

.toc-list li a:hover {
  color: var(--color-primary);
}

/* ── Sections ────────────────────────────────────────────────────────────── */

.policy-section {
  scroll-margin-top: 1rem;
}

.section-title {
  font-size: 1.1rem;
  font-weight: 700;
  color: var(--color-text);
  margin-bottom: 0.75rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--color-border);
}

.section-body :deep(p) {
  font-size: 0.9rem;
  color: var(--color-text-muted);
  line-height: 1.75;
  margin-bottom: 0.75rem;
}

.section-body :deep(p:last-child) {
  margin-bottom: 0;
}

.section-body :deep(h4) {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--color-text);
  margin: 1rem 0 0.35rem;
}

.section-body :deep(h4:first-child) {
  margin-top: 0;
}

.section-body :deep(ul),
.section-body :deep(ol) {
  padding-left: 1.35rem;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  margin-bottom: 0.75rem;
}

.section-body :deep(li) {
  font-size: 0.88rem;
  color: var(--color-text-muted);
  line-height: 1.65;
}

.section-body :deep(strong) {
  color: var(--color-text);
  font-weight: 600;
}

.section-body :deep(a) {
  color: var(--color-primary);
  text-decoration: underline;
  text-underline-offset: 2px;
}

/* ── Contact card ────────────────────────────────────────────────────────── */

.contact-card {
  background: color-mix(in srgb, var(--color-primary) 8%, var(--color-surface));
  border: 1px solid color-mix(in srgb, var(--color-primary) 25%, transparent);
  border-radius: var(--radius-lg);
  padding: 1.25rem 1.5rem;
}

.contact-title {
  font-size: 0.95rem;
  font-weight: 700;
  color: var(--color-text);
  margin-bottom: 0.4rem;
}

.contact-body {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  line-height: 1.65;
}

.contact-body a {
  color: var(--color-primary);
}

/* ── Back link ───────────────────────────────────────────────────────────── */

.back-link-row {
  padding-top: 0.5rem;
}

.back-link {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  text-decoration: none;
  transition: color 0.15s;
}

.back-link:hover {
  color: var(--color-primary);
}

/* ── Mobile ──────────────────────────────────────────────────────────────── */

@media (max-width: 580px) {
  .privacy-inner {
    padding: 1.5rem 1rem 4rem;
    gap: 1.5rem;
  }
}
</style>
