import { ChevronLeft, Share2, Mic, Smartphone, FileText, Sparkles, CheckSquare, Edit3, MessageSquare, Send, MoreVertical, Trash2, Check, Play, Pause, Plus, ChevronRight, ChevronDown, RefreshCw, Users, Phone, Clipboard, BookOpen, Brain, Lightbulb, Compass, X, ArrowUp, Star } from 'lucide-react';
import { useState, useEffect, useRef } from 'react';
import { AudioWaveform } from './AudioWaveform';
import { TodoDetailModal } from './TodoDetailModal';
import { MemoDetailModal } from './MemoDetailModal';
import { ExpertInsightCard, ExpertType } from './ExpertInsightCard';
import { NewTodoFromMemoModal } from './NewTodoFromMemoModal';
import { MarkSpeakerModal } from './MarkSpeakerModal';
import { ShareOptionsModal } from './ShareOptionsModal';
import { ShareContentSelectionModal } from './ShareContentSelectionModal';
import { MemoryOptionsModal } from './MemoryOptionsModal';
import { ManageProjectsModal } from './ManageProjectsModal';
import { AISummaryStylePage } from './AISummaryStylePage';
import { AIChatModal } from './AIChatModal';
import { PersonDetail } from './PersonDetail';
import { getInitialTranscript } from './MemoryActivityFlow_transcript_helper';
import { getTemplateDisplayName } from '../helper_template';

interface Memory {
  id: number;
  title: string;
  summary: string;
  date: string;
  hasAudio: true;
  hasSummary: true;
  hasActivity: true;
  audioDuration: string;
  audioSource: 'MemoPin' | 'MobilePhone';
}

interface ActivityItem {
  id: number;
  type: 'key-takeaways' | 'ai-insight' | 'todo' | 'note' | 'ask-ai' | 'resummary' | 'expert-insight';
  timestamp: string;
  content: any;
}

interface MemoryActivityFlowProps {
  memory: Memory;
  onClose: () => void;
  onAddTodo?: (todo: any) => void;
  isNewlyGenerated?: boolean;
  onCreateProject?: (project: { id: string; name: string; memoryId: number | null }) => void;
  allProjects?: { id: string; name: string }[];
  linkedProjectIds?: string[];
  onUpdateLinkedProjects?: (memoryId: number, projectIds: string[]) => void;
  memos?: any[];
  onCreateMemo?: (memo: any) => void;
  onUpdateMemo?: (memoId: number, updates: any) => void;
  onAnalyzeActions?: (memoId: number, todoTexts: string[]) => void;
  initialTab?: 'Overview' | 'Transcript' | 'Actions';
  highlightTimestamp?: string;
}

