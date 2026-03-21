import { ChevronLeft, Mic, Send, Clock, MapPin, CheckCircle, AlertCircle, Flame, Sparkles, Loader2, TrendingUp, Users, Target, Lightbulb, Heart } from 'lucide-react';
import { useState, useEffect } from 'react';

type ExpertType = 'Auto' | 'Business' | 'Execution' | 'Creative' | 'Wellness';

interface ExpertChatViewProps {
  expert: ExpertType;
  onClose: () => void;
  isFromHistory?: boolean;
}

interface Message {
  id: string;
  sender: 'user' | 'ai';
  text: string;
}

// Expert-specific content
const expertContent = {
  Business: {
    topicDiscussed: 'Revenue impact, market positioning, and strategic opportunities across recent decisions.',
    progressMade: [
      'Identified three key revenue drivers',
      'Aligned team on market positioning',
      'Validated customer feedback patterns'
    ],
    openQuestions: [
      'ROI metrics still being defined',
      'Competitive analysis incomplete',
      'Pricing strategy needs validation'
    ],
    currentTension: 'Short-term revenue goals conflict with long-term strategic positioning.',
    suggestedQuestions: [
      'What business opportunities am I missing?',
      'Which decisions have the highest ROI?',
      'What market signals should I pay attention to?',
      'How do recent decisions align with business goals?'
    ],
    icon: TrendingUp,
    color: '#007aff'
  },
  Execution: {
    topicDiscussed: 'Delivery timelines, resource allocation, and operational efficiency across active projects.',
    progressMade: [
      'Defined clear milestone dependencies',
      'Allocated resources to critical paths',
      'Established realistic timeline buffers'
    ],
    openQuestions: [
      'Team capacity constraints emerging',
      'Cross-team coordination gaps exist',
      'Risk mitigation plans need owners'
    ],
    currentTension: 'Aggressive delivery expectations exceed current team bandwidth and dependencies.',
    suggestedQuestions: [
      'What blockers need immediate attention?',
      'How can we optimize current workflows?',
      'What dependencies am I underestimating?',
      'Where should we cut scope to ship faster?'
    ],
    icon: Target,
    color: '#5856d6'
  },
  Creative: {
    topicDiscussed: 'Innovation opportunities, design thinking, and creative problem-solving approaches.',
    progressMade: [
      'Explored unconventional solutions',
      'Connected seemingly unrelated ideas',
      'Challenged existing assumptions'
    ],
    openQuestions: [
      'Alternative approaches not yet explored',
      'User experience implications unclear',
      'Innovation vs. execution balance needed'
    ],
    currentTension: 'Creative exploration requires time that conflicts with immediate execution demands.',
    suggestedQuestions: [
      'What if we approached this differently?',
      'What unconventional solutions exist?',
      'How might we reframe this problem?',
      'What ideas are we dismissing too quickly?'
    ],
    icon: Lightbulb,
    color: '#ff9500'
  },
  Wellness: {
    topicDiscussed: 'Work-life balance, team energy levels, and sustainable pace across commitments.',
    progressMade: [
      'Identified burnout risk indicators',
      'Established healthier boundaries',
      'Recognized need for recovery time'
    ],
    openQuestions: [
      'Workload distribution feels unbalanced',
      'Team morale signals need attention',
      'Sustainable pace not yet achieved'
    ],
    currentTension: 'High performance expectations clash with maintaining team wellbeing and energy.',
    suggestedQuestions: [
      'Am I maintaining a sustainable pace?',
      'What signs of burnout should I watch for?',
      'How can I better support team wellbeing?',
      'What commitments should I reconsider?'
    ],
    icon: Heart,
    color: '#34c759'
  },
  Auto: {
    topicDiscussed: 'Cross-functional insights combining business, execution, creative, and wellness perspectives.',
    progressMade: [
      'Synthesized multi-dimensional view',
      'Balanced competing priorities',
      'Identified holistic trade-offs'
    ],
    openQuestions: [
      'Conflicting signals across perspectives',
      'Priority alignment needs clarity',
      'Integrated action plan pending'
    ],
    currentTension: 'Multiple expert perspectives reveal competing priorities requiring difficult trade-offs.',
    suggestedQuestions: [
      'What decision should I make next?',
      'What trade-offs am I ignoring?',
      'What would de-risk this plan?',
      'Summarize open threads I\'m avoiding'
    ],
    icon: Sparkles,
    color: '#007aff'
  }
};

