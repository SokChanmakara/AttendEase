<template>
  <div class="dashboard">
    <div class="stats-grid">
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
          {{ presentToday }}
        </div>
        <p class="stat-trend trend-neutral">Open or completed attendance records today</p>
      </BaseCard>

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
          {{ onLeaveToday }}
        </div>
        <p class="stat-trend trend-neutral">Approved leave entries for today</p>
      </BaseCard>

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
          {{ pendingRequests }}
        </div>
        <p class="stat-trend trend-warning">Leave requests awaiting approval</p>
      </BaseCard>
    </div>

    <div class="dashboard-sections">
      <div class="section-column main-col">
        <SectionLabel>Recent Activity</SectionLabel>
        <BaseCard class="activity-card">
          <BaseTable :headers="['Employee', 'Time', 'Action', 'Status']">
            <tr v-for="row in recentActivity" :key="row.id">
              <td>
                <div class="employee-cell">
                  <div class="avatar">{{ row.initials }}</div>
                  <div class="employee-info">
                    <span class="name">{{ row.userName }}</span>
                  </div>
                </div>
              </td>
              <td class="mono text-subtle">{{ row.time }}</td>
              <td class="mono">{{ row.action }}</td>
              <td><span :class="['status-pill', row.statusClass]">{{ row.statusText }}</span></td>
            </tr>
            <tr v-if="recentActivity.length === 0">
              <td colspan="4" class="empty-cell">No attendance activity found.</td>
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
          <div class="empty-state" v-if="upcomingLeave.length === 0">
            <p class="text-subtle">No upcoming leave for the next 7 days.</p>
          </div>
          <div v-else class="upcoming-list">
            <div v-for="leave in upcomingLeave" :key="leave.id" class="upcoming-item">
              <p class="mono">{{ leave.userName }}</p>
              <p class="text-subtle">{{ leave.dateRange }}</p>
            </div>
          </div>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { CheckCircle2, Umbrella, Clock } from 'lucide-vue-next';
import { collection, getDocs, limit, orderBy, query } from 'firebase/firestore';

const { db } = useFirebase();

const companyId = ref('acme');
const presentToday = ref(0);
const onLeaveToday = ref(0);
const pendingRequests = ref(0);
const recentActivity = ref<any[]>([]);
const upcomingLeave = ref<any[]>([]);

const formatYmd = (date: Date) => date.toISOString().slice(0, 10);

const loadDashboard = async () => {
  try {
    const [attendanceSnap, leaveSnap] = await Promise.all([
      getDocs(query(collection(db, `companies/${companyId.value}/attendance`), orderBy('check_in_at', 'desc'), limit(200))),
      getDocs(collection(db, `companies/${companyId.value}/leave_requests`)),
    ]);

    const today = formatYmd(new Date());
    const plusSeven = formatYmd(new Date(Date.now() + 7 * 24 * 3600 * 1000));

    const attendanceRows = attendanceSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() })) as any[];
    const leaveRows = leaveSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() })) as any[];

    presentToday.value = attendanceRows.filter((row) => {
      const checkIn = (row.check_in_at as any)?.toDate?.();
      return checkIn && formatYmd(checkIn) === today;
    }).length;

    pendingRequests.value = leaveRows.filter((row) => row.status === 'pending').length;
    onLeaveToday.value = leaveRows.filter((row) => {
      if (row.status !== 'approved') return false;
      return row.start_date <= today && row.end_date >= today;
    }).length;

    recentActivity.value = attendanceRows.slice(0, 5).map((row) => {
      const userName = row.user_name || 'Unknown';
      const initials = userName
        .split(' ')
        .map((n: string) => n[0] || '')
        .join('')
        .slice(0, 2)
        .toUpperCase();
      const checkOut = (row.check_out_at as any)?.toDate?.();
      const checkIn = (row.check_in_at as any)?.toDate?.();
      const action = checkOut ? 'Check Out' : 'Check In';
      const actionDate = checkOut || checkIn;

      return {
        id: row.id,
        userName,
        initials: initials || 'NA',
        action,
        time: actionDate ? actionDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '-',
        statusText: row.status || (checkOut ? 'Completed' : 'Present'),
        statusClass: checkOut ? 'status-absent' : 'status-present',
      };
    });

    upcomingLeave.value = leaveRows
      .filter((row) => row.status === 'approved' && row.start_date > today && row.start_date <= plusSeven)
      .sort((a, b) => String(a.start_date).localeCompare(String(b.start_date)))
      .slice(0, 5)
      .map((row) => ({
        id: row.id,
        userName: row.user_name || row.user_id || 'Unknown',
        dateRange: `${row.start_date} to ${row.end_date}`,
      }));
  } catch (e) {
    console.error('Failed to load dashboard data:', e);
  }
};

onMounted(loadDashboard);
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
  background-color: #f0f0f0;
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

.empty-cell {
  text-align: center;
  padding: 2rem;
}

.upcoming-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.upcoming-item {
  padding: 0.75rem;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
}

.upcoming-item p {
  margin: 0;
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
