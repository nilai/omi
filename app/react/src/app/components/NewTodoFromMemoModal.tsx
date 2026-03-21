import { ChevronLeft, X, ChevronDown, ChevronRight } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';

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

interface NewTodoFromMemoModalProps {
  todo?: Todo;
  isOpen?: boolean;
  onClose: () => void;
  onSave?: (todo: Todo) => void;
  onSaveTodo?: (todo: any) => void;
  onMemoryClick?: (memoryId: string) => void;
  action?: { id: number; text: string };
  memory?: { id: string; title: string; date?: string; duration?: string; hasSummary?: boolean };
  suggestion?: string;
  insightContent?: string;
  onCreateTodo?: (newTodo: any) => void;
}

export function NewTodoFromMemoModal({ todo, isOpen, onClose, onSave, onSaveTodo, onMemoryClick, action, memory, suggestion, insightContent, onCreateTodo }: NewTodoFromMemoModalProps) {
  // Function to detect if text contains time information
  const hasTimeInfo = (text: string): boolean => {
    if (!text) return false;
    const lowerText = text.toLowerCase();
    // Check for explicit time keywords
    const timeKeywords = [
      'today', 'tomorrow', 'tonight', 'morning', 'afternoon', 'evening',
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
      'this week', 'next week', 'this month', 'next month',
      'am', 'pm', 'o\'clock', 'oclock',
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    
    // Check for time patterns like "3pm", "15:00", "at 3"
    const timePatterns = [
      /\d{1,2}:\d{2}/, // 14:30, 3:45
      /\d{1,2}\s*(am|pm)/, // 3pm, 3 pm
      /at\s+\d{1,2}/, // at 3
      /\d{1,2}\/\d{1,2}/, // 3/5, 03/05
      /\d{1,2}-\d{1,2}/ // 3-5, 03-05
    ];
    
    // Check for keywords
    for (const keyword of timeKeywords) {
      if (lowerText.includes(keyword)) return true;
    }
    
    // Check for patterns
    for (const pattern of timePatterns) {
      if (pattern.test(lowerText)) return true;
    }
    
    return false;
  };

  // If action is provided (from Memory), create a todo from it
  // If suggestion is provided (from Expert Insight), use it as the title
  const todoTitle = suggestion || action?.text || '';
  const shouldHaveDeadline = hasTimeInfo(todoTitle);

  const initialTodo: Todo = todo || {
    id: Date.now(),
    title: todoTitle,
    completed: false,
    category: 'Today',
    notes: [],
    priority: 'Normal',
    dueDate: shouldHaveDeadline ? 'Today' : 'No deadline',
    time: shouldHaveDeadline ? undefined : undefined,
    linkedMemory: memory ? {
      id: memory.id,
      title: memory.title,
      date: memory.date || 'Recently',
      duration: memory.duration,
      hasSummary: memory.hasSummary
    } : undefined
  };

  const titleTextareaRef = useRef<HTMLTextAreaElement>(null);
  const [editedTodo, setEditedTodo] = useState(initialTodo);
  const [showPriorityMenu, setShowPriorityMenu] = useState(false);
  const [showDueDateMenu, setShowDueDateMenu] = useState(false);
  const [showTimeMenu, setShowTimeMenu] = useState(false);
  const [editingNotes, setEditingNotes] = useState(insightContent || initialTodo.notes?.[0] || '');

  // Auto-resize textarea on mount and when title changes
  useEffect(() => {
    if (titleTextareaRef.current) {
      titleTextareaRef.current.style.height = 'auto';
      titleTextareaRef.current.style.height = titleTextareaRef.current.scrollHeight + 'px';
    }
  }, [editedTodo.title]);

  const priorityOptions = ['High priority', 'Normal', 'Low priority'];
  const dueDateOptions = ['Today', 'Tomorrow', 'This week', 'No deadline'];
  
  // Generate time options in 24-hour format (every 30 minutes)
  const timeOptions = [];
  for (let hour = 0; hour < 24; hour++) {
    for (let minute of [0, 30]) {
      const timeString = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
      timeOptions.push(timeString);
    }
  }
  
  // Check if time picker should be shown
  const shouldShowTimePicker = editedTodo.dueDate !== 'No deadline';

  const handleSave = () => {
    // Update the notes with edited content
    const updatedTodo: any = {
      ...editedTodo,
      notes: editingNotes.trim() ? [editingNotes] : []
    };
    
    // Only include time if due date is set
    if (editedTodo.dueDate === 'No deadline') {
      delete updatedTodo.time;
    }
    
    onSave?.(updatedTodo);
    onSaveTodo?.(updatedTodo);
    onCreateTodo?.(updatedTodo);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal */}
      <div 
        className="relative w-full max-w-md bg-white rounded-t-[24px] shadow-2xl animate-slide-up max-h-[85vh] flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-4 pt-3 pb-2 border-b border-black/[0.06] flex items-center justify-between flex-shrink-0">
          <button 
            onClick={onClose}
            className="flex items-center gap-2 text-[#007aff] text-[17px] font-medium hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
            <span>New Todo</span>
          </button>
          
          <button
            onClick={onClose}
            className="p-2 hover:bg-[#f2f2f7] rounded-full transition-colors"
          >
            <X className="w-5 h-5 text-[#3c3c43]" strokeWidth={2.5} />
          </button>
        </div>

        {/* Content - Scrollable */}
        <div className="flex-1 overflow-y-auto px-4 pt-4 pb-4">
          {/* Title - Editable */}
          <textarea
            ref={titleTextareaRef}
            value={editedTodo.title}
            onChange={(e) => setEditedTodo({ ...editedTodo, title: e.target.value })}
            className="w-full text-[20px] text-[#1c1c1e] font-semibold leading-[1.3] mb-5 border-none outline-none bg-transparent placeholder:text-[#c7c7cc] resize-none min-h-[28px]"
            placeholder="Todo title..."
            rows={1}
            onInput={(e) => {
              const target = e.target as HTMLTextAreaElement;
              target.style.height = 'auto';
              target.style.height = target.scrollHeight + 'px';
            }}
          />

          {/* Context */}
          {editedTodo.linkedMemory && (
            <div className="mb-4">
              <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
                Context
              </h3>
              <button
                onClick={() => onMemoryClick?.(editedTodo.linkedMemory!.id)}
                className="w-full bg-[#f9f9f9] rounded-[10px] p-3 text-left hover:bg-[#f2f2f7] transition-all border border-black/[0.06] group"
              >
                <p className="text-[11px] text-[#8e8e93] mb-1.5">From memory:</p>
                <div className="flex items-start justify-between gap-3">
                  <h4 className="text-[14px] font-medium text-[#1c1c1e] flex-1">
                    {editedTodo.linkedMemory.title}
                  </h4>
                  <ChevronRight className="w-4 h-4 text-[#007aff] flex-shrink-0 group-hover:translate-x-0.5 transition-transform" strokeWidth={2.5} />
                </div>
                {editedTodo.linkedMemory.date && (
                  <div className="flex items-center gap-2 text-[12px] text-[#8e8e93] mt-1">
                    <span>{editedTodo.linkedMemory.date}</span>
                    {editedTodo.linkedMemory.duration && (
                      <>
                        <span>·</span>
                        <span>{editedTodo.linkedMemory.duration}</span>
                      </>
                    )}
                    {editedTodo.linkedMemory.hasSummary && (
                      <>
                        <span>·</span>
                        <span>Summary</span>
                      </>
                    )}
                  </div>
                )}
              </button>
            </div>
          )}

          {/* Notes - Editable textarea */}
          <div className="mb-4">
            <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
              Notes
            </h3>
            <textarea
              value={editingNotes}
              onChange={(e) => setEditingNotes(e.target.value)}
              placeholder="Add notes..."
              rows={4}
              className="w-full bg-[#f9f9f9] rounded-[10px] p-3 text-[14px] text-[#3c3c43] leading-[1.5] border border-black/[0.06] outline-none focus:border-[#007aff] focus:bg-white transition-all resize-none placeholder:text-[#c7c7cc]"
            />
          </div>

          {/* Priority */}
          <div className="mb-4">
            <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
              Priority
            </h3>
            <div className="relative">
              <button
                onClick={() => setShowPriorityMenu(!showPriorityMenu)}
                className="w-full bg-[#f9f9f9] rounded-[10px] p-3 text-left hover:bg-[#f2f2f7] transition-all border border-black/[0.06] flex items-center justify-between"
              >
                <span className="text-[14px] text-[#3c3c43]">{editedTodo.priority || 'Normal'}</span>
                <ChevronDown className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
              </button>
              
              {showPriorityMenu && (
                <div className="absolute top-full left-0 right-0 mt-2 bg-white rounded-[12px] shadow-lg z-20 overflow-hidden border border-black/[0.06]">
                  {priorityOptions.map((option) => (
                    <button
                      key={option}
                      onClick={() => {
                        setEditedTodo({ ...editedTodo, priority: option });
                        setShowPriorityMenu(false);
                      }}
                      className={`w-full px-4 py-3 text-left text-[14px] hover:bg-[#f2f2f7] transition-colors ${
                        editedTodo.priority === option ? 'text-[#007aff] font-medium' : 'text-[#3c3c43]'
                      }`}
                    >
                      {option}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* When */}
          <div className="mb-4">
            <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
              WHEN
            </h3>
            <div className="relative">
              <button
                onClick={() => setShowDueDateMenu(!showDueDateMenu)}
                className="w-full bg-[#f9f9f9] rounded-[10px] p-3 text-left hover:bg-[#f2f2f7] transition-all border border-black/[0.06] flex items-center justify-between"
              >
                <span className="text-[14px] text-[#3c3c43]">{editedTodo.dueDate || 'No deadline'}</span>
                <ChevronDown className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
              </button>
              
              {showDueDateMenu && (
                <div className="absolute top-full left-0 right-0 mt-2 bg-white rounded-[12px] shadow-lg z-20 overflow-hidden border border-black/[0.06]">
                  {dueDateOptions.map((option) => (
                    <button
                      key={option}
                      onClick={() => {
                        setEditedTodo({ ...editedTodo, dueDate: option });
                        setShowDueDateMenu(false);
                      }}
                      className={`w-full px-4 py-3 text-left text-[14px] hover:bg-[#f2f2f7] transition-colors ${
                        editedTodo.dueDate === option ? 'text-[#007aff] font-medium' : 'text-[#3c3c43]'
                      }`}
                    >
                      {option}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Time - Only show when due date is set */}
          {shouldShowTimePicker && (
            <div className="mb-4">
              <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
                Time
              </h3>
              <div className="relative">
                <button
                  onClick={() => setShowTimeMenu(!showTimeMenu)}
                  className="w-full bg-[#f9f9f9] rounded-[10px] p-3 text-left hover:bg-[#f2f2f7] transition-all border border-black/[0.06] flex items-center justify-between"
                >
                  <span className="text-[14px] text-[#3c3c43]">{editedTodo.time || '09:00'}</span>
                  <ChevronDown className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                </button>
                
                {showTimeMenu && (
                  <div className="absolute top-full left-0 right-0 mt-2 bg-white rounded-[12px] shadow-lg z-20 overflow-hidden border border-black/[0.06] max-h-[200px] overflow-y-auto">
                    {timeOptions.map((option) => (
                      <button
                        key={option}
                        onClick={() => {
                          setEditedTodo({ ...editedTodo, time: option });
                          setShowTimeMenu(false);
                        }}
                        className={`w-full px-4 py-3 text-left text-[14px] hover:bg-[#f2f2f7] transition-colors ${
                          editedTodo.time === option ? 'text-[#007aff] font-medium' : 'text-[#3c3c43]'
                        }`}
                      >
                        {option}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Divider */}
          <div className="h-[1px] bg-black/[0.06] my-5" />
        </div>

        {/* Footer - Save Button */}
        <div className="px-4 pb-4 flex-shrink-0">
          <button
            onClick={handleSave}
            className="w-full bg-[#007aff] text-white rounded-[12px] py-3.5 font-semibold text-[16px] hover:bg-[#0051d5] transition-colors shadow-sm active:scale-[0.98]"
          >
            Save Todo
          </button>
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