import { ChevronLeft, Play, Pause, Sparkles, Mic, Smartphone, Share2, MoreVertical, Plus, Edit3, MessageCircle, ChevronRight, ChevronDown, FileText, Users, Phone, Clipboard, BookOpen, Brain, Lightbulb, Compass, Heart, CheckSquare, MessageSquare, Send, X, ArrowUp } from 'lucide-react';
import { useState, useEffect, useRef } from 'react';
import { AudioWaveform } from './AudioWaveform';
import { SystemShareModal } from './SystemShareModal';
import { NewTodoFromMemoModal } from './NewTodoFromMemoModal';
import { MarkSpeakerModal } from './MarkSpeakerModal';
import { ShareOptionsModal } from './ShareOptionsModal';
import { ShareContentSelectionModal } from './ShareContentSelectionModal';
import { MemoryOptionsModal } from './MemoryOptionsModal';
import { ManageProjectsModal } from './ManageProjectsModal';
import { AIChatModal } from './AIChatModal';
import { PersonDetail } from './PersonDetail';

interface MemoryDetailProps {
  memory: any;
  onClose: () => void;
  onSaveTodo?: (todo: any) => void;
  onGenerateResummary?: () => void;
  onCreateProject?: (project: { id: string; name: string; memoryId: number | null }) => void;
  allProjects?: { id: string; name: string }[];
  linkedProjectIds?: string[];
  onUpdateLinkedProjects?: (memoryId: number, projectIds: string[]) => void;
  initialTab?: TabType;  // Optional: initial tab to show
  highlightTimestamp?: string;  // Optional: timestamp to highlight and scroll to
}

type TabType = 'Overview' | 'Transcript' | 'Actions';

