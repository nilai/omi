import { ChevronLeft, ChevronRight, Sparkles, Clock, CheckSquare, Calendar as CalendarIcon, Mic, FileText, Activity, BarChart3, Compass, Square } from 'lucide-react';
import { useState, useCallback } from 'react';
import { MemoryGraphSummary } from './MemoryGraphSummary';
import { TodoDetailModal } from './TodoDetailModal';
import { CompletedTodoDetailModal } from './CompletedTodoDetailModal';

type TimeRange = '7days' | '30days' | '90days' | null;

interface CalendarPageProps {
  onBack: () => void;
  onMemoryClick: (memory: any) => void;
  onDailyInsightClick?: (insight: any) => void;
  onWeeklyInsightClick?: (insight: any) => void;
  onMonthlyInsightClick?: (insight: any) => void;
  onActionClick?: (action: any) => void;
  memos?: any[];
  onMemoClick?: (memo: any) => void;
  todos?: any[];
  setTodos?: (todos: any[]) => void;
  onLinkMemory?: (todoId: number) => void;
  onMemoryClickFromTodo?: (memoryId: string) => void;
}

interface DayData {
  date: Date;
  hasMemories: boolean;
  memoryCount: number;
  hasDailyInsight: boolean;
  hasWeeklyInsight: boolean;
  hasMonthlyInsight: boolean;
  hasTodos: boolean;
  todoCount: number;
}

interface Memory {
  id: number;
  title: string;
  time: string;
  hasAudio: boolean;
  hasSummary: boolean;
  hasActivity: boolean;
}

interface DailyInsight {
  id: number;
  summary: string;
  decisions: number;
  followUps: number;
  risks: number;
}

interface Action {
  id: number;
  title: string;
  completed: boolean;
  relatedMemoryId?: number;
}

