import { Sparkles, Send, Mic, Briefcase, Lightbulb, Code, Heart, RotateCcw, Link2, Compass, Menu, X, ArrowUp, Bot } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';
import { ConversationsPanel } from './ConversationsPanel';
import { ChatView } from './ChatView';
import { ExpertChatView } from './ExpertChatView';
import { AIChatModal } from './AIChatModal';
import { ErrorState } from './ErrorState';
import { useDevMode } from '../contexts/DevModeContext';

type ViewType = 'main' | 'recall' | 'connect' | 'decide';
type ExpertType = 'Business' | 'Creative' | 'Execution' | 'Wellness';

export function AskAITab() {
  const { devMode } = useDevMode();
  const [currentView, setCurrentView] = useState<ViewType>('main');
  const [showConversations, setShowConversations] = useState(false);
  const [activeChatId, setActiveChatId] = useState<string | null>(null);
  const [activeChatTitle, setActiveChatTitle] = useState<string>('');
  const [activeExpert, setActiveExpert] = useState<ExpertType | null>(null);
  const [isExpertFromHistory, setIsExpertFromHistory] = useState(false); // Track if expert opened from history
  const [inputValue, setInputValue] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const [showAIChatModal, setShowAIChatModal] = useState(false);
  const [initialQuestion, setInitialQuestion] = useState('');
  const inputRef = useRef<HTMLTextAreaElement>(null);
  
  // Auto-resize textarea when inputValue changes
  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.style.height = 'auto';
      inputRef.current.style.height = Math.min(inputRef.current.scrollHeight, 120) + 'px';
    }
  }, [inputValue]);
  
  // Load chat messages from localStorage
  const [chatMessages, setChatMessages] = useState<any[]>(() => {
    const stored = localStorage.getItem('ask-ai-general-chat');
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch (e) {
        return [];
      }
    }
    return [];
  });

  const handleOpenConversation = (conversationId: string, title: string) => {
    console.log('handleOpenConversation called with id:', conversationId, 'title:', title);
    console.log('Setting activeChatId to:', conversationId);
    console.log('Setting showConversations to false');
    setActiveChatId(conversationId);
    setActiveChatTitle(title);
    setShowConversations(false);
    setActiveExpert(null);
    console.log('State updates queued - will render ChatView on next render');
  };

  const handleCloseChat = () => {
    console.log('handleCloseChat called');
    console.log('Before setState - activeChatId:', activeChatId);
    setActiveChatId(null);
    setActiveChatTitle('');
    console.log('After setState called (will update on next render)');
  };

  const handleOpenExpert = (expert: ExpertType, fromHistory: boolean = false) => {
    console.log('handleOpenExpert called with:', expert, fromHistory);
    setActiveExpert(expert);
    setIsExpertFromHistory(fromHistory);
    setShowConversations(false);
  };

  const handleCloseExpert = () => {
    console.log('handleCloseExpert called');
    console.log('Before setState - activeExpert:', activeExpert);
    setActiveExpert(null);
    setIsExpertFromHistory(false);
    console.log('After setState called (will update on next render)');
  };

  const handleSend = () => {
    if (!inputValue.trim()) return;
    
    // Add the question as the first message
    const userMessage = {
      role: 'user' as const,
      content: inputValue,
      timestamp: 'Just now'
    };
    
    const updatedMessages = [...chatMessages, userMessage];
    setChatMessages(updatedMessages);
    
    // Open AI Chat Modal
    setShowAIChatModal(true);
    setInputValue('');
  };

  const handleQuestionClick = (question: string) => {
    // Add the question as the first message
    const userMessage = {
      role: 'user' as const,
      content: question,
      timestamp: 'Just now'
    };
    
    const updatedMessages = [...chatMessages, userMessage];
    setChatMessages(updatedMessages);
    
    // Open AI Chat Modal with this question
    setShowAIChatModal(true);
  };

  const recallPrompts = [
    'What have I been working on recently?',
    'What decisions did I make this week?',
    'Who have I been talking with most?'
  ];

  const connectPrompts = [
    'What problems keep repeating?',
    'Are there contradictions in discussions?',
    'What ideas connect across meetings?',
    'What decisions conflict with each other?',
    'What themes show up across teams?'
  ];

  const decidePrompts = [
    'What should I focus on today?',
    'What risks am I ignoring?',
    'What will break if decisions are delayed?',
    'What tasks need attention soon?',
    'What deserves priority this week?'
  ];

  const experts: { id: number, name: ExpertType, icon: any, color: string }[] = [
    { id: 1, name: 'Business', icon: Briefcase, color: 'bg-primary/10 text-primary' },
    { id: 2, name: 'Creative', icon: Lightbulb, color: 'bg-accent/10 text-accent' },
    { id: 3, name: 'Execution', icon: Code, color: 'bg-primary/10 text-primary' },
    { id: 4, name: 'Wellness', icon: Heart, color: 'bg-accent/10 text-accent' }
  ];

  // Handle Error State
  if (devMode === 'error') {
    return (
      <div className="flex flex-col h-full">
        <div className="px-5 pt-5 pb-3">
          <div className="flex items-start justify-between mb-1">
            <button 
              onClick={() => setCurrentView('main')}
              className="flex items-center gap-2 hover:opacity-70 transition-opacity"
            >
              <div className="w-10 h-10 rounded-full bg-accent/10 flex items-center justify-center">
                <Sparkles className="w-5 h-5 text-accent" />
              </div>
              <h1>Ask AI</h1>
            </button>
          </div>
        </div>
        <ErrorState
          title="AI service unavailable"
          description="Please try again later."
          onRetry={() => {
            console.log('Retry clicked');
          }}
        />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="px-5 pt-5 pb-3">
        <div className="flex items-start justify-between mb-1">
          <button 
            onClick={() => setCurrentView('main')}
            className="flex items-center gap-2 hover:opacity-70 transition-opacity"
          >
            <div className="w-10 h-10 rounded-full bg-accent/10 flex items-center justify-center">
              <Sparkles className="w-5 h-5 text-accent" />
            </div>
            <h1>Ask AI</h1>
          </button>
          
          {/* Conversations Button */}
          <button 
            onClick={() => setShowConversations(true)}
            className="w-9 h-9 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] hover:bg-[#f2f2f7] rounded-lg transition-all mt-1"
            aria-label="Conversations"
          >
            <Menu className="w-5 h-5" strokeWidth={2} />
          </button>
        </div>
        <p className="text-sm text-muted-foreground">Understand your memories and decide what matters</p>
      </div>

      {/* Main content area */}
      <div className="flex-1 px-5 pb-3 overflow-hidden">
        
        {/* Main View */}
        {currentView === 'main' && (
          <div className="space-y-3">
            {/* Recall card */}
            <button
              onClick={() => setCurrentView('recall')}
              className="w-full text-left bg-gradient-to-br from-blue-50/50 to-transparent rounded-xl p-4 shadow-sm border border-blue-100/50 hover:shadow-md transition-shadow"
            >
              <div className="flex items-center gap-2 mb-1.5">
                <RotateCcw className="w-4 h-4 text-blue-600/70" />
                <h4 className="text-[14px] font-semibold text-blue-900/90">Recall recent context</h4>
              </div>
              <p className="text-[13px] text-blue-900/60 pl-6">Remember what you've been discussing</p>
            </button>

            {/* Connect card */}
            <button
              onClick={() => setCurrentView('connect')}
              className="w-full text-left bg-gradient-to-br from-purple-50/50 to-transparent rounded-xl p-4 shadow-sm border border-purple-100/50 hover:shadow-md transition-shadow"
            >
              <div className="flex items-center gap-2 mb-1.5">
                <Link2 className="w-4 h-4 text-purple-600/70" />
                <h4 className="text-[14px] font-semibold text-purple-900/90">Connect patterns & signals</h4>
              </div>
              <p className="text-[13px] text-purple-900/60 pl-6">See connections across conversations</p>
            </button>

            {/* Decide card */}
            <button
              onClick={() => setCurrentView('decide')}
              className="w-full text-left bg-gradient-to-br from-amber-50/50 to-transparent rounded-xl p-4 shadow-sm border border-amber-100/50 hover:shadow-md transition-shadow"
            >
              <div className="flex items-center gap-2 mb-1.5">
                <Compass className="w-4 h-4 text-amber-600/70" />
                <h4 className="text-[14px] font-semibold text-amber-900/90">Decide what matters next</h4>
              </div>
              <p className="text-[13px] text-amber-900/60 pl-6">Figure out what deserves attention now</p>
            </button>
          </div>
        )}

        {/* Recall View */}
        {currentView === 'recall' && (
          <div className="space-y-4">
            <div className="border-b border-border pb-3">
              <h3 className="text-[15px] font-semibold text-foreground">Recall recent context</h3>
            </div>
            <div className="space-y-2.5">
              {recallPrompts.map((prompt, index) => (
                <button
                  key={index}
                  onClick={() => handleQuestionClick(prompt)}
                  className="block w-full text-left text-[15px] text-foreground/70 hover:text-foreground hover:underline transition-colors pl-1"
                >
                  • {prompt}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Connect View */}
        {currentView === 'connect' && (
          <div className="space-y-4">
            <div className="border-b border-border pb-3">
              <h3 className="text-[15px] font-medium text-foreground leading-relaxed">
                See connections across conversations<br />and recurring signals.
              </h3>
            </div>
            <div className="space-y-2.5">
              {connectPrompts.map((prompt, index) => (
                <button
                  key={index}
                  onClick={() => handleQuestionClick(prompt)}
                  className="block w-full text-left text-[15px] text-foreground/70 hover:text-foreground hover:underline transition-colors pl-1"
                >
                  • {prompt}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Decide View */}
        {currentView === 'decide' && (
          <div className="space-y-4">
            <div className="border-b border-border pb-3">
              <h3 className="text-[15px] font-medium text-foreground">Figure out what deserves attention now.</h3>
            </div>
            <div className="space-y-2.5">
              {decidePrompts.map((prompt, index) => (
                <button
                  key={index}
                  onClick={() => handleQuestionClick(prompt)}
                  className="block w-full text-left text-[15px] text-foreground/70 hover:text-foreground hover:underline transition-colors pl-1"
                >
                  • {prompt}
                </button>
              ))}
            </div>
          </div>
        )}

      </div>

      {/* Chat input - Fixed at bottom */}
      <div className="px-5 pb-5 pt-2 bg-background border-t border-border">
        {!isRecording && !isTranscribing ? (
          <>
            <div className="flex gap-2 items-end">
              <textarea
                ref={inputRef}
                placeholder="Ask about your memories..."
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleSend();
                  }
                }}
                rows={1}
                className="flex-1 px-3.5 py-2.5 text-[15px] bg-card rounded-xl border border-border focus:outline-none focus:ring-2 focus:ring-ring resize-none overflow-hidden"
                style={{ 
                  minHeight: '40px',
                  maxHeight: '120px'
                }}
                onInput={(e) => {
                  const target = e.target as HTMLTextAreaElement;
                  target.style.height = 'auto';
                  target.style.height = Math.min(target.scrollHeight, 120) + 'px';
                }}
                onFocus={() => currentView !== 'main' && setCurrentView('main')}
              />
              <button 
                onClick={() => setIsRecording(true)}
                className="p-2.5 bg-muted rounded-xl hover:bg-secondary transition-colors"
              >
                <Mic className="w-4.5 h-4.5 text-foreground" />
              </button>
              <button 
                disabled={!inputValue.trim()}
                className="p-2.5 bg-primary text-primary-foreground rounded-xl hover:bg-primary/90 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
                onClick={handleSend}
              >
                <Send className="w-4.5 h-4.5" />
              </button>
            </div>
          </>
        ) : isRecording ? (
          <>
            <p className="text-[13px] text-muted-foreground mb-2">Recording...</p>
            {/* Compact waveform matching AIChatModal */}
            <div className="flex items-center gap-3">
              <button 
                onClick={() => {
                  setIsRecording(false);
                  setInputValue('');
                }}
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
                onClick={() => {
                  setIsRecording(false);
                  setIsTranscribing(true);
                  setTimeout(() => {
                    const transcribedText = "What patterns should I pay attention to this week?";
                    setInputValue(transcribedText);
                    setIsTranscribing(false);
                  }, 2000);
                }}
                className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors flex-shrink-0"
              >
                <ArrowUp className="w-5 h-5 text-white" strokeWidth={2.5} />
              </button>
            </div>
          </>
        ) : (
          <>
            <p className="text-[13px] text-muted-foreground mb-2">Transcribing...</p>
            <div className="flex items-center gap-2.5 px-4 py-3 bg-[#f2f2f7] rounded-xl">
              <div className="flex items-center gap-1">
                <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '0ms' }}></div>
                <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '150ms' }}></div>
                <div className="w-1.5 h-1.5 rounded-full bg-[#007aff] animate-bounce" style={{ animationDelay: '300ms' }}></div>
              </div>
              <span className="text-[15px] text-[#8e8e93]">Transcribing...</span>
            </div>
          </>
        )}
      </div>

      {/* Conversations Panel */}
      <ConversationsPanel 
        isOpen={showConversations} 
        onClose={() => setShowConversations(false)} 
        onOpenConversation={handleOpenConversation}
        onOpenExpert={handleOpenExpert}
      />

      {/* Chat View */}
      {activeChatId && (
        <ChatView
          chatId={activeChatId}
          title={activeChatTitle}
          onClose={handleCloseChat}
        />
      )}

      {/* Expert Chat View */}
      {activeExpert && (
        <ExpertChatView
          expert={activeExpert}
          onClose={handleCloseExpert}
          isFromHistory={isExpertFromHistory}
        />
      )}

      {/* AI Chat Modal */}
      {showAIChatModal && (
        <AIChatModal
          isOpen={showAIChatModal}
          onClose={() => {
            setShowAIChatModal(false);
            setInitialQuestion('');
          }}
          initialMessages={chatMessages}
          onSaveMessages={(messages) => {
            setChatMessages(messages);
            localStorage.setItem('ask-ai-general-chat', JSON.stringify(messages));
          }}
          memoryTitle="Ask AI"
          suggestedQuestions={
            chatMessages.length === 0 && !initialQuestion
              ? [
                  'What patterns are emerging in my work?',
                  'What should I focus on this week?',
                  'Help me understand recent conversations',
                  'What decisions need my attention?'
                ]
              : undefined
          }
        />
      )}
    </div>
  );
}