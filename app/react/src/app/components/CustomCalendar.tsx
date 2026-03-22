import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useState } from 'react';
import { format, addMonths, subMonths, startOfMonth, endOfMonth, eachDayOfInterval, isSameDay, isToday, isSameMonth, startOfWeek, endOfWeek } from 'date-fns';

interface CustomCalendarProps {
  selectedDate?: Date;
  onSelectDate: (date: Date) => void;
  onClose?: () => void;
}

export function CustomCalendar({ selectedDate, onSelectDate, onClose }: CustomCalendarProps) {
  const [currentMonth, setCurrentMonth] = useState(selectedDate || new Date());
  const today = new Date();

  // Get all days to display in calendar (including prev/next month days)
  const monthStart = startOfMonth(currentMonth);
  const monthEnd = endOfMonth(currentMonth);
  const calendarStart = startOfWeek(monthStart, { weekStartsOn: 1 }); // Start week on Monday
  const calendarEnd = endOfWeek(monthEnd, { weekStartsOn: 1 });
  
  const calendarDays = eachDayOfInterval({
    start: calendarStart,
    end: calendarEnd
  });

  const handleDaySelect = (date: Date) => {
    onSelectDate(date);
  };

  const handlePrevMonth = () => {
    setCurrentMonth(subMonths(currentMonth, 1));
  };

  const handleNextMonth = () => {
    setCurrentMonth(addMonths(currentMonth, 1));
  };

  const weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  return (
    <>
      {/* Backdrop overlay */}
      {onClose && (
        <div 
          className="fixed inset-0 bg-black/40 z-[9998]"
          onClick={onClose}
        />
      )}
      
      {/* Calendar */}
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[9999] w-[90%] max-w-[340px]">
        <div className="bg-white rounded-[16px] shadow-2xl border border-black/[0.06] overflow-hidden">
          {/* Calendar Header */}
          <div className="px-4 py-4 border-b border-black/[0.06]">
            <div className="flex items-center justify-between mb-4">
              <button
                onClick={handlePrevMonth}
                className="p-2 hover:bg-[#f2f2f7] rounded-full transition-colors"
              >
                <ChevronLeft className="w-5 h-5 text-[#3c3c43]" strokeWidth={2.5} />
              </button>
              
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">
                {format(currentMonth, 'MMMM yyyy')}
              </h3>
              
              <button
                onClick={handleNextMonth}
                className="p-2 hover:bg-[#f2f2f7] rounded-full transition-colors"
              >
                <ChevronRight className="w-5 h-5 text-[#3c3c43]" strokeWidth={2.5} />
              </button>
            </div>

            {/* Week Days */}
            <div className="grid grid-cols-7 gap-1">
              {weekDays.map((day) => (
                <div key={day} className="text-center text-[12px] font-semibold text-[#8e8e93] py-1">
                  {day}
                </div>
              ))}
            </div>
          </div>

          {/* Calendar Grid */}
          <div className="p-4">
            <div className="grid grid-cols-7 gap-1.5">
              {calendarDays.map((day, index) => {
                const isCurrentMonth = isSameMonth(day, currentMonth);
                const isTodayDate = isToday(day);
                const isSelected = selectedDate && isSameDay(day, selectedDate);

                return (
                  <button
                    key={index}
                    onClick={() => handleDaySelect(day)}
                    disabled={!isCurrentMonth}
                    className={`
                      aspect-square flex items-center justify-center rounded-[10px] text-[15px] font-medium transition-all min-h-[44px]
                      ${!isCurrentMonth ? 'text-[#c7c7cc] cursor-not-allowed' : ''}
                      ${isCurrentMonth && !isTodayDate && !isSelected ? 'text-[#1c1c1e] hover:bg-[#f2f2f7] active:bg-[#e5e5ea]' : ''}
                      ${isTodayDate && !isSelected ? 'bg-[#e8f4fd] text-[#007aff] font-semibold' : ''}
                      ${isSelected ? 'bg-[#007aff] text-white font-semibold shadow-md' : ''}
                    `}
                  >
                    {format(day, 'd')}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Footer with Cancel button */}
          {onClose && (
            <div className="px-4 pb-4 pt-2 border-t border-black/[0.06]">
              <button
                onClick={onClose}
                className="w-full py-3 px-3 text-[#007aff] rounded-[12px] text-[15px] font-semibold hover:bg-[#f2f2f7] active:bg-[#e5e5ea] transition-colors"
              >
                Cancel
              </button>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
