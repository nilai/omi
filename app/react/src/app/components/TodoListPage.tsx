import { ChevronLeft, Square, CheckSquare, Mic, Search, ChevronDown, ChevronUp, ArrowUp, X, Check, Star } from 'lucide-react';
import { useState, useEffect, useCallback, useRef } from 'react';
import { format, parse } from 'date-fns';
import { TodoDetailModal } from './TodoDetailModal';
import { CompletedTodoDetailModal } from './CompletedTodoDetailModal';
import { NewTodoFromMemoModal } from './NewTodoFromMemoModal';
import { EmptyState } from './EmptyState';
import { ErrorState } from './ErrorState';
import { useDevMode } from '../contexts/DevModeContext';

interface LinkedMemory {
  id: string;
  title: string;
  date: string;
  duration?: string;
  hasSummary?: boolean;
}

interface Todo {
  id: number;
  title: string;
  completed: boolean;
  category: 'Up Next' | 'Today' | 'Upcoming' | 'Later' | 'Overdue' | 'Completed';
  linkedMemory?: LinkedMemory;
  context?: string;
  time?: string;
  notes?: string[];
  priority?: string;
  dueDate?: string;
  reason?: string; // Add reason field
  isNew?: boolean; // Mark todos created in empty state
}

interface TodoListPageProps {
  onBack: () => void;
  todoFromMemo?: any;
  todos?: Todo[];
  setTodos?: (todos: Todo[]) => void;
  onLinkMemory?: (todoId: number) => void;
  onMemoryClick?: (memoryId: string) => void;
}

