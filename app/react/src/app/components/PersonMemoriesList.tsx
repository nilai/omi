import { ChevronLeft, Clock } from 'lucide-react';
import { useState } from 'react';
import { MemoryDetail } from './MemoryDetail';

interface Memory {
  id: string;
  title: string;
  startTime: string;
  endInfo: string;
}

interface PersonMemoriesListProps {
  personName: string;
  onBack: () => void;
  onMemoryClick: (memoryId: string) => void;
}

export function PersonMemoriesList({ personName, onBack, onMemoryClick }: PersonMemoriesListProps) {
  const [selectedMemory, setSelectedMemory] = useState<any>(null);

  // Mock data - memories with this person
  const memories: Memory[] = [
    {
      id: '1',
      title: 'Investor meeting - Series A funding discussion',
      startTime: 'Yesterday, 4:30 PM',
      endInfo: 'Yesterday',
    },
    {
      id: '2',
      title: 'Product launch planning with marketing team',
      startTime: 'Today, 9:15 AM',
      endInfo: '3h ago',
    },
    {
      id: '3',
      title: 'Strategy discussion about Q2 roadmap',
      startTime: 'Jan 18, 2026, 11:20 AM',
      endInfo: 'Jan 18',
    },
    {
      id: '4',
      title: 'Weekly review and planning session',
      startTime: 'Jan 19, 2026',
      endInfo: 'Jan 19',
    },
    {
      id: '5',
      title: 'Client feedback call about new dashboard features',
      startTime: 'Jan 20, 2026',
      endInfo: 'Jan 20',
    },
    {
      id: '6',
      title: 'Team brainstorming on product improvements',
      startTime: 'Jan 21, 2026, 3:45 PM',
      endInfo: 'Jan 21',
    },
    {
      id: '7',
      title: 'Coffee chat with Jordan about team dynamics',
      startTime: 'Yesterday, 2:15 PM',
      endInfo: '5h ago',
    },
    {
      id: '8',
      title: 'Team standup discussion on API migration',
      startTime: 'Today, 10:30 AM',
      endInfo: '2h ago',
    },
  ];

  return (
    <>
      <div className="fixed inset-0 bg-[#f2f2f7] z-50 flex flex-col">
        {/* Header */}
        <div className="flex-shrink-0 bg-white border-b border-black/[0.06]">
          <div className="px-4 pt-4 pb-3 flex items-center gap-3">
            <button
              onClick={onBack}
              className="flex items-center justify-center w-8 h-8 -ml-1 text-[#007aff] hover:bg-[#f2f2f7] rounded-lg transition-colors relative z-10"
              style={{ pointerEvents: 'auto' }}
            >
              <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
            </button>
            <h1 className="text-[17px] font-semibold text-[#1c1c1e] flex-1 text-center -ml-8">
              Memories with {personName}
            </h1>
            <div className="w-8" />
          </div>
        </div>

        {/* Memories list */}
        <div className="flex-1 overflow-y-auto">
          <div className="px-4 py-3 space-y-3">
            {memories.map((memory) => (
              <button
                key={memory.id}
                onClick={() => {
                  // Create a memory object and open detail
                  setSelectedMemory({
                    id: memory.id,
                    title: memory.title,
                    date: memory.endInfo,
                    startTime: memory.startTime,
                  });
                }}
                className="w-full bg-white rounded-[16px] shadow-sm border border-black/[0.06] p-4 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors text-left"
              >
                <h3 className="text-[17px] font-medium text-[#1c1c1e] mb-2 leading-snug">
                  {memory.title}
                </h3>
                <div className="flex items-center gap-1.5 text-[#8e8e93]">
                  <Clock className="w-4 h-4" strokeWidth={2} />
                  <span className="text-[15px]">
                    {memory.startTime} · {memory.endInfo}
                  </span>
                </div>
              </button>
            ))}
          </div>
          
          {/* Bottom spacing */}
          <div className="h-4" />
        </div>
      </div>
      
      {/* MemoryDetail Modal */}
      {selectedMemory && (
        <MemoryDetail
          memory={selectedMemory}
          onClose={() => setSelectedMemory(null)}
        />
      )}
    </>
  );
}