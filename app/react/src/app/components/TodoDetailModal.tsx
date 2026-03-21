import { ChevronLeft, Check, MoreVertical, Calendar, Share2, ChevronDown, ChevronRight, Trash2 } from 'lucide-react';
import { useState, useEffect, useRef } from 'react';
import { format } from 'date-fns';
import { CustomCalendar } from './CustomCalendar';

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
  context?: string;
  linkedMemory?: LinkedMemory;
  time?: string;
  notes?: string;
  priority?: string;
  dueDate?: string;
}

interface TodoDetailModalProps {
  todo: Todo;
  onClose: () => void;
  onMarkDone?: (id: number) => void;
  onNotNow?: (id: number) => void;
  onDelete?: (id: number) => void;
  onMemoryClick?: (memoryId: string) => void;
  onLinkMemory?: (todoId: number) => void;
  onUpdate?: (id: number, updates: Partial<Todo>) => void;
}

export function TodoDetailModal({ todo, onClose, onMarkDone, onNotNow, onDelete, onMemoryClick, onLinkMemory, onUpdate }: TodoDetailModalProps) {
  const [showMenu, setShowMenu] = useState(false);
  const [showPriorityMenu, setShowPriorityMenu] = useState(false);
  const [showDueMenu, setShowDueMenu] = useState(false);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimeMenu, setShowTimeMenu] = useState(false);
  const [selectedPriority, setSelectedPriority] = useState(todo.priority || 'Normal');
  // Ensure empty strings and undefined are treated as "No deadline"
  const [selectedDue, setSelectedDue] = useState(() => {
    if (!todo.dueDate || todo.dueDate.trim() === '') return 'No deadline';
    return todo.dueDate;
  });
  // Only use todo's actual time value, don't auto-generate
  const [selectedTime, setSelectedTime] = useState(() => {
    return todo.time || '';
  });
  const [customDate, setCustomDate] = useState('');
  const [showSaved, setShowSaved] = useState(false);
  const [notes, setNotes] = useState(todo.notes || '');

  // Track initial values to detect changes properly - use refs to avoid recreating on every render
  const initialPriorityRef = useRef(todo.priority || 'Normal');
  const initialDueRef = useRef(() => {
    if (!todo.dueDate || todo.dueDate.trim() === '') return 'No deadline';
    return todo.dueDate;
  });
  const initialTimeRef = useRef(todo.time || '');

  // Sync state when todo prop changes (when opening a different todo)
  useEffect(() => {
    setSelectedPriority(todo.priority || 'Normal');
    
    // Ensure empty strings and undefined are treated as "No deadline"
    const newDue = (!todo.dueDate || todo.dueDate.trim() === '') ? 'No deadline' : todo.dueDate;
    setSelectedDue(newDue);
    
    // Only use todo's actual time value, don't auto-generate
    const newTime = todo.time || '';
    setSelectedTime(newTime);
    setNotes(todo.notes || '');
    
    // Parse and set hour and minute only if time exists
    if (newTime && newTime.includes(':')) {
      const parts = newTime.split(':');
      setSelectedHour(parseInt(parts[0], 10));
      setSelectedMinute(parseInt(parts[1], 10));
    } else {
      setSelectedHour(9);
      setSelectedMinute(0);
    }
    
    // Update initial refs
    initialPriorityRef.current = todo.priority || 'Normal';
    initialDueRef.current = newDue;
    initialTimeRef.current = newTime;
  }, [todo.id, todo.priority, todo.dueDate, todo.time, todo.notes]);

  // Auto-save when priority, due date, or time changes
  useEffect(() => {
    // Skip on initial mount - check if any value has actually changed from initial values
    const priorityChanged = selectedPriority !== initialPriorityRef.current;
    const dueChanged = selectedDue !== initialDueRef.current;
    const timeChanged = selectedTime !== initialTimeRef.current;
    
    if (!priorityChanged && !dueChanged && !timeChanged) {
      return;
    }

    // Save changes
    if (onUpdate) {
      const updates: any = {
        priority: selectedPriority,
        dueDate: selectedDue
      };
      
      // Only include time if due date is set, otherwise clear it
      if (selectedDue !== 'No deadline') {
        updates.time = selectedTime;
      } else {
        updates.time = undefined; // Clear time when no deadline is set
      }
      
      onUpdate(todo.id, updates);

      // Show saved indicator
      setShowSaved(true);
      const timer = setTimeout(() => {
        setShowSaved(false);
      }, 2000);

      return () => clearTimeout(timer);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedPriority, selectedDue, selectedTime]);

  const priorityOptions = ['High priority', 'Normal', 'Low priority'];
  const dueOptions = ['No deadline', 'Today', 'Tomorrow', 'Pick a date'];
  
  // Parse selected time into hours and minutes
  const [selectedHour, setSelectedHour] = useState(() => {
    if (!selectedTime || !selectedTime.includes(':')) return 9;
    const parts = selectedTime.split(':');
    return parseInt(parts[0], 10) || 9;
  });
  const [selectedMinute, setSelectedMinute] = useState(() => {
    if (!selectedTime || !selectedTime.includes(':')) return 0;
    const parts = selectedTime.split(':');
    return parseInt(parts[1], 10) || 0;
  });

  // Refs for scroll containers
  const hourScrollRef = useRef<HTMLDivElement>(null);
  const minuteScrollRef = useRef<HTMLDivElement>(null);

  // Update selectedTime when hour or minute changes, but only if there's a deadline
  useEffect(() => {
    if (selectedDue !== 'No deadline') {
      const newTime = `${selectedHour.toString().padStart(2, '0')}:${selectedMinute.toString().padStart(2, '0')}`;
      setSelectedTime(newTime);
    }
  }, [selectedHour, selectedMinute, selectedDue]);

  const handlePrioritySelect = (priority: string) => {
    setSelectedPriority(priority);
    setShowPriorityMenu(false);
  };

  const handleDueSelect = (due: string) => {
    if (due === 'Pick a date') {
      setShowDatePicker(true);
      setShowDueMenu(false);
    } else {
      setSelectedDue(due);
      setShowDueMenu(false);
      // If selecting "No deadline", clear the time
      if (due === 'No deadline') {
        setSelectedTime('');
      } else if (!selectedTime) {
        // If selecting a deadline and no time is set, set default time
        setSelectedTime('09:00');
        setSelectedHour(9);
        setSelectedMinute(0);
      }
    }
  };
  
  const handleHourSelect = (hour: number) => {
    setSelectedHour(hour);
  };

  const handleMinuteSelect = (minute: number) => {
    setSelectedMinute(minute);
  };

  // Scroll to selected time when picker opens
  useEffect(() => {
    if (showTimeMenu && hourScrollRef.current && minuteScrollRef.current) {
      const itemHeight = 40; // Height of each time item
      hourScrollRef.current.scrollTop = selectedHour * itemHeight;
      minuteScrollRef.current.scrollTop = selectedMinute * itemHeight;
    }
  }, [showTimeMenu, selectedHour, selectedMinute]);
  
  // Check if time picker should be shown
  const shouldShowTimePicker = selectedDue !== 'No deadline';

  const handleDateSelect = (date: Date) => {
    const formattedDate = format(date, 'MMM d, yyyy');
    setSelectedDue(formattedDate);
    setShowDatePicker(false);
    // Set default time if not already set
    if (!selectedTime) {
      setSelectedTime('09:00');
      setSelectedHour(9);
      setSelectedMinute(0);
    }
  };

  const handleExportToCalendar = () => {
    console.log('Export to calendar');
    setShowMenu(false);
    // 这里可以添加导出到日历的逻辑
  };

  const handleShareTask = () => {
    console.log('Share task');
    setShowMenu(false);
    // 这里可以添加分享任务的逻辑
  };

  // Auto-save notes with debounce
  const notesTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const handleNotesChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newNotes = e.target.value;
    setNotes(newNotes);
    
    // Clear previous timeout
    if (notesTimeoutRef.current) {
      clearTimeout(notesTimeoutRef.current);
    }
    
    // Set new timeout to save after 1 second of no typing
    notesTimeoutRef.current = setTimeout(() => {
      if (onUpdate) {
        onUpdate(todo.id, { notes: newNotes || undefined });
        // Show saved indicator
        setShowSaved(true);
        const timer = setTimeout(() => {
          setShowSaved(false);
        }, 2000);
      }
    }, 1000);
  };

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
        <div className="px-4 pt-3 pb-2 border-b border-black/[0.06] flex items-center justify-between relative">
          <button 
            onClick={onClose}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
          </button>
          
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 -translate-x-1/2">
            Todo
          </h1>
          
          {/* Saved indicator */}
          <div className="absolute left-1/2 -translate-x-1/2 flex items-center gap-1.5 pointer-events-none">
            {showSaved && (
              <div className="flex items-center gap-1.5 text-[#34c759] animate-fade-in mt-8">
                <Check className="w-4 h-4" strokeWidth={2.5} />
                <span className="text-[15px] font-medium">Saved</span>
              </div>
            )}
          </div>
          
          {/* Three dots menu button */}
          <div className="relative">
            <button
              onClick={() => setShowMenu(!showMenu)}
              className="p-2 hover:bg-[#f2f2f7] rounded-full transition-colors"
            >
              <MoreVertical className="w-5 h-5 text-[#3c3c43]" strokeWidth={2.5} />
            </button>
            
            {/* Dropdown menu */}
            {showMenu && (
              <div className="absolute right-0 top-full mt-2 bg-white rounded-[12px] shadow-lg z-20 min-w-[200px] overflow-hidden border border-black/[0.06]">
                <button
                  onClick={handleExportToCalendar}
                  className="w-full text-left px-4 py-3 text-[15px] font-medium hover:bg-[#f2f2f7] transition-colors flex items-center gap-3"
                >
                  <Calendar className="w-5 h-5 text-[#3c3c43]" strokeWidth={2} />
                  <span className="text-[#3c3c43]">Export to calendar</span>
                </button>
                <div className="h-[1px] bg-black/[0.06]" />
                <button
                  onClick={handleShareTask}
                  className="w-full text-left px-4 py-3 text-[15px] font-medium hover:bg-[#f2f2f7] transition-colors flex items-center gap-3"
                >
                  <Share2 className="w-5 h-5 text-[#3c3c43]" strokeWidth={2} />
                  <span className="text-[#3c3c43]">Share task</span>
                </button>
                {onDelete && (
                  <>
                    <div className="h-[1px] bg-black/[0.06]" />
                    <button
                      onClick={() => {
                        onDelete(todo.id);
                        onClose();
                      }}
                      className="w-full text-left px-4 py-3 text-[15px] font-medium hover:bg-[#f2f2f7] transition-colors flex items-center gap-3"
                    >
                      <Trash2 className="w-5 h-5 text-[#ff3b30]" strokeWidth={2} />
                      <span className="text-[#ff3b30]">Delete</span>
                    </button>
                  </>
                )}
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

          {/* Notes - Editable textarea, always visible */}
          <div className="mb-3">
            <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
              Notes
            </h3>
            <textarea
              value={notes}
              onChange={handleNotesChange}
              placeholder="Add notes..."
              className="w-full bg-[#f2f2f7] text-[#3c3c43] rounded-[10px] py-2.5 px-3 text-[14px] hover:bg-[#e5e5ea] focus:bg-[#e5e5ea] transition-colors resize-none min-h-[80px] focus:outline-none focus:ring-2 focus:ring-[#007aff]/20"
            />
          </div>

          {/* Priority, When & Time - Horizontal Layout */}
          <div className={`grid ${shouldShowTimePicker ? 'grid-cols-3' : 'grid-cols-2'} gap-2 mb-4`}>
            {/* Priority */}
            <div>
              <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
                Priority
              </h3>
              <div className="relative">
                <button
                  onClick={() => setShowPriorityMenu(!showPriorityMenu)}
                  className="w-full bg-[#f2f2f7] text-[#3c3c43] rounded-[10px] py-2 px-2 font-medium text-[13px] hover:bg-[#e5e5ea] transition-colors flex items-center justify-between"
                >
                  <span className="truncate">{selectedPriority}</span>
                  <ChevronDown className="w-3.5 h-3.5 flex-shrink-0 ml-1" strokeWidth={2.5} />
                </button>
                {showPriorityMenu && (
                  <div className="absolute left-0 right-0 top-full mt-1 bg-white rounded-[10px] shadow-lg z-50 border border-black/[0.06] overflow-hidden">
                    {priorityOptions.map((option) => (
                      <button
                        key={option}
                        onClick={() => handlePrioritySelect(option)}
                        className="w-full text-left px-2.5 py-2 text-[13px] font-medium hover:bg-[#f2f2f7] transition-colors"
                      >
                        {option}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* When */}
            <div>
              <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
                When
              </h3>
              <div className="relative">
                <button
                  onClick={() => setShowDueMenu(!showDueMenu)}
                  className="w-full bg-[#f2f2f7] text-[#3c3c43] rounded-[10px] py-2 px-2 font-medium text-[13px] hover:bg-[#e5e5ea] transition-colors flex items-center justify-between"
                >
                  <span className="truncate">{selectedDue}</span>
                  <ChevronDown className="w-3.5 h-3.5 flex-shrink-0 ml-1" strokeWidth={2.5} />
                </button>
                {showDueMenu && (
                  <div className="absolute left-0 right-0 top-full mt-1 bg-white rounded-[10px] shadow-lg z-50 border border-black/[0.06] overflow-hidden">
                    {dueOptions.map((option) => (
                      <button
                        key={option}
                        onClick={() => handleDueSelect(option)}
                        className="w-full text-left px-2.5 py-2 text-[13px] font-medium hover:bg-[#f2f2f7] transition-colors"
                      >
                        {option}
                      </button>
                    ))}
                  </div>
                )}
                {showDatePicker && (
                  <CustomCalendar
                    selectedDate={customDate ? new Date(customDate) : undefined}
                    onSelectDate={handleDateSelect}
                    onClose={() => setShowDatePicker(false)}
                  />
                )}
              </div>
            </div>

            {/* Time - Only show when due date is set */}
            {shouldShowTimePicker && (
              <div>
                <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-2">
                  Time
                </h3>
                <div className="relative">
                  <button
                    onClick={() => setShowTimeMenu(!showTimeMenu)}
                    className="w-full bg-[#f2f2f7] text-[#3c3c43] rounded-[10px] py-2 px-2 font-medium text-[13px] hover:bg-[#e5e5ea] transition-colors flex items-center justify-between"
                  >
                    <span className="truncate">{selectedTime}</span>
                    <ChevronDown className="w-3.5 h-3.5 flex-shrink-0 ml-1" strokeWidth={2.5} />
                  </button>
                  {showTimeMenu && (
                    <>
                      {/* Backdrop for time picker - transparent to see the time behind */}
                      <div 
                        className="fixed inset-0 bg-transparent z-[100]"
                        onClick={() => {
                          // Auto-save when clicking outside
                          setShowTimeMenu(false);
                        }}
                      />
                      
                      {/* Time picker modal - centered */}
                      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[90%] max-w-[340px] bg-white rounded-[16px] shadow-2xl z-[101] border border-black/[0.06] overflow-hidden">
                      
                      {/* iOS-style dual wheel picker */}
                      <div className="flex items-center justify-center gap-2 py-4 px-4">
                        {/* Hour Wheel */}
                        <div className="flex-1 relative">
                          <div className="text-center text-[11px] text-[#8e8e93] font-semibold mb-2 uppercase tracking-wide">Hour</div>
                          {/* Selection highlight - behind content */}
                          <div className="absolute left-0 right-0 h-[40px] bg-[#f2f2f7] rounded-[8px] pointer-events-none" style={{ top: '84px' }} />
                          {/* Scrollable list */}
                          <div 
                            ref={hourScrollRef}
                            className="h-[160px] overflow-y-scroll scrollbar-hide relative z-10"
                            onScroll={(e) => {
                              const scrollTop = e.currentTarget.scrollTop;
                              const itemHeight = 40;
                              const index = Math.round(scrollTop / itemHeight);
                              handleHourSelect(index);
                            }}
                          >
                            <div className="py-[60px]">
                              {Array.from({ length: 24 }, (_, i) => (
                                <button
                                  key={i}
                                  onClick={() => {
                                    handleHourSelect(i);
                                    if (hourScrollRef.current) {
                                      hourScrollRef.current.scrollTop = i * 40;
                                    }
                                  }}
                                  className="w-full h-[40px] flex items-center justify-center text-[17px] font-medium transition-all relative z-20"
                                  style={{
                                    color: i === selectedHour ? '#1c1c1e' : '#8e8e93',
                                    opacity: i === selectedHour ? 1 : 0.5,
                                    fontWeight: i === selectedHour ? 600 : 500,
                                  }}
                                >
                                  {i.toString().padStart(2, '0')}
                                </button>
                              ))}
                            </div>
                          </div>
                          {/* Gradient overlays - in front but with reduced opacity in center */}
                          <div className="absolute left-0 right-0 top-0 h-[50px] pointer-events-none z-30" style={{ marginTop: '24px', background: 'linear-gradient(to bottom, rgba(255,255,255,1) 0%, rgba(255,255,255,0.8) 50%, rgba(255,255,255,0) 100%)' }} />
                          <div className="absolute left-0 right-0 bottom-0 h-[50px] pointer-events-none z-30" style={{ background: 'linear-gradient(to top, rgba(255,255,255,1) 0%, rgba(255,255,255,0.8) 50%, rgba(255,255,255,0) 100%)' }} />
                        </div>

                        {/* Colon separator */}
                        <div className="text-[20px] font-semibold text-[#3c3c43] pb-1" style={{ marginTop: '24px' }}>:</div>

                        {/* Minute Wheel */}
                        <div className="flex-1 relative">
                          <div className="text-center text-[11px] text-[#8e8e93] font-semibold mb-2 uppercase tracking-wide">Min</div>
                          {/* Selection highlight - behind content */}
                          <div className="absolute left-0 right-0 h-[40px] bg-[#f2f2f7] rounded-[8px] pointer-events-none" style={{ top: '84px' }} />
                          {/* Scrollable list */}
                          <div 
                            ref={minuteScrollRef}
                            className="h-[160px] overflow-y-scroll scrollbar-hide relative z-10"
                            onScroll={(e) => {
                              const scrollTop = e.currentTarget.scrollTop;
                              const itemHeight = 40;
                              const index = Math.round(scrollTop / itemHeight);
                              handleMinuteSelect(index);
                            }}
                          >
                            <div className="py-[60px]">
                              {Array.from({ length: 60 }, (_, i) => (
                                <button
                                  key={i}
                                  onClick={() => {
                                    handleMinuteSelect(i);
                                    if (minuteScrollRef.current) {
                                      minuteScrollRef.current.scrollTop = i * 40;
                                    }
                                  }}
                                  className="w-full h-[40px] flex items-center justify-center text-[17px] font-medium transition-all relative z-20"
                                  style={{
                                    color: i === selectedMinute ? '#1c1c1e' : '#8e8e93',
                                    opacity: i === selectedMinute ? 1 : 0.5,
                                    fontWeight: i === selectedMinute ? 600 : 500,
                                  }}
                                >
                                  {i.toString().padStart(2, '0')}
                                </button>
                              ))}
                            </div>
                          </div>
                          {/* Gradient overlays - in front but with reduced opacity in center */}
                          <div className="absolute left-0 right-0 top-0 h-[50px] pointer-events-none z-30" style={{ marginTop: '24px', background: 'linear-gradient(to bottom, rgba(255,255,255,1) 0%, rgba(255,255,255,0.8) 50%, rgba(255,255,255,0) 100%)' }} />
                          <div className="absolute left-0 right-0 bottom-0 h-[50px] pointer-events-none z-30" style={{ background: 'linear-gradient(to top, rgba(255,255,255,1) 0%, rgba(255,255,255,0.8) 50%, rgba(255,255,255,0) 100%)' }} />
                        </div>
                      </div>
                    </div>
                    </>
                  )}
                </div>
              </div>
            )}
          </div>

          {/* Divider - 细线 */}
          <div className="h-[1px] bg-black/[0.06] mb-4" />

          {/* Actions - 紧凑按钮 */}
          <div className="space-y-2">
            {/* Mark as done - 主动作 */}
            {onMarkDone && (
              <button
                onClick={() => {
                  onMarkDone(todo.id);
                  onClose();
                }}
                className="w-full bg-[#2d5a47] text-white rounded-[10px] py-3 font-semibold text-[15px] hover:bg-[#234537] transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                <Check className="w-4 h-4" strokeWidth={2.5} />
                Mark as done
              </button>
            )}

            {/* Not now - 情绪友好失败出口 */}
            {onNotNow && (
              <button
                onClick={() => {
                  onNotNow(todo.id);
                  onClose();
                }}
                className="w-full bg-[#f2f2f7] text-[#3c3c43] rounded-[10px] py-3 font-medium text-[15px] hover:bg-[#e5e5ea] transition-colors"
              >
                Not now
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

        @keyframes fade-in {
          from {
            opacity: 0;
          }
          to {
            opacity: 1;
          }
        }
        .animate-fade-in {
          animation: fade-in 0.3s ease-out;
        }

        /* Hide scrollbar for iOS-style picker */
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }

        /* Smooth scrolling for picker */
        .scrollbar-hide {
          scroll-behavior: smooth;
        }
      `}</style>
    </div>
  );
}