interface AudioWaveformProps {
  duration: string;
  isPlaying: boolean;
  currentTime: number;
  totalSeconds: number;
  onSeek: (time: number) => void;
}

export function AudioWaveform({ duration, isPlaying, currentTime, totalSeconds, onSeek }: AudioWaveformProps) {
  // Generate random waveform bars (Apple Voice Memos style)
  const bars = Array.from({ length: 80 }, (_, i) => {
    const baseHeight = 25 + Math.random() * 50;
    const variation = Math.sin(i / 6) * 12;
    return Math.max(25, Math.min(75, baseHeight + variation));
  });

  const progress = totalSeconds > 0 ? (currentTime / totalSeconds) : 0;

  const handleClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const clickProgress = x / rect.width;
    const newTime = clickProgress * totalSeconds;
    onSeek(newTime);
  };

  return (
    <div 
      className="flex items-center justify-center gap-[2px] h-24 cursor-pointer"
      onClick={handleClick}
    >
      {bars.map((height, index) => {
        const barProgress = index / bars.length;
        const isPlayed = barProgress <= progress;
        
        return (
          <div
            key={index}
            className={`w-[3px] rounded-full transition-all duration-150 ${
              isPlayed ? 'bg-[#1c1c1e]' : 'bg-[#d1d1d6]'
            }`}
            style={{
              height: `${height}%`,
            }}
          />
        );
      })}
    </div>
  );
}