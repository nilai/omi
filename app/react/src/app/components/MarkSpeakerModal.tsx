import { X, Check, Play, AlertCircle } from 'lucide-react';
import { useState } from 'react';
import { useVoiceprints } from '../contexts/VoiceprintContext';

interface MarkSpeakerModalProps {
  isOpen: boolean;
  onClose: () => void;
  transcriptData: Array<{ speaker: string; time: string; text: string }>;
  onSave: (speakerName: string, selectedLines: number[]) => void;
}

export function MarkSpeakerModal({ isOpen, onClose, transcriptData, onSave }: MarkSpeakerModalProps) {
  const [selectedLines, setSelectedLines] = useState<number[]>([]);
  const [speakerName, setSpeakerName] = useState('');
  const [showWarning, setShowWarning] = useState(false);
  const [playingLine, setPlayingLine] = useState<number | null>(null);
  const [durationWarning, setDurationWarning] = useState(false);
  
  const { addVoiceprint } = useVoiceprints();

  // Filter only unidentified lines
  const unidentifiedLines = transcriptData
    .map((item, index) => ({ ...item, originalIndex: index }))
    .filter(item => item.speaker === 'Unidentified');

  // Calculate total duration of selected lines
  const calculateDuration = (indices: number[]) => {
    let totalSeconds = 0;
    const sortedIndices = [...indices].sort((a, b) => a - b);
    
    for (let i = 0; i < sortedIndices.length; i++) {
      const currentIndex = sortedIndices[i];
      const currentTime = transcriptData[currentIndex].time;
      
      // Get next time (either next selected line or estimate)
      let nextTime: string;
      if (i < sortedIndices.length - 1) {
        nextTime = transcriptData[sortedIndices[i + 1]].time;
      } else if (currentIndex < transcriptData.length - 1) {
        nextTime = transcriptData[currentIndex + 1].time;
      } else {
        // Last line, estimate 5 seconds
        nextTime = formatTimeFromSeconds(parseTime(currentTime) + 5);
      }
      
      const duration = parseTime(nextTime) - parseTime(currentTime);
      totalSeconds += duration;
    }
    
    return totalSeconds;
  };

  // Parse time string (e.g., "1:05" or "0:15") to seconds
  const parseTime = (timeStr: string): number => {
    const parts = timeStr.split(':').map(Number);
    if (parts.length === 2) {
      return parts[0] * 60 + parts[1];
    }
    return 0;
  };

  // Format seconds to time string
  const formatTimeFromSeconds = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const toggleLine = (originalIndex: number) => {
    setSelectedLines(prev => {
      const newSelection = prev.includes(originalIndex)
        ? prev.filter(idx => idx !== originalIndex)
        : [...prev, originalIndex];
      
      // Clear duration warning when user changes selection
      setDurationWarning(false);
      
      // AI detection simulation: if more than 2 lines selected, randomly show warning
      if (newSelection.length > 2 && Math.random() > 0.5) {
        setShowWarning(true);
      } else {
        setShowWarning(false);
      }
      
      return newSelection;
    });
  };

  const selectAll = () => {
    const allIndices = unidentifiedLines.map(item => item.originalIndex);
    setSelectedLines(allIndices);
    
    // Clear duration warning when user changes selection
    setDurationWarning(false);
    
    // Simulate AI detection
    if (unidentifiedLines.length > 2) {
      setShowWarning(Math.random() > 0.5);
    }
  };

  const deselectAll = () => {
    setSelectedLines([]);
    setShowWarning(false);
    setDurationWarning(false);
  };

  const handlePlayLine = (originalIndex: number) => {
    setPlayingLine(originalIndex);
    // Simulate audio playback
    setTimeout(() => {
      setPlayingLine(null);
    }, 2000);
  };

  // Calculate duration of a single segment
  const calculateSegmentDuration = (originalIndex: number): number => {
    const currentTime = parseTime(transcriptData[originalIndex].time);
    let nextTime: number;
    
    if (originalIndex < transcriptData.length - 1) {
      nextTime = parseTime(transcriptData[originalIndex + 1].time);
    } else {
      // Last line, estimate 5 seconds
      nextTime = currentTime + 5;
    }
    
    return nextTime - currentTime;
  };

  const handleSave = () => {
    if (speakerName.trim() && selectedLines.length > 0) {
      const duration = calculateDuration(selectedLines);
      
      // Check if duration is less than 30 seconds
      if (duration < 30) {
        setDurationWarning(true);
        return; // Block save
      }
      
      // Add to voiceprint database
      addVoiceprint({
        name: speakerName,
        duration: duration,
        sampleCount: selectedLines.length,
        audioSegments: selectedLines.map(index => ({
          time: transcriptData[index].time,
          text: transcriptData[index].text
        }))
      });
      
      // Update transcript
      onSave(speakerName, selectedLines);
      
      // Close modal and reset
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-[60] flex items-center justify-center p-5" onClick={onClose}>
      <div className="bg-white rounded-[24px] w-full max-w-2xl max-h-[85vh] shadow-2xl relative flex flex-col" onClick={(e) => e.stopPropagation()}>
        {/* Header */}
        <div className="px-6 pt-6 pb-4 border-b border-black/[0.06]">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-[22px] font-bold text-[#1c1c1e]">Mark Speaker</h3>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
            >
              <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
            </button>
          </div>
          <p className="text-[14px] text-[#8e8e93]">
            Select sentences spoken by the same person, then assign a name
          </p>
        </div>

        {/* Selection Info Bar */}
        <div className="px-6 py-3 bg-[#f2f2f7] border-b border-black/[0.06] flex items-center justify-between">
          <div className="text-[14px] text-[#1c1c1e]">
            <span className="font-semibold">{selectedLines.length}</span> of {unidentifiedLines.length} selected
          </div>
          <button
            onClick={() => selectedLines.length === unidentifiedLines.length ? deselectAll() : selectAll()}
            className="text-[14px] font-medium text-[#007aff] hover:opacity-70 transition-opacity"
          >
            {selectedLines.length === unidentifiedLines.length ? 'Deselect All' : 'Select All'}
          </button>
        </div>

        {/* Scrollable Transcript List */}
        <div className="flex-1 overflow-y-auto px-6 py-4">
          <div className="space-y-3">
            {unidentifiedLines.map((item) => (
              <div
                key={item.originalIndex}
                className={`p-4 rounded-[12px] border-2 transition-all ${
                  selectedLines.includes(item.originalIndex)
                    ? 'bg-[#007aff]/5 border-[#007aff]'
                    : 'bg-white border-black/[0.06] hover:border-black/[0.12]'
                }`}
              >
                <div className="flex items-start gap-3">
                  {/* Checkbox */}
                  <button
                    onClick={() => toggleLine(item.originalIndex)}
                    className={`w-5 h-5 rounded border-2 flex items-center justify-center flex-shrink-0 mt-0.5 transition-all ${
                      selectedLines.includes(item.originalIndex)
                        ? 'bg-[#007aff] border-[#007aff]'
                        : 'bg-white border-[#c7c7cc]'
                    }`}
                  >
                    {selectedLines.includes(item.originalIndex) && (
                      <Check className="w-3 h-3 text-white" strokeWidth={3} />
                    )}
                  </button>

                  {/* Content */}
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1.5">
                      <span className="text-[13px] font-medium text-[#8e8e93]">
                        {item.time} • {calculateSegmentDuration(item.originalIndex)}s
                      </span>
                      <span className="text-[13px] font-semibold text-[#ff9500]">Unidentified</span>
                    </div>
                    <p className="text-[15px] text-[#1c1c1e] leading-[1.5]">
                      {item.text}
                    </p>
                  </div>

                  {/* Play Button */}
                  <button
                    onClick={() => handlePlayLine(item.originalIndex)}
                    disabled={playingLine !== null}
                    className={`w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 transition-all ${
                      playingLine === item.originalIndex
                        ? 'bg-[#34c759] animate-pulse'
                        : 'bg-[#f2f2f7] hover:bg-[#e5e5ea]'
                    }`}
                  >
                    <Play 
                      className={`w-4 h-4 ml-0.5 ${
                        playingLine === item.originalIndex ? 'text-white' : 'text-[#34c759]'
                      }`}
                      strokeWidth={2.5}
                      fill={playingLine === item.originalIndex ? 'white' : '#34c759'}
                    />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* AI Warning */}
        {showWarning && (
          <div className="mx-6 mb-4 bg-[#ff9500]/10 border border-[#ff9500]/30 rounded-[12px] p-4">
            <div className="flex items-start gap-3">
              <div className="w-6 h-6 rounded-full bg-[#ff9500]/20 flex items-center justify-center flex-shrink-0">
                <span className="text-[14px]">⚠️</span>
              </div>
              <div className="flex-1">
                <h4 className="text-[14px] font-semibold text-[#ff9500] mb-1">Different Speakers Detected</h4>
                <p className="text-[13px] text-[#3c3c43] leading-relaxed">
                  The selected sentences appear to be from different speakers based on voice characteristics. Please review your selection.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Duration Warning */}
        {durationWarning && (
          <div className="mx-6 mb-4 bg-[#ff9500]/10 border border-[#ff9500]/30 rounded-[12px] p-4">
            <div className="flex items-start gap-3">
              <div className="w-6 h-6 rounded-full bg-[#ff9500]/20 flex items-center justify-center flex-shrink-0">
                <AlertCircle className="w-4 h-4 text-[#ff9500]" strokeWidth={2.5} />
              </div>
              <div className="flex-1">
                <h4 className="text-[14px] font-semibold text-[#ff9500] mb-1">Insufficient Audio Duration</h4>
                <p className="text-[13px] text-[#3c3c43] leading-relaxed">
                  Selected audio is only {Math.round(calculateDuration(selectedLines))} seconds. Please select at least 30 seconds of speech to create an accurate voiceprint.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Bottom Section - Name Input and Actions */}
        <div className="px-6 pb-6 pt-4 border-t border-black/[0.06]">
          {/* Name Input */}
          <div className="mb-4">
            <label className="block text-[14px] font-medium text-[#1c1c1e] mb-2">
              Speaker Name
            </label>
            <input
              type="text"
              value={speakerName}
              onChange={(e) => setSpeakerName(e.target.value)}
              placeholder="Enter speaker's name"
              className="w-full px-4 py-3 bg-[#f2f2f7] rounded-[12px] text-[15px] text-[#1c1c1e] placeholder-[#8e8e93] focus:outline-none focus:ring-2 focus:ring-[#007aff]"
            />
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={!speakerName.trim() || selectedLines.length === 0}
              className={`flex-1 py-3 rounded-[12px] font-semibold transition-all ${
                speakerName.trim() && selectedLines.length > 0
                  ? 'bg-[#007aff] text-white hover:bg-[#0051d5]'
                  : 'bg-[#e5e5ea] text-[#8e8e93] cursor-not-allowed'
              }`}
            >
              Save Speaker
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}