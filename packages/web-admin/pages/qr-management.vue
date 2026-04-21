<template>
  <div class="qr-management">
    <div class="page-top">
      <SectionLabel>Attendance QR</SectionLabel>
      <div class="header-actions">
        <BaseButton @click="handleRotate" :loading="rotating || generating">Rotate Token</BaseButton>
      </div>
    </div>

    <BaseCard class="config-card">
      <div class="config-grid">
        <BaseInput
          v-model="companyId"
          label="Company ID"
          placeholder="acme"
        />
        <div class="location-field">
          <label class="base-label">Location</label>
          <select v-model="selectedLocationId" class="base-select">
            <option v-for="loc in locations" :key="loc.id" :value="loc.id">
              {{ loc.name }} ({{ loc.id }})
            </option>
          </select>
        </div>
        <div class="location-actions">
          <BaseButton variant="secondary" @click="loadLocations">Load Locations</BaseButton>
        </div>
      </div>
    </BaseCard>

    <div class="qr-grid">
      <div class="qr-preview-col">
        <SectionLabel>Active Poster</SectionLabel>
        <BaseCard class="qr-card">
          <div class="qr-preview-container" v-if="attendanceQrValue">
            <div class="qr-container">
              <qrcode-vue :value="attendanceQrValue" :size="240" level="H" background="#ffffff" foreground="#000000" />
            </div>
            <div class="qr-details">
              <div class="detail-item">
                <span class="label small-caps">Location</span>
                <span class="value mono">{{ selectedLocationName || '-' }}</span>
              </div>
              <div class="detail-item">
                <span class="label small-caps">Last Issued</span>
                <span class="value mono">{{ lastRotated || '-' }}</span>
              </div>
              <div class="detail-item">
                <span class="label small-caps">Expires In</span>
                <span class="value mono">{{ expiresIn || '-' }} minutes</span>
              </div>
            </div>
          </div>
          <div v-else class="empty-preview">
            <p class="text-subtle">{{ generating ? 'Generating attendance QR...' : 'No active attendance QR.' }}</p>
          </div>

          <template #footer>
            <div class="card-footer-actions">
              <BaseButton variant="secondary" @click="generateToken" :loading="generating || rotating">Regenerate</BaseButton>
              <BaseButton variant="ghost" @click="printPoster" :disabled="!attendanceQrValue">Print Poster</BaseButton>
            </div>
          </template>
        </BaseCard>
      </div>

      <div class="history-col">
        <SectionLabel>Audit Trail</SectionLabel>
        <BaseCard class="rotation-history">
          <BaseTable :headers="['Date', 'Reason', 'Admin']">
            <tr v-for="log in rotationLogs" :key="log.id">
              <td class="mono">{{ formatDate(log.timestamp) }}</td>
              <td class="text-subtle">{{ log.reason || 'Manual Rotation' }}</td>
              <td class="small-caps">{{ log.adminName || 'Unknown' }}</td>
            </tr>
            <tr v-if="rotationLogs.length === 0">
              <td colspan="3" class="empty-cell">No recent rotation logs.</td>
            </tr>
          </BaseTable>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import QrcodeVue from 'qrcode.vue';
import { httpsCallable } from 'firebase/functions';
import { collection, doc, getDoc, getDocs, limit, orderBy, query } from 'firebase/firestore';

const { db, functions } = useFirebase();

const companyId = ref('acme');
const selectedLocationId = ref('');
const locations = ref<Array<{ id: string; name: string }>>([]);

const generating = ref(false);
const rotating = ref(false);
const qrToken = ref('');
const lastRotated = ref('');
const expiresIn = ref<number | null>(null);
const rotationLogs = ref<any[]>([]);

const selectedLocationName = computed(() => {
  return locations.value.find((loc) => loc.id === selectedLocationId.value)?.name ?? '';
});

const attendanceQrValue = computed(() => {
  if (!companyId.value || !selectedLocationId.value || !qrToken.value) return '';
  const payload = encodeURIComponent(
    JSON.stringify({
      companyId: companyId.value,
      locationId: selectedLocationId.value,
      qrToken: qrToken.value,
    })
  );
  return `AE_ATTEND:${payload}`;
});

const loadLocations = async () => {
  if (!companyId.value) return;
  try {
    const ref = collection(db, `companies/${companyId.value}/locations`);
    const snap = await getDocs(ref);
    locations.value = snap.docs.map((d) => ({
      id: d.id,
      name: (d.data().name as string) || d.id,
    }));
    if (!selectedLocationId.value && locations.value.isNotEmpty) {
      selectedLocationId.value = locations.value[0].id;
    }
  } catch (e) {
    console.error('Failed loading locations', e);
    locations.value = [];
  }
};

