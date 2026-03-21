import { ChevronLeft, Sparkles, Mic, ArrowUp, ChevronRight, X } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';

interface ProjectAskAIViewProps {
  projectName: string;
  onClose: () => void;
}

export function ProjectAskAIView({ projectName, onClose }: ProjectAskAIViewProps) {
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
        text: `Based on your project "${projectName}", I can help you understand progress, priorities, risks, and next steps...`,
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
      const transcribedText = `What matters most in ${projectName} right now?`;
      setInputValue(transcribedText);
      setIsTranscribing(false);
    }, 1500);
  };

  const handleCancelRecording = () => {
    setIsRecording(false);
  };

  const suggestedQuestions = [
    `What matters most in this project right now?`,
    `What should we prioritize in this project?`,
    `What risks are emerging in this project?`,
    `What decisions have been made recently?`,
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
        text: `Let me analyze "${projectName}" to answer that...`,
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
                <span className="font-medium">About:</span> {projectName}
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
                placeholder={`Ask about ${projectName}...`}
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
