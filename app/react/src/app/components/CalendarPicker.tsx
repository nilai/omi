import { X } from 'lucide-react';
import { useState } from 'react';

interface CalendarPickerProps {
  onClose: () => void;
  onSelectDate: (date: Date) => void;
}

export function CalendarPicker({ onClose, onSelectDate }: CalendarPickerProps) {
  const [currentMonth, setCurrentMonth] = useState(new Date(2026, 0)); // January 2026
  const today = new Date(2026, 0, 25); // Today is Jan 25, 2026

  // Days with memories (based on sample data)
  const daysWithMemories = [7, 8, 10, 11, 12, 13, 18, 19, 20, 21];

  const getDaysInMonth = (date: Date) => {
    const year = date.getFullYear();
    const month = date.getMonth();
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    
    return { firstDay, daysInMonth };
  };

  const { firstDay, daysInMonth } = getDaysInMonth(currentMonth);
  const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  const handleDayClick = (day: number) => {
    const selectedDate = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), day);
    onSelectDate(selectedDate);
    onClose();
  };

  const handleBackToToday = () => {
    onSelectDate(today);
    onClose();
  };

  const renderCalendarDays = () => {
    const days = [];
    
    // Empty cells for days before the first day of month
    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="h-11" />);
    }
    
    // Days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const isToday = day === today.getDate() && 
                      currentMonth.getMonth() === today.getMonth() &&
                      currentMonth.getFullYear() === today.getFullYear();
      const hasMemory = daysWithMemories.includes(day);
      
      days.push(
        <button
          key={day}
          onClick={() => handleDayClick(day)}
          className={`h-11 flex flex-col items-center justify-center rounded-[10px] transition-colors ${
            isToday 
              ? 'bg-[#007aff] text-white font-semibold' 
              : hasMemory
              ? 'bg-[#007aff]/10 text-[#1c1c1e] hover:bg-[#007aff]/20'
              : 'text-[#1c1c1e] hover:bg-[#f2f2f7]'
          }`}
        >
          <span className="text-[17px]">{day}</span>
          {hasMemory && !isToday && (
            <div className="w-1 h-1 rounded-full bg-[#007aff] mt-0.5" />
          )}
        </button>
      );
    }
    
    return days;
  };

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-[20px] w-full max-w-[340px] shadow-2xl">
        {/* Header */}
        <div className="px-5 pt-5 pb-3 flex items-center justify-between">
          <h2 className="text-[22px] font-bold">
            {monthNames[currentMonth.getMonth()]} {currentMonth.getFullYear()}
          </h2>
          <button 
            onClick={onClose}
            className="w-7 h-7 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
          >
            <X className="w-5 h-5" strokeWidth={2.5} />
          </button>
        </div>

        <div className="px-5 pb-5">
          {/* Day names header */}
          <div className="grid grid-cols-7 gap-1.5 mb-2">
            {dayNames.map((day, index) => (
              <div key={`day-${index}`} className="h-8 flex items-center justify-center">
                <span className="text-[12px] text-[#8e8e93] font-semibold">{day}</span>
              </div>
            ))}
          </div>

          {/* Calendar grid */}
          <div className="grid grid-cols-7 gap-1.5 mb-4">
            {renderCalendarDays()}
          </div>

          {/* Back to today button */}
          <button
            onClick={handleBackToToday}
            className="w-full bg-[#007aff] text-white text-[16px] font-semibold py-3 rounded-[12px] hover:bg-[#0066cc] transition-colors"
          >
            Back to Today
          </button>
        </div>
      </div>
    </div>
  );
}