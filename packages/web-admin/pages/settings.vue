<template>
  <div class="settings-page">
    <div class="settings-grid">
      <div class="settings-group">
        <SectionLabel>Organization</SectionLabel>
        <BaseCard class="settings-section">
          <template #header>
            <h3 class="display-serif">Company Information</h3>
          </template>
          
          <form @submit.prevent="saveCompanySettings" class="settings-form">
            <BaseInput v-model="companyData.name" label="Company Name" />
            <BaseInput v-model="companyData.timezone" label="Timezone" placeholder="Asia/Bangkok" />
            
            <div class="form-actions">
              <BaseButton type="submit" :loading="savingCompany">Save Changes</BaseButton>
            </div>
          </form>
        </BaseCard>
      </div>

      <div class="settings-group">
        <SectionLabel>Policy</SectionLabel>
        <BaseCard class="settings-section">
          <template #header>
            <h3 class="display-serif">Attendance Policy</h3>
          </template>
          
          <form @submit.prevent="savePolicySettings" class="settings-form">
            <BaseInput 
              v-model="policyData.proximityRadius" 
              label="Proximity Radius (meters)" 
              type="number" 
              placeholder="300" 
              class="mono-input"
            />
            <BaseInput 
              v-model="policyData.cutoffTime" 
              label="Auto-Close Cutoff Time" 
              type="time" 
              placeholder="23:59" 
              class="mono-input"
            />
            
            <div class="form-actions">
              <BaseButton type="submit" :loading="savingPolicy">Update Policy</BaseButton>
            </div>
          </form>
        </BaseCard>
      </div>

      <div class="settings-group">
        <SectionLabel>Geography</SectionLabel>
        <BaseCard class="settings-section">
          <template #header>
            <h3 class="display-serif">Locations</h3>
          </template>
          
          <BaseTable :headers="['Location Name', 'Coordinates', 'Actions']">
            <tr v-for="loc in locations" :key="loc.id">
              <td>{{ loc.name }}</td>
              <td class="mono fs-11">{{ loc.lat }}, {{ loc.lng }}</td>
              <td>
                <BaseButton variant="ghost">Edit</BaseButton>
              </td>
            </tr>
            <tr v-if="locations.length === 0">
              <td colspan="3" class="empty-cell">No locations configured.</td>
            </tr>
          </BaseTable>
          
          <template #footer>
            <BaseButton variant="secondary" style="width: 100%">Add New Location</BaseButton>
          </template>
        </BaseCard>
      </div>

      <div class="settings-group">
        <SectionLabel>Maintenance</SectionLabel>
        <BaseCard class="settings-section danger-zone">
          <template #header>
            <h3 class="text-error display-serif">Danger Zone</h3>
          </template>
          <p class="text-subtle">These actions are irreversible and affect the entire organization.</p>
          <div class="danger-actions">
            <BaseButton variant="ghost" class="btn-danger">Export All Audit Logs</BaseButton>
            <BaseButton variant="ghost" class="btn-danger">Deactivate All QR Codes</BaseButton>
          </div>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { doc, getDoc, updateDoc, collection, getDocs } from 'firebase/firestore';

const { db } = useFirebase();

const companyId = ref('acme'); // Default for now
const savingCompany = ref(false);
const savingPolicy = ref(false);

const companyData = ref({
  name: 'AttendEase Pilot',
  timezone: 'Asia/Bangkok',
});

const policyData = ref({
  proximityRadius: '300',
  cutoffTime: '23:59',
});

const locations = ref<any[]>([]);

const loadSettings = async () => {
  try {
    const compDoc = await getDoc(doc(db, 'companies', companyId.value));
    if (compDoc.exists()) {
      const data = compDoc.data();
      companyData.value.name = data.name || companyData.value.name;
      companyData.value.timezone = data.timezone || companyData.value.timezone;
      policyData.value.proximityRadius = (data.proximity_radius_m || 300).toString();
      policyData.value.cutoffTime = data.auto_close_cutoff_time || policyData.value.cutoffTime;
    }

    const locsRef = collection(db, `companies/${companyId.value}/locations`);
    const locSnapshot = await getDocs(locsRef);
    locations.value = locSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } catch (e) {
    console.error('Failed to load settings:', e);
  }
};

const saveCompanySettings = async () => {
  savingCompany.value = true;
  try {
    const compRef = doc(db, 'companies', companyId.value);
    await updateDoc(compRef, {
      name: companyData.value.name,
      timezone: companyData.value.timezone,
    });
    alert('Company settings updated.');
  } catch (e) {
    console.error(e);
    alert('Save failed.');
  } finally {
    savingCompany.value = false;
  }
};

const savePolicySettings = async () => {
  savingPolicy.value = true;
  try {
    const compRef = doc(db, 'companies', companyId.value);
    await updateDoc(compRef, {
      proximity_radius_m: Number(policyData.value.proximityRadius),
      auto_close_cutoff_time: policyData.value.cutoffTime,
    });
    alert('Attendance policy updated.');
  } catch (e) {
    console.error(e);
    alert('Save failed.');
  } finally {
    savingPolicy.value = false;
  }
};

onMounted(loadSettings);
</script>

<style scoped>
.settings-page {
  max-width: 1000px;
}

.settings-grid {
  display: flex;
  flex-direction: column;
  gap: 4rem;
}

.settings-group {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.settings-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 1rem;
}

.mono { font-family: var(--font-mono); }
.fs-11 { font-size: 11px; }

.text-error {
  color: var(--status-red);
}

.danger-zone {
  border: 1px solid #331111;
  background-color: #1a0a0a;
}

.danger-actions {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-top: 1.5rem;
}

.btn-danger {
  justify-content: flex-start;
  color: var(--status-red);
  padding-left: 0;
}

.btn-danger:hover {
  background-color: rgba(239, 68, 68, 0.1);
  color: var(--status-red);
}

.empty-cell {
  text-align: center;
  padding: 2rem;
  color: var(--muted-foreground);
}
</style>

