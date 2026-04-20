import { 
  onAuthStateChanged, 
  signInWithEmailAndPassword, 
  signOut, 
  type User 
} from 'firebase/auth';

export const useAuth = () => {
  const { auth } = useFirebase();
  const user = useState<User | null>('auth_user', () => null);
  const loading = useState('auth_loading', () => true);

  // Initialize auth state listener
  const initAuth = () => {
    onAuthStateChanged(auth, (firebaseUser) => {
      user.value = firebaseUser;
      loading.value = false;
    });
  };

  const login = async (email: string, pass: string) => {
    loading.value = true;
    try {
      await signInWithEmailAndPassword(auth, email, pass);
    } finally {
      loading.value = false;
    }
  };

  const logout = async () => {
    loading.value = true;
    try {
      await signOut(auth);
      user.value = null;
    } finally {
      loading.value = false;
    }
  };

  return {
    user,
    loading,
    initAuth,
    login,
    logout,
  };
};
