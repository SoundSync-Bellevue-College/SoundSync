<template>
  <div class="home-view">
    <!-- Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-top">
        <WeatherWidget />
      </div>
      <RouteSearchPanel />
    </aside>

    <!-- Map fills remaining space -->
    <div class="map-area">
      <MapContainer />
    </div>
  </div>
</template>

<script setup lang="ts">
import MapContainer from '@/components/map/MapContainer.vue'
import RouteSearchPanel from '@/components/transit/RouteSearchPanel.vue'
import WeatherWidget from '@/components/weather/WeatherWidget.vue'
</script>

<style scoped>
.home-view {
  display: flex;
  height: 100%;
  overflow: hidden;
}

.sidebar {
  width: 380px;
  flex-shrink: 0;
  background: var(--color-bg);
  border-right: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  gap: 1rem;
  padding: 1rem;
  overflow-y: auto;
}

.sidebar-top {
  display: flex;
  justify-content: flex-end;
}

.map-area {
  flex: 1;
  position: relative;
  overflow: hidden;
}
</style>
