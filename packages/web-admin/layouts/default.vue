<template>
  <div class="layout-root">
    <aside class="sidebar">
      <div class="brand">
        <h1 class="brand-name">AttendEase</h1>
        <p class="brand-tagline">ADMIN SUITE</p>
      </div>

      <nav class="nav">
        <NuxtLink to="/" class="nav-item">
          <LayoutDashboard :size="18" class="icon" />
          <span>Dashboard</span>
        </NuxtLink>
        <NuxtLink to="/attendance" class="nav-item">
          <Clock :size="18" class="icon" />
          <span>Attendance</span>
        </NuxtLink>
        <NuxtLink to="/employees" class="nav-item">
          <Users :size="18" class="icon" />
          <span>Employees</span>
        </NuxtLink>
        <NuxtLink to="/leave" class="nav-item">
          <Umbrella :size="18" class="icon" />
          <span>Leave Requests</span>
        </NuxtLink>
        <NuxtLink to="/qr-management" class="nav-item">
          <QrCode :size="18" class="icon" />
          <span>QR Management</span>
        </NuxtLink>
        <NuxtLink to="/settings" class="nav-item">
          <Settings :size="18" class="icon" />
          <span>Settings</span>
        </NuxtLink>
      </nav>

      <div class="sidebar-footer">
        <button class="logout-link" @click="handleLogout">
          Sign Out
        </button>
      </div>
    </aside>

    <main class="main-content">
      <header class="top-bar">
        <div class="page-title">
          {{ currentPageTitle }}
        </div>
        <div class="top-bar-right">
          <span class="today-date">{{ todayDate }}</span>
        </div>
      </header>
      
      <div class="content-body">
        <slot />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { 
  LayoutDashboard, 
  Clock, 
  Users, 
  Umbrella, 
  QrCode, 
  Settings 
} from 'lucide-vue-next';

const route = useRoute();
const { logout } = useAuth();

const currentPageTitle = computed(() => {
  const path = route.path;
  if (path === '/') return 'Dashboard';
  if (path.startsWith('/attendance')) return 'Attendance';
  if (path.startsWith('/employees')) return 'Employees';
  if (path.startsWith('/leave')) return 'Leave Requests';
  if (path.startsWith('/qr-management')) return 'QR Management';
  if (path.startsWith('/settings')) return 'Settings';
  return 'Admin';
});

const todayDate = computed(() => {
  return new Intl.DateTimeFormat('en-GB', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    year: 'numeric'
  }).format(new Date()).toUpperCase();
});

async function handleLogout() {
  await logout();
  navigateTo('/login');
}
</script>

<style scoped>
.layout-root {
  display: flex;
  min-height: 100vh;
  background-color: var(--background);
}

.sidebar {
  width: var(--sidebar-width);
  background-color: var(--sidebar);
  border-right: 1px solid var(--sidebar-border);
  display: flex;
  flex-direction: column;
  padding: 2.5rem 0; /* No horizontal padding on sidebar container to let active border touch edge */
  position: sticky;
  top: 0;
  height: 100vh;
}

.brand {
  padding: 0 1.5rem;
  margin-bottom: 3.5rem;
}

.brand-name {
  font-family: var(--font-display);
  font-size: 1.5rem;
  color: var(--accent);
  margin: 0;
  line-height: 1;
}

.brand-tagline {
  font-family: var(--font-mono);
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  color: var(--muted-foreground);
  margin-top: 0.5rem;
}

.nav {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1.5rem;
  color: var(--muted-foreground);
  text-decoration: none;
  font-family: var(--font-mono);
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  transition: var(--transition-base);
  border-left: 0 solid transparent;
}

.nav-item:hover {
  color: var(--foreground);
}

.nav-item.router-link-active {
  color: var(--foreground);
  border-left: 3px solid var(--accent);
  background-color: transparent; /* Explicitly no fill as per prompt */
}

.icon {
  opacity: 0.6;
  transition: var(--transition-base);
}

.nav-item:hover .icon,
.nav-item.router-link-active .icon {
  opacity: 1;
  color: var(--accent);
}

.main-content {
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.top-bar {
  height: 80px;
  padding: 0 3rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--border);
  position: sticky;
  top: 0;
  z-index: 10;
  background-color: var(--background);
}

.page-title {
  font-family: var(--font-display);
  font-size: 28px;
}

.top-bar-right {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.today-date {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--muted-foreground);
  letter-spacing: 0.05em;
}

.content-body {
  padding: 3rem;
  width: 100%;
}

.sidebar-footer {
  margin-top: auto;
  padding: 2rem 1.5rem 0;
}

.logout-link {
  background: transparent;
  border: none;
  padding: 0;
  color: var(--muted-foreground);
  cursor: pointer;
  font-family: var(--font-mono);
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  transition: var(--transition-base);
}

.logout-link:hover {
  color: var(--status-red);
}
</style>

