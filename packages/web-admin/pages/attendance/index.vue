<template>
  <div class="attendance-page">
    <SectionLabel>Filter & Search</SectionLabel>
    
    <BaseCard class="attendance-controls">
      <div class="filter-row">
        <BaseInput v-model="companyId" label="Company ID" placeholder="acme" />
        <BaseInput label="Quick Search" placeholder="Search by name..." />
      </div>
      <template #footer>
        <div class="controls-footer">
          <BaseButton variant="secondary" @click="refreshAttendance" :loading="loading">
            Refresh Records
          </BaseButton>
        </div>
      </template>
    </BaseCard>

    <SectionLabel>Attendance Records</SectionLabel>

    <BaseCard class="attendance-list">
      <BaseTable :headers="['User', 'Location', 'Check-In', 'Check-Out', 'Status', 'Actions']">
        <tr v-for="row in attendanceRows" :key="row.id">
          <td>
            <div class="user-info">
              <span class="user-name">{{ row.userName || 'Unknown' }}</span>
              <span class="user-id small-caps">ID: {{ row.userId }}</span>
            </div>
          </td>
          <td>{{ row.locationId }}</td>
          <td>{{ formatDate(row.checkInAtIso) }}</td>
          <td>{{ formatDate(row.checkOutAtIso) || '-' }}</td>
          <td>
            <span :class="['status-badge', (row.status || '').toLowerCase()]">
              {{ row.status || 'Unknown' }}
            </span>
          </td>
          <td>
            <BaseButton variant="ghost" @click="selectForCorrection(row)">
              Correct
            </BaseButton>
          </td>
        </tr>
        <tr v-if="attendanceRows.length === 0">
          <td colspan="6" class="empty-cell">No attendance records found.</td>
        </tr>
      </BaseTable>
    </BaseCard>

    <!-- Correction Overlay -->
    <div v-if="selectedId" class="correction-overlay" @click.self="clearCorrection">
      <BaseCard class="correction-card" elevated>
        <template #header>
          <h3 class="display-serif">Manual Correction</h3>
        </template>
        
        <form @submit.prevent="submitCorrection" class="correction-form">
          <BaseInput v-model="editCheckIn" label="Check-In" type="datetime-local" />
          <BaseInput v-model="editCheckOut" label="Check-Out" type="datetime-local" />
          <BaseInput v-model="editReason" label="Reason for Correction" placeholder="Approved by manager" />
          
          <div class="form-actions">
            <BaseButton type="submit" :loading="correcting">Apply Changes</BaseButton>
            <BaseButton variant="ghost" @click="clearCorrection">Cancel</BaseButton>
          </div>
        </form>
      </BaseCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { 
  collection, 
  query, 
  orderBy, 
  limit, 
  getDocs 
} from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';

const { db, functions } = useFirebase();

const companyId = ref('acme'); // Default for now
const attendanceRows = ref<any[]>([]);
const loading = ref(false);
const correcting = ref(false);

const selectedId = ref('');
const editCheckIn = ref('');
const editCheckOut = ref('');
const editReason = ref('');

const refreshAttendance = async () => {
  if (!companyId.value) return;
  loading.value = true;
  try {
    const attendanceRef = collection(db, `companies/${companyId.value}/attendance`);
    const q = query(attendanceRef, orderBy('check_in_at', 'desc'), limit(50));
    const snapshot = await getDocs(q);
    
    attendanceRows.value = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      // Ensure ISO format for dates
      checkInAtIso: (doc.data().check_in_at as any)?.toDate?.()?.toISOString() || doc.data().check_in_at,
      checkOutAtIso: (doc.data().check_out_at as any)?.toDate?.()?.toISOString() || doc.data().check_out_at,
    }));
  } catch (e) {
    console.error('Failed to load attendance:', e);
  } finally {
    loading.value = false;
  }
};

const selectForCorrection = (row: any) => {
  selectedId.value = row.id;
  editCheckIn.value = row.checkInAtIso?.slice(0, 16) || '';
  editCheckOut.value = row.checkOutAtIso?.slice(0, 16) || '';
  editReason.value = '';
};

const clearCorrection = () => {
  selectedId.value = '';
};

const submitCorrection = async () => {
  correcting.value = true;
  try {
    const correctFunc = httpsCallable(functions, 'adminCorrectAttendance');
    await correctFunc({
      companyId: companyId.value,
      attendanceId: selectedId.value,
      checkInAt: new Date(editCheckIn.value).toISOString(),
      checkOutAt: editCheckOut.value ? new Date(editCheckOut.value).toISOString() : null,
      reason: editReason.value,
    });
    alert('Correction applied successfully');
    clearCorrection();
    refreshAttendance();
  } catch (e) {
    console.error('Correction failed:', e);
    alert('Correction failed. See console for details.');
  } finally {
    correcting.value = false;
  }
};

const formatDate = (iso: string) => {
  if (!iso) return '';
  return new Date(iso).toLocaleString();
};

onMounted(() => {
  refreshAttendance();
});
</script>

<style scoped>
.attendance-page {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.controls-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.filter-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
}

.user-info {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-weight: 600;
  color: var(--foreground);
}

.user-id {
  font-size: 0.75rem;
  color: var(--muted-foreground);
}

.empty-cell {
  text-align: center;
  padding: 3rem;
  color: var(--muted-foreground);
  font-style: italic;
}

.correction-overlay {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(4px);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}

.correction-card {
  width: 100%;
  max-width: 500px;
}

.correction-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1rem;
}
</style>
