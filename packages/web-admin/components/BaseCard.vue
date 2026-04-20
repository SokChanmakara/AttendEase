<template>
  <div
    :class="[
      'base-card',
      { 'is-elevated': elevated }
    ]"
  >
    <div v-if="$slots.header" class="card-header">
      <slot name="header" />
    </div>
    <div class="card-content">
      <slot />
    </div>
    <div v-if="$slots.footer" class="card-footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps({
  elevated: {
    type: Boolean,
    default: false,
  },
});
</script>

<style scoped>
.base-card {
  background-color: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  overflow: hidden;
  padding: 28px;
  transition: var(--transition-base), transform 0.2s ease-out;
}

.base-card:hover {
  border-color: #3a3a3a;
  transform: translateY(-1px);
}

.card-header {
  margin-bottom: 24px;
}

.card-content {
  /* No extra padding needed as the base container has it */
}

.card-footer {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid var(--border);
}

:deep(h2), :deep(h3) {
  margin-bottom: 0.75rem;
  color: var(--foreground);
  font-family: var(--font-display);
  font-weight: 400;
}
</style>

