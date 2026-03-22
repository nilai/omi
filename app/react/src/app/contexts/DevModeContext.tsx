import { createContext, useContext, useState, ReactNode } from 'react';

export type DevModeState = 'normal' | 'empty' | 'error';

interface DevModeContextType {
  devMode: DevModeState;
  setDevMode: (mode: DevModeState) => void;
  isDevModeEnabled: boolean;
  setIsDevModeEnabled: (enabled: boolean) => void;
}

const DevModeContext = createContext<DevModeContextType | undefined>(undefined);

export function DevModeProvider({ children }: { children: ReactNode }) {
  const [devMode, setDevMode] = useState<DevModeState>('normal');
  const [isDevModeEnabled, setIsDevModeEnabled] = useState(false);

  return (
    <DevModeContext.Provider value={{ devMode, setDevMode, isDevModeEnabled, setIsDevModeEnabled }}>
      {children}
    </DevModeContext.Provider>
  );
}

export function useDevMode() {
  const context = useContext(DevModeContext);
  if (context === undefined) {
    throw new Error('useDevMode must be used within a DevModeProvider');
  }
  return context;
}
