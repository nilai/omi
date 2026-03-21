import { Brain, CheckSquare, Sparkles, Star, ChevronRight, Plus } from 'lucide-react';

interface HomeEmptyStateProps {
  memoryCount: number;
  todoCount: number;
  insightCount: number;
  onStartRecording: () => void;
  onQuickCapture: () => void;
  onAddTask: () => void;
  onViewAllTodos?: () => void;
  todos?: any[]; // Array of todos to display in Today's Focus when todoCount > 0
  memories?: any[]; // Array of memories to display in Recent Memory
  onSwitchToMemoryTab?: () => void;
  onMemoryClick?: (memory: any) => void;
}

export function HomeEmptyState({
  memoryCount,
  todoCount,
  insightCount,
  onStartRecording,
  onQuickCapture,
  onAddTask,
  onViewAllTodos,
  todos = [],
  memories = [],
  onSwitchToMemoryTab,
  onMemoryClick
}: HomeEmptyStateProps) {
  // Stage 1: Completely new user (0 Memory / 0 Todo / 0 Insight)
  const isStage1 = memoryCount === 0 && todoCount === 0 && insightCount === 0;
  
  // Stage 2: Has 1 memory
  const isStage2 = memoryCount === 1;

  // Filter Today todos for Today's Focus section
  const todayTodos = todos.filter(t => t.category === 'Today');
  // Filter Up Next todos for Today's Focus display in empty state
  const upNextTodos = todos.filter(t => t.category === 'Up Next');

  return (
    <div className="px-5 pt-2 pb-20 flex flex-col gap-4">
      {/* Hero Empty Card - Show until user has 3 memories */}
      {memoryCount < 3 && (
        <div className="mt-4 bg-gradient-to-br from-[#e8f4ff] via-[#f0f8ff] to-white rounded-[20px] p-6 shadow-sm border border-[#007aff]/10">
          <div className="flex flex-col">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-8 h-8 rounded-full bg-[#007aff]/10 flex items-center justify-center">
                <Brain className="w-4 h-4 text-[#007aff]" strokeWidth={2} />
              </div>
              <h2 className="text-[17px] font-semibold text-[#1c1c1e]">
                {memoryCount === 0 && 'Capture your first memory'}
                {memoryCount === 1 && 'Capture another memory'}
                {memoryCount === 2 && 'Build your memory timeline'}
              </h2>
            </div>
            <p className="text-[15px] text-[#8e8e93] mb-6 leading-relaxed">
              {memoryCount === 0 && (
                <>
                  Record conversations, meetings, or ideas.
                  <br />
                  MemoPin will turn them into insights and actions.
                </>
              )}
              {memoryCount === 1 && (
                <>
                  Try recording another conversation or idea.
                  <br />
                  The more you record, the better MemoPin understands your work.
                </>
              )}
              {memoryCount === 2 && (
                <>
                  Record a few more memories to help MemoPin
                  <br />
                  understand patterns in your work.
                </>
              )}
            </p>
            <div className="flex gap-3 w-full">
              <button
                onClick={onStartRecording}
                className="flex-1 py-2.5 bg-[#007aff] text-white text-[15px] font-medium rounded-[10px] hover:bg-[#0051d5] transition-colors"
              >
                Start Recording
              </button>
              <button
                onClick={onQuickCapture}
                className="flex-1 py-2.5 bg-[#f2f2f7] text-[#007aff] text-[15px] font-medium rounded-[10px] hover:bg-[#e5e5ea] transition-colors"
              >
                Quick Capture
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ZONE 1: Today's Focus - Same structure as normal state */}
      <div className="w-full bg-gradient-to-br from-[#f8fdf9] via-[#fcfefb] to-white rounded-[20px] p-6 shadow-[0_2px_8px_rgba(0,0,0,0.04),0_1px_2px_rgba(0,0,0,0.02)] border border-black/[0.04]">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-[17px] text-[#1c1c1e] font-semibold">Today's Focus</h3>
          {/* View All button - enabled when todoCount > 0 */}
          {todoCount > 0 ? (
            <button
              onClick={onViewAllTodos}
              className="flex items-center gap-1 text-[#059669] text-[14px] font-medium hover:opacity-70 transition-opacity"
            >
              View All
              <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
            </button>
          ) : (
            <div className="flex items-center gap-1 text-[#8e8e93] text-[14px] font-medium opacity-50">
              View All
              <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
            </div>
          )}
        </div>
        
        {/* Content - show real todos or empty state */}
        <div>
          {upNextTodos.length > 0 ? (
            // Has Up Next todos - display them
            <>
              <div className="space-y-4">
                {upNextTodos.slice(0, 3).map((todo) => (
                  <div
                    key={todo.id}
                    className="w-full"
                  >
                    <div className="w-full flex items-start gap-3 text-left">
                      <div className="flex-shrink-0 mt-[2px]">
                        <Star className="w-4 h-4 text-[#f59e42]" strokeWidth={2} fill="none" />
                      </div>
                      <span className={`flex-1 leading-[1.5] text-[15px] text-[#3c3c43] ${todo.completed ? 'line-through opacity-50' : ''}`}>
                        {todo.title || todo.text}
                      </span>
                      {todo.time && (
                        <span className="flex-shrink-0 text-[13px] text-[#8e8e93] font-medium">{todo.time}</span>
                      )}
                    </div>
                    {todo.reason && (
                      <div className="flex items-center gap-3 mt-1.5 ml-7">
                        <span className="text-[13px] text-[#8e8e93]">→ {todo.reason}</span>
                      </div>
                    )}
                  </div>
                ))}
              </div>
              
              {/* Suggestion card when Up Next has fewer than 3 todos */}
              {upNextTodos.length < 3 && (
                <div className="mt-4 p-4 bg-[#059669]/5 rounded-[12px] border border-[#059669]/10">
                  <p className="text-[14px] text-[#3c3c43] mb-3">
                    Add more tasks to Today's Focus to stay productive
                  </p>
                  <button
                    onClick={onViewAllTodos}
                    className="w-full py-2 bg-[#059669] text-white text-[14px] font-medium rounded-[8px] hover:bg-[#047857] transition-colors"
                  >
                    Go to All To-Dos
                  </button>
                </div>
              )}
            </>
          ) : (
            // No Up Next todos - show empty state
            <>
              {todoCount === 0 ? (
                // Completely empty - encourage Quick Capture
                <>
                  <p className="text-[15px] font-medium text-[#1c1c1e] mb-2">No tasks yet</p>
                  <p className="text-[14px] text-[#8e8e93] mb-4">
                    Use Quick Capture to create your first task.
                  </p>
                  <button
                    onClick={onQuickCapture}
                    className="w-full py-2.5 bg-[#059669] text-white text-[15px] font-medium rounded-[10px] hover:bg-[#047857] transition-colors"
                  >
                    Quick Capture
                  </button>
                </>
              ) : (
                // Has todos but not in Today's Focus - guide to All To-Dos
                <>
                  <p className="text-[15px] font-medium text-[#1c1c1e] mb-2">No tasks yet</p>
                  <p className="text-[14px] text-[#8e8e93] mb-4">
                    Tasks you add to Today's Focus will appear here.
                  </p>
                  <button
                    onClick={onViewAllTodos}
                    className="w-full py-2.5 bg-[#059669] text-white text-[15px] font-medium rounded-[10px] hover:bg-[#047857] transition-colors"
                  >
                    Go to All To-Dos
                  </button>
                </>
              )}
            </>
          )}
        </div>
      </div>

      {/* ZONE 2: Recent Memory - Same structure as normal state */}
      <div className="w-full bg-gradient-to-br from-[#fffcf5] via-[#fffef9] to-white rounded-[20px] p-6 shadow-[0_2px_8px_rgba(0,0,0,0.04),0_1px_2px_rgba(0,0,0,0.02)] border border-black/[0.04]">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-[17px] text-[#1c1c1e] font-semibold">Recent Memory</h3>
          {/* View All button - enabled when memories exist */}
          {memories.length > 0 ? (
            <button
              onClick={onSwitchToMemoryTab}
              className="flex items-center gap-1 text-[#d97706] text-[14px] font-medium hover:opacity-70 transition-opacity"
            >
              View All
              <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
            </button>
          ) : (
            <div className="flex items-center gap-1 text-[#8e8e93] text-[14px] font-medium opacity-50">
              View All
              <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
            </div>
          )}
        </div>
        
        {/* Content - show real memories or empty state */}
        {memories.length > 0 ? (
          <div className="space-y-3">
            {memories.slice(0, 3).map((memory) => (
              <button
                key={memory.id}
                onClick={() => onMemoryClick?.(memory)}
                className="w-full flex items-start justify-between gap-3 text-left hover:opacity-70 transition-opacity"
              >
                <p className="flex-1 leading-[1.5] text-[15px] text-[#3c3c43] line-clamp-1">
                  {memory.title || memory.date}
                </p>
                <span className="text-[13px] text-[#8e8e93] flex-shrink-0">{memory.time}</span>
              </button>
            ))}
          </div>
        ) : (
          <div>
            <p className="text-[15px] font-medium text-[#1c1c1e] mb-2">No memories yet</p>
            <p className="text-[14px] text-[#8e8e93] mb-4">
              Start recording to capture your first conversation or idea.
            </p>
            <button
              onClick={onStartRecording}
              className="w-full py-2.5 bg-[#007aff] text-white text-[15px] font-medium rounded-[10px] hover:bg-[#0051d5] transition-colors"
            >
              Start Recording
            </button>
          </div>
        )}
      </div>

      {/* ZONE 3: Insights - Same structure as normal state */}
      <div className="w-full bg-gradient-to-br from-[#f5f3ff] via-[#faf9ff] to-white rounded-[20px] p-6 shadow-[0_2px_8px_rgba(0,0,0,0.04),0_1px_2px_rgba(0,0,0,0.02)] border border-black/[0.04]">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-[#af52de]/10 flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-[#af52de]" strokeWidth={2} />
            </div>
            <h3 className="text-[17px] text-[#1c1c1e] font-semibold">Insights</h3>
          </div>
          {/* View All button - disabled in empty state */}
          <div className="flex items-center gap-1 text-[#8e8e93] text-[14px] font-medium opacity-50">
            View All
            <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
          </div>
        </div>
        
        {/* Empty state content */}
        <div>
          <p className="text-[14px] text-[#8e8e93] leading-relaxed">
            AI insights & summaries over time
          </p>
          <div className="mt-4 pt-4 border-t border-black/[0.04]">
            <p className="text-[15px] font-medium text-[#1c1c1e] mb-2">No insights yet</p>
            <p className="text-[14px] text-[#8e8e93]">
              Record more memories and AI will discover patterns for you.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}