export function CalendarPage({ onBack, onMemoryClick, onDailyInsightClick, onWeeklyInsightClick, onMonthlyInsightClick, onActionClick, memos, onMemoClick, todos, setTodos, onLinkMemory, onMemoryClickFromTodo }: CalendarPageProps) {
  const [currentMonth, setCurrentMonth] = useState(new Date(2026, 2, 1)); // March 2026
  const [selectedDate, setSelectedDate] = useState(new Date(2026, 2, 5)); // March 5, 2026 (today)
  const [timeRange, setTimeRange] = useState<TimeRange>('7days');
  const [selectedTodo, setSelectedTodo] = useState<any | null>(null);

  // Todo management functions
  const toggleTodo = (id: number) => {
    if (!setTodos || !todos) return;
    setTodos(todos.map(todo => {
      if (todo.id === id) {
        const newCompleted = !todo.completed;
        return {
          ...todo,
          completed: newCompleted,
          category: newCompleted ? 'Completed' : 'Today'
        };
      }
      return todo;
    }));
  };

  const handleMarkDone = (id: number) => {
    if (!setTodos || !todos) return;
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, completed: true, category: 'Completed' } : todo
    ));
    setSelectedTodo(null);
  };

  const handleNotNow = (id: number) => {
    if (!setTodos || !todos) return;
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, category: 'Later' } : todo
    ));
    setSelectedTodo(null);
  };

  const handleDelete = (id: number) => {
    if (!setTodos || !todos) return;
    setTodos(todos.filter(todo => todo.id !== id));
    setSelectedTodo(null);
  };

  const handleRestore = (id: number) => {
    if (!setTodos || !todos) return;
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, completed: false, category: 'Today' } : todo
    ));
    setSelectedTodo(null);
  };

  const handleUpdateTodo = useCallback((id: number, updates: any) => {
    if (!setTodos || !todos) return;
    setTodos(todos.map(todo => {
      if (todo.id === id) {
        return {
          ...todo,
          ...updates
        };
      }
      return todo;
    }));
  }, [todos, setTodos]);

  // Mock data - memories by date
  const memoriesData: { [key: string]: Memory[] } = {
    '2026-03-03': [
      { id: 1, title: 'Team standup discussion on API migration', time: '10:30 AM', hasAudio: true, hasSummary: true, hasActivity: false },
      { id: 7, title: 'Product launch planning with marketing team', time: '9:15 AM', hasAudio: true, hasSummary: true, hasActivity: true },
    ],
    '2026-03-02': [
      { id: 8, title: 'Investor meeting - Series A funding discussion', time: '4:30 PM', hasAudio: true, hasSummary: true, hasActivity: true },
      { id: 2, title: 'Coffee chat with Alex about product strategy', time: '2:15 PM', hasAudio: true, hasSummary: true, hasActivity: false },
    ],
    '2026-02-28': [
      { id: 4, title: 'Client feedback call about new dashboard features', time: '3:00 PM', hasAudio: true, hasSummary: true, hasActivity: true },
    ],
    '2026-01-21': [
      { id: 3, title: 'Audio only', time: '3:45 PM', hasAudio: true, hasSummary: false, hasActivity: false },
    ],
    '2026-01-19': [
      { id: 5, title: 'Weekly review and planning session', time: '1:00 PM', hasAudio: true, hasSummary: true, hasActivity: false },
    ],
    '2026-01-18': [
      { id: 6, title: 'Audio only', time: '11:20 AM', hasAudio: true, hasSummary: false, hasActivity: false },
    ],
  };

  // Mock data - daily insights by date
  const dailyInsightsData: { [key: string]: DailyInsight } = {
    '2026-03-03': {
      id: 1,
      summary: 'You spent most of today aligning the API migration strategy with the team. Key decisions were made about the timeline.',
      decisions: 2,
      followUps: 3,
      risks: 1,
    },
    '2026-01-23': {
      id: 2,
      summary: 'Focused on user research and marketing alignment. Several important insights emerged about user needs.',
      decisions: 1,
      followUps: 2,
      risks: 0,
    },
  };

  // Mock data - weekly insights by date (Sundays)
  const weeklyInsightsData: { [key: string]: any } = {
    '2026-03-02': {
      id: 'weekly-mar-02',
      date: 'Mar 2',
      dateSubtitle: 'Week of Feb 24 - Mar 2',
      summary: 'A productive week with strong momentum on the product roadmap. You balanced strategic planning with hands-on execution, completing 8 major tasks while identifying 3 key priorities for next week.',
      completedCount: 8,
      pendingCount: 5,
      recommendationsCount: 3
    },
    '2026-01-18': {
      id: 'weekly-jan-18',
      date: 'Jan 18',
      dateSubtitle: 'Week of Jan 12-18',
      summary: 'Intense week focused on sprint delivery. The team shipped 2 major features while managing technical debt. Need to balance velocity with code quality going forward.',
      completedCount: 12,
      pendingCount: 3,
      recommendationsCount: 2
    },
  };

  // Mock data - monthly insights by date (Last day of month)
  const monthlyInsightsData: { [key: string]: any } = {
    '2026-02-28': {
      id: 'monthly-feb-28',
      date: 'Feb 28',
      dateSubtitle: 'February 2026',
      summary: 'Execution momentum improved compared to January, with strong progress on the API migration and product roadmap. Team collaboration and decision-making velocity increased significantly.',
      topicsCount: 3,
      openThreadsCount: 2,
      decisionsCount: 5
    },
  };

  // Mock data - actions by date
  const actionsData: { [key: string]: Action[] } = {
    '2026-03-03': [
      { id: 1, title: 'Follow up with infrastructure team', completed: false, relatedMemoryId: 1 },
      { id: 2, title: 'Prepare detailed migration timeline', completed: true, relatedMemoryId: 1 },
      { id: 3, title: 'Evaluate rollout risk factors', completed: false, relatedMemoryId: 1 },
    ],
    '2026-03-02': [
      { id: 4, title: 'Share investor deck with team', completed: true, relatedMemoryId: 8 },
      { id: 5, title: 'Schedule follow-up with Alex', completed: false, relatedMemoryId: 2 },
    ],
  };

  const getDateKey = (date: Date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  const getDaysInMonth = (date: Date) => {
    const year = date.getFullYear();
    const month = date.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startingDayOfWeek = firstDay.getDay(); // 0 = Sunday, 1 = Monday, etc.

    const days: (DayData | null)[] = [];

    // Add empty cells for days before the first day of the month
    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(null);
    }

    // Add all days in the month
    for (let day = 1; day <= daysInMonth; day++) {
      const currentDate = new Date(year, month, day);
      const dateKey = getDateKey(currentDate);
      const hasMemories = memoriesData[dateKey] !== undefined;
      const memoryCount = memoriesData[dateKey]?.length || 0;
      const hasDailyInsight = dailyInsightsData[dateKey] !== undefined;
      const hasWeeklyInsight = weeklyInsightsData[dateKey] !== undefined;
      const hasMonthlyInsight = monthlyInsightsData[dateKey] !== undefined;
      
      // Count todos for this day
      // For today (March 5, 2026): show all 'Up Next' and 'Today' category todos
      // For other dates: only show todos with time
      const todayDate = new Date(2026, 2, 5); // March 5, 2026
      const isCurrentDateToday = isSameDate(currentDate, todayDate);
      
      const dayTodos = todos?.filter(todo => {
        if (isCurrentDateToday) {
          // For today: show all todos in 'Up Next' or 'Today' category
          return todo.category === 'Up Next' || todo.category === 'Today';
        } else {
          // For other dates: only show todos with time and matching dueDate
          if (!todo.time) return false;
          if (!todo.dueDate || todo.dueDate === 'No deadline') return false;
          
          const todoDate = new Date(todo.dueDate);
          return isSameDate(todoDate, currentDate);
        }
      }) || [];
      
      const hasTodos = dayTodos.length > 0;
      const todoCount = dayTodos.length;

      days.push({
        date: currentDate,
        hasMemories,
        memoryCount,
        hasDailyInsight,
        hasWeeklyInsight,
        hasMonthlyInsight,
        hasTodos,
        todoCount,
      });
    }

    return days;
  };

  const goToPreviousMonth = () => {
    setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1));
  };

  const goToNextMonth = () => {
    setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1));
  };

  const isToday = (date: Date) => {
    const today = new Date();
    return date.getDate() === today.getDate() &&
           date.getMonth() === today.getMonth() &&
           date.getFullYear() === today.getFullYear();
  };

  const isSameDate = (date1: Date, date2: Date) => {
    return date1.getDate() === date2.getDate() &&
           date1.getMonth() === date2.getMonth() &&
           date1.getFullYear() === date2.getFullYear();
  };

  const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  const days = getDaysInMonth(currentMonth);
  const selectedDateKey = getDateKey(selectedDate);
  const selectedDayMemories = memoriesData[selectedDateKey] || [];
  const selectedDayInsight = dailyInsightsData[selectedDateKey];
  const selectedWeeklyInsight = weeklyInsightsData[selectedDateKey];
  const selectedMonthlyInsight = monthlyInsightsData[selectedDateKey];
  
  // Filter todos for selected date
  // For today (March 5, 2026): show all 'Up Next' and 'Today' category todos
  // For other dates: only show todos with time
  const todayDate = new Date(2026, 2, 5); // March 5, 2026
  const isSelectedDateToday = isSameDate(selectedDate, todayDate);
  
  const selectedDayTodos = todos?.filter(todo => {
    if (isSelectedDateToday) {
      // For today: show all todos in 'Up Next' or 'Today' category
      return todo.category === 'Up Next' || todo.category === 'Today';
    } else {
      // For other dates: only show todos with time and matching dueDate
      if (!todo.time) return false;
      if (!todo.dueDate || todo.dueDate === 'No deadline') return false;
      
      const todoDate = new Date(todo.dueDate);
      return isSameDate(todoDate, selectedDate);
    }
  }) || [];
  
  // Filter memos for selected date
  const selectedDayMemos = memos?.filter(memo => {
    const memoDate = new Date(memo.timestamp);
    return isSameDate(memoDate, selectedDate);
  }) || [];
  
  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-[#f2f2f7] relative">
        <button 
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        <div className="absolute left-1/2 transform -translate-x-1/2 flex items-center gap-2">
          <CalendarIcon className="w-4.5 h-4.5 text-[#1c1c1e]" strokeWidth={2} />
          <h1 className="text-[17px] font-semibold text-[#1c1c1e]">
            {monthNames[selectedDate.getMonth()]} {selectedDate.getDate()}
          </h1>
        </div>
        <div className="w-5" /> {/* Spacer for centering */}
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto px-5 pb-24">
        
        {/* Calendar Card */}
        <div className="mt-4 mb-6 bg-white rounded-[20px] p-5 shadow-sm border border-black/[0.06]">
          {/* Month Navigation */}
          <div className="flex items-center justify-between mb-5">
            <button
              onClick={goToPreviousMonth}
              className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors"
            >
              <ChevronLeft className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2.5} />
            </button>
            <h2 className="text-[18px] font-semibold text-[#1c1c1e]">
              {monthNames[currentMonth.getMonth()]} {currentMonth.getFullYear()}
            </h2>
            <button
              onClick={goToNextMonth}
              className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors"
            >
              <ChevronRight className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2.5} />
            </button>
          </div>

          {/* Week Days */}
          <div className="grid grid-cols-7 gap-2 mb-3">
            {weekDays.map((day) => (
              <div key={day} className="text-center">
                <span className="text-[13px] font-medium text-[#8e8e93]">{day}</span>
              </div>
            ))}
          </div>

          {/* Calendar Days */}
          <div className="grid grid-cols-7 gap-2">
            {days.map((dayData, index) => {
              if (!dayData) {
                return <div key={`empty-${index}`} className="aspect-square" />;
              }

              const isSelected = isSameDate(dayData.date, selectedDate);
              const isTodayDate = isToday(dayData.date);

              return (
                <button
                  key={index}
                  onClick={() => setSelectedDate(dayData.date)}
                  className="aspect-square relative flex items-center justify-center"
                >
                  {/* Selected Date Background */}
                  {isSelected && (
                    <div className="absolute inset-0 rounded-full bg-[#007aff]" />
                  )}
                  
                  {/* Today Ring (if not selected) */}
                  {isTodayDate && !isSelected && (
                    <div className="absolute inset-0 rounded-full border-2 border-[#007aff]" />
                  )}

                  {/* Date Number */}
                  <span className={`text-[16px] font-medium relative z-10 ${
                    isSelected 
                      ? 'text-white' 
                      : isTodayDate 
                        ? 'text-[#007aff]'
                        : 'text-[#1c1c1e]'
                  }`}>
                    {dayData.date.getDate()}
                  </span>

                  {/* Indicator Dots for Memories and Todos */}
                  {(dayData.hasMemories || dayData.hasTodos) && !isSelected && (
                    <div className="absolute bottom-1 flex gap-0.5">
                      {dayData.hasMemories && (
                        <div className="w-1 h-1 rounded-full bg-[#34c759]" />
                      )}
                      {dayData.hasTodos && (
                        <div className="w-1 h-1 rounded-full bg-[#007aff]" />
                      )}
                    </div>
                  )}

                  {/* Indicator for Daily Insight */}
                  {dayData.hasDailyInsight && !isSelected && (
                    <div className="absolute top-1 right-1">
                      <div className="w-1.5 h-1.5 rounded-full bg-[#af52de]" />
                    </div>
                  )}

                  {/* Indicator for Weekly Insight */}
                  {dayData.hasWeeklyInsight && !isSelected && (
                    <div className="absolute top-1 left-1">
                      <div className="w-1.5 h-1.5 rounded-full bg-[#ea580c]" />
                    </div>
                  )}

                  {/* Indicator for Monthly Insight */}
                  {dayData.hasMonthlyInsight && !isSelected && (
                    <div className="absolute bottom-1 right-1">
                      <div className="w-1.5 h-1.5 rounded-full bg-[#d97706]" />
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Daily Insight Section */}
        {selectedDayInsight && (
          <div className="mb-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Daily Reflection</h3>
            <button
              onClick={() => onDailyInsightClick?.(selectedDayInsight)}
              className="w-full bg-gradient-to-br from-[#f3f0f8] via-[#f8f6fb] to-white rounded-[20px] p-5 shadow-sm border border-[#af52de]/10 text-left hover:shadow-md transition-all"
            >
              <div className="flex items-start gap-3 mb-4">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#af52de] to-[#9b3fce] flex items-center justify-center flex-shrink-0 shadow-sm">
                  <Sparkles className="w-5 h-5 text-white" strokeWidth={2} />
                </div>
                <p className="flex-1 text-[15px] text-[#3c3c43] leading-[1.5] pt-1.5">
                  {selectedDayInsight.summary}
                </p>
              </div>
              
              <div className="flex items-center gap-4 text-[13px]">
                <div className="flex items-center gap-1.5">
                  <CheckSquare className="w-4 h-4 text-[#af52de]" strokeWidth={2} />
                  <span className="text-[#3c3c43]">{selectedDayInsight.decisions} decisions made</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="text-[#af52de] font-semibold">•</span>
                  <span className="text-[#3c3c43]">{selectedDayInsight.followUps} follow-ups</span>
                </div>
                {selectedDayInsight.risks > 0 && (
                  <>
                    <div className="flex items-center gap-1.5">
                      <span className="text-[#ff9500] font-semibold">•</span>
                      <span className="text-[#3c3c43]">{selectedDayInsight.risks} risk to watch</span>
                    </div>
                  </>
                )}
              </div>
            </button>
          </div>
        )}

        {/* Weekly Insight Section */}
        {selectedWeeklyInsight && (
          <div className="mb-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Weekly Insight</h3>
            <button
              onClick={() => onWeeklyInsightClick?.(selectedWeeklyInsight)}
              className="w-full bg-gradient-to-br from-[#fff7ed] via-[#fff3e7] to-white rounded-[20px] p-5 shadow-sm border border-[#ea580c]/10 text-left hover:shadow-md transition-all"
            >
              <div className="flex items-start gap-3 mb-4">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#ea580c] to-[#c2410c] flex items-center justify-center flex-shrink-0 shadow-sm">
                  <BarChart3 className="w-5 h-5 text-white" strokeWidth={2} />
                </div>
                <p className="flex-1 text-[15px] text-[#3c3c43] leading-[1.5] pt-1.5">
                  {selectedWeeklyInsight.summary}
                </p>
              </div>
              
              <div className="flex items-center gap-4 text-[13px]">
                <div className="flex items-center gap-1.5">
                  <CheckSquare className="w-4 h-4 text-[#ea580c]" strokeWidth={2} />
                  <span className="text-[#3c3c43]">{selectedWeeklyInsight.completedCount} tasks completed</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="text-[#ea580c] font-semibold">•</span>
                  <span className="text-[#3c3c43]">{selectedWeeklyInsight.pendingCount} pending</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="text-[#ea580c] font-semibold">•</span>
                  <span className="text-[#3c3c43]">{selectedWeeklyInsight.recommendationsCount} recommendations</span>
                </div>
              </div>
            </button>
          </div>
        )}

        {/* Monthly Insight Section */}
        {selectedMonthlyInsight && (
          <div className="mb-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Monthly Insight</h3>
            <button
              onClick={() => onMonthlyInsightClick?.(selectedMonthlyInsight)}
              className="w-full bg-gradient-to-br from-[#fef3c7] via-[#fef6d8] to-white rounded-[20px] p-5 shadow-sm border border-[#d97706]/10 text-left hover:shadow-md transition-all"
            >
              <div className="flex items-start gap-3 mb-4">
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#d97706] to-[#b45309] flex items-center justify-center flex-shrink-0 shadow-sm">
                  <Compass className="w-5 h-5 text-white" strokeWidth={2} />
                </div>
                <p className="flex-1 text-[15px] text-[#3c3c43] leading-[1.5] pt-1.5">
                  {selectedMonthlyInsight.summary}
                </p>
              </div>
              
              <div className="flex items-center gap-4 text-[13px]">
                <div className="flex items-center gap-1.5">
                  <span className="text-[#d97706] font-semibold">•</span>
                  <span className="text-[#3c3c43]">{selectedMonthlyInsight.topicsCount} recurring topics</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="text-[#d97706] font-semibold">•</span>
                  <span className="text-[#3c3c43]">{selectedMonthlyInsight.openThreadsCount} open threads</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="text-[#d97706] font-semibold">•</span>
                  <span className="text-[#3c3c43]">{selectedMonthlyInsight.decisionsCount} critical decisions</span>
                </div>
              </div>
            </button>
          </div>
        )}

        {/* Memories Section */}
        {selectedDayMemories.length > 0 && (
          <div className="mb-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Memories that day</h3>
            <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06]">
              {selectedDayMemories.map((memory, index) => (
                <button
                  key={memory.id}
                  onClick={() => onMemoryClick(memory)}
                  className={`w-full px-5 py-3 flex items-start gap-3 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors ${
                    index !== selectedDayMemories.length - 1 ? 'border-b border-black/[0.06]' : ''
                  }`}
                >
                  <div className="flex-1">
                    {/* Title - First Line */}
                    <h4 className="text-[15px] font-medium text-[#1c1c1e] mb-1.5 leading-[1.3]">
                      {memory.title}
                    </h4>
                    
                    {/* Time + Icons - Second Line */}
                    <div className="flex items-center gap-2">
                      <Clock className="w-3.5 h-3.5 text-[#8e8e93]" strokeWidth={2} />
                      <span className="text-[13px] text-[#8e8e93]">{memory.time}</span>
                      
                      <div className="flex items-center gap-1.5 ml-1">
                        {memory.hasAudio && (
                          <div className="w-5 h-5 rounded-md bg-[#007aff]/10 flex items-center justify-center">
                            <Mic className="w-3 h-3 text-[#007aff]" strokeWidth={2} />
                          </div>
                        )}
                        {memory.hasSummary && (
                          <div className="w-5 h-5 rounded-md bg-[#34c759]/10 flex items-center justify-center">
                            <FileText className="w-3 h-3 text-[#34c759]" strokeWidth={2} />
                          </div>
                        )}
                        {memory.hasActivity && (
                          <div className="w-5 h-5 rounded-md bg-[#ff9500]/10 flex items-center justify-center">
                            <Activity className="w-3 h-3 text-[#ff9500]" strokeWidth={2} />
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0 mt-1" strokeWidth={2.5} />
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Memos Section */}
        {selectedDayMemos.length > 0 && (
          <div className="mb-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Memos that day</h3>
            <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06]">
              {selectedDayMemos.map((memo, index) => (
                <button
                  key={memo.id}
                  onClick={() => onMemoClick?.(memo)}
                  className={`w-full px-5 py-3 flex items-start gap-3 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors ${
                    index !== selectedDayMemos.length - 1 ? 'border-b border-black/[0.06]' : ''
                  }`}
                >
                  <div className="flex-1">
                    <h4 className="text-[15px] font-medium text-[#1c1c1e] mb-1 leading-[1.3]">
                      {memo.title}
                    </h4>
                    <p className="text-[13px] text-[#8e8e93] leading-[1.4] line-clamp-2">
                      {memo.content}
                    </p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0 mt-1" strokeWidth={2.5} />
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Todos Section */}
        {selectedDayTodos.length > 0 && (
          <div className="mb-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">To-Dos that day</h3>
            <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06]">
              {selectedDayTodos.map((todo, index) => (
                <button
                  key={todo.id}
                  onClick={() => setSelectedTodo(todo)}
                  className={`w-full px-5 py-3.5 flex items-center gap-3 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors ${
                    index !== selectedDayTodos.length - 1 ? 'border-b border-black/[0.06]' : ''
                  }`}
                >
                  <div className="flex-shrink-0">
                    {todo.completed ? (
                      <CheckSquare className="w-[18px] h-[18px] text-[#34c759]" strokeWidth={2} />
                    ) : (
                      <Square className="w-[18px] h-[18px] text-[#6c6c70]" strokeWidth={1.8} />
                    )}
                  </div>
                  <div className="flex-1">
                    <span className={`text-[15px] ${
                      todo.completed 
                        ? 'text-[#8e8e93] line-through' 
                        : 'text-[#1c1c1e]'
                    }`}>
                      {todo.title}
                    </span>
                  </div>
                  {todo.time && (
                    <span className="flex-shrink-0 text-[13px] text-[#8e8e93] font-medium">
                      {todo.time}
                    </span>
                  )}
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>
              ))}
            </div>
          </div>
        )}

        {/* No Memories State */}
        {selectedDayMemories.length === 0 && !selectedDayInsight && !selectedWeeklyInsight && !selectedMonthlyInsight && (
          <div className="mt-12 flex flex-col items-center text-center px-6">
            <div className="w-20 h-20 rounded-full bg-[#f2f2f7] flex items-center justify-center mb-4">
              <CalendarIcon className="w-10 h-10 text-[#8e8e93]" strokeWidth={2} />
            </div>
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">No memories that day</h3>
            <p className="text-[14px] text-[#8e8e93] max-w-sm">
              There are no recorded memories or insights for {monthNames[selectedDate.getMonth()]} {selectedDate.getDate()}, {selectedDate.getFullYear()}
            </p>
          </div>
        )}

        {/* Memory Graph Summary */}
        <MemoryGraphSummary
          timeRange={timeRange}
          setTimeRange={setTimeRange}
        />
      </div>

      {/* Todo Detail Modals */}
      {selectedTodo && (
        selectedTodo.category === 'Completed' ? (
          <CompletedTodoDetailModal
            todo={selectedTodo}
            onClose={() => setSelectedTodo(null)}
            onRestore={() => handleRestore(selectedTodo.id)}
            onDelete={() => handleDelete(selectedTodo.id)}
          />
        ) : (
          <TodoDetailModal
            todo={selectedTodo}
            onClose={() => setSelectedTodo(null)}
            onToggle={() => toggleTodo(selectedTodo.id)}
            onMarkDone={() => handleMarkDone(selectedTodo.id)}
            onNotNow={() => handleNotNow(selectedTodo.id)}
            onDelete={() => handleDelete(selectedTodo.id)}
            onUpdate={handleUpdateTodo}
            onLinkMemory={onLinkMemory}
            onMemoryClick={onMemoryClickFromTodo}
          />
        )
      )}
    </div>
  );
}