export function ExpertChatView({ expert, onClose, isFromHistory = false }: ExpertChatViewProps) {
  const [inputValue, setInputValue] = useState('');
  const [isGenerating, setIsGenerating] = useState(!isFromHistory);
  const [messages, setMessages] = useState<Message[]>([]);

  // Load messages from localStorage if coming from history
  useEffect(() => {
    if (isFromHistory) {
      const savedMessages = localStorage.getItem(`expert-chat-${expert.toLowerCase()}`);
      if (savedMessages) {
        setMessages(JSON.parse(savedMessages));
      } else {
        // Mock some conversation history if no saved messages
        const mockMessages: Message[] = [
          {
            id: '1',
            sender: 'user',
            text: 'What business opportunities am I missing?'
          },
          {
            id: '2',
            sender: 'ai',
            text: 'Based on your recent conversations, I see three key opportunities: 1) The enterprise segment shows strong interest but lacks dedicated support. 2) Your customer feedback indicates demand for API access. 3) Partnership discussions suggest potential for white-label solutions.'
          },
          {
            id: '3',
            sender: 'user',
            text: 'Can you elaborate on the enterprise segment opportunity?'
          },
          {
            id: '4',
            sender: 'ai',
            text: 'From your meetings, enterprises are asking about: dedicated account management, SLA guarantees, and custom integration support. They represent 3x higher lifetime value but need specialized resources to serve effectively.'
          }
        ];
        setMessages(mockMessages);
      }
    }
  }, [isFromHistory, expert]);

  // Save messages to localStorage whenever they change
  useEffect(() => {
    if (messages.length > 0) {
      localStorage.setItem(`expert-chat-${expert.toLowerCase()}`, JSON.stringify(messages));
    }
  }, [messages, expert]);

  // Start generating animation when component mounts (only if not from history)
  useEffect(() => {
    if (!isFromHistory) {
      const timer = setTimeout(() => {
        setIsGenerating(false);
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [isFromHistory]);

  // Debug: Log when component renders
  console.log('ExpertChatView rendered with expert:', expert, 'isFromHistory:', isFromHistory, 'isGenerating:', isGenerating);
  
  const handleBackClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    console.log('ExpertChatView back button clicked - calling onClose');
    onClose();
  };
  
  const expertColors = {
    Auto: 'text-[#007aff]',
    Business: 'text-[#007aff]',
    Execution: 'text-[#5856d6]',
    Creative: 'text-[#ff9500]',
    Wellness: 'text-[#34c759]',
  };

  const currentContent = expertContent[expert];
  const ExpertIcon = currentContent.icon;

  const handleSend = () => {
    if (!inputValue.trim()) return;
    
    // Add user message
    const newMessage: Message = {
      id: Date.now().toString(),
      sender: 'user',
      text: inputValue,
    };
    setMessages([...messages, newMessage]);
    setInputValue('');

    // Simulate AI response
    setTimeout(() => {
      const aiResponse: Message = {
        id: (Date.now() + 1).toString(),
        sender: 'ai',
        text: 'I\'m processing your question from a ' + expert + ' perspective...',
      };
      setMessages(prev => [...prev, aiResponse]);
    }, 1000);
  };

  const handleQuestionClick = (question: string) => {
    // Directly add user message to conversation
    const newMessage: Message = {
      id: Date.now().toString(),
      sender: 'user',
      text: question,
    };
    setMessages([...messages, newMessage]);

    // Simulate AI response
    setTimeout(() => {
      const aiResponse: Message = {
        id: (Date.now() + 1).toString(),
        sender: 'ai',
        text: 'Let me address that from a ' + expert + ' perspective...',
      };
      setMessages(prev => [...prev, aiResponse]);
    }, 1000);
  };

  return (
    <div className="fixed inset-0 bg-white z-[60] flex flex-col">
      {/* Header */}
      <div className="flex-shrink-0 bg-white border-b border-black/[0.06]">
        {/* Top bar - Back button and title */}
        <div className="px-4 pt-4 pb-2 flex items-center gap-3 relative z-10">
          <button
            onClick={handleBackClick}
            className="flex items-center justify-center w-8 h-8 -ml-1 text-[#007aff] hover:bg-[#f2f2f7] rounded-lg transition-colors relative z-50 cursor-pointer"
            type="button"
            style={{ pointerEvents: 'auto' }}
          >
            <ChevronLeft className="w-5 h-5 pointer-events-none" strokeWidth={2.5} />
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] flex-1 text-center -ml-8">
            Ask AI
          </h1>
          <div className="w-8" /> {/* Spacer for centering */}
        </div>

        {/* About and Expert selector - Single row */}
        <div className="px-5 py-2.5 bg-gradient-to-br from-[#f0f9ff] to-[#e0f2fe] border-t border-[#007aff]/10">
          <div className="flex items-center gap-3">
            {/* About Section */}
            <div className="flex items-center gap-2 flex-1 min-w-0">
              <Sparkles className="w-4 h-4 text-[#007aff] flex-shrink-0" />
              <p className="text-[13px] text-[#1c1c1e] truncate">
                <span className="font-medium">About:</span> All memories
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto px-4 py-3">
        <div className="space-y-4 max-w-2xl mx-auto">
          
          {/* Show generating animation OR content */}
          {isGenerating ? (
            <div className="flex flex-col items-center justify-center py-16">
              <div className="relative">
                <Loader2 className="w-12 h-12 text-[#007aff] animate-spin" strokeWidth={2} />
                <ExpertIcon 
                  className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-5 h-5"
                  style={{ color: currentContent.color }}
                  strokeWidth={2}
                />
              </div>
              <p className="text-[15px] text-[#1c1c1e] font-medium mt-6 mb-1">
                {expert} Expert analyzing...
              </p>
              <p className="text-[13px] text-[#8e8e93]">
                Reviewing all memories for insights
              </p>
            </div>
          ) : (
            <>
              {/* Only show recap and suggested questions if NOT from history */}
              {!isFromHistory && (
                <>
                  {/* Recap container with light background */}
                  <div className="bg-[#f9f9f9] rounded-2xl p-3 space-y-3">
                    {/* Topic discussed */}
                    <div className="bg-white rounded-xl p-3">
                      <div className="flex items-center gap-2 mb-2">
                        <MapPin className="w-4 h-4 text-[#8e8e93]" strokeWidth={2} />
                        <h3 className="text-[13px] font-semibold text-[#1c1c1e]">
                          Topic discussed
                        </h3>
                      </div>
                      <p className="text-[14px] text-[#1c1c1e] leading-snug">
                        {currentContent.topicDiscussed}
                      </p>
                    </div>

                    {/* Progress made */}
                    <div className="bg-white rounded-xl p-3">
                      <div className="flex items-center gap-2 mb-2">
                        <CheckCircle className="w-4 h-4 text-[#34c759]" strokeWidth={2} />
                        <h3 className="text-[13px] font-semibold text-[#1c1c1e]">
                          Progress made
                        </h3>
                      </div>
                      <ul className="space-y-1 text-[14px] text-[#1c1c1e]">
                        {currentContent.progressMade.map((item, index) => (
                          <li key={index} className="flex items-start gap-1.5">
                            <span className="text-[#1c1c1e] mt-0.5">•</span>
                            <span>{item}</span>
                          </li>
                        ))}
                      </ul>
                    </div>

                    {/* Open questions */}
                    <div className="bg-white rounded-xl p-3">
                      <div className="flex items-center gap-2 mb-2">
                        <AlertCircle className="w-4 h-4 text-[#ff9500]" strokeWidth={2} />
                        <h3 className="text-[13px] font-semibold text-[#1c1c1e]">
                          Open questions
                        </h3>
                      </div>
                      <ul className="space-y-1 text-[14px] text-[#1c1c1e]">
                        {currentContent.openQuestions.map((item, index) => (
                          <li key={index} className="flex items-start gap-1.5">
                            <span className="text-[#1c1c1e] mt-0.5">•</span>
                            <span>{item}</span>
                          </li>
                        ))}
                      </ul>
                    </div>

                    {/* Current tension */}
                    <div className="bg-white rounded-xl p-3">
                      <div className="flex items-center gap-2 mb-2">
                        <Flame className="w-4 h-4 text-[#ff3b30]" strokeWidth={2} />
                        <h3 className="text-[13px] font-semibold text-[#1c1c1e]">
                          Current tension
                        </h3>
                      </div>
                      <p className="text-[14px] text-[#1c1c1e] leading-snug">
                        {currentContent.currentTension}
                      </p>
                    </div>
                  </div>

                  {/* Suggested next questions */}
                  <div className="space-y-3">
                    <h3 className="text-[14px] font-semibold text-[#8e8e93]">
                      Suggested next questions
                    </h3>
                    <div className="space-y-2">
                      {currentContent.suggestedQuestions.map((question, index) => (
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

                  {/* Divider if there are messages */}
                  {messages.length > 0 && (
                    <div className="border-t border-black/[0.06] pt-4">
                      <p className="text-[13px] text-[#8e8e93] text-center mb-4">
                        Conversation continues here
                      </p>
                    </div>
                  )}
                </>
              )}
            </>
          )}

          {/* Messages - only shown when not generating */}
          {!isGenerating && (
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
                      <span className={`text-[13px] font-medium mb-1 ml-1 ${expertColors[expert]}`}>
                        {expert} Expert
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

      {/* Input area - Fixed at bottom */}
      <div className="flex-shrink-0 bg-white border-t border-black/[0.06] px-4 pb-5 pt-3">
        <div className="flex gap-2 items-end max-w-2xl mx-auto">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            placeholder="Ask about your memories..."
            className="flex-1 px-4 py-2.5 text-[15px] bg-[#f2f2f7] rounded-[20px] border-none focus:outline-none focus:ring-2 focus:ring-[#007aff]/20 transition-all"
            disabled={isGenerating}
          />
          <button 
            className="w-9 h-9 flex items-center justify-center bg-[#f2f2f7] text-[#8e8e93] rounded-full hover:bg-[#e5e5ea] transition-colors flex-shrink-0"
            disabled={isGenerating}
          >
            <Mic className="w-4.5 h-4.5" strokeWidth={2} />
          </button>
          <button
            onClick={handleSend}
            className="w-9 h-9 flex items-center justify-center bg-[#007aff] text-white rounded-full hover:bg-[#0051d5] transition-colors flex-shrink-0 disabled:opacity-50"
            disabled={!inputValue.trim() || isGenerating}
          >
            <Send className="w-4.5 h-4.5" strokeWidth={2} />
          </button>
        </div>
      </div>
    </div>
  );
}