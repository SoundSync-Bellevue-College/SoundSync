<template>
  <div class="route-detail-view">
    <div class="detail-header">
      <RouterLink to="/" class="back-link">← Back to Map</RouterLink>
      <h1 class="route-title">Route {{ routeId }}</h1>
    </div>

    <LoadingSpinner v-if="loading" overlay label="Loading route…" />

    <div v-else-if="route" class="detail-body">
      <div class="route-badge" :style="{ background: '#' + (route.color || '3b82f6') }">
        {{ route.shortName }}
      </div>
      <p class="route-name">{{ route.longName }}</p>

      <section class="section">
        <h2 class="section-title">Recent Condition Reports</h2>
        <p class="placeholder-text">Reports will appear here once they're submitted.</p>
      </section>

      <section class="section">
        <h2 class="section-title">Submit a Report</h2>
        <ConditionReportForm :routeId="routeId" />
      </section>
    </div>

    <p v-else class="error-text">Route not found.</p>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import type { Route } from '@/types/transit'
import { routeService } from '@/services/routeService'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import ConditionReportForm from '@/components/user/ConditionReportForm.vue'

const vueRoute = useRoute()
const routeId = vueRoute.params.id as string

const route = ref<Route | null>(null)
const loading = ref(true)

onMounted(async () => {
  try {
    route.value = await routeService.getRoute(routeId)
  } catch {
    route.value = null
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.route-detail-view {
  max-width: 720px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}

.detail-header {
  margin-bottom: 1.5rem;
}

.back-link {
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.route-title {
  font-size: 1.5rem;
  font-weight: 700;
  margin-top: 0.5rem;
}

.route-badge {
  display: inline-block;
  padding: 0.3rem 0.75rem;
  border-radius: var(--radius-sm);
  color: #fff;
  font-size: 1rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
}

.route-name {
  color: var(--color-text-muted);
  margin-bottom: 1.5rem;
}

.section {
  margin-bottom: 2rem;
}

.section-title {
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 0.75rem;
  color: var(--color-text);
}

.placeholder-text {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.error-text {
  color: var(--color-danger);
  padding: 2rem 0;
}
</style>
