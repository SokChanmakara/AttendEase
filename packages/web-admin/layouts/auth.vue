<template>
  <div class="auth-layout">
    <div class="auth-card-container">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.auth-layout {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--background);
  position: relative;
  overflow: hidden;
}

.auth-layout::after {
  content: "";
  position: absolute;
  width: 150vw;
  height: 150vw;
  background: radial-gradient(circle, rgba(184, 134, 11, 0.05) 0%, transparent 70%);
  top: -75vw;
  left: -75vw;
  z-index: 0;
}

.auth-card-container {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 450px;
  padding: 2rem;
}
</style>
