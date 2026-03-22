import { ChevronLeft, MoreVertical, ChevronDown, ChevronUp, FolderOpen, Clock, Sparkles, Briefcase, Lightbulb, Target, Heart, CheckSquare, Circle, CheckCircle2, BookOpen, MessageCircle, Mic, ArrowUp, ChevronRight, X } from 'lucide-react';
import { useState, useEffect, useRef } from 'react';
import { LinkMemoryPage } from './LinkMemoryPage';
import { ProjectAskAIView } from './ProjectAskAIView';

interface ProjectMemory {
  id: number;
  title: string;
  date: string;
}

interface Memory {
  id: number;
  title: string | null;
  date: string;
  summary?: string | null;
  hasAudio?: boolean;
  hasSummary?: boolean;
  hasActivity?: boolean;
  audioDuration?: string;
}

interface TimelineItem {
  date: string;
  title: string;
  status: 'completed' | 'in-progress' | 'upcoming';
}

interface RecurringTheme {
  title: string;
  count: number;
  type: 'risk' | 'strategy' | 'discussion';
  insight: string;
  lastMentioned: {
    meeting: string;
    date: string;
  };
}

interface Todo {
  id: number;
  title: string;
  dueDate?: string;
  dueTime?: string;
  completed: boolean;
  completedDate?: string;
}

interface ProjectDetailProps {
  project: {
    id: string;
    name: string;
    memoryCount: number;
    todoCount?: number;
    updateTime: string;
    overview: {
      summary: string;
      decisionTimeline: Array<{ date: string; text: string }>;
      recurringThemes: string[];
      currentStatus: string;
    };
    aiSummary?: string;
    timeline?: TimelineItem[];
    themes?: RecurringTheme[];
    todos?: Todo[];
    memories: ProjectMemory[];
  };
  onBack: () => void;
  onMemoryClick: (memoryId: number) => void;
  allMemories?: Memory[];
  onUpdateProject?: (projectId: string, newMemories: ProjectMemory[]) => void;
  onRemoveMemory?: (projectId: string, memoryId: number) => void;
  onRenameProject?: (projectId: string, newName: string) => void;
  onRegenerateOverview?: (projectId: string) => void;
  onDeleteProject?: (projectId: string) => void;
  onOpenTodo?: (todoId: number) => void;
  onToggleTodo?: (todoId: number) => void;
}

