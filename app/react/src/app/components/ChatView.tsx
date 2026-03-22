import { ChevronLeft, Mic, Send, Sparkles } from 'lucide-react';
import { useState } from 'react';

interface ChatViewProps {
  chatId: string;
  title: string;
  onClose: () => void;
}

interface Message {
  id: string;
  sender: 'user' | 'ai';
  text: string;
}

export function ChatView({ chatId, title, onClose }: ChatViewProps) {
  const [inputValue, setInputValue] = useState('');
  
  // Debug: Log when component renders
  console.log('ChatView rendered with chatId:', chatId, 'title:', title);
  
  const handleBackClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    console.log('Back button clicked - calling onClose');
    onClose();
  };
  
  // Sample conversation data
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      sender: 'user',
      text: 'What risks do you see?',
    },
    {
      id: '2',
      sender: 'ai',
      text: 'Bandwidth risk appears to be the primary concern here. Your team is already at capacity with the current platform, and migrating to a new API while maintaining existing features could stretch resources thin. I\'d also flag the client dependency risk - any downtime during migration could impact key accounts.',
    },
    {
      id: '3',
      sender: 'user',
      text: 'Switch to Execution perspective',
    },
    {
      id: '4',
      sender: 'ai',
      text: 'Delivery risks appear significant. The migration timeline overlaps with Q4 feature commitments, creating a potential bottleneck. Testing coverage is another concern - you\'ll need parallel environments running to ensure zero data loss. I\'d recommend breaking this into smaller sprints with clear rollback points.',
    },
  ]);

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

    // Simulate AI response (in real app, this would be an API call)
    setTimeout(() => {
      const aiResponse: Message = {
        id: (Date.now() + 1).toString(),
        sender: 'ai',
        text: `I'm analyzing your question... ${inputValue}`,
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

        {/* About section */}
        <div className="px-5 py-2.5 bg-gradient-to-br from-[#f0f9ff] to-[#e0f2fe] border-t border-[#007aff]/10">
          <div className="flex items-center gap-3">
            {/* About Section */}
            <div className="flex items-center gap-2 flex-1 min-w-0">
              <Sparkles className="w-4 h-4 text-[#007aff] flex-shrink-0" />
              <p className="text-[13px] text-[#1c1c1e] truncate">
                <span className="font-medium">About:</span> {title}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto px-4 py-4">
        <div className="space-y-4 max-w-2xl mx-auto">
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
                  <div className="bg-[#f2f2f7] text-[#1c1c1e] px-4 py-2.5 rounded-[18px] max-w-[85%]">
                    <p className="text-[15px] leading-relaxed">{message.text}</p>
                  </div>
                </div>
              )}
            </div>
          ))}
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
          />
          <button className="w-9 h-9 flex items-center justify-center bg-[#f2f2f7] text-[#8e8e93] rounded-full hover:bg-[#e5e5ea] transition-colors flex-shrink-0">
            <Mic className="w-4.5 h-4.5" strokeWidth={2} />
          </button>
          <button
            onClick={handleSend}
            className="w-9 h-9 flex items-center justify-center bg-[#007aff] text-white rounded-full hover:bg-[#0051d5] transition-colors flex-shrink-0 disabled:opacity-50"
            disabled={!inputValue.trim()}
          >
            <Send className="w-4.5 h-4.5" strokeWidth={2} />
          </button>
        </div>
      </div>
    </div>
  );
}