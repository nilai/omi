import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

// User Types based on PRD
export type UserType = 'device' | 'guest' | 'account';

export interface UserData {
  userType: UserType;
  deviceId: string;
  accountId?: string;
  email?: string;
  name?: string;
  avatar?: string;
  // Usage tracking for Guest User limits
  memoryCount: number;
  quickCaptureCount: number;
  askAICount: number;
}

interface UserContextType {
  user: UserData;
  isLoggedIn: boolean;
  hasReachedLimit: (type: 'memory' | 'quickCapture' | 'askAI') => boolean;
  incrementUsage: (type: 'memory' | 'quickCapture' | 'askAI') => void;
  login: (email: string, password: string) => Promise<void>;
  loginWithProvider: (provider: 'apple' | 'google') => Promise<void>;
  logout: () => void;
  syncLocalDataToCloud: () => Promise<void>;
}

const UserContext = createContext<UserContextType | undefined>(undefined);

// Generate unique device ID
const generateDeviceId = (): string => {
  const stored = localStorage.getItem('device_id');
  if (stored) return stored;
  
  const newId = `device_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  localStorage.setItem('device_id', newId);
  return newId;
};

// Load user data from localStorage
const loadUserData = (): UserData => {
  const stored = localStorage.getItem('user_data');
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch (error) {
      console.error('Failed to parse user data:', error);
    }
  }
  
  // Create new Device User
  const deviceId = generateDeviceId();
  return {
    userType: 'guest',
    deviceId,
    memoryCount: 0,
    quickCaptureCount: 0,
    askAICount: 0,
  };
};

// Save user data to localStorage
const saveUserData = (data: UserData) => {
  localStorage.setItem('user_data', JSON.stringify(data));
};

// Guest User limits based on PRD
const LIMITS = {
  memory: 2,
  quickCapture: 10,
  askAI: 10,
};

export function UserProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserData>(loadUserData);

  // Save user data whenever it changes
  useEffect(() => {
    saveUserData(user);
  }, [user]);

  const isLoggedIn = user.userType === 'account' && !!user.accountId;

  const hasReachedLimit = (type: 'memory' | 'quickCapture' | 'askAI'): boolean => {
    if (isLoggedIn) return false; // Account users have no limits
    
    switch (type) {
      case 'memory':
        return user.memoryCount >= LIMITS.memory;
      case 'quickCapture':
        return user.quickCaptureCount >= LIMITS.quickCapture;
      case 'askAI':
        return user.askAICount >= LIMITS.askAI;
      default:
        return false;
    }
  };

  const incrementUsage = (type: 'memory' | 'quickCapture' | 'askAI') => {
    setUser(prev => {
      const updated = { ...prev };
      switch (type) {
        case 'memory':
          updated.memoryCount += 1;
          break;
        case 'quickCapture':
          updated.quickCaptureCount += 1;
          break;
        case 'askAI':
          updated.askAICount += 1;
          break;
      }
      return updated;
    });
  };

  const login = async (email: string, password: string) => {
    // Mock login - replace with real API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const accountId = `account_${Date.now()}`;
    setUser(prev => ({
      ...prev,
      userType: 'account',
      accountId,
      email,
      name: email.split('@')[0],
    }));
    
    // Sync local data to cloud
    await syncLocalDataToCloud();
  };

  const loginWithProvider = async (provider: 'apple' | 'google') => {
    // Mock provider login - replace with real OAuth flow
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const accountId = `account_${provider}_${Date.now()}`;
    const mockEmail = `user@${provider}.com`;
    
    setUser(prev => ({
      ...prev,
      userType: 'account',
      accountId,
      email: mockEmail,
      name: `${provider} User`,
    }));
    
    // Sync local data to cloud
    await syncLocalDataToCloud();
  };

  const logout = () => {
    setUser(prev => ({
      userType: 'guest',
      deviceId: prev.deviceId,
      memoryCount: 0,
      quickCaptureCount: 0,
      askAICount: 0,
    }));
  };

  const syncLocalDataToCloud = async () => {
    // Mock cloud sync - replace with real API call
    console.log('Syncing local data to cloud...');
    await new Promise(resolve => setTimeout(resolve, 1500));
    console.log('Sync complete');
  };

  return (
    <UserContext.Provider
      value={{
        user,
        isLoggedIn,
        hasReachedLimit,
        incrementUsage,
        login,
        loginWithProvider,
        logout,
        syncLocalDataToCloud,
      }}
    >
      {children}
    </UserContext.Provider>
  );
}

export function useUser() {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within UserProvider');
  }
  return context;
}
