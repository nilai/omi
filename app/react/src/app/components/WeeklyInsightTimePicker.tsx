import { ChevronLeft } from 'lucide-react';
import { useState } from 'react';

interface WeeklyInsightTimePickerProps {
  currentTime: string;
  onSelect: (time: string) => void;
  onClose: () => void;
}

export function WeeklyInsightTimePicker({ currentTime, onSelect, onClose }: WeeklyInsightTimePickerProps) {
  const [selectedDay, setSelectedDay] = useState<'Sat' | 'Sun'>(
    currentTime.startsWith('Sat') ? 'Sat' : 'Sun'
  );
  const [selectedTime, setSelectedTime] = useState(() => {
    // Extract time from "Sat 10:00 AM" or "Sun 10:00 AM"
    const match = currentTime.match(/(\d{1,2}):(\d{2}) (AM|PM)/);
    return match ? `${match[1]}:${match[2]} ${match[3]}` : '10:00 AM';
  });

  // Generate 24-hour times with 15-minute intervals
  const generateTimes = () => {
    const times: string[] = [];
    for (let hour = 0; hour < 24; hour++) {
      for (let minute = 0; minute < 60; minute += 15) {
        const period = hour >= 12 ? 'PM' : 'AM';
        const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
        const displayMinute = minute.toString().padStart(2, '0');
        times.push(`${displayHour}:${displayMinute} ${period}`);
      }
    }
    return times;
  };

  const times = generateTimes();

  const handleDaySelect = (day: 'Sat' | 'Sun') => {
    setSelectedDay(day);
  };

  const handleTimeSelect = (time: string) => {
    setSelectedTime(time);
    const fullTime = `${selectedDay} ${time}`;
    onSelect(fullTime);
    setTimeout(() => {
      onClose();
    }, 200);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm" onClick={onClose}>
      <div 
        className="absolute inset-x-0 bottom-0 bg-[#f2f2f7] rounded-t-[20px] max-h-[70vh] flex flex-col animate-slide-up"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-5 pt-4 pb-3 flex items-center border-b border-black/[0.06] bg-[#f2f2f7] rounded-t-[20px]">
          <button 
            onClick={onClose}
            className="flex items-center gap-2 text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
            <span className="text-[17px] font-medium">Weekly Insight Push Time</span>
          </button>
        </div>

        {/* Description */}
        <div className="px-5 pt-3 pb-2">
          <p className="text-[13px] text-[#8e8e93] leading-relaxed">
            Choose a day and time for your weekly insights
          </p>
        </div>

        {/* Day Selector */}
        <div className="px-5 pb-3">
          <div className="flex gap-2">
            <button
              onClick={() => handleDaySelect('Sat')}
              className={`flex-1 py-2.5 px-4 rounded-[10px] text-[15px] font-medium transition-all ${
                selectedDay === 'Sat'
                  ? 'bg-[#007aff] text-white shadow-sm'
                  : 'bg-white text-[#1c1c1e] hover:bg-gray-50 shadow-sm'
              }`}
            >
              Saturday
            </button>
            <button
              onClick={() => handleDaySelect('Sun')}
              className={`flex-1 py-2.5 px-4 rounded-[10px] text-[15px] font-medium transition-all ${
                selectedDay === 'Sun'
                  ? 'bg-[#007aff] text-white shadow-sm'
                  : 'bg-white text-[#1c1c1e] hover:bg-gray-50 shadow-sm'
              }`}
            >
              Sunday
            </button>
          </div>
        </div>

        {/* Time List */}
        <div className="flex-1 overflow-y-auto px-5 pb-4">
          <div className="bg-white rounded-[14px] shadow-sm overflow-hidden">
            {times.map((time, index) => (
              <button
                key={time}
                onClick={() => handleTimeSelect(time)}
                className={`w-full px-4 py-3.5 flex items-center justify-between hover:bg-black/[0.02] active:bg-black/[0.05] transition-colors ${
                  index < times.length - 1 ? 'border-b border-black/[0.06]' : ''
                }`}
              >
                <span className={`text-[15px] ${selectedTime === time ? 'text-[#007aff] font-medium' : 'text-[#1c1c1e]'}`}>
                  {time}
                </span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
