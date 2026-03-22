import { ChevronLeft, Check } from 'lucide-react';
import { useState } from 'react';

interface ThreeOptionSelectorProps {
  title: string;
  description: string;
  currentValue: 'Low' | 'Medium' | 'High';
  onSelect: (value: 'Low' | 'Medium' | 'High') => void;
  onClose: () => void;
}

export function ThreeOptionSelector({ 
  title, 
  description, 
  currentValue, 
  onSelect, 
  onClose 
}: ThreeOptionSelectorProps) {
  const [selectedValue, setSelectedValue] = useState(currentValue);
  const options: Array<'Low' | 'Medium' | 'High'> = ['Low', 'Medium', 'High'];

  const handleSelect = (value: 'Low' | 'Medium' | 'High') => {
    setSelectedValue(value);
    onSelect(value);
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
            <span className="text-[17px] font-medium">{title}</span>
          </button>
        </div>

        {/* Description */}
        <div className="px-5 pt-3 pb-2">
          <p className="text-[13px] text-[#8e8e93] leading-relaxed">
            {description}
          </p>
        </div>

        {/* Options List */}
        <div className="flex-1 overflow-y-auto px-5 pb-4">
          <div className="bg-white rounded-[14px] shadow-sm overflow-hidden">
            {options.map((option, index) => (
              <button
                key={option}
                onClick={() => handleSelect(option)}
                className={`w-full px-4 py-3.5 flex items-center justify-between hover:bg-black/[0.02] active:bg-black/[0.05] transition-colors ${
                  index < options.length - 1 ? 'border-b border-black/[0.06]' : ''
                }`}
              >
                <span className="text-[15px] text-[#1c1c1e]">{option}</span>
                {selectedValue === option && (
                  <Check className="w-5 h-5 text-[#007aff]" strokeWidth={2.5} />
                )}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
