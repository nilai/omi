import { ChevronLeft } from 'lucide-react';
import { useState } from 'react';

interface SilentHoursPickerProps {
  currentRange: string; // e.g., "11:00 PM – 6:00 AM"
  onSelect: (range: string) => void;
  onClose: () => void;
}

export function SilentHoursPicker({ currentRange, onSelect, onClose }: SilentHoursPickerProps) {
  // Parse current range
  const parseCurrentRange = () => {
    const match = currentRange.match(/(\d{1,2}):(\d{2}) (AM|PM) – (\d{1,2}):(\d{2}) (AM|PM)/);
    if (match) {
      return {
        startTime: `${match[1]}:${match[2]} ${match[3]}`,
        endTime: `${match[4]}:${match[5]} ${match[6]}`
      };
    }
    return { startTime: '11:00 PM', endTime: '6:00 AM' };
  };

  const { startTime: initialStart, endTime: initialEnd } = parseCurrentRange();
  const [startTime, setStartTime] = useState(initialStart);
  const [endTime, setEndTime] = useState(initialEnd);
  const [editingMode, setEditingMode] = useState<'start' | 'end' | null>(null);

  // Generate start times: 9:00 PM onwards
  const generateStartTimes = () => {
    const times: string[] = [];
    for (let hour = 21; hour < 24; hour++) {
      for (let minute = 0; minute < 60; minute += 15) {
        const displayHour = hour > 12 ? hour - 12 : hour;
        const displayMinute = minute.toString().padStart(2, '0');
        times.push(`${displayHour}:${displayMinute} PM`);
      }
    }
    return times;
  };

  // Generate end times: 12:00 AM to 9:00 AM
  const generateEndTimes = () => {
    const times: string[] = [];
    // Midnight to 9 AM
    for (let hour = 0; hour <= 9; hour++) {
      for (let minute = 0; minute < 60; minute += 15) {
        // Stop at 9:00 AM, don't add 9:15, 9:30, 9:45 AM
        if (hour === 9 && minute > 0) {
          break;
        }
        const period = 'AM';
        const displayHour = hour === 0 ? 12 : hour;
        const displayMinute = minute.toString().padStart(2, '0');
        times.push(`${displayHour}:${displayMinute} ${period}`);
      }
    }
    return times;
  };

  const startTimes = generateStartTimes();
  const endTimes = generateEndTimes();

  const handleStartTimeSelect = (time: string) => {
    setStartTime(time);
    setEditingMode(null);
  };

  const handleEndTimeSelect = (time: string) => {
    setEndTime(time);
    setEditingMode(null);
  };

  const handleSave = () => {
    const range = `${startTime} – ${endTime}`;
    onSelect(range);
    onClose();
  };

  if (editingMode === 'start') {
    return (
      <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm" onClick={() => setEditingMode(null)}>
        <div 
          className="absolute inset-x-0 bottom-0 bg-[#f2f2f7] rounded-t-[20px] max-h-[70vh] flex flex-col animate-slide-up"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="px-5 pt-4 pb-3 flex items-center border-b border-black/[0.06] bg-[#f2f2f7] rounded-t-[20px]">
            <button 
              onClick={() => setEditingMode(null)}
              className="flex items-center gap-2 text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
              <span className="text-[17px] font-medium">Start Time</span>
            </button>
          </div>
          <div className="px-5 pt-3 pb-2">
            <p className="text-[13px] text-[#8e8e93] leading-relaxed">
              Select when silent hours begin (9:00 PM onwards)
            </p>
          </div>
          <div className="flex-1 overflow-y-auto px-5 pb-4">
            <div className="bg-white rounded-[14px] shadow-sm overflow-hidden">
              {startTimes.map((time, index) => (
                <button
                  key={time}
                  onClick={() => handleStartTimeSelect(time)}
                  className={`w-full px-4 py-3.5 flex items-center justify-between hover:bg-black/[0.02] active:bg-black/[0.05] transition-colors ${
                    index < startTimes.length - 1 ? 'border-b border-black/[0.06]' : ''
                  }`}
                >
                  <span className={`text-[15px] ${startTime === time ? 'text-[#007aff] font-medium' : 'text-[#1c1c1e]'}`}>
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

  if (editingMode === 'end') {
    return (
      <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm" onClick={() => setEditingMode(null)}>
        <div 
          className="absolute inset-x-0 bottom-0 bg-[#f2f2f7] rounded-t-[20px] max-h-[70vh] flex flex-col animate-slide-up"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="px-5 pt-4 pb-3 flex items-center border-b border-black/[0.06] bg-[#f2f2f7] rounded-t-[20px]">
            <button 
              onClick={() => setEditingMode(null)}
              className="flex items-center gap-2 text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
              <span className="text-[17px] font-medium">End Time</span>
            </button>
          </div>
          <div className="px-5 pt-3 pb-2">
            <p className="text-[13px] text-[#8e8e93] leading-relaxed">
              Select when silent hours end (before 9:00 AM)
            </p>
          </div>
          <div className="flex-1 overflow-y-auto px-5 pb-4">
            <div className="bg-white rounded-[14px] shadow-sm overflow-hidden">
              {endTimes.map((time, index) => (
                <button
                  key={time}
                  onClick={() => handleEndTimeSelect(time)}
                  className={`w-full px-4 py-3.5 flex items-center justify-between hover:bg-black/[0.02] active:bg-black/[0.05] transition-colors ${
                    index < endTimes.length - 1 ? 'border-b border-black/[0.06]' : ''
                  }`}
                >
                  <span className={`text-[15px] ${endTime === time ? 'text-[#007aff] font-medium' : 'text-[#1c1c1e]'}`}>
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

  return (
    <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm" onClick={onClose}>
      <div 
        className="absolute inset-x-0 bottom-0 bg-[#f2f2f7] rounded-t-[20px] max-h-[70vh] flex flex-col animate-slide-up"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06] bg-[#f2f2f7] rounded-t-[20px]">
          <button 
            onClick={onClose}
            className="flex items-center gap-2 text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
            <span className="text-[17px] font-medium">Silent Hours</span>
          </button>
          <button
            onClick={handleSave}
            className="text-[17px] font-semibold text-[#007aff] hover:opacity-70 transition-opacity"
          >
            Done
          </button>
        </div>

        {/* Description */}
        <div className="px-5 pt-4 pb-2">
          <p className="text-[13px] text-[#8e8e93] leading-relaxed">
            Choose the time range when you don't want to receive notifications
          </p>
        </div>

        {/* Time Range Selector */}
        <div className="flex-1 overflow-y-auto px-5 pb-4">
          <div className="bg-white rounded-[14px] shadow-sm overflow-hidden">
            <button
              onClick={() => setEditingMode('start')}
              className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-black/[0.02] active:bg-black/[0.05] transition-colors border-b border-black/[0.06]"
            >
              <span className="text-[15px] text-[#1c1c1e]">Start</span>
              <span className="text-[15px] text-[#007aff] font-medium">{startTime}</span>
            </button>
            <button
              onClick={() => setEditingMode('end')}
              className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-black/[0.02] active:bg-black/[0.05] transition-colors"
            >
              <span className="text-[15px] text-[#1c1c1e]">End</span>
              <span className="text-[15px] text-[#007aff] font-medium">{endTime}</span>
            </button>
          </div>

          {/* Preview */}
          <div className="mt-4 px-4 py-3 bg-[#eef2ff] rounded-[10px] border border-[#c7d2fe]/30">
            <p className="text-[13px] text-[#6366f1] font-medium">Preview</p>
            <p className="text-[15px] text-[#1c1c1e] mt-1">{startTime} – {endTime}</p>
          </div>
        </div>
      </div>
    </div>
  );
}