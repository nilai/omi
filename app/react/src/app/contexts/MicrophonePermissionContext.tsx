import { createContext, useContext, useState, ReactNode, useEffect } from 'react';

type PermissionStatus = 'not_determined' | 'granted' | 'denied';

interface MicrophonePermissionContextType {
  permissionStatus: PermissionStatus;
  requestPermission: () => Promise<boolean>;
  checkPermission: () => PermissionStatus;
  hasAskedPermission: boolean;
}

const MicrophonePermissionContext = createContext<MicrophonePermissionContextType | undefined>(undefined);

export function MicrophonePermissionProvider({ children }: { children: ReactNode }) {
  const [permissionStatus, setPermissionStatus] = useState<PermissionStatus>(() => {
    // Check localStorage for saved permission status
    const saved = localStorage.getItem('mic_permission_status');
    return (saved as PermissionStatus) || 'not_determined';
  });
  
  const [hasAskedPermission, setHasAskedPermission] = useState(() => {
    const asked = localStorage.getItem('mic_permission_asked');
    return asked === 'true';
  });

  // Save permission status to localStorage
  useEffect(() => {
    localStorage.setItem('mic_permission_status', permissionStatus);
  }, [permissionStatus]);

  useEffect(() => {
    localStorage.setItem('mic_permission_asked', hasAskedPermission.toString());
  }, [hasAskedPermission]);

  const requestPermission = async (): Promise<boolean> => {
    setHasAskedPermission(true);
    
    // In a real app, this would use navigator.mediaDevices.getUserMedia
    // For demo purposes, we'll simulate the system permission dialog
    return new Promise((resolve) => {
      // Simulate system dialog with a small delay
      setTimeout(() => {
        // For demo: randomly grant or deny (you can change this logic)
        // In production, this would be based on actual system response
        const granted = true; // Simulate user granting permission
        
        if (granted) {
          setPermissionStatus('granted');
          resolve(true);
        } else {
          setPermissionStatus('denied');
          resolve(false);
        }
      }, 500);
    });
  };

  const checkPermission = (): PermissionStatus => {
    return permissionStatus;
  };

  return (
    <MicrophonePermissionContext.Provider
      value={{
        permissionStatus,
        requestPermission,
        checkPermission,
        hasAskedPermission,
      }}
    >
      {children}
    </MicrophonePermissionContext.Provider>
  );
}

export function useMicrophonePermission() {
  const context = useContext(MicrophonePermissionContext);
  if (context === undefined) {
    throw new Error('useMicrophonePermission must be used within a MicrophonePermissionProvider');
  }
  return context;
}
