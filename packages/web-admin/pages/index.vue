<template>
  <div class="dashboard">
    <div class="stats-grid">
      <!-- Present Card -->
      <BaseCard class="stat-card">
        <div class="stat-header">
          <span class="stat-label">Present Today</span>
          <CheckCircle2 :size="18" class="stat-icon text-success" />
        </div>
        <div 
          class="stat-value"
          v-motion
          :initial="{ opacity: 0, y: 10 }"
          :enter="{ opacity: 1, y: 0, transition: { duration: 600, delay: 100 } }"
        >
          12
        </div>
        <p class="stat-trend trend-positive">+2 from yesterday</p>
      </BaseCard>

      <!-- Leave Card -->
      <BaseCard class="stat-card">
        <div class="stat-header">
          <span class="stat-label">On Leave</span>
          <Umbrella :size="18" class="stat-icon text-muted" />
        </div>
        <div 
          class="stat-value"
          v-motion
          :initial="{ opacity: 0, y: 10 }"
          :enter="{ opacity: 1, y: 0, transition: { duration: 600, delay: 200 } }"
        >
          3
        </div>
        <p class="stat-trend trend-neutral">Standard volume</p>
      </BaseCard>

      <!-- Pending Card -->
      <BaseCard class="stat-card">
        <div class="stat-header">
          <span class="stat-label">Pending Requests</span>
          <Clock :size="18" class="stat-icon text-warning" />
        </div>
        <div 
          class="stat-value"
          v-motion
          :initial="{ opacity: 0, y: 10 }"
          :enter="{ opacity: 1, y: 0, transition: { duration: 600, delay: 300 } }"
        >
          5
        </div>
        <p class="stat-trend trend-warning">Action required</p>
      </BaseCard>
    </div>

    <div class="dashboard-sections">
      <div class="section-column main-col">
        <SectionLabel>Recent Activity</SectionLabel>
        <BaseCard class="activity-card">
          <BaseTable :headers="['Employee', 'Time', 'Action', 'Status']">
            <tr v-for="i in 5" :key="i">
              <td>
                <div class="employee-cell">
                  <div class="avatar">{{ ['JS', 'MD', 'RB', 'KL', 'AW'][i-1] }}</div>
                  <div class="employee-info">
                    <span class="name">{{ ['John Smith', 'Maria Garcia', 'Robert Brown', 'Kevin Lee', 'Alice Wong'][i-1] }}</span>
                  </div>
                </div>
              </td>
              <td class="mono text-subtle">09:{{ 10 + i }} AM</td>
              <td class="mono">Check In</td>
              <td><span class="status-pill status-present">On Time</span></td>
            </tr>
          </BaseTable>
          <template #footer>
            <div class="footer-link">
              <NuxtLink to="/attendance" class="text-accent small-caps">View all records &rarr;</NuxtLink>
            </div>
          </template>
        </BaseCard>
      </div>

      <div class="section-column side-col">
        <SectionLabel>Upcoming</SectionLabel>
        <BaseCard class="upcoming-card">
          <template #header>
            <h3 class="display-serif">Upcoming Leave</h3>
          </template>
          <div class="empty-state">
            <p class="text-subtle">No upcoming leave for the next 7 days.</p>
          </div>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { CheckCircle2, Umbrella, Clock } from 'lucide-vue-next';
</script>

<style scoped>
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.stat-label {
  font-family: var(--font-mono);
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--muted-foreground);
}

.stat-value {
  font-family: var(--font-display);
  font-size: 56px;
  line-height: 1;
  color: var(--foreground);
  margin-bottom: 12px;
}

.stat-trend {
  font-family: var(--font-sans);
  font-size: 12px;
}

.trend-positive { color: var(--status-green); }
.trend-warning { color: var(--status-red); }
.trend-neutral { color: var(--muted-foreground); }

.text-success { color: var(--status-green); }
.text-warning { color: var(--status-amber); }
.text-muted { color: var(--muted-foreground); }

.dashboard-sections {
  display: grid;
  grid-template-columns: 1.3fr 0.7fr;
  gap: 2.5rem;
}

.employee-cell {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.avatar {
  width: 28px;
  height: 28px;
  background-color: #222;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-mono);
  font-size: 10px;
  color: var(--accent);
  border: 1px solid var(--border);
}

.employee-info .name {
  font-weight: 500;
  font-size: 13px;
}

.footer-link {
  display: flex;
  justify-content: flex-start;
}

.empty-state {
  text-align: center;
  padding: 2rem 1rem;
  border: 1px dashed var(--border);
  border-radius: var(--radius-sm);
}

@media (max-width: 1024px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }
  .dashboard-sections {
    grid-template-columns: 1fr;
  }
}
</style>
