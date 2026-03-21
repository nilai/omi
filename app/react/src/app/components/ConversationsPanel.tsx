import { X, Plus, Search, Briefcase, Lightbulb, Code, Heart } from 'lucide-react';

interface ConversationsPanelProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenConversation: (conversationId: string, title: string) => void;
  onOpenExpert: (expert: 'Business' | 'Creative' | 'Execution' | 'Wellness', fromHistory?: boolean) => void;
}

interface Conversation {
  id: string;
  title: string;
  expert: 'Business' | 'Creative' | 'Execution' | 'Wellness';
  timestamp: string;
}

export function ConversationsPanel({ isOpen, onClose, onOpenConversation, onOpenExpert }: ConversationsPanelProps) {
  const recentConversations: Conversation[] = [
    { id: '1', title: 'API migration discussion', expert: 'Business', timestamp: 'Today' },
    { id: '2', title: 'Product positioning rethink', expert: 'Creative', timestamp: 'Yesterday' },
    { id: '3', title: 'Hiring and team bandwidth', expert: 'Execution', timestamp: 'Yesterday' },
    { id: '4', title: 'Q4 revenue forecasting', expert: 'Business', timestamp: '2 days ago' },
    { id: '5', title: 'Brand identity refresh', expert: 'Creative', timestamp: '3 days ago' },
    { id: '6', title: 'Sprint planning issues', expert: 'Execution', timestamp: '4 days ago' },
    { id: '7', title: 'Customer feedback analysis', expert: 'Business', timestamp: '5 days ago' },
    { id: '8', title: 'Work-life balance strategies', expert: 'Wellness', timestamp: '6 days ago' },
  ];

  const experts = [
    { id: '1', name: 'Business', icon: Briefcase, color: 'bg-[#007aff] text-white' },
    { id: '2', name: 'Creative', icon: Lightbulb, color: 'bg-[#ff9500] text-white' },
    { id: '3', name: 'Execution', icon: Code, color: 'bg-[#ff3b30] text-white' },
    { id: '4', name: 'Wellness', icon: Heart, color: 'bg-[#4cd964] text-white' },
  ];

  return (
    <>
      {/* Backdrop */}
      <div 
        className={`fixed inset-0 bg-black/40 transition-opacity duration-300 z-40 ${ 
          isOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'
        }`}
        onClick={onClose}
      />

      {/* Panel */}
      <div 
        className={`fixed top-0 right-0 h-full w-2/3 bg-white shadow-[-4px_0_24px_rgba(0,0,0,0.15)] transition-transform duration-300 ease-out z-50 flex flex-col ${ 
          isOpen ? 'translate-x-0' : 'translate-x-full'
        }`}
        style={{ pointerEvents: isOpen ? 'auto' : 'none' }}
      >
        {/* Header - All in one row */}
        <div className="flex-shrink-0 px-4 pt-4 pb-4 border-b border-black/[0.06]">
          <div className="flex items-center gap-2">
            {/* New Conversation Icon Button - Left */}
            <button className="w-9 h-9 flex items-center justify-center bg-[#007aff] text-white rounded-lg hover:bg-[#0051d5] transition-colors shadow-sm flex-shrink-0">
              <Plus className="w-5 h-5" strokeWidth={2.5} />
            </button>
            
            {/* Search Bar - Middle */}
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#8e8e93]" strokeWidth={2} />
              <input
                type="text"
                placeholder="Search"
                className="w-full pl-9 pr-3 py-2 bg-[#f2f2f7] rounded-lg text-[14px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:ring-2 focus:ring-[#007aff]/20 transition-all"
              />
            </div>
            
            {/* Close Button - Right */}
            <button 
              onClick={onClose}
              className="w-9 h-9 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] transition-colors flex-shrink-0"
            >
              <X className="w-5 h-5" strokeWidth={2.5} />
            </button>
          </div>
        </div>

        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto">
          
          {/* Recent Conversations Section */}
          <div className="py-3">
            <h3 className="px-4 text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2">
              Recent conversations
            </h3>
            
            <div className="space-y-0.5">
              {recentConversations.map((conv) => (
                <button
                  key={conv.id}
                  className="w-full px-4 py-2.5 hover:bg-[#f2f2f7] transition-colors text-left"
                  onClick={() => onOpenConversation(conv.id, conv.title)}
                >
                  <h4 className="text-[15px] text-[#1c1c1e] line-clamp-1">
                    {conv.title}
                  </h4>
                </button>
              ))}
            </div>
          </div>

          {/* Bottom spacing - Room for future conversations */}
          <div className="h-32" />
        </div>
      </div>
    </>
  );
}