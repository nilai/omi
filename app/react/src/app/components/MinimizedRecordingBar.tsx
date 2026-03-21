import { Pause, Play } from 'lucide-react';
import { useState, useEffect } from 'react';

interface MinimizedRecordingBarProps {
  isRecording: boolean;
  recordingTime: number;
  onTogglePause: () => void;
  onExpand: () => void;
}

export function MinimizedRecordingBar({ 
  isRecording, 
  recordingTime, 
  onTogglePause, 
  onExpand 
}: MinimizedRecordingBarProps) {
  const [waveHeights, setWaveHeights] = useState<number[]>([3, 5, 4, 6, 3, 5]);

  // Animate waveform when recording
  useEffect(() => {
    if (!isRecording) return;

    const interval = setInterval(() => {
      setWaveHeights(prev => prev.map(() => Math.random() * 8 + 3));
    }, 150);

    return () => clearInterval(interval);
  }, [isRecording]);

  // Reset wave heights when paused
  useEffect(() => {
    if (!isRecording) {
      setWaveHeights([3, 3, 3, 3, 3, 3]);
    }
  }, [isRecording]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div 
      className="fixed bottom-24 left-1/2 -translate-x-1/2 z-[60] px-4 pointer-events-none"
      style={{ width: 'calc(100% - 2rem)', maxWidth: '400px' }}
    >
      <div 
        className="bg-gradient-to-r from-[#e3f2fd] via-[#f0f4ff] to-[#f3e5f5] rounded-full shadow-[0_8px_32px_rgba(0,122,255,0.15)] px-5 py-3.5 flex items-center gap-3 pointer-events-auto border border-[#007aff]/10 backdrop-blur-sm"
        onClick={onExpand}
        style={{ cursor: 'pointer' }}
      >
        {/* Waveform */}
        <div className="flex items-center gap-1 flex-1">
          {waveHeights.map((height, index) => (
            <div
              key={index}
              className="w-1 bg-gradient-to-t from-[#34c759] to-[#30d158] rounded-full transition-all duration-150"
              style={{ height: `${height * 2}px` }}
            />
          ))}
        </div>

        {/* Recording Time */}
        <div className="text-[#1c1c1e] text-[15px] font-mono font-semibold tabular-nums">
          {formatTime(recordingTime)}
        </div>

        {/* Pause/Play Button */}
        <button
          onClick={(e) => {
            e.stopPropagation();
            onTogglePause();
          }}
          className="w-9 h-9 rounded-full bg-[#ff3b30] hover:bg-[#ff4d42] flex items-center justify-center transition-colors shadow-lg flex-shrink-0"
        >
          {isRecording ? (
            <Pause className="w-5 h-5 text-white" strokeWidth={2.5} />
          ) : (
            <Play className="w-5 h-5 text-white fill-white ml-0.5" strokeWidth={2.5} />
          )}
        </button>

        {/* Recording indicator dot */}
        {isRecording && (
          <div className="w-2 h-2 rounded-full bg-[#ff3b30] animate-pulse flex-shrink-0" />
        )}
      </div>
    </div>
  );
}