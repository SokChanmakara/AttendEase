<template>
  <div class="table-container">
    <table class="base-table">
      <thead>
        <tr>
          <th v-for="header in headers" :key="header">{{ header }}</th>
        </tr>
      </thead>
      <tbody>
        <slot />
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
defineProps({
  headers: {
    type: Array as () => string[],
    required: true,
  },
});
</script>

<style scoped>
.table-container {
  width: 100%;
  overflow-x: auto;
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  background: var(--card);
}

.base-table {
  width: 100%;
  border-collapse: collapse;
  font-family: var(--font-sans);
  font-size: 0.9rem;
}

.base-table th {
  padding: 1rem 1.5rem;
  text-align: left;
  background-color: var(--muted);
  color: var(--muted-foreground);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-size: 0.75rem;
  border-bottom: 1px solid var(--border);
}

.base-table td {
  padding: 1rem 1.5rem;
  border-bottom: 1px solid var(--border);
  color: var(--foreground);
}

.base-table tr:last-child td {
  border-bottom: none;
}

.base-table tr:hover td {
  background-color: rgba(245, 243, 240, 0.5);
}
</style>
