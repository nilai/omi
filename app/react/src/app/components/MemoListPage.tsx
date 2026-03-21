import { ChevronLeft, Mic, ChevronDown, ChevronUp, Search, ArrowUp, X, Check, Trash2 } from 'lucide-react';
import { useState } from 'react';
import { MemoDetailModal } from './MemoDetailModal';

interface Memo {
  id: number;
  title: string;
  content: string;
  timestamp: Date;
  category: 'Today' | 'Earlier' | 'Long ago';
  relatedMemories?: string[];
  todoCreated?: boolean;
  type?: 'highlight' | 'manual' | 'voice';  // Type of memo
  linkedMemory?: {
    id: string;
    title: string;
    date: string;
    duration?: string;
    hasSummary?: boolean;
  };
}

interface MemoListPageProps {
  onBack: () => void;
  onMemoClick: (memo: Memo) => void;
  onCreateTodo?: (memoId: number) => void;
  onRelatedMemoryClick?: (memoryTitle: string) => void;
  onLinkMemory?: (memoId: number) => void;
  onMemoryClick?: (memoryId: string) => void;
  onHighlightClick?: (memoryId: number, timestamp: string) => void;
  memos?: Memo[];
  setMemos?: (memos: Memo[]) => void;
}

export function MemoListPage({ onBack, onMemoClick, onCreateTodo, onRelatedMemoryClick, onLinkMemory, onMemoryClick, onHighlightClick, memos: propMemos, setMemos: propSetMemos }: MemoListPageProps) {
  // Use memos from props if provided, otherwise use local state
  const [localMemos, setLocalMemos] = useState<Memo[]>([
    { id: 1, title: 'Idea: simplify onboarding for ADHD users', content: 'First-time users with ADHD might feel overwhelmed by too many options. A guided, step-by-step onboarding could help them understand the app without cognitive overload. Maybe use progressive disclosure and visual cues.', timestamp: new Date(), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 2, title: 'Need to rethink pricing for early adopters', content: 'Current pricing might be too high for early adopters who are taking a risk on a new product. Consider a special launch price or lifetime deal to build initial user base and get valuable feedback.', timestamp: new Date(), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 3, title: 'Consider adding dark mode for better focus', content: 'Many users with ADHD prefer dark mode to reduce visual distractions and eye strain during extended use. This could be a key accessibility feature that sets us apart.', timestamp: new Date(), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 4, title: 'Explore voice memo transcription feature', content: 'Speaking is often easier than writing for people with ADHD. Adding automatic transcription for voice memos could make capture much more frictionless. Worth researching available APIs.', timestamp: new Date(), category: 'Today', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 5, title: 'CES observations worth writing down', content: 'Attended several sessions on AI-powered productivity tools. Most focus on neurotypical users. Big opportunity to differentiate by designing specifically for neurodivergent needs from the ground up.', timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 6, title: 'Note about long-term memory vs memo distinction', content: 'Memories should be things that happened - conversations, events, experiences. Memos are thoughts, ideas, and reflections. Keeping this distinction clear helps users understand where to capture what.', timestamp: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 7, title: 'User feedback on notification timing', content: 'Beta testers mentioned that random notifications can be disruptive. Should explore gentle, predictable reminder schedules that respect focus time and align with natural breaks.', timestamp: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 8, title: 'Partnership opportunity with wellness app', content: 'Had conversation with founders of meditation app popular with ADHD community. Potential integration opportunity - they handle mindfulness, we handle productivity and memory.', timestamp: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), category: 'Earlier', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 9, title: 'Research findings on color psychology for neurodiverse users', content: 'Studies show that softer, muted colors reduce anxiety and help with focus for many neurodivergent individuals. Avoid high-contrast, saturated colors in main UI - reserve those for important actions only.', timestamp: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 10, title: 'Meeting notes from investor pitch practice', content: 'Focus on the problem first - people with ADHD struggle with traditional productivity tools. Then show how our approach is different. Use personal stories to make it relatable. Keep slides minimal.', timestamp: new Date(Date.now() - 35 * 24 * 60 * 60 * 1000), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 11, title: 'Product roadmap ideas for Q2', content: 'Priorities: 1) Voice memos with transcription, 2) Smart reminders based on context, 3) Integration with calendar apps, 4) Collaborative features for teams. Get user input before finalizing.', timestamp: new Date(Date.now() - 40 * 24 * 60 * 60 * 1000), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 12, title: 'User feedback compilation from beta testing', content: 'Most common requests: better search, tags/categories, ability to link related items, export options. Most loved features: simple capture flow, gentle visual design, non-judgmental tone.', timestamp: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 13, title: 'Brainstorming session: gamification features', content: 'Gamification can be motivating but also anxiety-inducing. If we add it, make it opt-in and focus on personal progress rather than competition. Celebrate small wins. Avoid shame or pressure.', timestamp: new Date(Date.now() - 50 * 24 * 60 * 60 * 1000), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 14, title: 'Notes on competitor analysis', content: 'Most productivity apps assume executive function works normally. They punish forgetting with overdue tasks and missed deadlines. Our advantage: designed for imperfect memory and variable attention.', timestamp: new Date(Date.now() - 55 * 24 * 60 * 60 * 1000), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 15, title: 'Design system update considerations', content: 'Current design system is good but could use more spacing options for better visual hierarchy. Also need standardized loading states and empty states. Keep accessibility as top priority.', timestamp: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
    { id: 16, title: 'Accessibility audit findings', content: 'Good: color contrast, keyboard navigation. Needs improvement: screen reader support for dynamic content, focus indicators on custom components, ARIA labels for icon buttons.', timestamp: new Date(Date.now() - 65 * 24 * 60 * 60 * 1000), category: 'Long ago', relatedMemories: [], todoCreated: false, type: 'voice' },
  ]);

  // Use prop memos if available, otherwise use local memos
  const memos = propMemos || localMemos;
  const updateMemos = propSetMemos || setLocalMemos;

  const [showRecordingInput, setShowRecordingInput] = useState(false);
  const [showVoiceInput, setShowVoiceInput] = useState(false);
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [memoInputText, setMemoInputText] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const [longAgoCollapsed, setLongAgoCollapsed] = useState(false);
  const [showClearConfirmation, setShowClearConfirmation] = useState(false);
  const [selectedMemosToDelete, setSelectedMemosToDelete] = useState<number[]>([]);

  const suggestions = ['ADHD', 'Product roadmap', 'User feedback', 'Design'];

  const clearLongAgoMemos = () => {
    // Open confirmation modal instead of directly deleting
    const longAgoMemoIds = memos.filter(m => m.category === 'Long ago').map(m => m.id);
    setSelectedMemosToDelete(longAgoMemoIds);
    setShowClearConfirmation(true);
  };

  const handleConfirmClear = () => {
    const updatedMemos = memos.filter(memo => !selectedMemosToDelete.includes(memo.id));
    updateMemos(updatedMemos);
    setShowClearConfirmation(false);
    setSelectedMemosToDelete([]);
  };

  const handleCancelClear = () => {
    setShowClearConfirmation(false);
    setSelectedMemosToDelete([]);
  };

  const toggleMemoSelection = (memoId: number) => {
    if (selectedMemosToDelete.includes(memoId)) {
      setSelectedMemosToDelete(selectedMemosToDelete.filter(id => id !== memoId));
    } else {
      setSelectedMemosToDelete([...selectedMemosToDelete, memoId]);
    }
  };

  const toggleSelectAll = () => {
    const longAgoMemoIds = memos.filter(m => m.category === 'Long ago').map(m => m.id);
    if (selectedMemosToDelete.length === longAgoMemoIds.length) {
      setSelectedMemosToDelete([]);
    } else {
      setSelectedMemosToDelete(longAgoMemoIds);
    }
  };

  const handleSaveMemo = () => {
    if (!memoInputText.trim()) return;
    
    // Extract title (first line or first ~50 chars)
    const lines = memoInputText.trim().split('\n');
    const title = lines[0].length > 60 ? lines[0].substring(0, 60) + '...' : lines[0];
    
    const newMemo: Memo = {
      id: memos.length + 1,
      title,
      content: memoInputText.trim(),
      timestamp: new Date(),
      category: 'Today',
      relatedMemories: [],
      todoCreated: false,
      type: 'voice'
    };
    
    updateMemos([newMemo, ...memos]);
    setMemoInputText('');
    setShowRecordingInput(false);
    
    // Directly close the input modal without showing preview
  };

  const handleCancelInput = () => {
    setMemoInputText('');
    setShowRecordingInput(false);
    setShowVoiceInput(false);
    setIsRecording(false);
    setIsTranscribing(false);
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
    
    // 模拟语音转写（实际应用中会调用真实的语音识别API）
    setTimeout(() => {
      const transcribedText = "I've been thinking about how to improve the user experience for people with ADHD. The key insight is that traditional productivity tools assume a level of executive function that many neurodivergent users don't consistently have. Instead of punishing users for forgetting or getting distracted, we should design systems that work with those patterns rather than against them.";
      setMemoInputText(transcribedText);
      setIsTranscribing(false);
    }, 2000);
  };

  const todayMemos = memos.filter(m => m.category === 'Today');
  const earlierMemos = memos.filter(m => m.category === 'Earlier');
  const longAgoMemos = memos.filter(m => m.category === 'Long ago');

  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {!showSearch ? (
        <>
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
        <button 
          onClick={onBack}
          className="flex items-center gap-2 text-[#007aff] text-[17px] font-medium hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
          <span>Ideas&Memos</span>
        </button>
        <button 
          onClick={() => setShowSearch(true)}
          className="w-8 h-8 flex items-center justify-center text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <Search className="w-5 h-5" strokeWidth={2.5} />
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto px-5 pt-6 pb-6">
        
        {/* Recording Input Section - 和主页Memo方块一样的渐变和立体感 */}
        <div className="mb-8 bg-gradient-to-br from-[#fff4e8] via-[#fffaf2] to-white rounded-[20px] p-5 shadow-[0_3px_10px_rgba(255,159,64,0.08),0_1px_3px_rgba(255,159,64,0.05)] border border-[#ffb85c]/15">
          <div className="w-full bg-white/80 rounded-[12px] px-4 py-3.5 flex items-center justify-between">
            {/* Text input area - left side */}
            <button
              onClick={() => setShowRecordingInput(true)}
              className="flex-1 text-left hover:opacity-70 transition-opacity"
            >
              <span className="text-[14px] text-[#6c6c70] font-medium">Capture a thought, idea, or reflection...</span>
            </button>
            
            {/* Voice input button - right side */}
            <button
              onClick={() => {
                setShowRecordingInput(true);
                // Auto start recording when mic button is clicked
                setTimeout(() => {
                  setIsRecording(true);
                }, 100);
              }}
              className="w-8 h-8 rounded-full bg-[#f59e42]/10 flex items-center justify-center hover:bg-[#f59e42]/20 transition-colors"
            >
              <Mic className="w-4 h-4 text-[#f59e42]" strokeWidth={2.5} />
            </button>
          </div>
        </div>

        {/* Today Section - 和背景融为一体，最高优先级 */}
        {todayMemos.length > 0 && (
          <div className="mb-8 px-2">
            <div className="flex items-center gap-3 mb-4 pb-3 border-b border-black/[0.08]">
              <h3 className="text-[16px] text-[#1c1c1e] font-semibold">Today</h3>
            </div>
            <div className="space-y-1.5">
              {todayMemos.map((memo) => (
                <button
                  key={memo.id}
                  onClick={() => onMemoClick(memo)}
                  className="w-full text-left py-2.5 px-3 rounded-[8px] hover:bg-white/60 transition-colors"
                >
                  <p className="text-[15px] text-[#1c1c1e] leading-[1.5]">
                    {memo.title}
                  </p>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Earlier Section - 和背景融为一体，中等优先级 */}
        {earlierMemos.length > 0 && (
          <div className="mb-8 px-2 opacity-90">
            <div className="flex items-center gap-3 mb-4 pb-3 border-b border-black/[0.06]">
              <h3 className="text-[16px] text-[#3c3c43] font-semibold">Earlier</h3>
            </div>
            <div className="space-y-1.5">
              {earlierMemos.map((memo) => (
                <button
                  key={memo.id}
                  onClick={() => onMemoClick(memo)}
                  className="w-full text-left py-2.5 px-3 rounded-[8px] hover:bg-white/50 transition-colors"
                >
                  <p className="text-[14px] text-[#3c3c43] leading-[1.5]">
                    {memo.title}
                  </p>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Long ago Section - 和背景融为一体，最低优先级 */}
        {longAgoMemos.length > 0 && (
          <div className="mb-6 px-2 opacity-70">
            <div className="flex items-center justify-between mb-4 pb-3 border-b border-black/[0.04]">
              <button
                onClick={() => setLongAgoCollapsed(!longAgoCollapsed)}
                className="flex items-center gap-2.5 hover:opacity-70 transition-opacity"
              >
                <h3 className="text-[15px] text-[#6c6c70] font-semibold">
                  Long ago · {longAgoMemos.length}
                </h3>
                {longAgoCollapsed ? (
                  <ChevronDown className="w-4 h-4 text-[#6c6c70]" strokeWidth={2.5} />
                ) : (
                  <ChevronUp className="w-4 h-4 text-[#6c6c70]" strokeWidth={2.5} />
                )}
              </button>
              {!longAgoCollapsed && longAgoMemos.length > 0 && (
                <button
                  onClick={clearLongAgoMemos}
                  className="text-[12px] text-[#8e8e93] hover:text-[#ff3b30] transition-colors font-medium"
                >
                  Clear
                </button>
              )}
            </div>
            {!longAgoCollapsed && (
              <div className="space-y-1">
                {longAgoMemos.map((memo) => (
                  <button
                    key={memo.id}
                    onClick={() => onMemoClick(memo)}
                    className="w-full text-left py-2 px-3 rounded-[8px] hover:bg-white/40 transition-colors"
                  >
                    <p className="text-[13px] text-[#6c6c70] leading-[1.5]">
                      {memo.title}
                    </p>
                  </button>
                ))}
              </div>
            )}
          </div>
        )}

      </div>

      {/* Half-screen Input Modal */}
      {showRecordingInput && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          {/* Backdrop */}
          <div 
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={handleCancelInput}
          />
          
          {/* Modal - 半页弹窗 */}
          <div 
            className="relative w-full max-w-md bg-white rounded-t-[24px] shadow-2xl animate-slide-up"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Content */}
            <div className="px-5 pt-6 pb-6 max-h-[70vh] flex flex-col">
              {/* Multi-line textarea */}
              <textarea
                autoFocus
                value={memoInputText}
                onChange={(e) => setMemoInputText(e.target.value)}
                placeholder="Capture a thought, idea, or reflection..."
                className="flex-1 min-h-[200px] text-[17px] text-[#1c1c1e] leading-[1.6] resize-none outline-none placeholder:text-[#8e8e93] bg-transparent"
                style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
                disabled={isRecording || isTranscribing}
              />
              
              {/* Recording Waveform */}
              {isRecording && (
                <div className="flex items-center justify-center py-8">
                  <div className="flex items-center gap-1.5">
                    {[...Array(20)].map((_, i) => (
                      <div
                        key={i}
                        className="w-1 bg-[#007aff] rounded-full animate-wave"
                        style={{
                          height: `${Math.random() * 40 + 20}px`,
                          animationDelay: `${i * 0.05}s`
                        }}
                      />
                    ))}
                  </div>
                </div>
              )}

              {/* Transcribing indicator */}
              {isTranscribing && (
                <div className="flex items-center justify-center py-8">
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" />
                    <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.2s' }} />
                    <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.4s' }} />
                    <span className="ml-2 text-[14px] text-[#8e8e93]">Transcribing...</span>
                  </div>
                </div>
              )}
              
              {/* Bottom bar with buttons */}
              <div className="flex items-center justify-between pt-4 border-t border-black/[0.06] mt-4">
                {isRecording ? (
                  <>
                    {/* Cancel recording button */}
                    <button
                      onClick={handleCancelRecording}
                      className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors active:scale-95"
                    >
                      <X className="w-5 h-5 text-[#8e8e93]" strokeWidth={2.5} />
                    </button>
                    
                    {/* Send voice button */}
                    <button
                      onClick={handleSendVoice}
                      className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors active:scale-95"
                    >
                      <Check className="w-5 h-5 text-white" strokeWidth={2.5} />
                    </button>
                  </>
                ) : isTranscribing ? (
                  <div className="flex-1" />
                ) : (
                  <>
                    <div className="flex-1" />
                    {memoInputText.trim() ? (
                      <button
                        onClick={handleSaveMemo}
                        className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors active:scale-95"
                      >
                        <ArrowUp className="w-5 h-5 text-white" strokeWidth={2.5} />
                      </button>
                    ) : (
                      <button
                        onClick={handleStartRecording}
                        className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors"
                      >
                        <Mic className="w-5 h-5 text-[#8e8e93]" strokeWidth={2.5} />
                      </button>
                    )}
                  </>
                )}
              </div>
            </div>
          </div>

          <style>{`
            @keyframes slide-up {
              from {
                transform: translateY(100%);
              }
              to {
                transform: translateY(0);
              }
            }
            .animate-slide-up {
              animation: slide-up 0.3s ease-out;
            }
            @keyframes wave {
              0%, 100% {
                transform: scaleY(1);
              }
              50% {
                transform: scaleY(1.5);
              }
            }
            .animate-wave {
              animation: wave 1s ease-in-out infinite;
            }
          `}</style>
        </div>
      )}
        </>
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
              <span className="text-[17px] font-semibold">Search memos</span>
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
                placeholder="Search by topic, idea, or keywords..."
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

      {/* Clear Confirmation Modal */}
      {showClearConfirmation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <div 
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={handleCancelClear}
          />
          
          {/* Modal - Center Card */}
          <div 
            className="relative w-full max-w-md bg-white rounded-[20px] shadow-2xl animate-scale-in max-h-[80vh] flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="px-5 pt-6 pb-4 border-b border-black/[0.06]">
              {/* Decorative line */}
              <div className="w-12 h-1 bg-[#8e8e93]/30 rounded-full mx-auto mb-4" />
              
              <h2 className="text-[20px] font-semibold text-[#1c1c1e] text-center mb-3">
                Clear old memos?
              </h2>
              
              <p className="text-[14px] text-[#8e8e93] text-center leading-[1.5]">
                The selected memos will be removed.<br />
                Only checked items will be cleared.
              </p>
            </div>

            {/* Memos List - Scrollable */}
            <div className="flex-1 overflow-auto px-5 py-4">
              <div className="mb-3">
                <p className="text-[13px] text-[#8e8e93] font-medium">
                  Long ago · {longAgoMemos.length} {longAgoMemos.length === 1 ? 'memo' : 'memos'}
                </p>
              </div>
              
              <div className="space-y-2">
                {longAgoMemos.map((memo) => (
                  <button
                    key={memo.id}
                    onClick={() => toggleMemoSelection(memo.id)}
                    className="w-full text-left p-3 rounded-[12px] hover:bg-[#f2f2f7] transition-colors flex items-start gap-3 border border-black/[0.06]"
                  >
                    {/* Checkbox */}
                    <div className="flex-shrink-0 mt-0.5">
                      <div className={`w-5 h-5 rounded-[6px] border-2 flex items-center justify-center transition-all ${
                        selectedMemosToDelete.includes(memo.id)
                          ? 'bg-[#007aff] border-[#007aff]'
                          : 'bg-white border-[#8e8e93]'
                      }`}>
                        {selectedMemosToDelete.includes(memo.id) && (
                          <Check className="w-3 h-3 text-white" strokeWidth={3} />
                        )}
                      </div>
                    </div>
                    
                    {/* Memo title */}
                    <p className="flex-1 text-[14px] text-[#1c1c1e] leading-[1.5]">
                      {memo.title}
                    </p>
                  </button>
                ))}
              </div>
            </div>

            {/* Select All Toggle */}
            <div className="px-5 pb-4">
              <button
                onClick={toggleSelectAll}
                className="w-full text-left p-3 rounded-[12px] hover:bg-[#f2f2f7] transition-colors flex items-center gap-3"
              >
                {/* Checkbox */}
                <div className="flex-shrink-0">
                  <div className={`w-5 h-5 rounded-[6px] border-2 flex items-center justify-center transition-all ${
                    selectedMemosToDelete.length === longAgoMemos.length && longAgoMemos.length > 0
                      ? 'bg-white border-[#8e8e93]'
                      : 'bg-white border-[#8e8e93]'
                  }`}>
                    {selectedMemosToDelete.length === longAgoMemos.length && longAgoMemos.length > 0 ? null : (
                      selectedMemosToDelete.length > 0 && <div className="w-2 h-2 bg-[#8e8e93] rounded-[2px]" />
                    )}
                  </div>
                </div>
                
                <p className="flex-1 text-[14px] text-[#3c3c43] font-medium">
                  {selectedMemosToDelete.length === longAgoMemos.length && longAgoMemos.length > 0
                    ? 'Unselect all'
                    : 'Select all'}
                </p>
              </button>
            </div>

            {/* Divider */}
            <div className="h-[1px] bg-black/[0.06] mx-5" />

            {/* Actions */}
            <div className="px-5 py-4 flex items-center gap-3">
              <button
                onClick={handleCancelClear}
                className="flex-1 py-3 rounded-[12px] bg-[#f2f2f7] text-[#1c1c1e] font-semibold text-[15px] hover:bg-[#e5e5ea] transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmClear}
                disabled={selectedMemosToDelete.length === 0}
                className={`flex-1 py-3 rounded-[12px] font-semibold text-[15px] transition-colors ${
                  selectedMemosToDelete.length === 0
                    ? 'bg-[#ff3b30]/30 text-white/50 cursor-not-allowed'
                    : 'bg-[#ff3b30] text-white hover:bg-[#ff2d1f]'
                }`}
              >
                Clear selected
              </button>
            </div>
          </div>

          <style>{`
            @keyframes scale-in {
              from {
                opacity: 0;
                transform: scale(0.9);
              }
              to {
                opacity: 1;
                transform: scale(1);
              }
            }
            .animate-scale-in {
              animation: scale-in 0.2s ease-out;
            }
          `}</style>
        </div>
      )}
    </div>
  );
}