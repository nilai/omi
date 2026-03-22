import { MemoryDetail } from './MemoryDetail';

interface Memory {
  id: number;
  title: string;
  time: string;
  content?: string;
  relatedMemories?: string[];
  hasAudio?: boolean;
  hasSummary?: boolean;
  hasActivity?: boolean;
  audioDuration?: string;
  audioSource?: 'MemoPin' | 'MobilePhone';
}

interface MemoryDetailPageProps {
  memory: Memory;
  onBack: () => void;
  onCreateTodo?: (memoryId: number) => void;
  initialTab?: 'Overview' | 'Transcript' | 'Actions';
  highlightTimestamp?: string;
}

export function MemoryDetailPage({ memory, onBack, initialTab, highlightTimestamp }: MemoryDetailPageProps) {
  // All memories from Home tab have Audio + Summary, so we use the new MemoryDetail component
  return (
    <MemoryDetail 
      memory={memory}
      onClose={onBack}
      initialTab={initialTab}
      highlightTimestamp={highlightTimestamp}
    />
  );
}