import { ChevronLeft, Send, Sparkles, Mic, X, ArrowUp } from 'lucide-react';
import { useState, useEffect, useRef } from 'react';

interface Message {
  role: 'user' | 'assistant';
  content: string;
  timestamp: string;
}

interface AIChatModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialMessages: Message[];
  onSaveMessages: (messages: Message[]) => void;
  memoryTitle: string;
  suggestedQuestions?: string[];
}

export function AIChatModal({ isOpen, onClose, initialMessages, onSaveMessages, memoryTitle, suggestedQuestions }: AIChatModalProps) {
  const [messages, setMessages] = useState<Message[]>(initialMessages);
  const [inputText, setInputText] = useState('');
  const [isThinking, setIsThinking] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const previousMessagesLengthRef = useRef(0);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  // Auto-resize textarea when inputText changes
  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.style.height = 'auto';
      inputRef.current.style.height = Math.min(inputRef.current.scrollHeight, 120) + 'px';
    }
  }, [inputText]);

  // Generate mock AI response based on user input
  const generateMockAIResponse = (question: string): string => {
    const lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.includes('working on') || lowerQuestion.includes('recently')) {
      return 'Based on your recent memories, you\'ve been primarily focused on:\n\n1. API migration planning with the infrastructure team\n2. Product roadmap discussions for Q2 2026\n3. Team coordination meetings about delivery timelines\n4. Regular check-ins with Sarah about authentication concerns\n\nYou\'ve had 8 conversations in the past week, with the most time spent on technical architecture discussions.';
    } else if (lowerQuestion.includes('decisions') || lowerQuestion.includes('decide')) {
      return 'This week, you made several key decisions:\n\n1. **API Migration**: Approved phased rollout approach to minimize risk\n2. **Team Resources**: Agreed to reassess infrastructure team capacity before committing to timeline\n3. **Authentication**: Decided to prioritize authentication service testing in the critical path\n4. **Q2 Roadmap**: Deferred two feature requests to focus on migration stability\n\nMost decisions centered around balancing delivery speed with technical stability.';
    } else if (lowerQuestion.includes('talking') || lowerQuestion.includes('who')) {
      return 'Your most frequent conversations this week were with:\n\n1. **Sarah** (5 conversations) - Primarily about API migration, authentication concerns, and technical architecture\n2. **Infrastructure Team** (3 meetings) - Capacity planning and migration timeline discussions\n3. **Product Team** (2 meetings) - Q2 roadmap and feature prioritization\n4. **Alex** (2 check-ins) - Project status updates\n\nSarah has been your main collaborator, especially on technical decisions.';
    } else if (lowerQuestion.includes('pattern') || lowerQuestion.includes('repeating')) {
      return 'I notice some recurring patterns in your recent work:\n\n**Repeating Themes:**\n- Capacity constraints frequently come up in planning discussions\n- Authentication and security concerns appear across multiple conversations\n- Timeline pressure vs. quality trade-offs are a common tension\n\n**Recurring Blockers:**\n- Infrastructure team bandwidth mentioned 4 times this week\n- Dependencies on external teams causing delays\n\nConsider addressing the infrastructure capacity issue proactively.';
    } else if (lowerQuestion.includes('contradiction') || lowerQuestion.includes('conflict')) {
      return 'I found a few potential contradictions in recent discussions:\n\n1. **Timeline Conflicts**: You committed to a Q2 delivery in one meeting, but infrastructure team flagged capacity concerns that might push dates\n\n2. **Priority Misalignment**: Product team prioritized new features, but technical discussions focused heavily on migration stability\n\n3. **Resource Allocation**: Multiple teams requesting your time during the same sprint\n\nYou might want to clarify priorities and align stakeholders on realistic timelines.';
    } else if (lowerQuestion.includes('focus') || lowerQuestion.includes('priority')) {
      return 'Based on your recent context, here\'s what deserves your attention:\n\n**Immediate Focus:**\n1. Resolve infrastructure team capacity constraints - this is blocking timeline commitments\n2. Schedule authentication service testing - on critical path\n3. Align with Sarah on migration rollout phases\n\n**This Week:**\n- Finalize Q2 roadmap with clear scope cuts\n- Document migration risks and mitigation strategies\n- Set realistic expectations with stakeholders\n\nThe infrastructure capacity issue appears most urgent.';
    } else if (lowerQuestion.includes('risk') || lowerQuestion.includes('ignoring')) {
      return 'A few risks seem to be under-addressed:\n\n**High Priority Risks:**\n1. **Infrastructure Overload**: Team capacity mentioned repeatedly but no concrete mitigation plan yet\n2. **Authentication Dependencies**: Critical path but testing not scheduled\n3. **Timeline Pressure**: Commitments made before technical feasibility confirmed\n\n**Medium Priority:**\n- Stakeholder alignment on what gets cut vs. delivered\n- Cross-team coordination overhead not factored into estimates\n\nThe infrastructure team bandwidth issue needs immediate attention.';
    } else if (lowerQuestion.includes('summary') || lowerQuestion.includes('summarize')) {
      return 'Based on your memories, here\'s a quick summary:\n\nYou\'ve been deeply involved in planning an API migration, navigating trade-offs between speed and stability. Key collaborators include Sarah (technical lead) and the infrastructure team.\n\n**Progress:** Migration approach defined, phased rollout approved\n**Challenges:** Infrastructure team capacity constraints, authentication testing not yet scheduled\n**Decisions Needed:** Finalize realistic timeline, prioritize Q2 roadmap\n\nYour work centers on balancing stakeholder expectations with technical realities.';
    } else {
      return 'I can help you understand your recent work, identify patterns, clarify decisions, or surface potential risks. What would you like to explore?';
    }
  };

  // Handle initialMessages changes and auto-generate AI response
  useEffect(() => {
    if (initialMessages.length > previousMessagesLengthRef.current) {
      const lastMessage = initialMessages[initialMessages.length - 1];
      
      if (lastMessage && lastMessage.role === 'user') {
        setMessages(initialMessages);
        setIsThinking(true);

        const timeoutId = setTimeout(() => {
          const aiMessage: Message = {
            role: 'assistant',
            content: generateMockAIResponse(lastMessage.content),
            timestamp: 'Just now'
          };
          const updatedMessages = [...initialMessages, aiMessage];
          setMessages(updatedMessages);
          setIsThinking(false);
        }, 1500);

        return () => clearTimeout(timeoutId);
      } else {
        setMessages(initialMessages);
      }
    } else {
      setMessages(initialMessages);
    }
    
    previousMessagesLengthRef.current = initialMessages.length;
  }, [initialMessages]);

  if (!isOpen) return null;

  const handleClose = () => {
    onSaveMessages(messages);
    onClose();
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
    
    setTimeout(() => {
      const transcribedText = "What were the main action items discussed in this conversation?";
      setInputText(transcribedText);
      setIsTranscribing(false);
    }, 2000);
  };

  const handleSend = () => {
    if (!inputText.trim()) return;

    const userMessage: Message = {
      role: 'user',
      content: inputText,
      timestamp: 'Just now'
    };

    const updatedMessages = [...messages, userMessage];
    setMessages(updatedMessages);
    setInputText('');
    setIsThinking(true);

    setTimeout(() => {
      const aiMessage: Message = {
        role: 'assistant',
        content: generateMockAIResponse(inputText),
        timestamp: 'Just now'
      };
      const finalMessages = [...updatedMessages, aiMessage];
      setMessages(finalMessages);
      setIsThinking(false);
    }, 1500);
  };

  const handleSuggestedQuestion = (question: string) => {
    const userMessage: Message = {
      role: 'user',
      content: question,
      timestamp: 'Just now'
    };

    const updatedMessages = [...messages, userMessage];
    setMessages(updatedMessages);
    setIsThinking(true);

    setTimeout(() => {
      const aiMessage: Message = {
        role: 'assistant',
        content: generateMockAIResponse(question),
        timestamp: 'Just now'
      };
      const finalMessages = [...updatedMessages, aiMessage];
      setMessages(finalMessages);
      setIsThinking(false);
    }, 1500);
  };

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] z-[200] flex flex-col">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
        <button 
          onClick={handleClose}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        <h1 className="text-[17px] font-semibold absolute left-1/2 -translate-x-1/2">Ask AI</h1>
        <div className="w-16" />
      </div>

      {/* Memory context banner */}
      <div className="px-5 py-2.5 bg-gradient-to-br from-[#f0f9ff] to-[#e0f2fe] border-b border-[#007aff]/10">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 flex-1 min-w-0">
            <Sparkles className="w-4 h-4 text-[#007aff] flex-shrink-0" />
            <p className="text-[13px] text-[#1c1c1e] truncate">
              <span className="font-medium">About:</span> {memoryTitle}
            </p>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-5 py-4">
        <div className="space-y-4 pb-4">
          {messages.length === 0 && suggestedQuestions && suggestedQuestions.length > 0 && (
            <div className="space-y-2.5">
              <div className="flex items-center gap-2 mb-2">
                <Sparkles className="w-4 h-4 text-[#007aff]" strokeWidth={2} />
                <h3 className="text-[15px] font-semibold text-[#1c1c1e]">Suggested Questions</h3>
              </div>
              <div className="space-y-2">
                {suggestedQuestions.map((question, index) => (
                  <button
                    key={index}
                    onClick={() => handleSuggestedQuestion(question)}
                    disabled={isThinking}
                    className="w-full text-left flex items-start gap-2 py-1 hover:opacity-70 transition-opacity disabled:opacity-40 disabled:cursor-not-allowed group"
                  >
                    <span className="text-[15px] text-[#8e8e93] mt-0.5">•</span>
                    <p className="text-[15px] text-[#007aff] leading-relaxed group-hover:underline">
                      {question}
                    </p>
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map((message, index) => (
            <div
              key={index}
              className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[80%] rounded-2xl px-4 py-3 ${
                  message.role === 'user'
                    ? 'bg-[#007aff] text-white'
                    : 'bg-white border border-[#e5e5ea] text-[#1c1c1e]'
                }`}
              >
                {message.role === 'assistant' && (
                  <div className="flex items-center gap-1.5 mb-2">
                    <Sparkles className="w-3.5 h-3.5 text-[#34c759]" />
                    <span className="text-[11px] font-semibold uppercase tracking-wide text-[#8e8e93]">
                      AI
                    </span>
                  </div>
                )}
                <p className="text-[15px] leading-relaxed whitespace-pre-wrap">
                  {message.content}
                </p>
              </div>
            </div>
          ))}

          {isThinking && (
            <div className="flex justify-start">
              <div className="bg-white border border-[#e5e5ea] rounded-2xl px-4 py-3">
                <div className="flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-[#34c759] animate-pulse" />
                  <div className="flex items-center gap-1">
                    <div className="w-2 h-2 rounded-full bg-[#8e8e93] animate-bounce" style={{ animationDelay: '0ms' }}></div>
                    <div className="w-2 h-2 rounded-full bg-[#8e8e93] animate-bounce" style={{ animationDelay: '150ms' }}></div>
                    <div className="w-2 h-2 rounded-full bg-[#8e8e93] animate-bounce" style={{ animationDelay: '300ms' }}></div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Input area */}
      <div className="px-5 py-4 bg-white border-t border-black/[0.06]">
        {!isRecording && !isTranscribing ? (
          <div className="flex gap-2">
            <textarea
              ref={inputRef}
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  handleSend();
                }
              }}
              placeholder="Ask AI anything about this memory..."
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
              disabled={isThinking}
            />
            <button
              className="bg-[#f2f2f7] text-[#1c1c1e] rounded-xl px-4 py-3 font-medium text-[15px] hover:bg-[#e5e5ea] transition-colors disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center"
              disabled={isThinking}
              onClick={handleStartRecording}
            >
              <Mic className="w-4.5 h-4.5" />
            </button>
            <button
              onClick={handleSend}
              disabled={!inputText.trim() || isThinking}
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
    </div>
  );
}