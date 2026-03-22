import { ChevronLeft, Search, Sparkles, X } from 'lucide-react';
import { useState } from 'react';
import { useDevMode } from '../contexts/DevModeContext';

interface Person {
  id: string;
  name: string;
  memoryCount: number;
  lastTalked: string;
  isRecent?: boolean;
}

interface AllPeopleByLetter {
  [letter: string]: Person[];
}

interface PeoplePageProps {
  onBack: () => void;
  onPersonClick?: (personId: string) => void;
  hideHeader?: boolean; // New prop to hide header when embedded in tab
}

export function PeoplePage({ onBack, onPersonClick, hideHeader = false }: PeoplePageProps) {
  const { devMode } = useDevMode();
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [isGeneratingPersonMemory, setIsGeneratingPersonMemory] = useState(false);
  const [selectedPersonName, setSelectedPersonName] = useState('');

  // Mock data
  const recentlyMentioned: Person[] = [
    { id: '1', name: 'Alex', memoryCount: 3, lastTalked: 'today', isRecent: true },
    { id: '2', name: 'Sarah', memoryCount: 2, lastTalked: 'yesterday', isRecent: true },
    { id: '3', name: 'Jordan', memoryCount: 5, lastTalked: 'today', isRecent: true },
    { id: '4', name: 'Emily', memoryCount: 1, lastTalked: 'today', isRecent: true },
  ];

  const allPeople: AllPeopleByLetter = {
    A: [
      { id: '5', name: 'Alex', memoryCount: 3, lastTalked: 'Jan 21' },
      { id: '6', name: 'Amy', memoryCount: 1, lastTalked: 'Jan 10' },
    ],
    D: [
      { id: '7', name: 'David', memoryCount: 4, lastTalked: 'Jan 20' },
      { id: '8', name: 'Daniel', memoryCount: 2, lastTalked: 'Jan 19' },
    ],
    E: [
      { id: '9', name: 'Emily', memoryCount: 1, lastTalked: 'Today' },
    ],
    J: [
      { id: '10', name: 'Jordan', memoryCount: 5, lastTalked: 'Today' },
      { id: '11', name: 'James', memoryCount: 3, lastTalked: 'Jan 16' },
    ],
    L: [
      { id: '12', name: 'Lisa', memoryCount: 3, lastTalked: 'Jan 18' },
    ],
    M: [
      { id: '13', name: 'Michael', memoryCount: 7, lastTalked: 'Jan 21' },
    ],
    S: [
      { id: '14', name: 'Sarah', memoryCount: 8, lastTalked: 'Jan 22' },
    ],
  };

  const formatMemoryCount = (count: number) => {
    return count === 1 ? '1 memory' : `${count} memories`;
  };

  const handlePersonClick = (personName: string) => {
    // Show generating animation
    setSelectedPersonName(personName);
    setIsGeneratingPersonMemory(true);
    
    // After 3 seconds, navigate to person detail
    setTimeout(() => {
      setIsGeneratingPersonMemory(false);
      if (onPersonClick) {
        onPersonClick(personName);
      }
    }, 3000);
  };

  const handleCancelGeneration = () => {
    setIsGeneratingPersonMemory(false);
    setSelectedPersonName('');
  };
  
  return (
    <div className={hideHeader ? "flex flex-col h-full" : "fixed inset-0 bg-[#f2f2f7] z-50 flex flex-col"}>
      {/* Header */}
      {!hideHeader && (
        <>
          <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
            <div className="flex items-center gap-3">
              <button 
                onClick={onBack}
                className="flex items-center gap-1 text-[#007aff] hover:opacity-70 transition-opacity"
              >
                <ChevronLeft className="w-7 h-7" strokeWidth={2} />
                <span className="text-[17px] font-semibold">People</span>
              </button>
            </div>
            
            {/* Search button */}
            <button
              onClick={() => setShowSearch(!showSearch)}
              className="text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <Search className="w-5 h-5" strokeWidth={2} />
            </button>
          </div>

          {/* Search bar - expandable */}
          {showSearch && (
            <div className="px-5 py-3 bg-white border-b border-black/[0.06]">
              <div className="flex items-center gap-2 bg-[#f2f2f7] rounded-[10px] px-3 py-2">
                <Search className="w-4 h-4 text-[#8e8e93]" />
                <input
                  type="text"
                  placeholder="Search people..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="flex-1 bg-transparent text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] outline-none"
                  autoFocus
                />
                <button
                  onClick={() => setShowSearch(false)}
                  className="text-[#8e8e93] hover:opacity-70 transition-opacity"
                >
                  <X className="w-4 h-4" strokeWidth={2} />
                </button>
              </div>
            </div>
          )}
        </>
      )}

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto bg-[#f2f2f7]">
        {devMode === 'empty' ? (
          // Empty state - no people yet
          <div className="flex flex-col items-center justify-center py-20 px-5">
            <p className="text-[15px] text-[#8e8e93] text-center">
              No people yet
            </p>
            <p className="text-[14px] text-[#8e8e93] text-center mt-2">
              Label speakers from your recordings and they'll appear here.
            </p>
          </div>
        ) : (
          <>
            {/* Recently mentioned section - with elevated card design */}
            <div className="pt-5 pb-4 px-5">
              <div className="mb-3">
                <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">Recently mentioned</h2>
              </div>
              
              {/* Elevated white card with stronger shadow */}
              <div className="bg-white rounded-[16px] shadow-md border border-black/[0.08] overflow-hidden">
                {recentlyMentioned.map((person, index) => (
                  <button
                    key={person.id}
                    onClick={() => handlePersonClick(person.name)}
                    className={`w-full px-4 py-3 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors text-left ${
                      index < recentlyMentioned.length - 1 ? 'border-b border-black/[0.06]' : ''
                    }`}
                  >
                    <div className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">
                      {person.name}
                    </div>
                    <div className="text-[14px] text-[#8e8e93]">
                      Last talked {person.lastTalked} · {formatMemoryCount(person.memoryCount)}
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* All people section - same card style as recently mentioned */}
            <div className="px-5 pb-4">
              <div className="mb-3">
                <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">All people</h2>
              </div>
              
              {/* White card with same width and shape */}
              <div className="bg-white rounded-[16px] shadow-sm border border-black/[0.06] overflow-hidden">
                {Object.keys(allPeople).sort().map((letter, letterIndex) => (
                  <div key={letter}>
                    {/* Letter header */}
                    <div className={`px-5 py-2 bg-[#f9f9f9] ${letterIndex > 0 ? 'border-t border-black/[0.06]' : ''}`}>
                      <div className="text-[14px] font-semibold text-[#8e8e93] uppercase tracking-wider">
                        {letter}
                      </div>
                    </div>
                    
                    {/* People under this letter */}
                    {allPeople[letter].map((person, personIndex) => (
                      <button
                        key={person.id}
                        onClick={() => handlePersonClick(person.name)}
                        className="w-full px-5 py-2.5 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors text-left border-b border-black/[0.04] last:border-b-0"
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-[16px] text-[#1c1c1e]">{person.name}</span>
                          <span className="text-[14px] text-[#8e8e93]">
                            · {person.lastTalked} · {person.memoryCount}
                          </span>
                        </div>
                      </button>
                    ))}
                  </div>
                ))}
              </div>
            </div>

            {/* Bottom hint - on background, not in card */}
            <div className="px-5 pb-8 text-center">
              <p className="text-[14px] text-[#8e8e93] leading-relaxed">
                You can label speakers from your recordings.
                <br />
                Newly identified people will appear here.
              </p>
            </div>

            {/* Bottom spacing for safe area */}
            <div className="h-8" />
          </>
        )}
      </div>

      {/* People Memory Generating Animation Overlay */}
      {isGeneratingPersonMemory && (
        <div className="fixed inset-0 bg-[#f2f2f7] z-[100] flex flex-col">
          {/* Header with back and close buttons */}
          <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
            <button 
              onClick={handleCancelGeneration}
              className="flex items-center gap-1 text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <ChevronLeft className="w-7 h-7" strokeWidth={2} />
              <span className="text-[17px] font-semibold">{selectedPersonName}</span>
            </button>
            
            <button
              onClick={handleCancelGeneration}
              className="text-[#8e8e93] hover:opacity-70 transition-opacity"
            >
              <X className="w-6 h-6" strokeWidth={2} />
            </button>
          </div>

          {/* Animation content */}
          <div className="flex-1 flex flex-col items-center justify-center px-5">
            <div className="flex flex-col items-center justify-center text-center">
              {/* Animated Sparkles Icon */}
              <div className="relative mb-6">
                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#007aff]/20 to-[#007aff]/10 flex items-center justify-center animate-pulse">
                  <Sparkles className="w-10 h-10 text-[#007aff]" />
                </div>
                {/* Rotating ring */}
                <div className="absolute inset-0 rounded-full border-2 border-transparent border-t-[#007aff] animate-spin"></div>
              </div>

              {/* Main heading */}
              <h3 className="text-[22px] font-bold mb-2 text-[#1c1c1e]">
                Loading {selectedPersonName}'s memories
              </h3>
              
              {/* Subtext */}
              <p className="text-[15px] text-[#8e8e93] max-w-sm leading-[1.4] mb-8">
                Gathering conversations and insights...
              </p>

              {/* Progress steps */}
              <div className="w-full max-w-xs space-y-3">
                <ProgressStep 
                  icon="🔍" 
                  text="Finding related memories" 
                  status="in-progress" 
                />
                <ProgressStep 
                  icon="🧠" 
                  text="Analyzing conversations" 
                  status="in-progress" 
                />
                <ProgressStep 
                  icon="📊" 
                  text="Building timeline" 
                  status="in-progress" 
                />
              </div>

              {/* Estimated time */}
              <div className="mt-8 px-4 py-2.5 bg-white rounded-[12px] border border-black/[0.06]">
                <p className="text-[13px] text-[#8e8e93]">
                  This usually takes <span className="font-medium text-[#1c1c1e]">a few seconds</span>
                </p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Progress Step Component
interface ProgressStepProps {
  icon: string;
  text: string;
  status: 'completed' | 'in-progress' | 'pending';
}

function ProgressStep({ icon, text, status }: ProgressStepProps) {
  const getStatusClass = () => {
    switch (status) {
      case 'completed':
        return 'bg-[#34c759]';
      case 'in-progress':
        return 'bg-[#007aff] animate-pulse';
      case 'pending':
        return 'bg-[#e5e5ea]';
    }
  };

  const getTextClass = () => {
    switch (status) {
      case 'completed':
        return 'text-[#1c1c1e]';
      case 'in-progress':
        return 'text-[#1c1c1e] font-medium';
      case 'pending':
        return 'text-[#8e8e93]';
    }
  };

  return (
    <div className="flex items-center gap-3">
      <div className={`w-8 h-8 rounded-full ${getStatusClass()} flex items-center justify-center flex-shrink-0`}>
        {status === 'completed' ? (
          <svg className="w-4 h-4 text-white" viewBox="0 0 16 16" fill="none">
            <path d="M13 4L6 11L3 8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        ) : (
          <span className="text-[14px]">{icon}</span>
        )}
      </div>
      <p className={`text-[15px] leading-[1.3] ${getTextClass()}`}>
        {text}
      </p>
    </div>
  );
}