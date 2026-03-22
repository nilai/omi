import { useState, useEffect } from 'react';
import { Home, BookOpen, Sparkles, Settings } from 'lucide-react';
import { HomeTab } from './components/HomeTab';
import { MemoryTab } from './components/MemoryTab';
import { AskAITab } from './components/AskAITab';
import { PreferencesTab } from './components/PreferencesTab';
import { MinimizedRecordingBar } from './components/MinimizedRecordingBar';
import { VoiceprintProvider } from './contexts/VoiceprintContext';
import { UserProvider, useUser } from './contexts/UserContext';
import { AudioStatusProvider } from './contexts/AudioStatusContext';
import { DevModeProvider } from './contexts/DevModeContext';
import { MicrophonePermissionProvider } from './contexts/MicrophonePermissionContext';
import { LoginModal } from './components/LoginModal';

type TabId = 'home' | 'memory' | 'ask-ai' | 'preferences';

interface Tab {
  id: TabId;
  label: string;
  icon: typeof Home;
  component: React.ComponentType;
}

// Main App Content - requires authentication
function AppContent() {
  const { isLoggedIn } = useUser();
  const [activeTab, setActiveTab] = useState<TabId>('home');
  
  // Recording state lifted to App level so minimized bar can be shown across all tabs
  const [isRecordingMinimized, setIsRecordingMinimized] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [recordingTime, setRecordingTime] = useState(0);
  
  const handleToggleRecordingPause = () => {
    setIsRecording(!isRecording);
  };
  
  const handleExpandRecording = () => {
    setIsRecordingMinimized(false);
  };
  
  const handleMinimizeRecording = () => {
    setIsRecordingMinimized(true);
  };
  
  const handleStopRecording = () => {
    setIsRecordingMinimized(false);
    setIsRecording(false);
    setRecordingTime(0);
  };
  
  // Timer effect for recording - continues when minimized
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null;
    
    if (isRecording) {
      interval = setInterval(() => {
        setRecordingTime((prev) => {
          // Max 60 minutes = 3600 seconds
          if (prev >= 3600) {
            if (interval) clearInterval(interval);
            setIsRecording(false);
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
  
  // Lift todos state to App level so it can be shared between tabs
  const [todos, setTodos] = useState([
    // Up Next (最多4个)
    { 
      id: 1, 
      text: 'Review migration milestones with infrastructure team',
      title: 'Review migration milestones with infrastructure team', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      memoryId: 1,
      notes: 'Need to confirm their availability for next sprint\nFocus on authentication service timeline', 
      priority: 'High priority', 
      dueDate: 'Mar 10',
      dueTime: '09:00',
      time: '09:00',
      category: 'Up Next',
      completed: false,
      reason: 'Meeting scheduled today'
    },
    { 
      id: 3, 
      text: 'Follow up with Sarah about design feedback',
      title: 'Follow up with Sarah about design feedback', 
      linkedMemory: {
        id: '3',
        title: 'Review session for new dashboard designs',
        date: 'Jan 27',
        duration: '15 min',
        hasSummary: true
      },
      memoryId: 3,
      notes: 'Wait for her return from vacation', 
      priority: 'Normal', 
      dueDate: 'Mar 10',
      dueTime: '14:00',
      time: '14:00',
      category: 'Up Next',
      completed: false,
      reason: 'Design feedback pending'
    },
    { 
      id: 4, 
      text: 'Finalize API migration timeline',
      title: 'Finalize API migration timeline', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      memoryId: 1,
      notes: 'Include authentication service and parallel execution strategy', 
      priority: 'High priority', 
      dueDate: 'Mar 11',
      dueTime: '16:30',
      time: '16:30',
      category: 'Up Next',
      completed: false,
      reason: 'Project deadline soon'
    },
    // Today
    { 
      id: 5, 
      text: 'Update API documentation for v2 endpoints',
      title: 'Update API documentation for v2 endpoints', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      memoryId: 1,
      notes: 'Confirm final numbers', 
      priority: 'High priority', 
      dueDate: 'Mar 9',
      dueTime: '09:00',
      time: '09:00',
      category: 'Today',
      completed: false
    },
    { 
      id: 6, 
      text: 'Review budget notes',
      title: 'Review budget notes', 
      priority: 'Normal', 
      dueDate: 'Mar 9',
      dueTime: '11:00',
      category: 'Today',
      completed: false
    },
    { 
      id: 7, 
      text: 'Revise marketing deck with ADHD-focused messaging',
      title: 'Revise marketing deck with ADHD-focused messaging', 
      linkedMemory: {
        id: '7',
        title: 'Product launch planning with marketing team',
        date: 'Today',
        duration: '22 min',
        hasSummary: true
      },
      memoryId: 7,
      notes: 'Lead with user stories\nRemove generic productivity language\nGet feedback from beta users',
      priority: 'High priority', 
      dueDate: 'Mar 10',
      dueTime: '14:00',
      time: '14:00',
      category: 'Today',
      completed: false
    },
    { 
      id: 8, 
      text: 'Update pitch deck with Q1 metrics',
      title: 'Update pitch deck with Q1 metrics', 
      linkedMemory: {
        id: '8',
        title: 'Investor meeting - Series A funding discussion',
        date: 'Yesterday',
        duration: '45 min',
        hasSummary: true
      },
      memoryId: 8,
      notes: 'Include retention numbers and unit economics',
      priority: 'High priority', 
      dueDate: 'Mar 12',
      dueTime: '10:00',
      time: '10:00',
      category: 'Today',
      completed: false
    },
    // Upcoming
    { 
      id: 9, 
      text: 'Schedule follow-up with lead investor',
      title: 'Schedule follow-up with lead investor', 
      linkedMemory: {
        id: '8',
        title: 'Investor meeting - Series A funding discussion',
        date: 'Yesterday',
        duration: '45 min',
        hasSummary: true
      },
      memoryId: 8,
      notes: 'Confirm availability for next week', 
      priority: 'High priority', 
      dueDate: 'Mar 15',
      dueTime: '10:00',
      time: '10:00',
      category: 'Upcoming',
      completed: false
    },
    { 
      id: 10, 
      text: 'Prepare beta onboarding materials',
      title: 'Prepare beta onboarding materials',
      linkedMemory: {
        id: '7',
        title: 'Product launch planning with marketing team',
        date: 'Today',
        duration: '22 min',
        hasSummary: true
      },
      memoryId: 7,
      notes: 'Include welcome email and setup guide',
      priority: 'Normal', 
      dueDate: 'Mar 20',
      dueTime: '14:00',
      time: '14:00',
      category: 'Upcoming',
      completed: false
    },
    { 
      id: 11, 
      text: 'Schedule team building event',
      title: 'Schedule team building event', 
      linkedMemory: {
        id: '2',
        title: 'Coffee chat with Jordan about team dynamics',
        date: 'Jan 28',
        duration: '8 min',
        hasSummary: true
      },
      priority: 'Low priority', 
      dueDate: 'Mar 12, 2026',
      time: '16:00',
      category: 'Upcoming',
      completed: false
    },
    { 
      id: 12, 
      text: 'Research new collaboration tools',
      title: 'Research new collaboration tools', 
      priority: 'Low priority', 
      dueDate: 'Mar 9, 2026',
      time: '11:30',
      category: 'Upcoming',
      completed: false
    },
    // Later
    { 
      id: 13, 
      text: 'Explore productivity ideas',
      title: 'Explore productivity ideas', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      priority: 'Low priority', 
      dueDate: 'Aug 10, 2026',
      time: '09:30',
      category: 'Later',
      completed: false
    },
    { 
      id: 14, 
      text: 'Organize old notes',
      title: 'Organize old notes', 
      linkedMemory: {
        id: '3',
        title: 'Review session for new dashboard designs',
        date: 'Jan 27',
        duration: '15 min',
        hasSummary: true
      },
      priority: 'Low priority', 
      dueDate: 'Mar 18, 2026',
      time: '15:30',
      category: 'Later',
      completed: false
    },
    { 
      id: 15, 
      text: 'Clean up desktop',
      title: 'Clean up desktop', 
      priority: 'Low priority', 
      dueDate: 'Aug 18, 2026',
      time: '11:00',
      category: 'Later',
      completed: false
    },
    { 
      id: 16, 
      text: 'Read through archive folder',
      title: 'Read through archive folder', 
      priority: 'Low priority', 
      dueDate: 'Apr 5, 2026',
      time: '10:00',
      category: 'Later',
      completed: false
    },
    { 
      id: 17, 
      text: 'Review industry reports',
      title: 'Review industry reports', 
      linkedMemory: {
        id: '2',
        title: 'Coffee chat with Jordan about team dynamics',
        date: 'Jan 28',
        duration: '8 min',
        hasSummary: true
      },
      priority: 'Low priority', 
      dueDate: 'Mar 20, 2026',
      time: '13:00',
      category: 'Later',
      completed: false
    },
    // Overdue
    { 
      id: 18, 
      text: 'Send invoice',
      title: 'Send invoice', 
      priority: 'Normal', 
      dueDate: 'Mar 4, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 19, 
      text: 'Submit expense report',
      title: 'Submit expense report', 
      priority: 'Normal', 
      dueDate: 'Mar 3, 2026',
      time: '14:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 20, 
      text: 'Review investor deck',
      title: 'Review investor deck', 
      priority: 'High priority', 
      dueDate: 'Mar 3, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 21, 
      text: 'Send contract to supplier',
      title: 'Send contract to supplier', 
      priority: 'Normal', 
      dueDate: 'Mar 2, 2026',
      time: '16:30',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 22, 
      text: 'Follow up with design agency',
      title: 'Follow up with design agency', 
      priority: 'Normal', 
      dueDate: 'Mar 2, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 23, 
      text: 'Update product roadmap',
      title: 'Update product roadmap', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      priority: 'Normal', 
      dueDate: 'Mar 1, 2026',
      time: '15:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 24, 
      text: 'Confirm venue for team meetup',
      title: 'Confirm venue for team meetup', 
      priority: 'Normal', 
      dueDate: 'Feb 28, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 25, 
      text: 'Prepare marketing report',
      title: 'Prepare marketing report', 
      priority: 'Normal', 
      dueDate: 'Feb 27, 2026',
      time: '14:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 26, 
      text: 'Respond to partnership email',
      title: 'Respond to partnership email', 
      priority: 'Normal', 
      dueDate: 'Feb 26, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 27, 
      text: 'Archive old project documents',
      title: 'Archive old project documents', 
      priority: 'Low priority', 
      dueDate: 'Feb 24, 2026',
      time: '13:00',
      category: 'Overdue',
      completed: false
    }
  ]);

  const handleAddTodo = (newTodo: any) => {
    const todoToAdd = {
      ...newTodo,
      id: Date.now(),
      category: 'Today', // New todos from expert insights go to Today, not Up Next
      completed: false
    };
    
    setTodos([...todos, todoToAdd]);
  };

  const handleMarkDone = (id: number) => {
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, completed: true, category: 'Completed' } : todo
    ));
  };

  const handleNotNow = (id: number) => {
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, category: 'Later' } : todo
    ));
  };

  const handleDeleteTodo = (id: number) => {
    setTodos(todos.filter(todo => todo.id !== id));
  };

  const handleUpdateTodo = (id: number, updates: any) => {
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, ...updates } : todo
    ));
  };

  // Lift memories state to App level so it can be shared between HomeTab and MemoryTab
  const [memories, setMemories] = useState([
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
      newInsightsCount: 1,
      time: '2h ago',
      content: 'Discussed the timeline for migrating to the new API. The team agreed to start with non-critical endpoints first. Sarah mentioned potential issues with authentication that we need to address.',
      relatedMemories: ['Previous API architecture meeting', 'Technical debt discussion']
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
      newInsightsCount: 3,
      time: '3h ago',
      content: 'Finalized the go-to-market strategy. Team proposed a three-phase rollout starting with beta users.',
      relatedMemories: []
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
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone',
      time: 'Yesterday',
      content: 'Presented growth metrics to potential lead investor. Strong interest in retention numbers.',
      relatedMemories: []
    },
    {
      id: 2,
      title: 'Coffee chat with Jordan about team dynamics',
      summary: 'Explored ideas for differentiation in competitive market. Jordan suggested focusing on user experience for neurodivergent users as unique positioning.',
      date: 'Yesterday, 2:15 PM',
      hasAudio: true,
      hasSummary: true,
      hasActivity: false,
      audioDuration: '8m42s',
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone',
      time: '5h ago',
      content: 'Had a great conversation about improving team communication. Jordan suggested weekly sync-ups and more async updates. We also talked about the new hire onboarding process.',
      relatedMemories: ['Team retrospective notes']
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
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone',
      time: 'Jan 21',
      content: 'January 21, 2026 at 3:45 PM',
      relatedMemories: []
    },
    {
      id: 4,
      title: 'Client feedback call about new dashboard features',
      summary: 'Client praised new data visualization features but requested more customization options for reports. Need to prioritize export functionality.',
      date: 'Jan 20, 2026',
      hasAudio: true,
      hasSummary: true,
      hasActivity: true,
      audioDuration: '18m56s',
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone',
      time: 'Jan 20',
      content: 'Client praised new data visualization features but requested more customization options.',
      relatedMemories: []
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
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone',
      time: 'Jan 19',
      content: 'Reviewed progress on Q1 goals. Most milestones on track except mobile app development.',
      relatedMemories: []
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
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone',
      time: 'Jan 18',
      content: 'January 18, 2026 at 11:20 AM',
      relatedMemories: []
    }
  ]);

  // Lift memos state to App level so it can be shared between HomeTab and MemoryTab
  const [memos, setMemos] = useState([
    // Today (March 3, 2026) - 5 memos
    { id: 1, title: 'Idea: simplify onboarding for ADHD users', content: 'First-time users with ADHD might feel overwhelmed by too many options. A guided, step-by-step onboarding could help them understand the app without cognitive overload. Maybe use progressive disclosure and visual cues.', timestamp: new Date('2026-03-03T14:30:00'), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 2, title: 'Need to rethink pricing for early adopters', content: 'Current pricing might be too high for early adopters who are taking a risk on a new product. Consider a special launch price or lifetime deal to build initial user base and get valuable feedback.', timestamp: new Date('2026-03-03T11:20:00'), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 3, title: 'Consider adding dark mode for better focus', content: 'Many users with ADHD prefer dark mode to reduce visual distractions and eye strain during extended use. This could be a key accessibility feature that sets us apart.', timestamp: new Date('2026-03-03T09:15:00'), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 4, title: 'Explore voice memo transcription feature', content: 'Speaking is often easier than writing for people with ADHD. Adding automatic transcription for voice memos could make capture much more frictionless. Worth researching available APIs.', timestamp: new Date('2026-03-03T16:45:00'), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 5, title: 'CES observations worth writing down', content: 'Attended several sessions on AI-powered productivity tools. Most focus on neurotypical users. Big opportunity to differentiate by designing specifically for neurodivergent needs from the ground up.', timestamp: new Date('2026-03-03T08:00:00'), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    
    // Yesterday (March 2, 2026) - 1 memo
    { id: 6, title: 'Note about long-term memory vs memo distinction', content: 'Memories should be things that happened - conversations, events, experiences. Memos are thoughts, ideas, and reflections. Keeping this distinction clear helps users understand where to capture what.', timestamp: new Date('2026-03-02T15:30:00'), category: 'Yesterday', relatedMemories: [], todoCreated: false, type: 'voice' },
    
    // Feb 28, 2026 - 3 memos
    { id: 7, title: 'User feedback on notification timing', content: 'Beta testers mentioned that random notifications can be disruptive. Should explore gentle, predictable reminder schedules that respect focus time and align with natural breaks.', timestamp: new Date('2026-02-28T10:00:00'), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 8, title: 'Partnership opportunity with wellness app', content: 'Had conversation with founders of meditation app popular with ADHD community. Potential integration opportunity - they handle mindfulness, we handle productivity and memory.', timestamp: new Date('2026-02-28T14:20:00'), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 9, title: 'Research findings on color psychology for neurodiverse users', content: 'Studies show that softer, muted colors reduce anxiety and help with focus for many neurodivergent individuals. Avoid high-contrast, saturated colors in main UI - reserve those for important actions only.', timestamp: new Date('2026-02-28T16:30:00'), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    
    // Jan 21 - 4 memos
    { id: 10, title: 'Meeting notes from investor pitch practice', content: 'Focus on the problem first - people with ADHD struggle with traditional productivity tools. Then show how our approach is different. Use personal stories to make it relatable. Keep slides minimal.', timestamp: new Date('2026-01-21T14:30:00'), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 11, title: 'Product roadmap ideas for Q2', content: 'Priorities: 1) Voice memos with transcription, 2) Smart reminders based on context, 3) Integration with calendar apps, 4) Collaborative features for teams. Get user input before finalizing.', timestamp: new Date('2026-01-21T10:15:00'), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 12, title: 'User feedback compilation from beta testing', content: 'Most common requests: better search, tags/categories, ability to link related items, export options. Most loved features: simple capture flow, gentle visual design, non-judgmental tone.', timestamp: new Date('2026-01-21T16:45:00'), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 13, title: 'Brainstorming session: gamification features', content: 'Gamification can be motivating but also anxiety-inducing. If we add it, make it opt-in and focus on personal progress rather than competition. Celebrate small wins. Avoid shame or pressure.', timestamp: new Date('2026-01-21T09:00:00'), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    
    // Jan 19 - 1 memo
    { id: 14, title: 'Notes on competitor analysis', content: 'Most productivity apps assume executive function works normally. They punish forgetting with overdue tasks and missed deadlines. Our advantage: designed for imperfect memory and variable attention.', timestamp: new Date('2026-01-19T15:20:00'), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    
    // Jan 18 - 2 memos
    { id: 15, title: 'Design system update considerations', content: 'Current design system is good but could use more spacing options for better visual hierarchy. Also need standardized loading states and empty states. Keep accessibility as top priority.', timestamp: new Date('2026-01-18T11:30:00'), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 16, title: 'Accessibility audit findings', content: 'Good: color contrast, keyboard navigation. Needs improvement: screen reader support for dynamic content, focus indicators on custom components, ARIA labels for icon buttons.', timestamp: new Date('2026-01-18T13:45:00'), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
  ]);

  const handleCreateMemo = (newMemo: any) => {
    setMemos([...memos, newMemo]);
  };

  const handleUpdateMemo = (memoId: number, updates: any) => {
    setMemos(prevMemos =>
      prevMemos.map(memo =>
        memo.id === memoId ? { ...memo, ...updates } : memo
      )
    );
  };

  const handleDeleteMemo = (memoId: number) => {
    setMemos(memos.filter(m => m.id !== memoId));
  };

  const handleAnalyzeActions = (memoId: number, todoTexts: string[]) => {
    // Mark the memo as analyzed
    handleUpdateMemo(memoId, { actionsAnalyzed: true });
    
    // Find the memo to get its info for linkedMemory
    const memo = memos.find(m => m.id === memoId);
    
    // Create todos from the AI-extracted actions
    const newTodos = todoTexts.map((text, index) => ({
      id: Math.max(...todos.map(t => t.id), 0) + index + 1,
      title: text,
      priority: 'Normal' as const,
      dueDate: 'Today',
      category: 'Today',
      notes: undefined,
      createdFromMemo: memoId,
      linkedMemory: memo ? {
        id: `memo-${memo.id}`,
        title: memo.title || memo.content.substring(0, 50),
        date: memo.timestamp ? new Date(memo.timestamp).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }) : 'Today',
      } : undefined,
    }));
    
    setTodos([...todos, ...newTodos]);
  };

  const handleCreateMemory = (newMemory: any) => {
    console.log('🎯 handleCreateMemory called in App.tsx');
    console.log('📥 Received memory:', newMemory);
    console.log('📚 Current memories count:', memories.length);
    
    const memoryToAdd = {
      ...newMemory,
      id: Math.max(...memories.map(m => m.id), 0) + 1,
    };
    
    console.log('💾 Memory with ID:', memoryToAdd);
    
    // Add to beginning of array so it appears first (most recent)
    setMemories([memoryToAdd, ...memories]);
    
    console.log('✅ Memory added to state');
  };

  const tabs: Tab[] = [
    { id: 'home', label: 'Home', icon: Home, component: HomeTab },
    { id: 'memory', label: 'Memory', icon: BookOpen, component: MemoryTab },
    { id: 'ask-ai', label: 'Ask AI', icon: Sparkles, component: AskAITab },
    { id: 'preferences', label: 'Preferences', icon: Settings, component: PreferencesTab }
  ];

  const ActiveComponent = tabs.find(tab => tab.id === activeTab)?.component || HomeTab;

  // Show login modal if not logged in
  if (!isLoggedIn) {
    return (
      <LoginModal 
        isOpen={true} 
        onClose={() => {}} // Prevent closing - user must log in
        promptMessage="Sign in to keep your memories safe and access them across devices."
      />
    );
  }

  return (
    <DevModeProvider>
      <VoiceprintProvider>
        <AudioStatusProvider>
          <MicrophonePermissionProvider>
            <div className="h-screen w-full max-w-md mx-auto bg-background flex flex-col overflow-hidden shadow-xl relative">
              {/* Main content area */}
              <div className="flex-1 overflow-hidden">
                {activeTab === 'home' ? (
                  <HomeTab 
                    onSwitchToMemoryTab={() => setActiveTab('memory')} 
                    todos={todos}
                    setTodos={setTodos}
                    onMarkDone={handleMarkDone}
                    onNotNow={handleNotNow}
                    onDeleteTodo={handleDeleteTodo}
                    onUpdateTodo={handleUpdateTodo}
                    memories={memories}
                    setMemories={setMemories}
                    memos={memos}
                    setMemos={setMemos}
                    recordingState={{
                      isMinimized: isRecordingMinimized,
                      isRecording: isRecording,
                      recordingTime: recordingTime,
                      setIsRecording: setIsRecording,
                      setRecordingTime: setRecordingTime,
                      onMinimize: handleMinimizeRecording,
                      onExpand: handleExpandRecording,
                      onStop: handleStopRecording
                    }}
                  />
                ) : activeTab === 'memory' ? (
                  <MemoryTab 
                    onAddTodo={handleAddTodo}
                    todos={todos}
                    onMarkDone={handleMarkDone}
                    onNotNow={handleNotNow}
                    onDeleteTodo={handleDeleteTodo}
                    onUpdateTodo={handleUpdateTodo}
                    memories={memories}
                    setMemories={setMemories}
                    memos={memos}
                    setMemos={setMemos}
                    onCreateMemo={handleCreateMemo}
                    onUpdateMemo={handleUpdateMemo}
                    onDeleteMemo={handleDeleteMemo}
                    onAnalyzeActions={handleAnalyzeActions}
                    onCreateMemory={handleCreateMemory}
                  />
                ) : activeTab === 'ask-ai' ? (
                  <AskAITab />
                ) : (
                  <PreferencesTab />
                )}
              </div>

              {/* Bottom tab bar */}
              <div className="bg-card border-t border-border safe-area-bottom">
                <div className="flex items-center justify-around px-2 py-2">
                  {tabs.map((tab) => {
                    const Icon = tab.icon;
                    const isActive = activeTab === tab.id;
                    return (
                      <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={`flex flex-col items-center gap-1 px-5 py-2.5 rounded-xl transition-all ${
                          isActive
                            ? 'text-primary'
                            : 'text-muted-foreground hover:text-foreground'
                        }`}
                      >
                        <Icon className={`w-6 h-6 ${isActive ? 'stroke-[2.5]' : 'stroke-2'}`} />
                        <span className="text-xs">{tab.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Minimized Recording Bar - shows across all tabs */}
              {isRecordingMinimized && (
                <MinimizedRecordingBar
                  isRecording={isRecording}
                  recordingTime={recordingTime}
                  onTogglePause={handleToggleRecordingPause}
                  onExpand={handleExpandRecording}
                />
              )}
            </div>
          </MicrophonePermissionProvider>
        </AudioStatusProvider>
      </VoiceprintProvider>
    </DevModeProvider>
  );
}

export default function App() {
  return (
    <UserProvider>
      <AppContent />
    </UserProvider>
  );
}