const refreshQrMetadata = async () => {
  if (!companyId.value || !selectedLocationId.value) return;
  try {
    const qrDoc = await getDoc(doc(db, `companies/${companyId.value}/qr_codes/${selectedLocationId.value}`));
    const issuedAt = (qrDoc.data()?.issued_at as any)?.toDate?.();
    lastRotated.value = issuedAt ? issuedAt.toLocaleString() : '';
  } catch (e) {
    console.error('Failed loading qr metadata', e);
  }
};

const loadRotationLogs = async () => {
  if (!companyId.value) return;
  try {
    const logsRef = collection(db, `companies/${companyId.value}/audit_log`);
    const logsQuery = query(logsRef, orderBy('timestamp', 'desc'), limit(40));
    const snapshot = await getDocs(logsQuery);
    rotationLogs.value = snapshot.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .filter((log: any) => log.action === 'qr_force_rotated' && log.target_id === selectedLocationId.value)
      .slice(0, 10)
      .map((log: any) => ({
        id: log.id,
        timestamp: (log.timestamp as any)?.toDate?.() ?? null,
        reason: log.rotation_reason ?? log.new_value?.rotation_reason ?? '',
        adminName: log.performed_by_uid ?? 'admin',
      }));
  } catch (e) {
    console.error('Failed loading rotation logs', e);
    rotationLogs.value = [];
  }
};

const generateToken = async () => {
  if (!companyId.value || !selectedLocationId.value) return;
  generating.value = true;
  try {
    const generateFunc = httpsCallable(functions, 'generateQrToken');
    const res = (await generateFunc({
      companyId: companyId.value,
      locationId: selectedLocationId.value,
    })) as any;
    qrToken.value = res.data.token;
    expiresIn.value = res.data.expiresInMinutes;
    await refreshQrMetadata();
    await loadRotationLogs();
  } catch (e) {
    console.error('Generate attendance QR failed:', e);
    alert('Failed to generate attendance QR. Verify admin auth and function deployment.');
  } finally {
    generating.value = false;
  }
};

const handleRotate = async () => {
  if (!companyId.value || !selectedLocationId.value) return;
  if (
    !confirm(
      'Rotating this token invalidates current posters. Employees must scan the new poster for check in/out. Continue?'
    )
  ) {
    return;
  }

  rotating.value = true;
  try {
    const rotateFunc = httpsCallable(functions, 'forceRotateQrToken');
    const res = (await rotateFunc({
      companyId: companyId.value,
      locationId: selectedLocationId.value,
      reason: 'Manual refresh from admin portal',
    })) as any;

    qrToken.value = res.data.token;
    expiresIn.value = res.data.expiresInMinutes;
    await refreshQrMetadata();
    await loadRotationLogs();
    alert('QR token rotated successfully.');
  } catch (e) {
    console.error('Rotation failed:', e);
    alert('Rotation failed. Verify admin auth and function deployment.');
  } finally {
    rotating.value = false;
  }
};

const printPoster = () => {
  if (process.client) {
    window.print();
  }
};

const formatDate = (value: Date | null) => {
  if (!value) return '-';
  return value.toLocaleString();
};

watch(selectedLocationId, async () => {
  await generateToken();
});

onMounted(async () => {
  await loadLocations();
  await generateToken();
});
</script>

<style scoped>
.qr-management {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.config-card {
  margin-bottom: 0.5rem;
}

.config-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
}

.location-field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.location-actions {
  align-self: end;
}

.base-label {
  font-family: var(--font-mono);
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  color: var(--muted-foreground);
}

.base-select {
  width: 100%;
  min-height: 48px;
  padding: 0 1rem;
  font-family: var(--font-sans);
  font-size: 0.95rem;
  color: var(--foreground);
  background-color: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  outline: none;
}

.qr-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2.5rem;
}

.qr-preview-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2rem;
}

.qr-container {
  padding: 1.5rem;
  background: white;
  border-radius: 8px;
  border: 1px solid var(--border);
}

.empty-preview {
  min-height: 320px;
  display: grid;
  place-items: center;
}

.qr-details {
  width: 100%;
  border-top: 1px solid var(--border);
  padding: 1.5rem 0.5rem 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

.detail-item .label {
  color: var(--muted-foreground);
}

.detail-item .value {
  font-size: 11px;
}

.card-footer-actions {
  display: flex;
  gap: 1rem;
  width: 100%;
}

.card-footer-actions > * {
  flex: 1;
}

.empty-cell {
  text-align: center;
  padding: 4rem;
  color: var(--muted-foreground);
}

@media print {
  .qr-management * {
    visibility: hidden;
  }
  .qr-card,
  .qr-card * {
    visibility: visible;
  }
  .qr-card {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    border: none;
    background: white;
    color: black;
  }
  .card-footer-actions,
  .page-top,
  .history-col,
  .config-card,
  .qr-details {
    display: none;
  }
}

@media (max-width: 1024px) {
  .qr-grid {
    grid-template-columns: 1fr;
  }
}
</style>
