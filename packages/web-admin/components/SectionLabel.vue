<template>
  <div class="section-label">
    <span class="text"><slot /></span>
    <span class="line"></span>
  </div>
</template>

<style scoped>
.section-label {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1.5rem;
  width: 100%;
}

.line {
  height: 1px;
  flex: 1;
  background-color: var(--border);
}

.text {
  font-family: var(--font-mono);
  font-size: 10px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--muted-foreground);
  white-space: nowrap;
}
</style>

