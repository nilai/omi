import { ChevronLeft, MoreVertical, Check, ChevronRight } from 'lucide-react';
import { useState } from 'react';

interface LinkedMemory {
  id: string;
  title: string;
  date: string;
  duration?: string;
  hasSummary?: boolean;
}

interface Todo {
  id: number;
  title: string;
  completed: boolean;
  category: 'Up Next' | 'Today' | 'Upcoming' | 'Later' | 'Completed';
  linkedMemory?: LinkedMemory;
  context?: string;
  time?: string;
  notes?: string[];
  priority?: string;
  dueDate?: string;
}

interface CompletedTodoDetailModalProps {
  todo: Todo;
  onClose: () => void;
  onRestore?: (id: number) => void;
  onDelete?: (id: number) => void;
  onMemoryClick?: (memoryId: string) => void;
}

export function CompletedTodoDetailModal({ todo, onClose, onRestore, onDelete, onMemoryClick }: CompletedTodoDetailModalProps) {
  const [showMenu, setShowMenu] = useState(false);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal - 半页弹窗 */}
      <div 
        className="relative w-full max-w-md bg-white rounded-t-[24px] shadow-2xl animate-slide-up"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-4 pt-3 pb-2 border-b border-black/[0.06] flex items-center justify-between">
          <button 
            onClick={onClose}
            className="flex items-center gap-2 text-[#007aff] text-[17px] font-medium hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
            <span>Todo</span>
          </button>
          
          {/* Three dots menu button */}
          <div className="relative">
            <button
              onClick={() => setShowMenu(!showMenu)}
              className="p-2 hover:bg-[#f2f2f7] rounded-full transition-colors"
            >
              <MoreVertical className="w-5 h-5 text-[#3c3c43]" strokeWidth={2.5} />
            </button>
            
            {/* Dropdown menu - Empty for completed todos */}
            {showMenu && (
              <div className="absolute right-0 top-full mt-2 bg-white rounded-[12px] shadow-lg z-20 min-w-[200px] overflow-hidden border border-black/[0.06]">
                <div className="px-4 py-3 text-[14px] text-[#8e8e93] text-center">
                  No actions available
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Content - 紧凑布局，无滚动 */}
        <div className="px-4 pt-4 pb-4">
          {/* 核心内容 - 减小字号和间距 */}
          <h2 className="text-[18px] text-[#1c1c1e] font-semibold leading-[1.3] mb-4">
            {todo.title}
          </h2>

          {/* Status - 紧凑 */}
          <div className="mb-3">
            <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
              Status
            </h3>
            <div className="flex items-center gap-2 text-[14px] text-[#2d5a47]">
              <Check className="w-4 h-4" strokeWidth={2.5} />
              <span className="font-medium">Completed {todo.time || 'today'}</span>
            </div>
          </div>

          {/* Context - 紧凑 */}
          {todo.linkedMemory && (
            <div className="mb-3">
              <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
                Context
              </h3>
              <button
                onClick={() => onMemoryClick?.(todo.linkedMemory!.id)}
                className="w-full bg-[#f9f9f9] rounded-[10px] p-3 text-left hover:bg-[#f2f2f7] transition-all border border-black/[0.06] group"
              >
                <p className="text-[11px] text-[#8e8e93] mb-1.5">From memory:</p>
                <div className="flex items-start justify-between gap-3 mb-1.5">
                  <h4 className="text-[14px] font-medium text-[#1c1c1e] flex-1">
                    {todo.linkedMemory.title}
                  </h4>
                  <ChevronRight className="w-4 h-4 text-[#007aff] flex-shrink-0 group-hover:translate-x-0.5 transition-transform" strokeWidth={2.5} />
                </div>
                <div className="flex items-center gap-2 text-[12px] text-[#8e8e93]">
                  <span>{todo.linkedMemory.date}</span>
                  {todo.linkedMemory.duration && (
                    <>
                      <span>·</span>
                      <span>{todo.linkedMemory.duration}</span>
                    </>
                  )}
                  {todo.linkedMemory.hasSummary && (
                    <>
                      <span>·</span>
                      <span>Summary</span>
                    </>
                  )}
                </div>
              </button>
            </div>
          )}

          {/* Notes - 紧凑 */}
          {todo.notes && todo.notes.length > 0 && (
            <div className="mb-3">
              <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
                Notes
              </h3>
              <div className="space-y-1">
                {todo.notes.map((note, index) => (
                  <div key={index} className="flex items-start gap-2">
                    <span className="text-[14px] text-[#3c3c43]">• {note}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Divider - 细线 */}
          <div className="h-[1px] bg-black/[0.06] mb-4 mt-4" />

          {/* Actions - 紧凑按钮 */}
          <div className="space-y-2">
            {/* Restore task - 主动作 */}
            {onRestore && (
              <button
                onClick={() => {
                  onRestore(todo.id);
                  onClose();
                }}
                className="w-full bg-[#007aff] text-white rounded-[10px] py-3 font-semibold text-[15px] hover:bg-[#0051d5] transition-colors shadow-sm"
              >
                Restore task
              </button>
            )}

            {/* Delete - 最弱出口 */}
            {onDelete && (
              <button
                onClick={() => {
                  onDelete(todo.id);
                  onClose();
                }}
                className="w-full text-[#ff3b30] text-[14px] font-medium hover:opacity-70 transition-opacity py-1.5"
              >
                Delete
              </button>
            )}
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
  );
}
