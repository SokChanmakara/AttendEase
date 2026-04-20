<template>
  <div class="qr-management">
    <div class="page-top">
      <SectionLabel>Security Configuration</SectionLabel>
      <div class="header-actions">
        <BaseButton @click="handleRotate" :loading="rotating">Rotate Service Secret</BaseButton>
      </div>
    </div>

    <div class="qr-grid">
      <div class="qr-preview-col">
        <SectionLabel>Active Poster</SectionLabel>
        <BaseCard class="qr-card">
          <div class="qr-preview-container">
            <div class="mock-qr">
              <div class="qr-pattern"></div>
              <p class="display-serif">AttendEase HQ</p>
              <div class="qr-border-line"></div>
            </div>
            <div class="qr-details">
              <div class="detail-item">
                <span class="label small-caps">Location</span>
                <span class="value mono">HQ Main Entrance</span>
              </div>
              <div class="detail-item">
                <span class="label small-caps">Last Rotated</span>
                <span class="value mono">{{ lastRotated || 'Never' }}</span>
              </div>
              <div class="detail-item">
                <span class="label small-caps">Expires In</span>
                <span class="value mono">{{ expiresIn || '-' }} minutes</span>
              </div>
            </div>
          </div>

          <template #footer>
            <div class="card-footer-actions">
              <BaseButton variant="secondary" @click="printPoster">Print Poster</BaseButton>
              <BaseButton variant="ghost">Download SVG</BaseButton>
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
              <td class="text-subtle">{{ log.reason || 'Periodic Refresh' }}</td>
              <td class="small-caps">{{ log.adminName || 'System' }}</td>
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
import { httpsCallable } from 'firebase/functions';

const { functions } = useFirebase();

const rotating = ref(false);
const lastRotated = ref('');
const expiresIn = ref(0);
const rotationLogs = ref<any[]>([]);

const handleRotate = async () => {
  if (!confirm('Warning: Rotating the QR secret will invalidate all current physical posters. Employees will not be able to check in until the new poster is printed and displayed. Continue?')) {
    return;
  }

  rotating.value = true;
  try {
    const rotateFunc = httpsCallable(functions, 'forceRotateQrToken');
    const res = await rotateFunc({
      companyId: 'acme',
      locationId: 'hq',
      reason: 'Manual refresh from dashboard'
    }) as any;
    
    lastRotated.value = new Date().toLocaleString();
    expiresIn.value = res.data.expiresInMinutes;
    
    alert('QR Token rotated successfully. Please print the new poster.');
  } catch (e) {
    console.error('Rotation failed:', e);
    alert('Rotation failed. This usually happens if the backend function is not deployed.');
  } finally {
    rotating.value = false;
  }
};

const printPoster = () => {
  if (process.client) {
    window.print();
  }
};

const formatDate = (ts: any) => {
  if (!ts) return '-';
  return new Date(ts).toLocaleString();
};
</script>

<style scoped>
.qr-management {
  display: flex;
  flex-direction: column;
  gap: 2rem;
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

.mock-qr {
  width: 200px;
  height: 200px;
  border: 1px solid var(--border);
  background-color: white;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  padding: 1.5rem;
  color: #000;
}

.qr-pattern {
  width: 100%;
  aspect-ratio: 1;
  background-image: radial-gradient(#000 1.5px, transparent 1.5px);
  background-size: 6px 6px;
  margin-bottom: 0.75rem;
}

.mock-qr p {
  margin: 0;
  font-size: 1rem;
  letter-spacing: -0.01em;
}

.qr-border-line {
  position: absolute;
  bottom: 1rem;
  left: 1.5rem;
  right: 1.5rem;
  height: 1px;
  background-color: var(--accent);
  opacity: 0.3;
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
  .qr-card, .qr-card * {
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
  .card-footer-actions, .page-top, .history-col, .qr-details {
    display: none;
  }
}
</style>

