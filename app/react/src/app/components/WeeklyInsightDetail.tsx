import { ChevronLeft, Share2, Copy, Download, Briefcase, Palette, Wrench, Heart, MoreVertical, Star, Sparkles, Check } from 'lucide-react';
import { useState, useEffect } from 'react';
import { ShareOptionsModal } from './ShareOptionsModal';
import { MemoryOptionsModal } from './MemoryOptionsModal';
import { AIChatModal } from './AIChatModal';
import { TodoDetailModal } from './TodoDetailModal';
import { NewTodoFromMemoModal } from './NewTodoFromMemoModal';

interface WeeklyInsightDetailProps {
  insight: any;
  onClose: () => void;
  todos?: any[];
  onMarkDone?: (id: number) => void;
  onNotNow?: (id: number) => void;
  onDelete?: (id: number) => void;
  onUpdateTodo?: (id: number, updates: any) => void;
  onAddTodo?: (todo: any) => void;
}

export function WeeklyInsightDetail({ insight, onClose, todos, onMarkDone, onNotNow, onDelete, onUpdateTodo, onAddTodo }: WeeklyInsightDetailProps) {
  const [showShareOptionsModal, setShowShareOptionsModal] = useState(false);
  const [showMemoryOptionsModal, setShowMemoryOptionsModal] = useState(false);
  const [showAIChatModal, setShowAIChatModal] = useState(false);
  const [selectedExpert, setSelectedExpert] = useState<string>('');
  const [showTodoModal, setShowTodoModal] = useState(false);
  const [selectedTodo, setSelectedTodo] = useState<any>(null);
  const [addedTodoItems, setAddedTodoItems] = useState<Set<number>>(() => {
    // Load from localStorage based on insight id
    const stored = localStorage.getItem(`weekly-insight-added-todos-${insight.id || 'current'}`);
    if (stored) {
      try {
        const array = JSON.parse(stored);
        return new Set(array);
      } catch (e) {
        return new Set();
      }
    }
    return new Set();
  });
  const [showAddTodoModal, setShowAddTodoModal] = useState(false);
  const [selectedTodoItem, setSelectedTodoItem] = useState<string>('');
  const [selectedTodoSubtitle, setSelectedTodoSubtitle] = useState<string>('');
  
  // Load chat messages from localStorage for this specific weekly insight
  const [chatMessages, setChatMessages] = useState<any[]>(() => {
    const stored = localStorage.getItem(`weekly-insight-chat-${insight.id || 'current'}`);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch (e) {
        return [];
      }
    }
    return [];
  });

  // Maintain a list of "this week's todo IDs" - initialized once, limited to 4 items
  const [weeklyTodoIds, setWeeklyTodoIds] = useState<number[]>(() => {
    // Initialize with todos from Today, Upcoming, Later, Up Next - but only 4 total
    if (todos) {
      // Get todos from different categories
      const todayTodos = todos.filter(t => t.category === 'Today');
      const upcomingTodos = todos.filter(t => t.category === 'Upcoming');
      const laterTodos = todos.filter(t => t.category === 'Later');
      const upNextTodos = todos.filter(t => t.category === 'Up Next');
      
      // Mix and match to get 4 todos total
      const selectedTodos = [
        ...todayTodos.slice(0, 1),      // 1 from Today
        ...upcomingTodos.slice(0, 1),   // 1 from Upcoming
        ...laterTodos.slice(0, 1),      // 1 from Later
        ...upNextTodos.slice(0, 1),     // 1 from Up Next
      ].slice(0, 4); // Ensure max 4 items
      
      return selectedTodos.map(t => t.id);
    }
    return [];
  });

  // Get the todos to display - all todos whose ID is in weeklyTodoIds
  const pendingItemsToDisplay = todos?.filter(t => weeklyTodoIds.includes(t.id)) || [];

  // Next Week Priorities data
  const nextWeekPriorities = [
    {
      title: 'Launch Mobile Beta',
      subtitle: 'Target: Thursday EOD'
    },
    {
      title: 'Q1 Planning Session',
      subtitle: 'All-hands meeting on Tuesday'
    },
    {
      title: 'Performance Optimization',
      subtitle: 'Focus on API response times'
    }
  ];

  // Expert feedback data
  const expertFeedback = [
    {
      id: 'business',
      name: 'Business Expert',
      icon: Briefcase,
      iconColor: 'text-[#007aff]',
      feedback: 'Pricing direction remains unclear across multiple conversations. Aligning ownership and decision checkpoints could prevent strategic drift next month.'
    },
    {
      id: 'creative',
      name: 'Creative Expert',
      icon: Palette,
      iconColor: 'text-[#af52de]',
      feedback: 'Recurring discussions suggest onboarding simplification and user education may offer untapped differentiation opportunities. Exploration here could unlock growth.'
    },
    {
      id: 'execution',
      name: 'Execution Expert',
      icon: Wrench,
      iconColor: 'text-[#ff9500]',
      feedback: 'Delivery risk persists due to infrastructure dependencies and cross-team coordination. Earlier escalation of blockers may help avoid timeline slippage.'
    },
    {
      id: 'wellness',
      name: 'Wellness Expert',
      icon: Heart,
      iconColor: 'text-[#34c759]',
      feedback: 'Energy dipped mid-week as workload peaked. Protecting recovery windows and avoiding stacked deadlines could sustain performance.'
    }
  ];

  const handleExpertClick = (expert: typeof expertFeedback[0]) => {
    // Load saved chat messages for this expert
    const storageKey = `weekly-expert-chat-${insight.id || 'current'}-${expert.id}`;
    const stored = localStorage.getItem(storageKey);
    
    let messages = [];
    if (stored) {
      try {
        messages = JSON.parse(stored);
      } catch (e) {
        messages = [];
      }
    }
    
    // If no existing chat, add the expert's feedback as the first message
    if (messages.length === 0) {
      messages = [{
        role: 'assistant' as const,
        content: expert.feedback,
        timestamp: 'Just now',
        expertName: expert.name
      }];
    }
    
    setSelectedExpert(expert.name);
    setChatMessages(messages);
    setShowAIChatModal(true);
  };

  return (
    <div className="flex flex-col h-full bg-white">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06] relative">
        <button
          onClick={onClose}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-6 h-6" strokeWidth={2} />
        </button>
        <div className="absolute left-1/2 transform -translate-x-1/2 text-center">
          <h1 className="text-[17px] font-semibold text-[#1c1c1e]">Weekly Insights</h1>
          <p className="text-[13px] text-[#8e8e93]">Jan 19 – Jan 25</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowShareOptionsModal(true)}
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

      {/* Content */}
      <div className="flex-1 overflow-y-auto bg-[#f2f2f7] px-5 pt-5 pb-24">
        <div className="space-y-4">
          {/* Hero Card */}
          <div className="bg-gradient-to-br from-[#f0fdfa] to-[#e0f2fe] rounded-2xl p-5 border border-[#a5f3fc]/40">
            <div className="flex items-start gap-2 mb-3">
              <span className="text-[24px] leading-none">📊</span>
              <div className="flex-1">
                <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-1">
                  Week of Jan 19-25
                </h2>
                <p className="text-[14px] text-[#8e8e93]">
                  End-of-week reflection · Sunday, 10:00 AM
                </p>
              </div>
            </div>
            <p className="text-[15px] text-[#3c3c43] leading-[1.5]">
              A productive week with strong momentum on the product roadmap. You balanced strategic planning with hands-on execution, completing 8 major tasks while identifying 3 key priorities for next week.
            </p>
          </div>

          {/* 1. Week Summary */}
          <div className="bg-white rounded-2xl p-5 border border-border shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-3">Week Summary</h3>
            <div className="space-y-3">
              <div>
                <p className="text-[13px] text-[#8e8e93] mb-1">Focus Areas</p>
                <p className="text-[15px] text-[#3c3c43] leading-[1.5]">
                  Product development, team coordination, and client engagement dominated this week. You spent approximately 60% of time on execution and 40% on planning and meetings.
                </p>
              </div>
              <div>
                <p className="text-[13px] text-[#8e8e93] mb-1">Key Metrics</p>
                <div className="grid grid-cols-3 gap-3 mt-2">
                  <div className="text-center p-3 bg-[#f0fdfa] rounded-xl">
                    <p className="text-[24px] font-semibold text-[#0891b2]">8</p>
                    <p className="text-[12px] text-[#8e8e93]">Completed</p>
                  </div>
                  <div className="text-center p-3 bg-[#f0fdfa] rounded-xl">
                    <p className="text-[24px] font-semibold text-[#0891b2]">5</p>
                    <p className="text-[12px] text-[#8e8e93]">In Progress</p>
                  </div>
                  <div className="text-center p-3 bg-[#f0fdfa] rounded-xl">
                    <p className="text-[24px] font-semibold text-[#0891b2]">12</p>
                    <p className="text-[12px] text-[#8e8e93]">Meetings</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* 2. Accomplishments */}
          <div className="bg-white rounded-2xl p-5 border border-border shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-3">
              Accomplishments
            </h3>
            <div className="space-y-2.5">
              <div className="flex items-start gap-3">
                <div className="w-5 h-5 rounded-full bg-[#0891b2]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <div className="w-2 h-2 rounded-full bg-[#0891b2]" />
                </div>
                <div className="flex-1">
                  <p className="text-[15px] text-[#1c1c1e] font-medium">API Migration Completed</p>
                  <p className="text-[14px] text-[#8e8e93] mt-0.5">Successfully migrated 3 core endpoints to new architecture</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-5 h-5 rounded-full bg-[#0891b2]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <div className="w-2 h-2 rounded-full bg-[#0891b2]" />
                </div>
                <div className="flex-1">
                  <p className="text-[15px] text-[#1c1c1e] font-medium">Design System Updates</p>
                  <p className="text-[14px] text-[#8e8e93] mt-0.5">Shipped 12 new components with documentation</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <div className="w-5 h-5 rounded-full bg-[#0891b2]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <div className="w-2 h-2 rounded-full bg-[#0891b2]" />
                </div>
                <div className="flex-1">
                  <p className="text-[15px] text-[#1c1c1e] font-medium">Client Onboarding</p>
                  <p className="text-[14px] text-[#8e8e93] mt-0.5">Completed onboarding for 2 new enterprise clients</p>
                </div>
              </div>
            </div>
          </div>

          {/* 3. Challenges & Learnings */}
          <div className="bg-white rounded-2xl p-5 border border-border shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-3">
              Challenges & Learnings
            </h3>
            <div className="space-y-3">
              <div className="p-3 bg-[#fef3c7]/30 rounded-xl border border-[#fbbf24]/20">
                <p className="text-[14px] text-[#1c1c1e] font-medium mb-1">Resource Constraints</p>
                <p className="text-[13px] text-[#6c6c70] leading-[1.5]">
                  Team bandwidth became a bottleneck mid-week. Consider redistributing workload or postponing non-critical items.
                </p>
              </div>
              <div className="p-3 bg-[#dbeafe] rounded-xl border border-[#3b82f6]/20">
                <p className="text-[14px] text-[#1c1c1e] font-medium mb-1">Communication Win</p>
                <p className="text-[13px] text-[#6c6c70] leading-[1.5]">
                  Daily stand-ups proved highly effective this week. Team alignment improved significantly.
                </p>
              </div>
            </div>
          </div>

          {/* 4. Pending Items */}
          <div className="bg-white rounded-2xl p-5 border border-border shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-3">
              Pending Items
            </h3>
            <div className="space-y-2.5">
              {pendingItemsToDisplay && pendingItemsToDisplay.length > 0 ? (
                pendingItemsToDisplay.map((todo) => (
                  <button
                    key={todo.id}
                    onClick={() => {
                      setSelectedTodo(todo);
                      setShowTodoModal(true);
                    }}
                    className="w-full flex items-center gap-3 p-3 bg-[#f9f9f9] rounded-xl hover:bg-[#f0f0f0] transition-colors text-left"
                  >
                    {todo.completed ? (
                      <Star className="w-4 h-4 text-[#ff9500] fill-[#ff9500]" strokeWidth={2} />
                    ) : (
                      <Star className="w-4 h-4 text-[#ff9500]" strokeWidth={2} />
                    )}
                    <p className={`text-[14px] flex-1 ${
                      todo.completed 
                        ? 'text-[#8e8e93] line-through' 
                        : 'text-[#3c3c43]'
                    }`}>
                      {todo.title}
                    </p>
                  </button>
                ))
              ) : (
                <p className="text-[14px] text-[#8e8e93] text-center py-4">
                  No pending items
                </p>
              )}
            </div>
          </div>

          {/* 5. Next Week Priorities */}
          <div className="bg-white rounded-2xl p-5 border border-border shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-3">
              Next Week Priorities
            </h3>
            <div className="space-y-4">
              {nextWeekPriorities.map((priority, index) => (
                <div key={index} className="flex items-start justify-between gap-3 pb-4 border-b border-black/[0.06] last:border-0 last:pb-0">
                  <div className="flex items-start gap-3 flex-1">
                    <div className="w-6 h-6 rounded-lg bg-[#0891b2] text-white flex items-center justify-center flex-shrink-0 text-[13px] font-semibold">
                      {index + 1}
                    </div>
                    <div className="flex-1">
                      <p className="text-[15px] text-[#1c1c1e] font-medium">{priority.title}</p>
                      <p className="text-[14px] text-[#8e8e93] mt-0.5">{priority.subtitle}</p>
                    </div>
                  </div>
                  {addedTodoItems.has(index) ? (
                    <button 
                      disabled
                      className="px-3 py-1.5 text-[13px] text-[#34c759] bg-green-50 rounded-lg whitespace-nowrap font-medium flex items-center gap-1.5 cursor-default"
                    >
                      <Check className="w-3.5 h-3.5" strokeWidth={2.5} />
                      Added
                    </button>
                  ) : (
                    <button 
                      onClick={() => {
                        setSelectedTodoItem(priority.title);
                        setSelectedTodoSubtitle(priority.subtitle);
                        setShowAddTodoModal(true);
                      }}
                      className="px-3 py-1.5 text-[13px] text-[#007aff] bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors whitespace-nowrap font-medium"
                    >
                      Add to Todo
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Expert Weekly Feedback */}
          <div className="bg-white rounded-2xl p-5 border border-border shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-3">Expert Weekly Feedback</h3>
            <div className="w-full h-px bg-black/[0.06] mb-4" />
            
            <div className="space-y-4">
              {/* Business Expert */}
              <div
                onClick={() => handleExpertClick(expertFeedback.find(e => e.id === 'business')!)}
                className="cursor-pointer p-3 rounded-xl hover:bg-[#f9f9f9] transition-colors -mx-3"
              >
                <div className="flex items-center gap-2 mb-1.5">
                  <Briefcase className="w-4 h-4 text-[#007aff]" strokeWidth={2} />
                  <h4 className="text-[15px] font-semibold text-[#1c1c1e]">Business Expert</h4>
                </div>
                <p className="text-[14px] text-[#3c3c43] leading-[1.5]">
                  Pricing direction remains unclear across multiple conversations. Aligning ownership and decision checkpoints could prevent strategic drift next month.
                </p>
              </div>

              {/* Creative Expert */}
              <div
                onClick={() => handleExpertClick(expertFeedback.find(e => e.id === 'creative')!)}
                className="cursor-pointer p-3 rounded-xl hover:bg-[#f9f9f9] transition-colors -mx-3"
              >
                <div className="flex items-center gap-2 mb-1.5">
                  <Palette className="w-4 h-4 text-[#af52de]" strokeWidth={2} />
                  <h4 className="text-[15px] font-semibold text-[#1c1c1e]">Creative Expert</h4>
                </div>
                <p className="text-[14px] text-[#3c3c43] leading-[1.5]">
                  Recurring discussions suggest onboarding simplification and user education may offer untapped differentiation opportunities. Exploration here could unlock growth.
                </p>
              </div>

              {/* Execution Expert */}
              <div
                onClick={() => handleExpertClick(expertFeedback.find(e => e.id === 'execution')!)}
                className="cursor-pointer p-3 rounded-xl hover:bg-[#f9f9f9] transition-colors -mx-3"
              >
                <div className="flex items-center gap-2 mb-1.5">
                  <Wrench className="w-4 h-4 text-[#ff9500]" strokeWidth={2} />
                  <h4 className="text-[15px] font-semibold text-[#1c1c1e]">Execution Expert</h4>
                </div>
                <p className="text-[14px] text-[#3c3c43] leading-[1.5]">
                  Delivery risk persists due to infrastructure dependencies and cross-team coordination. Earlier escalation of blockers may help avoid timeline slippage.
                </p>
              </div>

              {/* Wellness Expert */}
              <div
                onClick={() => handleExpertClick(expertFeedback.find(e => e.id === 'wellness')!)}
                className="cursor-pointer p-3 rounded-xl hover:bg-[#f9f9f9] transition-colors -mx-3"
              >
                <div className="flex items-center gap-2 mb-1.5">
                  <Heart className="w-4 h-4 text-[#34c759]" strokeWidth={2} />
                  <h4 className="text-[15px] font-semibold text-[#1c1c1e]">Wellness Expert</h4>
                </div>
                <p className="text-[14px] text-[#3c3c43] leading-[1.5]">
                  Energy dipped mid-week as workload peaked. Protecting recovery windows and avoiding stacked deadlines could sustain performance.
                </p>
              </div>
            </div>
          </div>

          {/* Ask AI about this week */}
          <div>
            <div className="h-px bg-gradient-to-r from-transparent via-black/[0.08] to-transparent my-5" />
            <button
              onClick={() => {
                setSelectedExpert('Weekly Insights AI');
                setShowAIChatModal(true);
              }}
              className="w-full flex items-center justify-center gap-2.5 px-4 py-3 bg-gradient-to-r from-[#af52de] to-[#9d3dcc] text-white rounded-xl hover:from-[#9d3dcc] hover:to-[#8b2fb8] transition-all shadow-sm hover:shadow-md"
            >
              <Sparkles className="w-[18px] h-[18px]" strokeWidth={2} />
              <span className="text-[15px] font-semibold">Ask AI about this week</span>
            </button>
          </div>
        </div>
      </div>

      {/* Share Options Modal */}
      <ShareOptionsModal
        isOpen={showShareOptionsModal}
        onClose={() => setShowShareOptionsModal(false)}
        onShare={async () => {
          const shareUrl = `https://app.example.com/weekly-insight/${insight.id}`;
          const shareText = `Weekly Insights - Jan 19-25\n\n${shareUrl}`;

          try {
            if (navigator.share && navigator.canShare) {
              const shareData = {
                title: 'Weekly Insights',
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
              alert(`Share link:\n\n${shareUrl}`);
            }
          }
        }}
        onCopyLink={async () => {
          const shareUrl = `https://app.example.com/weekly-insight/${insight.id}`;
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
          alert('Export as Markdown - Coming soon!');
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
          if (confirm('Are you sure you want to delete this weekly insight?')) {
            alert('Weekly insight deleted!');
            onClose();
          }
        }}
        showEditTitle={false}
        showModifyDate={false}
      />

      {/* AI Chat Modal */}
      {showAIChatModal && (
        <AIChatModal
          isOpen={showAIChatModal}
          onClose={() => setShowAIChatModal(false)}
          initialMessages={chatMessages}
          onSaveMessages={(messages) => {
            setChatMessages(messages);
            // Save to appropriate storage key based on whether it's expert chat or general "Ask AI about this week"
            if (selectedExpert === 'Weekly Insights AI') {
              localStorage.setItem(`weekly-insight-chat-${insight.id || 'current'}`, JSON.stringify(messages));
            } else {
              const expertId = expertFeedback.find(e => e.name === selectedExpert)?.id;
              if (expertId) {
                localStorage.setItem(`weekly-expert-chat-${insight.id || 'current'}-${expertId}`, JSON.stringify(messages));
              }
            }
          }}
          memoryTitle={selectedExpert === 'Weekly Insights AI' ? 'Weekly Insights' : `${selectedExpert} - Weekly Insight`}
          suggestedQuestions={
            selectedExpert === 'Weekly Insights AI'
              ? [
                  'What slowed progress this week?',
                  'What should I fix first next week?',
                  'Which tasks repeated unnecessarily?'
                ]
              : undefined
          }
        />
      )}

      {/* Todo Detail Modal */}
      {showTodoModal && selectedTodo && (
        <TodoDetailModal
          todo={selectedTodo}
          onClose={() => {
            setShowTodoModal(false);
            setSelectedTodo(null);
          }}
          onMarkDone={onMarkDone}
          onNotNow={onNotNow}
          onDelete={onDelete}
          onUpdate={onUpdateTodo}
        />
      )}

      {/* New Todo from Memo Modal */}
      {showAddTodoModal && (
        <NewTodoFromMemoModal
          suggestion={selectedTodoItem}
          insightContent={selectedTodoSubtitle}
          memory={{
            id: `weekly-insight-${insight.id || 'current'}`,
            title: `Weekly Insights · Jan 19-25`,
            date: 'Jan 19 – Jan 25',
            duration: undefined,
            hasSummary: false
          }}
          onClose={() => {
            setShowAddTodoModal(false);
            setSelectedTodoItem('');
            setSelectedTodoSubtitle('');
          }}
          onCreateTodo={(newTodo) => {
            // Find the index of the selected item
            const index = nextWeekPriorities.findIndex(p => p.title === selectedTodoItem);
            if (index !== -1) {
              const newSet = new Set(addedTodoItems).add(index);
              setAddedTodoItems(newSet);
              // Save to localStorage
              localStorage.setItem(`weekly-insight-added-todos-${insight.id || 'current'}`, JSON.stringify(Array.from(newSet)));
            }
            
            if (onAddTodo) {
              onAddTodo({
                id: Date.now(),
                title: newTodo.title,
                priority: newTodo.priority,
                dueDate: newTodo.dueDate,
                notes: newTodo.notes || [],
                completed: false,
                category: 'Today',
                linkedMemory: {
                  id: `weekly-insight-${insight.id || 'current'}`,
                  title: `Weekly Insights · Jan 19-25`,
                  date: 'Jan 19 – Jan 25'
                }
              });
            }
            
            setShowAddTodoModal(false);
            setSelectedTodoItem('');
            setSelectedTodoSubtitle('');
          }}
        />
      )}
    </div>
  );
}