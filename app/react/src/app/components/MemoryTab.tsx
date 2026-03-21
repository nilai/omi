import { useState, useEffect } from 'react';
import { Search, Calendar, Users, FolderOpen, Sparkles, Mic, Activity, ChevronLeft, X, List, ChevronRight, BookText, ChevronDown, ChevronUp, Brain, Pause, Play } from 'lucide-react';
import { InsightsSummaryCard } from './InsightsSummaryCard';
import { CalendarPicker } from './CalendarPicker';
import { CalendarPage } from './CalendarPage';
import { PeoplePage } from './PeoplePage';
import { PersonDetail } from './PersonDetail';
import { DailyInsightDetail } from './DailyInsightDetail';
import { WeeklyInsightDetail } from './WeeklyInsightDetail';
import { MonthlyInsightDetail } from './MonthlyInsightDetail';
import { AllInsightsListPage } from './AllInsightsListPage';
import { AudioMemoryDetail } from './AudioMemoryDetail';
import { MemoryDetail } from './MemoryDetail';
import { MemoryActivityFlow } from './MemoryActivityFlow';
import { PatternInsightDetail } from './PatternInsightDetail';
import { GeneratingResummaryPage } from './GeneratingResummaryPage';
import { ProjectDetail } from './ProjectDetail';
import { CreateProjectWithMemoriesModal } from './CreateProjectWithMemoriesModal';
import { MemoListPage } from './MemoListPage';
import { MemoDetailModal } from './MemoDetailModal';
import { NewTodoFromMemoModal } from './NewTodoFromMemoModal';
import { MemoryListSelector } from './MemoryListSelector';
import { TodoDetailModal } from './TodoDetailModal';
import { EmptyState } from './EmptyState';
import { ErrorState } from './ErrorState';
import { useDevMode } from '../contexts/DevModeContext';
import { PullToRefresh } from './PullToRefresh';
import { useMicrophonePermission } from '../contexts/MicrophonePermissionContext';
import { MicrophonePermissionModal } from './MicrophonePermissionModal';
import { MicrophonePermissionDeniedModal } from './MicrophonePermissionDeniedModal';

interface MemoryTabProps {
  onAddTodo?: (todo: any) => void;
  todos?: any[];
  setTodos?: (todos: any[]) => void;
  onMarkDone?: (id: number) => void;
  onNotNow?: (id: number) => void;
  onDeleteTodo?: (id: number) => void;
  onUpdateTodo?: (id: number, updates: any) => void;
  memories?: any[];
  setMemories?: (memories: any[]) => void;
  memos?: any[];
  setMemos?: (memos: any[]) => void;
  onCreateMemo?: (memo: any) => void;
  onUpdateMemo?: (memoId: number, updates: any) => void;
  onDeleteMemo?: (memoId: number) => void;
  onAnalyzeActions?: (memoId: number, todoTexts: string[]) => void;
  onCreateMemory?: (memory: any) => void;
}

type BrowseMode = 'time' | 'people' | 'projects';

