import { Mic } from 'lucide-react';

interface MicrophonePermissionModalProps {
  isOpen: boolean;
  onContinue: () => void;
  onNotNow: () => void;
}

export function MicrophonePermissionModal({ isOpen, onContinue, onNotNow }: MicrophonePermissionModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-[100] flex items-center justify-center p-5">
      <div 
        className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Icon */}
        <div className="flex justify-center mb-6">
          <div className="w-16 h-16 rounded-full bg-[#007aff]/10 flex items-center justify-center">
            <Mic className="w-8 h-8 text-[#007aff]" strokeWidth={2} />
          </div>
        </div>

        {/* Title */}
        <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-3 text-center leading-tight">
          Enable microphone access
        </h2>

        {/* Description */}
        <p className="text-[15px] text-[#3c3c43] text-center mb-8 leading-[1.4]">
          MemoPin records conversations and ideas to turn them into memories, summaries, and tasks.
        </p>

        {/* Buttons */}
        <div className="flex flex-col gap-3">
          {/* Primary Button */}
          <button
            onClick={onContinue}
            className="w-full py-3.5 bg-[#007aff] text-white text-[17px] font-semibold rounded-[14px] hover:bg-[#0051d5] transition-colors"
          >
            Continue
          </button>

          {/* Secondary Button */}
          <button
            onClick={onNotNow}
            className="w-full py-3.5 bg-[#f2f2f7] text-[#1c1c1e] text-[17px] font-medium rounded-[14px] hover:bg-[#e5e5ea] transition-colors"
          >
            Not Now
          </button>
        </div>
      </div>
    </div>
  );
}
