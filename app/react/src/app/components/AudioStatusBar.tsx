import { Mic } from 'lucide-react';

export type AudioStatusType = 'recording' | 'syncing' | 'importing' | 'processing';

interface AudioStatusBarProps {
  type: AudioStatusType;
  progress?: number; // 0-100, only for syncing/importing
  currentFile?: number; // For multiple files
  totalFiles?: number; // For multiple files
}

export function AudioStatusBar({ type, progress, currentFile, totalFiles }: AudioStatusBarProps) {
  const getStatusConfig = () => {
    switch (type) {
      case 'recording':
        return {
          icon: <Mic className="w-4 h-4" />,
          text: 'MemoPin is recording',
          showProgress: false,
          showActivityBar: true,
        };
      case 'syncing':
        return {
          icon: <Mic className="w-4 h-4" />,
          text: totalFiles && totalFiles > 1 
            ? `Syncing recordings (${currentFile} of ${totalFiles})`
            : 'Syncing recordings from MemoPin',
          showProgress: true,
          showActivityBar: false,
        };
      case 'importing':
        return {
          icon: <Mic className="w-4 h-4" />,
          text: 'Importing audio file',
          showProgress: true,
          showActivityBar: false,
        };
      case 'processing':
        return {
          icon: <Mic className="w-4 h-4" />,
          text: 'Processing audio',
          showProgress: true,
          showActivityBar: false,
        };
    }
  };

  const config = getStatusConfig();

  return (
    <div className="bg-[#f5f7fa] border-b border-[#e8ecef] px-4 py-3">
      <div className="flex items-center gap-3">
        {/* Icon */}
        <div className={`flex-shrink-0 ${type === 'recording' ? 'text-[#ff3b30]' : 'text-[#007aff]'}`}>
          {config.icon}
        </div>

        {/* Status Text and Progress */}
        <div className="flex-1 min-w-0">
          <div className="text-sm text-[#1d1d1f] mb-1.5">
            {config.text}
          </div>

          {/* Progress Bar */}
          {config.showProgress && progress !== undefined && (
            <div className="flex items-center gap-2">
              <div className="flex-1 h-1.5 bg-[#e8ecef] rounded-full overflow-hidden">
                <div 
                  className="h-full bg-[#007aff] rounded-full transition-all duration-300 ease-out"
                  style={{ width: `${progress}%` }}
                />
              </div>
              <div className="text-xs text-[#86868b] font-medium w-10 text-right">
                {progress}%
              </div>
            </div>
          )}

          {/* Activity Bar (for recording - no percentage) */}
          {config.showActivityBar && (
            <div className="h-1.5 bg-[#e8ecef] rounded-full overflow-hidden relative">
              {/* Pulsing bar animation */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div 
                  className="h-full bg-[#007aff] rounded-full"
                  style={{
                    width: '30%',
                    animation: 'recording-pulse 2s ease-in-out infinite',
                  }}
                />
              </div>
            </div>
          )}
        </div>
      </div>

      <style>{`
        @keyframes recording-pulse {
          0%, 100% {
            opacity: 0.6;
            transform: scaleX(1);
          }
          50% {
            opacity: 1;
            transform: scaleX(1.5);
          }
        }
      `}</style>
    </div>
  );
}