export function MemoryTab({ onAddTodo, todos, setTodos, onMarkDone, onNotNow, onDeleteTodo, onUpdateTodo, memories: memoriesProp, setMemories: setMemoriesProp, memos: memosProp = [], setMemos: setMemosProp, onCreateMemo, onUpdateMemo, onDeleteMemo, onAnalyzeActions, onCreateMemory }: MemoryTabProps = {}) {
  const { devMode } = useDevMode();
  const { permissionStatus, requestPermission } = useMicrophonePermission();
  const [browseMode, setBrowseMode] = useState<BrowseMode>('time');
  const [showMicPermissionModal, setShowMicPermissionModal] = useState(false);
  const [showMicPermissionDeniedModal, setShowMicPermissionDeniedModal] = useState(false);
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [showCalendar, setShowCalendar] = useState(false);
  const [showCalendarPage, setShowCalendarPage] = useState(false);
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [selectedMemory, setSelectedMemory] = useState<any>(null);
  const [memoryInitialTab, setMemoryInitialTab] = useState<'Overview' | 'Transcript' | 'Actions'>('Overview');
  const [memoryHighlightTimestamp, setMemoryHighlightTimestamp] = useState<string | undefined>(undefined);
  const [showPeoplePage, setShowPeoplePage] = useState(false);
  const [selectedPerson, setSelectedPerson] = useState<string | null>(null);
  const [showDailyInsightsList, setShowDailyInsightsList] = useState(false);
  const [selectedDailyInsight, setSelectedDailyInsight] = useState<any>(null);
  const [selectedWeeklyInsight, setSelectedWeeklyInsight] = useState<any>(null);
  const [selectedMonthlyInsight, setSelectedMonthlyInsight] = useState<any>(null);
  const [selectedPatternInsight, setSelectedPatternInsight] = useState<any>(null);
  const [isGeneratingSummary, setIsGeneratingSummary] = useState(false);
  const [generatingMemory, setGeneratingMemory] = useState<any>(null);
  const [isNewlyGeneratedMemory, setIsNewlyGeneratedMemory] = useState(false);
  const [viewedMemoryIds, setViewedMemoryIds] = useState<Set<number>>(new Set());
  const [fromPatternInsight, setFromPatternInsight] = useState(false);
  const [viewedPatternInsightIds, setViewedPatternInsightIds] = useState<Set<string>>(new Set());
  const [selectedProject, setSelectedProject] = useState<any>(null);
  const [showCreateProjectModal, setShowCreateProjectModal] = useState(false);
  
  // Memo related states
  const [showMemoList, setShowMemoList] = useState(false);
  const [selectedMemo, setSelectedMemo] = useState<any>(null);
  const [showNewTodoFromMemoModal, setShowNewTodoFromMemoModal] = useState(false);
  
  // Recording related states
  const [showRecordingModal, setShowRecordingModal] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [hasStartedRecording, setHasStartedRecording] = useState(false);
  const [recordingTime, setRecordingTime] = useState(0);
  const [showCancelConfirmModal, setShowCancelConfirmModal] = useState(false);
  
  // Todo related states
  const [selectedTodo, setSelectedTodo] = useState<any>(null);
  const [newTodoFromMemo, setNewTodoFromMemo] = useState<any>(null);
  const [expandedMemoGroups, setExpandedMemoGroups] = useState<Set<string>>(new Set());
  const [showMemorySelector, setShowMemorySelector] = useState(false);
  const [memoForMemoryLink, setMemoForMemoryLink] = useState<number | null>(null);
  const [memoToRestoreAfterTodo, setMemoToRestoreAfterTodo] = useState<any>(null);
  
  // Source tracking - where did the user come from?
  const [sourceContext, setSourceContext] = useState<'list' | 'calendar'>('list');

  // Project data
  const [projectsData, setProjectsData] = useState([
    {
      id: 'api-migration',
      name: 'API Migration',
      memoryCount: 3,
      updateTime: 'today',
      lastActivity: 'Timeline discussion',
      aiSummary: 'Across 3 discussions over 3 weeks, the team shifted from phased API migration to parallel execution.',
      timeline: [
        { date: 'Jan 21', title: 'Hardware finalized', status: 'completed' as const },
        { date: 'Feb 5', title: 'Kickstarter page draft', status: 'completed' as const },
        { date: 'Mar 15', title: 'Campaign video finalized', status: 'in-progress' as const },
        { date: 'Mar 25', title: 'Kickstarter launch', status: 'upcoming' as const }
      ],
      themes: [
        { 
          title: 'Execution overload', 
          count: 8, 
          type: 'risk' as const,
          insight: 'Team repeatedly raised concerns about parallel execution pressure, especially around resource allocation and coordination between backend and frontend teams.',
          lastMentioned: { meeting: 'Team standup', date: 'Today' }
        },
        { 
          title: 'Timeline pressure', 
          count: 6, 
          type: 'risk' as const,
          insight: 'Multiple discussions highlighted timeline concerns as dependencies between services became clearer during implementation.',
          lastMentioned: { meeting: 'Client feedback call', date: 'Jan 20' }
        },
        { 
          title: 'Architecture decisions', 
          count: 5, 
          type: 'strategy' as const,
          insight: 'Microservices architecture tradeoffs were debated across several meetings, with focus shifting from monolith concerns to scalability benefits.',
          lastMentioned: { meeting: 'Team standup', date: 'Today' }
        }
      ],
      overview: {
        summary: 'Across 3 discussions over 3 weeks, the team shifted from a phased API migration strategy to a parallel execution approach.',
        decisionTimeline: [
          { date: 'Jan 21', text: 'Auth-first migration proposed' },
          { date: 'Jan 20', text: 'Dashboard features discussed' },
          { date: 'Today', text: 'Microservices architecture finalized' }
        ],
        recurringThemes: [
          'Execution overload',
          'Timeline pressure'
        ],
        currentStatus: 'Active implementation phase.'
      },
      memories: [
        { id: 1, title: 'Team standup discussion on API migration', date: 'Today' },
        { id: 4, title: 'Client feedback call about new dashboard features', date: 'Jan 20' },
        { id: 3, title: 'Audio only', date: 'Jan 21' }
      ]
    },
    {
      id: 'product-launch-q2',
      name: 'Product Launch Q2',
      memoryCount: 2,
      updateTime: 'today',
      lastActivity: 'Marketing sync',
      aiSummary: 'Over 2 strategy sessions, the team refined the Q2 launch plan, moving from broad positioning to phased rollout.',
      timeline: [
        { date: 'Feb 10', title: 'Product positioning defined', status: 'completed' as const },
        { date: 'Mar 5', title: 'Beta user group confirmed', status: 'in-progress' as const },
        { date: 'Apr 1', title: 'Public launch', status: 'upcoming' as const }
      ],
      themes: [
        { 
          title: 'User experience focus', 
          count: 5, 
          type: 'strategy' as const,
          insight: 'Design reviews consistently emphasized ADHD-friendly interface patterns, with specific attention to reducing cognitive load and maintaining visual hierarchy.',
          lastMentioned: { meeting: 'Product launch planning', date: 'Today' }
        },
        { 
          title: 'Competitive differentiation', 
          count: 4, 
          type: 'discussion' as const,
          insight: 'Marketing discussions repeatedly positioned the product against generic productivity tools, highlighting neurodivergent-specific features as key differentiators.',
          lastMentioned: { meeting: 'Weekly planning session', date: 'Jan 19' }
        },
        { 
          title: 'Phased rollout concerns', 
          count: 3, 
          type: 'risk' as const,
          insight: 'Team debated buffer time between launch phases to ensure adequate time for user feedback integration and adjustment.',
          lastMentioned: { meeting: 'Product launch planning', date: 'Today' }
        }
      ],
      overview: {
        summary: 'Over 2 strategy sessions, the team refined the Q2 launch plan, moving from broad positioning to a phased go-to-market rollout.',
        decisionTimeline: [
          { date: 'Jan 19', text: 'Weekly planning session completed' },
          { date: 'Today', text: 'Three-phase rollout strategy proposed' }
        ],
        recurringThemes: [
          'Competitive differentiation',
          'User experience focus',
          'Phased rollout approach'
        ],
        currentStatus: 'Preparation for phased rollout.'
      },
      memories: [
        { id: 7, title: 'Product launch planning with marketing team', date: 'Today' },
        { id: 5, title: 'Weekly review and planning session', date: 'Jan 19' }
      ]
    },
    {
      id: 'series-a-fundraising',
      name: 'Series A Fundraising',
      memoryCount: 2,
      updateTime: 'yesterday',
      lastActivity: 'Investor prep',
      aiSummary: 'Across 2 investor-related meetings, the fundraising narrative evolved from product-centric storytelling to traction and market positioning emphasis.',
      timeline: [
        { date: 'Feb 15', title: 'Initial pitch deck created', status: 'completed' as const },
        { date: 'Mar 10', title: 'First investor meetings', status: 'completed' as const },
        { date: 'Mar 20', title: 'Term sheet negotiations', status: 'upcoming' as const }
      ],
      themes: [
        { 
          title: 'Growth metrics clarity', 
          count: 7, 
          type: 'discussion' as const,
          insight: 'Investors repeatedly asked about growth metrics clarity, especially retention and cohort expansion as indicators of sustainable growth.',
          lastMentioned: { meeting: 'Investor meeting', date: 'Mar 9' }
        },
        { 
          title: 'User retention focus', 
          count: 6, 
          type: 'strategy' as const,
          insight: 'Retention metrics were brought up in multiple investor discussions as a key indicator of product-market fit and defensibility.',
          lastMentioned: { meeting: 'Product strategy chat', date: 'Mar 8' }
        },
        { 
          title: 'Funding timeline pressure', 
          count: 4, 
          type: 'risk' as const,
          insight: 'Several conversations touched on runway concerns and the need to accelerate fundraising timeline while maintaining valuation expectations.',
          lastMentioned: { meeting: 'Investor meeting', date: 'Mar 9' }
        }
      ],
      overview: {
        summary: 'Across 2 investor-related meetings, the fundraising narrative evolved from product-centric storytelling to traction and market positioning emphasis.',
        decisionTimeline: [
          { date: 'Yesterday', text: 'Product strategy positioning discussed' },
          { date: 'Yesterday', text: 'Growth metrics and unit economics presented' }
        ],
        recurringThemes: [
          'Growth metrics clarity',
          'User retention focus',
          'Market differentiation'
        ],
        currentStatus: 'Preparing for next investor round.'
      },
      memories: [
        { id: 8, title: 'Investor meeting - Series A funding discussion', date: 'Yesterday' },
        { id: 2, title: 'Coffee chat with Alex about product strategy', date: 'Yesterday' }
      ]
    }
  ]);

  // Handler to create a new project
  const handleCreateProject = (project: { id: string; name: string; memoryId: number | null }) => {
    const newProject = {
      id: project.id,
      name: project.name,
      memoryCount: project.memoryId !== null ? 1 : 0,
      updateTime: 'today',
      lastActivity: project.memoryId !== null ? 'Created from memory' : 'Just created',
      overview: {
        summary: project.memoryId !== null ? `Project created from memory #${project.memoryId}` : 'New project',
        decisionTimeline: [],
        recurringThemes: [],
        currentStatus: 'Just created'
      },
      memories: project.memoryId !== null 
        ? [
            // Only link the memory if memoryId is provided
            memories.find(m => m.id === project.memoryId) || { id: project.memoryId, title: 'Linked memory', date: 'today' }
          ]
        : []  // Empty array if no memoryId provided
    };
    setProjectsData(prev => [...prev, newProject]);
  };

  // Handler to update project memories
  const handleUpdateProject = (projectId: string, newMemories: any[]) => {
    setProjectsData(prevProjects => 
      prevProjects.map(project => {
        if (project.id === projectId) {
          const updatedProject = {
            ...project,
            memories: newMemories,
            memoryCount: newMemories.length,
            updateTime: 'today'
          };
          // Also update selectedProject if it's the same project
          if (selectedProject?.id === projectId) {
            setSelectedProject(updatedProject);
          }
          return updatedProject;
        }
        return project;
      })
    );
  };

  // Handler to remove a memory from a project
  const handleRemoveMemoryFromProject = (projectId: string, memoryId: number) => {
    setProjectsData(prevProjects => 
      prevProjects.map(project => {
        if (project.id === projectId) {
          const updatedMemories = project.memories.filter(m => m.id !== memoryId);
          const updatedProject = {
            ...project,
            memories: updatedMemories,
            memoryCount: updatedMemories.length,
            updateTime: 'today'
          };
          // Also update selectedProject if it's the same project
          if (selectedProject?.id === projectId) {
            setSelectedProject(updatedProject);
          }
          return updatedProject;
        }
        return project;
      })
    );
  };

  // Handler to delete a project
  const handleDeleteProject = (projectId: string) => {
    setProjectsData(prevProjects => prevProjects.filter(p => p.id !== projectId));
    // Close the project detail if it's currently open
    if (selectedProject?.id === projectId) {
      setSelectedProject(null);
    }
  };

  // Timer effect for recording
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null;
    
    if (isRecording) {
      interval = setInterval(() => {
        setRecordingTime((prev) => {
          // Max 60 minutes = 3600 seconds
          if (prev >= 3600) {
            if (interval) clearInterval(interval);
            pauseRecording();
            return 3600;
          }
          return prev + 1;
        });
      }, 1000);
    }
    
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isRecording]);

  // Format time as MM:SS
  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const startRecording = () => {
    setIsRecording(true);
    setHasStartedRecording(true);
  };

  const pauseRecording = () => {
    setIsRecording(false);
  };

  const handleCloseRecordingModal = () => {
    if (hasStartedRecording) {
      setShowCancelConfirmModal(true);
    } else {
      setShowRecordingModal(false);
      setIsRecording(false);
      setHasStartedRecording(false);
      setRecordingTime(0);
      setShowCancelConfirmModal(false);
    }
  };

  const handleSaveRecording = () => {
    console.log('🎙️ handleSaveRecording called');
    console.log('onCreateMemory available:', !!onCreateMemory);
    console.log('setMemoriesProp available:', !!setMemoriesProp);
    
    // Create date format: "Jan 18, 2026, 11:20 AM"
    const now = new Date();
    const dateFormatOptions: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    };
    const formattedDate = now.toLocaleString('en-US', dateFormatOptions);
    
    // Create subtitle format: "January 18, 2026 at 11:20 AM"
    const dateSubtitleOptions: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    };
    const formattedSubtitle = now.toLocaleString('en-US', dateSubtitleOptions);
    
    // Format duration
    const mins = Math.floor(recordingTime / 60);
    const secs = recordingTime % 60;
    const audioDuration = `${mins}m${secs}s`;
    
    // Create time ago string
    const getTimeAgo = () => {
      const today = new Date();
      if (now.toDateString() === today.toDateString()) {
        const hoursAgo = Math.floor((today.getTime() - now.getTime()) / (1000 * 60 * 60));
        if (hoursAgo === 0) {
          return 'Just now';
        }
        return `${hoursAgo}h ago`;
      }
      // For other dates, just return the short date
      return now.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    };
    
    const newMemory = {
      title: null,
      summary: null,
      date: formattedDate,
      dateSubtitle: formattedSubtitle,
      hasAudio: true,
      hasSummary: false,
      hasActivity: false,
      audioDuration,
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone',
      time: getTimeAgo(),
      content: formattedSubtitle,
      relatedMemories: [],
      isUserCreated: true // Mark as user-created for filtering in empty mode
    };
    
    console.log('📝 New memory object created:', newMemory);
    
    // Use onCreateMemory if available, otherwise fallback to setMemoriesProp
    if (onCreateMemory) {
      console.log('✅ Calling onCreateMemory');
      onCreateMemory(newMemory);
    } else if (setMemoriesProp) {
      console.log('⚠️ Fallback to setMemoriesProp');
      const currentMemories = memoriesProp || [];
      setMemoriesProp([newMemory, ...currentMemories]);
    }
    
    // Close modal and reset states
    setShowRecordingModal(false);
    setIsRecording(false);
    setHasStartedRecording(false);
    setRecordingTime(0);
  };
  
  const handleConfirmCancel = () => {
    setShowRecordingModal(false);
    setShowCancelConfirmModal(false);
    setIsRecording(false);
    setHasStartedRecording(false);
    setRecordingTime(0);
  };

  // Handle automatic conversion to activity flow after 10 seconds
  useEffect(() => {
    if (isGeneratingSummary && generatingMemory) {
      const timer = setTimeout(() => {
        // Convert memory to have activity
        const updatedMemory = {
          ...generatingMemory,
          hasActivity: true
        };
        setSelectedMemory(updatedMemory);
        setIsGeneratingSummary(false);
        setGeneratingMemory(null);
        setIsNewlyGeneratedMemory(true); // Mark as newly generated
      }, 10000); // 10 seconds

      return () => clearTimeout(timer);
    }
  }, [isGeneratingSummary, generatingMemory]);

  // Daily insight data - appears at top of memory list
  const dailyInsight = {
    id: 'daily-jan-28',
    date: 'Jan 28',
    dateSubtitle: 'End-of-day reflection',
    summary: 'You spent most of today thinking about product direction and execution trade-offs, with several follow-ups emerging around API migration and team bandwidth.',
    decisionsCount: 2,
    followUpsCount: 3,
    risksCount: 1
  };

  // Weekly insight data - Sunday, Jan 25
  const weeklyInsight = {
    id: 'weekly-jan-25',
    date: 'Jan 25',
    dateSubtitle: 'Week of Jan 19-25',
    summary: 'A productive week with strong momentum on the product roadmap. You balanced strategic planning with hands-on execution, completing 8 major tasks while identifying 3 key priorities for next week.',
    completedCount: 8,
    pendingCount: 5,
    recommendationsCount: 3,
    type: 'weekly-insight' // Add type to distinguish from regular memories
  };

  // Monthly insight data - January 2026
  const monthlyInsight = {
    id: 'monthly-jan-2026',
    date: 'Jan 2026',
    dateSubtitle: 'Month of January 2026',
    summary: 'January was a month of significant progress on the product roadmap. You achieved key milestones, including the launch of the new dashboard features and the completion of the API migration project. The team also focused on strategic planning for the upcoming quarter, setting clear goals and priorities.',
    completedCount: 15,
    pendingCount: 10,
    recommendationsCount: 5,
    type: 'monthly-insight' // Add type to distinguish from regular memories
  };

  // In empty mode, filter out preset memories, only keep user-created ones
  const allMemoriesBeforeFilter = memoriesProp || [
    {
      id: 1,
      title: 'Team standup discussion on API migration',
      summary: 'Discussed timeline for migrating legacy API to new microservices architecture. Team agreed on phased approach starting with authentication service.',
      date: 'Today, 10:30 AM',
      hasAudio: true,
      hasSummary: true,
      hasActivity: true,
      audioDuration: '12m34s',
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone',
      hasNewInsights: true,
      newInsightsCount: 1
    },
    {
      id: 7,
      title: 'Product launch planning with marketing team',
      summary: 'Finalized go-to-market strategy for Q2 product release. Team proposed three-phase rollout starting with beta users, followed by influencer partnerships and public launch.',
      date: 'Today, 9:15 AM',
      hasAudio: true,
      hasSummary: true,
      hasActivity: true,
      audioDuration: '22m18s',
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone',
      hasNewInsights: true,
      newInsightsCount: 3
    },
    {
      id: 8,
      title: 'Investor meeting - Series A funding discussion',
      summary: 'Presented growth metrics and Q1 achievements to potential lead investor. They expressed strong interest in our user retention numbers and asked detailed questions about unit economics.',
      date: 'Yesterday, 4:30 PM',
      hasAudio: true,
      hasSummary: true,
      hasActivity: true,
      audioDuration: '45m52s',
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone'
    },
    {
      id: 2,
      title: 'Coffee chat with Alex about product strategy',
      summary: 'Explored ideas for differentiation in competitive market. Alex suggested focusing on user experience for neurodivergent users as unique positioning.',
      date: 'Yesterday, 2:15 PM',
      hasAudio: true,
      hasSummary: true,
      hasActivity: false,
      audioDuration: '8m42s',
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone'
    },
    {
      id: 3,
      title: null, // Audio only - no title
      summary: null,
      date: 'Jan 21, 2026, 3:45 PM',
      dateSubtitle: 'January 21, 2026 at 3:45 PM',
      hasAudio: true,
      hasSummary: false,
      hasActivity: false,
      audioDuration: '5m23s',
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone'
    },
    {
      id: 4,
      title: 'Client feedback call about new dashboard features',
      summary: 'Client praised new data visualization features but requested more customization options for reports. Need to prioritize export functionality.',
      date: 'Feb 28, 2026',
      hasAudio: true,
      hasSummary: true,
      hasActivity: true,
      audioDuration: '18m56s',
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone'
    },
    {
      id: 5,
      title: 'Weekly review and planning session',
      summary: 'Reviewed progress on Q1 goals. Most milestones on track except mobile app development. Need to allocate more resources to frontend team.',
      date: 'Jan 19, 2026',
      hasAudio: true,
      hasSummary: true,
      hasActivity: false,
      audioDuration: '1h5m',
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone'
    },
    {
      id: 6,
      title: null, // Audio only - no title
      summary: null,
      date: 'Jan 18, 2026, 11:20 AM',
      dateSubtitle: 'January 18, 2026 at 11:20 AM',
      hasAudio: true,
      hasSummary: false,
      hasActivity: false,
      audioDuration: '3m47s',
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone'
    }
  ];

  // Filter memories based on dev mode
  // In empty mode: only show user-created memories
  const memories = devMode === 'empty' 
    ? allMemoriesBeforeFilter.filter(m => 
        // Keep only memories marked as user-created (created during this session)
        m.isUserCreated === true
      )
    : allMemoriesBeforeFilter;

  // Use memos from props (managed in App.tsx)
  // In empty mode: don't show any memos (they're preset data)
  const allMemos = memosProp || [];
  const memos = devMode === 'empty' ? [] : allMemos;
  const setMemos = setMemosProp || (() => {});

  const suggestions = ['Alex', 'API migration', 'CES', 'Investor meeting'];

  // People data for navigation
  const allPeople: { [letter: string]: any[] } = {
    A: [
      { id: '1', name: 'Alex', memoryCount: 3, lastTalked: 'Jan 21' },
      { id: '6', name: 'Amy', memoryCount: 1, lastTalked: 'Jan 10' },
    ],
    D: [
      { id: '7', name: 'David', memoryCount: 4, lastTalked: 'Jan 20' },
      { id: '8', name: 'Daniel', memoryCount: 2, lastTalked: 'Jan 19' },
    ],
    E: [
      { id: '4', name: 'Emily', memoryCount: 1, lastTalked: 'Today' },
    ],
    J: [
      { id: '3', name: 'Jordan', memoryCount: 5, lastTalked: 'Today' },
      { id: '11', name: 'James', memoryCount: 3, lastTalked: 'Jan 16' },
    ],
    L: [
      { id: '12', name: 'Lisa', memoryCount: 3, lastTalked: 'Jan 18' },
    ],
    M: [
      { id: '13', name: 'Michael', memoryCount: 7, lastTalked: 'Jan 21' },
    ],
    S: [
      { id: '2', name: 'Sarah', memoryCount: 2, lastTalked: 'yesterday' },
    ],
  };

  // Memo handlers
  const handleMemoClick = (memo: any) => {
    setSelectedMemo(memo);
    // No longer set showMemoDetail - we use modal instead
  };

  const handleDeleteMemo = (id: number) => {
    // Delete memo from state using callback from App
    if (onDeleteMemo) {
      onDeleteMemo(id);
    }
    // Close modal
    setSelectedMemo(null);
  };

  const handleCreateTodoFromMemo = (memoId: number) => {
    const memo = memos.find(m => m.id === memoId);
    if (memo) {
      // Save the current memo to restore later if needed
      setMemoToRestoreAfterTodo(selectedMemo);
      // Close the memo detail modal first
      setSelectedMemo(null);
      // Then open the create todo modal
      setNewTodoFromMemo(memo);
      setShowNewTodoFromMemoModal(true);
    }
  };

  const handleRelatedMemoryClick = (memoryTitle: string) => {
    const memory = memories.find(m => m.title === memoryTitle);
    if (memory) {
      setSelectedMemory(memory);
      setShowMemoList(false);
    }
  };

  const handleLinkMemoryToMemo = (memoId: number) => {
    setMemoForMemoryLink(memoId);
    setShowMemorySelector(true);
    setSelectedMemo(null); // Close memo detail modal
  };

  const handleSelectMemoryForMemo = (memoryId: number) => {
    if (memoForMemoryLink === null) return;
    
    const memory = memories.find(m => m.id === memoryId);
    if (!memory) return;

    // Update the memo with the linked memory AND add to relatedMemories array
    if (onUpdateMemo) {
      onUpdateMemo(memoForMemoryLink, {
        linkedMemory: {
          id: memory.id.toString(),
          title: memory.title || 'Audio only',
          date: memory.date,
          duration: memory.duration,
          hasSummary: memory.hasSummary
        },
        // Add this memory to relatedMemories array if not already there
        relatedMemories: memos.find(m => m.id === memoForMemoryLink)?.relatedMemories.includes(memoryId)
          ? memos.find(m => m.id === memoForMemoryLink)?.relatedMemories
          : [...(memos.find(m => m.id === memoForMemoryLink)?.relatedMemories || []), memoryId]
      });
    }

    // Find the updated memo to reopen
    const updatedMemo = memos.find(m => m.id === memoForMemoryLink);

    // Close the memory selector
    setShowMemorySelector(false);
    setMemoForMemoryLink(null);
    
    // Reopen the memo detail modal with the updated memo (will be updated from props)
    if (updatedMemo) {
      // Set a timeout to allow state to update
      setTimeout(() => {
        const memo = memos.find(m => m.id === memoForMemoryLink);
        if (memo) {
          setSelectedMemo(memo);
        }
      }, 0);
    }
  };

  const handleMemoryClickFromMemo = (memoryId: string) => {
    const memory = memories.find(m => m.id.toString() === memoryId);
    if (memory) {
      setSelectedMemory(memory);
      setSelectedMemo(null); // Close memo detail modal
    }
  };

  const handleHighlightClick = (memoryId: number, timestamp: string) => {
    const memory = memories.find(m => m.id === memoryId);
    if (memory) {
      setSelectedMemory(memory);
      setMemoryInitialTab('Transcript');
      setMemoryHighlightTimestamp(timestamp);
      setSelectedMemo(null); // Close memo detail modal
    }
  };

  // Pull to refresh handler
  const handleRefresh = async () => {
    // Simulate network request to refresh data
    await new Promise(resolve => setTimeout(resolve, 1500));
    console.log('Refreshed Memory tab data');
    // In a real app, this would fetch fresh data from the server
  };

  // Permission check function
  const checkAndRequestPermission = async (): Promise<boolean> => {
    if (permissionStatus === 'granted') {
      return true;
    }
    
    if (permissionStatus === 'not_determined') {
      // Show our custom permission guide modal
      setShowMicPermissionModal(true);
      return false;
    }
    
    if (permissionStatus === 'denied') {
      // Show denied modal with instructions to go to Settings
      setShowMicPermissionDeniedModal(true);
      return false;
    }
    
    return false;
  };

  // Handle permission modal continue
  const handlePermissionContinue = async () => {
    setShowMicPermissionModal(false);
    
    // Request actual system permission
    const granted = await requestPermission();
    
    if (granted) {
      // Permission granted - proceed with recording
      setShowRecordingModal(true);
    } else {
      // Permission denied - show denied modal
      setShowMicPermissionDeniedModal(true);
    }
  };

  // Handle permission modal "Not Now"
  const handlePermissionNotNow = () => {
    setShowMicPermissionModal(false);
  };

  // Handle open settings (when permission is denied)
  const handleOpenSettings = () => {
    console.log('Opening Settings...');
    setShowMicPermissionDeniedModal(false);
    alert('Please enable microphone access in your browser settings or system preferences.');
  };

  const handleMemoryClickFromTodo = (memoryId: string) => {
    // Check if this is a memo ID (format: memo-${id})
    if (memoryId.startsWith('memo-')) {
      // Extract memo ID and show the memo detail
      const memoId = parseInt(memoryId.replace('memo-', ''));
      const memo = memos.find(m => m.id === memoId);
      if (memo) {
        setSelectedMemo(memo);
        setSelectedTodo(null); // Close todo detail modal
        // Optionally show memo list page for context
        setShowMemoList(true);
      }
      return;
    }
    
    // Find the corresponding memory and open the detail page
    const memory = memories.find(m => m.id.toString() === memoryId);
    if (memory) {
      setSelectedMemory(memory);
      setSelectedTodo(null); // Close todo detail modal
    }
  };

  // Helper: check if memory is Audio-only
  const isAudioOnly = (memory: any) => {
    return memory.hasAudio && !memory.hasSummary && !memory.hasActivity;
  };

  // Helper: check if memory has activity
  const hasActivity = (memory: any) => {
    return memory.hasActivity === true;
  };

  // Helper: get source icon - always use Mic icon for audio
  const getSourceIcon = (source: 'MemoPin' | 'MobilePhone') => {
    // Always return Mic icon for all audio types
    return <Mic className="w-3.5 h-3.5" />;
  };

  // Helper: Group memos by date
  const groupMemosByDate = () => {
    const groups: { [key: string]: { memos: any[]; displayDate: string; sortTimestamp: number } } = {};
    
    memos.forEach(memo => {
      const date = new Date(memo.timestamp);
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      
      let dateKey: string;
      let displayDate: string;
      
      // Check if today
      if (date.toDateString() === today.toDateString()) {
        dateKey = 'today';
        displayDate = 'Today';
      }
      // Check if yesterday
      else if (date.toDateString() === yesterday.toDateString()) {
        dateKey = 'yesterday';
        displayDate = 'Yesterday';
      }
      // Other dates
      else {
        dateKey = date.toISOString().split('T')[0];
        displayDate = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      }
      
      if (!groups[dateKey]) {
        groups[dateKey] = {
          memos: [],
          displayDate,
          sortTimestamp: date.getTime()
        };
      }
      groups[dateKey].memos.push(memo);
    });
    
    return groups;
  };

  const memoGroups = groupMemosByDate();

  const toggleMemoGroup = (dateKey: string) => {
    setExpandedMemoGroups(prev => {
      const newSet = new Set(prev);
      if (newSet.has(dateKey)) {
        newSet.delete(dateKey);
      } else {
        newSet.add(dateKey);
      }
      return newSet;
    });
  };

  // Helper: Render a memo group card
  const renderMemoGroup = (dateKey: string, bgClass: string = 'bg-[#fafafa]') => {
    const group = memoGroups[dateKey];
    if (!group || group.memos.length === 0) return null;
    
    const isExpanded = expandedMemoGroups.has(dateKey);
    const displayMemos = isExpanded ? group.memos : group.memos.slice(0, 3);
    const hasMore = group.memos.length > 3;
    
    return (
      <div className={`w-full p-5 rounded-2xl border border-border ${bgClass} shadow-[0_1px_3px_rgba(0,0,0,0.08)]`}>
        {/* Header */}
        <div className="flex items-center gap-2 mb-3">
          <BookText className="w-4 h-4 text-[#f59e42]" strokeWidth={2} />
          <h3 className="text-[15px] font-semibold text-[#1c1c1e]">
            Memos · {group.displayDate}
          </h3>
          <span className="text-[13px] text-[#8e8e93]">
            {group.memos.length} {group.memos.length === 1 ? 'item' : 'items'}
          </span>
        </div>
        
        {/* Memo list */}
        <div className="space-y-2">
          {displayMemos.map((memo) => (
            <button
              key={memo.id}
              onClick={() => handleMemoClick(memo)}
              className="w-full text-left hover:opacity-70 transition-opacity flex items-start gap-2"
            >
              <span className="text-[14px] text-[#1c1c1e] mt-[2px]">•</span>
              <p className="text-[14px] text-[#3c3c43] leading-[1.5] line-clamp-1 flex-1">
                {memo.title}
              </p>
            </button>
          ))}
        </div>
        
        {/* Expand/Collapse button */}
        {hasMore && (
          <button
            onClick={() => toggleMemoGroup(dateKey)}
            className="w-full mt-3 pt-3 border-t border-black/[0.06] flex items-center gap-1.5 text-[#007aff] text-[14px] font-medium hover:opacity-70 transition-opacity"
          >
            {isExpanded ? (
              <>
                <ChevronUp className="w-4 h-4" strokeWidth={2} />
                <span>Show less</span>
              </>
            ) : (
              <>
                <ChevronDown className="w-4 h-4" strokeWidth={2} />
                <span>+ {group.memos.length - 3} more</span>
              </>
            )}
          </button>
        )}
      </div>
    );
  };

  // Helper: Parse memory date to timestamp for sorting
  const parseMemoryDate = (dateStr: string): number => {
    const now = new Date();
    const today = new Date(now);
    today.setHours(0, 0, 0, 0);
    
    if (dateStr.startsWith('Today')) {
      // Extract time if present (e.g., "Today, 10:30 AM")
      const timeMatch = dateStr.match(/(\d+):(\d+)\s*(AM|PM)/i);
      if (timeMatch) {
        let hours = parseInt(timeMatch[1]);
        const minutes = parseInt(timeMatch[2]);
        const isPM = timeMatch[3].toUpperCase() === 'PM';
        
        if (isPM && hours !== 12) hours += 12;
        if (!isPM && hours === 12) hours = 0;
        
        const result = new Date(today);
        result.setHours(hours, minutes, 0, 0);
        return result.getTime();
      }
      return now.getTime();
    } else if (dateStr.startsWith('Yesterday')) {
      // Yesterday with time
      const timeMatch = dateStr.match(/(\d+):(\d+)\s*(AM|PM)/i);
      if (timeMatch) {
        let hours = parseInt(timeMatch[1]);
        const minutes = parseInt(timeMatch[2]);
        const isPM = timeMatch[3].toUpperCase() === 'PM';
        
        if (isPM && hours !== 12) hours += 12;
        if (!isPM && hours === 12) hours = 0;
        
        const result = new Date(today);
        result.setDate(result.getDate() - 1);
        result.setHours(hours, minutes, 0, 0);
        return result.getTime();
      }
      return today.getTime() - 24 * 60 * 60 * 1000;
    } else {
      // Try to parse as date
      const parsed = new Date(dateStr);
      return parsed.getTime();
    }
  };

  // Helper: Create merged and sorted list of memories and memo groups
  const getMergedTimelineItems = () => {
    const items: Array<{ type: 'memory' | 'memoGroup'; data: any; timestamp: number; index?: number }> = [];
    
    // Add memories with timestamps
    memories.forEach((memory, index) => {
      items.push({
        type: 'memory',
        data: memory,
        timestamp: parseMemoryDate(memory.date),
        index
      });
    });
    
    // Add memo groups with timestamps
    Object.keys(memoGroups).forEach(dateKey => {
      const group = memoGroups[dateKey];
      if (group && group.memos.length > 0) {
        items.push({
          type: 'memoGroup',
          data: { dateKey, group },
          timestamp: group.sortTimestamp
        });
      }
    });
    
    // Sort by timestamp (newest first)
    items.sort((a, b) => b.timestamp - a.timestamp);
    
    return items;
  };

  // Handle Empty State - only show when truly empty (no memories or memos to display)
  if (devMode === 'empty' && memories.length === 0 && memos.length === 0) {
    return (
      <div className="flex flex-col h-full">
        <div className="bg-white border-b border-black/[0.06]">
          <div className="px-5 pt-4 pb-3 flex items-center justify-between">
            <h1 className="text-[34px] font-bold text-[#1c1c1e] tracking-tight">Memory</h1>
            <div className="flex items-center gap-2">
              <button 
                onClick={() => setShowSearch(true)}
                className="w-8 h-8 flex items-center justify-center text-[#007aff] hover:opacity-70 transition-opacity"
              >
                <Search className="w-5 h-5" strokeWidth={2.5} />
              </button>
            </div>
          </div>

          {/* Browse Mode Tabs */}
          <div className="px-5 pb-3">
            <div className="flex gap-2">
              <button
                onClick={() => setBrowseMode('time')}
                className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                  browseMode === 'time'
                    ? 'bg-[#007aff] text-white shadow-sm'
                    : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
                }`}
              >
                <div className="flex items-center justify-center gap-2">
                  <List className="w-4 h-4" strokeWidth={2} />
                  <span>All</span>
                </div>
              </button>
              
              <button
                onClick={() => setBrowseMode('people')}
                className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                  browseMode === 'people'
                    ? 'bg-[#007aff] text-white shadow-sm'
                    : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
                }`}
              >
                <div className="flex items-center justify-center gap-2">
                  <Users className="w-4 h-4" strokeWidth={2} />
                  <span>People</span>
                </div>
              </button>
              
              <button
                onClick={() => setBrowseMode('projects')}
                className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                  browseMode === 'projects'
                    ? 'bg-[#007aff] text-white shadow-sm'
                    : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
                }`}
              >
                <div className="flex items-center justify-center gap-2">
                  <FolderOpen className="w-4 h-4" strokeWidth={2} />
                  <span>Projects</span>
                </div>
              </button>
            </div>
          </div>
        </div>
        <EmptyState
          icon={<Brain className="w-16 h-16 text-[#007aff]" strokeWidth={1.5} />}
          title="No memories yet"
          description="Start recording to capture your first ideas and conversations."
          actionLabel="Start Recording"
          onAction={async () => {
            const hasPermission = await checkAndRequestPermission();
            if (hasPermission) setShowRecordingModal(true);
          }}
        />

        {/* Recording Modal */}
        {showRecordingModal && (
          <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => !hasStartedRecording && handleCloseRecordingModal()}>
            <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
              {/* Close Button - Top Right */}
              <button
                onClick={handleCloseRecordingModal}
                className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
              >
                <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
              </button>

              <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-6 text-center">Record Audio</h3>
              
              <div className={`flex flex-col items-center gap-4 ${hasStartedRecording ? 'mb-6' : 'mb-8'}`}>
                {/* Recording Time - Show when recording has started */}
                {hasStartedRecording && (
                  <div className="text-[32px] font-mono font-semibold text-[#1c1c1e] tabular-nums">
                    {formatTime(recordingTime)}
                  </div>
                )}
                
                <button
                  onClick={isRecording ? pauseRecording : startRecording}
                  className={`w-20 h-20 rounded-full flex items-center justify-center transition-all shadow-lg ${
                    !hasStartedRecording
                      ? 'bg-[#007aff] hover:bg-[#0051d5]' 
                      : isRecording 
                        ? 'bg-[#ff3b30] hover:bg-[#ff4d42]' 
                        : 'bg-[#ff3b30] hover:bg-[#ff4d42]'
                  }`}
                >
                  {!hasStartedRecording ? (
                    <Mic className="w-9 h-9 text-white" strokeWidth={2} />
                  ) : isRecording ? (
                    <Pause className="w-9 h-9 text-white" strokeWidth={2} />
                  ) : (
                    <Play className="w-9 h-9 text-white fill-white" strokeWidth={2} />
                  )}
                </button>
                
                <p className="text-[15px] text-[#3c3c43] text-center">
                  {!hasStartedRecording 
                    ? 'Tap to start recording' 
                    : isRecording 
                      ? 'Recording...' 
                      : 'Paused'}
                </p>
              </div>

              {/* Bottom Buttons - Show when has started recording */}
              {hasStartedRecording && (
                <div className="flex gap-3">
                  <button
                    onClick={() => setShowCancelConfirmModal(true)}
                    className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleSaveRecording}
                    className="flex-1 py-3 bg-[#007aff] rounded-[12px] text-white font-semibold hover:bg-[#0051d5] transition-colors"
                  >
                    Save
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Cancel Confirm Modal */}
        {showCancelConfirmModal && (
          <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => setShowCancelConfirmModal(false)}>
            <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
              {/* Close Button - Top Right */}
              <button
                onClick={() => setShowCancelConfirmModal(false)}
                className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
              >
                <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
              </button>

              <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-6 text-center">Cancel Recording</h3>
              
              <p className="text-[15px] text-[#3c3c43] text-center mb-6">
                Are you sure you want to cancel this recording? All progress will be lost.
              </p>

              {/* Bottom Buttons */}
              <div className="flex gap-3">
                <button
                  onClick={() => setShowCancelConfirmModal(false)}
                  className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
                >
                  No, Keep Recording
                </button>
                <button
                  onClick={handleConfirmCancel}
                  className="flex-1 py-3 bg-[#ff3b30] rounded-[12px] text-white font-semibold hover:bg-[#ff4d42] transition-colors"
                >
                  Yes, Cancel
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Handle Error State
  if (devMode === 'error') {
    return (
      <div className="flex flex-col h-full">
        <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
          <h1 className="text-[34px] font-bold text-[#1c1c1e] tracking-tight">Memory</h1>
        </div>
        <ErrorState
          title="Unable to load memories"
          description="Please check your connection and try again."
          onRetry={() => {
            console.log('Retry clicked');
          }}
        />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* Show Memo List Page */}
      {showMemoList ? (
        <MemoListPage 
          onBack={() => setShowMemoList(false)}
          onMemoClick={handleMemoClick}
          onCreateTodo={handleCreateTodoFromMemo}
          onRelatedMemoryClick={handleRelatedMemoryClick}
          onLinkMemory={handleLinkMemoryToMemo}
          onMemoryClick={handleMemoryClickFromMemo}
          onHighlightClick={handleHighlightClick}
          memos={memos}
          setMemos={setMemos}
        />
      ) : showCalendarPage ? (
        <CalendarPage 
          onBack={() => setShowCalendarPage(false)}
          onMemoryClick={(memory) => {
            setSourceContext('calendar');
            setSelectedMemory(memory);
            setIsNewlyGeneratedMemory(false);
            setShowCalendarPage(false);
          }}
          onDailyInsightClick={(insight) => {
            setSourceContext('calendar');
            setSelectedDailyInsight(insight);
            setShowCalendarPage(false);
          }}
          onWeeklyInsightClick={(insight) => {
            setSourceContext('calendar');
            setSelectedWeeklyInsight(insight);
            setShowCalendarPage(false);
          }}
          onMonthlyInsightClick={(insight) => {
            setSourceContext('calendar');
            setSelectedMonthlyInsight(insight);
            setShowCalendarPage(false);
          }}
          memos={memos}
          onMemoClick={(memo) => {
            setSourceContext('calendar');
            handleMemoClick(memo);
          }}
          todos={todos}
          setTodos={setTodos}
          onLinkMemory={onLinkMemory}
          onMemoryClickFromTodo={(memoryId) => {
            const memory = filteredMemories.find(m => m.id.toString() === memoryId);
            if (memory) {
              setSourceContext('calendar');
              setSelectedMemory(memory);
              setIsNewlyGeneratedMemory(false);
              setShowCalendarPage(false);
            }
          }}
          onActionClick={(action) => {
            // Open todo detail modal
            if (action.todoData) {
              setSelectedTodo(action.todoData);
              setShowCalendarPage(false);
            }
          }}
        />
      ) : !showSearch && !selectedMemory && !showPeoplePage && !selectedPerson && !selectedDailyInsight && !showDailyInsightsList && !selectedWeeklyInsight && !selectedMonthlyInsight && !selectedPatternInsight && !selectedProject ? (
        <>
          {/* Header with Calendar and Search Button */}
          <div className="bg-white border-b border-black/[0.06]">
            <div className="px-5 pt-4 pb-3 flex items-center justify-between">
              <h1 className="text-[34px] font-bold tracking-tight">Memory</h1>
              <div className="flex items-center gap-2">
                <button 
                  onClick={() => setShowSearch(true)}
                  className="w-8 h-8 flex items-center justify-center text-[#007aff] hover:opacity-70 transition-opacity"
                >
                  <Search className="w-5 h-5" strokeWidth={2.5} />
                </button>
              </div>
            </div>

            {/* Browse Mode Tabs */}
            <div className="px-5 pb-3">
              <div className="flex gap-2">
                <button
                  onClick={() => setBrowseMode('time')}
                  className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                    browseMode === 'time'
                      ? 'bg-[#007aff] text-white shadow-sm'
                      : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
                  }`}
                >
                  <div className="flex items-center justify-center gap-2">
                    <List className="w-4 h-4" strokeWidth={2} />
                    <span>All</span>
                  </div>
                </button>
                
                <button
                  onClick={() => setBrowseMode('people')}
                  className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                    browseMode === 'people'
                      ? 'bg-[#007aff] text-white shadow-sm'
                      : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
                  }`}
                >
                  <div className="flex items-center justify-center gap-2">
                    <Users className="w-4 h-4" strokeWidth={2} />
                    <span>People</span>
                  </div>
                </button>
                
                <button
                  onClick={() => setBrowseMode('projects')}
                  className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                    browseMode === 'projects'
                      ? 'bg-[#007aff] text-white shadow-sm'
                      : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
                  }`}
                >
                  <div className="flex items-center justify-center gap-2">
                    <FolderOpen className="w-4 h-4" strokeWidth={2} />
                    <span>Projects</span>
                  </div>
                </button>
              </div>
            </div>
          </div>

          <PullToRefresh onRefresh={handleRefresh}>
            {/* Time Mode - Original Memory List */}
            {browseMode === 'time' && (
              <>
                {/* Daily Insight Card & Memory timeline */}
                <div className="px-5 pt-6 pb-20 space-y-3">
                  
                  {/* Memos Card */}
                  <div className="hidden w-full bg-gradient-to-br from-[#fff4e8] via-[#fffaf2] to-white rounded-[20px] p-5 shadow-[0_3px_10px_rgba(255,159,64,0.08),0_1px_3px_rgba(255,159,64,0.05)] border border-[#ffb85c]/15">
                    <div className="flex items-center justify-between mb-3">
                      <h4 className="text-[14px] text-[#1c1c1e] font-semibold tracking-[-0.2px]">Memos</h4>
                      <button 
                        onClick={() => setShowMemoList(true)}
                        className="flex items-center gap-1 text-[#f59e42] text-[13px] font-medium hover:opacity-70 transition-opacity"
                      >
                        View All
                        <ChevronRight className="w-3.5 h-3.5" strokeWidth={2.5} />
                      </button>
                    </div>
                    <div className="space-y-2">
                      {memos.slice(0, 3).map((memo) => (
                        <button
                          key={memo.id}
                          onClick={() => handleMemoClick(memo)}
                          className="w-full text-left hover:opacity-70 transition-opacity"
                        >
                          <p className="text-[13px] text-[#6c6c70] leading-[1.5] line-clamp-2">
                            {memo.title}
                          </p>
                        </button>
                      ))}
                    </div>
                  </div>
                  
                  {/* Merged timeline: memories and memo groups sorted by time */}
                  {getMergedTimelineItems().map((item, globalIndex) => {
                    if (item.type === 'memoGroup') {
                      // Render memo group
                      const bgClass = globalIndex % 2 === 1 ? 'bg-[#fafafa]' : 'bg-white';
                      return <div key={`memo-${item.data.dateKey}`}>{renderMemoGroup(item.data.dateKey, bgClass)}</div>;
                    }
                    
                    // Render memory
                    const memory = item.data;
                    const index = item.index || 0;
                    const audioOnly = isAudioOnly(memory);
                    const isEven = globalIndex % 2 === 1;
                    
                    return (
                      <div key={memory.id} className="relative">
                        {/* Left purple indicator bar for new insights */}
                        {memory.hasNewInsights && !viewedMemoryIds.has(memory.id) && (
                          <div className="absolute left-0 top-0 bottom-0 w-1 bg-[#7c3aed] rounded-l-2xl" />
                        )}
                        
                        <button
                          onClick={() => {
                            setSourceContext('list');
                            setSelectedMemory(memory);
                            setIsNewlyGeneratedMemory(false);
                            // Mark this memory as viewed
                            if (memory.hasNewInsights) {
                              setViewedMemoryIds(prev => new Set(prev).add(memory.id));
                            }
                          }}
                          className={`w-full p-5 rounded-2xl border text-left hover:bg-secondary/30 transition-colors ${
                            memory.hasNewInsights && !viewedMemoryIds.has(memory.id)
                              ? 'border-[#7c3aed]/30 bg-white shadow-[0_2px_8px_rgba(124,58,237,0.12)]'
                              : isEven 
                                ? 'border-border bg-[#fafafa] shadow-[0_1px_3px_rgba(0,0,0,0.08)]' 
                                : 'border-border bg-white shadow-[0_1px_2px_rgba(0,0,0,0.06)]'
                          }`}
                        >
                          {audioOnly ? (
                            // Audio-only layout
                            <>
                              {/* Line 1: Main title (date) */}
                              <h3 className="mb-2 leading-snug text-[20px] font-semibold">
                                {memory.date}
                              </h3>
                              
                              {/* Line 2: Subtitle (full date and time) */}
                              <div className="mb-2">
                                <span className="text-[14px] text-[#8e8e93]">{memory.dateSubtitle}</span>
                              </div>
                              
                              {/* Line 3: Source (left) and Duration (right) */}
                              <div className="flex items-center justify-between">
                                <div className="flex items-center gap-1.5 text-[14px] text-[#8e8e93]">
                                  {getSourceIcon(memory.audioSource)}
                                  <span>{memory.audioSource}</span>
                                </div>
                                <span className="text-[14px] text-[#8e8e93]">{memory.audioDuration}</span>
                              </div>
                            </>
                          ) : (
                            // Regular memory layout
                            <>
                              {/* Title and Date with badge */}
                              <div className="mb-3 relative">
                                <div className="flex items-start justify-between gap-2">
                                  <h3 className="mb-1 leading-snug flex-1">
                                    {memory.title}
                                  </h3>
                                  {/* Right top corner badge */}
                                  {memory.hasNewInsights && !viewedMemoryIds.has(memory.id) && memory.newInsightsCount > 0 && (
                                    <div className="flex-shrink-0 min-w-[20px] h-[20px] bg-[#7c3aed] rounded-full flex items-center justify-center px-1.5">
                                      <span className="text-[11px] font-semibold text-white leading-none">
                                        {memory.newInsightsCount}
                                      </span>
                                    </div>
                                  )}
                                </div>
                                <div className="flex items-center gap-1.5">
                                  <span className="text-sm text-muted-foreground">{memory.date}</span>
                                  {memory.hasNewInsights && !viewedMemoryIds.has(memory.id) && (
                                    <>
                                      <span className="text-sm text-muted-foreground">·</span>
                                      <span className="text-sm text-[#7c3aed] font-medium">New updates</span>
                                    </>
                                  )}
                                </div>
                              </div>

                              {/* Summary */}
                              {memory.summary && (
                                <p className="text-[14px] text-[#6c6c70] leading-[1.5] mb-3 line-clamp-2">
                                  {memory.summary}
                                </p>
                              )}

                              {/* Indicators - no audio duration for non-audio-only */}
                              <div className="flex gap-3">
                                {memory.hasAudio && (
                                  <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
                                    {getSourceIcon(memory.audioSource)}
                                    <span>Audio</span>
                                  </div>
                                )}
                                {memory.hasSummary && (
                                  <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
                                    <Sparkles className="w-4 h-4" />
                                    <span>Summary</span>
                                  </div>
                                )}
                                {hasActivity(memory) && (
                                  <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
                                    <Activity className="w-4 h-4" />
                                    <span>Activity</span>
                                  </div>
                                )}
                              </div>
                            </>
                          )}
                        </button>
                      </div>
                    );
                  })}
                </div>
              </>
            )}

            {/* People Mode - Embedded PeoplePage content */}
            {browseMode === 'people' && (
              <PeoplePage 
                onBack={() => {}} // No back button in tab mode
                onPersonClick={(personName) => {
                  setSelectedPerson(personName);
                }}
                hideHeader={true} // Hide header when embedded in tab
              />
            )}

            {/* Projects Mode - Project List */}
            {browseMode === 'projects' && (
              <div className="px-5 pt-5 pb-20">
                {/* Projects Header */}
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-[22px] font-semibold text-[#1c1c1e]">
                    Projects <span className="text-[#8e8e93]">({devMode === 'empty' ? 0 : projectsData.length})</span>
                  </h2>
                  <button 
                    onClick={() => setShowCreateProjectModal(true)}
                    className="text-[17px] text-[#007aff] font-normal hover:opacity-70 transition-opacity"
                  >
                    + New
                  </button>
                </div>

                {/* Project Cards - Hide in empty mode */}
                {devMode === 'empty' ? (
                  <div className="flex flex-col items-center justify-center py-20">
                    <p className="text-[15px] text-[#8e8e93] text-center">
                      No projects yet
                    </p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {projectsData.map((project) => (
                      <button 
                        key={project.id}
                        onClick={() => setSelectedProject(project)}
                        className="w-full bg-white rounded-[16px] shadow-sm border border-black/[0.06] p-4 text-left hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors"
                      >
                        <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">
                          {project.name}
                        </h3>
                        <div className="flex items-center gap-1.5 mb-1.5">
                          <span className="text-[14px] text-[#8e8e93]">Updated {project.updateTime}</span>
                          <span className="text-[#8e8e93]">·</span>
                          <span className="text-[14px] text-[#8e8e93]">{project.memoryCount} memories</span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          <span className="text-[13px] text-[#6c6c70]">Last activity</span>
                          <span className="text-[#6c6c70]">·</span>
                          <span className="text-[13px] text-[#6c6c70]">{project.lastActivity}</span>
                        </div>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </PullToRefresh>
        </>
      ) : selectedMemory ? (
        // Memory Detail View - Choose based on type
        isAudioOnly(selectedMemory) ? (
          <AudioMemoryDetail 
            memory={selectedMemory}
            onClose={() => {
              if (fromPatternInsight) {
                // Go back to Pattern Insight detail page
                setSelectedMemory(null);
                setFromPatternInsight(false);
                // Keep selectedPatternInsight so we return to it
              } else {
                setSelectedMemory(null);
              }
            }}
            onSummarize={() => {
              setIsGeneratingSummary(true);
              setGeneratingMemory(selectedMemory);
              setTimeout(() => {
                setIsGeneratingSummary(false);
              }, 3000); // Simulate a 3-second summary generation
            }}
          />
        ) : hasActivity(selectedMemory) ? (
          <MemoryActivityFlow 
            memory={selectedMemory}
            onClose={() => {
              // Reset memory detail params
              setMemoryInitialTab('Overview');
              setMemoryHighlightTimestamp(undefined);
              if (fromPatternInsight) {
                // Go back to Pattern Insight detail page
                setSelectedMemory(null);
                setFromPatternInsight(false);
                setIsNewlyGeneratedMemory(false);
                // Keep selectedPatternInsight so we return to it
              } else {
                setSelectedMemory(null);
                setIsNewlyGeneratedMemory(false);
              }
            }}
            onAddTodo={onAddTodo}
            isNewlyGenerated={isNewlyGeneratedMemory}
            onCreateProject={handleCreateProject}
            allProjects={projectsData.map(p => ({ id: p.id, name: p.name }))}
            linkedProjectIds={projectsData.filter(p => p.memories.some(m => m.id === selectedMemory.id)).map(p => p.id)}
            onUpdateLinkedProjects={(memoryId, projectIds) => {
              setProjectsData(prevProjects =>
                prevProjects.map(project => {
                  const shouldInclude = projectIds.includes(project.id);
                  const currentlyIncludes = project.memories.some(m => m.id === memoryId);
                  
                  if (shouldInclude && !currentlyIncludes) {
                    const memory = memories.find(m => m.id === memoryId);
                    return {
                      ...project,
                      memories: [...project.memories, { id: memoryId, title: memory?.title || 'Untitled', date: memory?.date || 'today' }],
                      memoryCount: project.memories.length + 1,
                      updateTime: 'today'
                    };
                  } else if (!shouldInclude && currentlyIncludes) {
                    return {
                      ...project,
                      memories: project.memories.filter(m => m.id !== memoryId),
                      memoryCount: project.memories.length - 1,
                      updateTime: 'today'
                    };
                  }
                  return project;
                })
              );
            }}
            memos={memos}
            onCreateMemo={onCreateMemo}
            onUpdateMemo={onUpdateMemo}
            onAnalyzeActions={onAnalyzeActions}
            initialTab={memoryInitialTab}
            highlightTimestamp={memoryHighlightTimestamp}
          />
        ) : (
          <MemoryDetail 
            memory={selectedMemory}
            onClose={() => {
              // Reset memory detail params
              setMemoryInitialTab('Overview');
              setMemoryHighlightTimestamp(undefined);
              if (fromPatternInsight) {
                // Go back to Pattern Insight detail page
                setSelectedMemory(null);
                setFromPatternInsight(false);
                // Keep selectedPatternInsight so we return to it
              } else if (sourceContext === 'calendar') {
                // Return to calendar page
                setSelectedMemory(null);
                setShowCalendarPage(true);
              } else {
                // Return to memory list
                setSelectedMemory(null);
              }
            }}
            onGenerateResummary={() => {
              // Start generating resummary process
              setGeneratingMemory(selectedMemory);
              setSelectedMemory(null);
              setIsGeneratingSummary(true);
            }}
            onCreateProject={handleCreateProject}
            allProjects={projectsData.map(p => ({ id: p.id, name: p.name }))}
            linkedProjectIds={projectsData.filter(p => p.memories.some(m => m.id === selectedMemory.id)).map(p => p.id)}
            onUpdateLinkedProjects={(memoryId, projectIds) => {
              setProjectsData(prevProjects =>
                prevProjects.map(project => {
                  const shouldInclude = projectIds.includes(project.id);
                  const currentlyIncludes = project.memories.some(m => m.id === memoryId);
                  
                  if (shouldInclude && !currentlyIncludes) {
                    const memory = memories.find(m => m.id === memoryId);
                    return {
                      ...project,
                      memories: [...project.memories, { id: memoryId, title: memory?.title || 'Untitled', date: memory?.date || 'today' }],
                      memoryCount: project.memories.length + 1,
                      updateTime: 'today'
                    };
                  } else if (!shouldInclude && currentlyIncludes) {
                    return {
                      ...project,
                      memories: project.memories.filter(m => m.id !== memoryId),
                      memoryCount: project.memories.length - 1,
                      updateTime: 'today'
                    };
                  }
                  return project;
                })
              );
            }}
            initialTab={memoryInitialTab}
            highlightTimestamp={memoryHighlightTimestamp}
          />
        )
      ) : showPeoplePage ? (
        <PeoplePage 
          onBack={() => setShowPeoplePage(false)}
          onPersonClick={(personName) => {
            // Receive person name directly
            setSelectedPerson(personName);
            setShowPeoplePage(false);
          }}
        />
      ) : selectedPerson ? (
        <PersonDetail 
          personName={selectedPerson}
          onBack={() => {
            setSelectedPerson(null);
            setShowPeoplePage(true);
          }}
          todos={todos}
          onMarkDone={onMarkDone}
          onNotNow={onNotNow}
          onDeleteTodo={onDeleteTodo}
          onUpdateTodo={onUpdateTodo}
        />
      ) : selectedDailyInsight ? (
        <DailyInsightDetail 
          insight={selectedDailyInsight}
          onClose={() => {
            setSelectedDailyInsight(null);
            if (sourceContext === 'calendar') {
              // Return to calendar page
              setShowCalendarPage(true);
            } else {
              // Return to insights list
              setShowDailyInsightsList(true);
            }
          }}
          onAddTodo={onAddTodo}
        />
      ) : showDailyInsightsList ? (
        <AllInsightsListPage 
          onBack={() => setShowDailyInsightsList(false)}
          onDailyInsightClick={(insight) => {
            setSourceContext('list');
            setSelectedDailyInsight(insight);
            setShowDailyInsightsList(false);
          }}
          onWeeklyInsightClick={(insight) => {
            setSourceContext('list');
            setSelectedWeeklyInsight(insight);
            setShowDailyInsightsList(false);
          }}
          onMonthlyInsightClick={(insight) => {
            setSourceContext('list');
            setSelectedMonthlyInsight(insight);
            setShowDailyInsightsList(false);
          }}
          onPatternInsightClick={(insight) => {
            setSourceContext('list');
            setSelectedPatternInsight(insight);
            setShowDailyInsightsList(false);
            // Mark pattern insight as viewed
            setViewedPatternInsightIds(prev => new Set(prev).add(insight.id));
          }}
          viewedPatternInsightIds={viewedPatternInsightIds}
        />
      ) : selectedWeeklyInsight ? (
        <WeeklyInsightDetail 
          insight={selectedWeeklyInsight}
          onClose={() => {
            setSelectedWeeklyInsight(null);
            if (sourceContext === 'calendar') {
              // Return to calendar page
              setShowCalendarPage(true);
            } else {
              // Return to insights list
              setShowDailyInsightsList(true);
            }
          }}
          todos={todos}
          onMarkDone={onMarkDone}
          onNotNow={onNotNow}
          onDelete={onDeleteTodo}
          onUpdateTodo={onUpdateTodo}
          onAddTodo={onAddTodo}
        />
      ) : selectedMonthlyInsight ? (
        <MonthlyInsightDetail 
          insight={selectedMonthlyInsight}
          onClose={() => {
            setSelectedMonthlyInsight(null);
            if (sourceContext === 'calendar') {
              // Return to calendar page
              setShowCalendarPage(true);
            } else {
              // Return to insights list
              setShowDailyInsightsList(true);
            }
          }}
          onAddTodo={onAddTodo}
        />
      ) : selectedPatternInsight ? (
        <PatternInsightDetail 
          insight={selectedPatternInsight}
          onBack={() => {
            setSelectedPatternInsight(null);
            setShowDailyInsightsList(true);
          }}
          onMemoryClick={(memoryId) => {
            // Find the memory and display it
            const memory = memories.find(m => m.id === parseInt(memoryId));
            if (memory) {
              setSelectedMemory(memory);
              setFromPatternInsight(true); // Mark that we came from Pattern Insight
            }
          }}
          onAddTodo={onAddTodo}
          onCreateTodo={(todoTitle) => {
            if (onAddTodo) {
              const newTodo = {
                text: todoTitle,
                completed: false,
                category: 'Today',
                isNew: true
              };
              onAddTodo(newTodo);
            }
          }}
        />
      ) : selectedProject ? (
        <ProjectDetail 
          project={{
            ...selectedProject,
            // Dynamically get todos from memories linked to this project
            todos: (() => {
              // Get all memory IDs from this project
              const memoryIds = selectedProject.memories.map((m: any) => m.id);
              
              // Find all todos that are linked to these memories
              const projectTodos = (todos || [])
                .filter((todo: any) => todo.memoryId && memoryIds.includes(todo.memoryId))
                .map((todo: any) => ({
                  id: todo.id,
                  title: todo.text,
                  dueDate: todo.dueDate,
                  dueTime: todo.dueTime,
                  completed: todo.completed,
                  completedDate: todo.completedDate,
                  memoryId: todo.memoryId
                }));
              
              return projectTodos;
            })(),
            todoCount: (() => {
              const memoryIds = selectedProject.memories.map((m: any) => m.id);
              return (todos || []).filter((todo: any) => todo.memoryId && memoryIds.includes(todo.memoryId)).length;
            })()
          }}
          onBack={() => setSelectedProject(null)}
          onMemoryClick={(memoryId) => {
            // Find the memory and navigate to it
            const memory = memories.find(m => m.id === memoryId);
            if (memory) {
              setSelectedMemory(memory);
              setIsNewlyGeneratedMemory(false);
            }
          }}
          allMemories={memories}
          onUpdateProject={handleUpdateProject}
          onRemoveMemory={handleRemoveMemoryFromProject}
          onRenameProject={(projectId, newName) => {
            // Update the project name in the projects array
            setProjectsData(prevProjects => 
              prevProjects.map(p => 
                p.id === projectId ? { ...p, name: newName } : p
              )
            );
            // Also update the selected project
            if (selectedProject && selectedProject.id === projectId) {
              setSelectedProject({ ...selectedProject, name: newName });
            }
          }}
          onRegenerateOverview={(projectId) => {
            console.log('Regenerate overview for project:', projectId);
            // TODO: Implement regenerate overview functionality
          }}
          onDeleteProject={(projectId) => {
            handleDeleteProject(projectId);
          }}
          onOpenTodo={(todoId) => {
            // Find the todo and open the detail modal
            const todo = todos?.find(t => t.id === todoId);
            if (todo) {
              setSelectedTodo(todo);
            }
          }}
          onToggleTodo={(todoId) => {
            // Toggle the todo completion status
            if (onMarkDone && !todos?.find(t => t.id === todoId)?.completed) {
              onMarkDone(todoId);
            } else if (onUpdateTodo) {
              const todo = todos?.find(t => t.id === todoId);
              onUpdateTodo(todoId, { 
                completed: !todo?.completed,
                completedDate: !todo?.completed ? new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : undefined
              });
            }
          }}
        />
      ) : (
        // Search View
        <div className="flex flex-col h-full bg-white">
          {/* Search Header */}
          <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06]">
            <div className="flex items-center gap-2 flex-1">
              <button
                onClick={() => setShowSearch(false)}
                className="text-[#007aff] hover:opacity-70 transition-opacity"
              >
                <ChevronLeft className="w-6 h-6" strokeWidth={2} />
              </button>
              <button
                onClick={() => setShowSearch(false)}
                className="text-[17px] font-semibold hover:opacity-70 transition-opacity"
              >
                Search memories
              </button>
            </div>
            <button
              onClick={() => {
                setShowSearch(false);
                setSearchQuery('');
              }}
              className="w-8 h-8 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
            >
              <X className="w-5 h-5" strokeWidth={2.5} />
            </button>
          </div>

          {/* Search Input */}
          <div className="px-5 pt-4">
            <div className="flex items-center gap-2 bg-[#f2f2f7] rounded-[12px] px-4 py-3">
              <Search className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by people, topic, or keywords..."
                className="flex-1 bg-transparent outline-none text-[17px] text-[#1c1c1e] placeholder:text-[#8e8e93]"
                autoFocus
              />
            </div>
          </div>

          {/* Suggestions */}
          <div className="px-5 pt-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3">Suggestions</h3>
            <div className="space-y-2">
              {suggestions.map((suggestion, index) => (
                <button
                  key={index}
                  onClick={() => setSearchQuery(suggestion)}
                  className="w-full text-left py-3 px-4 rounded-[12px] hover:bg-[#f2f2f7] transition-colors flex items-center gap-3"
                >
                  <div className="w-1 h-1 rounded-full bg-[#8e8e93]" />
                  <span className="text-[17px] text-[#1c1c1e]">{suggestion}</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Calendar Picker Modal */}
      {showCalendar && (
        <CalendarPicker 
          onClose={() => setShowCalendar(false)}
          onSelectDate={(date) => {
            setSelectedDate(date);
            console.log('Selected date:', date);
            // TODO: Filter memories by selected date
          }}
        />
      )}

      {/* Generating Resummary Page */}
      {isGeneratingSummary && generatingMemory && (
        <GeneratingResummaryPage 
          memory={generatingMemory}
          onBack={() => {
            setIsGeneratingSummary(false);
            setGeneratingMemory(null);
            setSelectedMemory(null);
          }}
        />
      )}

      {/* Create Project with Memories Modal */}
      <CreateProjectWithMemoriesModal 
        isOpen={showCreateProjectModal}
        onClose={() => setShowCreateProjectModal(false)}
        onCreate={(projectName, selectedMemoryIds) => {
          // Create new project ID
          const newProjectId = Date.now().toString();
          
          // Get selected memories
          const selectedMemoriesData = memories.filter(m => selectedMemoryIds.includes(m.id));
          
          // Create new project with selected memories
          const newProject = {
            id: newProjectId,
            name: projectName,
            memoryCount: selectedMemoriesData.length,
            updateTime: 'today',
            lastActivity: selectedMemoriesData.length > 0 ? 'Created with memories' : 'Just created',
            overview: {
              summary: selectedMemoriesData.length > 0 
                ? `Project created with ${selectedMemoriesData.length} ${selectedMemoriesData.length === 1 ? 'memory' : 'memories'}`
                : 'New project',
              decisionTimeline: [],
              recurringThemes: [],
              currentStatus: 'Just created'
            },
            memories: selectedMemoriesData.map(m => ({
              id: m.id,
              title: m.title || 'Audio only',
              date: m.date
            }))
          };
          
          // Add project to projects data
          setProjectsData(prev => [...prev, newProject]);
        }}
        allMemories={memories}
      />

      {/* New Todo From Memo Modal */}
      {showNewTodoFromMemoModal && newTodoFromMemo && onAddTodo && (
        <NewTodoFromMemoModal
          isOpen={showNewTodoFromMemoModal}
          onClose={() => {
            setShowNewTodoFromMemoModal(false);
            setNewTodoFromMemo(null);
            // Clear the saved memo reference
            setMemoToRestoreAfterTodo(null);
          }}
          onSaveTodo={(newTodo) => {
            onAddTodo(newTodo);
            // Mark this memo as having a todo created
            if (onUpdateMemo) {
              onUpdateMemo(newTodoFromMemo.id, { todoCreated: true });
            }
            setShowNewTodoFromMemoModal(false);
            setNewTodoFromMemo(null);
            // Clear the saved memo reference
            setMemoToRestoreAfterTodo(null);
          }}
          todo={{
            id: Date.now(),
            title: newTodoFromMemo.title,
            completed: false,
            category: 'Today',
            notes: newTodoFromMemo.content ? [newTodoFromMemo.content] : [],
            priority: 'Normal',
            dueDate: 'No deadline'
          }}
        />
      )}

      {/* Memo Detail Modal */}
      {selectedMemo && (
        <MemoDetailModal
          memo={selectedMemo}
          memos={memos}
          onClose={() => {
            setSelectedMemo(null);
            // If we came from calendar, we're already there since modal is overlay
            // So we don't need to navigate back - just close the modal
          }}
          onDelete={handleDeleteMemo}
          onCreateTodo={handleCreateTodoFromMemo}
          onAnalyzeActions={onAnalyzeActions}
          onRelatedMemoryClick={handleRelatedMemoryClick}
          onLinkMemory={handleLinkMemoryToMemo}
          onMemoryClick={handleMemoryClickFromMemo}
          onHighlightClick={handleHighlightClick}
        />
      )}

      {/* Memory List Selector for linking to memos */}
      {showMemorySelector && (
        <MemoryListSelector
          onBack={() => {
            setShowMemorySelector(false);
            setMemoForMemoryLink(null);
          }}
          onSelectMemory={handleSelectMemoryForMemo}
          memories={memories}
        />
      )}

      {/* Todo Detail Modal */}
      {selectedTodo && (
        <TodoDetailModal
          todo={selectedTodo}
          onClose={() => {
            setSelectedTodo(null);
            setShowCalendarPage(true); // Return to calendar page
          }}
          onMarkDone={onMarkDone}
          onNotNow={onNotNow}
          onDelete={onDeleteTodo}
          onUpdate={onUpdateTodo}
          onMemoryClick={handleMemoryClickFromTodo}
        />
      )}

      {/* Microphone Permission Modal */}
      <MicrophonePermissionModal
        isOpen={showMicPermissionModal}
        onContinue={handlePermissionContinue}
        onNotNow={handlePermissionNotNow}
      />

      {/* Microphone Permission Denied Modal */}
      <MicrophonePermissionDeniedModal
        isOpen={showMicPermissionDeniedModal}
        onClose={() => setShowMicPermissionDeniedModal(false)}
        onOpenSettings={handleOpenSettings}
      />
    </div>
  );
}