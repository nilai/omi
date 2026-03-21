import { ChevronLeft, Search } from 'lucide-react';
import { useState, useEffect } from 'react';

interface Memory {
  id: number;
  title: string | null;
  date: string;
  audioDuration?: string;
}

interface SelectMemoriesPageProps {
  isOpen: boolean;
  onBack: () => void;
  onDone: (selectedIds: number[]) => void;
  allMemories: Memory[];
  initialSelectedIds: number[];
}

export function SelectMemoriesPage({
  isOpen,
  onBack,
  onDone,
  allMemories,
  initialSelectedIds,
}: SelectMemoriesPageProps) {
  const [selectedMemories, setSelectedMemories] = useState<Set<number>>(
    new Set(initialSelectedIds)
  );
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Update selected memories when initialSelectedIds changes
  useEffect(() => {
    if (isOpen) {
      setSelectedMemories(new Set(initialSelectedIds));
    }
  }, [isOpen, initialSelectedIds]);

  if (!isOpen) return null;

  const toggleMemory = (memoryId: number) => {
    setSelectedMemories(prev => {
      const newSet = new Set(prev);
      if (newSet.has(memoryId)) {
        newSet.delete(memoryId);
      } else {
        newSet.add(memoryId);
      }
      return newSet;
    });
  };

  const handleDone = () => {
    onDone(Array.from(selectedMemories));
  };

  const handleBack = () => {
    // Reset to initial selection when going back without saving
    setSelectedMemories(new Set(initialSelectedIds));
    onBack();
  };

  // Separate selected and unselected memories
  const selectedMemoriesData = allMemories.filter(m => selectedMemories.has(m.id));
  const unselectedMemoriesData = allMemories.filter(m => !selectedMemories.has(m.id));

  // Filter by search query if in search mode
  const filteredUnselected = showSearch && searchQuery
    ? unselectedMemoriesData.filter(m => {
        const searchLower = searchQuery.toLowerCase();
        const title = m.title || m.date;
        return title.toLowerCase().includes(searchLower);
      })
    : unselectedMemoriesData;

  const MemoryItem = ({ memory, isSelected }: { memory: Memory; isSelected: boolean }) => {
    const isAudioOnly = !memory.title;
    
    return (
      <button
        onClick={() => toggleMemory(memory.id)}
        className="w-full flex items-center gap-3 px-4 py-3.5 active:bg-[#f2f2f7] transition-colors"
      >
        {/* Checkbox */}
        <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-all ${
          isSelected
            ? 'border-[#007aff] bg-[#007aff]'
            : 'border-[#c6c6c8]'
        }`}>
          {isSelected && (
            <svg
              width="14"
              height="11"
              viewBox="0 0 14 11"
              fill="none"
              className="text-white"
            >
              <path
                d="M1 5.5L5 9.5L13 1.5"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          )}
        </div>
        
        {/* Memory Info */}
        <div className="flex-1 text-left min-w-0">
          <div className="text-[17px] text-[#1c1c1e] truncate">
            {isAudioOnly ? memory.date : memory.title}
          </div>
          <div className="text-[14px] text-[#8e8e93] flex items-center gap-1.5 mt-0.5">
            <span>{isAudioOnly ? 'Audio only' : memory.date}</span>
            {memory.audioDuration && (
              <>
                <span>·</span>
                <span>{memory.audioDuration}</span>
              </>
            )}
          </div>
        </div>
      </button>
    );
  };

  // If in search mode, show search page
  if (showSearch) {
    return (
      <div className="fixed inset-0 z-[70] bg-white">
        {/* Search Header */}
        <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06] relative">
          <button
            onClick={() => {
              setShowSearch(false);
              setSearchQuery('');
            }}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-6 h-6" strokeWidth={2} />
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            Search memories
          </h1>
          <div className="w-6" />
        </div>

        {/* Search Input */}
        <div className="px-5 pt-4">
          <div className="flex items-center gap-2 bg-[#f2f2f7] rounded-[12px] px-4 py-3">
            <Search className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by title or date..."
              className="flex-1 bg-transparent outline-none text-[17px] text-[#1c1c1e] placeholder:text-[#8e8e93]"
              autoFocus
            />
          </div>
        </div>

        {/* Search Results */}
        <div className="px-5 pt-6 pb-20 overflow-y-auto" style={{ height: 'calc(100vh - 140px)' }}>
          {searchQuery && (
            <>
              <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3">
                Results
              </h3>
              <div className="bg-white rounded-[16px] border border-black/[0.06] overflow-hidden">
                {filteredUnselected.length === 0 ? (
                  <div className="px-4 py-8 text-center">
                    <p className="text-[15px] text-[#8e8e93]">No memories found</p>
                  </div>
                ) : (
                  filteredUnselected.map((memory, index) => (
                    <div key={memory.id}>
                      <MemoryItem memory={memory} isSelected={selectedMemories.has(memory.id)} />
                      {index < filteredUnselected.length - 1 && (
                        <div className="border-b border-black/[0.06] ml-[52px]" />
                      )}
                    </div>
                  ))
                )}
              </div>
            </>
          )}
        </div>
      </div>
    );
  }

  // Main selection page
  return (
    <div className="fixed inset-0 z-[70] bg-[#f2f2f7] flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-black/[0.06]">
        <div className="px-5 pt-4 pb-3 flex items-center justify-between relative">
          <button
            onClick={handleBack}
            className="text-[#007aff] active:opacity-60 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            Select Memories
          </h1>
          <button
            onClick={handleDone}
            className="text-[17px] text-[#007aff] font-semibold active:opacity-60 transition-opacity"
          >
            Done ({selectedMemories.size})
          </button>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="px-5 pt-5 pb-20 space-y-5">
          {/* Search Bar */}
          <button
            onClick={() => setShowSearch(true)}
            className="w-full flex items-center gap-3 bg-white rounded-[12px] px-4 py-3 border border-black/[0.06] active:bg-[#f9f9f9] transition-colors"
          >
            <Search className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
            <span className="text-[17px] text-[#8e8e93]">Search memories</span>
          </button>

          {/* Selected Memories Section */}
          {selectedMemoriesData.length > 0 && (
            <div>
              <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3 px-1">
                Selected ({selectedMemoriesData.length})
              </h3>
              <div className="bg-white rounded-[16px] border border-black/[0.06] overflow-hidden">
                {selectedMemoriesData.map((memory, index) => (
                  <div key={memory.id}>
                    <MemoryItem memory={memory} isSelected={true} />
                    {index < selectedMemoriesData.length - 1 && (
                      <div className="border-b border-black/[0.06] ml-[52px]" />
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* All Memories Section */}
          <div>
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3 px-1">
              All Memories
            </h3>
            <div className="bg-white rounded-[16px] border border-black/[0.06] overflow-hidden">
              {unselectedMemoriesData.length === 0 ? (
                <div className="px-4 py-8 text-center">
                  <p className="text-[15px] text-[#8e8e93]">
                    {selectedMemoriesData.length > 0 
                      ? 'All memories have been selected'
                      : 'No memories available'}
                  </p>
                </div>
              ) : (
                unselectedMemoriesData.map((memory, index) => (
                  <div key={memory.id}>
                    <MemoryItem memory={memory} isSelected={false} />
                    {index < unselectedMemoriesData.length - 1 && (
                      <div className="border-b border-black/[0.06] ml-[52px]" />
                    )}
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}