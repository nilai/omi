import { Mic, FileText, Sparkles, User, Search, Calendar, Users, FolderOpen } from 'lucide-react';
import { useState } from 'react';

type BrowseMode = 'time' | 'people' | 'collections';

export function MemoryTabPreview() {
  const [browseMode, setBrowseMode] = useState<BrowseMode>('time');
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Mock data for different browse modes
  const mockTimeMemories = [
    {
      id: 1,
      title: 'Team standup discussion',
      date: 'Today, 10:30 AM',
      hasAudio: true,
      hasSummary: true,
    },
    {
      id: 2,
      title: 'Project planning meeting',
      date: 'Yesterday, 3:45 PM',
      hasAudio: true,
      hasSummary: true,
    },
  ];

  const mockPeople = [
    { id: 1, name: 'Alex', memoryCount: 3, lastTalked: 'today' },
    { id: 2, name: 'Sarah', memoryCount: 2, lastTalked: 'yesterday' },
    { id: 3, name: 'Jordan', memoryCount: 5, lastTalked: 'today' },
  ];

  const mockCollections = [
    { id: 1, name: 'Work Projects', count: 12, icon: '💼', color: '#007aff' },
    { id: 2, name: 'Personal Ideas', count: 8, icon: '💡', color: '#34c759' },
    { id: 3, name: 'Meeting Notes', count: 15, icon: '📝', color: '#ff9500' },
  ];

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-black/[0.06]">
        <div className="px-5 pt-3 pb-2 flex items-center justify-between">
          <h1 className="text-[28px] font-bold text-[#1c1c1e]">Memory</h1>
          
          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowSearch(!showSearch)}
              className="text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <Search className="w-5 h-5" strokeWidth={2} />
            </button>
            <button className="text-[#007aff] hover:opacity-70 transition-opacity">
              <Calendar className="w-5 h-5" strokeWidth={2} />
            </button>
          </div>
        </div>

        {/* Search bar - expandable */}
        {showSearch && (
          <div className="px-5 pb-3">
            <div className="flex items-center gap-2 bg-[#f2f2f7] rounded-[10px] px-3 py-2">
              <Search className="w-4 h-4 text-[#8e8e93]" />
              <input
                type="text"
                placeholder="Search memories..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="flex-1 bg-transparent text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] outline-none"
                autoFocus
              />
            </div>
          </div>
        )}

        {/* Tab buttons */}
        <div className="px-5 pb-3">
          <div className="flex gap-2">
            <button
              onClick={() => setBrowseMode('time')}
              className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                browseMode === 'time'
                  ? 'bg-[#007aff] text-white shadow-sm'
                  : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
              }`}
            >
              <div className="flex items-center justify-center gap-2">
                <Calendar className="w-4 h-4" strokeWidth={2} />
                <span>Time</span>
              </div>
            </button>
            
            <button
              onClick={() => setBrowseMode('people')}
              className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                browseMode === 'people'
                  ? 'bg-[#007aff] text-white shadow-sm'
                  : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
              }`}
            >
              <div className="flex items-center justify-center gap-2">
                <Users className="w-4 h-4" strokeWidth={2} />
                <span>People</span>
              </div>
            </button>
            
            <button
              onClick={() => setBrowseMode('collections')}
              className={`flex-1 px-4 py-2.5 rounded-[12px] font-medium text-[15px] transition-all ${
                browseMode === 'collections'
                  ? 'bg-[#007aff] text-white shadow-sm'
                  : 'bg-white text-[#1c1c1e] border border-black/[0.08] hover:bg-[#f9f9f9]'
              }`}
            >
              <div className="flex items-center justify-center gap-2">
                <FolderOpen className="w-4 h-4" strokeWidth={2} />
                <span>Collections</span>
              </div>
            </button>
          </div>
        </div>
      </div>

      {/* Content Area - Different content based on browse mode */}
      <div className="flex-1 overflow-y-auto">
        {/* Time Mode */}
        {browseMode === 'time' && (
          <div className="px-5 py-5 space-y-4">
            <div className="mb-3">
              <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
                Today
              </h2>
            </div>
            
            {mockTimeMemories.map((memory) => (
              <div
                key={memory.id}
                className="bg-white rounded-[16px] p-4 shadow-sm border border-black/[0.06] hover:shadow-md transition-shadow"
              >
                <div className="flex items-start gap-3">
                  <div className="flex-shrink-0 w-10 h-10 rounded-[10px] bg-gradient-to-br from-[#007aff]/20 to-[#007aff]/10 flex items-center justify-center">
                    <Mic className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">
                      {memory.title}
                    </h3>
                    <div className="flex items-center gap-2 text-[14px] text-[#8e8e93]">
                      <span>{memory.date}</span>
                      {memory.hasAudio && (
                        <>
                          <span>·</span>
                          <Mic className="w-3.5 h-3.5" />
                        </>
                      )}
                      {memory.hasSummary && (
                        <>
                          <span>·</span>
                          <Sparkles className="w-3.5 h-3.5" />
                        </>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))}

            {/* Reflection card example */}
            <div className="mb-3 mt-6">
              <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
                Reflections
              </h2>
            </div>
            
            <div className="bg-white rounded-[16px] p-4 shadow-sm border border-black/[0.06]">
              <div className="flex items-start gap-3">
                <div className="flex-shrink-0 w-10 h-10 rounded-[10px] bg-gradient-to-br from-[#ff9500]/20 to-[#ff9500]/10 flex items-center justify-center">
                  <Sparkles className="w-5 h-5 text-[#ff9500]" strokeWidth={2} />
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">
                    Daily Insight
                  </h3>
                  <p className="text-[14px] text-[#8e8e93] leading-[1.4] line-clamp-2">
                    You spent most of today thinking about product direction...
                  </p>
                  <div className="flex items-center gap-2 text-[14px] text-[#8e8e93] mt-2">
                    <span>Jan 28</span>
                    <span>·</span>
                    <span>End-of-day reflection</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* People Mode */}
        {browseMode === 'people' && (
          <div className="px-5 py-5">
            <div className="mb-3">
              <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
                Recently Mentioned
              </h2>
            </div>
            
            <div className="bg-white rounded-[16px] shadow-sm border border-black/[0.06] overflow-hidden">
              {mockPeople.map((person, index) => (
                <button
                  key={person.id}
                  className={`w-full px-4 py-3 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors text-left ${
                    index < mockPeople.length - 1 ? 'border-b border-black/[0.06]' : ''
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#007aff]/20 to-[#007aff]/10 flex items-center justify-center">
                      <User className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
                    </div>
                    <div className="flex-1">
                      <div className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">
                        {person.name}
                      </div>
                      <div className="text-[14px] text-[#8e8e93]">
                        Last talked {person.lastTalked} · {person.memoryCount} {person.memoryCount === 1 ? 'memory' : 'memories'}
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Collections Mode */}
        {browseMode === 'collections' && (
          <div className="px-5 py-5">
            <div className="mb-3">
              <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
                My Collections
              </h2>
            </div>
            
            <div className="space-y-3">
              {mockCollections.map((collection) => (
                <button
                  key={collection.id}
                  className="w-full bg-white rounded-[16px] p-4 shadow-sm border border-black/[0.06] hover:shadow-md transition-all text-left"
                >
                  <div className="flex items-center gap-3">
                    <div 
                      className="w-12 h-12 rounded-[12px] flex items-center justify-center text-[24px]"
                      style={{ backgroundColor: `${collection.color}20` }}
                    >
                      {collection.icon}
                    </div>
                    <div className="flex-1">
                      <div className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">
                        {collection.name}
                      </div>
                      <div className="text-[14px] text-[#8e8e93]">
                        {collection.count} {collection.count === 1 ? 'memory' : 'memories'}
                      </div>
                    </div>
                    <div className="text-[#8e8e93]">
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    </div>
                  </div>
                </button>
              ))}

              {/* Add new collection button */}
              <button className="w-full bg-white rounded-[16px] p-4 shadow-sm border-2 border-dashed border-black/[0.1] hover:border-[#007aff]/50 hover:bg-[#007aff]/5 transition-all text-left">
                <div className="flex items-center gap-3 justify-center">
                  <div className="w-10 h-10 rounded-[10px] bg-[#007aff]/10 flex items-center justify-center">
                    <svg className="w-5 h-5 text-[#007aff]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
                    </svg>
                  </div>
                  <span className="text-[17px] font-medium text-[#007aff]">
                    Create New Collection
                  </span>
                </div>
              </button>
            </div>

            {/* Info text */}
            <div className="mt-8 text-center px-4">
              <p className="text-[14px] text-[#8e8e93] leading-relaxed">
                Organize your memories into collections.
                <br />
                Add any memory to multiple collections.
              </p>
            </div>
          </div>
        )}

        {/* Bottom spacing for safe area */}
        <div className="h-24" />
      </div>
    </div>
  );
}