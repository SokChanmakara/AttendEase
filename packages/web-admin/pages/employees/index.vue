<template>
  <div class="employees-page">
    <div class="page-top">
      <SectionLabel>Employee Directory</SectionLabel>
      <div class="page-actions">
        <BaseButton @click="showAddModal = true">Add New Employee</BaseButton>
      </div>
    </div>

    <BaseCard class="employees-list">
      <template #header>
        <div class="list-header">
          <div class="search-box">
            <BaseInput v-model="searchQuery" placeholder="Search by name or email..." />
          </div>
        </div>
      </template>

      <BaseTable :headers="['Employee', 'Department', 'Role', 'Joined Date', 'Status', 'Actions']">
        <tr v-for="user in filteredUsers" :key="user.id">
          <td>
            <div class="user-cell">
              <div class="avatar display-serif">{{ user.name?.substring(0, 2).toUpperCase() }}</div>
              <div class="user-details">
                <span class="user-name">{{ user.name }}</span>
                <span class="user-email text-subtle">{{ user.email }}</span>
              </div>
            </div>
          </td>
          <td class="mono">{{ user.department || '-' }}</td>
          <td class="mono">{{ user.role || 'Employee' }}</td>
          <td class="mono">{{ formatDate(user.startDate) }}</td>
          <td>
            <span :class="['status-pill', user.isActive ? 'status-present' : 'status-absent']">
              {{ user.isActive ? 'Active' : 'Inactive' }}
            </span>
          </td>
          <td>
            <BaseButton variant="ghost" @click="editUser(user)">Edit</BaseButton>
          </td>
        </tr>
        <tr v-if="filteredUsers.length === 0">
          <td colspan="6" class="empty-cell">No employees found matching your search.</td>
        </tr>
      </BaseTable>
    </BaseCard>

    <!-- Add/Edit Employee Modal -->
    <div v-if="showAddModal" class="modal-overlay" @click.self="showAddModal = false">
      <BaseCard class="modal-card">
        <template #header>
          <h3 class="display-serif">{{ editingId ? 'Edit Employee' : 'Onboard New Employee' }}</h3>
        </template>

        <form @submit.prevent="saveEmployee" class="employee-form">
          <div class="form-grid">
            <BaseInput v-model="formData.firstName" label="First Name" required />
            <BaseInput v-model="formData.lastName" label="Last Name" required />
          </div>
          <BaseInput v-model="formData.email" label="Email Address" type="email" required :disabled="!!editingId" />
          
          <div class="form-grid">
            <BaseInput v-model="formData.department" label="Department ID" placeholder="it-ops" />
            <BaseInput v-model="formData.role" label="Role" placeholder="Developer" />
          </div>

          <div class="form-grid">
            <BaseInput v-model="formData.startDate" label="Start Date" type="date" />
            <BaseInput v-model="formData.dob" label="Date of Birth" type="date" />
          </div>

          <div class="form-actions">
            <BaseButton type="submit" :loading="saving">
              {{ editingId ? 'Update Employee' : 'Create Account' }}
            </BaseButton>
            <BaseButton variant="ghost" @click="showAddModal = false">Cancel</BaseButton>
          </div>
        </form>
      </BaseCard>
    </div>
  </div>
</template>


<script setup lang="ts">
import { collection, query, getDocs, where } from 'firebase/firestore';

const { db } = useFirebase();

const users = ref<any[]>([]);
const searchQuery = ref('');
const showAddModal = ref(false);
const editingId = ref<string | null>(null);
const saving = ref(false);

const formData = ref({
  firstName: '',
  lastName: '',
  email: '',
  department: '',
  role: 'Employee',
  startDate: '',
  dob: '',
});

const loadUsers = async () => {
  try {
    const usersRef = collection(db, 'users');
    // In real app, we might filter by company_id
    const snapshot = await getDocs(usersRef);
    users.value = snapshot.docs.map(doc => ({
      id: doc.id,
      name: `${doc.data().first_name} ${doc.data().last_name}`,
      ...doc.data(),
      firstName: doc.data().first_name,
      lastName: doc.data().last_name,
      isActive: doc.data().is_active ?? true,
      startDate: doc.data().start_date,
    }));
  } catch (e) {
    console.error('Failed to load users:', e);
  }
};

const filteredUsers = computed(() => {
  if (!searchQuery.value) return users.value;
  const q = searchQuery.value.toLowerCase();
  return users.value.filter(u => 
    u.name?.toLowerCase().includes(q) || 
    u.email?.toLowerCase().includes(q)
  );
});

const saveEmployee = async () => {
  saving.value = true;
  try {
    // This would typically call a Cloud Function to handle user creation in Admin Auth
    console.log('Saving employee:', formData.value);
    alert('In a real environment, this would call a Cloud Function to create the Firebase Auth user and Firestore record.');
    showAddModal.value = false;
    await loadUsers();
  } finally {
    saving.value = false;
  }
};

const editUser = (user: any) => {
  editingId.value = user.id;
  formData.value = {
    firstName: user.firstName,
    lastName: user.lastName,
    email: user.email,
    department: user.department_id,
    role: user.role,
    startDate: user.startDate,
    dob: user.date_of_birth,
  };
  showAddModal.value = true;
};

const formatDate = (date: any) => {
  if (!date) return '-';
  return new Date(date).toLocaleDateString();
};

onMounted(loadUsers);
</script>

<style scoped>
.page-actions {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 2rem;
}

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 2rem;
}

.search-box {
  width: 100%;
  max-width: 400px;
}

.user-cell {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.avatar {
  width: 32px;
  height: 32px;
  background-color: #222;
  color: var(--accent);
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 11px;
  border: 1px solid var(--border);
}

.user-details {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-weight: 500;
  font-size: 13px;
  color: var(--foreground);
}

.user-email {
  font-size: 11px;
  color: var(--muted-foreground);
}

.empty-cell {
  text-align: center;
  padding: 4rem;
  color: var(--muted-foreground);
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(8px);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}


.modal-card {
  width: 100%;
  max-width: 600px;
}

.employee-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1rem;
}
</style>