export function ProjectDetail({ project, onBack, onMemoryClick, allMemories = [], onUpdateProject, onRemoveMemory, onRenameProject, onRegenerateOverview, onDeleteProject, onOpenTodo, onToggleTodo }: ProjectDetailProps) {
  const [isAISummaryExpanded, setIsAISummaryExpanded] = useState(false);
  const [showMenu, setShowMenu] = useState(false);
  const [showLinkMemoryPage, setShowLinkMemoryPage] = useState(false);
  const [swipedMemoryId, setSwipedMemoryId] = useState<number | null>(null);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [swipeOffset, setSwipeOffset] = useState(0);
  const [isDragging, setIsDragging] = useState(false);
  const [startX, setStartX] = useState(0);
  const [showRenameDialog, setShowRenameDialog] = useState(false);
  const [newProjectName, setNewProjectName] = useState('');
  const [showRegenerateDialog, setShowRegenerateDialog] = useState(false);
  const [selectedPerspective, setSelectedPerspective] = useState('auto');
  const [isRegenerating, setIsRegenerating] = useState(false);
  const [expandedPatterns, setExpandedPatterns] = useState<Set<number>>(new Set());
  const [showAskAI, setShowAskAI] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // Toggle pattern expansion
  const togglePattern = (index: number) => {
    setExpandedPatterns(prev => {
      const newSet = new Set(prev);
      if (newSet.has(index)) {
        newSet.delete(index);
      } else {
        newSet.add(index);
      }
      return newSet;
    });
  };

  // Get color for theme type
  const getThemeColor = (type: 'risk' | 'strategy' | 'discussion') => {
    switch (type) {
      case 'risk':
        return '#ff3b30'; // Red
      case 'strategy':
        return '#007aff'; // Blue
      case 'discussion':
        return '#ff9500'; // Orange
    }
  };

  // Close menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setShowMenu(false);
      }
    };

    if (showMenu) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showMenu]);

  const handleLinkMemories = (newMemoryIds: number[]) => {
    if (onUpdateProject && newMemoryIds.length > 0) {
      // Find the full memory objects for the new IDs
      const newMemories = allMemories
        .filter(m => newMemoryIds.includes(m.id))
        .map(m => ({
          id: m.id,
          title: m.title || 'Audio only',
          date: m.date
        }));
      
      // Combine with existing memories
      const updatedMemories = [...project.memories, ...newMemories];
      onUpdateProject(project.id, updatedMemories);
    }
    setShowLinkMemoryPage(false);
  };

  // Handle swipe/drag events
  const handleDragStart = (e: React.MouseEvent | React.TouchEvent, memoryId: number) => {
    setIsDragging(true);
    setSwipedMemoryId(memoryId);
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    setStartX(clientX);
  };

  const handleDragMove = (e: React.MouseEvent | React.TouchEvent) => {
    if (!isDragging || swipedMemoryId === null) return;
    
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const diff = clientX - startX;
    
    // Only allow left swipe (negative offset)
    if (diff < 0) {
      setSwipeOffset(Math.max(diff, -80)); // Max swipe distance is 80px
    } else {
      setSwipeOffset(0);
    }
  };

  const handleDragEnd = () => {
    setIsDragging(false);
    
    // If swiped more than 40px, keep it swiped, otherwise reset
    if (swipeOffset < -40) {
      setSwipeOffset(-80); // Snap to full swipe
    } else {
      setSwipeOffset(0);
      setSwipedMemoryId(null);
    }
  };

  const handleRemoveMemory = (memoryId: number) => {
    if (onRemoveMemory) {
      onRemoveMemory(project.id, memoryId);
    }
    // Reset swipe state
    setSwipedMemoryId(null);
    setSwipeOffset(0);
  };

  // If showing link memory page, render it instead
  if (showLinkMemoryPage) {
    return (
      <LinkMemoryPage
        onBack={() => setShowLinkMemoryPage(false)}
        allMemories={allMemories}
        linkedMemoryIds={project.memories.map(m => m.id)}
        onConfirm={handleLinkMemories}
      />
    );
  }

  // If showing Ask AI, render ProjectAskAIView
  if (showAskAI) {
    return <ProjectAskAIView projectName={project.name} onClose={() => setShowAskAI(false)} />;
  }

  return (
    <div className="flex flex-col h-full bg-[#f2f2f7]">
      {/* Header */}
      <div className="bg-white border-b border-black/[0.06]">
        <div className="px-5 pt-4 pb-3 flex items-center justify-between relative">
          <button
            onClick={onBack}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-6 h-6" strokeWidth={2} />
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            {project.name}
          </h1>
          <div className="relative">
            <button
              onClick={() => setShowMenu(!showMenu)}
              className="w-8 h-8 flex items-center justify-center text-[#1c1c1e] hover:bg-[#f2f2f7] rounded-full transition-colors"
            >
              <MoreVertical className="w-5 h-5" strokeWidth={2} />
            </button>

            {/* Dropdown Menu */}
            {showMenu && (
              <div
                ref={menuRef}
                className="absolute top-full right-0 mt-2 w-56 bg-white rounded-[14px] shadow-[0_8px_30px_rgba(0,0,0,0.12)] overflow-hidden z-50"
              >
                {/* Menu Items */}
                <button
                  onClick={() => {
                    setNewProjectName(project.name);
                    setShowRenameDialog(true);
                    setShowMenu(false);
                  }}
                  className="w-full px-4 py-3 text-left text-[17px] text-[#1c1c1e] hover:bg-[#f2f2f7] active:bg-[#e5e5ea] transition-colors"
                >
                  Rename project
                </button>
                
                <button
                  onClick={() => {
                    if (project.memoryCount > 0) {
                      setShowRegenerateDialog(true);
                      setShowMenu(false);
                    }
                  }}
                  disabled={project.memoryCount === 0}
                  className={`w-full px-4 py-3 text-left text-[17px] transition-colors ${
                    project.memoryCount === 0
                      ? 'text-[#8e8e93] cursor-not-allowed'
                      : 'text-[#1c1c1e] hover:bg-[#f2f2f7] active:bg-[#e5e5ea]'
                  }`}
                >
                  Regenerate overview
                </button>

                {/* Divider */}
                <div className="border-t border-black/[0.06]" />

                {/* Delete Button - Danger Style */}
                <button
                  onClick={() => {
                    setShowDeleteConfirm(true);
                    setShowMenu(false);
                  }}
                  className="w-full px-4 py-3 text-left text-[17px] text-[#ff3b30] font-medium hover:bg-[#ff3b30]/5 active:bg-[#ff3b30]/10 transition-colors"
                >
                  Delete project
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        {/* Project Header Stats - Chip Style */}
        <div className="px-5 pt-5 pb-4">
          <div className="flex items-center gap-2 flex-wrap">
            {/* Memories Chip */}
            <div className="inline-flex items-center gap-1.5 px-3 py-2 bg-white rounded-[10px] border border-black/[0.08]">
              <FolderOpen className="w-4 h-4 text-[#8e8e93]" strokeWidth={2} />
              <span className="text-[15px] text-[#1c1c1e] font-medium">{project.memoryCount} {project.memoryCount === 1 ? 'Memory' : 'Memories'}</span>
            </div>
            
            {/* Todos Chip */}
            <div className="inline-flex items-center gap-1.5 px-3 py-2 bg-white rounded-[10px] border border-black/[0.08]">
              <CheckSquare className="w-4 h-4 text-[#8e8e93]" strokeWidth={2} />
              <span className="text-[15px] text-[#1c1c1e] font-medium">{project.todoCount || 0} {(project.todoCount || 0) === 1 ? 'Todo' : 'Todos'}</span>
            </div>
            
            {/* Updated Chip */}
            <div className="inline-flex items-center gap-1.5 px-3 py-2 bg-white rounded-[10px] border border-black/[0.08]">
              <Clock className="w-4 h-4 text-[#8e8e93]" strokeWidth={2} />
              <span className="text-[15px] text-[#1c1c1e] font-medium">Updated {project.updateTime}</span>
            </div>
          </div>
        </div>

        {/* Project Summary Section */}
        <div className="px-5 pt-1 pb-4">
          <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-4">Project Summary</h2>
          
          {/* Current Status */}
          <div className="mb-4">
            <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">Current Status</h3>
            <p className="text-[15px] text-[#1c1c1e] leading-[1.5]">
              {project.id === 'api-migration' ? 
                'API migration is in active implementation. The team has aligned on parallel execution, but coordination pressure remains.' :
              project.id === 'product-launch-q2' ?
                'Product launch is in preparation phase. Marketing materials are being revised with ADHD-focused messaging, and beta onboarding is underway.' :
              project.id === 'series-a-fundraising' ?
                'Fundraising is in active investor engagement. Pitch deck updated with Q1 metrics, preparing for follow-up meetings with lead investors.' :
                'Project is actively progressing with team coordination.'}
            </p>
          </div>

          {/* Progress */}
          <div className="mb-4">
            <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">Progress</h3>
            <p className="text-[15px] text-[#1c1c1e] leading-[1.5]">
              {project.id === 'api-migration' ? 
                'Three project-related discussions this month clarified architecture direction and reduced uncertainty around rollout sequence.' :
              project.id === 'product-launch-q2' ?
                'Two strategy sessions refined the three-phase rollout approach, shifting focus from generic messaging to neurodivergent-friendly positioning.' :
              project.id === 'series-a-fundraising' ?
                'Two investor meetings established strong interest in retention metrics. Narrative evolved from product features to traction and unit economics.' :
                'Multiple discussions have moved the project forward with clear alignment.'}
            </p>
          </div>

          {/* Next Steps */}
          <div>
            <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">Next Steps</h3>
            <div className="space-y-1.5">
              {project.id === 'api-migration' ? (
                <>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Confirm API ownership and team responsibilities</span>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Finalize rollout plan with timeline milestones</span>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Follow up on infrastructure support availability</span>
                  </div>
                </>
              ) : project.id === 'product-launch-q2' ? (
                <>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Complete marketing deck with user stories</span>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Finalize beta onboarding materials and survey</span>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Build buffer between rollout phases</span>
                  </div>
                </>
              ) : project.id === 'series-a-fundraising' ? (
                <>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Schedule follow-up with lead investor</span>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Send detailed financial model and cohort analysis</span>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Prepare reference calls from existing customers</span>
                  </div>
                </>
              ) : (
                <>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Define next milestones and action items</span>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Align team on priorities</span>
                  </div>
                  <div className="flex items-start gap-2">
                    <span className="text-[15px] text-[#1c1c1e]">•</span>
                    <span className="text-[15px] text-[#1c1c1e]">Schedule follow-up discussions</span>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Key Patterns Section */}
        {project.themes && project.themes.length > 0 && (
          <>
            {/* Divider to separate from Project Summary */}
            <div className="px-5 pt-4">
              <div className="border-t border-black/[0.06]" />
            </div>

            <div className="px-5 pt-5 pb-4">
              <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-4">Key Patterns</h2>
              <div className="space-y-3">
                {project.themes.map((theme, index) => {
                  const isExpanded = expandedPatterns.has(index);
                  const themeColor = getThemeColor(theme.type);
                  
                  return (
                    <button
                      key={index}
                      onClick={() => togglePattern(index)}
                      className="w-full text-left bg-white rounded-[12px] px-4 py-3 border border-black/[0.06] hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors"
                    >
                      <div className="flex items-start gap-2.5">
                        {/* Colored Dot */}
                        <div 
                          className="w-2 h-2 rounded-full mt-1.5 flex-shrink-0"
                          style={{ backgroundColor: themeColor }}
                        />
                        
                        <div className="flex-1 min-w-0">
                          {/* Title and Count - Always Visible */}
                          <div className="flex items-start justify-between gap-2 mb-1">
                            <h3 className="text-[15px] font-semibold text-[#1c1c1e] flex-1">
                              {theme.title}
                            </h3>
                            <ChevronDown 
                              className={`w-4 h-4 text-[#8e8e93] flex-shrink-0 mt-0.5 transition-transform ${isExpanded ? 'rotate-180' : ''}`}
                              strokeWidth={2.5}
                            />
                          </div>
                          
                          {/* Discussion Count - Always Visible */}
                          <p className="text-[13px] text-[#8e8e93]">
                            Discussed in {theme.count} {theme.count === 1 ? 'meeting' : 'meetings'}
                          </p>
                          
                          {/* Expanded Content */}
                          {isExpanded && (
                            <div className="mt-3 pt-3 border-t border-black/[0.06]">
                              {/* Insight */}
                              <p className="text-[15px] text-[#1c1c1e] leading-[1.5] mb-2.5">
                                {theme.insight}
                              </p>
                              
                              {/* Last Mentioned */}
                              <p className="text-[13px] text-[#8e8e93]">
                                Last mentioned: {theme.lastMentioned.meeting} · {theme.lastMentioned.date}
                              </p>
                            </div>
                          )}
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Divider */}
            <div className="px-5">
              <div className="border-t border-black/[0.06]" />
            </div>
          </>
        )}

        {/* Related Memories Section */}
        <div className="px-5 pt-5 pb-4">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-[20px] font-semibold text-[#1c1c1e]">Related Memories</h2>
            <button
              onClick={() => setShowLinkMemoryPage(true)}
              className="text-[17px] text-[#007aff] font-medium hover:opacity-70 transition-opacity"
            >
              + Add
            </button>
          </div>
          
          {project.memories.length > 0 ? (
            <div className="space-y-2">
              {project.memories.map((memory) => {
                const isThisSwiped = swipedMemoryId === memory.id;
                const offset = isThisSwiped ? swipeOffset : 0;
                
                return (
                  <div 
                    key={memory.id} 
                    className="relative overflow-hidden rounded-[12px]"
                    onMouseMove={handleDragMove}
                    onMouseUp={handleDragEnd}
                    onMouseLeave={handleDragEnd}
                    onTouchMove={handleDragMove}
                    onTouchEnd={handleDragEnd}
                  >
                    {/* Remove Button - Behind the card */}
                    <div className="absolute inset-0 flex items-center justify-end pr-4 bg-[#ff3b30] rounded-[12px]">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleRemoveMemory(memory.id);
                        }}
                        className="text-white text-[15px] font-semibold whitespace-nowrap"
                      >
                        Remove
                      </button>
                    </div>

                    {/* Memory Card - Slides over the remove button */}
                    <button
                      onClick={() => {
                        if (offset === 0) {
                          onMemoryClick(memory.id);
                        } else {
                          // If swiped, first click resets the swipe
                          setSwipeOffset(0);
                          setSwipedMemoryId(null);
                        }
                      }}
                      onMouseDown={(e) => handleDragStart(e, memory.id)}
                      onTouchStart={(e) => handleDragStart(e, memory.id)}
                      style={{
                        transform: `translateX(${offset}px)`,
                        transition: isDragging ? 'none' : 'transform 0.3s ease-out'
                      }}
                      className="w-full text-left px-4 py-3 bg-white rounded-[12px] border border-black/[0.06] hover:bg-[#f9f9f9] active:bg-[#f2f2f7] relative"
                    >
                      <div className="flex items-start gap-2">
                        <BookOpen className="w-4 h-4 text-[#8e8e93] mt-0.5 flex-shrink-0" strokeWidth={2} />
                        <div className="flex-1 min-w-0">
                          <p className="text-[15px] text-[#1c1c1e] font-medium mb-0.5 line-clamp-1">{memory.title}</p>
                          <p className="text-[13px] text-[#8e8e93]">{memory.date}</p>
                        </div>
                      </div>
                    </button>
                  </div>
                );
              })}
            </div>
          ) : (
            <p className="text-[15px] text-[#8e8e93] text-center py-8">No memories linked yet</p>
          )}
        </div>

        {/* Divider */}
        <div className="px-5">
          <div className="border-t border-black/[0.06]" />
        </div>

        {/* Related Todos Section */}
        {project.todos && project.todos.length > 0 && (
          <>
            <div className="px-5 pt-5 pb-4">
              <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-3">Related Todos</h2>
              <div className="space-y-2">
                {project.todos.map((todo) => (
                  <div key={todo.id} className="flex items-start gap-3 px-4 py-3 bg-white rounded-[12px] border border-black/[0.06] hover:bg-[#f9f9f9] active:bg-[#f2f2f7] cursor-pointer transition-colors"
                    onClick={() => {
                      if (onOpenTodo) {
                        onOpenTodo(todo.id);
                      }
                    }}
                  >
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        if (onToggleTodo) {
                          onToggleTodo(todo.id);
                        }
                      }}
                      className={`w-5 h-5 rounded-[6px] border-2 flex items-center justify-center flex-shrink-0 mt-0.5 hover:opacity-70 transition-opacity ${
                        todo.completed 
                          ? 'border-[#34c759] bg-[#34c759]' 
                          : 'border-[#8e8e93]'
                      }`}
                    >
                      {todo.completed && (
                        <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                      )}
                    </button>
                    <div className="flex-1 min-w-0">
                      <p className={`text-[15px] mb-1 ${todo.completed ? 'text-[#8e8e93] line-through' : 'text-[#1c1c1e]'}`}>
                        {todo.title}
                      </p>
                      {(todo.dueDate || todo.dueTime) && (
                        <p className="text-[13px] text-[#8e8e93]">
                          {todo.completed 
                            ? `Completed ${todo.completedDate || todo.dueDate}` 
                            : `Due ${todo.dueDate}${todo.dueTime ? ` at ${todo.dueTime}` : ''}`
                          }
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Divider */}
            <div className="px-5">
              <div className="border-t border-black/[0.06]" />
            </div>
          </>
        )}

        {/* Add Memory Button */}
        <div className="px-5 pt-4 pb-3">
          {/* Ask AI Button Section */}
          <button
            onClick={() => setShowAskAI(true)}
            className="w-full bg-[#007aff] hover:bg-[#0051d5] text-white rounded-[14px] px-5 py-4 flex items-center justify-center gap-2 transition-colors shadow-sm"
          >
            <MessageCircle className="w-5 h-5" strokeWidth={2} />
            <span className="text-[17px] font-semibold">
              Ask AI about this project
            </span>
          </button>
        </div>

        {/* Bottom spacing */}
        <div className="h-4 pb-20" />
      </div>

      {/* Link Memory Page - Removed as it's now rendered at the top level */}

      {/* Rename Dialog */}
      {showRenameDialog && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-[14px] w-full max-w-[270px] shadow-[0_20px_60px_rgba(0,0,0,0.35)]">
            {/* Dialog Header */}
            <div className="px-4 pt-5 pb-2 text-center">
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Rename Project</h3>
            </div>

            {/* Current Name Display */}
            <div className="px-4 pb-3 text-center">
              <p className="text-[13px] text-[#8e8e93]">Current: {project.name}</p>
            </div>

            {/* Input Field */}
            <div className="px-4 pb-4">
              <input
                type="text"
                value={newProjectName}
                onChange={(e) => setNewProjectName(e.target.value)}
                placeholder="Enter new name"
                autoFocus
                className="w-full px-3 py-2 text-[15px] text-[#1c1c1e] bg-white border border-black/[0.15] rounded-[8px] focus:outline-none focus:border-[#007aff] focus:ring-1 focus:ring-[#007aff]"
              />
            </div>

            {/* Buttons */}
            <div className="border-t border-black/[0.15]">
              <div className="flex">
                {/* Cancel Button */}
                <button
                  onClick={() => {
                    setShowRenameDialog(false);
                    setNewProjectName('');
                  }}
                  className="flex-1 py-3 text-[17px] text-[#007aff] hover:bg-[#f2f2f7] active:bg-[#e5e5ea] transition-colors border-r border-black/[0.15]"
                >
                  Cancel
                </button>

                {/* Rename Button */}
                <button
                  onClick={() => {
                    if (onRenameProject && newProjectName.trim()) {
                      onRenameProject(project.id, newProjectName.trim());
                    }
                    setShowRenameDialog(false);
                    setNewProjectName('');
                  }}
                  className="flex-1 py-3 text-[17px] text-[#007aff] font-semibold hover:bg-[#f2f2f7] active:bg-[#e5e5ea] transition-colors disabled:opacity-50"
                  disabled={!newProjectName.trim()}
                >
                  Rename
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Regenerate Overview Dialog */}
      {showRegenerateDialog && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-[14px] w-full max-w-[300px] shadow-[0_20px_60px_rgba(0,0,0,0.35)]">
            {/* Dialog Header */}
            <div className="px-5 pt-5 pb-3 text-center border-b border-black/[0.06]">
              <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">Regenerate overview</h3>
              <p className="text-[13px] text-[#8e8e93]">Choose perspective</p>
              
              {/* Warning for 1 memory */}
              {project.memoryCount === 1 && (
                <div className="mt-3 pt-3 border-t border-black/[0.06]">
                  <p className="text-[13px] text-[#8e8e93] leading-[1.4]">
                    This project contains only 1 memory.<br />
                    Overview may be limited.
                  </p>
                </div>
              )}
            </div>

            {/* Radio Options */}
            <div className="px-5 py-4">
              <div className="space-y-2.5">
                {/* Auto (recommended) */}
                <button
                  onClick={() => setSelectedPerspective('auto')}
                  className="w-full flex items-start gap-3 p-3.5 rounded-[12px] hover:bg-[#f2f2f7] transition-colors"
                >
                  <div className="w-5 h-5 rounded-full border-2 border-[#007aff] flex items-center justify-center flex-shrink-0 mt-0.5">
                    {selectedPerspective === 'auto' && (
                      <div className="w-3 h-3 rounded-full bg-[#007aff]"></div>
                    )}
                  </div>
                  <div className="w-8 h-8 rounded-[10px] bg-gradient-to-br from-[#007aff]/10 to-[#007aff]/5 flex items-center justify-center flex-shrink-0">
                    <Sparkles className="w-4 h-4 text-[#007aff]" strokeWidth={2} />
                  </div>
                  <div className="flex-1 text-left min-w-0">
                    <div className="mb-0.5">
                      <span className="text-[15px] font-medium text-[#1c1c1e]">Auto </span>
                      <span className="text-[13px] text-[#8e8e93]">(recommended)</span>
                    </div>
                    <p className="text-[13px] text-[#8e8e93] leading-[1.3]">
                      AI chooses the most relevant perspective
                    </p>
                  </div>
                </button>

                {/* Business */}
                <button
                  onClick={() => setSelectedPerspective('business')}
                  className="w-full flex items-start gap-3 p-3.5 rounded-[12px] hover:bg-[#f2f2f7] transition-colors"
                >
                  <div className="w-5 h-5 rounded-full border-2 border-[#007aff] flex items-center justify-center flex-shrink-0 mt-0.5">
                    {selectedPerspective === 'business' && (
                      <div className="w-3 h-3 rounded-full bg-[#007aff]"></div>
                    )}
                  </div>
                  <div className="w-8 h-8 rounded-[10px] bg-gradient-to-br from-[#34c759]/10 to-[#34c759]/5 flex items-center justify-center flex-shrink-0">
                    <Briefcase className="w-4 h-4 text-[#34c759]" strokeWidth={2} />
                  </div>
                  <div className="flex-1 text-left min-w-0">
                    <div className="mb-0.5">
                      <span className="text-[15px] font-medium text-[#1c1c1e]">Business</span>
                    </div>
                    <p className="text-[13px] text-[#8e8e93] leading-[1.3]">
                      Strategy, metrics, risks & opportunities
                    </p>
                  </div>
                </button>

                {/* Creative */}
                <button
                  onClick={() => setSelectedPerspective('creative')}
                  className="w-full flex items-start gap-3 p-3.5 rounded-[12px] hover:bg-[#f2f2f7] transition-colors"
                >
                  <div className="w-5 h-5 rounded-full border-2 border-[#007aff] flex items-center justify-center flex-shrink-0 mt-0.5">
                    {selectedPerspective === 'creative' && (
                      <div className="w-3 h-3 rounded-full bg-[#007aff]"></div>
                    )}
                  </div>
                  <div className="w-8 h-8 rounded-[10px] bg-gradient-to-br from-[#ff9500]/10 to-[#ff9500]/5 flex items-center justify-center flex-shrink-0">
                    <Lightbulb className="w-4 h-4 text-[#ff9500]" strokeWidth={2} />
                  </div>
                  <div className="flex-1 text-left min-w-0">
                    <div className="mb-0.5">
                      <span className="text-[15px] font-medium text-[#1c1c1e]">Creative</span>
                    </div>
                    <p className="text-[13px] text-[#8e8e93] leading-[1.3]">
                      Ideas, positioning & direction shifts
                    </p>
                  </div>
                </button>

                {/* Execution */}
                <button
                  onClick={() => setSelectedPerspective('execution')}
                  className="w-full flex items-start gap-3 p-3.5 rounded-[12px] hover:bg-[#f2f2f7] transition-colors"
                >
                  <div className="w-5 h-5 rounded-full border-2 border-[#007aff] flex items-center justify-center flex-shrink-0 mt-0.5">
                    {selectedPerspective === 'execution' && (
                      <div className="w-3 h-3 rounded-full bg-[#007aff]"></div>
                    )}
                  </div>
                  <div className="w-8 h-8 rounded-[10px] bg-gradient-to-br from-[#ff3b30]/10 to-[#ff3b30]/5 flex items-center justify-center flex-shrink-0">
                    <Target className="w-4 h-4 text-[#ff3b30]" strokeWidth={2} />
                  </div>
                  <div className="flex-1 text-left min-w-0">
                    <div className="mb-0.5">
                      <span className="text-[15px] font-medium text-[#1c1c1e]">Execution</span>
                    </div>
                    <p className="text-[13px] text-[#8e8e93] leading-[1.3]">
                      Progress, blockers & next steps
                    </p>
                  </div>
                </button>

                {/* Wellness */}
                <button
                  onClick={() => setSelectedPerspective('wellness')}
                  className="w-full flex items-start gap-3 p-3.5 rounded-[12px] hover:bg-[#f2f2f7] transition-colors"
                >
                  <div className="w-5 h-5 rounded-full border-2 border-[#007aff] flex items-center justify-center flex-shrink-0 mt-0.5">
                    {selectedPerspective === 'wellness' && (
                      <div className="w-3 h-3 rounded-full bg-[#007aff]"></div>
                    )}
                  </div>
                  <div className="w-8 h-8 rounded-[10px] bg-gradient-to-br from-[#ff2d55]/10 to-[#ff2d55]/5 flex items-center justify-center flex-shrink-0">
                    <Heart className="w-4 h-4 text-[#ff2d55]" strokeWidth={2} />
                  </div>
                  <div className="flex-1 text-left min-w-0">
                    <div className="mb-0.5">
                      <span className="text-[15px] font-medium text-[#1c1c1e]">Wellness</span>
                    </div>
                    <p className="text-[13px] text-[#8e8e93] leading-[1.3]">
                      Team load, energy & sustainability
                    </p>
                  </div>
                </button>
              </div>
            </div>

            {/* Buttons */}
            <div className="border-t border-black/[0.06] px-4 py-3 flex gap-3">
              <button
                onClick={() => {
                  setShowRegenerateDialog(false);
                  setSelectedPerspective('auto');
                }}
                className="flex-1 py-2.5 text-[15px] text-[#8e8e93] bg-[#f2f2f7] rounded-[10px] hover:bg-[#e5e5ea] active:bg-[#d1d1d6] transition-colors font-medium"
              >
                Cancel
              </button>

              <button
                onClick={() => {
                  setShowRegenerateDialog(false);
                  setIsRegenerating(true);
                  
                  // Simulate 3-second regeneration process
                  setTimeout(() => {
                    setIsRegenerating(false);
                    if (onRegenerateOverview) {
                      onRegenerateOverview(project.id);
                    }
                  }, 3000);
                }}
                className="flex-1 py-2.5 text-[15px] text-white bg-[#007aff] rounded-[10px] hover:bg-[#0051d5] active:bg-[#0040a8] transition-colors font-semibold"
              >
                Regenerate
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Dialog */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-[14px] w-full max-w-[300px] shadow-[0_20px_60px_rgba(0,0,0,0.35)]">
            {/* Dialog Header */}
            <div className="px-5 pt-5 pb-3 text-center border-b border-black/[0.06]">
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Delete project</h3>
            </div>

            {/* Warning Text */}
            <div className="px-5 py-4">
              <p className="text-[13px] text-[#8e8e93] leading-[1.4]">
                This action is irreversible.
              </p>
            </div>

            {/* Buttons */}
            <div className="border-t border-black/[0.06] px-4 py-3 flex gap-3">
              <button
                onClick={() => {
                  setShowDeleteConfirm(false);
                }}
                className="flex-1 py-2.5 text-[15px] text-[#8e8e93] bg-[#f2f2f7] rounded-[10px] hover:bg-[#e5e5ea] active:bg-[#d1d1d6] transition-colors font-medium"
              >
                Cancel
              </button>

              <button
                onClick={() => {
                  setShowDeleteConfirm(false);
                  if (onDeleteProject) onDeleteProject(project.id);
                }}
                className="flex-1 py-2.5 text-[15px] text-white bg-[#ff3b30] rounded-[10px] hover:bg-[#ff2400] active:bg-[#ff0000] transition-colors font-semibold"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}