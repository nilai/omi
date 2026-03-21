import { ChevronLeft, Check } from 'lucide-react';
import { useState } from 'react';

interface Memory {
  id: number;
  title: string | null;
  date: string;
  summary?: string | null;
  hasAudio?: boolean;
  hasSummary?: boolean;
  hasActivity?: boolean;
  audioDuration?: string;
}

interface LinkMemoryPageProps {
  onBack: () => void;
  allMemories: Memory[];
  linkedMemoryIds: number[];
  onConfirm: (selectedIds: number[]) => void;
}

export function LinkMemoryPage({ onBack, allMemories, linkedMemoryIds, onConfirm }: LinkMemoryPageProps) {
  const [selectedIds, setSelectedIds] = useState<number[]>([...linkedMemoryIds]);

  const handleToggle = (memoryId: number) => {
    // Check if this memory is already linked (cannot be unselected)
    if (linkedMemoryIds.includes(memoryId)) {
      return;
    }

    if (selectedIds.includes(memoryId)) {
      setSelectedIds(selectedIds.filter(id => id !== memoryId));
    } else {
      setSelectedIds([...selectedIds, memoryId]);
    }
  };

  const handleConfirm = () => {
    // Only return newly selected memories (exclude already linked ones)
    const newlySelected = selectedIds.filter(id => !linkedMemoryIds.includes(id));
    onConfirm(newlySelected);
  };

  const isAlreadyLinked = (memoryId: number) => linkedMemoryIds.includes(memoryId);
  const isSelected = (memoryId: number) => selectedIds.includes(memoryId);
  const newlySelectedCount = selectedIds.filter(id => !linkedMemoryIds.includes(id)).length;

  return (
    <div className="flex flex-col h-full bg-[#f2f2f7]">
      {/* Header */}
      <div className="bg-white border-b border-black/[0.06]">
        <div className="px-5 pt-4 pb-3 flex items-center justify-between relative">
          <button
            onClick={onBack}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-6 h-6" strokeWidth={2} />
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            Add memories to project
          </h1>
          <button
            onClick={handleConfirm}
            disabled={newlySelectedCount === 0}
            className={`text-[17px] font-semibold transition-opacity ${
              newlySelectedCount === 0
                ? 'text-[#8e8e93] cursor-not-allowed'
                : 'text-[#007aff] hover:opacity-70'
            }`}
          >
            {newlySelectedCount > 0 ? `Add (${newlySelectedCount})` : 'Add'}
          </button>
        </div>
      </div>

      {/* Memory List */}
      <div className="flex-1 overflow-y-auto">
        <div className="px-5 pt-5 pb-20 space-y-2">
          {allMemories.map((memory) => {
            const alreadyLinked = isAlreadyLinked(memory.id);
            const selected = isSelected(memory.id);
            const audioOnly = memory.title === null || memory.title === 'Audio only';

            return (
              <button
                key={memory.id}
                onClick={() => handleToggle(memory.id)}
                disabled={alreadyLinked}
                className={`w-full text-left px-4 py-3 rounded-[12px] border transition-all ${
                  alreadyLinked
                    ? 'bg-[#f2f2f7] border-black/[0.06] cursor-not-allowed opacity-60'
                    : selected
                    ? 'bg-white border-[#007aff] shadow-sm'
                    : 'bg-white border-black/[0.06] hover:bg-[#f9f9f9] active:bg-[#f2f2f7]'
                }`}
              >
                <div className="flex items-start gap-3">
                  {/* Checkbox */}
                  <div className="mt-0.5 flex-shrink-0">
                    <div
                      className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all ${
                        selected
                          ? 'bg-[#007aff] border-[#007aff]'
                          : 'bg-white border-[#d1d1d6]'
                      }`}
                    >
                      {selected && <Check className="w-3 h-3 text-white" strokeWidth={3} />}
                    </div>
                  </div>

                  {/* Memory Content */}
                  <div className="flex-1 min-w-0">
                    {audioOnly ? (
                      // Audio-only layout
                      <>
                        <div className="mb-1">
                          <span className="text-[15px] font-medium text-[#1c1c1e]">
                            {memory.date}
                          </span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-[13px] text-[#8e8e93]">
                            Audio only
                          </span>
                          {memory.audioDuration && (
                            <>
                              <span className="text-[#8e8e93]">·</span>
                              <span className="text-[13px] text-[#8e8e93]">
                                {memory.audioDuration}
                              </span>
                            </>
                          )}
                        </div>
                      </>
                    ) : (
                      // Regular memory layout
                      <>
                        <div className="mb-1">
                          <span className="text-[15px] font-medium text-[#1c1c1e] line-clamp-2">
                            {memory.title}
                          </span>
                        </div>
                        <div className="flex items-center gap-1.5 text-[13px] text-[#8e8e93]">
                          <span>{memory.date}</span>
                          {alreadyLinked && (
                            <>
                              <span>·</span>
                              <span className="text-[#007aff]">Already linked</span>
                            </>
                          )}
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}