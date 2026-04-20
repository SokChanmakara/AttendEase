<template>
  <div class="base-input-wrapper">
    <label v-if="label" class="base-label">{{ label }}</label>
    <div class="input-container" :class="{ 'has-error': error }">
      <input
        :value="modelValue"
        @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
        class="base-input"
        v-bind="$attrs"
      />
    </div>
    <span v-if="error" class="error-text">{{ error }}</span>
  </div>
</template>

<script setup lang="ts">
defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
  error: {
    type: String,
    default: '',
  },
});

defineEmits(['update:modelValue']);
</script>

<style scoped>
.base-input-wrapper {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  width: 100%;
}

.base-label {
  font-family: var(--font-mono);
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  color: var(--muted-foreground);
}

.input-container {
  position: relative;
}

.base-input {
  width: 100%;
  min-height: 48px; /* h-12 equivalent */
  padding: 0 1rem;
  font-family: var(--font-sans);
  font-size: 0.95rem;
  color: var(--foreground);
  background-color: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  transition: all 0.2s ease-out;
  outline: none;
}

.base-input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--background), 0 0 0 4px var(--accent); /* ring-offset equivalent */
}

.input-container.has-error .base-input {
  border-color: var(--error);
}

.error-text {
  color: var(--error);
  font-size: 0.75rem;
  margin-top: 0.25rem;
}
</style>
