import { ChevronLeft, Trash2, ChevronRight, Sparkles, Edit3, Mic } from 'lucide-react';
import { useState } from 'react';
import { AnalyzeActionsModal } from './AnalyzeActionsModal';

interface Memo {
  id: number;
  title?: string;
  content: string;
  timestamp?: Date;
  relatedMemories?: string[];
  todoCreated?: boolean;
  actionsAnalyzed?: boolean;  // New field to track if actions were analyzed
  type?: 'highlight' | 'manual' | 'voice';  // Type of memo
  sourceMemory?: {  // For highlight memos - where they came from
    id: number;
    title: string;
    timestamp: string;  // e.g., "02:14"
  };
  linkedMemory?: {
    id: string;
    title: string;
    date: string;
    duration?: string;
    hasSummary?: boolean;
  };
}

interface MemoDetailModalProps {
  memo: Memo;
  memos?: Memo[];  // Optional memos array for real-time updates
  onClose: () => void;
  onDelete?: (memoId: number) => void;
  onCreateTodo?: (memoId: number) => void;
  onAnalyzeActions?: (memoId: number, todos: string[]) => void;  // New callback
  onRelatedMemoryClick?: (memoryTitle: string) => void;
  onLinkMemory?: (memoId: number) => void;
  onMemoryClick?: (memoryId: string) => void;
  onHighlightClick?: (memoryId: number, timestamp: string) => void;  // New callback for highlight source click
}

