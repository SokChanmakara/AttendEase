<template>
  <div class="leave-page">
    <SectionLabel>Queue Management</SectionLabel>
    
    <div class="tabs-container">
      <div class="tabs">
        <BaseButton 
          :variant="activeTab === 'pending' ? 'primary' : 'ghost'" 
          @click="activeTab = 'pending'"
        >
          Pending ({{ pendingCount }})
        </BaseButton>
        <BaseButton 
          :variant="activeTab === 'history' ? 'primary' : 'ghost'" 
          @click="activeTab = 'history'"
        >
          History
        </BaseButton>
      </div>
    </div>

    <SectionLabel>{{ activeTab === 'pending' ? 'Pending Requests' : 'Leave History' }}</SectionLabel>

    <BaseCard class="leave-list">
      <BaseTable :headers="['Employee', 'Type', 'Period', 'Days', 'Status', 'Actions']">
        <tr v-for="req in filteredRequests" :key="req.id">
          <td>
            <div class="employee-info">
              <span class="name">{{ req.userName }}</span>
              <span class="dept small-caps">{{ req.departmentId || 'General' }}</span>
            </div>
            <div v-if="req.overlap_flagged" class="overlap-warning">
              <span class="warning-icon">⚠️</span> Overlap Detection
            </div>
          </td>
          <td class="display-serif">{{ req.leaveTypeLabel || 'Annual' }}</td>
          <td>
            <div class="period">
              <span>{{ formatDate(req.start_date) }}</span>
              <span class="to-text small-caps">to</span>
              <span>{{ formatDate(req.end_date) }}</span>
            </div>
            <span v-if="req.is_half_day" class="half-day-tag small-caps">
              Half Day ({{ req.half_day_period }})
            </span>
          </td>
          <td class="display-serif">{{ req.days || '-' }}</td>
          <td>
            <span :class="['status-badge', req.status?.toLowerCase()]">
              {{ req.status }}
            </span>
          </td>
          <td>
            <div v-if="req.status === 'Pending'" class="action-buttons">
              <BaseButton variant="secondary" @click="handleApproval(req, 'Approved')">Approve</BaseButton>
              <BaseButton variant="ghost" @click="handleApproval(req, 'Rejected')">Reject</BaseButton>
            </div>
            <span v-else class="decided-info text-subtle">
              {{ req.status }} by {{ req.approved_by || 'Admin' }}
            </span>
          </td>
        </tr>
        <tr v-if="filteredRequests.length === 0">
          <td colspan="6" class="empty-cell">No leave requests found.</td>
        </tr>
      </BaseTable>
    </BaseCard>
  </div>
</template>

<script setup lang="ts">
import { collection, query, getDocs, where, orderBy } from 'firebase/firestore';

const { db } = useFirebase();

const activeTab = ref<'pending' | 'history'>('pending');
const requests = ref<any[]>([]);
const loading = ref(false);

const companyId = ref('acme'); // Default for now

const loadRequests = async () => {
  loading.value = true;
  try {
    const leaveRef = collection(db, `companies/${companyId.value}/leave_requests`);
    const q = query(leaveRef, orderBy('start_date', 'desc'));
    const snapshot = await getDocs(q);
    requests.value = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (e) {
    console.error('Failed to load leave requests:', e);
  } finally {
    loading.value = false;
  }
};

const filteredRequests = computed(() => {
  return requests.value.filter(r => 
    activeTab.value === 'pending' ? r.status === 'Pending' : r.status !== 'Pending'
  );
});

const pendingCount = computed(() => {
  return requests.value.filter(r => r.status === 'Pending').length;
});

const handleApproval = async (req: any, newStatus: string) => {
  console.log(`Setting status of ${req.id} to ${newStatus}`);
  alert(`In a real implementation, this would update the status to ${newStatus} in Firestore and trigger notification functions.`);
  // Logically update locally for demo
  req.status = newStatus;
  req.approved_by = 'Current Admin';
};

const formatDate = (date: any) => {
  if (!date) return '-';
  // If firestore timestamp
  if (date?.toDate) return date.toDate().toLocaleDateString();
  return new Date(date).toLocaleDateString();
};

onMounted(loadRequests);
</script>

<style scoped>
.leave-page {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.tabs {
  display: flex;
  gap: 1rem;
}

.employee-info {
  display: flex;
  flex-direction: column;
}

.employee-info .name {
  font-weight: 600;
}

.employee-info .dept {
  font-size: 0.75rem;
  color: var(--muted-foreground);
}

.period {
  display: flex;
  flex-direction: column;
  line-height: 1.4;
}

.to-text {
  font-size: 0.75rem;
  color: var(--muted-foreground);
  text-transform: uppercase;
}

.overlap-warning {
  margin-top: 0.5rem;
  font-size: 0.7rem;
  color: var(--warning);
  font-weight: 600;
  background: #fff3e0;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  width: fit-content;
}

.half-day-tag {
  font-size: 0.75rem;
  color: var(--accent);
  font-weight: 600;
}

.action-buttons {
  display: flex;
  gap: 0.5rem;
}

.decided-info {
  font-size: 0.8125rem;
  color: var(--muted-foreground);
  font-style: italic;
}

.empty-cell {
  text-align: center;
  padding: 4rem;
  color: var(--muted-foreground);
  font-style: italic;
}
</style>
