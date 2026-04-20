<template>
  <div class="login-page">
    <div class="login-header">
      <h1 class="display-serif">AttendEase</h1>
      <p class="text-subtle">Admin Portal Access</p>
    </div>

    <BaseCard class="login-card" elevated>
      <form @submit.prevent="handleLogin" class="login-form">
        <BaseInput
          v-model="email"
          label="Email Address"
          type="email"
          placeholder="admin@company.com"
          required
          :disabled="loading"
        />

        <BaseInput
          v-model="password"
          label="Password"
          type="password"
          placeholder="••••••••"
          required
          :disabled="loading"
        />

        <div v-if="error" class="error-banner">
          {{ error }}
        </div>

        <BaseButton
          type="submit"
          class="w-full"
          :loading="loading"
        >
          {{ loading ? 'Authenticating...' : 'Sign In' }}
        </BaseButton>
      </form>
    </BaseCard>

    <div class="login-footer">
      <p>&copy; 2026 AttendEase. All rights reserved.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: 'auth',
});

const { login } = useAuth();
const email = ref('');
const password = ref('');
const loading = ref(false);
const error = ref('');

const handleLogin = async () => {
  error.value = '';
  loading.value = true;
  try {
    await login(email.value, password.value);
    navigateTo('/');
  } catch (e: any) {
    error.value = e.message || 'Login failed. Please check your credentials.';
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.login-page {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.login-header {
  text-align: center;
}

.login-header h1 {
  font-size: 2.5rem;
  color: var(--accent);
  margin-bottom: 0.5rem;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.w-full {
  width: 100%;
}

.error-banner {
  padding: 0.75rem;
  background-color: #fee2e2;
  color: #ef4444;
  border-radius: var(--radius);
  font-size: 0.875rem;
  text-align: center;
}

.login-footer {
  text-align: center;
  font-size: 0.75rem;
  color: var(--muted-foreground);
}
</style>
