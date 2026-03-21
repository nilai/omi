import { ChevronLeft, Sparkles, Activity, X, ChevronRight, MessageCircle, Mic, ArrowUp } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';
import { TodoDetailModal } from './TodoDetailModal';

interface PersonDetailProps {
  personName: string;
  onBack: () => void;
  todos?: any[];
  onMarkDone?: (id: number) => void;
  onNotNow?: (id: number) => void;
  onDeleteTodo?: (id: number) => void;
  onUpdateTodo?: (id: number, updates: any) => void;
}

export function PersonDetail({ personName, onBack, todos, onMarkDone, onNotNow, onDeleteTodo, onUpdateTodo }: PersonDetailProps) {
  const [showAskAI, setShowAskAI] = useState(false);
  const [selectedTodo, setSelectedTodo] = useState<any>(null);
  const [selectedMemory, setSelectedMemory] = useState<any>(null);
  const [showMemoriesList, setShowMemoriesList] = useState(false);

  // Mock data for this person
  const talkCount = 12;
  const lastTalked = 'yesterday';
  
  const recentContext = {
    focusedOn: [
      'API migration timeline alignment',
      'Delivery ownership clarification',
      'Product strategy follow-ups',
    ],
    lastDiscussed: {
      date: 'Yesterday',
      title: 'Team standup discussion',
    },
    openFollowUps: [
      'Review migration milestones',
      'Confirm infrastructure support plan',
    ],
  };
  
  const patterns = {
    themes: [
      'Delivery ownership often unclear',
      'Coordination delays execution',
      'Decisions frequently postponed',
    ],
    impact: 'Tasks involving multiple teams tend to slip timelines without clear ownership.',
  };
  
  const nextSteps = [
    {
      id: 1,
      title: 'Review migration milestones',
      priority: 'High priority',
      dueDate: 'Due tomorrow',
    },
    {
      id: 2,
      title: 'Follow up on product positioning',
      priority: 'Normal',
      dueDate: 'No due date',
    },
  ];

  const recentMemories = [
    {
      id: 1,
      title: 'Team standup discussion on API migration',
      date: 'Today',
      hasSummary: true,
      hasActivity: true,
    },
    {
      id: 2,
      title: 'Coffee chat about product strategy',
      date: 'Yesterday',
      hasSummary: true,
      hasActivity: false,
    },
  ];

  const allMemories = [
    {
      id: 3,
      date: 'Jan 21',
      title: 'CES Exhibition Notes · Day 1',
    },
    {
      id: 4,
      date: 'Jan 18',
      title: 'Investor sync call',
    },
  ];

  const getPriorityColor = (priority: string) => {
    if (priority === 'High priority') return 'text-[#ff3b30]';
    if (priority === 'Normal') return 'text-[#ff9500]';
    if (priority === 'Low priority') return 'text-[#8e8e93]';
    return 'text-[#8e8e93]';
  };

  if (showAskAI) {
    return <PersonAskAIView personName={personName} onClose={() => setShowAskAI(false)} />;
  }

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] z-50 flex flex-col">
      {/* Header with back and close buttons */}
      <div className="px-5 pt-4 pb-4 bg-white border-b border-black/[0.06]">
        <div className="flex items-center justify-between relative">
          <button 
            onClick={onBack}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-6 h-6" strokeWidth={2} />
          </button>
          
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            {personName}
          </h1>
          
          <button 
            onClick={onBack}
            className="text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
          >
            <X className="w-6 h-6" strokeWidth={2} />
          </button>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Person header section */}
        <div className="px-5 pt-6 pb-5 bg-white border-b border-black/[0.06]">
          <h1 className="text-[28px] font-bold text-[#1c1c1e] mb-3">
            {personName}
          </h1>
          <div className="flex items-center gap-2 text-[15px] mb-2">
            <span className="text-[#1c1c1e] font-medium">
              {talkCount} {talkCount === 1 ? 'conversation' : 'conversations'}
            </span>
            <span className="text-[#8e8e93]">·</span>
            <span className="text-[#8e8e93]">
              Last active {lastTalked}
            </span>
          </div>
        </div>

        {/* Recent context section */}
        <div className="px-5 py-5 bg-white border-b border-black/[0.06]">
          <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-4">
            Recent context
          </h2>
          
          <div className="space-y-4">
            {/* Recent conversations focused on */}
            <div>
              <p className="text-[15px] text-[#1c1c1e] mb-2.5">
                Recent conversations focused on:
              </p>
              <ul className="space-y-2">
                {recentContext.focusedOn.map((item, index) => (
                  <li key={index} className="text-[15px] text-[#1c1c1e] leading-relaxed flex">
                    <span className="mr-2">•</span>
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
            
            {/* Last discussed */}
            <div>
              <p className="text-[15px] text-[#1c1c1e] mb-1.5">
                Last discussed:
              </p>
              <p className="text-[15px] text-[#8e8e93]">
                {recentContext.lastDiscussed.date} · {recentContext.lastDiscussed.title}
              </p>
            </div>
            
            {/* Open follow-ups */}
            <div>
              <p className="text-[15px] text-[#1c1c1e] mb-2.5">
                Open follow-ups:
              </p>
              <ul className="space-y-2">
                {recentContext.openFollowUps.map((item, index) => (
                  <li key={index} className="text-[15px] text-[#1c1c1e] leading-relaxed flex">
                    <span className="mr-2">•</span>
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        {/* Patterns section */}
        <div className="px-5 py-5 bg-white border-b border-black/[0.06]">
          <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-4">
            Patterns with {personName}
          </h2>
          
          <div className="space-y-4">
            {/* Recurring themes */}
            <div>
              <p className="text-[15px] text-[#1c1c1e] mb-2.5">
                Recurring themes across conversations:
              </p>
              <ul className="space-y-2">
                {patterns.themes.map((theme, index) => (
                  <li key={index} className="text-[15px] text-[#1c1c1e] leading-relaxed flex">
                    <span className="mr-2">•</span>
                    <span>{theme}</span>
                  </li>
                ))}
              </ul>
            </div>
            
            {/* Impact */}
            <div>
              <p className="text-[15px] text-[#1c1c1e] mb-2">
                Impact:
              </p>
              <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                {patterns.impact}
              </p>
            </div>
          </div>
        </div>

        {/* Next steps section */}
        <div className="pt-5 pb-4 px-5">
          <div className="mb-3">
            <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              Next steps with {personName}
            </h2>
          </div>
          
          <div className="bg-white rounded-[16px] shadow-sm border border-black/[0.06] overflow-hidden">
            {nextSteps.map((item, index) => {
              // Check if this todo is completed from the global todos state
              const globalTodo = todos?.find(t => t.id === item.id);
              const isCompleted = globalTodo?.completed || false;
              
              return (
                <button
                  key={item.id}
                  className={`w-full px-4 py-3.5 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors text-left ${
                    index < nextSteps.length - 1 ? 'border-b border-black/[0.06]' : ''
                  }`}
                  onClick={() => setSelectedTodo(item)}
                >
                  <div className={`text-[16px] font-medium mb-1.5 flex items-center gap-2 ${
                    isCompleted ? 'line-through text-[#8e8e93]' : 'text-[#1c1c1e]'
                  }`}>
                    {isCompleted && (
                      <span className="flex-shrink-0 w-4 h-4 rounded-full bg-[#34c759] flex items-center justify-center">
                        <svg className="w-2.5 h-2.5 text-white" fill="none" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" viewBox="0 0 24 24" stroke="currentColor">
                          <path d="M5 13l4 4L19 7"></path>
                        </svg>
                      </span>
                    )}
                    <span>{item.title}</span>
                  </div>
                  <div className="flex items-center gap-2 text-[14px]">
                    <span className={getPriorityColor(item.priority)}>{item.priority}</span>
                    <span className="text-[#8e8e93]">·</span>
                    <span className="text-[#8e8e93]">
                      {item.dueDate}
                    </span>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Recent memories section */}
        <div className="pb-4 px-5">
          <div className="mb-3">
            <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              Recent memories
            </h2>
          </div>
          
          <div className="bg-white rounded-[16px] shadow-sm border border-black/[0.06] overflow-hidden">
            {recentMemories.map((memory, index) => (
              <button
                key={memory.id}
                className={`w-full px-4 py-3.5 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors text-left ${
                  index < recentMemories.length - 1 ? 'border-b border-black/[0.06]' : ''
                }`}
                onClick={() => setSelectedMemory(memory)}
              >
                <div className="text-[16px] font-medium text-[#1c1c1e] mb-2">
                  {memory.title}
                </div>
                <div className="flex items-center gap-2 text-[14px] text-[#8e8e93]">
                  <span>{memory.date}</span>
                  {memory.hasSummary && (
                    <>
                      <span>·</span>
                      <span className="flex items-center gap-1">
                        Summary
                      </span>
                    </>
                  )}
                  {memory.hasActivity && (
                    <>
                      <span>·</span>
                      <span className="flex items-center gap-1">
                        Activity
                      </span>
                    </>
                  )}
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* All memories section */}
        <div className="pb-4 px-5">
          <div className="mb-3">
            <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              All memories
            </h2>
          </div>
          
          <div className="bg-white rounded-[16px] shadow-sm border border-black/[0.06] overflow-hidden">
            {/* Memory list items */}
            {allMemories.map((memory, index) => (
              <button
                key={memory.id}
                onClick={() => setSelectedMemory(memory)}
                className={`w-full px-4 py-3 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors text-left ${
                  index < allMemories.length - 1 ? 'border-b border-black/[0.06]' : ''
                }`}
              >
                <div className="text-[16px] text-[#1c1c1e]">
                  {memory.date} · {memory.title}
                </div>
              </button>
            ))}
            
            {/* View all button */}
            <button className="w-full px-4 py-3.5 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors border-t border-black/[0.06]" onClick={() => setShowMemoriesList(true)}>
              <div className="flex items-center justify-between">
                <span className="text-[16px] text-[#007aff] font-medium">
                  View all memories with {personName} →
                </span>
              </div>
            </button>
          </div>
        </div>

        {/* Ask about working with button */}
        <div className="px-5 pb-8">
          <button
            onClick={() => setShowAskAI(true)}
            className="w-full bg-[#007aff] hover:bg-[#0051d5] text-white rounded-[14px] px-5 py-4 flex items-center justify-center gap-2 transition-colors shadow-sm"
          >
            <MessageCircle className="w-5 h-5" strokeWidth={2} />
            <span className="text-[17px] font-semibold">
              Ask about working with {personName}...
            </span>
          </button>
        </div>

        {/* Bottom spacing */}
        <div className="h-4" />
      </div>
      
      {/* TodoDetailModal */}
      {selectedTodo && (
        <TodoDetailModal
          todo={selectedTodo}
          onClose={() => setSelectedTodo(null)}
          onMarkDone={onMarkDone}
          onNotNow={onNotNow}
          onDelete={onDeleteTodo}
          onUpdate={onUpdateTodo}
        />
      )}
      
      {/* PersonMemoriesList */}
      {showMemoriesList && (
        <PersonMemoriesList
          personName={personName}
          onBack={() => {
            setShowMemoriesList(false);
            // Also clear any selected memory to ensure clean state
            setSelectedMemory(null);
          }}
          onMemoryClick={(memoryId) => {
            // Find the memory and open it
            const memory = recentMemories.find(m => m.id.toString() === memoryId) || 
                          allMemories.find(m => m.id.toString() === memoryId) ||
                          { id: memoryId, title: 'Memory details', date: 'Today' };
            setSelectedMemory(memory);
          }}
        />
      )}
    </div>
  );
}

// Ask AI view for person context
function PersonAskAIView({ personName, onClose }: { personName: string; onClose: () => void }) {
  const [inputValue, setInputValue] = useState('');
  const [messages, setMessages] = useState<Array<{ id: string; sender: 'user' | 'ai'; text: string }>>([]);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);

  // Auto-resize textarea when inputValue changes
  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.style.height = 'auto';
      inputRef.current.style.height = Math.min(inputRef.current.scrollHeight, 120) + 'px';
    }
  }, [inputValue]);

  const handleSend = () => {
    if (!inputValue.trim()) return;
    
    const newMessage = {
      id: Date.now().toString(),
      sender: 'user' as const,
      text: inputValue,
    };
    setMessages([...messages, newMessage]);
    setInputValue('');

    // Simulate AI response
    setTimeout(() => {
      const aiResponse = {
        id: (Date.now() + 1).toString(),
        sender: 'ai' as const,
        text: `Based on your interactions with ${personName}, I can help you understand patterns, upcoming commitments, and how to improve your working relationship...`,
      };
      setMessages(prev => [...prev, aiResponse]);
    }, 1000);
  };

  const handleStartRecording = () => {
    setIsRecording(true);
  };

  const handleSendVoice = () => {
    setIsRecording(false);
    setIsTranscribing(true);
    
    // Simulate voice transcription
    setTimeout(() => {
      const transcribedText = `What are the main patterns in my conversations with ${personName}?`;
      setInputValue(transcribedText);
      setIsTranscribing(false);
    }, 1500);
  };

  const handleCancelRecording = () => {
    setIsRecording(false);
  };

  const suggestedQuestions = [
    `What should I follow up on with ${personName}?`,
    `What are recurring themes in our conversations?`,
    `How can I better support ${personName}?`,
    `What commitments have I made to ${personName}?`,
  ];

  const handleQuestionClick = (question: string) => {
    const newMessage = {
      id: Date.now().toString(),
      sender: 'user' as const,
      text: question,
    };
    setMessages([...messages, newMessage]);

    // Simulate AI response
    setTimeout(() => {
      const aiResponse = {
        id: (Date.now() + 1).toString(),
        sender: 'ai' as const,
        text: `Let me analyze your interactions with ${personName} to answer that...`,
      };
      setMessages(prev => [...prev, aiResponse]);
    }, 1000);
  };

  return (
    <div className="fixed inset-0 bg-white z-[60] flex flex-col">
      {/* Header */}
      <div className="flex-shrink-0 bg-white border-b border-black/[0.06]">
        <div className="px-4 pt-4 pb-2 flex items-center justify-between relative">
          <button
            onClick={onClose}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            Ask AI
          </h1>
          <div className="w-5" />
        </div>

        <div className="px-5 py-2.5 bg-gradient-to-br from-[#f0f9ff] to-[#e0f2fe] border-t border-[#007aff]/10">
          <div className="flex items-center justify-between gap-3">
            {/* About Section */}
            <div className="flex items-center gap-2 flex-1 min-w-0">
              <Sparkles className="w-4 h-4 text-[#007aff] flex-shrink-0" />
              <p className="text-[13px] text-[#1c1c1e] truncate">
                <span className="font-medium">About:</span> Working with {personName}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto px-4 py-3">
        <div className="space-y-4 max-w-2xl mx-auto">
          {messages.length === 0 ? (
            <>
              {/* Suggested questions */}
              <div className="space-y-3 pt-4">
                <h3 className="text-[14px] font-semibold text-[#8e8e93]">
                  Suggested questions
                </h3>
                <div className="space-y-2">
                  {suggestedQuestions.map((question, index) => (
                    <button
                      key={index}
                      onClick={() => handleQuestionClick(question)}
                      className="w-full text-left px-4 py-3 bg-white border border-black/[0.08] rounded-xl text-[15px] text-[#1c1c1e] hover:bg-[#f2f2f7] hover:border-[#007aff]/20 transition-all"
                    >
                      {question}
                    </button>
                  ))}
                </div>
              </div>
            </>
          ) : (
            <div className="space-y-4">
              {messages.map((message) => (
                <div key={message.id} className="space-y-1">
                  {message.sender === 'user' ? (
                    <div className="flex justify-end">
                      <div className="bg-[#007aff] text-white px-4 py-2.5 rounded-[18px] max-w-[75%]">
                        <p className="text-[15px] leading-relaxed">{message.text}</p>
                      </div>
                    </div>
                  ) : (
                    <div className="flex flex-col items-start">
                      <span className="text-[13px] font-medium mb-1 ml-1 text-[#007aff]">
                        AI Assistant
                      </span>
                      <div className="bg-[#f2f2f7] text-[#1c1c1e] px-4 py-2.5 rounded-[18px] max-w-[85%]">
                        <p className="text-[15px] leading-relaxed">{message.text}</p>
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Input area */}
      <div className="flex-shrink-0 bg-white border-t border-black/[0.06] px-4 pb-5 pt-3">
        <div className="flex gap-2 items-end max-w-2xl mx-auto">
          {!isRecording && !isTranscribing ? (
            <>
              <textarea
                ref={inputRef}
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleSend();
                  }
                }}
                placeholder={`Ask about ${personName}...`}
                rows={1}
                className="flex-1 px-4 py-2.5 text-[15px] bg-[#f2f2f7] rounded-[20px] border-none focus:outline-none focus:ring-2 focus:ring-[#007aff]/20 transition-all resize-none overflow-hidden"
                style={{ 
                  minHeight: '40px',
                  maxHeight: '120px'
                }}
                onInput={(e) => {
                  const target = e.target as HTMLTextAreaElement;
                  target.style.height = 'auto';
                  target.style.height = Math.min(target.scrollHeight, 120) + 'px';
                }}
              />
              <button
                onClick={handleStartRecording}
                className="w-9 h-9 flex items-center justify-center bg-[#f2f2f7] text-[#1c1c1e] rounded-full hover:bg-[#e5e5ea] transition-colors flex-shrink-0"
              >
                <Mic className="w-4.5 h-4.5" strokeWidth={2} />
              </button>
              <button
                onClick={handleSend}
                className="w-9 h-9 flex items-center justify-center bg-[#007aff] text-white rounded-full hover:bg-[#0051d5] transition-colors flex-shrink-0 disabled:opacity-50"
                disabled={!inputValue.trim()}
              >
                <ChevronRight className="w-4.5 h-4.5" strokeWidth={2} />
              </button>
            </>
          ) : isRecording ? (
            <div className="flex-1 flex items-center gap-3">
              <button 
                onClick={handleCancelRecording}
                className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors flex-shrink-0"
              >
                <X className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2.5} />
              </button>
              <div className="flex-1 flex items-center justify-center gap-1.5 px-4 py-3 bg-[#007aff]/10 rounded-[20px]">
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
            <div className="flex-1 flex items-center gap-2.5 px-4 py-3 bg-[#f2f2f7] rounded-[20px]">
              <div className="flex items-center gap-1">
                <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '0ms' }}></div>
                <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '150ms' }}></div>
                <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '300ms' }}></div>
              </div>
              <span className="text-[15px] text-[#8e8e93]">Transcribing...</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}