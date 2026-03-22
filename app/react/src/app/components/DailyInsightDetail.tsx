import { ChevronLeft, Compass, CheckSquare, AlertCircle, RotateCcw, Lightbulb, Plus, Sparkles, Share2, MoreVertical, Check } from 'lucide-react';
import { useState } from 'react';
import { ShareOptionsModal } from './ShareOptionsModal';
import { MemoryOptionsModal } from './MemoryOptionsModal';
import { AIChatModal } from './AIChatModal';
import { NewTodoFromMemoModal } from './NewTodoFromMemoModal';

interface DailyInsightDetailProps {
  insight: any;
  onClose: () => void;
  onAddTodo?: (todo: any) => void;
}

export function DailyInsightDetail({ insight, onClose, onAddTodo }: DailyInsightDetailProps) {
  const [showAddMemoModal, setShowAddMemoModal] = useState(false);
  const [showShareOptionsModal, setShowShareOptionsModal] = useState(false);
  const [showMemoryOptionsModal, setShowMemoryOptionsModal] = useState(false);
  const [addedTodoItems, setAddedTodoItems] = useState<Set<number>>(() => {
    // Load from localStorage based on insight date
    const stored = localStorage.getItem(`daily-insight-added-todos-${insight.date}`);
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
  const [memoText, setMemoText] = useState('');
  const [isRecordingMemo, setIsRecordingMemo] = useState(false);
  const [isTranscribingMemo, setIsTranscribingMemo] = useState(false);
  const [askAIText, setAskAIText] = useState('');
  const [isRecordingAskAI, setIsRecordingAskAI] = useState(false);
  const [isTranscribingAskAI, setIsTranscribingAskAI] = useState(false);
  const [showAIChatModal, setShowAIChatModal] = useState(false);
  
  // Load chat messages from localStorage for this specific insight
  const [chatMessages, setChatMessages] = useState<any[]>(() => {
    const stored = localStorage.getItem(`insight-chat-${insight.date}`);
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch (e) {
        return [];
      }
    }
    return [];
  });

  const decisions = [
    'Delay external rollout until recording is stable',
    'Prioritize audio reliability over new features',
    'Proceed with phased API migration to reduce risk'
  ];

  const openQuestions = [
    'Migration timeline still unclear under infra limits',
    'User segmentation strategy not aligned yet',
    'Who owns onboarding improvements is undefined'
  ];

  const ideas = [
    'Simplify onboarding steps for ADHD users',
    'Add a lightweight daily review loop',
    'Improve hardware status feedback clarity'
  ];

  const tomorrowItems = [
    'Review migration milestones',
    'Align infrastructure support priorities'
  ];

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] z-50 flex flex-col">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
        <button 
          onClick={onClose}
          className="text-[#7c3aed] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-7 h-7" strokeWidth={2} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          Daily Insight
        </h1>
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
      <div className="flex-1 overflow-y-auto pb-24">
        {/* Header info */}
        <div className="px-5 pt-5 pb-4">
          <h2 className="text-[20px] font-bold text-[#1c1c1e]">
            Daily Insight · {insight.date}
          </h2>
        </div>

        {/* Divider */}
        <div className="h-px bg-gradient-to-r from-transparent via-black/[0.08] to-transparent" />

        {/* Sections */}
        <div className="px-5 space-y-4 pt-5">
          {/* Today's narrative */}
          <section>
            <div className="flex items-center gap-2.5 mb-3">
              <div className="w-7 h-7 rounded-full bg-blue-500/10 flex items-center justify-center">
                <Compass className="w-4 h-4 text-blue-600" strokeWidth={2.5} />
              </div>
              <h3 className="text-[16px] font-semibold text-[#1c1c1e]">
                Today's narrative
              </h3>
            </div>
            <div className="bg-gradient-to-br from-blue-50/50 to-white rounded-2xl p-4 border border-blue-100/50 shadow-sm">
              <p className="text-[15px] text-[#3c3c43] leading-[1.6]">
                Today's conversations centered on API architecture and product positioning. Several threads returned to the same tension: shipping fast vs. stabilizing recording reliability. Concerns about scalability and team bandwidth kept resurfacing.
              </p>
            </div>
          </section>

          {/* Decisions made */}
          <section>
            <div className="flex items-center gap-2.5 mb-3">
              <div className="w-7 h-7 rounded-full bg-green-500/10 flex items-center justify-center">
                <CheckSquare className="w-4 h-4 text-green-600" strokeWidth={2.5} />
              </div>
              <h3 className="text-[16px] font-semibold text-[#1c1c1e]">
                Decisions made
              </h3>
            </div>
            <div className="bg-gradient-to-br from-green-50/50 to-white rounded-2xl p-4 border border-green-100/50 shadow-sm">
              <div className="space-y-3">
                {decisions.map((decision, index) => (
                  <div key={index} className="flex items-start gap-2.5">
                    <span className="text-green-600 mt-0.5 font-bold">•</span>
                    <p className="text-[15px] text-[#3c3c43] leading-[1.6] flex-1">
                      {decision}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </section>

          {/* Open questions */}
          <section>
            <div className="flex items-center gap-2.5 mb-3">
              <div className="w-7 h-7 rounded-full bg-orange-500/10 flex items-center justify-center">
                <AlertCircle className="w-4 h-4 text-orange-600" strokeWidth={2.5} />
              </div>
              <h3 className="text-[16px] font-semibold text-[#1c1c1e]">
                Open questions
              </h3>
            </div>
            <div className="bg-gradient-to-br from-orange-50/50 to-white rounded-2xl p-4 border border-orange-100/50 shadow-sm">
              <div className="space-y-3">
                {openQuestions.map((question, index) => (
                  <div key={index} className="flex items-start gap-2.5">
                    <span className="text-orange-600 mt-0.5 font-bold">•</span>
                    <p className="text-[15px] text-[#3c3c43] leading-[1.6] flex-1">
                      {question}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </section>

          {/* Patterns emerging */}
          <section>
            <div className="flex items-center gap-2.5 mb-3">
              <div className="w-7 h-7 rounded-full bg-purple-500/10 flex items-center justify-center">
                <RotateCcw className="w-4 h-4 text-purple-600" strokeWidth={2.5} />
              </div>
              <h3 className="text-[16px] font-semibold text-[#1c1c1e]">
                Patterns emerging
              </h3>
            </div>
            <div className="bg-gradient-to-br from-purple-50/50 to-white rounded-2xl p-4 border border-purple-100/50 shadow-sm">
              <p className="text-[15px] text-[#3c3c43] leading-[1.6]">
                Architecture concerns have surfaced repeatedly for several days, suggesting systemic friction rather than isolated implementation issues.
              </p>
            </div>
          </section>

          {/* Ideas captured */}
          <section>
            <div className="flex items-center gap-2.5 mb-3">
              <div className="w-7 h-7 rounded-full bg-amber-500/10 flex items-center justify-center">
                <Lightbulb className="w-4 h-4 text-amber-600" strokeWidth={2.5} />
              </div>
              <h3 className="text-[16px] font-semibold text-[#1c1c1e]">
                Ideas captured
              </h3>
            </div>
            <div className="bg-gradient-to-br from-amber-50/50 to-white rounded-2xl p-4 border border-amber-100/50 shadow-sm">
              <div className="space-y-3">
                {ideas.map((idea, index) => (
                  <div key={index} className="flex items-start gap-2.5">
                    <span className="text-amber-600 mt-0.5 font-bold">•</span>
                    <p className="text-[15px] text-[#3c3c43] leading-[1.6] flex-1">
                      {idea}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </section>

          {/* Tomorrow's focus */}
          <section>
            <div className="h-px bg-gradient-to-r from-transparent via-black/[0.08] to-transparent my-5" />
            <h3 className="text-[16px] font-semibold text-[#1c1c1e] mb-3">
              Tomorrow's focus
            </h3>
            <div className="bg-white rounded-2xl p-4 border border-black/[0.06] shadow-sm">
              <div className="space-y-4">
                {tomorrowItems.map((item, index) => (
                  <div key={index} className="flex items-start justify-between gap-3 pb-4 border-b border-black/[0.06] last:border-0 last:pb-0">
                    <p className="text-[15px] text-[#3c3c43] leading-[1.6] flex-1">
                      • {item}
                    </p>
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
                          setSelectedTodoItem(item);
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
          </section>

          {/* Ask AI about today */}
          <section>
            <div className="h-px bg-gradient-to-r from-transparent via-black/[0.08] to-transparent my-5" />
            <button
              onClick={() => setShowAIChatModal(true)}
              className="w-full flex items-center justify-center gap-2.5 px-4 py-3 bg-gradient-to-r from-[#7c3aed] to-[#6929cc] text-white rounded-xl hover:from-[#6929cc] hover:to-[#5a1fb3] transition-all shadow-sm hover:shadow-md"
            >
              <Sparkles className="w-[18px] h-[18px]" strokeWidth={2} />
              <span className="text-[15px] font-semibold">Ask AI about today</span>
            </button>
          </section>
        </div>
      </div>

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
                  className="w-full h-32 px-3.5 py-2.5 text-[15px] bg-[#f2f2f7] rounded-xl border border-black/[0.06] focus:outline-none focus:ring-2 focus:ring-[#7c3aed]/30 resize-none"
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
                    className="flex-1 bg-[#7c3aed] text-white py-3 rounded-xl hover:bg-[#7c3aed]/90 transition-colors text-[15px] font-semibold disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    Save Memo
                  </button>
                </div>
              </>
            ) : isRecordingMemo ? (
              <>
                <div className="flex items-center justify-center gap-1.5 px-4 py-12 bg-[#ff3b30]/10 rounded-xl">
                  {[...Array(20)].map((_, i) => (
                    <div
                      key={i}
                      className="w-1.5 bg-[#7c3aed] rounded-full animate-pulse"
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
                    className="flex-1 bg-[#7c3aed] text-white py-3 rounded-xl hover:bg-[#7c3aed]/90 transition-colors text-[15px] font-semibold"
                  >
                    Done
                  </button>
                </div>
              </>
            ) : (
              <>
                <div className="flex items-center justify-center gap-2.5 px-4 py-12 bg-[#f2f2f7] rounded-xl">
                  <div className="flex items-center gap-1">
                    <div className="w-2 h-2 rounded-full bg-[#7c3aed] animate-bounce" style={{ animationDelay: '0ms' }}></div>
                    <div className="w-2 h-2 rounded-full bg-[#7c3aed] animate-bounce" style={{ animationDelay: '150ms' }}></div>
                    <div className="w-2 h-2 rounded-full bg-[#7c3aed] animate-bounce" style={{ animationDelay: '300ms' }}></div>
                  </div>
                  <span className="text-[15px] text-[#8e8e93] font-medium">Transcribing...</span>
                </div>
              </>
            )}
          </div>
        </div>
      )}

      {/* Share Options Modal */}
      <ShareOptionsModal
        isOpen={showShareOptionsModal}
        onClose={() => setShowShareOptionsModal(false)}
        onShare={async () => {
          const shareUrl = `https://app.example.com/insight/${insight.id}`;
          const shareText = `Daily Insight - ${insight.date}\n\n${insight.summary}\n\n${shareUrl}`;

          try {
            if (navigator.share && navigator.canShare) {
              const shareData = {
                title: 'Daily Insight',
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
          const shareUrl = `https://app.example.com/insight/${insight.id}`;
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
          const markdownContent = `# Daily Insight - ${insight.date}\n\n${insight.summary}`;
          
          try {
            const blob = new Blob([markdownContent], { type: 'text/markdown' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `daily_insight_${insight.date.replace(/[^a-z0-9]/gi, '_')}.md`;
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
          if (confirm('Are you sure you want to delete this insight?')) {
            alert('Insight deleted!');
            onClose();
          }
        }}
        showEditTitle={false}
        showModifyDate={false}
      />

      {/* Add Todo Modal */}
      {showAddTodoModal && (
        <NewTodoFromMemoModal
          suggestion={selectedTodoItem}
          insightContent={''}
          memory={{
            id: `insight-${insight.date}`,
            title: `Daily Insight · ${insight.date}`,
            date: insight.date,
            duration: undefined,
            hasSummary: false
          }}
          onClose={() => {
            setShowAddTodoModal(false);
            setSelectedTodoItem('');
          }}
          onCreateTodo={(newTodo) => {
            // Find the index of the selected item
            const index = tomorrowItems.indexOf(selectedTodoItem);
            if (index !== -1) {
              const newSet = new Set(addedTodoItems).add(index);
              setAddedTodoItems(newSet);
              // Save to localStorage
              localStorage.setItem(`daily-insight-added-todos-${insight.date}`, JSON.stringify(Array.from(newSet)));
            }
            
            if (onAddTodo) {
              onAddTodo({
                id: Date.now(),
                title: newTodo.title,
                priority: newTodo.priority,
                dueDate: newTodo.dueDate,
                notes: newTodo.notes || [],
                completed: false,
                linkedMemory: {
                  id: `insight-${insight.date}`,
                  title: `Daily Insight · ${insight.date}`,
                  date: insight.date
                }
              });
            }
            
            setShowAddTodoModal(false);
            setSelectedTodoItem('');
          }}
        />
      )}

      {/* AI Chat Modal */}
      {showAIChatModal && (
        <AIChatModal
          isOpen={showAIChatModal}
          onClose={() => setShowAIChatModal(false)}
          initialMessages={chatMessages}
          onSaveMessages={(messages) => {
            setChatMessages(messages);
            localStorage.setItem(`daily-insight-chat-${insight.id || 'current'}`, JSON.stringify(messages));
          }}
          memoryTitle="Daily Insights"
          suggestedQuestions={[
            'What should I focus on tomorrow?',
            'What problems might slow me down next?',
            'What follow-ups matter most right now?'
          ]}
        />
      )}
    </div>
  );
}