export function MemoryActivityFlow({ memory, onClose, onAddTodo, isNewlyGenerated = false, onCreateProject, allProjects = [], linkedProjectIds = [], onUpdateLinkedProjects, memos = [], onCreateMemo, onUpdateMemo, onAnalyzeActions, initialTab, highlightTimestamp }: MemoryActivityFlowProps) {
  // Define expert insights based on memory ID
  const getExpertInsights = () => {
    if (memory.id === 1) {
      // Team standup discussion on API migration
      return [
        {
          id: 201,
          type: 'expert-insight' as const,
          timestamp: '2 min later',
          content: {
            expertType: 'business' as ExpertType,
            mainContent: 'Product discussions repeatedly circle around interaction behavior and hardware constraints, suggesting product definition is still evolving while engineering implementation is already underway.',
            riskSection: {
              title: 'This creates risk of:',
              items: [
                'Rework in firmware and hardware decisions',
                'Misalignment between product and delivery',
                'Slower iteration due to late clarification'
              ]
            },
            suggestion: 'Freeze core interaction logic and hardware constraints before next engineering sprint.'
          }
        },
        {
          id: 202,
          type: 'expert-insight' as const,
          timestamp: '10 min later',
          content: {
            expertType: 'execution' as ExpertType,
            mainContent: 'Several implementation blockers surfaced: recording start/stop logic still conflicts between press timing and user expectation, timestamp behavior during recording not fully aligned across teams, and sleep mode and LED states confuse usage.',
            riskSection: {
              title: 'Execution risk:',
              items: [
                'Teams are clarifying requirements while already implementing features'
              ]
            },
            suggestion: 'Create a short execution checklist for: interaction logic, device states, and transmission flow before next build.'
          }
        }
      ];
    } else if (memory.id === 7) {
      // Product launch planning with marketing team
      return [
        {
          id: 201,
          type: 'expert-insight' as const,
          timestamp: '3 min later',
          content: {
            expertType: 'business' as ExpertType,
            mainContent: 'Three-phase rollout approach is solid, but timing dependencies between beta feedback, influencer content creation, and public launch create execution risk if any phase delays.',
            riskSection: {
              title: 'Risk factors:',
              items: [
                'Beta user feedback cycle might extend beyond planned timeline',
                'Influencer content requires 2-3 week lead time',
                'Public launch date already communicated to stakeholders'
              ]
            },
            suggestion: 'Build 1-week buffer between each phase and pre-produce core marketing assets now.'
          }
        },
        {
          id: 202,
          type: 'expert-insight' as const,
          timestamp: '12 min later',
          content: {
            expertType: 'creative' as ExpertType,
            mainContent: 'The positioning around "neurodivergent-friendly productivity" is unique but marketing materials still use generic productivity language.',
            riskSection: {
              title: 'Opportunity:',
              items: [
                'Lead with specific ADHD-friendly features in all materials',
                'Show real user stories about focus and organization wins',
                'Differentiate visually with calm, clear design language',
                'Build community around user experiences, not just features'
              ]
            },
            suggestion: 'Revise all launch assets to lead with user stories and ADHD-specific benefits.'
          }
        }
      ];
    } else if (memory.id === 8) {
      // Investor meeting - Series A funding discussion
      return [
        {
          id: 201,
          type: 'expert-insight' as const,
          timestamp: '5 min later',
          content: {
            expertType: 'business' as ExpertType,
            mainContent: 'Strong investor interest in retention metrics and unit economics suggests they\'re evaluating product-market fit and scalability. Their detailed questions indicate serious consideration.',
            riskSection: {
              title: 'Next steps critical:',
              items: [
                'Need cohort analysis showing retention by user segment',
                'LTV/CAC breakdown with realistic scaling assumptions',
                'Clear path to profitability with current burn rate',
                'Competitive positioning on retention vs market alternatives'
              ]
            },
            suggestion: 'Prepare detailed financial model and retention cohort deck for follow-up meeting this week.'
          }
        },
        {
          id: 202,
          type: 'expert-insight' as const,
          timestamp: '18 min later',
          content: {
            expertType: 'execution' as ExpertType,
            mainContent: 'You presented growth story well, but investor asked several questions you deferred. Quick follow-up with precise data will maintain momentum.',
            riskSection: {
              title: 'Action items:',
              items: [
                'Send CAC breakdown by channel within 48 hours',
                'Clarify churn rate for paying vs free users',
                'Share product roadmap timeline for next 12 months',
                'Provide reference calls from 2-3 existing customers'
              ]
            },
            suggestion: 'Block tomorrow morning to compile all requested data and send comprehensive follow-up.'
          }
        }
      ];
    } else if (memory.id === 4) {
      // Client feedback call about new dashboard features
      return [
        {
          id: 201,
          type: 'expert-insight' as const,
          timestamp: '2 min later',
          content: {
            expertType: 'creative' as ExpertType,
            mainContent: 'The conversation highlights recurring friction around users not knowing device state from light indicators alone.\n\nThis opens opportunity to rethink interaction:',
            riskSection: {
              title: 'Opportunity:',
              items: [
                'Add vibration feedback for key actions',
                'Simplify state transitions for users',
                'Reduce reliance on LED signals',
                'A clearer physical feedback system could differentiate the product from competitors'
              ]
            },
            suggestion: 'Prototype vibration + light hybrid feedback.'
          }
        },
        {
          id: 202,
          type: 'expert-insight' as const,
          timestamp: '10 min later',
          content: {
            expertType: 'wellness' as ExpertType,
            mainContent: 'Multiple moments show teams debugging behavior live while discussing requirements, suggesting:',
            riskSection: {
              title: 'Pattern:',
              items: [
                'Ongoing implementation pressure',
                'Need for quick fixes over structured planning',
                'Potential overload if iteration pace continues',
                'Teams repeatedly fix issues mid-discussion'
              ]
            },
            suggestion: 'Schedule weekly alignment meetings to reduce ad-hoc decision pressure.'
          }
        }
      ];
    }
    return [];
  };

  const expertInsights = getExpertInsights();

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
          'Q1 goals reviewed - most milestones on track',
          'Mobile app development behind schedule',
          'Need to allocate more resources to frontend team'
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

  // Generate initial activities based on memory ID
  const getInitialActivities = (): ActivityItem[] => {
    // If this is a newly generated resummary, include key takeaways and new resummary card
    if (isNewlyGenerated) {
      return [
        {
          id: 1,
          type: 'key-takeaways',
          timestamp: 'AI generated',
          content: {
            takeaways: keyTakeaways
          }
        },
        {
          id: 2,
          type: 'resummary',
          timestamp: 'Just now',
          content: {
            styleId: 'investor-review',
            perspective: 'Investor Perspective',
            title: 'Strategic Investment Analysis',
            sections: [
              {
                heading: 'Executive Summary',
                content: 'From an investment standpoint, this API migration discussion reveals both opportunities and red flags that warrant careful attention. The technical debt being addressed represents necessary infrastructure modernization, but execution risks appear higher than currently acknowledged.'
              },
              {
                heading: 'Opportunity Assessment',
                content: 'Moving to microservices architecture positions the company for future scalability and faster feature deployment. This technical foundation is essential for maintaining competitive velocity. The phased approach demonstrates risk awareness, though timeline estimates may be optimistic given team bandwidth constraints.'
              },
              {
                heading: 'Risk Analysis',
                content: 'Key concerns: 1) Infrastructure team appears overloaded with parallel initiatives, 2) No mention of rollback strategy if migration encounters critical issues, 3) Authentication service as first target is high-risk given user impact potential, 4) Unclear ownership of cross-service dependencies and data consistency challenges.'
              },
              {
                heading: 'Investment Implications',
                content: 'This migration will consume significant engineering resources over next 2-3 quarters. Expect slower feature velocity short-term. Need clear metrics for measuring migration success beyond "technical completion" - focus on system reliability, performance improvements, and developer productivity gains. Request detailed project timeline with milestones and success criteria before next board meeting.'
              }
            ]
          }
        }
      ];
    }
    
    if (memory.id === 1) {
      // Team standup discussion on API migration
      return [
        {
          id: 1,
          type: 'key-takeaways',
          timestamp: 'AI generated',
          content: {
            takeaways: keyTakeaways
          }
        },
        ...expertInsights,
        {
          id: 3,
          type: 'todo',
          timestamp: '10 min ago',
          content: {
            id: 101,
            title: 'Review migration milestones with infrastructure team',
            priority: 'High priority',
            dueDate: 'Tomorrow',
            context: 'API Migration Planning Meeting',
            time: '09:00',
            notes: ['Need to confirm their availability for next sprint', 'Focus on authentication service timeline'],
            linkedMemory: {
              id: '1',
              title: 'Team standup discussion on API migration',
              date: 'Today, 10:30 AM',
              duration: '12m34s',
              hasSummary: true
            }
          }
        },
        {
          id: 4,
          type: 'todo',
          timestamp: '15 min ago',
          content: {
            id: 102,
            title: 'Update API documentation for v2 endpoints',
            priority: 'High priority',
            dueDate: 'This week',
            context: 'API Migration Planning Meeting',
            time: '14:00',
            notes: ['Include authentication changes', 'Add migration guide for existing clients'],
            linkedMemory: {
              id: '1',
              title: 'Team standup discussion on API migration',
              date: 'Today, 10:30 AM',
              duration: '12m34s',
              hasSummary: true
            }
          }
        },
        {
          id: 5,
          type: 'note',
          timestamp: '20 min ago',
          content: {
            id: 201,
            text: 'Infra team seems overloaded. Maybe we should loop in Sarah from the platform team to help?',
            title: 'Team resource concern',
            type: 'highlight',
            sourceMemory: {
              id: 1,
              title: 'Team standup discussion on API migration',
              timestamp: '02:14'
            }
          }
        }
      ];
    } else if (memory.id === 7) {
      // Product launch planning with marketing team
      return [
        {
          id: 1,
          type: 'key-takeaways',
          timestamp: 'AI generated',
          content: {
            takeaways: keyTakeaways
          }
        },
        ...expertInsights,
        {
          id: 3,
          type: 'resummary',
          timestamp: '20 min ago',
          content: {
            styleId: 'project-sync',
            perspective: 'Marketing Perspective',
            title: 'Go-to-Market Strategy Analysis',
            sections: [
              {
                heading: 'Launch Readiness Assessment',
                content: 'The three-phase rollout strategy demonstrates solid understanding of product-market fit validation. Starting with beta users provides crucial feedback loop before broader market exposure. However, the compressed timeline between phases creates execution risk if beta insights require material product adjustments.'
              },
              {
                heading: 'Positioning Opportunity',
                content: 'The team has identified a unique positioning angle around neurodivergent-friendly productivity tools, yet current marketing materials default to generic productivity messaging. This disconnect represents both a risk (diluted differentiation) and an opportunity (clear repositioning path). The ADHD user community is underserved and highly engaged - authentic messaging here could drive strong organic growth.'
              },
              {
                heading: 'Execution Recommendations',
                content: 'Immediate priorities: 1) Revise all launch assets to lead with user stories and ADHD-specific benefits, 2) Build 1-week buffer between each rollout phase, 3) Pre-produce core marketing content now to reduce last-minute pressure, 4) Establish clear success metrics for beta phase to inform go/no-go decision for influencer partnerships.'
              }
            ]
          }
        },
        {
          id: 4,
          type: 'todo',
          timestamp: '25 min ago',
          content: {
            id: 103,
            title: 'Revise marketing deck with ADHD-focused messaging',
            priority: 'High priority',
            dueDate: 'Tomorrow',
            context: 'Product Launch Planning',
            time: '14:00',
            notes: ['Lead with user stories', 'Remove generic productivity language', 'Get feedback from beta users'],
            linkedMemory: {
              id: '7',
              title: 'Product launch planning with marketing team',
              date: 'Today, 9:15 AM',
              duration: '22m18s',
              hasSummary: true
            }
          }
        },
        {
          id: 5,
          type: 'todo',
          timestamp: '30 min ago',
          content: {
            id: 104,
            title: 'Prepare beta onboarding materials',
            priority: 'Normal',
            dueDate: 'Next week',
            context: 'Product Launch Planning',
            time: '10:00',
            notes: ['Include welcome email template', 'Create setup guide for new users', 'Design feedback survey'],
            linkedMemory: {
              id: '7',
              title: 'Product launch planning with marketing team',
              date: 'Today, 9:15 AM',
              duration: '22m18s',
              hasSummary: true
            }
          }
        }
      ];
    } else if (memory.id === 8) {
      // Investor meeting - Series A funding discussion
      return [
        {
          id: 1,
          type: 'key-takeaways',
          timestamp: 'AI generated',
          content: {
            takeaways: keyTakeaways
          }
        },
        ...expertInsights,
        {
          id: 3,
          type: 'todo',
          timestamp: '1 hour ago',
          content: {
            id: 105,
            title: 'Update pitch deck with Q1 metrics',
            priority: 'High priority',
            dueDate: 'Tomorrow',
            context: 'Series A Fundraising',
            time: '10:00',
            notes: ['Include retention numbers by cohort', 'Add unit economics breakdown', 'Update financial projections'],
            linkedMemory: {
              id: '8',
              title: 'Investor meeting - Series A funding discussion',
              date: 'Yesterday, 4:30 PM',
              duration: '45m52s',
              hasSummary: true
            }
          }
        },
        {
          id: 4,
          type: 'todo',
          timestamp: '1 hour ago',
          content: {
            id: 106,
            title: 'Schedule follow-up with lead investor',
            priority: 'High priority',
            dueDate: 'This week',
            context: 'Series A Fundraising',
            time: '15:00',
            notes: ['Confirm availability for next week', 'Prepare detailed financial model', 'Send CAC breakdown by channel'],
            linkedMemory: {
              id: '8',
              title: 'Investor meeting - Series A funding discussion',
              date: 'Yesterday, 4:30 PM',
              duration: '45m52s',
              hasSummary: true
            }
          }
        }
      ];
    } else if (memory.id === 4) {
      // Client feedback call about new dashboard features
      return [
        {
          id: 1,
          type: 'key-takeaways',
          timestamp: 'AI generated',
          content: {
            takeaways: keyTakeaways
          }
        },
        ...expertInsights,
        {
          id: 3,
          type: 'todo',
          timestamp: '2 hours ago',
          content: {
            id: 107,
            title: 'Add export functionality to dashboard reports',
            priority: 'High priority',
            dueDate: 'Next week',
            context: 'Client Feature Request',
            time: '11:00',
            notes: ['Support CSV and PDF formats', 'Include all data visualization options', 'Test with large datasets'],
            linkedMemory: {
              id: '4',
              title: 'Client feedback call about new dashboard features',
              date: 'Jan 20, 2026',
              duration: '18m56s',
              hasSummary: true
            }
          }
        },
        {
          id: 4,
          type: 'todo',
          timestamp: '2 hours ago',
          content: {
            id: 108,
            title: 'Design customization options for report templates',
            priority: 'Normal',
            dueDate: 'Next week',
            context: 'Client Feature Request',
            time: '14:30',
            notes: ['Create mockups for custom report layouts', 'Research competitor features', 'Schedule review with design team'],
            linkedMemory: {
              id: '4',
              title: 'Client feedback call about new dashboard features',
              date: 'Jan 20, 2026',
              duration: '18m56s',
              hasSummary: true
            }
          }
        }
      ];
    } else {
      // Default activities for other memories
      return [
    {
      id: 1,
      type: 'key-takeaways',
      timestamp: 'AI generated',
      content: {
        takeaways: keyTakeaways
      }
    },
    ...expertInsights,
    {
      id: 3,
      type: 'note',
      timestamp: '15 min ago',
      content: {
        id: 201,
        text: 'Important discussion points captured. Follow-up needed.',
        title: 'Meeting notes',
        type: 'highlight',
        sourceMemory: {
          id: memory.id,
          title: memory.title,
          timestamp: '00:45'
        }
      }
    }
      ];
    }
  };

  // Load activities from localStorage or use initial activities
  const ACTIVITIES_VERSION = 'v4'; // Increment this when todo data structure changes
  const [activities, setActivities] = useState<ActivityItem[]>(() => {
    // If this is a newly generated resummary, ignore localStorage and use fresh data
    if (isNewlyGenerated) {
      return getInitialActivities();
    }
    
    const versionKey = `memory-activities-version-${memory.id}`;
    const storedVersion = localStorage.getItem(versionKey);
    
    // If version doesn't match, clear old data and use fresh initial activities
    if (storedVersion !== ACTIVITIES_VERSION) {
      localStorage.removeItem(`memory-activities-${memory.id}`);
      localStorage.setItem(versionKey, ACTIVITIES_VERSION);
      return getInitialActivities();
    }
    
    const stored = localStorage.getItem(`memory-activities-${memory.id}`);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch (e) {
        return getInitialActivities();
      }
    }
    return getInitialActivities();
  });

  const [quickInputText, setQuickInputText] = useState('');
  const [quickInputMode, setQuickInputMode] = useState<'note' | 'todo' | 'ask' | null>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const [expandedInsights, setExpandedInsights] = useState<Set<number>>(new Set());
  const quickInputRef = useRef<HTMLTextAreaElement>(null);
  
  // Auto-resize textarea when quickInputText changes
  useEffect(() => {
    if (quickInputRef.current) {
      quickInputRef.current.style.height = 'auto';
      quickInputRef.current.style.height = Math.min(quickInputRef.current.scrollHeight, 120) + 'px';
    }
  }, [quickInputText]);
  
  // Todo and Memo detail modals
  const [selectedTodo, setSelectedTodo] = useState<any>(null);
  const [selectedMemo, setSelectedMemo] = useState<any>(null);
  const [selectedTodoActivityId, setSelectedTodoActivityId] = useState<number | null>(null);
  
  // Delete confirmation state
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [todoToDelete, setTodoToDelete] = useState<{ activityId: number; todoId: number } | null>(null);
  
  // New Todo from Expert Insight modal
  const [showNewTodoModal, setShowNewTodoModal] = useState(false);
  const [newTodoSuggestion, setNewTodoSuggestion] = useState('');
  const [newTodoInsightContent, setNewTodoInsightContent] = useState('');
  // Load expert insights with todos from localStorage
  const [expertInsightsWithTodos, setExpertInsightsWithTodos] = useState<Set<number>>(() => {
    const stored = localStorage.getItem(`memory-expert-todos-${memory.id}`);
    if (stored) {
      try {
        return new Set(JSON.parse(stored));
      } catch (e) {
        return new Set();
      }
    }
    return new Set();
  });
  const [currentExpertInsightId, setCurrentExpertInsightId] = useState<number | null>(null);
  
  // Audio player state
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  
  // Source card state
  const [activeTab, setActiveTab] = useState<'Overview' | 'Transcript' | 'Actions'>(initialTab || 'Overview');
  const [showFullSummary, setShowFullSummary] = useState(false);
  const [showFullTranscript, setShowFullTranscript] = useState(false);
  
  // Mark speaker modal state
  const [showMarkSpeakerModal, setShowMarkSpeakerModal] = useState(false);
  
  // Edit speaker name modal state
  const [showEditSpeakerModal, setShowEditSpeakerModal] = useState(false);
  const [editingSpeakerIndex, setEditingSpeakerIndex] = useState<number | null>(null);
  const [editingSpeakerName, setEditingSpeakerName] = useState('');
  const [newSpeakerName, setNewSpeakerName] = useState('');
  const [applyToAllSameSpeaker, setApplyToAllSameSpeaker] = useState(false);
  
  // Share options modal state
  const [showShareOptionsModal, setShowShareOptionsModal] = useState(false);
  const [showShareContentModal, setShowShareContentModal] = useState(false);
  const [selectedShareContent, setSelectedShareContent] = useState<{
    summaryId: number | string;
    includeExpertInsights: {
      business: boolean;
      execution: boolean;
      creative: boolean;
      wellness: boolean;
    };
    includeTodos: boolean;
    includeMemos: boolean;
    includeTranscript: boolean;
    includeAudio: boolean;
  } | null>(null);
  
  // Memory options modal state
  const [showMemoryOptionsModal, setShowMemoryOptionsModal] = useState(false);
  
  // AI Summary Style Page state
  const [showAISummaryStylePage, setShowAISummaryStylePage] = useState(false);
  const [tempSelectedTemplate, setTempSelectedTemplate] = useState<string>('autopilot');
  
  // Resummary confirmation modal state
  const [showResummaryModal, setShowResummaryModal] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('autopilot');
  
  // Choose summary style modal state
  const [showTemplateModal, setShowTemplateModal] = useState(false);
  
  // Generating activities state - tracks which resummary activities are being generated
  const [generatingActivities, setGeneratingActivities] = useState<Set<string>>(new Set());
  
  // AI Chat modal state
  const [showAIChatModal, setShowAIChatModal] = useState(false);
  
  // Person Detail state
  const [showPersonDetail, setShowPersonDetail] = useState(false);
  const [showManageProjectsModal, setShowManageProjectsModal] = useState(false);
  const [selectedPersonName, setSelectedPersonName] = useState<string>('');
  
  // Convert props to projects format for ManageProjectsModal
  const projects = allProjects.map(p => ({
    ...p,
    isLinked: linkedProjectIds.includes(p.id)
  }));
  
  // Action Create Todo state
  const [showActionTodoModal, setShowActionTodoModal] = useState(false);
  const [selectedAction, setSelectedAction] = useState<{ id: number; text: string } | null>(null);
  const [actionsWithTodos, setActionsWithTodos] = useState<Set<number>>(() => {
    const stored = localStorage.getItem(`memory-action-todos-${memory.id}`);
    if (stored) {
      try {
        return new Set(JSON.parse(stored));
      } catch (e) {
        return new Set();
      }
    }
    return new Set();
  });
  
  // Save activities to localStorage whenever they change
  useEffect(() => {
    localStorage.setItem(`memory-activities-${memory.id}`, JSON.stringify(activities));
  }, [activities, memory.id]);
  
  // Save expert insights with todos to localStorage whenever they change
  useEffect(() => {
    localStorage.setItem(`memory-expert-todos-${memory.id}`, JSON.stringify(Array.from(expertInsightsWithTodos)));
  }, [expertInsightsWithTodos, memory.id]);
  
  // Save actions with todos to localStorage whenever they change
  useEffect(() => {
    localStorage.setItem(`memory-action-todos-${memory.id}`, JSON.stringify(Array.from(actionsWithTodos)));
  }, [actionsWithTodos, memory.id]);
  
  // Use memory.summary as full summary text
  const fullSummaryText = memory.summary || `This recording captures a team standup discussion about the upcoming API migration project.

The team discussed the timeline for migrating from the legacy API to the new microservices architecture. There was agreement on starting with a phased approach, beginning with non-critical endpoints before moving to core services.

Sarah raised important concerns about potential authentication issues that could arise during the migration. The team acknowledged these risks and agreed to dedicate extra time to testing the authentication service migration.

Key decisions were made about resource allocation and the team discussed the need for additional infrastructure support during the rollout phase.`;

  const [transcriptData, setTranscriptData] = useState(getInitialTranscript(memory.id));

  // Calculate speakers dynamically from transcript
  const speakers = Array.from(new Set(transcriptData.map(item => item.speaker)));

  // Dynamic suggested actions based on memory ID
  const getSuggestedActions = () => {
    switch (memory.id) {
      case 1: // Team standup discussion on API migration
        return [
          { id: 1, text: 'Review migration milestones with infrastructure team' },
          { id: 2, text: 'Schedule authentication service testing session' },
          { id: 3, text: 'Document rollout risks and mitigation strategies' },
        ];
      case 2: // Coffee chat with Alex about product strategy
        return [
          { id: 1, text: 'Research neurodivergent user needs and pain points' },
          { id: 2, text: 'Schedule follow-up meeting with Alex to explore positioning' },
          { id: 3, text: 'Draft positioning statement focused on neurodivergent users' },
        ];
      case 7: // Product launch planning with marketing team
        return [
          { id: 1, text: 'Create detailed timeline for three-phase rollout' },
          { id: 2, text: 'Identify and reach out to potential influencer partners' },
          { id: 3, text: 'Prepare beta user onboarding materials' },
        ];
      case 8: // Investor meeting - Series A funding
        return [
          { id: 1, text: 'Prepare detailed unit economics breakdown for follow-up' },
          { id: 2, text: 'Send thank you email with additional retention data' },
          { id: 3, text: 'Schedule next meeting to discuss terms' },
        ];
      case 4: // Client feedback call
        return [
          { id: 1, text: 'Prioritize Excel export functionality for next sprint' },
          { id: 2, text: 'Design mockups for report customization options' },
          { id: 3, text: 'Schedule follow-up demo after features are implemented' },
        ];
      case 5: // Weekly review and planning
        return [
          { id: 1, text: 'Allocate frontend developer to mobile team' },
          { id: 2, text: 'Research Android contractor availability' },
          { id: 3, text: 'Update Q1 timeline with revised mobile delivery date' },
        ];
      default:
        return [
          { id: 1, text: 'Review key discussion points' },
          { id: 2, text: 'Follow up with mentioned action items' },
          { id: 3, text: 'Schedule next check-in' },
        ];
    }
  };
  
  const suggestedActions = getSuggestedActions();

  // Parse duration to seconds - must be declared before getCurrentSegmentIndex
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

  const totalSeconds = parseDuration(memory.audioDuration || '12m34s');

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

  const handleSeek = (time: number) => {
    setCurrentTime(time);
  };

  const circleRadius = 24;
  const circumference = 2 * Math.PI * circleRadius;
  const strokeDashoffset = circumference - (progress / 100) * circumference;

  const getSourceIcon = (source: 'MemoPin' | 'MobilePhone') => {
    if (source === 'MemoPin') {
      return <Mic className="w-4 h-4" />;
    }
    return <Smartphone className="w-4 h-4" />;
  };
  
  const formatMemoTimestamp = (timestamp: Date) => {
    const now = new Date();
    const diff = now.getTime() - new Date(timestamp).getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes} min ago`;
    if (hours < 24) return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    if (days < 7) return `${days} day${days > 1 ? 's' : ''} ago`;
    return new Date(timestamp).toLocaleDateString();
  };

  const handleQuickAdd = () => {
    if (!quickInputText.trim() || !quickInputMode) return;

    const newActivity: ActivityItem = {
      id: activities.length + 1,
      type: quickInputMode === 'note' ? 'note' : quickInputMode === 'todo' ? 'todo' : 'ask-ai',
      timestamp: 'Just now',
      content: quickInputMode === 'note' 
        ? { id: Date.now(), text: quickInputText, title: quickInputText.substring(0, 50) + (quickInputText.length > 50 ? '...' : ''), type: 'manual' }
        : quickInputMode === 'todo'
        ? { 
            title: quickInputText, 
            priority: 'Medium', 
            dueDate: 'No deadline',
            linkedMemory: {
              id: String(memory.id),
              title: memory.title,
              date: memory.date,
              duration: memory.audioDuration,
              hasSummary: memory.hasSummary
            }
          }
        : { question: quickInputText, answer: 'AI is thinking...' }
    };

    setActivities([...activities, newActivity]);
    
    // If it's a note (memo), also save it to the global memos state
    if (quickInputMode === 'note' && onCreateMemo) {
      const newMemo = {
        id: Date.now(),
        title: quickInputText.substring(0, 50) + (quickInputText.length > 50 ? '...' : ''),
        content: quickInputText,
        timestamp: new Date(),
        category: 'Today',
        relatedMemories: [memory.id],
        type: 'manual',
        linkedMemory: {
          id: memory.id.toString(),
          title: memory.title || 'Audio only',
          date: memory.date,
          duration: memory.audioDuration,
          hasSummary: memory.hasSummary
        },
        todoCreated: false
      };
      onCreateMemo(newMemo);
    }
    
    setQuickInputText('');
    setQuickInputMode(null);
  };

  const handleStartRecording = () => {
    setIsRecording(true);
  };

  const handleCancelRecording = () => {
    setIsRecording(false);
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
    }, 2000);
  };

  const toggleInsightExpansion = (id: number) => {
    const newExpanded = new Set(expandedInsights);
    if (newExpanded.has(id)) {
      newExpanded.delete(id);
    } else {
      newExpanded.add(id);
    }
    setExpandedInsights(newExpanded);
  };

  const handleDeleteActivity = (id: number | string) => {
    setActivities(prevActivities => prevActivities.filter(a => a.id !== id));
  };

  const handleGenerateResummary = () => {
    // Load the last used or default summary style
    const lastUsedStyle = localStorage.getItem('lastUsedSummaryStyle') || localStorage.getItem('defaultSummaryStyle') || 'autopilot';
    setSelectedTemplate(lastUsedStyle);
    setTempSelectedTemplate(lastUsedStyle);
    // Show confirmation modal
    setShowResummaryModal(true);
  };

  const handleGenerateResummaryWithStyle = (styleId: string) => {
    // Create a new resummary activity with selected style
    const newResummary: ActivityItem = {
      id: activities.length + 1,
      type: 'resummary',
      timestamp: 'Just now',
      content: {
        styleId: styleId, // Store the styleId for later reference
        perspective: 'Investor Perspective',
        title: 'Strategic Investment Analysis',
        sections: [
          {
            heading: 'Executive Summary',
            content: 'From an investment standpoint, this API migration discussion reveals both opportunities and red flags that warrant careful attention. The technical debt being addressed represents necessary infrastructure modernization, but execution risks appear higher than currently acknowledged.'
          },
          {
            heading: 'Opportunity Assessment',
            content: 'The migration to microservices architecture positions the platform for improved scalability and faster feature development velocity. This could translate to better unit economics and competitive positioning long-term. However, infrastructure team capacity constraints mentioned multiple times raise questions about whether current headcount aligns with growth ambitions.'
          },
          {
            heading: 'Risk Factors',
            content: 'Authentication service dependencies create systemic risk - any downtime directly impacts revenue. The lack of detailed rollback strategies discussed is concerning from a business continuity perspective. Resource allocation appears tight, which could lead to either timeline slippage or quality compromises.'
          },
          {
            heading: 'Capital Efficiency',
            content: 'The team\'s collaborative approach and early risk surfacing suggest operational maturity. However, the infrastructure team being "overloaded" may indicate underinvestment in engineering resources relative to product ambitions. This could be masking technical debt accumulation.'
          },
          {
            heading: 'Recommended Due Diligence',
            content: 'Request detailed migration budget, timeline with confidence intervals, and infrastructure capacity planning. Understanding the full cost of this initiative - both direct expenses and opportunity cost of engineering time - is critical for accurate financial modeling.'
          },
          {
            heading: 'Bottom Line',
            content: 'This is necessary technical work, but execution risk appears higher than team currently acknowledges. Consider whether additional infrastructure investment could derisk timeline and improve long-term operational leverage.'
          }
        ]
      }
    };

    // Mark this activity as generating
    const newGenerating = new Set(generatingActivities);
    newGenerating.add(String(newResummary.id));
    setGeneratingActivities(newGenerating);

    // Find the index of the last ask-ai activity
    const lastAskIndex = activities.findIndex(a => a.type === 'ask-ai');
    
    if (lastAskIndex !== -1) {
      // Insert after the last ask-ai activity
      const newActivities = [...activities];
      newActivities.splice(lastAskIndex + 1, 0, newResummary);
      setActivities(newActivities);
    } else {
      // If no ask-ai activity, insert at the end
      setActivities([...activities, newResummary]);
    }
    
    // Close the AI Summary Style Page
    setShowAISummaryStylePage(false);
  };

  // Extract all resummary versions from activities
  const getSummaryVersions = () => {
    const resummaries = activities.filter(a => a.type === 'resummary');
    const versions = resummaries.map((resummary, index) => ({
      id: resummary.id,
      styleId: resummary.content.styleId || 'autopilot',
      timestamp: resummary.timestamp,
      isLatest: index === 0, // First resummary is the latest
      isOriginal: false
    }));
    
    // Add original summary at the beginning
    return [
      {
        id: 'original',
        styleId: 'original',
        timestamp: memory.date,
        isLatest: false,
        isOriginal: true
      },
      ...versions
    ];
  };

  // Get available expert insights from activities for sharing
  const getAvailableExpertInsightsForSharing = () => {
    const insightActivities = activities.filter(a => a.type === 'expert-insight');
    const availableExperts = new Set(insightActivities.map(a => a.content.expertType));
    
    return [
      { type: 'business' as const, available: availableExperts.has('business') },
      { type: 'execution' as const, available: availableExperts.has('execution') },
      { type: 'creative' as const, available: availableExperts.has('creative') },
      { type: 'wellness' as const, available: availableExperts.has('wellness') }
    ];
  };

  // Handle content selection continue
  const handleShareContentContinue = (
    selectedSummaryId: number | string,
    selectedContent: {
      includeExpertInsights: {
        business: boolean;
        execution: boolean;
        creative: boolean;
        wellness: boolean;
      };
      includeTodos: boolean;
      includeMemos: boolean;
      includeTranscript: boolean;
      includeAudio: boolean;
    }
  ) => {
    // Store selected content
    setSelectedShareContent({
      summaryId: selectedSummaryId,
      ...selectedContent
    });
    
    // Close first modal and open second modal
    setShowShareContentModal(false);
    setShowShareOptionsModal(true);
  };

  // useEffect to remove activities from generating state after 10 seconds
  useEffect(() => {
    if (generatingActivities.size === 0) return;

    const timers: NodeJS.Timeout[] = [];

    generatingActivities.forEach((activityId) => {
      const timer = setTimeout(() => {
        setGeneratingActivities(prev => {
          const newSet = new Set(prev);
          newSet.delete(activityId);
          return newSet;
        });
      }, 10000); // 10 seconds

      timers.push(timer);
    });

    return () => {
      timers.forEach(timer => clearTimeout(timer));
    };
  }, [generatingActivities]);

  const handleAudioPlay = () => {
    setIsPlaying(true);
  };

  const handleAudioPause = () => {
    setIsPlaying(false);
  };

  const handleAudioTimeUpdate = (currentTime: number) => {
    setCurrentTime(currentTime);
  };

  const handleAudioDuration = (duration: number) => {
    // No need to set duration here as we parse it from memory.audioDuration
  };

  return (
    <div className="flex flex-col h-full bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
        <button 
          onClick={onClose}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-7 h-7" strokeWidth={2} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 -translate-x-1/2">
          Memory
        </h1>
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

      {/* Activity Flow */}
      <div className="flex-1 overflow-y-auto px-5 pt-6 pb-32">
        <div className="space-y-4">
          {/* Source Card - 置顶 */}
          <div className="bg-gradient-to-br from-[#2d5a47] to-[#234537] rounded-2xl p-6 shadow-lg text-white">
            {/* Header */}
            <div className="mb-3">
              <h2 className="text-[20px] font-bold leading-tight">
                {memory.title}
              </h2>
            </div>
            
            {/* Metadata */}
            <div className="flex flex-wrap items-center gap-2 text-[13px] opacity-80 mb-5">
              <span>{memory.date}</span>
              <span>•</span>
              <span>{memory.audioDuration}</span>
              <span>•</span>
              <div className="flex items-center gap-1">
                {getSourceIcon(memory.audioSource)}
                <span>{memory.audioSource}</span>
              </div>
            </div>

            {/* Audio Player - Compact inline layout */}
            <div className="mb-5">
              {/* Time display */}
              <div className="flex justify-between mb-2 text-[14px]">
                <span className="font-medium">{formatTime(currentTime)}</span>
                <span className="opacity-75">{memory.audioDuration}</span>
              </div>

              {/* Waveform and Play button in one row */}
              <div className="flex items-center gap-3">
                {/* Waveform - takes most space */}
                <div className="flex-1 bg-white/10 rounded-lg overflow-hidden h-12">
                  <AudioWaveform 
                    duration={memory.audioDuration}
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
                    className="absolute inset-0 -rotate-90" 
                    width="56" 
                    height="56"
                  >
                    <circle cx="28" cy="28" r="24" stroke="rgba(255,255,255,0.2)" strokeWidth="2.5" fill="none" />
                    <circle
                      cx="28" cy="28" r="24"
                      stroke="white" strokeWidth="2.5" fill="none"
                      strokeDasharray={circumference}
                      strokeDashoffset={strokeDashoffset}
                      strokeLinecap="round"
                      className="transition-all duration-300"
                    />
                  </svg>
                  
                  {/* Play button */}
                  <button
                    onClick={() => setIsPlaying(!isPlaying)}
                    className="w-14 h-14 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors backdrop-blur-sm"
                  >
                    {isPlaying ? (
                      <Pause className="w-5 h-5 text-white" fill="white" />
                    ) : (
                      <Play className="w-5 h-5 text-white ml-0.5" fill="white" />
                    )}
                  </button>
                </div>
              </div>
            </div>

            {/* Speakers */}
            {speakers.filter(speaker => speaker !== 'Unidentified').length > 0 && (
              <div className="mb-5">
                <div className="text-[12px] font-semibold uppercase tracking-wide opacity-75 mb-2">Speakers</div>
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
                        className="px-3 py-1.5 bg-white/10 backdrop-blur-sm border border-white/20 rounded-full text-[13px] cursor-pointer hover:bg-white/20 active:bg-white/30 transition-colors"
                      >
                        <span>{speaker}</span>
                      </button>
                    ))}
                </div>
              </div>
            )}

            {/* Separator */}
            <div className="relative h-px my-5">
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent"></div>
            </div>

            {/* Tabs */}
            <div className="mb-4">
              <div className="flex gap-1 bg-white/10 backdrop-blur-sm rounded-xl p-1">
                {(['Overview', 'Transcript', 'Actions'] as const).map((tab) => (
                  <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`flex-1 px-3 py-2 rounded-lg text-[13px] font-medium transition-all ${
                      activeTab === tab
                        ? 'bg-white/20 text-white shadow-sm'
                        : 'text-white/70 hover:text-white/90'
                    }`}
                  >
                    {tab}
                  </button>
                ))}
              </div>
            </div>

            {/* Tab Content - Overview */}
            {activeTab === 'Overview' && (
              <div className="max-h-[400px] overflow-y-auto px-1 -mx-1 scrollbar-thin">
                {/* Key Takeaways */}
                <div className="mb-4">
                  <div className="flex items-center gap-2 mb-2">
                    <Sparkles className="w-4 h-4" />
                    <h4 className="text-[13px] font-semibold opacity-90">Key Takeaways</h4>
                  </div>
                  <ul className="space-y-1.5 text-[14px] opacity-80">
                    {activities
                      .find((a) => a.type === 'key-takeaways')
                      ?.content.takeaways.map((takeaway: string, index: number) => (
                        <li key={index} className="flex items-start gap-2">
                          <span className="mt-1">•</span>
                          <span>{takeaway}</span>
                        </li>
                      ))}
                  </ul>
                </div>

                {/* Conversation Context */}
                <div className="mb-4">
                  <h4 className="text-[13px] font-semibold mb-2 opacity-90">Conversation Context</h4>
                  <div className="space-y-2.5">
                    <div>
                      <span className="text-[11px] font-medium opacity-60">Event:</span>
                      <p className="text-[14px] opacity-90 mt-0.5">CES 2026 exhibition discussion</p>
                    </div>
                    <div>
                      <span className="text-[11px] font-medium opacity-60">Timing:</span>
                      <p className="text-[14px] opacity-90 mt-0.5">Day 1 product exploration</p>
                    </div>
                    <div>
                      <span className="text-[11px] font-medium opacity-60">Format:</span>
                      <p className="text-[14px] opacity-90 mt-0.5">Walk-and-record conversation</p>
                    </div>
                    <div className="pt-2">
                      <span className="text-[11px] font-medium opacity-60">Goal:</span>
                      <p className="text-[14px] opacity-90 mt-0.5 leading-[1.4]">
                        Evaluate differentiation opportunities and reassess positioning in a crowded AI hardware market.
                      </p>
                    </div>
                  </div>
                </div>

                {/* Key Discussion Topics */}
                <div className="mb-4">
                  <h4 className="text-[13px] font-semibold mb-2 opacity-90">Key Discussion Topics</h4>
                  <ul className="space-y-1.5 text-[14px] opacity-80 leading-[1.4]">
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>Exhibition halls & city experiences influenced perception of products</span>
                    </li>
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>Innovative product interactions and user engagement patterns observed</span>
                    </li>
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>AI is no longer the sole selling point — usability and authenticity matter</span>
                    </li>
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>Data authenticity and practical implementation seen as key advantages</span>
                    </li>
                  </ul>
                </div>

                {/* Decisions & Directions */}
                <div className="mb-4">
                  <h4 className="text-[13px] font-semibold mb-2 opacity-90">Decisions & Directions</h4>
                  <ul className="space-y-1.5 text-[14px] opacity-80 leading-[1.4]">
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>Consider neurodivergent-focused UX as a differentiation strategy</span>
                    </li>
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>Position product around real-life usability rather than AI novelty</span>
                    </li>
                  </ul>
                </div>

                {/* Ideas & Opportunities */}
                <div className="mb-2">
                  <h4 className="text-[13px] font-semibold mb-2 opacity-90">Ideas & Opportunities</h4>
                  <ul className="space-y-1.5 text-[14px] opacity-80 leading-[1.4]">
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>Explore onboarding optimized for neurodivergent users</span>
                    </li>
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>Build narrative around practical usage and reliability</span>
                    </li>
                    <li className="flex gap-2">
                      <span className="mt-0.5 opacity-60">•</span>
                      <span>Study competitor gaps in user experience positioning</span>
                    </li>
                  </ul>
                </div>
              </div>
            )}

            {/* Tab Content - Transcript */}
            {activeTab === 'Transcript' && (
              <div className="max-h-[400px] overflow-y-auto px-1 -mx-1 scrollbar-thin">
                <div className="space-y-3 mb-2">
                  {/* Show all transcript items */}
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
                            ? 'bg-white/10 border border-white/20' 
                            : 'hover:bg-white/5'
                        }`}
                      >
                        <div className="flex-shrink-0 w-12 text-[12px] opacity-60 font-medium pt-0.5 flex items-start gap-1">
                          {item.hasMarkedMemo && (
                            <Star className="w-3 h-3 flex-shrink-0 mt-0.5 fill-[#FF9500] text-[#FF9500]" />
                          )}
                          <span>{item.time}</span>
                        </div>
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <span 
                              onClick={(e) => {
                                e.stopPropagation();
                                handleEditSpeaker(idx, item.speaker);
                              }}
                              className="text-[13px] font-semibold cursor-pointer hover:opacity-70 transition-opacity opacity-90"
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
                              className="flex-shrink-0 p-0.5 rounded-full bg-[#f2f2f7] text-[#8e8e93] hover:bg-[#e5e5ea] transition-colors"
                            >
                              {isCurrentPlaying ? (
                                <Pause className="w-3 h-3" fill="currentColor" strokeWidth={0} />
                              ) : (
                                <Play className="w-3 h-3 ml-[1px]" fill="currentColor" strokeWidth={0} />
                              )}
                            </button>
                          </div>
                          <p className={`text-[14px] leading-relaxed ${
                            isCurrentSegment ? 'text-[#1c1c1e] font-medium opacity-100' : 'opacity-80'
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
              <div>
                <p className="text-[13px] opacity-70 mb-3">
                  Possible follow-ups (suggested by AI)
                </p>
                <div className="space-y-3">
                  {suggestedActions.map((action) => (
                    <div
                      key={action.id}
                      className="bg-white/10 backdrop-blur-sm rounded-xl p-3 border border-white/20"
                    >
                      <p className="text-[14px] leading-relaxed opacity-90 mb-3">
                        {action.text}
                      </p>
                      {actionsWithTodos.has(action.id) ? (
                        <button 
                          disabled
                          className="px-3 py-1.5 bg-green-500/30 rounded-lg text-[13px] font-medium flex items-center gap-1.5 cursor-default"
                        >
                          <Check className="w-3.5 h-3.5" />
                          <span>Todo Created</span>
                        </button>
                      ) : (
                        <button 
                          onClick={() => {
                            setSelectedAction(action);
                            setShowActionTodoModal(true);
                          }}
                          className="px-3 py-1.5 bg-white/20 hover:bg-white/30 rounded-lg text-[13px] font-medium transition-colors flex items-center gap-1.5"
                        >
                          <Plus className="w-3.5 h-3.5" />
                          <span>Create Todo</span>
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Separator */}
            <div className="relative h-px my-5">
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent"></div>
            </div>

            {/* Generate Resummary Button */}
            <button
              onClick={handleGenerateResummary}
              className="w-full bg-white/20 hover:bg-white/30 backdrop-blur-sm rounded-xl py-3 font-medium text-[15px] transition-colors flex items-center justify-center gap-2 border border-white/30"
            >
              <RefreshCw className="w-4 h-4" />
              <span>Generate Resummary</span>
            </button>
          </div>

          {/* Activity Cards */}
          {(() => {
            // Group ALL todos and notes together (not just consecutive ones)
            const groupedActivities: Array<ActivityItem | { type: 'todo-group' | 'note-group', items: ActivityItem[], latestTimestamp: string }> = [];
            const todoActivities: ActivityItem[] = [];
            const noteActivities: ActivityItem[] = [];

            // First pass: collect all todos and notes from activities
            activities.forEach((activity) => {
              if (activity.type === 'todo') {
                todoActivities.push(activity);
              } else if (activity.type === 'note') {
                noteActivities.push(activity);
              }
            });
            
            // Also add memos from global state that are linked to this memory
            const linkedMemos = memos.filter(memo => 
              memo.relatedMemories && memo.relatedMemories.includes(memory.id)
            );
            
            // Convert linked memos to ActivityItem format and add to noteActivities
            linkedMemos.forEach(memo => {
              // Check if this memo is not already in noteActivities (to avoid duplicates)
              const alreadyExists = noteActivities.some(note => note.content.id === memo.id);
              if (!alreadyExists) {
                noteActivities.push({
                  id: `memo-${memo.id}`, // Prefix with 'memo-' to avoid ID conflicts with activities
                  type: 'note',
                  timestamp: formatMemoTimestamp(memo.timestamp),
                  content: {
                    id: memo.id,
                    text: memo.content,
                    title: memo.title,
                    type: memo.type || 'manual',
                    sourceMemory: memo.sourceMemory
                  }
                });
              }
            });

            let todoGroupInserted = false;
            let noteGroupInserted = false;

            // Build the final array with groups inserted at first occurrence
            activities.forEach((activity) => {
              if (activity.type === 'todo') {
                // Only insert todo group once at first todo position
                if (!todoGroupInserted) {
                  if (todoActivities.length > 1) {
                    groupedActivities.push({
                      type: 'todo-group',
                      items: todoActivities,
                      latestTimestamp: todoActivities[todoActivities.length - 1].timestamp
                    });
                  } else if (todoActivities.length === 1) {
                    groupedActivities.push(todoActivities[0]);
                  }
                  todoGroupInserted = true;
                }
                // Skip individual todos as they're now in the group
              } else if (activity.type === 'note') {
                // Only insert note group once at first note position
                if (!noteGroupInserted) {
                  if (noteActivities.length > 1) {
                    groupedActivities.push({
                      type: 'note-group',
                      items: noteActivities,
                      latestTimestamp: noteActivities[noteActivities.length - 1].timestamp
                    });
                  } else if (noteActivities.length === 1) {
                    groupedActivities.push(noteActivities[0]);
                  }
                  noteGroupInserted = true;
                }
                // Skip individual notes as they're now in the group
              } else {
                // Add other activities in their original position
                groupedActivities.push(activity);
              }
            });

            return groupedActivities.map((item, groupIndex) => {
              // Handle todo group
              if ('type' in item && item.type === 'todo-group') {
                const group = item as { type: 'todo-group', items: ActivityItem[], latestTimestamp: string };
                
                return (
                  <div 
                    key={`todo-group-${groupIndex}`}
                    className={'bg-white rounded-2xl p-5 shadow-sm border-l-4 border-[#2d5a47]'}
                  >
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center gap-2">
                        <div className={'w-7 h-7 rounded-full flex items-center justify-center bg-[#2d5a47]/10'}>
                          <CheckSquare className={'w-4 h-4 text-[#2d5a47]'} />
                        </div>
                        <h3 className="text-[13px] font-semibold uppercase tracking-wide text-[#8e8e93]">
                          Todos Created
                        </h3>
                      </div>
                      <span className="text-[12px] text-[#8e8e93]">{group.latestTimestamp}</span>
                    </div>
                    
                    <div className="space-y-0">
                      {group.items.map((activity, idx) => {
                        const isCompleted = activity.content.completed || false;
                        const getPriorityColor = (priority: string) => {
                          if (priority === 'High priority') return 'text-[#ff3b30]';
                          if (priority === 'Normal') return 'text-[#ff9500]';
                          return 'text-[#8e8e93]';
                        };
                        
                        return (
                          <button
                            key={activity.id}
                            onClick={() => {
                              setSelectedTodo(activity.content);
                              setSelectedTodoActivityId(activity.id);
                            }}
                            className={`w-full text-left px-0 py-3 hover:bg-[#f9f9f9] transition-colors ${
                              idx < group.items.length - 1 ? 'border-b border-black/[0.06]' : ''
                            }`}
                          >
                            <h4 className={`text-[17px] font-medium mb-1.5 ${
                              isCompleted ? 'text-[#8e8e93] line-through' : 'text-[#1c1c1e]'
                            }`}>
                              {activity.content.title}
                            </h4>
                            <div className="flex items-center gap-2 text-[14px]">
                              <span className={getPriorityColor(activity.content.priority) + ' font-medium'}>
                                {activity.content.priority}
                              </span>
                              <span className="text-[#8e8e93]">·</span>
                              <span className="text-[#8e8e93]">
                                {activity.content.dueDate}
                              </span>
                            </div>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                );
              }
              
              // Handle note group
              if ('type' in item && item.type === 'note-group') {
                const group = item as { type: 'note-group', items: ActivityItem[], latestTimestamp: string };
                
                return (
                  <div 
                    key={`note-group-${groupIndex}`}
                    className="bg-white rounded-2xl p-5 shadow-sm border-l-4 border-[#007aff]"
                  >
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center gap-2">
                        <div className="w-7 h-7 rounded-full bg-[#007aff]/10 flex items-center justify-center">
                          <Edit3 className="w-4 h-4 text-[#007aff]" />
                        </div>
                        <h3 className="text-[13px] font-semibold uppercase tracking-wide text-[#8e8e93]">
                          My Memos
                        </h3>
                      </div>
                      <span className="text-[12px] text-[#8e8e93]">{group.latestTimestamp}</span>
                    </div>
                    
                    <div className="space-y-0">
                      {group.items.map((activity, idx) => (
                        <button
                          key={activity.id}
                          onClick={() => setSelectedMemo(activity.content)}
                          className={`w-full text-left px-0 py-3 hover:bg-[#f9f9f9] transition-colors ${
                            idx < group.items.length - 1 ? 'border-b border-black/[0.06]' : ''
                          }`}
                        >
                          <p className="text-[15px] text-[#1c1c1e] leading-relaxed italic">
                            "{activity.content.text}"
                          </p>
                        </button>
                      ))}
                    </div>
                  </div>
                );
              }
              
              // Handle single activity (original rendering logic)
              const activity = item as ActivityItem;
          
            if (activity.type === 'key-takeaways') {
              // Key Takeaways now shown in Overview tab, so skip rendering as separate card
              return null;
            }

            if (activity.type === 'ai-insight') {
              const isExpanded = expandedInsights.has(activity.id);
              const text = activity.content.text;
              const shouldTruncate = text.length > 120;
              const displayText = isExpanded || !shouldTruncate ? text : text.substring(0, 120) + '...';

              return (
                <div key={activity.id} className="bg-gradient-to-br from-[#f0e7ff] to-[#e6d9ff] rounded-2xl p-5 shadow-sm border border-[#d4c5f9]">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-full bg-[#7c3aed]/20 flex items-center justify-center">
                        <Sparkles className="w-4 h-4 text-[#7c3aed]" />
                      </div>
                      <h3 className="text-[13px] font-semibold uppercase tracking-wide text-[#7c3aed]">
                        AI Insight
                      </h3>
                    </div>
                    <span className="text-[12px] text-[#8e8e93]">{activity.timestamp}</span>
                  </div>
                  <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-3">
                    {displayText}
                  </p>
                  {shouldTruncate && (
                    <button 
                      onClick={() => toggleInsightExpansion(activity.id)}
                      className="text-[14px] text-[#7c3aed] font-medium hover:opacity-70 transition-opacity"
                    >
                      {isExpanded ? 'Show less' : 'Read more'}
                    </button>
                  )}
                </div>
              );
            }

            if (activity.type === 'todo') {
              const isCompleted = activity.content.completed || false;
              
              return (
                <div 
                  key={activity.id} 
                  className={'bg-white rounded-2xl p-5 shadow-sm border-l-4 cursor-pointer hover:shadow-md transition-shadow ' + (isCompleted ? 'border-[#34c759] opacity-70' : 'border-[#2d5a47]')}
                  onClick={() => {
                    // Ensure linkedMemory is set if not already present
                    const todoWithMemory = {
                      ...activity.content,
                      linkedMemory: activity.content.linkedMemory || {
                        id: String(memory.id),
                        title: memory.title,
                        date: memory.date,
                        duration: memory.audioDuration,
                        hasSummary: memory.hasSummary
                      }
                    };
                    setSelectedTodo(todoWithMemory);
                    setSelectedTodoActivityId(activity.id);
                  }}
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <div className={'w-7 h-7 rounded-full flex items-center justify-center ' + (isCompleted ? 'bg-[#34c759]/10' : 'bg-[#2d5a47]/10')}>
                        <CheckSquare className={'w-4 h-4 ' + (isCompleted ? 'text-[#34c759]' : 'text-[#2d5a47]')} />
                      </div>
                      <h3 className="text-[13px] font-semibold uppercase tracking-wide text-[#8e8e93]">
                        {isCompleted ? 'Todo Completed' : 'Todo Created'}
                      </h3>
                    </div>
                    <span className="text-[12px] text-[#8e8e93]">{activity.timestamp}</span>
                  </div>
                  <h4 className={'text-[16px] font-medium mb-2 ' + (isCompleted ? 'text-[#8e8e93] line-through' : 'text-[#1c1c1e]')}>
                    {activity.content.title}
                  </h4>
                  <div className="flex items-center gap-3 text-[13px] text-[#8e8e93]">
                    <span>Priority: <span className="text-[#ff3b30] font-medium">{activity.content.priority}</span></span>
                    <span>•</span>
                    <span>When: {activity.content.dueDate}</span>
                  </div>
                </div>
              );
            }

            if (activity.type === 'note') {
              return (
                <div 
                  key={activity.id} 
                  className="bg-white rounded-2xl p-5 shadow-sm border-l-4 border-[#007aff] cursor-pointer hover:shadow-md transition-shadow"
                  onClick={() => setSelectedMemo(activity.content)}
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-full bg-[#007aff]/10 flex items-center justify-center">
                        <Edit3 className="w-4 h-4 text-[#007aff]" />
                      </div>
                      <h3 className="text-[13px] font-semibold uppercase tracking-wide text-[#8e8e93]">
                        My Memo
                      </h3>
                    </div>
                    <span className="text-[12px] text-[#8e8e93]">{activity.timestamp}</span>
                  </div>
                  <p className="text-[15px] text-[#1c1c1e] leading-relaxed italic">
                    "{activity.content.text}"
                  </p>
                </div>
              );
            }

            if (activity.type === 'ask-ai') {
              const messages = activity.content.messages || [];
              const hasMessages = messages.length > 0;
              
              return (
                <div 
                  key={activity.id} 
                  className="bg-white rounded-2xl p-5 shadow-sm border border-[#e5e5ea] cursor-pointer hover:shadow-md transition-shadow"
                  onClick={() => setShowAIChatModal(true)}
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-full bg-[#34c759]/10 flex items-center justify-center">
                        <MessageSquare className="w-4 h-4 text-[#34c759]" />
                      </div>
                      <h3 className="text-[13px] font-semibold uppercase tracking-wide text-[#8e8e93]">
                        You Asked
                      </h3>
                    </div>
                    <span className="text-[12px] text-[#8e8e93]">{activity.timestamp}</span>
                  </div>
                  
                  {hasMessages ? (
                    <>
                      {/* Show conversation preview */}
                      <div className="space-y-2">
                        {/* Show last 2 messages */}
                        {messages.slice(-2).map((msg: any, idx: number) => (
                          <div key={idx}>
                            {msg.role === 'user' ? (
                              <div className="bg-[#007aff]/5 rounded-xl p-3">
                                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                                  {msg.content}
                                </p>
                              </div>
                            ) : (
                              <div className="pl-3 border-l-2 border-[#34c759]/30">
                                <div className="flex items-center gap-2 mb-1.5">
                                  <Sparkles className="w-3.5 h-3.5 text-[#34c759]" />
                                  <span className="text-[11px] font-semibold uppercase tracking-wide text-[#8e8e93]">AI</span>
                                </div>
                                <p className="text-[14px] text-[#3c3c43] leading-relaxed">
                                  {msg.content}
                                </p>
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                      
                      {/* Show conversation count if more than 2 messages */}
                      {messages.length > 2 && (
                        <div className="mt-3 pt-3 border-t border-[#e5e5ea]">
                          <p className="text-[13px] text-[#8e8e93] text-center">
                            {messages.length} messages · Tap to continue
                          </p>
                        </div>
                      )}
                    </>
                  ) : (
                    /* Empty state - no messages yet */
                    <div className="text-center py-4">
                      <p className="text-[14px] text-[#8e8e93]">
                        Tap to start chatting with AI
                      </p>
                    </div>
                  )}
                </div>
              );
            }

            if (activity.type === 'resummary') {
              const isExpanded = expandedInsights.has(activity.id);
              const isGenerating = generatingActivities.has(String(activity.id));
              
              // Safety check for sections
              if (!activity.content.sections || activity.content.sections.length === 0) {
                return null;
              }

              return (
                <div key={activity.id} className="bg-white rounded-2xl p-5 shadow-sm border border-[#e5e5ea]">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-full bg-[#34c759]/10 flex items-center justify-center">
                        <FileText className="w-4 h-4 text-[#34c759]" />
                      </div>
                      <h3 className="text-[13px] font-semibold uppercase tracking-wide text-[#8e8e93]">
                        Resummary
                      </h3>
                    </div>
                    <span className="text-[12px] text-[#8e8e93]">{activity.timestamp}</span>
                  </div>
                  
                  {isGenerating ? (
                    /* Loading state - AI is generating */
                    <div className="flex flex-col items-center justify-center py-12">
                      {/* Animated sparkles icon */}
                      <div className="relative mb-4">
                        <div className="absolute inset-0 animate-ping">
                          <Sparkles className="w-12 h-12 text-[#34c759] opacity-20" />
                        </div>
                        <Sparkles className="w-12 h-12 text-[#34c759] animate-pulse" />
                      </div>
                      
                      {/* Loading text */}
                      <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-1.5">
                        AI is analyzing...
                      </h3>
                      <p className="text-[14px] text-[#8e8e93] text-center max-w-[280px] leading-relaxed">
                        Generating a fresh perspective based on your recording
                      </p>
                      
                      {/* Progress dots animation */}
                      <div className="flex items-center gap-1.5 mt-5">
                        <div className="w-2 h-2 rounded-full bg-[#34c759] animate-bounce" style={{ animationDelay: '0ms' }}></div>
                        <div className="w-2 h-2 rounded-full bg-[#34c759] animate-bounce" style={{ animationDelay: '150ms' }}></div>
                        <div className="w-2 h-2 rounded-full bg-[#34c759] animate-bounce" style={{ animationDelay: '300ms' }}></div>
                      </div>
                    </div>
                  ) : (
                    /* Actual content after generation */
                    <>
                      {/* Template Tag */}
                      {(activity.content.styleId || activity.content.perspective) && (
                        <div className="mb-4">
                          <span className="inline-block px-3 py-1.5 bg-[#34c759]/10 rounded-full text-[13px] text-[#34c759] font-medium">
                            {activity.content.styleId ? getTemplateDisplayName(activity.content.styleId) : activity.content.perspective}
                          </span>
                        </div>
                      )}

                      {/* Article Title */}
                      {activity.content.title && (
                        <h2 className="text-[20px] font-bold text-[#1c1c1e] leading-tight mb-4">
                          {activity.content.title}
                        </h2>
                      )}

                      {/* Show first section only when collapsed */}
                      {!isExpanded ? (
                        <>
                          <div className="mb-3">
                            <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-2">
                              {activity.content.sections[0].heading}
                            </h3>
                            <p className="text-[15px] text-[#3c3c43] leading-relaxed">
                              {activity.content.sections[0].content}
                            </p>
                          </div>
                          <button 
                            onClick={() => toggleInsightExpansion(activity.id)}
                            className="text-[14px] text-[#34c759] font-medium hover:opacity-70 transition-opacity flex items-center gap-1"
                          >
                            <span>Read full analysis</span>
                            <ChevronDown className="w-4 h-4" />
                          </button>
                        </>
                      ) : (
                        <>
                          {/* All sections when expanded */}
                          <div className="space-y-5 mb-4">
                            {activity.content.sections.map((section: { heading: string, content: string }, index: number) => (
                              <div key={index}>
                                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-2">
                                  {section.heading}
                                </h3>
                                <p className="text-[15px] text-[#3c3c43] leading-relaxed">
                                  {section.content}
                                </p>
                              </div>
                            ))}
                          </div>
                          <button 
                            onClick={() => toggleInsightExpansion(activity.id)}
                            className="text-[14px] text-[#34c759] font-medium hover:opacity-70 transition-opacity flex items-center gap-1"
                          >
                            <span>Show less</span>
                            <ChevronDown className="w-4 h-4 rotate-180" />
                          </button>
                        </>
                      )}
                    </>
                  )}
                </div>
              );
            }

            if (activity.type === 'expert-insight') {
              return (
                <ExpertInsightCard
                  key={activity.id}
                  expertType={activity.content.expertType}
                  timestamp={activity.timestamp}
                  mainContent={activity.content.mainContent}
                  riskSection={activity.content.riskSection}
                  suggestion={activity.content.suggestion}
                  hasTodoAdded={expertInsightsWithTodos.has(activity.id)}
                  onAddTodo={() => {
                    // Open the New Todo modal with pre-filled suggestion
                    setNewTodoSuggestion(activity.content.suggestion);
                    setNewTodoInsightContent(activity.content.mainContent);
                    setCurrentExpertInsightId(activity.id);
                    setShowNewTodoModal(true);
                  }}
                />
              );
            }

            return null;
          });
        })()}
        </div>
      </div>

      {/* Bottom Quick Input Area */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-black/[0.06] px-5 py-4 max-w-md mx-auto">
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
              onClick={() => {
                // Simply open chat modal without creating activity
                // Activity will be created when user sends first message
                setShowAIChatModal(true);
              }}
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

      {/* Todo Detail Modal */}
      {selectedTodo && selectedTodoActivityId !== null && (
        <TodoDetailModal
          todo={selectedTodo}
          onClose={() => {
            setSelectedTodo(null);
            setSelectedTodoActivityId(null);
          }}
          onMarkDone={() => {
            // Mark todo as completed in the activities
            setActivities(activities.map(a => {
              if (a.id === selectedTodoActivityId && a.type === 'todo') {
                return {
                  ...a,
                  content: {
                    ...a.content,
                    completed: true
                  }
                };
              }
              return a;
            }));
            setSelectedTodo(null);
            setSelectedTodoActivityId(null);
          }}
          onDelete={() => {
            // Show confirmation dialog
            setTodoToDelete({ activityId: selectedTodoActivityId, todoId: selectedTodo.id });
            setShowDeleteConfirm(true);
            setSelectedTodo(null);
            setSelectedTodoActivityId(null);
          }}
          onUpdate={(id, updates) => {
            // Update todo in the activities
            setActivities(activities.map(a => {
              if (a.id === selectedTodoActivityId && a.type === 'todo') {
                return {
                  ...a,
                  content: {
                    ...a.content,
                    ...updates
                  }
                };
              }
              return a;
            }));
            // Update selectedTodo to reflect changes
            setSelectedTodo({ ...selectedTodo, ...updates });
          }}
        />
      )}

      {/* Memo Detail Modal */}
      {selectedMemo && (
        <MemoDetailModal
          memo={{ 
            id: selectedMemo.id, 
            content: selectedMemo.text, 
            title: selectedMemo.title,
            type: selectedMemo.type,
            sourceMemory: selectedMemo.sourceMemory
          }}
          onClose={() => setSelectedMemo(null)}
          onDelete={(memoId) => {
            // Find the activity with this memo and delete it
            const activityToDelete = activities.find(a => a.type === 'note' && a.content.id === memoId);
            if (activityToDelete) {
              handleDeleteActivity(activityToDelete.id);
            }
            setSelectedMemo(null);
          }}
          onCreateTodo={(memoId) => {
            // Find the memo content
            const memoActivity = activities.find(a => a.type === 'note' && a.content.id === memoId);
            if (memoActivity) {
              setNewTodoSuggestion(memoActivity.content.text || '');
              setNewTodoInsightContent(''); // Clear insight content since this is from a note
              setCurrentExpertInsightId(null); // Not from expert insight
              setShowNewTodoModal(true);
            }
            setSelectedMemo(null);
          }}
          onAnalyzeActions={onAnalyzeActions}
          onHighlightClick={(memoryId, timestamp) => {
            // Close the memo modal
            setSelectedMemo(null);
            // Switch to transcript tab
            setActiveTab('Transcript');
            // Auto-scroll and highlight the timestamp
            setTimeout(() => {
              const targetIndex = transcriptData.findIndex(item => item.time === timestamp);
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
          }}
        />
      )}

      {/* New Todo from Expert Insight Modal */}
      {showNewTodoModal && (
        <NewTodoFromMemoModal
          suggestion={newTodoSuggestion}
          insightContent={newTodoInsightContent}
          memory={{
            id: String(memory.id),
            title: memory.title,
            date: memory.date,
            duration: memory.audioDuration,
            hasSummary: memory.hasSummary
          }}
          onClose={() => {
            setShowNewTodoModal(false);
            setNewTodoSuggestion('');
            setNewTodoInsightContent('');
            setCurrentExpertInsightId(null);
          }}
          onCreateTodo={(newTodo) => {
            // Create activity item format expected by the flow
            const newActivity = {
              id: activities.length + 1,
              type: 'todo' as const,
              timestamp: 'Just now',
              content: {
                id: activities.length + 101,
                title: newTodo.title,
                priority: newTodo.priority,
                dueDate: newTodo.dueDate,
                context: memory.title,
                time: newTodo.time,
                notes: newTodo.notes || [],
                linkedMemory: {
                  id: String(memory.id),
                  title: memory.title,
                  date: memory.date,
                  duration: memory.audioDuration,
                  hasSummary: memory.hasSummary
                }
              }
            };
            setActivities([...activities, newActivity]);
            // Mark this expert insight as having a todo added
            if (currentExpertInsightId) {
              setExpertInsightsWithTodos(new Set([...expertInsightsWithTodos, currentExpertInsightId]));
            }
            setShowNewTodoModal(false);
            setNewTodoSuggestion('');
            setNewTodoInsightContent('');
            setCurrentExpertInsightId(null);
            if (onAddTodo) {
              onAddTodo(newActivity.content);
            }
          }}
        />
      )}

      {/* New Todo from Action Modal */}
      {showActionTodoModal && selectedAction && (
        <NewTodoFromMemoModal
          suggestion={selectedAction.text}
          insightContent={''}
          memory={{
            id: String(memory.id),
            title: memory.title,
            date: memory.date,
            duration: memory.audioDuration,
            hasSummary: memory.hasSummary
          }}
          onClose={() => {
            setShowActionTodoModal(false);
            setSelectedAction(null);
          }}
          onCreateTodo={(newTodo) => {
            // Create activity item format expected by the flow
            const newActivity = {
              id: activities.length + 1,
              type: 'todo' as const,
              timestamp: 'Just now',
              content: {
                id: activities.length + 101,
                title: newTodo.title,
                priority: newTodo.priority,
                dueDate: newTodo.dueDate,
                context: memory.title,
                time: newTodo.time,
                notes: newTodo.notes || [],
                linkedMemory: {
                  id: String(memory.id),
                  title: memory.title,
                  date: memory.date,
                  duration: memory.audioDuration,
                  hasSummary: memory.hasSummary
                }
              }
            };
            setActivities([...activities, newActivity]);
            // Mark this action as having a todo created
            if (selectedAction) {
              setActionsWithTodos(new Set([...actionsWithTodos, selectedAction.id]));
            }
            setShowActionTodoModal(false);
            setSelectedAction(null);
            if (onAddTodo) {
              onAddTodo(newActivity.content);
            }
          }}
        />
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && todoToDelete && (
        <div className="fixed inset-0 bg-black/[0.5] flex items-center justify-center">
          <div className="bg-white rounded-xl p-6 max-w-sm text-center">
            <h3 className="text-[18px] font-bold mb-4">Delete Todo?</h3>
            <p className="text-[15px] text-[#3c3c43] leading-relaxed mb-6">
              Are you sure you want to delete this todo?
            </p>
            <div className="flex gap-4">
              <button
                onClick={() => {
                  setShowDeleteConfirm(false);
                  setTodoToDelete(null);
                }}
                className="bg-[#ff3b30] text-white rounded-xl px-5 py-3 font-medium text-[15px] hover:bg-[#e53935] transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  handleDeleteActivity(todoToDelete.activityId);
                  setShowDeleteConfirm(false);
                  setTodoToDelete(null);
                }}
                className="bg-[#007aff] text-white rounded-xl px-5 py-3 font-medium text-[15px] hover:bg-[#0051d5] transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
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
        onContinue={handleShareContentContinue}
        summaryVersions={getSummaryVersions()}
        expertInsights={getAvailableExpertInsightsForSharing()}
      />

      {/* Share Options Modal (Step 2) */}
      <ShareOptionsModal
        isOpen={showShareOptionsModal}
        onClose={() => setShowShareOptionsModal(false)}
        onShare={async () => {
          const shareUrl = `https://app.example.com/memory/${memory.id}`;
          const shareText = `${memory.title}\n\n${memory.transcript}\n\n${shareUrl}`;

          try {
            // Try native share API
            if (navigator.share && navigator.canShare) {
              const shareData = {
                title: 'Memory from AI Assistant',
                text: shareText
              };
              
              if (navigator.canShare(shareData)) {
                await navigator.share(shareData);
                return;
              }
            }
            
            // Fallback: copy to clipboard
            await navigator.clipboard.writeText(shareText);
            alert('✓ Copied to clipboard! You can now paste and share.');
          } catch (err) {
            const error = err as Error;
            if (error.name === 'AbortError') return;
            
            // Last resort
            try {
              await navigator.clipboard.writeText(shareText);
              alert('✓ Copied to clipboard!');
            } catch {
              alert(`Share link:\n\n${shareUrl}`);
            }
          }
        }}
        onCopyLink={async () => {
          const shareUrl = `https://app.example.com/memory/${memory.id}`;
          try {
            await navigator.clipboard.writeText(shareUrl);
            alert('✓ Link copied to clipboard!');
          } catch {
            alert(`Copy this link:\n\n${shareUrl}`);
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
          const markdownContent = `# ${memory.title}\n\n**Date:** ${memory.date}\n**Duration:** ${memory.audioDuration}\n\n## Summary\n\n${memory.summary}\n\n## Transcript\n\n${memory.transcript}`;
          
          try {
            const blob = new Blob([markdownContent], { type: 'text/markdown' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `${memory.title.replace(/[^a-z0-9]/gi, '_')}.md`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
          } catch {
            alert('Export failed. Please try again.');
          }
        }}
      />

      {/* Memory Options Modal */}
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
                  AI will analyze this memory from a new perspective and create a resummary.
                </p>
              </div>

              {/* Unified Summary Features Card */}
              <div className="bg-[#f2f2f7] rounded-[16px] p-4 mb-4">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-3">
                  What you'll get:
                </h3>
                <div className="space-y-3">
                  {/* Different perspective */}
                  <div className="flex items-start gap-3">
                    <div className="w-5 h-5 flex-shrink-0 flex items-center justify-center">
                      <Sparkles className="w-[18px] h-[18px] text-[#007aff]" strokeWidth={2} />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-[15px] font-medium text-[#1c1c1e] mb-0.5">
                        Different perspective
                      </h4>
                      <p className="text-[13px] text-[#3c3c43] leading-[1.3]">
                        Analyze this memory through a new lens
                      </p>
                    </div>
                  </div>

                  {/* Fresh insights */}
                  <div className="flex items-start gap-3">
                    <div className="w-5 h-5 flex-shrink-0 flex items-center justify-center">
                      <FileText className="w-[18px] h-[18px] text-[#007aff]" strokeWidth={2} />
                    </div>
                    <div className="flex-1">
                      <h4 className="text-[15px] font-medium text-[#1c1c1e] mb-0.5">
                        Fresh insights
                      </h4>
                      <p className="text-[13px] text-[#3c3c43] leading-[1.3]">
                        Discover details you might have missed
                      </p>
                    </div>
                  </div>

                  {/* Structured analysis */}
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
                        Structured analysis
                      </h4>
                      <p className="text-[13px] text-[#3c3c43] leading-[1.3]">
                        Organized sections based on style
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
                    setTempSelectedTemplate(selectedTemplate);
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
                  setShowResummaryModal(false);
                  // Generate resummary with selected style
                  handleGenerateResummaryWithStyle(selectedTemplate);
                }}
                className="w-full bg-[#007aff] text-white text-[17px] font-semibold py-3.5 rounded-[14px] hover:bg-[#0051d5] transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                <Sparkles className="w-5 h-5" />
                <span>Generate resummary</span>
              </button>

              {/* Additional info text */}
              <p className="text-[12px] text-[#8e8e93] text-center mt-3 leading-[1.4]">
                This will add a new activity card below
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Choose Summary Style Modal */}
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

                return (
                  <div className="space-y-1.5 mb-2.5">
                    {templatesToShow.map((templateId: string) => {
                      const template = allTemplates[templateId];
                      if (!template) return null;

                      return (
                        <button
                          key={templateId}
                          onClick={() => setTempSelectedTemplate(templateId)}
                          className={`w-full bg-[#f2f2f7] rounded-[12px] p-2.5 text-left border-2 transition-all ${
                            tempSelectedTemplate === templateId ? 'border-[#007aff] bg-[#f0f7ff]' : 'border-transparent'
                          }`}
                        >
                          <div className="flex items-start gap-2">
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
                    setShowTemplateModal(false);
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

      {/* AI Chat Modal */}
      <AIChatModal
        isOpen={showAIChatModal}
        onClose={() => setShowAIChatModal(false)}
        initialMessages={(() => {
          const askAIActivity = activities.find(a => a.type === 'ask-ai');
          return askAIActivity?.content.messages || [];
        })()}
        onSaveMessages={(messages) => {
          // Check if ask-ai activity already exists
          const existingAskAI = activities.find(a => a.type === 'ask-ai');
          
          if (existingAskAI) {
            // Update existing activity
            setActivities(activities.map(a => {
              if (a.type === 'ask-ai') {
                return {
                  ...a,
                  timestamp: 'Just now',
                  content: {
                    messages: messages
                  }
                };
              }
              return a;
            }));
          } else {
            // Create new ask-ai activity if there are messages
            if (messages.length > 0) {
              const newAskActivity: ActivityItem = {
                id: Math.max(...activities.map(a => a.id), 0) + 1,
                type: 'ask-ai',
                timestamp: 'Just now',
                content: {
                  messages: messages
                }
              };
              setActivities([...activities, newAskActivity]);
            }
          }
        }}
        memoryTitle={memory.title}
      />

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
              // Generate resummary with selected style
              handleGenerateResummaryWithStyle(styleId);
            }}
            fromAudioMemory={true}
          />
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