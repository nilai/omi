import { ChevronLeft, Share2, Sparkles } from 'lucide-react';
import { useState } from 'react';
import { AIChatModal } from './AIChatModal';
import { NewTodoFromMemoModal } from './NewTodoFromMemoModal';
import { Check } from 'lucide-react';

interface PatternInsightDetailProps {
  onBack: () => void;
  onMemoryClick?: (memoryId: string) => void;
  onCreateTodo?: (todoTitle: string) => void;
  onAddTodo?: (todo: any) => void;
  insight: any;
}

export function PatternInsightDetail({ onBack, onMemoryClick, onCreateTodo, onAddTodo, insight }: PatternInsightDetailProps) {
  const [showAIChatModal, setShowAIChatModal] = useState(false);
  const [showAddTodoModal, setShowAddTodoModal] = useState(false);
  const [todoCreated, setTodoCreated] = useState<boolean>(() => {
    // Load from localStorage based on insight id
    const stored = localStorage.getItem(`pattern-insight-todo-created-${insight?.id || 'current'}`);
    return stored === 'true';
  });
  const [chatMessages, setChatMessages] = useState<any[]>(() => {
    const stored = localStorage.getItem(`pattern-insight-chat-${insight?.id || 'current'}`);
    return stored ? JSON.parse(stored) : [];
  });

  // Mock data for pattern insight
  const patternData = {
    title: 'API migration blockers have surfaced across multiple conversations over the past two weeks',
    description: 'Ownership and delivery sequencing remain unclear, causing repeated execution friction.',
    relatedMemories: [
      { id: '1', title: 'Team standup', date: 'Jan 18' },
      { id: '2', title: 'Infra sync', date: 'Jan 20' },
      { id: '3', title: 'Product review', date: 'Jan 23' },
      { id: '1', title: 'Hiring discussion', date: 'Jan 25' }
    ],
    appearanceCount: 4,
    whyMatters: 'Continued ambiguity may delay rollout and increase cross-team coordination costs, affecting delivery confidence.',
    suggestedNextStep: 'Clarify API ownership and rollout sequence in next infrastructure sync.',
    askAISuggestions: [
      'Why does this keep resurfacing?',
      'What decision is missing?',
      'How do we unblock this?'
    ]
  };

  const handleCreateTodo = () => {
    setShowAddTodoModal(true);
  };

  return (
    <div className="flex flex-col h-full bg-white">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06] relative">
        <button
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-6 h-6" strokeWidth={2} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          Pattern Insight
        </h1>
        <button className="w-8 h-8 flex items-center justify-center text-[#007aff] hover:opacity-70 transition-opacity">
          <Share2 className="w-5 h-5" strokeWidth={2} />
        </button>
      </div>

      {/* Subtitle */}
      <div className="px-5 pt-4 pb-3 border-b border-black/[0.06] bg-gradient-to-r from-[#fff3e0]/30 to-[#ffe082]/20">
        <h2 className="text-[15px] font-semibold text-[#ff9800]">Emerging Pattern Detected</h2>
      </div>

      {/* Content - Scrollable */}
      <div className="flex-1 overflow-y-auto px-5 pt-6 pb-20">
        
        {/* Pattern Detected Section */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <span className="text-[24px]">🧠</span>
            <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Pattern Detected</h3>
          </div>
          
          <div className="h-[1px] bg-black/[0.1] mb-4" />
          
          <p className="text-[16px] text-[#1c1c1e] leading-[1.6] mb-4">
            {patternData.title}
          </p>
          
          <p className="text-[15px] text-[#3c3c43] leading-[1.5]">
            {patternData.description}
          </p>
        </div>

        {/* Where This Appeared Section */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <span className="text-[24px]">📍</span>
            <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Where This Appeared</h3>
          </div>
          
          <div className="h-[1px] bg-black/[0.1] mb-4" />
          
          <p className="text-[14px] text-[#6c6c70] mb-4">
            Appeared in recent memories:
          </p>
          
          <div className="space-y-2 mb-4">
            {patternData.relatedMemories.map((memory, index) => (
              <button
                key={index}
                onClick={() => onMemoryClick?.(memory.id)}
                className="w-full text-left p-3 rounded-[12px] bg-[#f2f2f7] hover:bg-[#e5e5ea] transition-colors group flex items-center justify-between"
              >
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#ff9800]">•</span>
                  <span className="text-[15px] text-[#1c1c1e]">{memory.title}</span>
                  <span className="text-[13px] text-[#8e8e93]">— {memory.date}</span>
                </div>
                <span className="text-[13px] text-[#007aff] opacity-0 group-hover:opacity-100 transition-opacity">
                  View
                </span>
              </button>
            ))}
          </div>
          
          <p className="text-[14px] text-[#6c6c70]">
            Appeared in {patternData.appearanceCount} conversations.
          </p>
        </div>

        {/* Why This Matters Section */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <span className="text-[24px]">⚠️</span>
            <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Why This Matters</h3>
          </div>
          
          <div className="h-[1px] bg-black/[0.1] mb-4" />
          
          <p className="text-[15px] text-[#3c3c43] leading-[1.5]">
            {patternData.whyMatters}
          </p>
        </div>

        {/* Suggested Next Step Section */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-4">
            <span className="text-[24px]">🎯</span>
            <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Suggested Next Step</h3>
          </div>
          
          <div className="h-[1px] bg-black/[0.1] mb-4" />
          
          <div className="flex items-start gap-3">
            <p className="flex-1 text-[15px] text-[#3c3c43] leading-[1.5]">
              {patternData.suggestedNextStep}
            </p>
            {todoCreated ? (
              <button 
                disabled
                className="px-3 py-1.5 text-[13px] text-[#34c759] bg-green-50 rounded-lg whitespace-nowrap font-medium flex items-center gap-1.5 cursor-default"
              >
                <Check className="w-3.5 h-3.5" strokeWidth={2.5} />
                Added
              </button>
            ) : (
              <button
                onClick={handleCreateTodo}
                className="px-4 py-2 rounded-[10px] bg-[#007aff] text-white text-[14px] font-medium hover:bg-[#0051d5] transition-colors whitespace-nowrap"
              >
                + Add as Todo
              </button>
            )}
          </div>
        </div>

        {/* Ask AI About This Pattern Button */}
        <section>
          <div className="h-px bg-gradient-to-r from-transparent via-black/[0.08] to-transparent my-5" />
          <button
            onClick={() => setShowAIChatModal(true)}
            className="w-full flex items-center justify-center gap-2.5 px-4 py-3 bg-gradient-to-r from-[#7c3aed] to-[#6929cc] text-white rounded-xl hover:from-[#6929cc] hover:to-[#5a1fb3] transition-all shadow-sm hover:shadow-md"
          >
            <Sparkles className="w-[18px] h-[18px]" strokeWidth={2} />
            <span className="text-[15px] font-semibold">Ask AI About This Pattern</span>
          </button>
        </section>
      </div>

      {/* AI Chat Modal */}
      {showAIChatModal && (
        <AIChatModal
          isOpen={showAIChatModal}
          onClose={() => setShowAIChatModal(false)}
          initialMessages={chatMessages}
          onSaveMessages={(messages) => {
            setChatMessages(messages);
            localStorage.setItem(`pattern-insight-chat-${insight?.id || 'current'}`, JSON.stringify(messages));
          }}
          memoryTitle="Pattern Insight"
          suggestedQuestions={[
            'Why does this keep resurfacing?',
            'What decision is missing?',
            'How do we unblock this?'
          ]}
        />
      )}

      {/* Add Todo Modal */}
      {showAddTodoModal && (
        <NewTodoFromMemoModal
          suggestion={patternData.suggestedNextStep}
          insightContent={''}
          memory={{
            id: `pattern-insight-${insight?.id || 'current'}`,
            title: `Pattern Insight · ${insight?.date || 'Feb 2'}`,
            date: insight?.date || 'Feb 2',
            duration: undefined,
            hasSummary: false
          }}
          onClose={() => setShowAddTodoModal(false)}
          onCreateTodo={(newTodo) => {
            if (onAddTodo) {
              onAddTodo({
                id: Date.now(),
                title: newTodo.title,
                priority: newTodo.priority,
                dueDate: newTodo.dueDate,
                notes: newTodo.notes || [],
                completed: false,
                linkedMemory: {
                  id: `pattern-insight-${insight?.id || 'current'}`,
                  title: `Pattern Insight · ${insight?.date || 'Feb 2'}`,
                  date: insight?.date || 'Feb 2'
                }
              });
            }
            
            setShowAddTodoModal(false);
            setTodoCreated(true);
            localStorage.setItem(`pattern-insight-todo-created-${insight?.id || 'current'}`, 'true');
          }}
        />
      )}
    </div>
  );
}