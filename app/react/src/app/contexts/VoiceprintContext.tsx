import { createContext, useContext, useState, ReactNode } from 'react';

export interface Voiceprint {
  id: string;
  name: string;
  duration: number; // in seconds
  sampleCount: number;
  createdAt: Date;
  audioSegments?: Array<{
    time: string;
    text: string;
  }>;
}

interface VoiceprintContextType {
  voiceprints: Voiceprint[];
  addVoiceprint: (voiceprint: Omit<Voiceprint, 'id' | 'createdAt'>) => void;
  removeVoiceprint: (id: string) => void;
  getVoiceprint: (id: string) => Voiceprint | undefined;
}

const VoiceprintContext = createContext<VoiceprintContextType | undefined>(undefined);

export function VoiceprintProvider({ children }: { children: ReactNode }) {
  const [voiceprints, setVoiceprints] = useState<Voiceprint[]>([
    {
      id: '1',
      name: 'Alex',
      duration: 45,
      sampleCount: 3,
      createdAt: new Date('2026-01-15'),
    },
    {
      id: '2',
      name: 'Sarah',
      duration: 38,
      sampleCount: 2,
      createdAt: new Date('2026-01-18'),
    },
  ]);

  const addVoiceprint = (voiceprint: Omit<Voiceprint, 'id' | 'createdAt'>) => {
    const newVoiceprint: Voiceprint = {
      ...voiceprint,
      id: Date.now().toString(),
      createdAt: new Date(),
    };
    setVoiceprints(prev => [...prev, newVoiceprint]);
  };

  const removeVoiceprint = (id: string) => {
    setVoiceprints(prev => prev.filter(v => v.id !== id));
  };

  const getVoiceprint = (id: string) => {
    return voiceprints.find(v => v.id === id);
  };

  return (
    <VoiceprintContext.Provider value={{ voiceprints, addVoiceprint, removeVoiceprint, getVoiceprint }}>
      {children}
    </VoiceprintContext.Provider>
  );
}

export function useVoiceprints() {
  const context = useContext(VoiceprintContext);
  if (context === undefined) {
    throw new Error('useVoiceprints must be used within a VoiceprintProvider');
  }
  return context;
}
