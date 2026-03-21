import { createContext, useContext, useState, ReactNode } from 'react';
import { AudioStatusType } from '../components/AudioStatusBar';

interface AudioStatus {
  type: AudioStatusType;
  progress?: number;
  currentFile?: number;
  totalFiles?: number;
}

interface AudioStatusContextType {
  audioStatus: AudioStatus | null;
  setRecording: () => void;
  setSyncing: (currentFile?: number, totalFiles?: number, progress?: number) => void;
  setImporting: (progress: number) => void;
  setProcessing: (progress: number) => void;
  clearStatus: () => void;
  updateProgress: (progress: number) => void;
}

const AudioStatusContext = createContext<AudioStatusContextType | undefined>(undefined);

export function AudioStatusProvider({ children }: { children: ReactNode }) {
  const [audioStatus, setAudioStatus] = useState<AudioStatus | null>(null);

  const setRecording = () => {
    setAudioStatus({ type: 'recording' });
  };

  const setSyncing = (currentFile?: number, totalFiles?: number, progress?: number) => {
    setAudioStatus({ 
      type: 'syncing', 
      currentFile,
      totalFiles,
      progress 
    });
  };

  const setImporting = (progress: number) => {
    setAudioStatus({ type: 'importing', progress });
  };

  const setProcessing = (progress: number) => {
    setAudioStatus({ type: 'processing', progress });
  };

  const clearStatus = () => {
    setAudioStatus(null);
  };

  const updateProgress = (progress: number) => {
    setAudioStatus(prev => prev ? { ...prev, progress } : null);
  };

  return (
    <AudioStatusContext.Provider
      value={{
        audioStatus,
        setRecording,
        setSyncing,
        setImporting,
        setProcessing,
        clearStatus,
        updateProgress,
      }}
    >
      {children}
    </AudioStatusContext.Provider>
  );
}

export function useAudioStatus() {
  const context = useContext(AudioStatusContext);
  if (!context) {
    throw new Error('useAudioStatus must be used within AudioStatusProvider');
  }
  return context;
}
