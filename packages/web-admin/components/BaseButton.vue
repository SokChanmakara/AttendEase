<template>
  <button
    :class="[
      'base-button',
      `variant-${variant}`,
      { 'is-loading': loading }
    ]"
    :disabled="disabled || loading"
    v-bind="$attrs"
  >
    <span v-if="loading" class="spinner"></span>
    <span :class="{ 'opacity-0': loading }">
      <slot />
    </span>
  </button>
</template>

<script setup lang="ts">
defineProps({
  variant: {
    type: String,
    default: 'primary',
  },
  loading: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});
</script>

<style scoped>
.base-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem 1.5rem;
  font-family: var(--font-mono);
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.1em;
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: var(--transition-base);
  border: 1px solid transparent;
  min-height: 36px;
  width: fit-content;
  text-transform: uppercase;
  touch-action: manipulation;
}

.base-button:disabled {
  cursor: not-allowed;
  opacity: 0.4;
  filter: grayscale(1);
}

/* Primary Variant */
.variant-primary {
  background-color: var(--accent);
  color: #000; /* Black text on gold is more editorial */
}

.variant-primary:hover:not(:disabled) {
  background-color: #dcb85c;
  transform: translateY(-1px);
}

/* Secondary Variant */
.variant-secondary {
  background-color: transparent;
  border-color: #333;
  color: var(--foreground);
}

.variant-secondary:hover:not(:disabled) {
  border-color: var(--accent);
  color: var(--accent);
}

/* Ghost Variant */
.variant-ghost {
  background-color: transparent;
  color: var(--muted-foreground);
  border: none;
}

.variant-ghost:hover:not(:disabled) {
  color: var(--foreground);
  background-color: rgba(255, 255, 255, 0.05);
}

.spinner {
  position: absolute;
  width: 1rem;
  height: 1rem;
  border: 2px solid currentColor;
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.opacity-0 {
  opacity: 0;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>

