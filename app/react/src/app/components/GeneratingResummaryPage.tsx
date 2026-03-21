import { ChevronLeft, Sparkles, Mic, Smartphone } from 'lucide-react';

interface GeneratingResummaryPageProps {
  memory: any;
  onBack: () => void;
}

export function GeneratingResummaryPage({ memory, onBack }: GeneratingResummaryPageProps) {
  // Get source icon
  const getSourceIcon = (source: 'MemoPin' | 'MobilePhone') => {
    if (source === 'MemoPin') {
      return <Mic className="w-3.5 h-3.5" />;
    }
    return <Smartphone className="w-3.5 h-3.5" />;
  };

  return (
    <div className="fixed inset-0 z-50 bg-[#f2f2f7] flex flex-col">
      {/* Header */}
      <div className="px-5 py-4 bg-white border-b border-black/[0.06] flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button 
            onClick={onBack}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-7 h-7" strokeWidth={2} />
          </button>
          <h1 className="text-[17px] font-semibold">Audio Memory</h1>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Background Info */}
        <div className="px-5 pt-6 pb-4">
          <div className="space-y-1">
            <h2 className="text-[28px] font-bold text-[#1c1c1e]">
              {memory.title || memory.date}
            </h2>
            <div className="flex items-center gap-2 text-[15px] text-[#8e8e93]">
              <span>{memory.dateSubtitle || memory.date}</span>
              <span>·</span>
              <div className="flex items-center gap-1">
                {getSourceIcon(memory.audioSource)}
                <span>{memory.audioSource}</span>
              </div>
            </div>
          </div>
        </div>

        {/* AI Summary Generating State */}
        <div className="px-5 pt-8 pb-6">
          <div className="flex flex-col items-center justify-center py-12 text-center">
            {/* Animated Sparkles Icon */}
            <div className="relative mb-6">
              <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#007aff]/20 to-[#007aff]/10 flex items-center justify-center animate-pulse">
                <Sparkles className="w-10 h-10 text-[#007aff]" />
              </div>
              {/* Rotating ring */}
              <div className="absolute inset-0 rounded-full border-2 border-transparent border-t-[#007aff] animate-spin"></div>
            </div>

            {/* Main heading */}
            <h3 className="text-[22px] font-bold mb-2 text-[#1c1c1e]">
              AI is working on it
            </h3>
            
            {/* Subtext */}
            <p className="text-[15px] text-[#8e8e93] max-w-sm leading-[1.4] mb-8">
              Analyzing your recording and generating insights...
            </p>

            {/* Progress steps */}
            <div className="w-full max-w-xs space-y-3">
              <AIProgressStep 
                icon="🎧" 
                text="Transcribing audio" 
                status="in-progress" 
              />
              <AIProgressStep 
                icon="🧠" 
                text="Understanding context" 
                status="in-progress" 
              />
              <AIProgressStep 
                icon="✨" 
                text="Generating insights" 
                status="in-progress" 
              />
              <AIProgressStep 
                icon="📝" 
                text="Organizing summary" 
                status="in-progress" 
              />
            </div>

            {/* Estimated time */}
            <div className="mt-8 px-4 py-2.5 bg-[#f2f2f7] rounded-[12px]">
              <p className="text-[13px] text-[#8e8e93]">
                This usually takes <span className="font-medium text-[#1c1c1e]">30 seconds - 2 minute</span>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// AI Progress Step Component - Same as AudioMemoryDetail
interface AIProgressStepProps {
  icon: string;
  text: string;
  status: 'completed' | 'in-progress' | 'pending';
}

function AIProgressStep({ icon, text, status }: AIProgressStepProps) {
  const getStatusClass = () => {
    switch (status) {
      case 'completed':
        return 'bg-[#34c759]';
      case 'in-progress':
        return 'bg-[#007aff] animate-pulse';
      case 'pending':
        return 'bg-[#e5e5ea]';
    }
  };

  const getTextClass = () => {
    switch (status) {
      case 'completed':
        return 'text-[#1c1c1e]';
      case 'in-progress':
        return 'text-[#1c1c1e] font-medium';
      case 'pending':
        return 'text-[#8e8e93]';
    }
  };

  return (
    <div className="flex items-center gap-3">
      <div className={`w-8 h-8 rounded-full ${getStatusClass()} flex items-center justify-center flex-shrink-0`}>
        {status === 'completed' ? (
          <svg className="w-4 h-4 text-white" viewBox="0 0 16 16" fill="none">
            <path d="M13 4L6 11L3 8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        ) : (
          <span className="text-[14px]">{icon}</span>
        )}
      </div>
      <p className={`text-[15px] leading-[1.3] ${getTextClass()}`}>
        {text}
      </p>
    </div>
  );
}