import { ChevronLeft, Share2, Copy, Download, Compass, BarChart3, Users, Brain, AlertTriangle, TrendingUp, AlertCircle, Target, MoreVertical, Sparkles, Check } from 'lucide-react';
import { useState } from 'react';
import { ShareOptionsModal } from './ShareOptionsModal';
import { MemoryOptionsModal } from './MemoryOptionsModal';
import { AIChatModal } from './AIChatModal';
import { NewTodoFromMemoModal } from './NewTodoFromMemoModal';
import { PersonDetail } from './PersonDetail';

interface MonthlyInsightDetailProps {
  insight: any;
  onClose: () => void;
  onAddTodo?: (todo: any) => void;
}

export function MonthlyInsightDetail({ insight, onClose, onAddTodo }: MonthlyInsightDetailProps) {
  const [showShareOptionsModal, setShowShareOptionsModal] = useState(false);
  const [showMemoryOptionsModal, setShowMemoryOptionsModal] = useState(false);
  const [showAIChatModal, setShowAIChatModal] = useState(false);
  const [selectedPerson, setSelectedPerson] = useState<string | null>(null);
  const [addedTodoItems, setAddedTodoItems] = useState<Set<number>>(() => {
    // Load from localStorage based on insight id
    const stored = localStorage.getItem(`monthly-insight-added-todos-${insight.id || 'current'}`);
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
  
  // Load chat messages from localStorage for this specific monthly insight
  const [chatMessages, setChatMessages] = useState<any[]>(() => {
    const stored = localStorage.getItem(`monthly-insight-chat-${insight.id || 'current'}`);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch (e) {
        return [];
      }
    }
    return [];
  });

  // Next Month Priorities data
  const nextMonthPriorities = [
    'Close ownership decisions early',
    'Reduce hiring bottlenecks',
    'Align pricing before launch prep'
  ];

  return (
    <div className="relative flex flex-col h-full bg-white">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06] relative">
        <button
          onClick={onClose}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-6 h-6" strokeWidth={2} />
        </button>
        <div className="absolute left-1/2 transform -translate-x-1/2 text-center">
          <h1 className="text-[17px] font-semibold text-[#1c1c1e]">Monthly Insight</h1>
          <p className="text-[13px] text-[#8e8e93]">January 2026</p>
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
          {/* Month Overview */}
          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <Compass className="w-5 h-5 text-[#d97706]" strokeWidth={2} />
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Month Overview</h3>
            </div>
            <div className="mb-3 pb-3 border-b border-black/[0.06]" />
            <div className="space-y-3">
              <p className="text-[15px] text-[#3c3c43] leading-[1.5]">
                Execution momentum improved compared to December, but several strategic decisions continued to stall progress.
              </p>
              <p className="text-[15px] text-[#3c3c43] leading-[1.5]">
                Hiring capacity, API ownership, and pricing direction resurfaced throughout the month.
              </p>
            </div>
          </div>

          {/* Attention Distribution */}
          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <BarChart3 className="w-5 h-5 text-[#0891b2]" strokeWidth={2} />
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Attention Distribution</h3>
            </div>
            <div className="mb-3 pb-3 border-b border-black/[0.06]" />
            <div className="space-y-3">
              <div className="space-y-2.5">
                <div className="flex items-center gap-3">
                  <span className="text-[14px] text-[#3c3c43] w-28 flex-shrink-0">Product</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#0891b2] to-[#06b6d4] rounded-full" style={{ width: '70%' }} />
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-[14px] text-[#3c3c43] w-28 flex-shrink-0">Engineering</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#0891b2] to-[#06b6d4] rounded-full" style={{ width: '50%' }} />
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-[14px] text-[#3c3c43] w-28 flex-shrink-0">Hiring</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#0891b2] to-[#06b6d4] rounded-full" style={{ width: '20%' }} />
                  </div>
                </div>
              </div>
              <p className="text-[14px] text-[#6c6c70] leading-[1.5] pt-2">
                Most effort went into execution, while hiring constraints continued to slow delivery.
              </p>
            </div>
          </div>

          {/* Key People This Month */}
          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <Users className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Key People This Month</h3>
            </div>
            <div className="mb-3 pb-3 border-b border-black/[0.06]" />
            <div className="space-y-3">
              <div className="space-y-2.5">
                <button
                  onClick={() => setSelectedPerson('Jordan')}
                  className="w-full flex items-center gap-3 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] -mx-2 px-2 py-1.5 rounded-lg transition-colors"
                >
                  <span className="text-[14px] text-[#3c3c43] w-20 flex-shrink-0">Jordan</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#007aff] to-[#0051d5] rounded-full" style={{ width: '90%' }} />
                  </div>
                  <span className="text-[13px] text-[#8e8e93] w-24 text-right flex-shrink-0">12 memories</span>
                </button>
                <button
                  onClick={() => setSelectedPerson('Alex')}
                  className="w-full flex items-center gap-3 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] -mx-2 px-2 py-1.5 rounded-lg transition-colors"
                >
                  <span className="text-[14px] text-[#3c3c43] w-20 flex-shrink-0">Alex</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#007aff] to-[#0051d5] rounded-full" style={{ width: '75%' }} />
                  </div>
                  <span className="text-[13px] text-[#8e8e93] w-24 text-right flex-shrink-0">10 memories</span>
                </button>
                <button
                  onClick={() => setSelectedPerson('Sarah')}
                  className="w-full flex items-center gap-3 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] -mx-2 px-2 py-1.5 rounded-lg transition-colors"
                >
                  <span className="text-[14px] text-[#3c3c43] w-20 flex-shrink-0">Sarah</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#007aff] to-[#0051d5] rounded-full" style={{ width: '60%' }} />
                  </div>
                  <span className="text-[13px] text-[#8e8e93] w-24 text-right flex-shrink-0">8 memories</span>
                </button>
              </div>
              <p className="text-[14px] text-[#6c6c70] leading-[1.5] pt-2">
                Conversations repeatedly involved delivery ownership and coordination.
              </p>
            </div>
          </div>

          {/* Topics Resurfacing */}
          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <Brain className="w-5 h-5 text-[#af52de]" strokeWidth={2} />
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Topics Resurfacing</h3>
            </div>
            <div className="mb-3 pb-3 border-b border-black/[0.06]" />
            <div className="space-y-3">
              <div className="space-y-2.5">
                <div className="flex items-center gap-3">
                  <span className="text-[14px] text-[#3c3c43] flex-1">API migration</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#af52de] to-[#9b3fce] rounded-full" style={{ width: '60%' }} />
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-[14px] text-[#3c3c43] flex-1">Hiring bandwidth</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#af52de] to-[#9b3fce] rounded-full" style={{ width: '40%' }} />
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-[14px] text-[#3c3c43] flex-1">Pricing strategy</span>
                  <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                    <div className="h-full bg-gradient-to-r from-[#af52de] to-[#9b3fce] rounded-full" style={{ width: '30%' }} />
                  </div>
                </div>
              </div>
              <p className="text-[14px] text-[#6c6c70] leading-[1.5] pt-2">
                These topics appeared across multiple weeks without clear resolution.
              </p>
            </div>
          </div>

          {/* Long-running Open Threads */}
          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <AlertTriangle className="w-5 h-5 text-[#ff9500]" strokeWidth={2} />
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Long-running Open Threads</h3>
            </div>
            <div className="mb-3 pb-3 border-b border-black/[0.06]" />
            <div className="space-y-3">
              <div className="space-y-2">
                <div className="flex items-start gap-2">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#ff9500] mt-2 flex-shrink-0" />
                  <span className="text-[15px] text-[#3c3c43] leading-[1.5]">Hiring plan unresolved for 6 weeks</span>
                </div>
                <div className="flex items-start gap-2">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#ff9500] mt-2 flex-shrink-0" />
                  <span className="text-[15px] text-[#3c3c43] leading-[1.5]">Pricing model undecided since December</span>
                </div>
                <div className="flex items-start gap-2">
                  <div className="w-1.5 h-1.5 rounded-full bg-[#ff9500] mt-2 flex-shrink-0" />
                  <span className="text-[15px] text-[#3c3c43] leading-[1.5]">API ownership still debated</span>
                </div>
              </div>
              <p className="text-[14px] text-[#6c6c70] leading-[1.5] pt-2">
                These issues repeatedly delayed progress.
              </p>
            </div>
          </div>

          {/* Month-to-Month Trend */}
          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <TrendingUp className="w-5 h-5 text-[#34c759]" strokeWidth={2} />
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Month-to-Month Trend</h3>
            </div>
            <div className="mb-3 pb-3 border-b border-black/[0.06]" />
            <div className="space-y-2">
              <p className="text-[15px] text-[#3c3c43] leading-[1.5]">Execution speed improved.</p>
              <p className="text-[15px] text-[#3c3c43] leading-[1.5]">Team coordination strengthened.</p>
              <p className="text-[15px] text-[#3c3c43] leading-[1.5]">Decision delays persist across teams.</p>
            </div>
          </div>

          {/* Decisions That Cannot Slip Again */}
          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <AlertCircle className="w-5 h-5 text-[#ff3b30]" strokeWidth={2} />
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Decisions That Cannot Slip Again</h3>
            </div>
            <div className="mb-3 pb-3 border-b border-black/[0.06]" />
            <div className="space-y-3">
              <p className="text-[14px] text-[#6c6c70] leading-[1.5]">
                If unresolved next month, these will continue to slow execution:
              </p>
              <div className="space-y-2.5">
                <div className="flex items-start gap-3">
                  <div className="w-6 h-6 rounded-lg bg-[#ff3b30] text-white flex items-center justify-center flex-shrink-0 text-[13px] font-semibold">
                    1
                  </div>
                  <span className="text-[15px] text-[#3c3c43] leading-[1.5] flex-1">Finalize API ownership</span>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-6 h-6 rounded-lg bg-[#ff3b30] text-white flex items-center justify-center flex-shrink-0 text-[13px] font-semibold">
                    2
                  </div>
                  <span className="text-[15px] text-[#3c3c43] leading-[1.5] flex-1">Stabilize hiring capacity</span>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-6 h-6 rounded-lg bg-[#ff3b30] text-white flex items-center justify-center flex-shrink-0 text-[13px] font-semibold">
                    3
                  </div>
                  <span className="text-[15px] text-[#3c3c43] leading-[1.5] flex-1">Lock pricing direction</span>
                </div>
              </div>
            </div>
          </div>

          {/* Suggested Focus Next Month */}
          <div className="bg-white rounded-2xl p-5 border border-black/[0.06] shadow-sm">
            <div className="flex items-center gap-2 mb-3">
              <Target className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Suggested Focus Next Month</h3>
            </div>
            <div className="mb-3 pb-3 border-b border-black/[0.06]" />
            <div className="space-y-4">
              {nextMonthPriorities.map((priority, index) => (
                <div key={index} className="flex items-start justify-between gap-3 pb-4 border-b border-black/[0.06] last:border-0 last:pb-0">
                  <div className="flex items-start gap-3 flex-1">
                    <div className="w-6 h-6 rounded-lg bg-[#007aff] text-white flex items-center justify-center flex-shrink-0 text-[13px] font-semibold">
                      {index + 1}
                    </div>
                    <span className="text-[15px] text-[#3c3c43] leading-[1.5] flex-1">{priority}</span>
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
                        setSelectedTodoItem(priority);
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

          {/* Ask AI about this month */}
          <div>
            <div className="h-px bg-gradient-to-r from-transparent via-black/[0.08] to-transparent my-5" />
            <button
              onClick={() => setShowAIChatModal(true)}
              className="w-full flex items-center justify-center gap-2.5 px-4 py-3 bg-gradient-to-r from-[#af52de] to-[#9d3dcc] text-white rounded-xl hover:from-[#9d3dcc] hover:to-[#8b2fb8] transition-all shadow-sm hover:shadow-md"
            >
              <Sparkles className="w-[18px] h-[18px]" strokeWidth={2} />
              <span className="text-[15px] font-semibold">Ask AI about this month</span>
            </button>
          </div>
        </div>
      </div>

      {/* Share Options Modal */}
      <ShareOptionsModal
        isOpen={showShareOptionsModal}
        onClose={() => setShowShareOptionsModal(false)}
        onShare={async () => {
          const shareUrl = `https://app.example.com/monthly-insight/${insight.id}`;
          const shareText = `Monthly Insight - January 2026\n\n${shareUrl}`;

          try {
            if (navigator.share && navigator.canShare) {
              const shareData = {
                title: 'Monthly Insight',
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
          const shareUrl = `https://app.example.com/monthly-insight/${insight.id}`;
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
          if (confirm('Are you sure you want to delete this monthly insight?')) {
            alert('Monthly insight deleted!');
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
            localStorage.setItem(`monthly-insight-chat-${insight.id || 'current'}`, JSON.stringify(messages));
          }}
          memoryTitle="Monthly Insights"
          suggestedQuestions={[
            'What patterns hurt progress?',
            'What must change next month?',
            'Where did time get wasted?'
          ]}
        />
      )}

      {/* Add Todo Modal */}
      {showAddTodoModal && (
        <NewTodoFromMemoModal
          suggestion={selectedTodoItem}
          insightContent={''}
          memory={{
            id: `monthly-insight-${insight.id || 'current'}`,
            title: `Monthly Insight · January 2026`,
            date: 'January 2026',
            duration: undefined,
            hasSummary: false
          }}
          onClose={() => {
            setShowAddTodoModal(false);
            setSelectedTodoItem('');
          }}
          onCreateTodo={(newTodo) => {
            // Find the index of the selected item
            const index = nextMonthPriorities.findIndex(p => p === selectedTodoItem);
            if (index !== -1) {
              const newSet = new Set(addedTodoItems).add(index);
              setAddedTodoItems(newSet);
              // Save to localStorage
              localStorage.setItem(`monthly-insight-added-todos-${insight.id || 'current'}`, JSON.stringify(Array.from(newSet)));
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
                  id: `monthly-insight-${insight.id || 'current'}`,
                  title: `Monthly Insight · January 2026`,
                  date: 'January 2026'
                }
              });
            }
            
            setShowAddTodoModal(false);
            setSelectedTodoItem('');
          }}
        />
      )}

      {/* PersonDetail Modal */}
      {selectedPerson && (
        <PersonDetail
          personName={selectedPerson}
          onBack={() => setSelectedPerson(null)}
        />
      )}
    </div>
  );
}