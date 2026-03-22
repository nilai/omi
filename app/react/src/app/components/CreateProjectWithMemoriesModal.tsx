import { X, ChevronRight } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useState, useEffect } from 'react';
import { SelectMemoriesPage } from './SelectMemoriesPage';

interface Memory {
  id: number;
  title: string | null;
  date: string;
  audioDuration?: string;
}

interface CreateProjectWithMemoriesModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCreate: (name: string, selectedMemoryIds: number[]) => void;
  allMemories: Memory[];
}

export function CreateProjectWithMemoriesModal({
  isOpen,
  onClose,
  onCreate,
  allMemories,
}: CreateProjectWithMemoriesModalProps) {
  const [projectName, setProjectName] = useState('');
  const [selectedMemories, setSelectedMemories] = useState<Set<number>>(new Set());
  const [showAllMemories, setShowAllMemories] = useState(false);
  const [showSelectMemoriesPage, setShowSelectMemoriesPage] = useState(false);
  const [hasUserSelectedMemories, setHasUserSelectedMemories] = useState(false);

  // Reset state when modal opens/closes
  useEffect(() => {
    if (!isOpen) {
      setProjectName('');
      setSelectedMemories(new Set());
      setShowAllMemories(false);
      setShowSelectMemoriesPage(false);
      setHasUserSelectedMemories(false);
    }
  }, [isOpen]);

  const handleCreate = () => {
    if (projectName.trim()) {
      onCreate(projectName.trim(), Array.from(selectedMemories));
      onClose();
    }
  };

  const handleCancel = () => {
    onClose();
  };

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
    // Don't set hasUserSelectedMemories here - only when coming back from SelectMemoriesPage
  };

  // Determine what memories to display
  let displayedMemories: Memory[];
  let needsScrolling = false;
  
  if (hasUserSelectedMemories) {
    // User has selected memories - show selected memories only
    displayedMemories = allMemories.filter(m => selectedMemories.has(m.id));
    needsScrolling = displayedMemories.length > 3;
  } else {
    // Default view - show latest 3 memories (or fewer if less than 3 exist)
    // Sort by id descending (assuming higher id = newer)
    const sortedMemories = [...allMemories].sort((a, b) => b.id - a.id);
    displayedMemories = sortedMemories.slice(0, 3);
    needsScrolling = false;
  }

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleCancel}
            className="fixed inset-0 bg-black/40 z-[60]"
          />

          {/* Bottom Sheet Modal */}
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 30, stiffness: 300 }}
            className="fixed inset-x-0 bottom-0 bg-white rounded-t-[28px] z-[60] shadow-2xl max-h-[85vh] flex flex-col"
          >
            {/* Handle bar */}
            <div className="flex justify-center pt-3 pb-2">
              <div className="w-9 h-1 bg-[#d1d1d6] rounded-full" />
            </div>

            {/* Header */}
            <div className="flex items-center justify-between px-5 pt-3 pb-4 border-b border-black/[0.06]">
              <h2 className="text-[20px] font-semibold text-[#1c1c1e]">
                Create Project
              </h2>
              <button
                onClick={handleCancel}
                className="w-8 h-8 flex items-center justify-center rounded-full active:bg-[#f2f2f7] transition-colors"
              >
                <X className="w-5 h-5 text-[#8e8e93]" strokeWidth={2.5} />
              </button>
            </div>

            {/* Scrollable Content */}
            <div className="flex-1 overflow-y-auto">
              <div className="px-5 py-5 space-y-6">
                {/* Project Name Input */}
                <div>
                  <label className="block mb-2">
                    <span className="text-[15px] font-semibold text-[#1c1c1e]">
                      Project Name
                    </span>
                  </label>
                  <input
                    type="text"
                    value={projectName}
                    onChange={(e) => setProjectName(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && projectName.trim()) {
                        handleCreate();
                      }
                    }}
                    placeholder="Enter project name"
                    autoFocus
                    className="w-full px-4 py-3.5 text-[17px] text-[#1c1c1e] placeholder:text-[#8e8e93] bg-[#f2f2f7] border border-transparent rounded-[12px] focus:outline-none focus:border-[#007aff] focus:bg-white transition-all"
                  />
                </div>

                {/* Add Memories Section */}
                <div>
                  <div className="mb-3">
                    <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-1">
                      Add Memories (optional)
                    </h3>
                    <p className="text-[13px] text-[#8e8e93]">
                      Select memories to include in this project
                    </p>
                  </div>

                  {/* Memory List */}
                  <div 
                    className={`bg-white rounded-[16px] border border-black/[0.06] overflow-hidden ${
                      needsScrolling ? 'overflow-y-auto' : ''
                    }`}
                    style={needsScrolling ? { maxHeight: '280px' } : {}}
                  >
                    {allMemories.length === 0 ? (
                      <div className="px-4 py-6 text-center">
                        <p className="text-[15px] text-[#8e8e93]">
                          No memory exist
                        </p>
                      </div>
                    ) : displayedMemories.length === 0 ? (
                      <div className="px-4 py-6 text-center">
                        <p className="text-[15px] text-[#8e8e93]">
                          No memories selected
                        </p>
                        <p className="text-[13px] text-[#8e8e93] mt-1">
                          Tap "View more memories" to add
                        </p>
                      </div>
                    ) : (
                      displayedMemories.map((memory, index) => {
                        const isSelected = selectedMemories.has(memory.id);
                        const isAudioOnly = !memory.title;
                        
                        return (
                          <div key={memory.id}>
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
                            
                            {/* Divider - not on last item */}
                            {index < displayedMemories.length - 1 && (
                              <div className="border-b border-black/[0.06] ml-[52px]" />
                            )}
                          </div>
                        );
                      })
                    )}
                  </div>

                  {/* View More Memories Button - Always show */}
                  <button
                    onClick={() => setShowSelectMemoriesPage(true)}
                    className="w-full mt-3 flex items-center justify-center gap-1 py-2.5 text-[15px] text-[#007aff] font-medium active:opacity-60 transition-opacity"
                  >
                    <span>
                      {selectedMemories.size === 0 
                        ? `View all memories (${allMemories.length})` 
                        : `View more memories`}
                    </span>
                    <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
                  </button>
                </div>
              </div>
            </div>

            {/* Footer Buttons */}
            <div className="border-t border-black/[0.06] bg-white px-5 py-3 safe-area-inset-bottom">
              <div className="flex gap-3">
                <button
                  onClick={handleCancel}
                  className="flex-1 py-3.5 rounded-[12px] bg-[#f2f2f7] text-[#1c1c1e] text-[17px] font-semibold active:bg-[#e5e5ea] transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCreate}
                  disabled={!projectName.trim()}
                  className={`flex-1 py-3.5 rounded-[12px] text-white text-[17px] font-semibold transition-all ${
                    projectName.trim()
                      ? 'bg-[#007aff] active:bg-[#0051d5]'
                      : 'bg-[#007aff]/40 cursor-not-allowed'
                  }`}
                >
                  Create
                </button>
              </div>
            </div>
          </motion.div>

          {/* Select Memories Full Screen Page */}
          <SelectMemoriesPage 
            isOpen={showSelectMemoriesPage}
            onBack={() => setShowSelectMemoriesPage(false)}
            onDone={(selectedIds) => {
              setSelectedMemories(new Set(selectedIds));
              setShowSelectMemoriesPage(false);
              setHasUserSelectedMemories(true);
            }}
            allMemories={allMemories}
            initialSelectedIds={Array.from(selectedMemories)}
          />
        </>
      )}
    </AnimatePresence>
  );
}