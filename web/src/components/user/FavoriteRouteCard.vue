<template>
  <div class="fav-card">
    <div class="fav-info">
      <p class="fav-label">{{ favorite.label }}</p>
      <p class="fav-route">
        {{ favorite.origin.name }} → {{ favorite.destination.name }}
      </p>
      <div class="fav-tags">
        <span v-for="id in favorite.transitRouteIds" :key="id" class="route-tag">
          {{ id }}
        </span>
      </div>
    </div>
    <button class="btn-remove" title="Remove favorite" @click="$emit('remove', favorite._id)">
      ✕
    </button>
  </div>
</template>

<script setup lang="ts">
import type { FavoriteRoute } from '@/types/user'

defineProps<{ favorite: FavoriteRoute }>()
defineEmits<{ remove: [id: string] }>()
</script>

<style scoped>
.fav-card {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  background: var(--color-surface);
  border-radius: var(--radius-md);
  padding: 0.75rem 1rem;
}

.fav-info {
  flex: 1;
}

.fav-label {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--color-text);
  margin-bottom: 0.2rem;
}

.fav-route {
  font-size: 0.8rem;
  color: var(--color-text-muted);
  margin-bottom: 0.4rem;
}

.fav-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}

.route-tag {
  background: var(--color-primary);
  color: #fff;
  font-size: 0.7rem;
  font-weight: 700;
  padding: 0.1rem 0.4rem;
  border-radius: 3px;
}

.btn-remove {
  background: transparent;
  color: var(--color-text-muted);
  font-size: 0.8rem;
  padding: 0.2rem;
  transition: color 0.15s;
}

.btn-remove:hover {
  color: var(--color-danger);
}
</style>
