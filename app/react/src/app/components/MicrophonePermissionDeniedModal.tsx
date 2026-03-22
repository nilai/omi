import { Settings, X } from 'lucide-react';

interface MicrophonePermissionDeniedModalProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenSettings: () => void;
}

export function MicrophonePermissionDeniedModal({ isOpen, onClose, onOpenSettings }: MicrophonePermissionDeniedModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-[100] flex items-center justify-center p-5">
      <div 
        className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
        >
          <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
        </button>

        {/* Icon */}
        <div className="flex justify-center mb-6">
          <div className="w-16 h-16 rounded-full bg-[#ff3b30]/10 flex items-center justify-center">
            <Settings className="w-8 h-8 text-[#ff3b30]" strokeWidth={2} />
          </div>
        </div>

        {/* Title */}
        <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-3 text-center leading-tight">
          Microphone access required
        </h2>

        {/* Description */}
        <p className="text-[15px] text-[#3c3c43] text-center mb-8 leading-[1.4]">
          To record audio, please enable microphone access in Settings. Go to Settings → MemoPin → Microphone.
        </p>

        {/* Buttons */}
        <div className="flex flex-col gap-3">
          {/* Primary Button */}
          <button
            onClick={onOpenSettings}
            className="w-full py-3.5 bg-[#007aff] text-white text-[17px] font-semibold rounded-[14px] hover:bg-[#0051d5] transition-colors"
          >
            Open Settings
          </button>

          {/* Secondary Button */}
          <button
            onClick={onClose}
            className="w-full py-3.5 bg-[#f2f2f7] text-[#1c1c1e] text-[17px] font-medium rounded-[14px] hover:bg-[#e5e5ea] transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}