export function MemoryDetail({ memory, onClose, onSaveTodo, onGenerateResummary, onCreateProject, allProjects = [], linkedProjectIds = [], onUpdateLinkedProjects, initialTab, highlightTimestamp }: MemoryDetailProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [showShareContentModal, setShowShareContentModal] = useState(false);
  const [showShareOptionsModal, setShowShareOptionsModal] = useState(false);
  const [showMemoryOptionsModal, setShowMemoryOptionsModal] = useState(false);
  const [activeTab, setActiveTab] = useState<TabType>(initialTab || 'Overview');
  const [showSystemShareModal, setShowSystemShareModal] = useState(false);
  const [showCreateTodoModal, setShowCreateTodoModal] = useState(false);
  const [selectedAction, setSelectedAction] = useState<any>(null);
  const [showMarkSpeakerModal, setShowMarkSpeakerModal] = useState(false);
  const [showResummaryModal, setShowResummaryModal] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('autopilot');
  const [showAIChatModal, setShowAIChatModal] = useState(false);
  const [showAddMemoModal, setShowAddMemoModal] = useState(false);
  const [memoText, setMemoText] = useState('');
  const [isRecordingMemo, setIsRecordingMemo] = useState(false);
  const [isTranscribingMemo, setIsTranscribingMemo] = useState(false);
  const [showPersonDetail, setShowPersonDetail] = useState(false);
  const [selectedPersonName, setSelectedPersonName] = useState<string>('');
  const [showManageProjectsModal, setShowManageProjectsModal] = useState(false);
  
  // Quick input states (matching MemoryActivityFlow)
  const [quickInputText, setQuickInputText] = useState('');
  const [quickInputMode, setQuickInputMode] = useState<'note' | 'todo' | 'ask' | null>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const quickInputRef = useRef<HTMLTextAreaElement>(null);
  
  // Auto-resize textarea when quickInputText changes
  useEffect(() => {
    if (quickInputRef.current) {
      quickInputRef.current.style.height = 'auto';
      quickInputRef.current.style.height = Math.min(quickInputRef.current.scrollHeight, 120) + 'px';
    }
  }, [quickInputText]);
  
  // Convert props to projects format for ManageProjectsModal
  const projects = allProjects.map(p => ({
    ...p,
    isLinked: linkedProjectIds.includes(p.id)
  }));
  
  // Load chat messages from localStorage for this specific memory
  const [chatMessages, setChatMessages] = useState<any[]>(() => {
    const stored = localStorage.getItem(`memory-chat-${memory.id}`);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch (e) {
        return [];
      }
    }
    return [];
  });
  
  // Edit speaker name modal state
  const [showEditSpeakerModal, setShowEditSpeakerModal] = useState(false);
  const [editingSpeakerIndex, setEditingSpeakerIndex] = useState<number | null>(null);
  const [editingSpeakerName, setEditingSpeakerName] = useState('');
  const [newSpeakerName, setNewSpeakerName] = useState('');
  const [applyToAllSameSpeaker, setApplyToAllSameSpeaker] = useState(false);
  const [tempSelectedTemplate, setTempSelectedTemplate] = useState<string>('autopilot');
  const [isGeneratingResummary, setIsGeneratingResummary] = useState(false);
  const [showTemplateModal, setShowTemplateModal] = useState(false);
  const [favoriteStyles, setFavoriteStyles] = useState<string[]>([]);
  
  // Remove old segment playback states - now unified with main player
  // const [playingSegmentIndex, setPlayingSegmentIndex] = useState<number | null>(null);
  // const [isSegmentPlaying, setIsSegmentPlaying] = useState(false);
  
  // Load default style on mount - prioritize last used style
  useEffect(() => {
    const lastUsedStyle = localStorage.getItem('lastUsedSummaryStyle');
    const defaultStyle = localStorage.getItem('defaultSummaryStyle');
    const styleToUse = lastUsedStyle || defaultStyle || 'autopilot';
    setSelectedTemplate(styleToUse);
    setTempSelectedTemplate(styleToUse);
  }, []);
  
  // Load favorite styles when template modal opens
  useEffect(() => {
    if (showTemplateModal) {
      const favorites = JSON.parse(localStorage.getItem('favoriteSummaryStyles') || '[]');
      setFavoriteStyles(favorites);
    }
  }, [showTemplateModal]);
  
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

  const totalSeconds = parseDuration(memory.audioDuration || '15m26s');
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

  // Quick input handlers (matching MemoryActivityFlow)
  const handleQuickAdd = () => {
    if (!quickInputText.trim() || !quickInputMode) return;

    if (quickInputMode === 'todo') {
      // Create todo
      onSaveTodo?.({
        title: quickInputText,
        priority: 'Medium',
        dueDate: 'No deadline',
        linkedMemory: {
          id: memory.id.toString(),
          title: memory.title
        }
      });
      alert('✓ Todo added!');
    } else if (quickInputMode === 'note') {
      // Save memo
      alert('✓ Memo saved!');
    } else if (quickInputMode === 'ask') {
      // Open AI chat with the question
      setShowAIChatModal(true);
    }

    setQuickInputText('');
    setQuickInputMode(null);
    setIsRecording(false);
    setIsTranscribing(false);
  };

  const handleStartRecording = () => {
    setIsRecording(true);
  };

  const handleSendVoice = () => {
    setIsRecording(false);
    setIsTranscribing(true);
    
    // Simulate voice transcription
    setTimeout(() => {
      let transcribedText = '';
      if (quickInputMode === 'todo') {
        transcribedText = "Review API migration timeline and coordinate with infrastructure team";
      } else if (quickInputMode === 'note') {
        transcribedText = "Important discussion about authentication service dependencies and potential risks during migration phase";
      } else {
        transcribedText = "What were the main action items discussed in this conversation?";
      }
      setQuickInputText(transcribedText);
      setIsTranscribing(false);
    }, 1500);
  };

  const handleCancelRecording = () => {
    setIsRecording(false);
  };

  const circleRadius = 24;
  const circumference = 2 * Math.PI * circleRadius;
  const strokeDashoffset = circumference - (progress / 100) * circumference;

  // Mock data
  const [transcriptData, setTranscriptData] = useState([
    { speaker: 'Alex', time: '00:00', text: 'Alright, so we just walked into the main hall. This place is massive.' },
    { speaker: 'Sarah', time: '00:15', text: 'Yeah, I was looking at the map earlier. There\'s no way we\'re seeing everything today.' },
    { speaker: 'Alex', time: '00:22', text: 'Agreed. I think we should focus on the innovation zone first, then hit the consumer electronics section.' },
    { speaker: 'Sarah', time: '00:35', text: 'Sounds good. Oh, interesting observation - a lot of booths this year aren\'t leading with AI.' },
    { speaker: 'Alex', time: '00:45', text: 'Right? I noticed that too. It\'s like they\'ve moved past the "everything is AI" phase.' },
    { speaker: 'Unidentified', time: '01:02', text: 'This coffee maker completes cold brew in 5 minutes instead of 12 hours.' },
    { speaker: 'Unidentified', time: '01:10', text: 'We use a special pressure system combined with precise temperature control.' },
    { speaker: 'Sarah', time: '01:15', text: 'Wait, that\'s actually impressive. How does it work?' },
    { speaker: 'Unidentified', time: '01:22', text: 'The taste profile is very close to traditional cold brew, but you can customize the strength.' },
    { speaker: 'Alex', time: '01:28', text: 'The demo looked good, but I wonder about the taste compared to traditional cold brew.' },
    { speaker: 'Sarah', time: '01:45', text: 'Should we grab their info? This could be interesting for the office.' },
    { speaker: 'Alex', time: '01:52', text: 'Yeah, definitely. Let me take a photo of their booth.' },
    { speaker: 'Sarah', time: '02:05', text: 'Check this out - infrared fall detection for elderly care.' },
    { speaker: 'Unidentified', time: '02:12', text: 'The system can detect falls within 0.3 seconds and automatically alert caregivers.' },
    { speaker: 'Sarah', time: '02:14', text: 'I think this technology could be really useful for aging populations. We should definitely explore this further for our healthcare product line.' },
    { speaker: 'Alex', time: '02:18', text: 'That could be really valuable, especially for reducing emergency response times.' },
    { speaker: 'Unidentified', time: '02:25', text: 'We\'ve already deployed this in over 200 care facilities across Europe.' },
    { speaker: 'Sarah', time: '02:30', text: 'True, though they\'ll need to prove it works reliably in real-world conditions.' },
    { speaker: 'Alex', time: '02:42', text: 'I\'m curious about the false positive rate. That would be critical for adoption.' },
    { speaker: 'Unidentified', time: '02:50', text: 'Our false positive rate is below 2%, and we\'re constantly improving the AI model.' },
    { speaker: 'Sarah', time: '03:05', text: 'Impressive. We should connect with them before the end of the day.' },
    { speaker: 'Alex', time: '03:12', text: 'Agreed. Let\'s grab lunch first though, I\'m starving.' },
  ]);

  // Calculate speakers dynamically from transcript
  const speakers = Array.from(new Set(transcriptData.map(item => item.speaker)));
  
  // Dynamic key takeaways based on memory ID
  const getKeyTakeaways = () => {
    switch (memory.id) {
      case 1: // Team standup discussion on API migration
        return [
          'Migrating legacy API to new microservices architecture',
          'Phased approach agreed, starting with authentication service',
          'Timeline discussed with team alignment on execution plan'
        ];
      case 2: // Coffee chat with Alex about product strategy
        return [
          'Explored differentiation strategies in competitive market',
          'Alex suggested focusing on neurodivergent user experience',
          'Unique positioning opportunity identified for product'
        ];
      case 7: // Product launch planning with marketing team
        return [
          'Go-to-market strategy finalized for Q2 product release',
          'Three-phase rollout: beta users → influencer partnerships → public launch',
          'Team aligned on launch timeline and execution approach'
        ];
      case 8: // Investor meeting - Series A funding discussion
        return [
          'Presented growth metrics and Q1 achievements to lead investor',
          'Strong interest expressed in user retention numbers',
          'Detailed questions about unit economics and business model'
        ];
      case 4: // Client feedback call about new dashboard features
        return [
          'Client praised new data visualization features',
          'More customization options requested for reports',
          'Export functionality needs to be prioritized'
        ];
      case 5: // Weekly review and planning
        return [
          'Q1 goals reviewed - mostly on track',
          'Mobile app development behind schedule',
          'Frontend team needs more resources'
        ];
      default:
        return [
          'Key discussion points captured',
          'Action items identified',
          'Follow-up scheduled'
        ];
    }
  };
  
  const keyTakeaways = getKeyTakeaways();

  // Use memory.summary as full summary text
  const fullSummaryText = memory.summary || 'No summary available for this memory.';

  // Dynamic suggested actions based on memory ID
  const getSuggestedActionsData = () => {
    switch (memory.id) {
      case 1: // Team standup discussion on API migration
        return [
          { id: 1, text: 'Review migration milestones with infrastructure team', todoCreated: false },
          { id: 2, text: 'Schedule authentication service testing session', todoCreated: false },
          { id: 3, text: 'Document rollout risks and mitigation strategies', todoCreated: false },
        ];
      case 2: // Coffee chat with Alex about product strategy
        return [
          { id: 1, text: 'Research neurodivergent user needs and pain points', todoCreated: false },
          { id: 2, text: 'Schedule follow-up meeting with Alex to explore positioning', todoCreated: false },
          { id: 3, text: 'Draft positioning statement focused on neurodivergent users', todoCreated: false },
        ];
      case 7: // Product launch planning with marketing team
        return [
          { id: 1, text: 'Create detailed timeline for three-phase rollout', todoCreated: false },
          { id: 2, text: 'Identify and reach out to potential influencer partners', todoCreated: false },
          { id: 3, text: 'Prepare beta user onboarding materials', todoCreated: false },
        ];
      case 8: // Investor meeting - Series A funding
        return [
          { id: 1, text: 'Prepare detailed unit economics breakdown for follow-up', todoCreated: false },
          { id: 2, text: 'Send thank you email with additional retention data', todoCreated: false },
          { id: 3, text: 'Schedule next meeting to discuss terms', todoCreated: false },
        ];
      case 4: // Client feedback call
        return [
          { id: 1, text: 'Prioritize Excel export functionality for next sprint', todoCreated: false },
          { id: 2, text: 'Design mockups for report customization options', todoCreated: false },
          { id: 3, text: 'Schedule follow-up demo after features are implemented', todoCreated: false },
        ];
      case 5: // Weekly review and planning
        return [
          { id: 1, text: 'Allocate frontend developer to mobile team', todoCreated: false },
          { id: 2, text: 'Research Android contractor availability', todoCreated: false },
          { id: 3, text: 'Update Q1 timeline with revised mobile delivery date', todoCreated: false },
        ];
      default:
        return [
          { id: 1, text: 'Review key discussion points', todoCreated: false },
          { id: 2, text: 'Follow up with mentioned action items', todoCreated: false },
          { id: 3, text: 'Schedule next check-in', todoCreated: false },
        ];
    }
  };
  
  const [suggestedActions, setSuggestedActions] = useState(getSuggestedActionsData());

  // Parse time string (e.g., "0:20" or "1:05") to seconds
  const parseTimeToSeconds = (timeStr: string): number => {
    const parts = timeStr.split(':');
    const minutes = parseInt(parts[0]);
    const seconds = parseInt(parts[1]);
    return minutes * 60 + seconds;
  };

  // Get current playing segment index based on currentTime
  const getCurrentSegmentIndex = (): number | null => {
    for (let i = 0; i < transcriptData.length; i++) {
      const startTime = parseTimeToSeconds(transcriptData[i].time);
      const endTime = i < transcriptData.length - 1 
        ? parseTimeToSeconds(transcriptData[i + 1].time)
        : totalSeconds;
      
      if (currentTime >= startTime && currentTime < endTime) {
        return i;
      }
    }
    return null;
  };

  const currentSegmentIndex = getCurrentSegmentIndex();

  // Handle segment playback - unified with main audio player
  const handleSegmentPlayback = (index: number) => {
    const segmentTime = parseTimeToSeconds(transcriptData[index].time);
    handleSeek(segmentTime);
    setIsPlaying(true);
  };

  // Handle edit speaker name
  const handleEditSpeaker = (index: number, currentSpeaker: string) => {
    setEditingSpeakerIndex(index);
    setEditingSpeakerName(currentSpeaker);
    setNewSpeakerName(currentSpeaker);
    setApplyToAllSameSpeaker(false);
    setShowEditSpeakerModal(true);
  };

  // Handle save speaker name
  const handleSaveSpeakerName = () => {
    if (!newSpeakerName.trim() || editingSpeakerIndex === null) return;

    if (applyToAllSameSpeaker) {
      // Update all segments with the same speaker name
      const updatedTranscript = transcriptData.map((item) => {
        if (item.speaker === editingSpeakerName) {
          return { ...item, speaker: newSpeakerName.trim() };
        }
        return item;
      });
      setTranscriptData(updatedTranscript);
    } else {
      // Update only the selected segment
      const updatedTranscript = [...transcriptData];
      updatedTranscript[editingSpeakerIndex] = {
        ...updatedTranscript[editingSpeakerIndex],
        speaker: newSpeakerName.trim()
      };
      setTranscriptData(updatedTranscript);
    }

    // Close modal and reset state
    setShowEditSpeakerModal(false);
    setEditingSpeakerIndex(null);
    setEditingSpeakerName('');
    setNewSpeakerName('');
    setApplyToAllSameSpeaker(false);
  };

  // Auto-scroll to current segment when switching to Transcript tab
  useEffect(() => {
    if (activeTab === 'Transcript' && currentSegmentIndex !== null && isPlaying) {
      const segmentElement = document.getElementById(`transcript-segment-${currentSegmentIndex}`);
      if (segmentElement) {
        segmentElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    }
  }, [activeTab, currentSegmentIndex, isPlaying]);

  // Auto-scroll to highlighted timestamp when component mounts with highlightTimestamp
  useEffect(() => {
    if (activeTab === 'Transcript' && highlightTimestamp) {
      // Small delay to ensure DOM is rendered
      setTimeout(() => {
        const targetIndex = transcriptData.findIndex(item => item.time === highlightTimestamp);
        if (targetIndex !== -1) {
          const segmentElement = document.getElementById(`transcript-segment-${targetIndex}`);
          if (segmentElement) {
            segmentElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
            // Add a highlight effect
            segmentElement.style.backgroundColor = 'rgba(255, 149, 0, 0.15)';
            setTimeout(() => {
              segmentElement.style.transition = 'background-color 2s ease';
              segmentElement.style.backgroundColor = '';
            }, 1500);
          }
        }
      }, 300);
    }
  }, [activeTab, highlightTimestamp, transcriptData]);

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] z-[60] flex flex-col">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
        <button 
          onClick={onClose}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-7 h-7" strokeWidth={2} />
        </button>
        
        <h1 className="absolute left-1/2 transform -translate-x-1/2 text-[17px] font-semibold text-[#1c1c1e]">
          Memory
        </h1>
        
        {/* Right side buttons */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowShareContentModal(true)}
            className="p-2 hover:bg-[#f2f2f7] rounded-full transition-colors"
          >
            <Share2 className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
          </button>
          
          <button
            onClick={() => setShowMemoryOptionsModal(true)}
            className="p-2 hover:bg-[#f2f2f7] rounded-full transition-colors"
          >
            <MoreVertical className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
          </button>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto pb-20">
        {/* Title Section */}
        <div className="px-5 pt-6 pb-4">
          <h2 className="text-[24px] font-bold text-[#1c1c1e] mb-2">
            {memory.title}
          </h2>
          <div className="flex flex-wrap items-center gap-2 text-[15px] text-[#8e8e93]">
            <span>Jan 21, 2026</span>
            <span>·</span>
            <span>Las Vegas</span>
            <span>·</span>
            <span>15 min</span>
            <span>·</span>
            <div className="flex items-center gap-1">
              <Mic className="w-3.5 h-3.5" />
              <span>MemoPin</span>
            </div>
          </div>
        </div>

        {/* Audio Player - Compact inline layout */}
        <div className="px-5 pt-2 pb-4">
          {/* Time display */}
          <div className="flex justify-between mb-2 text-[15px]">
            <span className="font-medium text-[#1c1c1e]">{formatTime(currentTime)}</span>
            <span className="text-[#8e8e93]">15:26</span>
          </div>

          {/* Waveform and Play button in one row */}
          <div className="flex items-center gap-3">
            {/* Waveform - takes most space */}
            <div className="flex-1 bg-[#f2f2f7] rounded-lg overflow-hidden h-12">
              <AudioWaveform 
                duration="15m26s"
                isPlaying={isPlaying}
                currentTime={currentTime}
                totalSeconds={totalSeconds}
                onSeek={handleSeek}
              />
            </div>

            {/* Play/Pause button - compact with progress ring */}
            <div className="relative flex-shrink-0">
              {/* Circular progress ring */}
              <svg 
                className="absolute inset-0 -rotate-90 pointer-events-none" 
                width="56" 
                height="56"
              >
                <circle cx="28" cy="28" r="24" stroke="#e5e5ea" strokeWidth="2.5" fill="none" />
                <circle
                  cx="28" cy="28" r="24"
                  stroke="#1c1c1e" strokeWidth="2.5" fill="none"
                  strokeDasharray={circumference}
                  strokeDashoffset={strokeDashoffset}
                  strokeLinecap="round"
                  className="transition-all duration-300"
                />
              </svg>
              
              {/* Play button */}
              <button
                onClick={() => setIsPlaying(!isPlaying)}
                className="relative z-10 w-14 h-14 rounded-full bg-white flex items-center justify-center hover:bg-[#f9f9f9] transition-colors shadow-sm border border-black/[0.06]"
              >
                {isPlaying ? (
                  <Pause className="w-5 h-5 text-[#1c1c1e]" fill="#1c1c1e" />
                ) : (
                  <Play className="w-5 h-5 text-[#1c1c1e] ml-0.5" fill="#1c1c1e" />
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Speakers */}
        {speakers.filter(speaker => speaker !== 'Unidentified').length > 0 && (
          <div className="px-5 pb-4">
            <div className="text-[13px] text-[#8e8e93] mb-2 font-medium">Speakers</div>
            <div className="flex flex-wrap gap-2">
              {speakers
                .filter(speaker => speaker !== 'Unidentified')
                .map((speaker, idx) => (
                  <button
                    key={idx}
                    onClick={() => {
                      setSelectedPersonName(speaker);
                      setShowPersonDetail(true);
                    }}
                    className="px-3 py-1.5 bg-[#f2f2f7] border border-[#e5e5ea] rounded-full text-[14px] text-[#1c1c1e] cursor-pointer hover:bg-[#e5e5ea] hover:border-[#d1d1d6] active:bg-[#d1d1d6] transition-colors"
                  >
                    <span>{speaker}</span>
                  </button>
                ))}
            </div>
          </div>
        )}

        {/* Separator */}
        <div className="relative h-px mx-5 my-4">
          <div className="absolute inset-0 bg-gradient-to-r from-transparent via-black/[0.08] to-transparent"></div>
        </div>

        {/* Tabs */}
        <div className="px-5 pb-3">
          <div className="flex gap-1 bg-[#f2f2f7] rounded-[12px] p-1">
            {(['Overview', 'Transcript', 'Actions'] as TabType[]).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`flex-1 px-3 py-2 rounded-[10px] text-[14px] font-medium transition-all ${
                  activeTab === tab
                    ? 'bg-white text-[#1c1c1e] shadow-sm'
                    : 'text-[#8e8e93]'
                }`}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>

        {/* Tab Content - Overview */}
        {activeTab === 'Overview' && (
          <div className="px-5 pb-6">
            {/* Key Takeaways */}
            <div className="mb-5">
              <div className="flex items-center gap-2 mb-3">
                <Sparkles className="w-5 h-5 text-[#007aff]" />
                <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Key Takeaways</h3>
              </div>
              <ul className="space-y-2">
                {keyTakeaways.map((item, idx) => (
                  <li key={idx} className="flex gap-2 text-[15px] text-[#1c1c1e] leading-[1.5]">
                    <span className="text-[#8e8e93] mt-0.5">•</span>
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* Conversation Context */}
            <div className="mb-5">
              <h4 className="text-[15px] font-semibold text-[#1c1c1e] mb-3">Conversation Context</h4>
              <div className="space-y-3">
                <div>
                  <span className="text-[13px] font-medium text-[#8e8e93]">Event:</span>
                  <p className="text-[15px] text-[#1c1c1e] mt-0.5">CES 2026 exhibition discussion</p>
                </div>
                <div>
                  <span className="text-[13px] font-medium text-[#8e8e93]">Timing:</span>
                  <p className="text-[15px] text-[#1c1c1e] mt-0.5">Day 1 product exploration</p>
                </div>
                <div>
                  <span className="text-[13px] font-medium text-[#8e8e93]">Format:</span>
                  <p className="text-[15px] text-[#1c1c1e] mt-0.5">Walk-and-record conversation</p>
                </div>
                <div className="pt-1">
                  <span className="text-[13px] font-medium text-[#8e8e93]">Goal:</span>
                  <p className="text-[15px] text-[#1c1c1e] mt-0.5 leading-[1.5]">
                    Evaluate differentiation opportunities and reassess positioning in a crowded AI hardware market.
                  </p>
                </div>
              </div>
            </div>

            {/* Key Discussion Topics */}
            <div className="mb-5">
              <h4 className="text-[15px] font-semibold text-[#1c1c1e] mb-3">Key Discussion Topics</h4>
              <ul className="space-y-2 text-[15px] text-[#1c1c1e] leading-[1.5]">
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>Exhibition halls & city experiences influenced perception of products</span>
                </li>
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>Innovative product interactions and user engagement patterns observed</span>
                </li>
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>AI is no longer the sole selling point — usability and authenticity matter</span>
                </li>
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>Data authenticity and practical implementation seen as key advantages</span>
                </li>
              </ul>
            </div>

            {/* Decisions & Directions */}
            <div className="mb-5">
              <h4 className="text-[15px] font-semibold text-[#1c1c1e] mb-3">Decisions & Directions</h4>
              <ul className="space-y-2 text-[15px] text-[#1c1c1e] leading-[1.5]">
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>Consider neurodivergent-focused UX as a differentiation strategy</span>
                </li>
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>Position product around real-life usability rather than AI novelty</span>
                </li>
              </ul>
            </div>

            {/* Ideas & Opportunities */}
            <div className="mb-5">
              <h4 className="text-[15px] font-semibold text-[#1c1c1e] mb-3">Ideas & Opportunities</h4>
              <ul className="space-y-2 text-[15px] text-[#1c1c1e] leading-[1.5]">
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>Explore onboarding optimized for neurodivergent users</span>
                </li>
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>Build narrative around practical usage and reliability</span>
                </li>
                <li className="flex gap-2">
                  <span className="text-[#8e8e93] mt-0.5">•</span>
                  <span>Study competitor gaps in user experience positioning</span>
                </li>
              </ul>
            </div>
          </div>
        )}

        {/* Tab Content - Transcript */}
        {activeTab === 'Transcript' && (
          <div className="px-5 pb-6">
            <div className="space-y-3">
              {transcriptData.map((item, idx) => {
                const isCurrentSegment = currentSegmentIndex === idx;
                const isCurrentPlaying = isCurrentSegment && isPlaying;
                
                return (
                  <div 
                    key={idx} 
                    id={`transcript-segment-${idx}`}
                    onClick={() => {
                      // If clicking the currently playing segment, toggle pause/play
                      if (isCurrentSegment && isPlaying) {
                        setIsPlaying(false);
                      } else {
                        handleSegmentPlayback(idx);
                      }
                    }}
                    className={`flex gap-3 rounded-[10px] p-2.5 -mx-2.5 transition-all cursor-pointer ${
                      isCurrentSegment 
                        ? 'bg-[#f0f7ff] border border-[#007aff]/20' 
                        : 'hover:bg-[#f9f9f9]'
                    }`}
                  >
                    <div className="flex-shrink-0 w-12 text-[13px] text-[#8e8e93] font-medium pt-0.5">
                      {item.time}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span 
                          onClick={(e) => {
                            e.stopPropagation();
                            handleEditSpeaker(idx, item.speaker);
                          }}
                          className={`text-[14px] font-semibold cursor-pointer hover:opacity-70 transition-opacity ${
                            isCurrentSegment ? 'text-[#007aff]' : 'text-[#007aff]'
                          }`}
                        >
                          {item.speaker}
                        </span>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleEditSpeaker(idx, item.speaker);
                          }}
                          className="flex-shrink-0 p-0.5 rounded-full bg-[#f2f2f7] text-[#8e8e93] hover:bg-[#e5e5ea] transition-colors"
                          title="Edit speaker name"
                        >
                          <Edit3 className="w-3 h-3" strokeWidth={2} />
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            // Toggle pause/play if currently playing this segment
                            if (isCurrentSegment && isPlaying) {
                              setIsPlaying(false);
                            } else {
                              handleSegmentPlayback(idx);
                            }
                          }}
                          className={`flex-shrink-0 p-0.5 rounded-full transition-colors ${
                            isCurrentSegment 
                              ? 'bg-[#007aff] text-white' 
                              : 'bg-[#f2f2f7] text-[#8e8e93] hover:bg-[#e5e5ea]'
                          }`}
                        >
                          {isCurrentPlaying ? (
                            <Pause className="w-3 h-3" fill="currentColor" strokeWidth={0} />
                          ) : (
                            <Play className="w-3 h-3 ml-[1px]" fill="currentColor" strokeWidth={0} />
                          )}
                        </button>
                      </div>
                      <p className={`text-[15px] leading-[1.5] ${
                        isCurrentSegment ? 'text-[#1c1c1e] font-medium' : 'text-[#1c1c1e]'
                      }`}>
                        {item.text}
                      </p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Tab Content - Actions */}
        {activeTab === 'Actions' && (
          <div className="px-5 pb-6">
            <p className="text-[14px] text-[#8e8e93] mb-4">
              Possible follow-ups (suggested by AI)
            </p>
            <div className="space-y-2.5">
              {suggestedActions.map((action) => (
                <div
                  key={action.id}
                  className="bg-[#fafafa] rounded-[12px] p-4 border border-black/[0.04]"
                >
                  <p className="text-[15px] text-[#1c1c1e] leading-[1.5] mb-3">
                    {action.text}
                  </p>
                  {action.todoCreated ? (
                    <div className="text-[14px] text-[#34c759] font-medium flex items-center gap-1.5">
                      <span>Todo created</span>
                    </div>
                  ) : (
                    <button 
                      onClick={() => {
                        setSelectedAction(action);
                        setShowCreateTodoModal(true);
                      }}
                      className="px-4 py-2 bg-gradient-to-br from-[#e8f5f1] via-white to-[#f0f9f6] rounded-[10px] text-[14px] text-[#2d5a47] font-semibold border border-[#2d5a47]/15 hover:shadow-md transition-all active:scale-[0.98] flex items-center gap-1.5"
                    >
                      <Plus className="w-4 h-4" strokeWidth={2.5} />
                      <span>Create Todo</span>
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Separator */}
        <div className="relative h-px mx-5 my-4">
          <div className="absolute inset-0 bg-gradient-to-r from-transparent via-black/[0.08] to-transparent"></div>
        </div>
      </div>

      {/* Bottom Quick Input Area - Three buttons */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-black/[0.06] px-5 py-4">
        {!quickInputMode ? (
          <div className="flex gap-2">
            <button
              onClick={() => setQuickInputMode('todo')}
              className="flex-1 bg-[#2d5a47] text-white rounded-xl py-3 font-medium text-[15px] hover:bg-[#234537] transition-colors flex items-center justify-center gap-2"
            >
              <CheckSquare className="w-4 h-4" />
              <span>Add Todo</span>
            </button>
            <button
              onClick={() => setQuickInputMode('note')}
              className="flex-1 bg-[#007aff] text-white rounded-xl py-3 font-medium text-[15px] hover:bg-[#0051d5] transition-colors flex items-center justify-center gap-2"
            >
              <Edit3 className="w-4 h-4" />
              <span>Add Memo</span>
            </button>
            <button
              onClick={() => setQuickInputMode('ask')}
              className="flex-1 bg-[#34c759] text-white rounded-xl py-3 font-medium text-[15px] hover:bg-[#2da84a] transition-colors flex items-center justify-center gap-2"
            >
              <MessageSquare className="w-4 h-4" />
              <span>Ask AI</span>
            </button>
          </div>
        ) : (
          <div className="space-y-3">
            <div className="flex items-center justify-between mb-2">
              <span className="text-[13px] font-semibold uppercase tracking-wide text-[#8e8e93]">
                {quickInputMode === 'todo' ? 'Add Todo' : quickInputMode === 'note' ? 'Add Memo' : 'Ask AI'}
              </span>
              <button
                onClick={() => {
                  setQuickInputMode(null);
                  setQuickInputText('');
                  setIsRecording(false);
                  setIsTranscribing(false);
                }}
                className="text-[#ff3b30] text-[15px] font-medium"
              >
                Cancel
              </button>
            </div>
            
            {!isRecording && !isTranscribing ? (
              <div className="flex gap-2">
                <textarea
                  ref={quickInputRef}
                  value={quickInputText}
                  onChange={(e) => setQuickInputText(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                      e.preventDefault();
                      handleQuickAdd();
                    }
                  }}
                  placeholder={
                    quickInputMode === 'todo'
                      ? 'What needs to be done?'
                      : quickInputMode === 'note'
                      ? 'Write a note...'
                      : 'Ask AI anything...'
                  }
                  rows={1}
                  className="flex-1 bg-[#f2f2f7] rounded-xl px-4 py-3 text-[15px] focus:outline-none focus:ring-2 focus:ring-[#007aff] resize-none overflow-hidden"
                  style={{ 
                    minHeight: '44px',
                    maxHeight: '120px'
                  }}
                  onInput={(e) => {
                    const target = e.target as HTMLTextAreaElement;
                    target.style.height = 'auto';
                    target.style.height = Math.min(target.scrollHeight, 120) + 'px';
                  }}
                  autoFocus
                />
                <button
                  className="bg-[#f2f2f7] text-[#1c1c1e] rounded-xl px-4 py-3 font-medium text-[15px] hover:bg-[#e5e5ea] transition-colors flex items-center justify-center"
                  onClick={handleStartRecording}
                >
                  <Mic className="w-4.5 h-4.5" />
                </button>
                <button
                  onClick={handleQuickAdd}
                  disabled={!quickInputText.trim()}
                  className="bg-[#007aff] text-white rounded-xl px-5 py-3 font-medium text-[15px] hover:bg-[#0051d5] transition-colors disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center"
                >
                  <Send className="w-4 h-4" />
                </button>
              </div>
            ) : isRecording ? (
              <div className="flex items-center gap-3">
                <button 
                  onClick={handleCancelRecording}
                  className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors flex-shrink-0"
                >
                  <X className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2.5} />
                </button>
                <div className="flex-1 flex items-center justify-center gap-1.5 px-4 py-3 bg-[#ff3b30]/10 rounded-xl">
                  {[...Array(20)].map((_, i) => (
                    <div
                      key={i}
                      className="w-1 bg-[#007aff] rounded-full animate-pulse"
                      style={{
                        height: `${Math.random() * 12 + 12}px`,
                        animationDelay: `${i * 50}ms`,
                        animationDuration: '1s'
                      }}
                    />
                  ))}
                </div>
                <button 
                  onClick={handleSendVoice}
                  className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors flex-shrink-0"
                >
                  <ArrowUp className="w-5 h-5 text-white" strokeWidth={2.5} />
                </button>
              </div>
            ) : (
              <div className="flex items-center gap-2.5 px-4 py-3 bg-[#f2f2f7] rounded-xl">
                <div className="flex items-center gap-1">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '0ms' }}></div>
                  <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '150ms' }}></div>
                  <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '300ms' }}></div>
                </div>
                <span className="text-[15px] text-[#8e8e93]">Transcribing...</span>
              </div>
            )}
          </div>
        )}
      </div>

      {/* System Share Modal */}
      {showSystemShareModal && (
        <SystemShareModal
          isOpen={showSystemShareModal}
          onClose={() => setShowSystemShareModal(false)}
          shareUrl={`https://www.memopin.ai/memory/${memory.id}`}
          title="Memory"
        />
      )}

      {/* New Todo From Memo Modal */}
      {showCreateTodoModal && selectedAction && (
        <NewTodoFromMemoModal
          isOpen={showCreateTodoModal}
          onClose={() => {
            setShowCreateTodoModal(false);
            setSelectedAction(null);
          }}
          onSaveTodo={(todo) => {
            onSaveTodo?.(todo);
            // Mark this action as having a todo created
            setSuggestedActions(suggestedActions.map(a => 
              a.id === selectedAction.id ? { ...a, todoCreated: true } : a
            ));
            setShowCreateTodoModal(false);
            setSelectedAction(null);
          }}
          action={selectedAction}
          memory={{
            id: memory.id.toString(),
            title: memory.title,
            date: 'Jan 21',
            duration: '15 min',
            hasSummary: true
          }}
        />
      )}

      {/* Mark Speaker Modal */}
      {showMarkSpeakerModal && (
        <MarkSpeakerModal
          isOpen={showMarkSpeakerModal}
          onClose={() => setShowMarkSpeakerModal(false)}
          transcriptData={transcriptData}
          onSave={(speakerName: string, selectedLines: number[]) => {
            // Update transcript with new speaker name
            const updatedTranscript = transcriptData.map((item, index) => {
              if (selectedLines.includes(index)) {
                return { ...item, speaker: speakerName };
              }
              return item;
            });
            setTranscriptData(updatedTranscript);
            setShowMarkSpeakerModal(false);
          }}
        />
      )}

      {/* Share Content Selection Modal (Step 1) */}
      <ShareContentSelectionModal
        isOpen={showShareContentModal}
        onClose={() => setShowShareContentModal(false)}
        onContinue={(selectedSummaryId, selectedContent) => {
          // Close content selection modal and open share options modal
          setShowShareContentModal(false);
          setShowShareOptionsModal(true);
        }}
        summaryVersions={[
          {
            id: 'original',
            styleId: 'autopilot',
            timestamp: memory.date || new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
            isLatest: true,
            isOriginal: true
          }
        ]}
        expertInsights={[]}
        showTodos={false}
        showMemos={false}
      />

      {/* Share Options Modal - Using unified component */}
      <ShareOptionsModal
        isOpen={showShareOptionsModal}
        onClose={() => setShowShareOptionsModal(false)}
        onShare={async () => {
          const shareUrl = `https://www.memopin.ai/memory/${memory.id}`;
          const shareText = `${memory.title}\\n\\n${shareUrl}`;

          try {
            if (navigator.share && navigator.canShare) {
              const shareData = {
                title: 'Memory from MemoPin',
                text: shareText
              };
              
              if (navigator.canShare(shareData)) {
                await navigator.share(shareData);
                return;
              }
            }
            
            await navigator.clipboard.writeText(shareText);
            alert('✓ Copied to clipboard! You can now paste and share.');
          } catch (err) {
            const error = err as Error;
            if (error.name === 'AbortError') return;
            
            try {
              await navigator.clipboard.writeText(shareText);
              alert('✓ Copied to clipboard!');
            } catch {
              alert(`Share link:\\n\\n${shareUrl}`);
            }
          }
        }}
        onCopyLink={async () => {
          const shareUrl = `https://www.memopin.ai/memory/${memory.id}`;
          try {
            await navigator.clipboard.writeText(shareUrl);
            alert('✓ Link copied to clipboard!');
          } catch {
            alert(`Copy this link:\\n\\n${shareUrl}`);
          }
        }}
        onExportImage={() => {
          alert('Export as Image - Coming soon!');
        }}
        onExportPDF={() => {
          alert('Export as PDF - Coming soon!');
        }}
        onExportWord={() => {
          alert('Export as Word - Coming soon!');
        }}
        onExportMarkdown={() => {
          const takeawaysList = keyTakeaways.map(t => `- ${t}`).join('\n');
          const markdownContent = `# ${memory.title || 'Memory Note'}\n\n**Date:** ${memory.date}\n**Duration:** ${memory.audioDuration || 'N/A'}\n\n## Key Takeaways\n\n${takeawaysList}\n\n## Summary\n\n${memory.summary || 'No summary available'}`;
          
          try {
            const blob = new Blob([markdownContent], { type: 'text/markdown' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `memory_${memory.id}.md`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
          } catch {
            alert('Export failed. Please try again.');
          }
        }}
      />

      {/* Memory Options Modal - Using unified component */}
      <MemoryOptionsModal
        isOpen={showMemoryOptionsModal}
        onClose={() => setShowMemoryOptionsModal(false)}
        onEditTitle={() => {
          alert('Edit Title - Coming soon!');
        }}
        onModifyDate={() => {
          alert('Modify Date - Coming soon!');
        }}
        onDelete={() => {
          if (confirm('Are you sure you want to delete this memory?')) {
            alert('Memory deleted!');
            onClose();
          }
        }}
        showGenerateResummary={true}
        onGenerateResummary={() => {
          setShowMemoryOptionsModal(false);
          setShowResummaryModal(true);
        }}
        projectCount={projects.filter(p => p.isLinked).length}
        onManageProjects={() => {
          setShowMemoryOptionsModal(false);
          setShowManageProjectsModal(true);
        }}
      />

      {/* Manage Projects Modal */}
      <ManageProjectsModal
        isOpen={showManageProjectsModal}
        onClose={() => setShowManageProjectsModal(false)}
        projects={projects}
        onSave={(selectedProjectIds) => {
          // Update linked projects in parent component
          if (onUpdateLinkedProjects) {
            onUpdateLinkedProjects(memory.id, selectedProjectIds);
          }
        }}
        onCreateProject={(projectName) => {
          const newProjectId = Date.now().toString();
          
          // Sync to global project list (but WITHOUT linking to current memory yet)
          if (onCreateProject) {
            onCreateProject({
              id: newProjectId,
              name: projectName,
              memoryId: null  // Don't link yet - only link when Save is clicked
            });
          }
          
          // Return the new project info to ManageProjectsModal
          return {
            id: newProjectId,
            name: projectName
          };
        }}
      />

      {/* Resummary Confirmation Modal */}
      {showResummaryModal && (
        <div className="fixed inset-0 bg-black/40 flex items-end z-[100]">
          <div 
            className="absolute inset-0" 
            onClick={() => setShowResummaryModal(false)}
          />
          <div className="bg-white w-full rounded-t-[28px] px-5 pt-4 pb-6 relative animate-slide-up max-h-[85vh] flex flex-col">
            {/* Drag handle */}
            <div className="flex justify-center mb-2">
              <div className="w-10 h-1 bg-[#c7c7cc] rounded-full" />
            </div>

            {/* Scrollable content */}
            <div className="flex-1 overflow-y-auto">
              {/* Header */}
              <div className="mb-3">
                <h2 className="text-[19px] font-bold text-[#1c1c1e] leading-tight mb-1.5">
                  Here's what AI will do for you
                </h2>
                <p className="text-[14px] text-[#3c3c43] leading-[1.35]">
                  AI will regenerate this summary with fresh insights.
                </p>
              </div>

              {/* Summary Features Card */}
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

              {/* Selected style notice with Change button */}
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

            {/* Bottom CTA */}
            <div className="pt-3">
              <button
                onClick={() => {
                  localStorage.setItem('lastUsedSummaryStyle', selectedTemplate);
                  setShowResummaryModal(false);
                  // Trigger the parent callback to start generating
                  if (onGenerateResummary) {
                    onGenerateResummary();
                  } else {
                    // Fallback to local generation if no callback provided
                    setIsGeneratingResummary(true);
                    setTimeout(() => {
                      setIsGeneratingResummary(false);
                      alert('✓ AI Summary regenerated successfully!');
                    }, 10000);
                  }
                }}
                className="w-full bg-[#007aff] text-white text-[17px] font-semibold py-3.5 rounded-[14px] hover:bg-[#0051d5] transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                <Sparkles className="w-5 h-5" />
                <span>Generate summary</span>
              </button>

              <p className="text-[12px] text-[#8e8e93] text-center mt-3 leading-[1.4]">
                This will replace the current summary<br/>
                • New insights • Updated analysis
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
            {/* Header */}
            <div className="flex items-center justify-between mb-2 -mx-1">
              <button
                onClick={() => {
                  setShowTemplateModal(false);
                  setTempSelectedTemplate(selectedTemplate);
                }}
                className="text-[#007aff] hover:opacity-70 transition-opacity flex items-center gap-1 text-[16px]"
              >
                <ChevronLeft className="w-5 h-5" />
                <span>Back</span>
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
              <div className="mb-2.5 mt-0.5">
                <div className="text-[18px] mb-0.5">✨</div>
                <h3 className="text-[16px] font-bold text-[#1c1c1e] mb-0.5">
                  Choose how you'd like this summarized
                </h3>
                <p className="text-[13px] text-[#3c3c43] leading-[1.25]">
                  Pick a style that fits this recording.
                </p>
              </div>

              {/* Autopilot (Recommended) */}
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
                <span className="text-[12px] font-medium text-[#8e8e93]">Other styles</span>
                <div className="h-px flex-1 bg-gradient-to-r from-transparent via-black/[0.1] to-transparent" />
              </div>

              {/* Other templates */}
              <div className="space-y-2">
                {[
                  { id: 'meeting-secretary', emoji: '🧑‍💼', title: 'Meeting secretary', desc: 'Clear, structured meeting notes' },
                  { id: 'sales-followup', emoji: '📞', title: 'Sales follow-up', desc: 'Client needs, objections, next steps' },
                  { id: 'learning-notes', emoji: '📚', title: 'Learning notes', desc: 'Concepts, examples, personal takeaways' },
                  { id: 'adhd-friendly', emoji: '🧠', title: 'ADHD-friendly', desc: 'Extra structure, clarity, no overload' },
                  { id: 'reflection-insights', emoji: '💡', title: 'Reflection', desc: 'Patterns and insights' },
                ].map((template) => (
                  <button
                    key={template.id}
                    onClick={() => setTempSelectedTemplate(template.id)}
                    className={`w-full bg-[#f9f9f9] rounded-[12px] p-2.5 text-left border-2 transition-all ${
                      tempSelectedTemplate === template.id ? 'border-[#007aff] bg-[#f0f7ff]' : 'border-transparent'
                    }`}
                  >
                    <div className="flex items-start gap-2.5">
                      <div className="text-[20px] leading-none flex-shrink-0">{template.emoji}</div>
                      <div className="flex-1">
                        <h3 className="text-[14px] font-semibold text-[#1c1c1e] mb-0.5">
                          {template.title}
                        </h3>
                        <p className="text-[12px] text-[#3c3c43] leading-[1.2]">
                          {template.desc}
                        </p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Bottom button */}
            <div className="pt-3 mt-2">
              <button
                onClick={() => {
                  setSelectedTemplate(tempSelectedTemplate);
                  setShowTemplateModal(false);
                }}
                className="w-full bg-[#007aff] text-white text-[16px] font-semibold py-3 rounded-[14px] hover:bg-[#0051d5] transition-colors"
              >
                Confirm selection
              </button>
            </div>
          </div>
        </div>
      )}

      {/* AI Generating Animation */}
      {isGeneratingResummary && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-[120]">
          <div className="bg-white rounded-[24px] px-8 py-10 max-w-sm mx-4">
            <div className="flex flex-col items-center text-center">
              {/* Animated Icon */}
              <div className="relative mb-6">
                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#007aff]/20 to-[#007aff]/10 flex items-center justify-center animate-pulse">
                  <Sparkles className="w-10 h-10 text-[#007aff]" />
                </div>
                <div className="absolute inset-0 rounded-full border-2 border-transparent border-t-[#007aff] animate-spin"></div>
              </div>

              <h3 className="text-[22px] font-bold mb-2 text-[#1c1c1e]">
                AI is working on it
              </h3>
              
              <p className="text-[15px] text-[#8e8e93] leading-[1.4] mb-6">
                Regenerating your summary...
              </p>

              <div className="px-4 py-2.5 bg-[#f2f2f7] rounded-[12px]">
                <p className="text-[13px] text-[#8e8e93]">
                  This usually takes <span className="font-medium text-[#1c1c1e]">about 10 seconds</span>
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Speaker Name Modal */}
      {showEditSpeakerModal && (
        <div className="fixed inset-0 bg-black/40 flex items-end z-[100]">
          <div 
            className="absolute inset-0" 
            onClick={() => setShowEditSpeakerModal(false)}
          />
          <div className="bg-white w-full rounded-t-[28px] px-5 pt-4 pb-6 relative animate-slide-up">
            {/* Drag handle */}
            <div className="flex justify-center mb-3">
              <div className="w-10 h-1 bg-[#c7c7cc] rounded-full" />
            </div>

            {/* Header */}
            <div className="mb-4">
              <h2 className="text-[20px] font-bold text-[#1c1c1e] mb-1">
                Edit Speaker Name
              </h2>
              <p className="text-[14px] text-[#8e8e93]">
                Change "{editingSpeakerName}" to a new name
              </p>
            </div>

            {/* Input field */}
            <div className="mb-4">
              <label className="block text-[13px] font-medium text-[#8e8e93] mb-2">
                New Speaker Name
              </label>
              <input
                type="text"
                value={newSpeakerName}
                onChange={(e) => setNewSpeakerName(e.target.value)}
                placeholder="Enter speaker name"
                className="w-full px-4 py-3 bg-[#f2f2f7] rounded-[12px] text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:ring-2 focus:ring-[#007aff]"
                autoFocus
              />
            </div>

            {/* Apply to all checkbox */}
            <div className="mb-5">
              <label className="flex items-start gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={applyToAllSameSpeaker}
                  onChange={(e) => setApplyToAllSameSpeaker(e.target.checked)}
                  className="mt-0.5 w-5 h-5 rounded border-2 border-[#c7c7cc] text-[#007aff] focus:ring-2 focus:ring-[#007aff] focus:ring-offset-0"
                />
                <div className="flex-1">
                  <div className="text-[15px] text-[#1c1c1e] font-medium mb-0.5">
                    Apply to all "{editingSpeakerName}"
                  </div>
                  <div className="text-[13px] text-[#8e8e93] leading-[1.3]">
                    Update all segments where this speaker appears in the transcript
                  </div>
                </div>
              </label>
            </div>

            {/* Action buttons */}
            <div className="flex gap-3">
              <button
                onClick={() => setShowEditSpeakerModal(false)}
                className="flex-1 px-4 py-3 bg-[#f2f2f7] rounded-[12px] text-[15px] font-semibold text-[#1c1c1e] hover:bg-[#e5e5ea] transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveSpeakerName}
                disabled={!newSpeakerName.trim()}
                className="flex-1 px-4 py-3 bg-[#007aff] rounded-[12px] text-[15px] font-semibold text-white hover:bg-[#0051d5] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Memo Modal */}
      {showAddMemoModal && (
        <div className="fixed inset-0 bg-black/40 z-[100] flex items-end">
          <div 
            className="absolute inset-0"
            onClick={() => {
              setShowAddMemoModal(false);
              setMemoText('');
              setIsRecordingMemo(false);
              setIsTranscribingMemo(false);
            }}
          />
          <div className="w-full bg-white rounded-t-[20px] p-5 space-y-4 animate-slide-up relative">
            <div className="flex items-center justify-between">
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Add Memo</h3>
              <button 
                onClick={() => {
                  setShowAddMemoModal(false);
                  setMemoText('');
                  setIsRecordingMemo(false);
                  setIsTranscribingMemo(false);
                }}
                className="text-[#007aff] text-[15px] hover:opacity-70 transition-opacity"
              >
                Cancel
              </button>
            </div>
            
            {!isRecordingMemo && !isTranscribingMemo ? (
              <>
                <textarea
                  value={memoText}
                  onChange={(e) => setMemoText(e.target.value)}
                  placeholder="Write your memo..."
                  className="w-full h-32 px-3.5 py-2.5 text-[15px] bg-[#f2f2f7] rounded-xl border border-black/[0.06] focus:outline-none focus:ring-2 focus:ring-[#007aff]/30 resize-none"
                />
                <div className="flex gap-2">
                  <button 
                    onClick={() => setIsRecordingMemo(true)}
                    className="flex-1 bg-[#f2f2f7] text-[#1c1c1e] py-3 rounded-xl hover:bg-[#e5e5ea] transition-colors text-[15px] font-semibold flex items-center justify-center gap-2"
                  >
                    <Mic className="w-4.5 h-4.5" />
                    Voice Input
                  </button>
                  <button 
                    onClick={() => {
                      if (memoText.trim()) {
                        alert('Memo saved!');
                        setShowAddMemoModal(false);
                        setMemoText('');
                      }
                    }}
                    disabled={!memoText.trim()}
                    className="flex-1 bg-[#007aff] text-white py-3 rounded-xl hover:bg-[#0051d5] transition-colors text-[15px] font-semibold disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    Save Memo
                  </button>
                </div>
              </>
            ) : isRecordingMemo ? (
              <>
                <div className="flex items-center justify-center gap-1.5 px-4 py-12 bg-[#007aff]/10 rounded-xl">
                  {[...Array(20)].map((_, i) => (
                    <div
                      key={i}
                      className="w-1.5 bg-[#007aff] rounded-full animate-pulse"
                      style={{
                        height: `${Math.random() * 16 + 16}px`,
                        animationDelay: `${i * 50}ms`,
                        animationDuration: '1s'
                      }}
                    />
                  ))}
                </div>
                <div className="flex gap-2">
                  <button 
                    onClick={() => setIsRecordingMemo(false)}
                    className="flex-1 bg-[#f2f2f7] text-[#1c1c1e] py-3 rounded-xl hover:bg-[#e5e5ea] transition-colors text-[15px] font-semibold"
                  >
                    Cancel
                  </button>
                  <button 
                    onClick={() => {
                      setIsRecordingMemo(false);
                      setIsTranscribingMemo(true);
                      setTimeout(() => {
                        const transcribedText = "Remember to follow up with the team about the new feature requirements discussed today.";
                        setMemoText(transcribedText);
                        setIsTranscribingMemo(false);
                      }, 2000);
                    }}
                    className="flex-1 bg-[#007aff] text-white py-3 rounded-xl hover:bg-[#0051d5] transition-colors text-[15px] font-semibold"
                  >
                    Done
                  </button>
                </div>
              </>
            ) : (
              <>
                <div className="flex items-center justify-center gap-2.5 px-4 py-12 bg-[#f2f2f7] rounded-xl">
                  <div className="flex items-center gap-1">
                    <div className="w-2 h-2 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '0ms' }}></div>
                    <div className="w-2 h-2 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '150ms' }}></div>
                    <div className="w-2 h-2 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '300ms' }}></div>
                  </div>
                  <span className="text-[15px] text-[#8e8e93] font-medium">Transcribing...</span>
                </div>
              </>
            )}
          </div>
        </div>
      )}

      {/* AI Chat Modal */}
      {showAIChatModal && (
        <AIChatModal
          isOpen={showAIChatModal}
          onClose={() => setShowAIChatModal(false)}
          initialMessages={chatMessages}
          onSaveMessages={(messages) => {
            setChatMessages(messages);
            localStorage.setItem(`memory-chat-${memory.id}`, JSON.stringify(messages));
          }}
          memoryTitle={memory.title || 'Memory'}
          suggestedQuestions={[
            'What were the key points discussed?',
            'Can you summarize this for me?',
            'What action items came up?'
          ]}
        />
      )}

      {/* Person Detail View */}
      {showPersonDetail && (
        <div className="fixed inset-0 z-[120]">
          <PersonDetail
            personName={selectedPersonName}
            onBack={() => {
              setShowPersonDetail(false);
              setSelectedPersonName('');
            }}
          />
        </div>
      )}
    </div>
  );
}