export function TodoListPage({ onBack, todoFromMemo, todos: propTodos, setTodos: propSetTodos, onLinkMemory, onMemoryClick }: TodoListPageProps) {
  const { devMode } = useDevMode();
  // Use prop todos if provided, otherwise fall back to local state
  const isControlled = propTodos !== undefined && propSetTodos !== undefined;
  
  const [localTodos, setLocalTodos] = useState<Todo[]>([
    // Up Next
    { 
      id: 1, 
      title: 'Review migration milestones with infrastructure team', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      notes: 'Need to confirm their availability for next sprint\nFocus on authentication service timeline', 
      priority: 'High priority', 
      dueDate: 'Mar 10',
      time: '09:00',
      category: 'Up Next',
      completed: false,
      context: 'Meeting scheduled today'
    },
    { 
      id: 3, 
      title: 'Follow up with Sarah about design feedback', 
      linkedMemory: {
        id: '3',
        title: 'Review session for new dashboard designs',
        date: 'Jan 27',
        duration: '15 min',
        hasSummary: true
      },
      notes: 'Wait for her return from vacation', 
      priority: 'Normal', 
      dueDate: 'Mar 10',
      time: '14:00',
      category: 'Up Next',
      completed: false,
      context: 'Design feedback pending'
    },
    { 
      id: 4, 
      title: 'Finalize API migration timeline', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      notes: 'Include authentication service and parallel execution strategy', 
      priority: 'High priority', 
      dueDate: 'Mar 11',
      time: '16:30',
      category: 'Up Next',
      completed: false,
      context: 'Project deadline soon'
    },
    // Today
    { 
      id: 5, 
      title: 'Update API documentation for v2 endpoints', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      notes: 'Confirm final numbers', 
      priority: 'High priority', 
      dueDate: 'Mar 9',
      time: '09:00',
      category: 'Today',
      completed: false
    },
    { 
      id: 6, 
      title: 'Review budget notes', 
      priority: 'Normal', 
      dueDate: 'Mar 9',
      time: '11:00',
      category: 'Today',
      completed: false
    },
    { 
      id: 7, 
      title: 'Revise marketing deck with ADHD-focused messaging', 
      linkedMemory: {
        id: '7',
        title: 'Product launch planning with marketing team',
        date: 'Today',
        duration: '22 min',
        hasSummary: true
      },
      notes: 'Lead with user stories\nRemove generic productivity language\nGet feedback from beta users',
      priority: 'High priority', 
      dueDate: 'Mar 10',
      time: '14:00',
      category: 'Today',
      completed: false
    },
    { 
      id: 8, 
      title: 'Update pitch deck with Q1 metrics', 
      linkedMemory: {
        id: '8',
        title: 'Investor meeting - Series A funding discussion',
        date: 'Yesterday',
        duration: '45 min',
        hasSummary: true
      },
      notes: 'Include retention numbers and unit economics',
      priority: 'High priority', 
      dueDate: 'Mar 12',
      time: '10:00',
      category: 'Today',
      completed: false
    },
    // Upcoming
    { 
      id: 9, 
      title: 'Schedule follow-up with lead investor', 
      linkedMemory: {
        id: '8',
        title: 'Investor meeting - Series A funding discussion',
        date: 'Yesterday',
        duration: '45 min',
        hasSummary: true
      },
      notes: 'Confirm availability for next week', 
      priority: 'High priority', 
      dueDate: 'Mar 15',
      time: '10:00',
      category: 'Upcoming',
      completed: false
    },
    { 
      id: 10, 
      title: 'Prepare beta onboarding materials',
      linkedMemory: {
        id: '7',
        title: 'Product launch planning with marketing team',
        date: 'Today',
        duration: '22 min',
        hasSummary: true
      },
      notes: 'Include welcome email and setup guide',
      priority: 'Normal', 
      dueDate: 'Mar 20',
      time: '14:00',
      category: 'Upcoming',
      completed: false
    },
    { 
      id: 11, 
      title: 'Schedule team building event', 
      linkedMemory: {
        id: '2',
        title: 'Coffee chat with Jordan about team dynamics',
        date: 'Jan 28',
        duration: '8 min',
        hasSummary: true
      },
      priority: 'Low priority', 
      dueDate: 'Mar 12, 2026',
      time: '16:00',
      category: 'Upcoming',
      completed: false
    },
    { 
      id: 12, 
      title: 'Research new collaboration tools', 
      priority: 'Low priority', 
      dueDate: 'Mar 9, 2026',
      time: '11:30',
      category: 'Upcoming',
      completed: false
    },
    { 
      id: 21, 
      title: 'Book flight for conference', 
      priority: 'Normal', 
      dueDate: 'Mar 14',
      time: '13:00',
      category: 'Upcoming',
      completed: false
    },
    { 
      id: 22, 
      title: 'Update team calendar', 
      priority: 'Low priority', 
      dueDate: 'Mar 16',
      time: '10:30',
      category: 'Upcoming',
      completed: false
    },
    // Later
    { 
      id: 13, 
      title: 'Explore productivity ideas', 
      linkedMemory: {
        id: '1',
        title: 'Team standup discussion on API migration',
        date: 'Jan 28',
        duration: '12 min',
        hasSummary: true
      },
      priority: 'Low priority', 
      dueDate: 'Aug 10, 2026',
      time: '09:30',
      category: 'Later',
      completed: false
    },
    { 
      id: 14, 
      title: 'Organize old notes', 
      linkedMemory: {
        id: '3',
        title: 'Review session for new dashboard designs',
        date: 'Jan 27',
        duration: '15 min',
        hasSummary: true
      },
      priority: 'Low priority', 
      dueDate: 'Mar 18, 2026',
      time: '15:30',
      category: 'Later',
      completed: false
    },
    { 
      id: 15, 
      title: 'Clean up desktop', 
      priority: 'Low priority', 
      dueDate: 'Aug 18, 2026',
      time: '11:00',
      category: 'Later',
      completed: false
    },
    { 
      id: 16, 
      title: 'Read through archive folder', 
      priority: 'Low priority', 
      dueDate: 'Apr 5, 2026',
      time: '10:00',
      category: 'Later',
      completed: false
    },
    { 
      id: 17, 
      title: 'Review industry reports', 
      linkedMemory: {
        id: '2',
        title: 'Coffee chat with Jordan about team dynamics',
        date: 'Jan 28',
        duration: '8 min',
        hasSummary: true
      },
      priority: 'Low priority', 
      dueDate: 'Mar 20, 2026',
      time: '13:00',
      category: 'Later',
      completed: false
    },
    // Overdue
    { 
      id: 18, 
      title: 'Send invoice', 
      priority: 'Normal', 
      dueDate: 'Mar 4, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 19, 
      title: 'Submit expense report', 
      priority: 'Normal', 
      dueDate: 'Mar 3, 2026',
      time: '14:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 20, 
      title: 'Review investor deck', 
      priority: 'High priority', 
      dueDate: 'Mar 2, 2026',
      time: '09:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 23, 
      title: 'Call dentist for appointment', 
      priority: 'Normal', 
      dueDate: 'Mar 1, 2026',
      time: '10:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 24, 
      title: 'Reply to client email', 
      priority: 'High priority', 
      dueDate: 'Feb 28, 2026',
      time: '15:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 25, 
      title: 'Update website copy', 
      priority: 'Normal', 
      dueDate: 'Feb 27, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 26, 
      title: 'Renew software license', 
      priority: 'High priority', 
      dueDate: 'Feb 26, 2026',
      time: '11:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 27, 
      title: 'Order office supplies', 
      priority: 'Low priority', 
      dueDate: 'Feb 25, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 28, 
      title: 'Review contract terms', 
      priority: 'Normal', 
      dueDate: 'Feb 24, 2026',
      time: '16:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 29, 
      title: 'Schedule doctor appointment', 
      priority: 'Normal', 
      dueDate: 'Feb 23, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 30, 
      title: 'Pay utility bill', 
      priority: 'High priority', 
      dueDate: 'Feb 22, 2026',
      time: '12:00',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 31, 
      title: 'Send thank you notes', 
      priority: 'Low priority', 
      dueDate: 'Feb 21, 2026',
      category: 'Overdue',
      completed: false
    },
    { 
      id: 32, 
      title: 'Update LinkedIn profile', 
      priority: 'Low priority', 
      dueDate: 'Feb 20, 2026',
      time: '13:30',
      category: 'Overdue',
      completed: false
    }
  ]);

  const [showRecordingInput, setShowRecordingInput] = useState(false);
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [todoInputText, setTodoInputText] = useState('');
  const [quickInputText, setQuickInputText] = useState(''); // For the "Add something you need to do" input
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribing, setIsTranscribing] = useState(false);
  const [isVoiceInput, setIsVoiceInput] = useState(false);
  const [laterCollapsed, setLaterCollapsed] = useState(false);
  const [overdueCollapsed, setOverdueCollapsed] = useState(false);
  const [completedCollapsed, setCompletedCollapsed] = useState(false);
  const [selectedTodo, setSelectedTodo] = useState<Todo | null>(null);
  const [isNewTodoFromMemo, setIsNewTodoFromMemo] = useState(false);
  const [swipedTodoId, setSwipedTodoId] = useState<number | null>(null);
  const [swipedTodoIdRight, setSwipedTodoIdRight] = useState<number | null>(null);
  const [showReplaceFocusModal, setShowReplaceFocusModal] = useState(false);
  const [todoToAdd, setTodoToAdd] = useState<number | null>(null);
  const [dismissedSuggestion, setDismissedSuggestion] = useState(false);

  const quickInputRef = useRef<HTMLTextAreaElement>(null);

  const suggestions = ['Budget', 'Team meeting', 'CES', 'Design feedback'];

  // Use controlled todos if provided, otherwise use local state
  const todos = isControlled ? propTodos! : localTodos;
  const setTodos = isControlled ? propSetTodos! : setLocalTodos;

  // In empty mode, only show new todos (created via Quick Capture)
  const filteredTodos = devMode === 'empty' 
    ? todos.filter((t: any) => t.isNew) 
    : todos;

  // Auto-resize textarea when quickInputText changes
  useEffect(() => {
    if (quickInputRef.current) {
      quickInputRef.current.style.height = 'auto';
      quickInputRef.current.style.height = Math.min(quickInputRef.current.scrollHeight, 120) + 'px';
    }
  }, [quickInputText]);

  const toggleTodo = (id: number) => {
    setTodos(todos.map(todo => {
      if (todo.id === id) {
        const newCompleted = !todo.completed;
        return {
          ...todo,
          completed: newCompleted,
          // If marking as completed, move to Completed category
          // If uncompleting, move back to Today category
          category: newCompleted ? 'Completed' : 'Today'
        };
      }
      return todo;
    }));
  };

  const handleMarkDone = (id: number) => {
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, completed: true, category: 'Completed' } : todo
    ));
    setSelectedTodo(null);
  };

  const handleNotNow = (id: number) => {
    // Move to Later category
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, category: 'Later' } : todo
    ));
    setSelectedTodo(null);
  };

  const handleDelete = (id: number) => {
    setTodos(todos.filter(todo => todo.id !== id));
    setSelectedTodo(null);
  };

  const handleRestore = (id: number) => {
    // Restore completed todo back to Today category
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, completed: false, category: 'Today' } : todo
    ));
    setSelectedTodo(null);
  };

  const handleUpdateTodo = useCallback((id: number, updates: any) => {
    // Update todo with new priority or due date
    setTodos(prevTodos => prevTodos.map(todo => {
      if (todo.id === id) {
        return {
          ...todo,
          ...updates
        };
      }
      return todo;
    }));
    // Don't update selectedTodo here to avoid causing re-render loop in TodoDetailModal
    // The modal manages its own state and will sync on close
  }, []);

  const clearLaterTodos = () => {
    // Move all Later todos to Completed and mark them as completed
    setTodos(todos.map(todo => 
      todo.category === 'Later' 
        ? { ...todo, completed: true, category: 'Completed' } 
        : todo
    ));
  };

  const clearOverdueTodos = () => {
    // Move all Overdue todos to Completed and mark them as completed
    setTodos(todos.map(todo => 
      todo.category === 'Overdue' 
        ? { ...todo, completed: true, category: 'Completed' } 
        : todo
    ));
  };

  const handleSaveTodo = () => {
    if (!todoInputText.trim()) return;
    
    // Function to detect if text contains time information
    const hasTimeInfo = (text: string): boolean => {
      const lowerText = text.toLowerCase();
      // Check for explicit time keywords
      const timeKeywords = [
        'today', 'tomorrow', 'tonight', 'morning', 'afternoon', 'evening',
        'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
        'this week', 'next week', 'this month', 'next month',
        'am', 'pm', 'o\'clock', 'oclock',
        'january', 'february', 'march', 'april', 'may', 'june',
        'july', 'august', 'september', 'october', 'november', 'december'
      ];
      
      // Check for time patterns like "3pm", "15:00", "at 3"
      const timePatterns = [
        /\d{1,2}:\d{2}/, // 14:30, 3:45
        /\d{1,2}\s*(am|pm)/, // 3pm, 3 pm
        /at\s+\d{1,2}/, // at 3
        /\d{1,2}\/\d{1,2}/, // 3/5, 03/05
        /\d{1,2}-\d{1,2}/ // 3-5, 03-05
      ];
      
      // Check for keywords
      for (const keyword of timeKeywords) {
        if (lowerText.includes(keyword)) return true;
      }
      
      // Check for patterns
      for (const pattern of timePatterns) {
        if (pattern.test(lowerText)) return true;
      }
      
      return false;
    };
    
    // Determine due date and time based on whether time info is present
    const hasTimeInText = hasTimeInfo(todoInputText);
    const determinedDueDate = !hasTimeInText ? 'No deadline' : 'Today';
    
    const newTodo: Todo = {
      id: todos.length + 1,
      title: todoInputText.trim(),
      completed: false,
      category: 'Today',
      context: isVoiceInput ? 'Added via voice input' : "Added from Today's Focus",
      time: undefined, // Don't set time here, let user set it in detail modal if needed
      priority: 'Normal',
      dueDate: determinedDueDate
    };
    
    setTodos([newTodo, ...todos]);
    setTodoInputText('');
    setShowRecordingInput(false);
    setIsVoiceInput(false);
  };

  const handleCancelInput = () => {
    setTodoInputText('');
    setShowRecordingInput(false);
    setIsRecording(false);
    setIsTranscribing(false);
    setIsVoiceInput(false);
  };

  const handleStartRecording = () => {
    setIsRecording(true);
    setIsVoiceInput(true);
  };

  const handleCancelRecording = () => {
    setIsRecording(false);
    setIsTranscribing(false);
    setIsVoiceInput(false);
  };

  const handleQuickInputSubmit = () => {
    if (quickInputText.trim()) {
      const newTodo: Todo = {
        id: Date.now(),
        title: quickInputText,
        completed: false,
        category: 'Today',
        dueDate: 'No Deadline',
        isNew: true
      };
      setTodos([...todos, newTodo]);
      setQuickInputText('');
    }
  };

  const handleSendVoice = () => {
    setIsRecording(false);
    setIsTranscribing(true);
    
    // Simulate voice transcription
    setTimeout(() => {
      const transcribedText = "Review the new product roadmap and prepare feedback for tomorrow's meeting";
      
      // If in overlay mode (not showRecordingInput), fill the quick input box
      if (!showRecordingInput) {
        setQuickInputText(transcribedText);
        setIsTranscribing(false);
        setIsVoiceInput(false);
      } else {
        // If in modal mode, just set the text
        setTodoInputText(transcribedText);
        setIsTranscribing(false);
      }
    }, 2000);
  };

  // Handle removing from Today's Focus (move from "Up Next" to "Today")
  const handleRemoveFromFocus = (id: number) => {
    setTodos(todos.map(todo => 
      todo.id === id ? { ...todo, category: 'Today' } : todo
    ));
    setSwipedTodoId(null);
  };

  // Handle adding to Today's Focus
  const handleAddToFocus = (id: number) => {
    const currentFocusCount = upNextTodos.length;
    
    // Get today's date from existing Up Next todos to maintain consistency
    const todayDate = upNextTodos.length > 0 && upNextTodos[0].dueDate 
      ? upNextTodos[0].dueDate 
      : format(new Date(), 'MMM d');
    
    if (currentFocusCount < 3) {
      // Directly add to focus
      setTodos(todos.map(todo => 
        todo.id === id 
          ? { ...todo, category: 'Up Next', reason: 'Marked as priority today', dueDate: todayDate } 
          : todo
      ));
      setSwipedTodoIdRight(null);
    } else {
      // Show replacement modal
      setTodoToAdd(id);
      setShowReplaceFocusModal(true);
      setSwipedTodoIdRight(null);
    }
  };

  // Handle replacing a focus item
  const handleReplaceFocus = (oldId: number, newId: number) => {
    // Get today's date from existing Up Next todos to maintain consistency
    const todayDate = upNextTodos.length > 0 && upNextTodos[0].dueDate 
      ? upNextTodos[0].dueDate 
      : format(new Date(), 'MMM d');
    
    setTodos(todos.map(todo => {
      if (todo.id === oldId) {
        // Move old todo to Today category
        return { ...todo, category: 'Today' };
      }
      if (todo.id === newId) {
        // Move new todo to Up Next category
        return { ...todo, category: 'Up Next', reason: 'Marked as priority today', dueDate: todayDate };
      }
      return todo;
    }));
    setShowReplaceFocusModal(false);
    setTodoToAdd(null);
  };

  // Helper function to format time display for Upcoming and Later
  const formatTimeDisplay = (todo: Todo, section: 'upcoming' | 'later') => {
    if (!todo.time) return null;
    
    if (section === 'upcoming' && todo.dueDate && todo.dueDate !== 'No deadline') {
      try {
        const date = parse(todo.dueDate, 'MMM d, yyyy', new Date());
        const dayOfWeek = format(date, 'EEE');
        return `${dayOfWeek} ${todo.time}`;
      } catch {
        return todo.time;
      }
    }
    
    if (section === 'later' && todo.dueDate && todo.dueDate !== 'No deadline') {
      try {
        const date = parse(todo.dueDate, 'MMM d, yyyy', new Date());
        const monthDay = format(date, 'MMM d');
        return `${monthDay} ${todo.time}`;
      } catch {
        return todo.time;
      }
    }
    
    return todo.time;
  };

  // Helper function to convert time string to minutes for sorting
  const timeToMinutes = (timeStr: string | undefined): number => {
    if (!timeStr) return Infinity; // No time goes to the end
    
    try {
      // Check if time has AM/PM
      const hasAMPM = /[AP]M/i.test(timeStr);
      
      if (hasAMPM) {
        // Handle 12-hour format (e.g., "3:00 PM", "11:30 AM")
        const [time, period] = timeStr.split(/\s*([AP]M)/i);
        let [hours, minutes] = time.split(':').map(Number);
        
        if (!minutes) minutes = 0;
        
        if (period?.toUpperCase() === 'PM' && hours !== 12) {
          hours += 12;
        } else if (period?.toUpperCase() === 'AM' && hours === 12) {
          hours = 0;
        }
        
        return hours * 60 + minutes;
      } else {
        // Handle 24-hour format (e.g., "09:00", "14:00", "16:30")
        const [hours, minutes] = timeStr.split(':').map(Number);
        return hours * 60 + (minutes || 0);
      }
    } catch {
      return Infinity;
    }
  };

  // Helper function to parse date string to Date object
  const parseDate = (dateStr: string | undefined): Date | null => {
    if (!dateStr || dateStr === 'No deadline') return null;
    
    try {
      // Try different date formats
      const formats = ['MMM d, yyyy', 'MMM d', 'yyyy-MM-dd'];
      for (const formatStr of formats) {
        try {
          const parsed = parse(dateStr, formatStr, new Date());
          if (!isNaN(parsed.getTime())) return parsed;
        } catch {
          continue;
        }
      }
      return null;
    } catch {
      return null;
    }
  };

  // Sort function for todos
  const sortTodosByDateTime = (a: Todo, b: Todo): number => {
    const dateA = parseDate(a.dueDate);
    const dateB = parseDate(b.dueDate);
    
    // Both have dates - compare dates first
    if (dateA && dateB) {
      const dateDiff = dateA.getTime() - dateB.getTime();
      if (dateDiff !== 0) return dateDiff;
      
      // Same date - compare times
      const timeA = timeToMinutes(a.time);
      const timeB = timeToMinutes(b.time);
      return timeA - timeB;
    }
    
    // Only A has date
    if (dateA && !dateB) return -1;
    
    // Only B has date
    if (!dateA && dateB) return 1;
    
    // Neither has date - compare by time only
    const timeA = timeToMinutes(a.time);
    const timeB = timeToMinutes(b.time);
    return timeA - timeB;
  };

  const upNextTodos = filteredTodos
    .filter(t => t.category === 'Up Next')
    .sort(sortTodosByDateTime);
  
  // Today section includes both 'Today' and 'Up Next' categories
  // Sort by time from early to late
  const todayTodos = filteredTodos
    .filter(t => t.category === 'Today' || t.category === 'Up Next')
    .sort(sortTodosByDateTime);
  
  const upcomingTodos = filteredTodos
    .filter(t => t.category === 'Upcoming')
    .sort(sortTodosByDateTime);
    
  const laterTodos = filteredTodos
    .filter(t => t.category === 'Later')
    .sort(sortTodosByDateTime);
    
  const overdueTodos = filteredTodos.filter(t => t.category === 'Overdue');
  const completedTodos = filteredTodos.filter(t => t.category === 'Completed');

  // Get AI suggestion for Today's Focus
  const getSuggestedTodo = (): Todo | null => {
    if (upNextTodos.length >= 3 || dismissedSuggestion) return null;
    
    // Get todos from Today category only (exclude Up Next)
    const todayOnlyTodos = filteredTodos
      .filter(t => t.category === 'Today')
      .sort(sortTodosByDateTime);
    
    if (todayOnlyTodos.length === 0) return null;
    
    // Return the first todo with time, or the first todo if none have time
    const todoWithTime = todayOnlyTodos.find(t => t.time);
    return todoWithTime || todayOnlyTodos[0];
  };

  const suggestedTodo = getSuggestedTodo();

  // Generate suggestion reason
  const getSuggestionReason = (todo: Todo): string => {
    if (todo.time && todo.dueDate && todo.dueDate !== 'No deadline') {
      const date = parseDate(todo.dueDate);
      if (date) {
        const today = new Date();
        const isToday = date.toDateString() === today.toDateString();
        if (isToday) {
          return `Meeting at ${todo.time}`;
        }
      }
    }
    if (todo.time) {
      return `Scheduled for ${todo.time}`;
    }
    if (todo.priority === 'High priority') {
      return 'High priority task';
    }
    if (todo.linkedMemory) {
      return 'Related to recent memory';
    }
    return 'Important task for today';
  };

  const handleAddSuggestionToFocus = () => {
    if (!suggestedTodo) return;
    
    // Get today's date from existing Up Next todos to maintain consistency
    const todayDate = upNextTodos.length > 0 && upNextTodos[0].dueDate 
      ? upNextTodos[0].dueDate 
      : format(new Date(), 'MMM d');
    
    setTodos(todos.map(todo => 
      todo.id === suggestedTodo.id 
        ? { ...todo, category: 'Up Next', reason: getSuggestionReason(suggestedTodo), dueDate: todayDate } 
        : todo
    ));
    setDismissedSuggestion(false);
  };

  const handleDismissSuggestion = () => {
    setDismissedSuggestion(true);
  };

  // Handle Error State
  if (devMode === 'error') {
    return (
      <div className="h-full flex flex-col bg-[#f2f2f7]">
        <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
          <button 
            onClick={onBack}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
          </button>
          <h1 className="absolute left-1/2 transform -translate-x-1/2 text-[17px] font-semibold text-[#1c1c1e]">
            All To-Dos
          </h1>
          <div className="w-5" />
        </div>
        <ErrorState
          title="Unable to load tasks"
          description="Please check your connection."
          onRetry={() => {
            console.log('Retry clicked');
          }}
        />
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {!showSearch ? (
        <>
        {/* Header */}
        <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
          <button 
            onClick={onBack}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
          </button>
          <h1 className="absolute left-1/2 transform -translate-x-1/2 text-[17px] font-semibold text-[#1c1c1e]">
            All To-Dos
          </h1>
          <button 
            onClick={() => setShowSearch(true)}
            className="w-8 h-8 flex items-center justify-center text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <Search className="w-5 h-5" strokeWidth={2.5} />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-auto px-5 pt-4 pb-6">
          
          {/* Up Next Section - Featured Card */}
          <div className="mb-6 bg-gradient-to-br from-[#e8f5f1] via-white to-[#f0f9f6] rounded-[20px] p-6 shadow-[0_4px_16px_rgba(45,90,71,0.12),0_1px_4px_rgba(45,90,71,0.08)] border-2 border-[#2d5a47]/10">
            <h2 className="text-[17px] text-[#1c1c1e] font-semibold mb-4">Today's Focus</h2>
            
            <div className="space-y-4">
              {upNextTodos.map((todo) => {
                const isSwiped = swipedTodoId === todo.id;
                
                return (
                  <div key={todo.id} className="w-full relative overflow-hidden">
                    {/* Swipeable container */}
                    <div 
                      className="relative"
                      onTouchStart={(e) => {
                        const touch = e.touches[0];
                        const startX = touch.clientX;
                        
                        const handleTouchMove = (e: TouchEvent) => {
                          const touch = e.touches[0];
                          const diff = startX - touch.clientX;
                          
                          if (diff > 80) {
                            setSwipedTodoId(todo.id);
                            document.removeEventListener('touchmove', handleTouchMove);
                            document.removeEventListener('touchend', handleTouchEnd);
                          }
                        };
                        
                        const handleTouchEnd = () => {
                          document.removeEventListener('touchmove', handleTouchMove);
                          document.removeEventListener('touchend', handleTouchEnd);
                        };
                        
                        document.addEventListener('touchmove', handleTouchMove);
                        document.addEventListener('touchend', handleTouchEnd);
                      }}
                      onMouseDown={(e) => {
                        const startX = e.clientX;
                        
                        const handleMouseMove = (e: MouseEvent) => {
                          const diff = startX - e.clientX;
                          
                          if (diff > 80) {
                            setSwipedTodoId(todo.id);
                            document.removeEventListener('mousemove', handleMouseMove);
                            document.removeEventListener('mouseup', handleMouseUp);
                          }
                        };
                        
                        const handleMouseUp = () => {
                          document.removeEventListener('mousemove', handleMouseMove);
                          document.removeEventListener('mouseup', handleMouseUp);
                        };
                        
                        document.addEventListener('mousemove', handleMouseMove);
                        document.addEventListener('mouseup', handleMouseUp);
                      }}
                      style={{
                        transform: isSwiped ? 'translateX(-120px)' : 'translateX(0)',
                        transition: 'transform 0.3s ease-out'
                      }}
                    >
                      {/* 第一行：⭐ 标题 + 时间（右对齐） */}
                      <button
                        onClick={() => {
                          if (!isSwiped) {
                            setSelectedTodo(todo);
                          } else {
                            setSwipedTodoId(null);
                          }
                        }}
                        className="w-full flex items-start gap-3 hover:opacity-70 transition-opacity text-left"
                      >
                        <div className="flex-shrink-0 mt-[2px]">
                          <Star className="w-4 h-4 text-[#f59e42]" strokeWidth={2} fill="none" />
                        </div>
                        <span className={`flex-1 leading-[1.5] text-[15px] text-[#3c3c43] ${todo.completed ? 'line-through opacity-50' : ''}`}>
                          {todo.title}
                        </span>
                        {todo.time && (
                          <span className="flex-shrink-0 text-[13px] text-[#8e8e93] font-medium">{todo.time}</span>
                        )}
                      </button>
                      
                      {/* 第二行：→ 推荐原因（不可点击） */}
                      {(todo.reason || todo.context) && (
                        <div className="flex items-center gap-3 mt-1.5 ml-7">
                          <span className="text-[13px] text-[#8e8e93]">→ {todo.reason || todo.context}</span>
                        </div>
                      )}
                    </div>
                    
                    {/* Remove from Focus button - revealed on swipe */}
                    {isSwiped && (
                      <button
                        onClick={() => handleRemoveFromFocus(todo.id)}
                        className="absolute right-0 top-0 h-full w-[120px] bg-[#ff3b30] flex items-center justify-center text-white text-[13px] font-medium"
                      >
                        Remove from Focus
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Divider after Today's Focus */}
          <div className="mb-6">
            <div className="h-[1px] bg-gradient-to-r from-transparent via-black/[0.15] to-transparent" />
          </div>

          {/* AI Suggestion Card */}
          {suggestedTodo && (
            <div className="mb-6 bg-white rounded-[16px] p-5 shadow-[0_2px_8px_rgba(0,0,0,0.08)] border border-black/[0.06] relative">
              {/* Close button */}
              <button
                onClick={handleDismissSuggestion}
                className="absolute top-3 right-3 w-7 h-7 flex items-center justify-center text-[#8e8e93] hover:bg-black/[0.05] rounded-full transition-colors"
              >
                <X className="w-4 h-4" strokeWidth={2.5} />
              </button>

              {/* Suggested by AI label */}
              <div className="text-[11px] font-semibold text-[#8e8e93] tracking-wide uppercase mb-3">
                Suggested by AI
              </div>

              {/* Todo title */}
              <h3 className="text-[17px] text-[#1c1c1e] font-medium mb-1.5 pr-6">
                {suggestedTodo.title}
              </h3>

              {/* Reason */}
              <div className="flex items-center gap-1.5 mb-5">
                <span className="text-[15px] text-[#8e8e93]">→</span>
                <span className="text-[15px] text-[#8e8e93]">
                  {getSuggestionReason(suggestedTodo)}
                </span>
              </div>

              {/* Add to Focus button */}
              <button
                onClick={handleAddSuggestionToFocus}
                className="w-full bg-[#007aff] text-white text-[15px] font-semibold py-3 rounded-[12px] hover:bg-[#0051d5] transition-colors"
              >
                Add to Focus
              </button>
            </div>
          )}

          {/* All Todos Title with top divider */}
          <div className="mb-5">
            <h2 className="text-[17px] text-[#1c1c1e] font-bold tracking-wide uppercase px-2 mb-4">All To Dos</h2>
            
            {/* Add New Input */}
            <div className="px-2 mb-5 relative">
              <div className="w-full bg-white rounded-[14px] px-5 py-4 flex items-start justify-between shadow-[0_2px_6px_rgba(45,90,71,0.08)] border border-[#2d5a47]/10">
                {/* Text input area - left side */}
                <textarea
                  ref={quickInputRef}
                  value={quickInputText}
                  onChange={(e) => setQuickInputText(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey && quickInputText.trim()) {
                      e.preventDefault();
                      handleQuickInputSubmit();
                    }
                  }}
                  placeholder="Add something you need to do"
                  rows={1}
                  className="flex-1 text-[14px] text-[#1c1c1e] font-medium placeholder:text-[#6c6c70] bg-transparent outline-none resize-none overflow-hidden"
                  style={{ 
                    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
                    minHeight: '20px',
                    maxHeight: '120px'
                  }}
                  onInput={(e) => {
                    const target = e.target as HTMLTextAreaElement;
                    target.style.height = 'auto';
                    target.style.height = Math.min(target.scrollHeight, 120) + 'px';
                  }}
                />
                
                {/* Right side button - changes based on input */}
                {quickInputText.trim() ? (
                  <button
                    onClick={handleQuickInputSubmit}
                    className="w-8 h-8 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors active:scale-95 ml-3 flex-shrink-0"
                  >
                    <ArrowUp className="w-4 h-4 text-white" strokeWidth={2.5} />
                  </button>
                ) : (
                  <button
                    onClick={() => {
                      setIsVoiceInput(true);
                      setIsRecording(true);
                    }}
                    className="w-8 h-8 rounded-full bg-[#2d5a47]/10 flex items-center justify-center hover:bg-[#2d5a47]/20 transition-colors flex-shrink-0"
                  >
                    <Mic className="w-4 h-4 text-[#2d5a47]" strokeWidth={2.5} />
                  </button>
                )}
              </div>

              {/* Recording Overlay */}
              {isRecording && !showRecordingInput && (
                <div className="absolute inset-0 bg-white rounded-[14px] shadow-[0_4px_12px_rgba(0,122,255,0.15)] border-2 border-[#007aff] flex items-center px-5 z-10">
                  {/* Cancel button */}
                  <button
                    onClick={handleCancelRecording}
                    className="w-8 h-8 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors active:scale-95 mr-3"
                  >
                    <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                  </button>

                  {/* Compact Waveform */}
                  <div className="flex-1 flex items-center justify-center gap-1">
                    {[...Array(12)].map((_, i) => (
                      <div
                        key={i}
                        className="w-0.5 bg-[#007aff] rounded-full animate-wave"
                        style={{
                          height: `${Math.random() * 20 + 10}px`,
                          animationDelay: `${i * 0.05}s`
                        }}
                      />
                    ))}
                  </div>
                  
                  {/* Send button */}
                  <button
                    onClick={handleSendVoice}
                    className="w-8 h-8 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors active:scale-95 ml-3"
                  >
                    <Check className="w-4 h-4 text-white" strokeWidth={2.5} />
                  </button>
                </div>
              )}

              {/* Transcribing Overlay */}
              {isTranscribing && !showRecordingInput && (
                <div className="absolute inset-0 bg-white rounded-[14px] shadow-[0_4px_12px_rgba(0,122,255,0.15)] border-2 border-[#007aff] flex items-center justify-center px-5 z-10">
                  <div className="flex items-center gap-2">
                    <div className="w-1.5 h-1.5 bg-[#007aff] rounded-full animate-pulse" />
                    <div className="w-1.5 h-1.5 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.2s' }} />
                    <div className="w-1.5 h-1.5 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.4s' }} />
                    <span className="ml-2 text-[13px] text-[#8e8e93] font-medium">Transcribing...</span>
                  </div>
                </div>
              )}
            </div>

            {/* Divider before sections */}
            <div className="h-[1px] bg-gradient-to-r from-transparent via-black/[0.1] to-transparent mb-5" />
          </div>

          {/* Today Section - Highest Priority (no card, darkest text) */}
          <div className="mb-5 px-2">
            <h3 className="text-[16px] text-[#1c1c1e] font-semibold mb-2">Today</h3>
            <div className="space-y-1">
              {todayTodos.map((todo) => {
                const isSwipedRight = swipedTodoIdRight === todo.id;
                
                return (
                  <div key={todo.id} className="w-full relative overflow-hidden">
                    {/* Swipeable container */}
                    <div
                      className="relative"
                      onTouchStart={(e) => {
                        const touch = e.touches[0];
                        const startX = touch.clientX;
                        
                        const handleTouchMove = (e: TouchEvent) => {
                          const touch = e.touches[0];
                          const diff = touch.clientX - startX;
                          
                          if (diff > 80) {
                            setSwipedTodoIdRight(todo.id);
                            document.removeEventListener('touchmove', handleTouchMove);
                            document.removeEventListener('touchend', handleTouchEnd);
                          }
                        };
                        
                        const handleTouchEnd = () => {
                          document.removeEventListener('touchmove', handleTouchMove);
                          document.removeEventListener('touchend', handleTouchEnd);
                        };
                        
                        document.addEventListener('touchmove', handleTouchMove);
                        document.addEventListener('touchend', handleTouchEnd);
                      }}
                      onMouseDown={(e) => {
                        const startX = e.clientX;
                        
                        const handleMouseMove = (e: MouseEvent) => {
                          const diff = e.clientX - startX;
                          
                          if (diff > 80) {
                            setSwipedTodoIdRight(todo.id);
                            document.removeEventListener('mousemove', handleMouseMove);
                            document.removeEventListener('mouseup', handleMouseUp);
                          }
                        };
                        
                        const handleMouseUp = () => {
                          document.removeEventListener('mousemove', handleMouseMove);
                          document.removeEventListener('mouseup', handleMouseUp);
                        };
                        
                        document.addEventListener('mousemove', handleMouseMove);
                        document.addEventListener('mouseup', handleMouseUp);
                      }}
                      style={{
                        transform: isSwipedRight ? 'translateX(150px)' : 'translateX(0)',
                        transition: 'transform 0.3s ease-out'
                      }}
                    >
                      <button
                        onClick={() => {
                          if (!isSwipedRight) {
                            setSelectedTodo(todo);
                          } else {
                            setSwipedTodoIdRight(null);
                          }
                        }}
                        className="w-full flex items-start gap-3 py-1.5 rounded-[8px] hover:bg-white/60 transition-colors text-left"
                      >
                        <div
                          onClick={(e) => {
                            e.stopPropagation();
                            toggleTodo(todo.id);
                          }}
                          className="flex-shrink-0 mt-[2px] cursor-pointer"
                        >
                          {todo.completed ? (
                            <CheckSquare className="w-5 h-5 text-[#2d5a47]" strokeWidth={2} />
                          ) : (
                            <Square className="w-5 h-5 text-[#2d5a47]" strokeWidth={2} />
                          )}
                        </div>
                        <span className={`flex-1 leading-[1.4] text-[15px] text-[#1c1c1e] ${todo.completed ? 'line-through opacity-50' : ''}`}>
                          {todo.title}
                        </span>
                        {todo.time && (
                          <span className="flex-shrink-0 text-[14px] text-[#8e8e93] font-medium">
                            {todo.time}
                          </span>
                        )}
                      </button>
                    </div>

                    {/* Add to Today's Focus button - revealed on right swipe */}
                    {isSwipedRight && (
                      <button
                        onClick={() => handleAddToFocus(todo.id)}
                        className="absolute left-0 top-0 h-full w-[150px] bg-[#34c759] flex items-center justify-center text-white text-[13px] font-medium px-2 text-center leading-tight"
                      >
                        Add to Today's Focus
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Upcoming Section - Medium Priority (lighter text) */}
          <div className="mb-5 px-2">
            <h3 className="text-[15px] text-[#3c3c43] font-semibold mb-2">Upcoming (7 days)</h3>
            <div className="space-y-0.5">
              {upcomingTodos.map((todo) => (
                <button
                  key={todo.id}
                  onClick={() => setSelectedTodo(todo)}
                  className="w-full flex items-start gap-3 py-1.5 rounded-[8px] hover:bg-white/60 transition-colors text-left"
                >
                  <div
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleTodo(todo.id);
                    }}
                    className="flex-shrink-0 mt-[2px] cursor-pointer"
                  >
                    {todo.completed ? (
                      <CheckSquare className="w-[18px] h-[18px] text-[#6c6c70]" strokeWidth={1.8} />
                    ) : (
                      <Square className="w-[18px] h-[18px] text-[#6c6c70]" strokeWidth={1.8} />
                    )}
                  </div>
                  <span className={`flex-1 leading-[1.4] text-[14px] text-[#3c3c43] ${todo.completed ? 'line-through opacity-50' : ''}`}>
                    {todo.title}
                  </span>
                  {formatTimeDisplay(todo, 'upcoming') && (
                    <span className="flex-shrink-0 text-[13px] text-[#8e8e93] font-medium">
                      {formatTimeDisplay(todo, 'upcoming')}
                    </span>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Later Section - Lowest Priority (lightest text, collapsible) */}
          <div className="mb-5 px-2">
            <button
              onClick={() => setLaterCollapsed(!laterCollapsed)}
              className="flex items-center gap-1.5 hover:opacity-70 transition-opacity mb-2"
            >
              <h3 className="text-[15px] text-[#3c3c43] font-semibold">Future (&gt;7 days)</h3>
              {laterCollapsed ? (
                <ChevronDown className="w-4 h-4 text-[#3c3c43]" strokeWidth={2.5} />
              ) : (
                <ChevronUp className="w-4 h-4 text-[#3c3c43]" strokeWidth={2.5} />
              )}
            </button>
            {!laterCollapsed && (
              <div className="space-y-0.5">
                {laterTodos.map((todo) => (
                  <button
                    key={todo.id}
                    onClick={() => setSelectedTodo(todo)}
                    className="w-full flex items-start gap-3 py-1.5 rounded-[8px] hover:bg-white/60 transition-colors text-left"
                  >
                    <div
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleTodo(todo.id);
                      }}
                      className="flex-shrink-0 mt-[2px] cursor-pointer"
                    >
                      {todo.completed ? (
                        <CheckSquare className="w-[18px] h-[18px] text-[#6c6c70]" strokeWidth={1.8} />
                      ) : (
                        <Square className="w-[18px] h-[18px] text-[#6c6c70]" strokeWidth={1.8} />
                      )}
                    </div>
                    <span className={`flex-1 leading-[1.4] text-[14px] text-[#3c3c43] ${todo.completed ? 'line-through opacity-50' : ''}`}>
                      {todo.title}
                    </span>
                    {formatTimeDisplay(todo, 'later') && (
                      <span className="flex-shrink-0 text-[13px] text-[#8e8e93] font-medium">
                        {formatTimeDisplay(todo, 'later')}
                      </span>
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Overdue Section - Collapsible with clear button */}
          <div className="mb-6 px-2 opacity-70">
            <div className="flex items-center justify-between mb-2">
              <button
                onClick={() => setOverdueCollapsed(!overdueCollapsed)}
                className="flex items-center gap-1.5 hover:opacity-70 transition-opacity"
              >
                <h3 className="text-[14px] text-[#8e8e93] font-semibold">Overdue</h3>
                {overdueCollapsed ? (
                  <ChevronDown className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                ) : (
                  <ChevronUp className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                )}
              </button>
              {!overdueCollapsed && overdueTodos.length > 0 && (
                <button
                  onClick={clearOverdueTodos}
                  className="text-[12px] text-[#8e8e93] hover:text-[#ff3b30] transition-colors font-medium"
                >
                  Clear
                </button>
              )}
            </div>
            {!overdueCollapsed && (
              <div className="space-y-0.5">
                {overdueTodos.map((todo) => (
                  <button
                    key={todo.id}
                    onClick={() => setSelectedTodo(todo)}
                    className="w-full flex items-start gap-2.5 py-1 rounded-[6px] hover:bg-white/40 transition-colors text-left"
                  >
                    <div
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleTodo(todo.id);
                      }}
                      className="flex-shrink-0 mt-[2px] cursor-pointer"
                    >
                      {todo.completed ? (
                        <CheckSquare className="w-4 h-4 text-[#b0b0b5]" strokeWidth={1.5} />
                      ) : (
                        <Square className="w-4 h-4 text-[#b0b0b5]" strokeWidth={1.5} />
                      )}
                    </div>
                    <span className={`flex-1 leading-[1.4] text-[13px] text-[#8e8e93] ${todo.completed ? 'line-through opacity-50' : ''}`}>
                      {todo.title}
                    </span>
                    {formatTimeDisplay(todo, 'later') && (
                      <span className="flex-shrink-0 text-[12px] text-[#b0b0b5] font-medium">
                        {formatTimeDisplay(todo, 'later')}
                      </span>
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Completed Section - Collapsible with clear button */}
          <div className="mb-6 px-2 opacity-70">
            <div className="flex items-center justify-between mb-2">
              <button
                onClick={() => setCompletedCollapsed(!completedCollapsed)}
                className="flex items-center gap-1.5 hover:opacity-70 transition-opacity"
              >
                <h3 className="text-[14px] text-[#8e8e93] font-semibold">Completed</h3>
                {completedCollapsed ? (
                  <ChevronDown className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                ) : (
                  <ChevronUp className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                )}
              </button>
            </div>
            {!completedCollapsed && (
              <div className="space-y-0.5">
                {completedTodos.map((todo) => (
                  <button
                    key={todo.id}
                    onClick={() => setSelectedTodo(todo)}
                    className="w-full flex items-start gap-2.5 py-1 rounded-[6px] hover:bg-white/40 transition-colors text-left"
                  >
                    <div
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleTodo(todo.id);
                      }}
                      className="flex-shrink-0 mt-[2px] cursor-pointer"
                    >
                      {todo.completed ? (
                        <CheckSquare className="w-4 h-4 text-[#b0b0b5]" strokeWidth={1.5} />
                      ) : (
                        <Square className="w-4 h-4 text-[#b0b0b5]" strokeWidth={1.5} />
                      )}
                    </div>
                    <span className={`leading-[1.4] text-[13px] text-[#8e8e93] ${todo.completed ? 'line-through opacity-50' : ''}`}>
                      {todo.title}
                    </span>
                  </button>
                ))}
              </div>
            )}
          </div>

        </div>
        {selectedTodo && (
          isNewTodoFromMemo ? (
            <NewTodoFromMemoModal
              todo={selectedTodo}
              onClose={() => {
                setSelectedTodo(null);
                setIsNewTodoFromMemo(false);
              }}
              onSave={(updatedTodo) => {
                // Update the todo with the edited data
                setTodos(todos.map(t => t.id === updatedTodo.id ? updatedTodo : t));
                setSelectedTodo(null);
                setIsNewTodoFromMemo(false);
              }}
            />
          ) : selectedTodo.category === 'Completed' ? (
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
              onMemoryClick={onMemoryClick}
            />
          )
        )}
        {showRecordingInput && (
          <div className="fixed inset-0 z-50 flex items-end justify-center">
            {/* Backdrop */}
            <div 
              className="absolute inset-0 bg-black/40 backdrop-blur-sm"
              onClick={handleCancelInput}
            />
            
            {/* Modal - 半页弹窗 */}
            <div 
              className="relative w-full max-w-md bg-white rounded-t-[24px] shadow-2xl animate-slide-up"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Content */}
              <div className="px-5 pt-6 pb-6 max-h-[70vh] flex flex-col">
                {/* Multi-line textarea */}
                <textarea
                  autoFocus
                  value={todoInputText}
                  onChange={(e) => setTodoInputText(e.target.value)}
                  placeholder="Add something you need to do..."
                  className="flex-1 min-h-[200px] text-[17px] text-[#1c1c1e] leading-[1.6] resize-none outline-none placeholder:text-[#8e8e93] bg-transparent"
                  style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
                  disabled={isRecording || isTranscribing}
                />
                
                {/* Recording Waveform - only in modal mode */}
                {isRecording && showRecordingInput && (
                  <div className="flex items-center justify-center py-8">
                    <div className="flex items-center gap-1.5">
                      {[...Array(20)].map((_, i) => (
                        <div
                          key={i}
                          className="w-1 bg-[#007aff] rounded-full animate-wave"
                          style={{
                            height: `${Math.random() * 40 + 20}px`,
                            animationDelay: `${i * 0.05}s`
                          }}
                        />
                      ))}
                    </div>
                  </div>
                )}

                {/* Transcribing indicator - only in modal mode */}
                {isTranscribing && showRecordingInput && (
                  <div className="flex items-center justify-center py-8">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" />
                      <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.2s' }} />
                      <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.4s' }} />
                      <span className="ml-2 text-[14px] text-[#8e8e93]">Transcribing...</span>
                    </div>
                  </div>
                )}
                
                {/* Bottom bar with buttons */}
                <div className="flex items-center justify-between pt-4 border-t border-black/[0.06] mt-4">
                  {isRecording ? (
                    <>
                      {/* Cancel recording button */}
                      <button
                        onClick={handleCancelRecording}
                        className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors active:scale-95"
                      >
                        <X className="w-5 h-5 text-[#8e8e93]" strokeWidth={2.5} />
                      </button>
                      
                      {/* Send voice button */}
                      <button
                        onClick={handleSendVoice}
                        className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors active:scale-95"
                      >
                        <Check className="w-5 h-5 text-white" strokeWidth={2.5} />
                      </button>
                    </>
                  ) : isTranscribing ? (
                    <div className="flex-1" />
                  ) : (
                    <>
                      <div className="flex-1" />
                      {todoInputText.trim() ? (
                        <button
                          onClick={handleSaveTodo}
                          className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors active:scale-95"
                        >
                          <ArrowUp className="w-5 h-5 text-white" strokeWidth={2.5} />
                        </button>
                      ) : (
                        <button
                          onClick={handleStartRecording}
                          className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors"
                        >
                          <Mic className="w-5 h-5 text-[#8e8e93]" strokeWidth={2.5} />
                        </button>
                      )}
                    </>
                  )}
                </div>
              </div>
            </div>

            <style>{`
              @keyframes slide-up {
                from {
                  transform: translateY(100%);
                }
                to {
                  transform: translateY(0);
                }
              }
              .animate-slide-up {
                animation: slide-up 0.3s ease-out;
              }
              @keyframes wave {
                0%, 100% {
                  transform: scaleY(1);
                }
                50% {
                  transform: scaleY(1.5);
                }
              }
              .animate-wave {
                animation: wave 1s ease-in-out infinite;
              }
            `}</style>
          </div>
        )}
        
        {/* Replace Focus Modal */}
        {showReplaceFocusModal && todoToAdd !== null && (
          <div className="fixed inset-0 z-50 flex items-center justify-center">
            {/* Backdrop */}
            <div 
              className="absolute inset-0 bg-black/40 backdrop-blur-sm"
              onClick={() => {
                setShowReplaceFocusModal(false);
                setTodoToAdd(null);
              }}
            />
            
            {/* Modal */}
            <div 
              className="relative w-full max-w-sm mx-5 bg-white rounded-[20px] shadow-2xl overflow-hidden"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Close button */}
              <button
                onClick={() => {
                  setShowReplaceFocusModal(false);
                  setTodoToAdd(null);
                }}
                className="absolute top-4 right-4 w-8 h-8 flex items-center justify-center rounded-full bg-[#f2f2f7] hover:bg-[#e5e5ea] transition-colors z-10"
              >
                <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
              </button>

              {/* Content */}
              <div className="px-6 pt-6 pb-5">
                <h3 className="text-[20px] text-[#1c1c1e] font-semibold mb-1">Today's Focus is full.</h3>
                <p className="text-[15px] text-[#8e8e93] mb-6">Replace one priority?</p>
                
                {/* Current Focus Items */}
                <div className="space-y-3">
                  {upNextTodos.map((focusTodo) => (
                    <button
                      key={focusTodo.id}
                      onClick={() => handleReplaceFocus(focusTodo.id, todoToAdd)}
                      className="w-full flex items-start gap-3 p-4 rounded-[14px] bg-[#f9f9f9] hover:bg-[#f2f2f7] transition-colors text-left"
                    >
                      <div className="flex-shrink-0 mt-[2px]">
                        <Star className="w-4 h-4 text-[#f59e42]" strokeWidth={2} fill="none" />
                      </div>
                      <span className="flex-1 leading-[1.4] text-[15px] text-[#1c1c1e]">
                        {focusTodo.title}
                      </span>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
        </>
      ) : (
        // Search View
        <div className="flex flex-col h-full bg-white">
          {/* Search Header */}
          <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06]">
            <div className="flex items-center gap-2 flex-1">
              <button
                onClick={() => setShowSearch(false)}
                className="text-[#007aff] hover:opacity-70 transition-opacity"
              >
                <ChevronLeft className="w-6 h-6" strokeWidth={2} />
              </button>
              <span className="text-[17px] font-semibold">Search to-dos</span>
            </div>
            <button
              onClick={() => {
                setShowSearch(false);
                setSearchQuery('');
              }}
              className="w-8 h-8 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
            >
              <X className="w-5 h-5" strokeWidth={2.5} />
            </button>
          </div>

          {/* Search Input */}
          <div className="px-5 pt-4">
            <div className="flex items-center gap-2 bg-[#f2f2f7] rounded-[12px] px-4 py-3">
              <Search className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search by context, priority, or keywords..."
                className="flex-1 bg-transparent outline-none text-[17px] text-[#1c1c1e] placeholder:text-[#8e8e93]"
                autoFocus
              />
            </div>
          </div>

          {/* Suggestions */}
          <div className="px-5 pt-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3">Suggestions</h3>
            <div className="space-y-2">
              {suggestions.map((suggestion, index) => (
                <button
                  key={index}
                  onClick={() => setSearchQuery(suggestion)}
                  className="w-full text-left py-3 px-4 rounded-[12px] hover:bg-[#f2f2f7] transition-colors flex items-center gap-3"
                >
                  <div className="w-1 h-1 rounded-full bg-[#8e8e93]" />
                  <span className="text-[17px] text-[#1c1c1e]">{suggestion}</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}