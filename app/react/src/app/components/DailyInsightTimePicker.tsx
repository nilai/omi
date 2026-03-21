import { ChevronLeft } from 'lucide-react';
import { useState } from 'react';

interface DailyInsightTimePickerProps {
  currentTime: string;
  onSelect: (time: string) => void;
  onClose: () => void;
}

export function DailyInsightTimePicker({ currentTime, onSelect, onClose }: DailyInsightTimePickerProps) {
  // Generate times from 7:00 PM to 11:00 PM
  const generateTimes = () => {
    const times: string[] = [];
    for (let hour = 19; hour <= 23; hour++) {
      for (let minute = 0; minute < 60; minute += 15) {
        // Stop at 11:00 PM, don't add 11:15, 11:30, 11:45 PM
        if (hour === 23 && minute > 0) {
          break;
        }
        const period = hour >= 12 ? 'PM' : 'AM';
        const displayHour = hour > 12 ? hour - 12 : hour;
        const displayMinute = minute.toString().padStart(2, '0');
        times.push(`${displayHour}:${displayMinute} ${period}`);
      }
    }
    return times;
  };

  const times = generateTimes();
  const [selectedTime, setSelectedTime] = useState(currentTime);

  const handleSelect = (time: string) => {
    setSelectedTime(time);
    onSelect(time);
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
            <span className="text-[17px] font-medium">Daily Insight Push Time</span>
          </button>
        </div>

        {/* Description */}
        <div className="px-5 pt-3 pb-2">
          <p className="text-[13px] text-[#8e8e93] leading-relaxed">
            Choose when you'd like to receive your daily insights (7:00 PM - 11:00 PM)
          </p>
        </div>

        {/* Time List */}
        <div className="flex-1 overflow-y-auto px-5 pb-4">
          <div className="bg-white rounded-[14px] shadow-sm overflow-hidden">
            {times.map((time, index) => (
              <button
                key={time}
                onClick={() => handleSelect(time)}
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