import { ChevronLeft, Check, MoreVertical, Calendar, Share2, ChevronDown } from 'lucide-react';
import { useState } from 'react';
import { format } from 'date-fns';
import { CustomCalendar } from './CustomCalendar';

interface Todo {
  id: number;
  title: string;
  context?: string;
  time?: string;
  notes?: string[];
  priority?: string;
  dueDate?: string;
  completed?: boolean;
}

interface TodoDetailPageProps {
  todo: Todo;
  onBack: () => void;
  onToggle?: (id: number) => void;
  onDelete?: (id: number) => void;
  onMarkDone?: (id: number) => void;
  onNotNow?: (id: number) => void;
}

export function TodoDetailPage({ todo, onBack, onToggle, onDelete, onMarkDone, onNotNow }: TodoDetailPageProps) {
  const [showMenu, setShowMenu] = useState(false);
  const [showPriorityMenu, setShowPriorityMenu] = useState(false);
  const [showDueMenu, setShowDueMenu] = useState(false);
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [selectedPriority, setSelectedPriority] = useState(todo.priority || 'Normal');
  const [selectedDue, setSelectedDue] = useState(todo.dueDate || 'No deadline');
  const [customDate, setCustomDate] = useState('');

  const priorityOptions = ['High priority', 'Normal', 'Low priority'];
  const dueOptions = ['No deadline', 'Today', 'Tomorrow', 'Pick a date'];

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
    }
  };

  const handleDateSelect = (date: Date) => {
    const formattedDate = format(date, 'MMM d, yyyy');
    setSelectedDue(formattedDate);
    setShowDatePicker(false);
  };

  const handleExportToCalendar = () => {
    console.log('Export to calendar');
    setShowMenu(false);
    // Export to calendar logic can be added here
  };

  const handleShareTask = () => {
    console.log('Share task');
    setShowMenu(false);
    // Share task logic can be added here
  };

  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
        <button 
          onClick={onBack}
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
            </div>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto px-5 pt-6 pb-8">
        {/* Core content */}
        <h2 className="text-[20px] text-[#1c1c1e] font-semibold leading-[1.4] mb-8">
          {todo.title}
        </h2>

        {/* Context */}
        {(todo.context || todo.time) && (
          <div className="mb-6">
            <h3 className="text-[13px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-3">
              Context
            </h3>
            <div className="space-y-2">
              {todo.context && (
                <div className="flex items-start gap-2">
                  <span className="text-[15px] text-[#3c3c43]">• From: {todo.context}</span>
                </div>
              )}
              {todo.time && (
                <div className="flex items-start gap-2">
                  <span className="text-[15px] text-[#3c3c43]">• Time: {todo.time}</span>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Notes */}
        {todo.notes && todo.notes.length > 0 && (
          <div className="mb-6">
            <h3 className="text-[13px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-3">
              Notes
            </h3>
            <div className="space-y-2">
              {todo.notes.map((note, index) => (
                <div key={index} className="flex items-start gap-2">
                  <span className="text-[15px] text-[#3c3c43]">- {note}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Priority */}
        <div className="mb-6">
          <h3 className="text-[13px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-3">
            Priority
          </h3>
          <div className="relative">
            <button
              onClick={() => setShowPriorityMenu(!showPriorityMenu)}
              className="w-full bg-white text-[#3c3c43] rounded-[12px] px-4 py-3.5 font-medium text-[16px] hover:bg-[#f8f8f9] transition-colors flex items-center justify-between shadow-[0_1px_3px_rgba(0,0,0,0.04)]"
            >
              {selectedPriority}
              <ChevronDown className="w-5 h-5" strokeWidth={2.5} />
            </button>
            {showPriorityMenu && (
              <div className="absolute left-0 right-0 top-full mt-1 bg-white rounded-[12px] shadow-lg z-10 overflow-hidden border border-black/[0.06]">
                {priorityOptions.map((option) => (
                  <button
                    key={option}
                    onClick={() => handlePrioritySelect(option)}
                    className="w-full text-left px-4 py-3.5 text-[15px] font-medium hover:bg-[#f2f2f7] transition-colors"
                  >
                    {option}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* When */}
        <div className="mb-8">
          <h3 className="text-[13px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-3">
            When (optional)
          </h3>
          <div className="relative">
            <button
              onClick={() => setShowDueMenu(!showDueMenu)}
              className="w-full bg-white text-[#3c3c43] rounded-[12px] px-4 py-3.5 font-medium text-[16px] hover:bg-[#f8f8f9] transition-colors flex items-center justify-between shadow-[0_1px_3px_rgba(0,0,0,0.04)]"
            >
              {selectedDue}
              <ChevronDown className="w-5 h-5" strokeWidth={2.5} />
            </button>
            {showDueMenu && (
              <div className="absolute left-0 right-0 top-full mt-1 bg-white rounded-[12px] shadow-lg z-10 overflow-hidden border border-black/[0.06]">
                {dueOptions.map((option) => (
                  <button
                    key={option}
                    onClick={() => handleDueSelect(option)}
                    className="w-full text-left px-4 py-3.5 text-[15px] font-medium hover:bg-[#f2f2f7] transition-colors"
                  >
                    {option}
                  </button>
                ))}
              </div>
            )}
          </div>
          {showDatePicker && (
            <CustomCalendar
              selectedDate={customDate ? new Date(customDate) : undefined}
              onSelectDate={handleDateSelect}
              onClose={() => setShowDatePicker(false)}
            />
          )}
        </div>

        {/* Divider */}
        <div className="h-[1px] bg-black/[0.06] mb-8" />

        {/* Actions */}
        <div className="space-y-3">
          {/* Mark as done - 主动作 */}
          <button
            onClick={() => {
              if (onMarkDone) {
                onMarkDone(todo.id);
              } else if (onToggle) {
                onToggle(todo.id);
              }
              onBack();
            }}
            className="w-full bg-[#2d5a47] text-white rounded-[12px] py-3.5 font-semibold text-[16px] hover:bg-[#234537] transition-colors flex items-center justify-center gap-2 shadow-sm"
          >
            <Check className="w-5 h-5" strokeWidth={2.5} />
            Mark as done
          </button>

          {/* Not now - 情绪友好失败出口 */}
          {onNotNow && (
            <button
              onClick={() => {
                onNotNow(todo.id);
                onBack();
              }}
              className="w-full bg-[#f2f2f7] text-[#3c3c43] rounded-[12px] py-3.5 font-medium text-[16px] hover:bg-[#e5e5ea] transition-colors"
            >
              Not now
            </button>
          )}

          {/* Delete - 最弱出口 */}
          {onDelete && (
            <button
              onClick={() => {
                onDelete(todo.id);
                onBack();
              }}
              className="w-full text-[#ff3b30] text-[15px] font-medium hover:opacity-70 transition-opacity py-2"
            >
              Delete
            </button>
          )}
        </div>
      </div>
    </div>
  );
}