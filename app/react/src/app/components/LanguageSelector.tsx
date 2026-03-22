import { ChevronLeft, Check } from 'lucide-react';
import { useState } from 'react';

interface LanguageSelectorProps {
  currentLanguage: string;
  onSelect: (language: string) => void;
  onClose: () => void;
}

const LANGUAGES = [
  'English',
  'Chinese (Simplified)',
  'Chinese (Traditional)',
  'Spanish',
  'French',
  'German',
  'Japanese',
  'Korean',
  'Italian',
  'Portuguese',
  'Russian',
  'Arabic'
];

export function LanguageSelector({ currentLanguage, onSelect, onClose }: LanguageSelectorProps) {
  const [selectedLanguage, setSelectedLanguage] = useState(currentLanguage);

  const handleSelect = (language: string) => {
    setSelectedLanguage(language);
    onSelect(language);
    // Close after a short delay to show selection
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
            <span className="text-[17px] font-medium">Transcription Language</span>
          </button>
        </div>

        {/* Language List */}
        <div className="flex-1 overflow-y-auto px-5 py-4">
          <div className="bg-white rounded-[14px] shadow-sm overflow-hidden">
            {LANGUAGES.map((language, index) => (
              <button
                key={language}
                onClick={() => handleSelect(language)}
                className={`w-full px-4 py-3.5 flex items-center justify-between hover:bg-black/[0.02] active:bg-black/[0.05] transition-colors ${
                  index < LANGUAGES.length - 1 ? 'border-b border-black/[0.06]' : ''
                }`}
              >
                <span className="text-[15px] text-[#1c1c1e]">{language}</span>
                {selectedLanguage === language && (
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