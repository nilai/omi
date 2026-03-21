import { ChevronLeft, Play, Pause, Sparkles, Mic, Smartphone, Share2, MoreVertical, Info, FileText, Users, Phone, Clipboard, BookOpen, Brain, Lightbulb, Compass } from 'lucide-react';
import { useState, useEffect } from 'react';
import { AudioWaveform } from './AudioWaveform';
import { SystemShareModal } from './SystemShareModal';
import { TemplateDetailModal } from './TemplateDetailModal';
import { AISummaryStylePage } from './AISummaryStylePage';

interface AudioMemoryDetailProps {
  memory: any;
  onClose: () => void;
  onSummarize: () => void;
}

export function AudioMemoryDetail({ memory, onClose, onSummarize }: AudioMemoryDetailProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [showShareMenu, setShowShareMenu] = useState(false);
  const [showMoreMenu, setShowMoreMenu] = useState(false);
  const [showExportModal, setShowExportModal] = useState(false);
  const [showSummarizeModal, setShowSummarizeModal] = useState(false);
  const [exportFormat, setExportFormat] = useState('MP3');
  const [showTemplateModal, setShowTemplateModal] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('autopilot');
  const [tempSelectedTemplate, setTempSelectedTemplate] = useState<string>('autopilot');
  const [isGeneratingSummary, setIsGeneratingSummary] = useState(false);
  const [showSystemShareModal, setShowSystemShareModal] = useState(false);
  const [showTemplateDetail, setShowTemplateDetail] = useState(false);
  const [selectedTemplateForDetail, setSelectedTemplateForDetail] = useState<string>('meeting-secretary');
  const [favoriteStyles, setFavoriteStyles] = useState<string[]>([]);
  const [showAISummaryStylePage, setShowAISummaryStylePage] = useState(false);
  
  // Load default style on mount - prioritize last used style
  useEffect(() => {
    // First check for last used style, then default style, then fallback to autopilot
    const lastUsedStyle = localStorage.getItem('lastUsedSummaryStyle');
    const defaultStyle = localStorage.getItem('defaultSummaryStyle');
    const styleToUse = lastUsedStyle || defaultStyle || 'autopilot';
    setSelectedTemplate(styleToUse);
    setTempSelectedTemplate(styleToUse);
  }, []);
  
  // Load favorite styles when template modal opens
  useEffect(() => {
    if (showTemplateModal || showTemplateDetail) {
      const favorites = JSON.parse(localStorage.getItem('favoriteSummaryStyles') || '[]');
      setFavoriteStyles(favorites);
    }
  }, [showTemplateModal, showTemplateDetail]);
  
  // Listen for storage changes (when favorites are updated)
  useEffect(() => {
    const handleStorageChange = () => {
      const favorites = JSON.parse(localStorage.getItem('favoriteSummaryStyles') || '[]');
      setFavoriteStyles(favorites);
    };
    
    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, []);
  
  // Parse duration to seconds
  const parseDuration = (duration: string) => {
    const parts = duration.match(/(\d+)h|(\d+)m|(\d+)s/g);
    if (!parts) return 0;
    
    let totalSeconds = 0;
    parts.forEach(part => {
      if (part.includes('h')) totalSeconds += parseInt(part) * 3600;
      if (part.includes('m')) totalSeconds += parseInt(part) * 60;
      if (part.includes('s')) totalSeconds += parseInt(part);
    });
    return totalSeconds;
  };

  const totalSeconds = parseDuration(memory.audioDuration);
  const progress = totalSeconds > 0 ? (currentTime / totalSeconds) * 100 : 0;

  // Simulate audio playback
  useEffect(() => {
    let interval: NodeJS.Timeout;
    
    if (isPlaying && currentTime < totalSeconds) {
      interval = setInterval(() => {
        setCurrentTime(prev => {
          const newTime = prev + 0.1;
          if (newTime >= totalSeconds) {
            setIsPlaying(false);
            return totalSeconds;
          }
          return newTime;
        });
      }, 100);
    }
    
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isPlaying, currentTime, totalSeconds]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const handleSeek = (time: number) => {
    setCurrentTime(time);
  };

  const getSourceIcon = (source: 'MemoPin' | 'MobilePhone') => {
    if (source === 'MemoPin') {
      return <Mic className="w-4 h-4" />;
    }
    return <Smartphone className="w-4 h-4" />;
  };

  // Calculate circle progress (circumference)
  const circleRadius = 24; // Updated to match smaller button
  const circumference = 2 * Math.PI * circleRadius;
  const strokeDashoffset = circumference - (progress / 100) * circumference;

  // Get template info based on selected template
  const getTemplateInfo = () => {
    switch (selectedTemplate) {
      case 'autopilot':
        return {
          icon: '🤖',
          title: 'Autopilot mode',
          description: 'AI decides what matters'
        };
      case 'meeting-secretary':
      case 'meeting':
        return {
          icon: '🧑‍💼',
          title: 'Meeting secretary',
          description: 'Structure, decisions, actions'
        };
      case 'sales-followup':
      case 'sales':
        return {
          icon: '📞',
          title: 'Sales follow-up',
          description: 'Needs, objections, next steps'
        };
      case 'project-sync':
        return {
          icon: '📋',
          title: 'Project sync',
          description: 'Progress, blockers, timelines'
        };
      case 'learning-notes':
      case 'learning':
        return {
          icon: '📚',
          title: 'Learning notes',
          description: 'Concepts and understanding'
        };
      case 'adhd-friendly':
      case 'adhd':
        return {
          icon: '🧠',
          title: 'ADHD-friendly',
          description: 'Extra structure, clear priorities'
        };
      case 'reflection-insights':
        return {
          icon: '💡',
          title: 'Reflection',
          description: 'Patterns and insights'
        };
      case 'interview-research':
        return {
          icon: '🎙',
          title: 'Interview',
          description: 'Key points and quotes'
        };
      case 'investor-review':
        return {
          icon: '🧭',
          title: 'Decision review',
          description: 'Arguments and questions'
        };
      default:
        return {
          icon: '🤖',
          title: 'Autopilot mode',
          description: 'AI decides what matters'
        };
    }
  };

  const templateInfo = getTemplateInfo();

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] z-50 flex flex-col">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
        {/* Left side - Back button */}
        <button 
          onClick={onClose}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        
        {/* Center - Title */}
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          Audio Memory
        </h1>
        
        {/* Right side buttons */}
        <div className="flex items-center gap-3 relative">
          {/* Share button */}
          <button
            onClick={() => {
              setShowShareMenu(!showShareMenu);
              setShowMoreMenu(false);
            }}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <Share2 className="w-5 h-5" strokeWidth={2} />
          </button>
          
          {/* More menu button */}
          <button
            onClick={() => {
              setShowMoreMenu(!showMoreMenu);
              setShowShareMenu(false);
            }}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <MoreVertical className="w-5 h-5" strokeWidth={2} />
          </button>

          {/* Share Menu Dropdown */}
          {showShareMenu && (
            <>
              <div 
                className="fixed inset-0 z-40" 
                onClick={() => setShowShareMenu(false)}
              />
              <div className="absolute top-8 right-0 bg-white rounded-[14px] shadow-2xl border border-black/[0.08] overflow-hidden z-50 min-w-[180px]">
                <button
                  onClick={() => {
                    setShowShareMenu(false);
                    setShowSystemShareModal(true);
                  }}
                  className="w-full px-4 py-3.5 text-left text-[15px] text-[#1c1c1e] hover:bg-[#f2f2f7] transition-colors border-b border-black/[0.06]"
                >
                  Share Links
                </button>
                <button
                  onClick={() => {
                    setShowShareMenu(false);
                    setShowExportModal(true);
                  }}
                  className="w-full px-4 py-3.5 text-left text-[15px] text-[#1c1c1e] hover:bg-[#f2f2f7] transition-colors"
                >
                  Export Audio
                </button>
              </div>
            </>
          )}

          {/* More Menu Dropdown */}
          {showMoreMenu && (
            <>
              <div 
                className="fixed inset-0 z-40" 
                onClick={() => setShowMoreMenu(false)}
              />
              <div className="absolute top-8 right-0 bg-white rounded-[14px] shadow-2xl border border-black/[0.08] overflow-hidden z-50 min-w-[180px]">
                <button
                  onClick={() => {
                    setShowMoreMenu(false);
                    console.log('Delete memory');
                  }}
                  className="w-full px-4 py-3.5 text-left text-[15px] text-[#ff3b30] hover:bg-[#f2f2f7] transition-colors"
                >
                  Delete Memory
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Background Info - Not a card, just text */}
        <div className="px-5 pt-6 pb-4">
          <div className="space-y-1">
            <h2 className="text-[28px] font-bold text-[#1c1c1e]">
              {memory.date}
            </h2>
            <div className="flex items-center gap-2 text-[15px] text-[#8e8e93]">
              <span>{memory.dateSubtitle}</span>
              <span>·</span>
              <div className="flex items-center gap-1">
                {getSourceIcon(memory.audioSource)}
                <span>{memory.audioSource}</span>
              </div>
            </div>
          </div>
        </div>

        {isGeneratingSummary ? (
          /* AI Summary Generating State */
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
        ) : (
          <>
            {/* Audio Player - No card, softer visual */}
            <div className="px-5 pt-2">
              {/* Time display at top */}
              <div className="flex justify-between mb-3 text-[15px]">
                <span className="font-medium text-[#1c1c1e]">{formatTime(currentTime)}</span>
                <span className="text-[#8e8e93]">{memory.audioDuration}</span>
              </div>

              {/* Waveform - interactive */}
              <div className="mb-4">
                <AudioWaveform 
                  duration={memory.audioDuration} 
                  isPlaying={isPlaying}
                  currentTime={currentTime}
                  totalSeconds={totalSeconds}
                  onSeek={handleSeek}
                />
              </div>

              {/* Play/Pause button with circular progress - smaller, closer to waveform */}
              <div className="flex justify-center mb-6">
                <div className="relative">
                  {/* Circular progress ring - smaller */}
                  <svg 
                    className="absolute inset-0 -rotate-90" 
                    width="56" 
                    height="56"
                  >
                    {/* Background circle */}
                    <circle
                      cx="28"
                      cy="28"
                      r="24"
                      stroke="#e5e5ea"
                      strokeWidth="2.5"
                      fill="none"
                    />
                    {/* Progress circle */}
                    <circle
                      cx="28"
                      cy="28"
                      r="24"
                      stroke="#1c1c1e"
                      strokeWidth="2.5"
                      fill="none"
                      strokeDasharray={circumference}
                      strokeDashoffset={strokeDashoffset}
                      strokeLinecap="round"
                      className="transition-all duration-300"
                    />
                  </svg>
                  
                  {/* Play button - smaller, softer shadow */}
                  <button
                    onClick={() => setIsPlaying(!isPlaying)}
                    className="w-14 h-14 rounded-full bg-white flex items-center justify-center hover:bg-[#f9f9f9] transition-colors shadow-sm border border-black/[0.06]"
                  >
                    {isPlaying ? (
                      <Pause className="w-5 h-5 text-[#1c1c1e]" fill="#1c1c1e" />
                    ) : (
                      <Play className="w-5 h-5 text-[#1c1c1e] ml-0.5" fill="#1c1c1e" />
                    )}
                  </button>
                </div>
              </div>

              {/* Separator line with gradient - subtle divider */}
              <div className="relative h-px mb-6">
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-black/[0.08] to-transparent"></div>
              </div>
            </div>

            {/* Empty state for summary */}
            <div className="px-5 pt-4 pb-6">
              <div className="flex flex-col items-center justify-center py-8 text-center">
                <div className="w-14 h-14 rounded-full bg-[#007aff]/10 flex items-center justify-center mb-3">
                  <Sparkles className="w-7 h-7 text-[#007aff]" />
                </div>
                <h3 className="text-[17px] font-semibold mb-1.5 text-[#1c1c1e]">
                  Want a quick overview?
                </h3>
                <p className="text-[15px] text-[#8e8e93] max-w-xs leading-[1.4]">
                  Generate an AI summary of this conversation
                </p>
              </div>
            </div>
          </>
        )}
      </div>

      {/* Bottom Button - 75% width, softer style - Only show when not generating */}
      {!isGeneratingSummary && (
        <div className="px-5 pb-6 pt-4 bg-[#f2f2f7] flex justify-center">
          <button
            onClick={() => setShowSummarizeModal(true)}
            className="w-[75%] bg-gradient-to-br from-[#e8f5ff] to-[#dbeafe] text-[#007aff] text-[16px] font-semibold py-3.5 rounded-[18px] hover:shadow-md transition-all flex items-center justify-center gap-2 border border-[#007aff]/10"
          >
            <Sparkles className="w-5 h-5" />
            <span>AI Summarize</span>
          </button>
        </div>
      )}

      {/* Export Audio Modal */}
      {showExportModal && (
        <div className="fixed inset-0 bg-black/40 flex items-end z-[100]">
          <div 
            className="absolute inset-0" 
            onClick={() => setShowExportModal(false)}
          />
          <div className="bg-white w-full rounded-t-[24px] p-6 pb-8 relative animate-slide-up">
            {/* Header */}
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-[22px] font-bold text-[#1c1c1e]">
                Export Audio
              </h2>
              <button
                onClick={() => setShowExportModal(false)}
                className="text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
              >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                  <path d="M18 6L6 18M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Export Format Selector */}
            <div className="mb-6">
              <label className="block text-[15px] text-[#1c1c1e] font-medium mb-3">
                Export Format
              </label>
              <div className="relative">
                <select
                  value={exportFormat}
                  onChange={(e) => setExportFormat(e.target.value)}
                  className="w-full appearance-none bg-[#f2f2f7] border border-[#e5e5ea] rounded-[12px] px-4 py-3.5 text-[16px] text-[#1c1c1e] font-medium cursor-pointer hover:bg-[#e8e8ed] transition-colors"
                >
                  <option value="MP3">MP3</option>
                  <option value="M4A">M4A</option>
                  <option value="WAV">WAV</option>
                  <option value="FLAC">FLAC</option>
                </select>
                <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-[#8e8e93]">
                  <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                    <path d="M4 6L8 10L12 6" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
              </div>
            </div>

            {/* Export Button */}
            <button
              onClick={() => {
                setShowExportModal(false);
                console.log(`Exporting as ${exportFormat}`);
                // Trigger system file/share dialog
              }}
              className="w-full bg-[#1c1c1e] text-white text-[17px] font-semibold py-4 rounded-[14px] hover:bg-[#2c2c2e] transition-colors"
            >
              Export
            </button>
          </div>
        </div>
      )}

      {/* AI Summarize Modal - Half-screen from bottom */}
      {showSummarizeModal && (
        <div className="fixed inset-0 bg-black/40 flex items-end z-[100]">
          <div 
            className="absolute inset-0" 
            onClick={() => setShowSummarizeModal(false)}
          />
          <div className="bg-white w-full rounded-t-[28px] px-5 pt-4 pb-6 relative animate-slide-up max-h-[85vh] flex flex-col">
            {/* Drag handle */}
            <div className="flex justify-center mb-2">
              <div className="w-10 h-1 bg-[#c7c7cc] rounded-full" />
            </div>

            {/* Scrollable content */}
            <div className="flex-1 overflow-y-auto">
              {/* Header with sparkles emoji */}
              <div className="mb-3">
                <h2 className="text-[19px] font-bold text-[#1c1c1e] leading-tight mb-1.5">
                  Here's what AI will do for you
                </h2>
                <p className="text-[14px] text-[#3c3c43] leading-[1.35]">
                  AI will turn this recording into something you can quickly review and act on.
                </p>
              </div>

              {/* Unified Summary Features Card */}
              <div className="bg-[#f2f2f7] rounded-[16px] p-4 mb-4">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-3">
                  What you'll get:
                </h3>
                <div className="space-y-3">
                  {/* Quick overview */}
                  <div className="flex items-start gap-3">
                    <div className="w-5 h-5 flex-shrink-0 flex items-center justify-center">
                      <FileText className="w-[18px] h-[18px] text-[#007aff]" strokeWidth={2} />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-[15px] font-medium text-[#1c1c1e] mb-0.5">
                        Quick overview
                      </h4>
                      <p className="text-[13px] text-[#3c3c43] leading-[1.3]">
                        What this recording is about
                      </p>
                    </div>
                  </div>

                  {/* Key takeaways */}
                  <div className="flex items-start gap-3">
                    <div className="w-5 h-5 flex-shrink-0 flex items-center justify-center">
                      <Sparkles className="w-[18px] h-[18px] text-[#007aff]" strokeWidth={2} />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-[15px] font-medium text-[#1c1c1e] mb-0.5">
                        Key takeaways
                      </h4>
                      <p className="text-[13px] text-[#3c3c43] leading-[1.3]">
                        Most important ideas & conclusions
                      </p>
                    </div>
                  </div>

                  {/* Action items */}
                  <div className="flex items-start gap-3">
                    <div className="w-5 h-5 flex-shrink-0 flex items-center justify-center">
                      <svg className="w-[18px] h-[18px] text-[#007aff]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M9 11l3 3L22 4"/>
                        <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
                      </svg>
                    </div>
                    <div className="flex-1">
                      <h4 className="text-[15px] font-medium text-[#1c1c1e] mb-0.5">
                        Action items
                      </h4>
                      <p className="text-[13px] text-[#3c3c43] leading-[1.3]">
                        Things you may need to do next
                      </p>
                    </div>
                  </div>

                  {/* Reflection & insights */}
                  <div className="flex items-start gap-3">
                    <div className="w-5 h-5 flex-shrink-0 flex items-center justify-center">
                      <svg className="w-[18px] h-[18px] text-[#007aff]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>
                        <path d="M12 17h.01"/>
                      </svg>
                    </div>
                    <div className="flex-1">
                      <h4 className="text-[15px] font-medium text-[#1c1c1e] mb-0.5">
                        Reflection & insights
                      </h4>
                      <p className="text-[13px] text-[#3c3c43] leading-[1.3]">
                        Deeper patterns or risks you missed
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Autopilot mode notice with Change button */}
              <div className="bg-[#fffbf0] border border-[#f5e6c3] rounded-[14px] p-3.5 mb-4 flex items-start justify-between gap-3">
                <div className="flex items-start gap-2.5 flex-1">
                  <div className="w-5 h-5 flex-shrink-0 flex items-center justify-center">
                    {(() => {
                      const iconProps = { className: "w-[18px] h-[18px] text-[#f5a623]", strokeWidth: 2 };
                      
                      switch (selectedTemplate) {
                        case 'autopilot':
                          return <Sparkles {...iconProps} />;
                        case 'meeting-secretary':
                        case 'meeting':
                          return <Users {...iconProps} />;
                        case 'sales-followup':
                        case 'sales':
                          return <Phone {...iconProps} />;
                        case 'project-sync':
                          return <Clipboard {...iconProps} />;
                        case 'learning-notes':
                        case 'learning':
                          return <BookOpen {...iconProps} />;
                        case 'adhd-friendly':
                        case 'adhd':
                          return <Brain {...iconProps} />;
                        case 'reflection-insights':
                          return <Lightbulb {...iconProps} />;
                        case 'interview-research':
                          return <Mic {...iconProps} />;
                        case 'investor-review':
                          return <Compass {...iconProps} />;
                        default:
                          return <Sparkles {...iconProps} />;
                      }
                    })()}
                  </div>
                  <div>
                    <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-0.5">
                      {templateInfo.title}
                    </h3>
                    <p className="text-[13px] text-[#3c3c43] leading-[1.3]">
                      {templateInfo.description}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => {
                    setShowTemplateModal(true);
                  }}
                  className="flex-shrink-0 text-[14px] font-medium text-[#007aff] hover:opacity-70 transition-opacity flex items-center gap-1 pt-0.5"
                >
                  <span>Change</span>
                  <span className="text-[12px]">▸</span>
                </button>
              </div>
            </div>

            {/* Bottom CTA - Fixed at bottom */}
            <div className="pt-3">
              <button
                onClick={() => {
                  // Save the selected style as last used
                  localStorage.setItem('lastUsedSummaryStyle', selectedTemplate);
                  setShowSummarizeModal(false);
                  setIsGeneratingSummary(true);
                  // AI processing state will persist until user manually exits
                }}
                className="w-full bg-[#007aff] text-white text-[17px] font-semibold py-3.5 rounded-[14px] hover:bg-[#0051d5] transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                <Sparkles className="w-5 h-5" />
                <span>Generate summary</span>
              </button>

              {/* Additional info text */}
              <p className="text-[12px] text-[#8e8e93] text-center mt-3 leading-[1.4]">
                After the summary is ready, you can:<br/>
                • Create todos • Add your own notes<br/>
                • Ask AI follow-up questions
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Template Selection Modal */}
      {showTemplateModal && (
        <div className="fixed inset-0 bg-black/40 flex items-end z-[110]">
          <div 
            className="absolute inset-0" 
            onClick={() => {
              setShowTemplateModal(false);
              setTempSelectedTemplate(selectedTemplate);
            }}
          />
          <div className="bg-white w-full rounded-t-[28px] px-5 pt-3 pb-5 relative animate-slide-up max-h-[85vh] flex flex-col">
            {/* Header with back and close */}
            <div className="flex items-center justify-between mb-2 -mx-1">
              <button
                onClick={() => {
                  setShowTemplateModal(false);
                  setTempSelectedTemplate(selectedTemplate);
                }}
                className="text-[#007aff] hover:opacity-70 transition-opacity"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <h2 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 -translate-x-1/2">
                Choose summary style
              </h2>
              <button
                onClick={() => {
                  setShowTemplateModal(false);
                  setTempSelectedTemplate(selectedTemplate);
                }}
                className="text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
              >
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                  <path d="M18 6L6 18M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Scrollable content */}
            <div className="flex-1 overflow-y-auto -mx-5 px-5">
              {/* Intro section */}
              <div className="mb-2.5 mt-0.5">
                <div className="text-[18px] mb-0.5">✨</div>
                <h3 className="text-[16px] font-bold text-[#1c1c1e] mb-0.5">
                  Choose how you'd like this summarized
                </h3>
                <p className="text-[13px] text-[#3c3c43] leading-[1.25]">
                  Pick a style that fits this recording.
                </p>
              </div>

              {/* Autopilot (Recommended) - Larger card */}
              <button
                onClick={() => setTempSelectedTemplate('autopilot')}
                className={`w-full bg-[#f9f9f9] rounded-[14px] p-2.5 mb-2.5 text-left border-2 transition-all ${
                  tempSelectedTemplate === 'autopilot' ? 'border-[#007aff] bg-[#f0f7ff]' : 'border-transparent'
                }`}
              >
                <div className="flex items-start gap-2.5">
                  <div className="w-7 h-7 rounded-full bg-[#f0f9ff] flex items-center justify-center flex-shrink-0">
                    <Sparkles className="w-4 h-4 text-[#007aff]" strokeWidth={2} />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-0.5">
                      <h3 className="text-[15px] font-semibold text-[#1c1c1e]">
                        Autopilot
                      </h3>
                      <span className="text-[10px] font-medium text-[#007aff] bg-[#e8f5ff] px-1.5 py-0.5 rounded-full">
                        Recommended
                      </span>
                    </div>
                    <p className="text-[12px] text-[#3c3c43] leading-[1.25]">
                      Let AI decide what's worth generating based on the content
                    </p>
                  </div>
                </div>
              </button>

              {/* Section divider */}
              <div className="flex items-center gap-3 mb-2 mt-2.5">
                <div className="h-px flex-1 bg-gradient-to-r from-transparent via-black/[0.1] to-transparent" />
                <span className="text-[12px] font-medium text-[#8e8e93]">Your styles</span>
                <div className="h-px flex-1 bg-gradient-to-r from-transparent via-black/[0.1] to-transparent" />
              </div>

              {/* Your styles section - Shows favorites if any, otherwise shows default templates */}
              {(() => {
                const favorites = JSON.parse(localStorage.getItem('favoriteSummaryStyles') || '[]');
                console.log('🔍 Favorites from localStorage:', favorites);
                
                // Helper function to get icon for style
                const getStyleIcon = (styleId: string) => {
                  const iconProps = { className: "w-4 h-4 text-[#007aff]", strokeWidth: 2 };
                  
                  switch (styleId) {
                    case 'autopilot':
                      return <Sparkles {...iconProps} />;
                    case 'meeting-secretary':
                    case 'meeting':
                      return <Users {...iconProps} />;
                    case 'sales-followup':
                    case 'sales':
                      return <Phone {...iconProps} />;
                    case 'project-sync':
                      return <Clipboard {...iconProps} />;
                    case 'learning-notes':
                    case 'learning':
                      return <BookOpen {...iconProps} />;
                    case 'adhd-friendly':
                    case 'adhd':
                      return <Brain {...iconProps} />;
                    case 'reflection-insights':
                      return <Lightbulb {...iconProps} />;
                    case 'interview-research':
                      return <Mic {...iconProps} />;
                    case 'investor-review':
                      return <Compass {...iconProps} />;
                    default:
                      return <Sparkles {...iconProps} />;
                  }
                };
                
                const allTemplates: Record<string, { emoji: string; title: string; description: string }> = {
                  autopilot: { emoji: '🤖', title: 'Autopilot', description: 'AI adapts to each memory' },
                  'meeting-secretary': { emoji: '🧑‍💼', title: 'Meeting secretary', description: 'Clear, structured meeting notes' },
                  'sales-followup': { emoji: '📞', title: 'Sales follow-up', description: 'Client needs, objections, next steps' },
                  'project-sync': { emoji: '📋', title: 'Project sync', description: 'Progress, blockers, timelines' },
                  'learning-notes': { emoji: '📚', title: 'Learning notes', description: 'Concepts, examples, personal takeaways' },
                  'adhd-friendly': { emoji: '🧠', title: 'ADHD-friendly', description: 'Extra structure, clarity, no overload' },
                  'reflection-insights': { emoji: '💡', title: 'Reflection', description: 'Patterns and insights' },
                  'interview-research': { emoji: '🎙', title: 'Interview', description: 'Key points and quotes' },
                  'investor-review': { emoji: '🧭', title: 'Decision review', description: 'Arguments and questions' },
                  // Legacy IDs for backward compatibility
                  meeting: { emoji: '🧑‍💼', title: 'Meeting secretary', description: 'Clear, structured meeting notes' },
                  sales: { emoji: '📞', title: 'Sales follow-up', description: 'Client needs, objections, next steps' },
                  learning: { emoji: '📚', title: 'Learning notes', description: 'Concepts, examples, personal takeaways' },
                  adhd: { emoji: '🧠', title: 'ADHD-friendly', description: 'Extra structure, clarity, no overload' },
                };

                // Default templates if no favorites (using new IDs)
                const defaultTemplateIds = ['meeting-secretary', 'sales-followup', 'learning-notes', 'adhd-friendly'];
                
                // Use favorites if they exist, otherwise use default templates
                const templatesToShow = favorites.length > 0 
                  ? favorites.filter((id: string) => id !== 'autopilot') // Exclude autopilot from favorites list
                  : defaultTemplateIds;
                
                console.log('📋 Templates to show:', templatesToShow);

                return (
                  <div className="space-y-1.5 mb-2.5">
                    {templatesToShow.map((templateId: string) => {
                      const template = allTemplates[templateId];
                      console.log(`🔎 Checking template: ${templateId}`, template ? '✅ Found' : '❌ NOT FOUND');
                      if (!template) return null;

                      return (
                        <button
                          key={templateId}
                          onClick={() => setTempSelectedTemplate(templateId)}
                          className={`w-full bg-[#f2f2f7] rounded-[12px] p-2.5 text-left border-2 transition-all relative ${
                            tempSelectedTemplate === templateId ? 'border-[#007aff] bg-[#f0f7ff]' : 'border-transparent'
                          }`}
                        >
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedTemplateForDetail(templateId);
                              setShowTemplateDetail(true);
                            }}
                            className="absolute top-2 right-2 w-6 h-6 flex items-center justify-center text-[#8e8e93] hover:text-[#007aff] transition-colors bg-white/80 rounded-full"
                          >
                            <Info className="w-4 h-4" strokeWidth={2} />
                          </button>
                          <div className="flex items-start gap-2 pr-8">
                            <div className="w-7 h-7 rounded-full bg-[#f0f9ff] flex items-center justify-center flex-shrink-0">
                              {getStyleIcon(templateId)}
                            </div>
                            <div>
                              <h3 className="text-[14px] font-semibold text-[#1c1c1e] mb-0.5">
                                {template.title}
                              </h3>
                              <p className="text-[12px] text-[#3c3c43] leading-[1.25]">
                                {template.description}
                              </p>
                            </div>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                );
              })()}

              {/* Divider */}
              <div className="flex items-center gap-3 mb-2 mt-2.5">
                <div className="h-px flex-1 bg-gradient-to-r from-transparent via-black/[0.1] to-transparent" />
              </div>

              {/* Browse all styles link */}
              <div className="mb-2.5">
                <p className="text-[13px] text-[#3c3c43] leading-[1.35] mb-1">
                  Looking for a specific role or style?
                </p>
                <button
                  onClick={() => {
                    setShowAISummaryStylePage(true);
                  }}
                  className="text-[13px] font-medium text-[#007aff] hover:opacity-70 transition-opacity"
                >
                  Browse all styles →
                </button>
              </div>
            </div>

            {/* Bottom CTA - Fixed at bottom */}
            <div className="pt-2">
              <button
                onClick={() => {
                  setShowTemplateModal(false);
                  setSelectedTemplate(tempSelectedTemplate);
                }}
                className="w-full bg-[#007aff] text-white text-[17px] font-semibold py-3 rounded-[14px] hover:bg-[#0051d5] transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                <Sparkles className="w-5 h-5" />
                <span>Use this style</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Template Detail Modal */}
      {showTemplateDetail && (
        <TemplateDetailModal
          templateId={selectedTemplateForDetail}
          onClose={() => setShowTemplateDetail(false)}
          onUseStyle={(styleId) => {
            setSelectedTemplate(styleId as 'autopilot' | 'meeting' | 'sales' | 'learning' | 'adhd');
            setTempSelectedTemplate(styleId as 'autopilot' | 'meeting' | 'sales' | 'learning' | 'adhd');
            setShowTemplateDetail(false);
            setShowTemplateModal(false);
          }}
        />
      )}

      {/* System Share Modal */}
      {showSystemShareModal && (
        <SystemShareModal
          isOpen={showSystemShareModal}
          onClose={() => setShowSystemShareModal(false)}
          shareUrl={`https://www.memopin.ai/memory/${memory.id}`}
          title="Audio Memory"
        />
      )}

      {/* AI Summary Style Page */}
      {showAISummaryStylePage && (
        <div className="fixed inset-0 z-[120] bg-[#f2f2f7]">
          <AISummaryStylePage
            onBack={() => {
              setShowAISummaryStylePage(false);
              // Reload default style when coming back
              const defaultStyle = localStorage.getItem('defaultSummaryStyle') || 'autopilot';
              setTempSelectedTemplate(defaultStyle);
            }}
            currentStyle={tempSelectedTemplate}
            onSelectStyle={(styleId) => {
              setTempSelectedTemplate(styleId);
            }}
            fromAudioMemory={true}
          />
        </div>
      )}
    </div>
  );
}

// AI Progress Step Component
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