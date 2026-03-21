import { ChevronLeft, Clock } from 'lucide-react';
import { useState } from 'react';

interface Memory {
  id: number;
  title: string;
  date: string;
  time?: string;
  duration?: string;
  type?: string;
  hasSummary?: boolean;
}

interface MemoryListSelectorProps {
  onBack: () => void;
  onSelectMemory: (memoryId: number) => void;
  memories: Memory[];
}

export function MemoryListSelector({ onBack, onSelectMemory, memories }: MemoryListSelectorProps) {
  // Sort memories by ID (newest first - higher ID means newer)
  const sortedMemories = [...memories].sort((a, b) => b.id - a.id);

  return (
    <div className="fixed inset-0 z-50 bg-background">
      {/* Header */}
      <div className="px-5 pt-5 pb-3 border-b border-border">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="w-9 h-9 flex items-center justify-center -ml-2"
          >
            <ChevronLeft className="w-6 h-6 text-[#007aff]" strokeWidth={2} />
          </button>
          <h1 className="text-[17px] font-semibold">Link to a Memory</h1>
        </div>
      </div>

      {/* Memory List - Compact layout */}
      <div className="overflow-y-auto" style={{ height: 'calc(100vh - 68px)' }}>
        <div className="px-5 py-3">
          {sortedMemories.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-[15px] text-muted-foreground">No memories found</p>
            </div>
          ) : (
            <div className="space-y-2">
              {sortedMemories.map((memory) => (
                <button
                  key={memory.id}
                  onClick={() => onSelectMemory(memory.id)}
                  className="w-full text-left bg-white border border-black/[0.06] rounded-[12px] p-3 hover:bg-[#f9f9f9] transition-colors active:scale-[0.98]"
                >
                  {/* Title */}
                  <h3 className="text-[15px] font-medium text-[#1c1c1e] mb-1 line-clamp-2">
                    {memory.title}
                  </h3>
                  
                  {/* Date and Time */}
                  <div className="flex items-center gap-2 text-[13px] text-[#8e8e93]">
                    <Clock className="w-3.5 h-3.5" />
                    <span>
                      {memory.date}
                      {memory.time && ` • ${memory.time}`}
                      {memory.duration && ` • ${memory.duration}`}
                    </span>
                  </div>
                  
                  {/* Type indicator if available */}
                  {memory.type && (
                    <div className="mt-2">
                      <span className="inline-block px-2 py-0.5 text-[11px] font-medium bg-[#f2f2f7] text-[#8e8e93] rounded">
                        {memory.type}
                      </span>
                    </div>
                  )}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}