export function MemoDetailModal({ memo, memos, onClose, onDelete, onCreateTodo, onAnalyzeActions, onRelatedMemoryClick, onLinkMemory, onMemoryClick, onHighlightClick }: MemoDetailModalProps) {
  // Use real-time memo data from memos array if available, otherwise use the prop
  const currentMemo = memos ? memos.find(m => m.id === memo.id) || memo : memo;
  const [showAnalyzeModal, setShowAnalyzeModal] = useState(false);
  
  const handleDelete = () => {
    onDelete?.(currentMemo.id);
    onClose();
  };

  const handleAnalyzeClick = () => {
    setShowAnalyzeModal(true);
  };

  const handleAnalyzeConfirm = (selectedTodos: string[]) => {
    onAnalyzeActions?.(currentMemo.id, selectedTodos);
    setShowAnalyzeModal(false);
  };

  return (
    <>
      <div className="fixed inset-0 z-50 flex items-end justify-center">
        {/* Backdrop */}
        <div 
          className="absolute inset-0 bg-black/40 backdrop-blur-sm"
          onClick={onClose}
        />
        
        {/* Modal - 半页弹窗 */}
        <div 
          className="relative w-full max-w-md bg-[#f2f2f7] rounded-t-[24px] shadow-2xl animate-slide-up"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="px-5 pt-4 pb-3 border-b border-black/[0.06] bg-white rounded-t-[24px] flex items-center justify-between relative">
            <button 
              onClick={onClose}
              className="text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
            </button>
            <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 -translate-x-1/2">
              Memo
            </h1>
            {onDelete && (
              <button 
                onClick={handleDelete}
                className="w-8 h-8 flex items-center justify-center text-[#ff3b30] hover:opacity-70 transition-opacity"
              >
                <Trash2 className="w-5 h-5" strokeWidth={2} />
              </button>
            )}
          </div>

          {/* Content */}
          <div className="px-5 pt-6 pb-8 max-h-[70vh] overflow-y-auto">
            {/* Memo Type Badge */}
            <div className="mb-4">
              {currentMemo.type === 'highlight' ? (
                <div className="flex items-center gap-2 text-[#ff9500]">
                  <Sparkles className="w-4 h-4" strokeWidth={2} />
                  <span className="text-[13px] font-medium">Highlight</span>
                </div>
              ) : currentMemo.type === 'voice' ? (
                <div className="flex items-center gap-2 text-[#ff9500]">
                  <Mic className="w-4 h-4" strokeWidth={2} />
                  <span className="text-[13px] font-medium">Voice Memo</span>
                </div>
              ) : (
                <div className="flex items-center gap-2 text-[#8e8e93]">
                  <Edit3 className="w-4 h-4" strokeWidth={2} />
                  <span className="text-[13px] font-medium">Manual Memo</span>
                </div>
              )}
            </div>

            {/* Source Memory for Highlight - Clickable */}
            {currentMemo.type === 'highlight' && currentMemo.sourceMemory && (
              <div className="mb-6">
                <button
                  onClick={() => onHighlightClick?.(currentMemo.sourceMemory!.id, currentMemo.sourceMemory!.timestamp)}
                  className="text-[13px] text-[#007aff] hover:text-[#0051d5] transition-colors font-normal"
                >
                  From: {currentMemo.sourceMemory.title} · {currentMemo.sourceMemory.timestamp}
                </button>
              </div>
            )}

            {/* Divider after type info */}
            <div className="h-[1px] bg-black/[0.1] mb-6" />

            {/* Title - only show for voice and from types, not for manual memos */}
            {currentMemo.type && (currentMemo.type === 'voice' || currentMemo.type === 'from') && (
              <h2 className="text-[22px] text-[#1c1c1e] font-semibold leading-[1.3] mb-6">
                {currentMemo.title}
              </h2>
            )}

            {/* Memo 内容 */}
            <div className="mb-8">
              <p className="text-[15px] text-[#3c3c43] leading-[1.5] mb-8">
                {currentMemo.content}
              </p>
            </div>

            {/* Linked Memory Section */}
            {currentMemo.linkedMemory && (
              <>
                <div className="h-[1px] bg-black/[0.1] mb-6" />
                
                <div className="mb-8">
                  <h3 className="text-[13px] text-[#8e8e93] font-medium mb-3">
                    Linked memory (optional)
                  </h3>
                  <div className="space-y-2">
                    <button
                      onClick={() => onMemoryClick?.(currentMemo.linkedMemory.id)}
                      className="w-full text-left px-0 py-2 rounded-[8px] hover:bg-white/60 transition-colors group"
                    >
                      <p className="text-[15px] text-[#3c3c43] leading-[1.5] group-hover:text-[#007aff] transition-colors">
                        {currentMemo.linkedMemory.title}
                      </p>
                    </button>
                  </div>
                </div>
              </>
            )}

            {/* Divider before Actions */}
            <div className="h-[1px] bg-black/[0.1] mb-6" />

            {/* Actions */}
            <div className="mb-2">
              <h3 className="text-[13px] text-[#8e8e93] font-medium mb-3">
                Actions
              </h3>
              <div className="space-y-2">
                {/* Analyze Actions Button */}
                {currentMemo.actionsAnalyzed ? (
                  <div className="text-[15px] text-[#34c759] font-medium">
                    Action extracted
                  </div>
                ) : (
                  <button
                    onClick={handleAnalyzeClick}
                    className="text-[15px] text-[#007aff]/70 hover:text-[#007aff] transition-colors font-normal flex items-center gap-1.5"
                  >
                    <Sparkles className="w-4 h-4" strokeWidth={2} />
                    <span>Analyze actions</span>
                  </button>
                )}
                
                {/* Link Memory Action - Removed from UI but system still tracks linkedMemory */}
                {/* The linkedMemory data structure and functionality is preserved in the system */}
              </div>
            </div>
          </div>
        </div>

        <style>{`
          @keyframes slide-up {
            from {
              transform: translateY(100%);
            }
            to {
              transform: translateY(0);
            }
          }
          .animate-slide-up {
            animation: slide-up 0.3s ease-out;
          }
        `}</style>
      </div>

      {/* Analyze Actions Modal */}
      {showAnalyzeModal && (
        <AnalyzeActionsModal
          isOpen={showAnalyzeModal}
          onClose={() => setShowAnalyzeModal(false)}
          memoContent={currentMemo.content}
          memoTitle={currentMemo.title}
          memoId={currentMemo.id}
          onConfirm={handleAnalyzeConfirm}
        />
      )}
    </>
  );
}