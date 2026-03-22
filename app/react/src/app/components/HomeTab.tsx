import { Square, Mic, Sparkles, Plus, ChevronRight, CheckSquare, X, Upload, Pause, Play, Star, Minimize2, PenSquare, ArrowUp, Check, Calendar, Brain } from 'lucide-react';
import deviceIcon from 'figma:asset/4aa5d96a75e1e7c95fc1cafc2688510efa24be85.png';
import { useState, useEffect, useRef } from 'react';
import { TodoListPage } from './TodoListPage';
import { TodoDetailModal } from './TodoDetailModal';
import { MemoryDetailPage } from './MemoryDetailPage';
import { DeviceConnectionPage } from './DeviceConnectionPage';
import { IconPreviewPage } from './IconPreviewPage';
import { DeviceIconBattery } from './DeviceIconBattery';
import { MemoryListSelector } from './MemoryListSelector';
import { InsightsSummaryCard } from './InsightsSummaryCard';
import { AllInsightsListPage } from './AllInsightsListPage';
import { DailyInsightDetail } from './DailyInsightDetail';
import { WeeklyInsightDetail } from './WeeklyInsightDetail';
import { MonthlyInsightDetail } from './MonthlyInsightDetail';
import { PatternInsightDetail } from './PatternInsightDetail';
import { CalendarPage } from './CalendarPage';
import { AudioStatusBar } from './AudioStatusBar';
import { useAudioStatus } from '../contexts/AudioStatusContext';
import { useDevMode } from '../contexts/DevModeContext';
import { HomeEmptyState } from './HomeEmptyState';
import { PullToRefresh } from './PullToRefresh';
import { useMicrophonePermission } from '../contexts/MicrophonePermissionContext';
import { MicrophonePermissionModal } from './MicrophonePermissionModal';
import { MicrophonePermissionDeniedModal } from './MicrophonePermissionDeniedModal';

interface HomeTabProps {
  onSwitchToMemoryTab?: () => void;
  todos: any[];
  setTodos: (todos: any[]) => void;
  onMarkDone?: (id: number) => void;
  onNotNow?: (id: number) => void;
  onDeleteTodo?: (id: number) => void;
  onUpdateTodo?: (id: number, updates: any) => void;
  recordingState?: {
    isMinimized: boolean;
    isRecording: boolean;
    recordingTime: number;
    setIsRecording: (value: boolean) => void;
    setRecordingTime: (value: number) => void;
    onMinimize: () => void;
    onExpand: () => void;
    onStop: () => void;
  };
  memories?: any[];
  setMemories?: (memories: any[]) => void;
  memos?: any[];
  setMemos?: (memos: any[]) => void;
}

interface ConnectedDevice {
  id: string;
  name: string;
  battery: number;
  signal: number;
}

export function HomeTab({ onSwitchToMemoryTab, todos, setTodos, onMarkDone, onNotNow, onDeleteTodo, onUpdateTodo, recordingState, memories: memoriesProp, setMemories: setMemoriesProp, memos: memosProp, setMemos: setMemosProp }: HomeTabProps) {
  const { devMode } = useDevMode();
  const { audioStatus, setImporting, setSyncing, setRecording, clearStatus } = useAudioStatus();
  const { permissionStatus, requestPermission } = useMicrophonePermission();
  const [showRecordingModal, setShowRecordingModal] = useState(false);
  const [showMicPermissionModal, setShowMicPermissionModal] = useState(false);
  const [showMicPermissionDeniedModal, setShowMicPermissionDeniedModal] = useState(false);
  const [pendingRecordingAction, setPendingRecordingAction] = useState<'recording' | 'quickCapture' | null>(null);
  const [showOptionsModal, setShowOptionsModal] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [hasStartedRecording, setHasStartedRecording] = useState(false);
  const [recordingTime, setRecordingTime] = useState(0); // in seconds
  const [showCancelConfirmModal, setShowCancelConfirmModal] = useState(false);
  const [currentView, setCurrentView] = useState<'home' | 'todoList' | 'memoryDetail'>('home');
  const [selectedTodo, setSelectedTodo] = useState<any>(null);
  const [selectedMemory, setSelectedMemory] = useState<any>(null);
  const [memoryInitialTab, setMemoryInitialTab] = useState<'Overview' | 'Transcript' | 'Actions'>('Overview');
  const [memoryHighlightTimestamp, setMemoryHighlightTimestamp] = useState<string | undefined>(undefined);
  const [showTodoModal, setShowTodoModal] = useState(false);
  const [showDeleteConfirmModal, setShowDeleteConfirmModal] = useState(false);
  const [todoToDelete, setTodoToDelete] = useState<number | null>(null);
  const [showDeviceConnection, setShowDeviceConnection] = useState(false);
  const [showIconPreview, setShowIconPreview] = useState(false);
  const [connectedDevice, setConnectedDevice] = useState<ConnectedDevice | null>(null);
  const [showMemorySelector, setShowMemorySelector] = useState(false);
  const [todoForMemoryLink, setTodoForMemoryLink] = useState<number | null>(null);
  const [memoryReturnContext, setMemoryReturnContext] = useState<'home' | 'todoModal'>('home');
  
  // Insights related states
  const [showDailyInsightsList, setShowDailyInsightsList] = useState(false);
  const [selectedDailyInsight, setSelectedDailyInsight] = useState<any>(null);
  const [selectedWeeklyInsight, setSelectedWeeklyInsight] = useState<any>(null);
  const [selectedMonthlyInsight, setSelectedMonthlyInsight] = useState<any>(null);
  const [selectedPatternInsight, setSelectedPatternInsight] = useState<any>(null);
  const [viewedPatternInsightIds, setViewedPatternInsightIds] = useState<Set<string>>(new Set());
  
  // Calendar related states
  const [showCalendarPage, setShowCalendarPage] = useState(false);
  
  // Quick Capture related states
  const [showQuickCaptureModal, setShowQuickCaptureModal] = useState(false);
  const [quickCaptureMemoText, setQuickCaptureMemoText] = useState('');
  const [isQuickCaptureRecording, setIsQuickCaptureRecording] = useState(false);
  const [quickCaptureProcessing, setQuickCaptureProcessing] = useState<'' | 'transcribing' | 'analyzing'>('');
  const [showQuickCaptureConfirm, setShowQuickCaptureConfirm] = useState(false);
  const [aiParsedTodos, setAiParsedTodos] = useState<Array<{id: number; text: string; selected: boolean}>>([]);
  const [aiParsedMemos, setAiParsedMemos] = useState<Array<{id: number; text: string; selected: boolean}>>([]);
  const [originalTranscript, setOriginalTranscript] = useState('');
  const [selectionMode, setSelectionMode] = useState<'original' | 'structured'>('structured');
  const [quickCaptureInputMode, setQuickCaptureInputMode] = useState<'voice' | 'manual'>('manual');

  const audioRef = useRef<HTMLAudioElement>(null);

  // Effect to restore recording modal when expanded from minimized state
  useEffect(() => {
    if (recordingState && !recordingState.isMinimized && recordingState.recordingTime > 0 && !showRecordingModal) {
      // Restore state from App level
      setShowRecordingModal(true);
      setIsRecording(recordingState.isRecording);
      setHasStartedRecording(true);
      setRecordingTime(recordingState.recordingTime);
    }
  }, [recordingState?.isMinimized, recordingState?.recordingTime, showRecordingModal]);

  // Timer effect for recording
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null;
    
    if (isRecording) {
      interval = setInterval(() => {
        setRecordingTime((prev) => {
          // Max 60 minutes = 3600 seconds
          if (prev >= 3600) {
            if (interval) clearInterval(interval);
            pauseRecording();
            return 3600;
          }
          return prev + 1;
        });
      }, 1000);
    }
    
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isRecording]);

  // Format time as MM:SS
  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  // Permission check function
  const checkAndRequestPermission = async (action: 'recording' | 'quickCapture'): Promise<boolean> => {
    if (permissionStatus === 'granted') {
      return true;
    }
    
    if (permissionStatus === 'not_determined') {
      // Show our custom permission guide modal
      setPendingRecordingAction(action);
      setShowMicPermissionModal(true);
      return false;
    }
    
    if (permissionStatus === 'denied') {
      // Show denied modal with instructions to go to Settings
      setShowMicPermissionDeniedModal(true);
      return false;
    }
    
    return false;
  };

  // Handle permission modal continue
  const handlePermissionContinue = async () => {
    setShowMicPermissionModal(false);
    
    // Request actual system permission
    const granted = await requestPermission();
    
    if (granted) {
      // Permission granted - proceed with the pending action
      if (pendingRecordingAction === 'recording') {
        setShowRecordingModal(true);
      } else if (pendingRecordingAction === 'quickCapture') {
        setShowQuickCaptureModal(true);
      }
      setPendingRecordingAction(null);
    } else {
      // Permission denied - show denied modal
      setShowMicPermissionDeniedModal(true);
      setPendingRecordingAction(null);
    }
  };

  // Handle permission modal "Not Now"
  const handlePermissionNotNow = () => {
    setShowMicPermissionModal(false);
    setPendingRecordingAction(null);
  };

  // Handle open settings (when permission is denied)
  const handleOpenSettings = () => {
    // In a real app, this would open system settings
    // For demo, just close the modal
    console.log('Opening Settings...');
    setShowMicPermissionDeniedModal(false);
    
    // In iOS, you would use: UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    // In web, we can't directly open settings, so just show an alert
    alert('Please enable microphone access in your browser settings or system preferences.');
  };

  const startRecording = () => {
    setIsRecording(true);
    setHasStartedRecording(true);
    // Audio recording logic can be added here
  };

  const pauseRecording = () => {
    setIsRecording(false);
    // Pause recording logic here (keep the recorded audio so far)
  };

  const handleCloseRecordingModal = () => {
    // If recording has started, show confirmation modal
    if (hasStartedRecording) {
      setShowCancelConfirmModal(true);
    } else {
      // If not started, just close
      setShowRecordingModal(false);
      setIsRecording(false);
      setHasStartedRecording(false);
      setRecordingTime(0);
      setShowCancelConfirmModal(false);
      // Also reset App-level state if recordingState is available
      if (recordingState) {
        recordingState.onStop();
      }
    }
  };

  const handleSaveRecording = () => {
    // Create date format: "Jan 18, 2026, 11:20 AM"
    const now = new Date();
    const dateFormatOptions: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    };
    const formattedDate = now.toLocaleString('en-US', dateFormatOptions);
    
    // Create subtitle format: "January 18, 2026 at 11:20 AM"
    const dateSubtitleOptions: Intl.DateTimeFormatOptions = {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    };
    const formattedSubtitle = now.toLocaleString('en-US', dateSubtitleOptions);
    
    // Format recording duration as "3m47s"
    const formatDuration = (seconds: number) => {
      const mins = Math.floor(seconds / 60);
      const secs = seconds % 60;
      if (mins === 0) {
        return `${secs}s`;
      }
      return `${mins}m${secs}s`;
    };
    
    // Create new audio memory
    const newMemory = {
      id: Date.now(),
      title: null, // Audio only - no title
      time: 'Just now',
      content: formattedSubtitle, // Use subtitle as content
      date: formattedDate,
      dateSubtitle: formattedSubtitle,
      summary: null,
      relatedMemories: [],
      hasAudio: true,
      hasSummary: false,
      hasActivity: false,
      audioDuration: formatDuration(recordingTime),
      audioSource: connectedDevice ? 'MemoPin' as 'MemoPin' | 'MobilePhone' : 'MobilePhone' as 'MemoPin' | 'MobilePhone',
      isUserCreated: true // Mark as user-created for filtering in empty mode
    };
    
    // Add new memory to the front of the list in both local and shared state
    if (setMemoriesProp) {
      const currentMemories = memoriesProp || [];
      setMemoriesProp([newMemory, ...currentMemories]);
    } else {
      setLocalRecentMemories([newMemory, ...localRecentMemories]);
    }
    
    // Close modal and reset states
    setShowRecordingModal(false);
    setIsRecording(false);
    setHasStartedRecording(false);
    setRecordingTime(0);
    
    // Reset App-level state
    if (recordingState) {
      recordingState.onStop();
    }
  };
  
  const handleConfirmCancel = () => {
    // Close all modals and reset all states
    setShowRecordingModal(false);
    setShowCancelConfirmModal(false);
    setIsRecording(false);
    setHasStartedRecording(false);
    setRecordingTime(0);
    // Reset App-level state
    if (recordingState) {
      recordingState.onStop();
    }
  };

  const handleImportAudio = () => {
    // Create file input element
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'audio/*,.mp3,.m4a,.wav,.ogg,.aac';
    input.onchange = async (e: Event) => {
      const target = e.target as HTMLInputElement;
      const file = target.files?.[0];
      if (file) {
        console.log('Selected audio file:', file.name);
        
        // Simulate import process with progress
        setImporting(0);
        
        // Simulate progress from 0% to 100%
        for (let i = 0; i <= 100; i += 10) {
          await new Promise(resolve => setTimeout(resolve, 200));
          setImporting(i);
        }
        
        // Clear status after completion
        await new Promise(resolve => setTimeout(resolve, 500));
        clearStatus();
        
        // Create a new audio memory (mock)
        console.log('Audio imported and memory created');
      }
    };
    input.click();
    setShowOptionsModal(false);
  };

  const handleHomeTodoClick = (todo: any) => {
    setSelectedTodo(todo);
    setShowTodoModal(true);
  };

  const handleHomeMemoryClick = (memory: any) => {
    setSelectedMemory(memory);
    setCurrentView('memoryDetail');
  };



  const handleTodoClick = (todo: any) => {
    setSelectedTodo(todo);
    setCurrentView('todoDetail');
  };

  const handleToggleTodo = (id: number) => {
    if (selectedTodo && selectedTodo.id === id) {
      setSelectedTodo({ ...selectedTodo, completed: !selectedTodo.completed });
    }
  };

  const handleDeleteTodo = (id: number) => {
    // Show delete confirmation modal instead of deleting immediately
    setTodoToDelete(id);
    setShowDeleteConfirmModal(true);
  };

  const confirmDeleteTodo = () => {
    // Remove todo completely from the array
    if (todoToDelete !== null) {
      setTodos(todos.filter(todo => todo.id !== todoToDelete));
      // Close both modals
      setShowDeleteConfirmModal(false);
      setShowTodoModal(false);
      setSelectedTodo(null);
      setTodoToDelete(null);
    }
  };

  const handleMarkDone = (id: number) => {
    // Mark todo as completed and move to Completed category
    setTodos(todos.map(todo => {
      if (todo.id === id) {
        return {
          ...todo,
          completed: true,
          category: 'Completed'
        };
      }
      return todo;
    }));
    // Close the modal
    setShowTodoModal(false);
    setSelectedTodo(null);
  };

  const handleNotNow = (id: number) => {
    // Move todo to Today category
    setTodos(todos.map(todo => {
      if (todo.id === id) {
        return {
          ...todo,
          category: 'Today'
        };
      }
      return todo;
    }));
    // Close the modal
    setShowTodoModal(false);
    setSelectedTodo(null);
  };

  const handleUpdateTodo = (id: number, updates: any) => {
    // Update todo with new priority or due date
    setTodos(todos.map(todo => {
      if (todo.id === id) {
        return {
          ...todo,
          ...updates
        };
      }
      return todo;
    }));
    // Update selectedTodo to reflect changes
    if (selectedTodo && selectedTodo.id === id) {
      setSelectedTodo({ ...selectedTodo, ...updates });
    }
  };



  const handleMemoryClick = (memory: any) => {
    setSelectedMemory(memory);
    setCurrentView('memoryDetail');
  };

  const handleRelatedMemoryClick = (memoryTitle: string) => {
    // Find the corresponding memory and open the detail page
    const memory = recentMemories.find(m => m.title === memoryTitle);
    if (memory) {
      setSelectedMemory(memory);
      setMemoryReturnContext('todoModal');
      setCurrentView('memoryDetail');
    }
  };

  const handleMemoryClickFromTodo = (memoryId: string) => {
    // Check if this is a memo ID (format: memo-${id})
    if (memoryId.startsWith('memo-')) {
      // Extract memo ID and switch to Memory tab to show memo
      const memoId = parseInt(memoryId.replace('memo-', ''));
      // We need to switch to Memory tab and show the memo
      // This requires cooperation from parent (App.tsx)
      // For now, just alert the user
      console.log('Navigate to memo:', memoId);
      // Close the todo modal
      setShowTodoModal(false);
      setCurrentView('home');
      // Switch to memory tab - need to add this callback to props
      if (onSwitchToMemoryTab) {
        onSwitchToMemoryTab();
      }
      return;
    }
    
    // Find the corresponding memory and open the detail page
    const memory = recentMemories.find(m => m.id.toString() === memoryId);
    if (memory) {
      setSelectedMemory(memory);
      // Close the todo modal and remember to return to it
      setShowTodoModal(false);
      setMemoryReturnContext('todoModal');
      setCurrentView('memoryDetail');
    }
  };

  const handleLinkMemory = (todoId: number) => {
    // Show Memory List Selector
    setTodoForMemoryLink(todoId);
    setShowMemorySelector(true);
    setMemoryReturnContext('todoModal');
  };

  const handleHighlightClick = (memoryId: number, timestamp: string) => {
    // Find the memory by ID
    const memory = recentMemories.find(m => m.id === memoryId);
    if (memory) {
      setSelectedMemory(memory);
      setMemoryInitialTab('Transcript');
      setMemoryHighlightTimestamp(timestamp);
      setCurrentView('memoryDetail');
    }
  };

  // Pull to refresh handler
  const handleRefresh = async () => {
    // Simulate network request to refresh data
    await new Promise(resolve => setTimeout(resolve, 1500));
    console.log('Refreshed Home page data');
    // In a real app, this would fetch fresh data from the server
  };

  const handleSelectMemory = (memoryId: number) => {
    // Find the selected memory
    const memory = recentMemories.find(m => m.id === memoryId);
    if (!memory) return;
    
    // Create linked memory object
    const linkedMemory = {
      id: memory.id.toString(),
      title: memory.title || memory.date,
      date: memory.time,
      duration: memory.audioDuration,
      hasSummary: memory.hasSummary
    };
    
    // Handle todo linking
    if (todoForMemoryLink !== null) {
      // Find and update the todo with the linked memory
      const updatedTodos = todos.map(todo => {
        if (todo.id === todoForMemoryLink) {
          return {
            ...todo,
            linkedMemory: linkedMemory
          };
        }
        return todo;
      });
      
      setTodos(updatedTodos);
      
      // Find the updated todo to set as selectedTodo
      const updatedTodo = updatedTodos.find(todo => todo.id === todoForMemoryLink);
      if (updatedTodo) {
        setSelectedTodo(updatedTodo);
      }
      
      setTodoForMemoryLink(null);
    }
    
    // Close selector and reopen the appropriate modal
    setShowMemorySelector(false);
    if (memoryReturnContext === 'todoModal') {
      setShowTodoModal(true);
    }
  };



  // Quick Capture handlers
  const handleCancelQuickCapture = () => {
    setQuickCaptureMemoText('');
    setShowQuickCaptureModal(false);
    setIsQuickCaptureRecording(false);
    setQuickCaptureProcessing('');
    setQuickCaptureInputMode('manual');
  };

  const handleStartQuickCaptureRecording = () => {
    setIsQuickCaptureRecording(true);
  };

  const handleCancelQuickCaptureRecording = () => {
    setIsQuickCaptureRecording(false);
  };

  const handleSendQuickCaptureVoice = () => {
    setIsQuickCaptureRecording(false);
    setQuickCaptureProcessing('transcribing');
    setQuickCaptureInputMode('voice'); // Mark as voice input
    
    // Simulate voice transcription and AI parsing (in real app would call actual speech recognition and AI API)
    setTimeout(() => {
      // Store the original transcript
      const transcript = 'Contact John tomorrow morning at 10:30 and update the UI this afternoon. Also I had an idea that UX should be ADHD friendly.';
      setOriginalTranscript(transcript);
      
      // Simulate AI parsing the voice input into todos and memos
      const parsedTodos = [
        { id: 1, text: 'Contact John tomorrow morning 10:30', selected: true },
        { id: 2, text: 'Update UI this afternoon', selected: true }
      ];
      
      const parsedMemos = [
        { id: 1, text: 'UX improvement idea should be ADHD friendly', selected: true }
      ];
      
      setAiParsedTodos(parsedTodos);
      setAiParsedMemos(parsedMemos);
      setSelectionMode('structured');
      setQuickCaptureProcessing('');
      setShowQuickCaptureConfirm(true);
    }, 2000);
  };

  const handleSaveQuickCapture = () => {
    if (!quickCaptureMemoText.trim()) return;
    
    // Show analyzing indicator while AI processes the text
    setQuickCaptureProcessing('analyzing');
    setQuickCaptureInputMode('manual'); // Mark as manual text input
    
    // Simulate AI parsing the text input into todos and memos (in real app would call AI API)
    setTimeout(() => {
      // Simulate AI parsing - in production this would be actual AI analysis
      const text = quickCaptureMemoText.trim();
      
      // Store the original text
      setOriginalTranscript(text);
      
      // Example parsing logic (would be replaced with actual AI)
      const parsedTodos = [
        { id: 1, text: 'Review project timeline by Friday', selected: true },
        { id: 2, text: 'Schedule team meeting next week', selected: true }
      ];
      
      const parsedMemos = [
        { id: 1, text: text.substring(0, 100) + (text.length > 100 ? '...' : ''), selected: true }
      ];
      
      setAiParsedTodos(parsedTodos);
      setAiParsedMemos(parsedMemos);
      setSelectionMode('structured');
      setQuickCaptureProcessing('');
      setShowQuickCaptureConfirm(true);
    }, 1500);
  };

  const toggleAiTodoSelection = (id: number) => {
    // Only toggle if we're in structured mode
    if (selectionMode === 'structured') {
      setAiParsedTodos(aiParsedTodos.map(todo => 
        todo.id === id ? { ...todo, selected: !todo.selected } : todo
      ));
    }
  };

  const toggleAiMemoSelection = (id: number) => {
    // Only toggle if we're in structured mode
    if (selectionMode === 'structured') {
      setAiParsedMemos(aiParsedMemos.map(memo => 
        memo.id === id ? { ...memo, selected: !memo.selected } : memo
      ));
    }
  };

  const handleSelectOriginal = () => {
    // Switch to original mode and deselect all structured items
    setSelectionMode('original');
    setAiParsedTodos(aiParsedTodos.map(todo => ({ ...todo, selected: false })));
    setAiParsedMemos(aiParsedMemos.map(memo => ({ ...memo, selected: false })));
  };

  const handleSelectStructured = () => {
    // Switch to structured mode
    setSelectionMode('structured');
  };

  const handleConfirmAiParsed = () => {
    if (selectionMode === 'original') {
      // Save original transcript as a single memo
      const newMemo = {
        id: Date.now(),
        title: originalTranscript.length > 60 ? originalTranscript.substring(0, 60) + '...' : originalTranscript,
        content: originalTranscript,
        timestamp: new Date(),
        category: 'Today' as 'Today' | 'Yesterday' | 'Earlier' | 'Long ago',
        relatedMemories: [],
        todoCreated: false,
        type: quickCaptureInputMode // 'voice' or 'manual'
      };
      
      // Save to memos if setMemosProp is available
      if (setMemosProp && memosProp) {
        setMemosProp([newMemo, ...memosProp]);
      }
    } else {
      // Save selected todos to Today category
      const selectedTodoItems = aiParsedTodos.filter(todo => todo.selected);
      if (selectedTodoItems.length > 0) {
        const newTodos = selectedTodoItems.map((todo, index) => ({
          id: Date.now() + index,
          title: todo.text,
          text: todo.text,
          completed: false,
          category: 'Today',
          isNew: true
        }));
        
        setTodos([...todos, ...newTodos]);
      }

      // Save selected memos
      const selectedMemoItems = aiParsedMemos.filter(memo => memo.selected);
      if (selectedMemoItems.length > 0 && setMemosProp && memosProp) {
        const newMemos = selectedMemoItems.map((memo, index) => ({
          id: Date.now() + index + 1000,
          title: memo.text.length > 60 ? memo.text.substring(0, 60) + '...' : memo.text,
          content: memo.text,
          timestamp: new Date(),
          category: 'Today' as 'Today' | 'Yesterday' | 'Earlier' | 'Long ago',
          relatedMemories: [],
          todoCreated: false,
          type: quickCaptureInputMode // 'voice' or 'manual'
        }));
        
        // Merge with existing memos
        setMemosProp([...newMemos, ...memosProp]);
      }
    }

    // Reset states
    setShowQuickCaptureConfirm(false);
    setShowQuickCaptureModal(false);
    setAiParsedTodos([]);
    setAiParsedMemos([]);
    setQuickCaptureMemoText('');
    setOriginalTranscript('');
    setSelectionMode('structured');
    setQuickCaptureInputMode('manual');
  };

  const handleCancelAiParsed = () => {
    setShowQuickCaptureConfirm(false);
    setShowQuickCaptureModal(false);
    setAiParsedTodos([]);
    setAiParsedMemos([]);
    setQuickCaptureMemoText('');
    setOriginalTranscript('');
    setSelectionMode('structured');
    setIsQuickCaptureRecording(false);
    setQuickCaptureProcessing('');
    setQuickCaptureInputMode('manual');
  };

  const toggleTodoCheckbox = (id: number) => {
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

  // Use prop memories if available, otherwise use local recentMemories state
  const [localRecentMemories, setLocalRecentMemories] = useState([
    { 
      id: 1, 
      title: 'Team standup discussion on API migration', 
      time: '2h ago', 
      content: 'Discussed the timeline for migrating to the new API. The team agreed to start with non-critical endpoints first. Sarah mentioned potential issues with authentication that we need to address.', 
      relatedMemories: ['Previous API architecture meeting', 'Technical debt discussion'],
      hasAudio: true,
      hasSummary: true,
      hasActivity: false,
      audioDuration: '12m34s',
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone'
    },
    { 
      id: 2, 
      title: 'Coffee chat with Jordan about team dynamics', 
      time: '5h ago', 
      content: 'Had a great conversation about improving team communication. Jordan suggested weekly sync-ups and more async updates. We also talked about the new hire onboarding process.', 
      relatedMemories: ['Team retrospective notes'],
      hasAudio: true,
      hasSummary: true,
      hasActivity: true,
      audioDuration: '8m15s',
      audioSource: 'MobilePhone' as 'MemoPin' | 'MobilePhone'
    },
    { 
      id: 3, 
      title: 'Review session for new dashboard designs', 
      time: 'Yesterday', 
      content: 'Reviewed the latest dashboard mockups. The new data visualization is much clearer. Need to consider mobile responsiveness and accessibility improvements.', 
      relatedMemories: ['Initial dashboard requirements', 'User feedback on current dashboard'],
      hasAudio: true,
      hasSummary: true,
      hasActivity: false,
      audioDuration: '15m42s',
      audioSource: 'MemoPin' as 'MemoPin' | 'MobilePhone'
    }
  ]);

  // Use prop memories if available, otherwise use local state
  const recentMemories = memoriesProp || localRecentMemories;
  const setRecentMemories = setMemoriesProp || setLocalRecentMemories;

  const aiInsight = {
    text: 'You have three meetings tomorrow morning. Consider blocking 30 minutes before the first one to review notes.',
    available: true
  };

  return (
    <>
      {/* Show Calendar Page */}
      {showCalendarPage && (
        <CalendarPage 
          onBack={() => setShowCalendarPage(false)}
          onMemoryClick={(memory) => {
            setSelectedMemory(memory);
            setShowCalendarPage(false);
            setCurrentView('memoryDetail');
          }}
          onDailyInsightClick={(insight) => {
            setSelectedDailyInsight(insight);
            setShowCalendarPage(false);
          }}
          onWeeklyInsightClick={(insight) => {
            setSelectedWeeklyInsight(insight);
            setShowCalendarPage(false);
          }}
          onMonthlyInsightClick={(insight) => {
            setSelectedMonthlyInsight(insight);
            setShowCalendarPage(false);
          }}
          onActionClick={(action) => {
            // Open todo detail modal
            if (action.todoData) {
              setSelectedTodo(action.todoData);
              setShowCalendarPage(false);
            }
          }}
          memos={memosProp}
          onMemoClick={(memo) => {
            handleMemoClick(memo);
          }}
          todos={todos}
          setTodos={setTodos}
          onLinkMemory={handleLinkMemory}
          onMemoryClickFromTodo={(memoryId) => {
            const memory = recentMemories.find(m => m.id.toString() === memoryId);
            if (memory) {
              setSelectedMemory(memory);
              setShowCalendarPage(false);
              setCurrentView('memoryDetail');
            }
          }}
        />
      )}

      {/* Show Device Connection Page */}
      {showDeviceConnection && (
        <DeviceConnectionPage 
          onBack={() => setShowDeviceConnection(false)} 
          onDeviceConnected={(device) => {
            setConnectedDevice(device);
            setShowDeviceConnection(false);
          }}
          onDeviceDisconnected={() => {
            setConnectedDevice(null);
          }}
          initialConnectedDevice={connectedDevice}
        />
      )}

      {/* Show Icon Preview Page */}
      {showIconPreview && (
        <IconPreviewPage onBack={() => setShowIconPreview(false)} />
      )}

      {/* All Insights List Page */}
      {showDailyInsightsList && (
        <AllInsightsListPage 
          onBack={() => setShowDailyInsightsList(false)}
          onDailyInsightClick={(insight) => {
            setSelectedDailyInsight(insight);
            setShowDailyInsightsList(false);
          }}
          onWeeklyInsightClick={(insight) => {
            setSelectedWeeklyInsight(insight);
            setShowDailyInsightsList(false);
          }}
          onMonthlyInsightClick={(insight) => {
            setSelectedMonthlyInsight(insight);
            setShowDailyInsightsList(false);
          }}
          onPatternInsightClick={(insight) => {
            setSelectedPatternInsight(insight);
            setShowDailyInsightsList(false);
            setViewedPatternInsightIds(prev => new Set(prev).add(insight.id));
          }}
          viewedPatternInsightIds={viewedPatternInsightIds}
        />
      )}

      {/* Daily Insight Detail */}
      {selectedDailyInsight && (
        <DailyInsightDetail 
          insight={selectedDailyInsight}
          onClose={() => {
            setSelectedDailyInsight(null);
            setShowDailyInsightsList(true);
          }}
          todos={todos}
          onMarkDone={onMarkDone}
          onNotNow={onNotNow}
          onDelete={onDeleteTodo}
          onUpdateTodo={onUpdateTodo}
          onAddTodo={(newTodo) => {
            if (newTodo && typeof newTodo === 'object') {
              setTodos([...todos, { ...newTodo, id: Date.now() }]);
            }
          }}
        />
      )}

      {/* Weekly Insight Detail */}
      {selectedWeeklyInsight && (
        <WeeklyInsightDetail 
          insight={selectedWeeklyInsight}
          onClose={() => {
            setSelectedWeeklyInsight(null);
            setShowDailyInsightsList(true);
          }}
          todos={todos}
          onMarkDone={onMarkDone}
          onNotNow={onNotNow}
          onDelete={onDeleteTodo}
          onUpdateTodo={onUpdateTodo}
          onAddTodo={(newTodo) => {
            if (newTodo && typeof newTodo === 'object') {
              setTodos([...todos, { ...newTodo, id: Date.now() }]);
            }
          }}
        />
      )}

      {/* Monthly Insight Detail */}
      {selectedMonthlyInsight && (
        <MonthlyInsightDetail 
          insight={selectedMonthlyInsight}
          onClose={() => {
            setSelectedMonthlyInsight(null);
            setShowDailyInsightsList(true);
          }}
          onAddTodo={(newTodo) => {
            if (newTodo && typeof newTodo === 'object') {
              setTodos([...todos, { ...newTodo, id: Date.now() }]);
            }
          }}
        />
      )}

      {/* Pattern Insight Detail */}
      {selectedPatternInsight && (
        <PatternInsightDetail 
          insight={selectedPatternInsight}
          onBack={() => {
            setSelectedPatternInsight(null);
            setShowDailyInsightsList(true);
          }}
          onMemoryClick={(memoryId) => {
            const memory = recentMemories.find(m => m.id === parseInt(memoryId));
            if (memory) {
              setSelectedMemory(memory);
              setSelectedPatternInsight(null);
              setCurrentView('memoryDetail');
            }
          }}
          onAddTodo={(newTodo) => {
            if (newTodo && typeof newTodo === 'object') {
              setTodos([...todos, { ...newTodo, id: Date.now() }]);
            }
          }}
          onCreateTodo={(todoTitle) => {
            if (todoTitle && typeof todoTitle === 'string') {
              const newTodo = {
                id: Date.now(),
                title: todoTitle,
                text: todoTitle,
                completed: false,
                category: 'Today',
                isNew: true
              };
              setTodos([...todos, newTodo]);
            }
          }}
        />
      )}

      {/* Show different views based on currentView state */}
      {!showDeviceConnection && !showIconPreview && !showDailyInsightsList && !selectedDailyInsight && !selectedWeeklyInsight && !selectedMonthlyInsight && !selectedPatternInsight && currentView === 'home' && (
        <div className="h-full flex flex-col bg-[#f2f2f7]">
          
          {/* Top Bar with Device Connection, App Title, and Add Button */}
          <div className="px-5 pt-4 pb-2 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button 
                onClick={() => setShowDeviceConnection(true)}
                className="w-8 h-8 rounded-lg bg-white border border-black/[0.06] flex items-center justify-center hover:bg-white/90 transition-colors shadow-[0_1px_2px_rgba(0,0,0,0.06)]"
              >
                {connectedDevice ? (
                  <DeviceIconBattery 
                    batteryPercentage={connectedDevice.battery} 
                    className="w-[18px] h-[18px]" 
                  />
                ) : (
                  <DeviceIconBattery 
                    batteryLevel="disconnected" 
                    className="w-[18px] h-[18px]" 
                  />
                )}
              </button>
              <span className="text-[17px] text-[#3c3c43] tracking-[-0.4px] font-medium">MemoPin</span>
            </div>
            <div className="flex items-center gap-3">
              {/* Calendar button */}
              <button 
                onClick={() => setShowCalendarPage(true)}
                className="w-8 h-8 flex items-center justify-center text-[#007aff] hover:opacity-70 transition-opacity active:scale-95"
              >
                <Calendar className="w-5.5 h-5.5" strokeWidth={2.5} />
              </button>
              
              {/* Add/Options button */}
              <button 
                onClick={() => setShowOptionsModal(true)}
                className="w-8 h-8 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors shadow-md active:scale-95"
              >
                <Plus className="w-[18px] h-[18px] text-white" strokeWidth={2.5} />
              </button>
            </div>
          </div>

          {/* Audio Status Bar - Only show when there's audio activity */}
          {audioStatus && (
            <AudioStatusBar 
              type={audioStatus.type}
              progress={audioStatus.progress}
              currentFile={audioStatus.currentFile}
              totalFiles={audioStatus.totalFiles}
            />
          )}

          {/* Main Content - Scrollable */}
          {devMode === 'empty' ? (
            <PullToRefresh onRefresh={handleRefresh}>
              <HomeEmptyState
                memoryCount={recentMemories.filter(m => m.isUserCreated).length}
                todoCount={todos.filter(t => t.isNew).length}
                insightCount={0}
                onStartRecording={async () => {
                  const hasPermission = await checkAndRequestPermission('recording');
                  if (hasPermission) setShowRecordingModal(true);
                }}
                onQuickCapture={async () => {
                  const hasPermission = await checkAndRequestPermission('quickCapture');
                  if (hasPermission) setShowQuickCaptureModal(true);
                }}
                onAddTask={() => setShowTodoModal(true)}
                onViewAllTodos={() => setCurrentView('todoList')}
                todos={todos.filter(t => t.isNew)}
                memories={recentMemories.filter(m => m.isUserCreated)}
                onSwitchToMemoryTab={onSwitchToMemoryTab}
                onMemoryClick={handleHomeMemoryClick}
              />
            </PullToRefresh>
          ) : (
            <PullToRefresh onRefresh={handleRefresh}>
              <div className="px-5 pt-2 pb-20 flex flex-col gap-4">
              
              {/* ZONE 1: Up Next (Ultra-soft mint green) */}
              <div className="w-full bg-gradient-to-br from-[#f8fdf9] via-[#fcfefb] to-white rounded-[20px] p-6 shadow-[0_2px_8px_rgba(0,0,0,0.04),0_1px_2px_rgba(0,0,0,0.02)] border border-black/[0.04]">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-[17px] text-[#1c1c1e] font-semibold">Today's Focus</h3>
                <button 
                  onClick={() => setCurrentView('todoList')}
                  className="flex items-center gap-1 text-[#059669] text-[14px] font-medium hover:opacity-70 transition-opacity"
                >
                  View All
                  <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
                </button>
              </div>
              
              <div className="space-y-4">
                {todos.filter(t => t.category === 'Up Next').slice(0, 3).map((todo) => (
                  <div
                    key={todo.id}
                    className="w-full"
                  >
                    {/* Clickable Todo Title */}
                    <button
                      onClick={() => handleHomeTodoClick(todo)}
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
                    
                    {/* Non-clickable Reason */}
                    {todo.reason && (
                      <div className="flex items-center gap-3 mt-1.5 ml-7">
                        <span className="text-[13px] text-[#8e8e93]">→ {todo.reason}</span>
                      </div>
                    )}
                  </div>
                ))}
                
                {/* Suggestion card when Up Next has fewer than 3 todos */}
                {todos.filter(t => t.category === 'Up Next').length < 3 && (
                  <div className="mt-4 p-4 bg-[#059669]/5 rounded-[12px] border border-[#059669]/10">
                    <p className="text-[14px] text-[#3c3c43] mb-3">
                      Add more tasks to Today's Focus to stay productive
                    </p>
                    <button
                      onClick={() => setCurrentView('todoList')}
                      className="w-full py-2 bg-[#059669] text-white text-[14px] font-medium rounded-[8px] hover:bg-[#047857] transition-colors"
                    >
                      Add to Today's Focus
                    </button>
                  </div>
                )}
              </div>
            </div>

            {/* ZONE 2: Recent Memory (Ultra-soft cream/beige) */}
            <div className="w-full bg-gradient-to-br from-[#fffcf5] via-[#fffef9] to-white rounded-[20px] p-6 shadow-[0_2px_8px_rgba(0,0,0,0.04),0_1px_2px_rgba(0,0,0,0.02)] border border-black/[0.04]">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-[17px] text-[#1c1c1e] font-semibold">Recent Memory</h3>
                <button 
                  onClick={() => onSwitchToMemoryTab?.()}
                  className="flex items-center gap-1 text-[#d97706] text-[14px] font-medium hover:opacity-70 transition-opacity"
                >
                  View All
                  <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
                </button>
              </div>
              {recentMemories.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#d97706]/10 to-[#b45309]/10 flex items-center justify-center mb-4">
                    <Mic className="w-8 h-8 text-[#d97706]" strokeWidth={2} />
                  </div>
                  <p className="text-[15px] text-[#8e8e93] mb-4">No memories yet</p>
                  <button
                    onClick={async () => {
                      const hasPermission = await checkAndRequestPermission('recording');
                      if (hasPermission) setShowRecordingModal(true);
                    }}
                    className="px-4 py-2 bg-[#d97706] text-white text-[14px] font-medium rounded-[10px] hover:bg-[#b45309] transition-colors"
                  >
                    Start Recording
                  </button>
                </div>
              ) : (
                <div className="space-y-3">
                  {recentMemories.slice(0, 3).map((memory) => (
                    <button
                      key={memory.id}
                      onClick={() => handleHomeMemoryClick(memory)}
                      className="w-full flex items-start justify-between gap-3 text-left hover:opacity-70 transition-opacity"
                    >
                      <p className="flex-1 leading-[1.5] text-[15px] text-[#3c3c43] line-clamp-1">
                        {memory.title || memory.date}
                      </p>
                      <span className="text-[13px] text-[#8e8e93] flex-shrink-0">{memory.time}</span>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* ZONE 3: AI Reflections */}
            <InsightsSummaryCard 
              onClick={() => setShowDailyInsightsList(true)}
              unreadCount={viewedPatternInsightIds.has('pattern-feb-2') ? 0 : 1}
            />

              </div>
            </PullToRefresh>
          )}

          {/* Recording Modal */}
          {showRecordingModal && (
            <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => !hasStartedRecording && handleCloseRecordingModal()}>
              <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
                {/* Minimize Button - Top Left (only show when recording has started) */}
                {hasStartedRecording && recordingState && (
                  <button
                    onClick={() => {
                      // Sync current state to App level before minimizing
                      recordingState.setIsRecording(isRecording);
                      recordingState.setRecordingTime(recordingTime);
                      recordingState.onMinimize();
                      setShowRecordingModal(false);
                    }}
                    className="absolute top-4 left-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
                  >
                    <Minimize2 className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                  </button>
                )}
                
                {/* Close Button - Top Right */}
                <button
                  onClick={handleCloseRecordingModal}
                  className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
                >
                  <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                </button>

                <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-6 text-center">Record Audio</h3>
                
                <div className={`flex flex-col items-center gap-4 ${hasStartedRecording ? 'mb-6' : 'mb-8'}`}>
                  {/* Recording Time - Show when recording has started */}
                  {hasStartedRecording && (
                    <div className="text-[32px] font-mono font-semibold text-[#1c1c1e] tabular-nums">
                      {formatTime(recordingTime)}
                    </div>
                  )}
                  
                  <button
                    onClick={isRecording ? pauseRecording : startRecording}
                    className={`w-20 h-20 rounded-full flex items-center justify-center transition-all shadow-lg ${
                      !hasStartedRecording
                        ? 'bg-[#007aff] hover:bg-[#0051d5]' 
                        : isRecording 
                          ? 'bg-[#ff3b30] hover:bg-[#ff4d42]' 
                          : 'bg-[#ff3b30] hover:bg-[#ff4d42]'
                    }`}
                  >
                    {!hasStartedRecording ? (
                      <Mic className="w-9 h-9 text-white" strokeWidth={2} />
                    ) : isRecording ? (
                      <Pause className="w-9 h-9 text-white" strokeWidth={2} />
                    ) : (
                      <Play className="w-9 h-9 text-white fill-white" strokeWidth={2} />
                    )}
                  </button>
                  
                  <p className="text-[15px] text-[#3c3c43] text-center">
                    {!hasStartedRecording 
                      ? 'Tap to start recording' 
                      : isRecording 
                        ? 'Recording...' 
                        : 'Paused'}
                  </p>
                </div>

                {/* Bottom Buttons - Show when has started recording */}
                {hasStartedRecording && (
                  <div className="flex gap-3">
                    <button
                      onClick={() => setShowCancelConfirmModal(true)}
                      className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleSaveRecording}
                      className="flex-1 py-3 bg-[#007aff] rounded-[12px] text-white font-semibold hover:bg-[#0051d5] transition-colors"
                    >
                      Save
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Cancel Confirm Modal */}
          {showCancelConfirmModal && (
            <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => setShowCancelConfirmModal(false)}>
              <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
                {/* Close Button - Top Right */}
                <button
                  onClick={() => setShowCancelConfirmModal(false)}
                  className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
                >
                  <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                </button>

                <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-6 text-center">Cancel Recording</h3>
                
                <p className="text-[15px] text-[#3c3c43] text-center mb-6">
                  Are you sure you want to cancel this recording? All progress will be lost.
                </p>

                {/* Bottom Buttons */}
                <div className="flex gap-3">
                  <button
                    onClick={() => setShowCancelConfirmModal(false)}
                    className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
                  >
                    No, Keep Recording
                  </button>
                  <button
                    onClick={handleConfirmCancel}
                    className="flex-1 py-3 bg-[#ff3b30] rounded-[12px] text-white font-semibold hover:bg-[#ff4d42] transition-colors"
                  >
                    Yes, Cancel
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Options Modal - iOS Style */}
          {showOptionsModal && (
            <div 
              className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-end justify-center p-5 pb-7" 
              onClick={() => setShowOptionsModal(false)}
            >
              <div 
                className="w-full max-w-sm relative"
                onClick={(e) => e.stopPropagation()}
              >
                {/* Options Card */}
                <div className="bg-white rounded-[18px] overflow-hidden shadow-2xl mb-3">
                  {/* Close Button */}
                  <div className="absolute top-3 right-3 z-10">
                    <button
                      onClick={() => setShowOptionsModal(false)}
                      className="w-7 h-7 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
                    >
                      <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                    </button>
                  </div>

                  {/* Start Recording Option */}
                  <button
                    onClick={async () => {
                      setShowOptionsModal(false);
                      const hasPermission = await checkAndRequestPermission('recording');
                      if (hasPermission) setShowRecordingModal(true);
                    }}
                    className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                  >
                    <div className="w-11 h-11 rounded-full bg-gradient-to-br from-[#007aff] to-[#0051d5] flex items-center justify-center flex-shrink-0 shadow-sm">
                      <Mic className="w-5 h-5 text-white" strokeWidth={2.5} />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">Start Recording</h3>
                      <p className="text-[13px] text-[#8e8e93]">Record a new audio memory</p>
                    </div>
                  </button>

                  {/* Quick Capture Option */}
                  <button
                    onClick={() => {
                      setShowOptionsModal(false);
                      setShowQuickCaptureModal(true);
                    }}
                    className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                  >
                    <div className="w-11 h-11 rounded-full bg-gradient-to-br from-[#ff9f40] to-[#ff8c00] flex items-center justify-center flex-shrink-0 shadow-sm">
                      <PenSquare className="w-5 h-5 text-white" strokeWidth={2.5} />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">Quick Capture</h3>
                      <p className="text-[13px] text-[#8e8e93]">Type or speak a quick note</p>
                    </div>
                  </button>

                  {/* Import Audio Option */}
                  <button
                    onClick={handleImportAudio}
                    className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                  >
                    <div className="w-11 h-11 rounded-full bg-gradient-to-br from-[#34c759] to-[#28a745] flex items-center justify-center flex-shrink-0 shadow-sm">
                      <Upload className="w-5 h-5 text-white" strokeWidth={2.5} />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">Import Audio</h3>
                      <p className="text-[13px] text-[#8e8e93]">Choose an audio file from your device</p>
                    </div>
                  </button>

                  {/* Test MemoPin Recording - For Demo */}
                  <button
                    onClick={async () => {
                      setShowOptionsModal(false);
                      setRecording();
                      await new Promise(resolve => setTimeout(resolve, 3000));
                      clearStatus();
                    }}
                    className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                  >
                    <div className="w-11 h-11 rounded-full bg-gradient-to-br from-[#ff3b30] to-[#d32f2f] flex items-center justify-center flex-shrink-0 shadow-sm">
                      <Mic className="w-5 h-5 text-white" strokeWidth={2.5} />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">Test: MemoPin Recording</h3>
                      <p className="text-[13px] text-[#8e8e93]">Simulate device recording (3s demo)</p>
                    </div>
                  </button>

                  {/* Test Syncing - For Demo */}
                  <button
                    onClick={async () => {
                      setShowOptionsModal(false);
                      setSyncing(1, 3, 0);
                      for (let i = 0; i <= 100; i += 10) {
                        await new Promise(resolve => setTimeout(resolve, 200));
                        setSyncing(1, 3, i);
                      }
                      await new Promise(resolve => setTimeout(resolve, 300));
                      setSyncing(2, 3, 0);
                      for (let i = 0; i <= 100; i += 10) {
                        await new Promise(resolve => setTimeout(resolve, 150));
                        setSyncing(2, 3, i);
                      }
                      await new Promise(resolve => setTimeout(resolve, 300));
                      setSyncing(3, 3, 0);
                      for (let i = 0; i <= 100; i += 10) {
                        await new Promise(resolve => setTimeout(resolve, 150));
                        setSyncing(3, 3, i);
                      }
                      await new Promise(resolve => setTimeout(resolve, 500));
                      clearStatus();
                    }}
                    className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors"
                  >
                    <div className="w-11 h-11 rounded-full bg-gradient-to-br from-[#5856d6] to-[#4b4acf] flex items-center justify-center flex-shrink-0 shadow-sm">
                      <Upload className="w-5 h-5 text-white" strokeWidth={2.5} />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">Test: Sync 3 Files</h3>
                      <p className="text-[13px] text-[#8e8e93]">Simulate syncing multiple recordings</p>
                    </div>
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {currentView === 'todoList' && (
        <TodoListPage 
          onBack={() => setCurrentView('home')}
          todos={todos}
          setTodos={setTodos}
          onLinkMemory={handleLinkMemory}
          onMemoryClick={handleMemoryClickFromTodo}
        />
      )}

      {currentView === 'todoDetail' && selectedTodo && (
        <TodoDetailModal
          todo={selectedTodo}
          onClose={() => setCurrentView('todoList')}
          onToggle={handleToggleTodo}
          onDelete={handleDeleteTodo}
          onMarkDone={handleMarkDone}
          onNotNow={handleNotNow}
          onLinkMemory={handleLinkMemory}
          onMemoryClick={handleMemoryClickFromTodo}
          onUpdate={handleUpdateTodo}
        />
      )}



      {currentView === 'memoryDetail' && selectedMemory && (
        <MemoryDetailPage
          memory={selectedMemory}
          onBack={() => {
            // Reset memory detail params
            setMemoryInitialTab('Overview');
            setMemoryHighlightTimestamp(undefined);
            // Return to the correct context
            if (memoryReturnContext === 'todoModal') {
              setCurrentView('home');
              setShowTodoModal(true);
              setMemoryReturnContext('home'); // Reset context
            } else {
              setCurrentView('home');
            }
          }}
          onSaveTodo={(newTodo) => {
            setTodos([...todos, newTodo]);
          }}
          initialTab={memoryInitialTab}
          highlightTimestamp={memoryHighlightTimestamp}
        />
      )}

      {showTodoModal && selectedTodo && (
        <TodoDetailModal
          todo={selectedTodo}
          onClose={() => setShowTodoModal(false)}
          onToggle={handleToggleTodo}
          onDelete={handleDeleteTodo}
          onMarkDone={handleMarkDone}
          onNotNow={handleNotNow}
          onLinkMemory={handleLinkMemory}
          onMemoryClick={handleMemoryClickFromTodo}
          onUpdate={handleUpdateTodo}
        />
      )}



      {/* Delete Confirm Modal */}
      {showDeleteConfirmModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => setShowDeleteConfirmModal(false)}>
          <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
            {/* Close Button - Top Right */}
            <button
              onClick={() => setShowDeleteConfirmModal(false)}
              className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
            >
              <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
            </button>

            <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-6 text-center">Delete Todo</h3>
            
            <p className="text-[15px] text-[#3c3c43] text-center mb-6">
              Are you sure you want to delete this todo? This action cannot be undone.
            </p>

            {/* Bottom Buttons */}
            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteConfirmModal(false)}
                className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
              >
                No, Keep Todo
              </button>
              <button
                onClick={confirmDeleteTodo}
                className="flex-1 py-3 bg-[#ff3b30] rounded-[12px] text-white font-semibold hover:bg-[#ff4d42] transition-colors"
              >
                Yes, Delete
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Memory List Selector */}
      {showMemorySelector && (
        <MemoryListSelector
          onBack={() => setShowMemorySelector(false)}
          onSelectMemory={handleSelectMemory}
          memories={recentMemories}
        />
      )}

      {/* Quick Capture Modal */}
      {showQuickCaptureModal && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          {/* Backdrop */}
          <div 
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={handleCancelQuickCapture}
          />
          
          {/* Modal - Half-screen popup */}
          <div 
            className="relative w-full max-w-md bg-white rounded-t-[24px] shadow-2xl animate-slide-up"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="px-5 pt-5 pb-4 flex items-center justify-between border-b border-black/[0.06]">
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Quick Capture</h3>
              <button 
                onClick={handleCancelQuickCapture}
                className="w-8 h-8 flex items-center justify-center text-[#8e8e93] hover:opacity-70 transition-opacity"
              >
                <X className="w-5 h-5" strokeWidth={2.5} />
              </button>
            </div>

            {/* Content */}
            <div className="px-5 pt-6 pb-6 max-h-[70vh] flex flex-col">
              {/* Multi-line textarea */}
              <textarea
                autoFocus
                value={quickCaptureMemoText}
                onChange={(e) => setQuickCaptureMemoText(e.target.value)}
                placeholder="Capture a thought, idea, or task..."
                className="flex-1 min-h-[200px] text-[17px] text-[#1c1c1e] leading-[1.6] resize-none outline-none placeholder:text-[#8e8e93] bg-transparent"
                style={{ fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' }}
                disabled={isQuickCaptureRecording || quickCaptureProcessing !== ''}
              />
              
              {/* Recording Waveform */}
              {isQuickCaptureRecording && (
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

              {/* Processing indicator (Transcribing or Analyzing) */}
              {quickCaptureProcessing !== '' && (
                <div className="flex items-center justify-center py-8">
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" />
                    <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.2s' }} />
                    <div className="w-2 h-2 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.4s' }} />
                    <span className="ml-2 text-[14px] text-[#8e8e93]">
                      {quickCaptureProcessing === 'transcribing' ? 'Transcribing...' : 'Analyzing...'}
                    </span>
                  </div>
                </div>
              )}
              
              {/* Bottom bar with buttons */}
              <div className="flex items-center justify-between pt-4 border-t border-black/[0.06] mt-4">
                {isQuickCaptureRecording ? (
                  <>
                    {/* Cancel recording button */}
                    <button
                      onClick={handleCancelQuickCaptureRecording}
                      className="w-9 h-9 rounded-full bg-[#f2f2f7] flex items-center justify-center hover:bg-[#e5e5ea] transition-colors active:scale-95"
                    >
                      <X className="w-5 h-5 text-[#8e8e93]" strokeWidth={2.5} />
                    </button>
                    
                    {/* Send voice button */}
                    <button
                      onClick={handleSendQuickCaptureVoice}
                      className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors active:scale-95"
                    >
                      <Check className="w-5 h-5 text-white" strokeWidth={2.5} />
                    </button>
                  </>
                ) : quickCaptureProcessing !== '' ? (
                  <div className="flex-1" />
                ) : (
                  <>
                    <div className="flex-1" />
                    {quickCaptureMemoText.trim() ? (
                      <button
                        onClick={handleSaveQuickCapture}
                        className="w-9 h-9 rounded-full bg-[#007aff] flex items-center justify-center hover:bg-[#0051d5] transition-colors active:scale-95"
                      >
                        <ArrowUp className="w-5 h-5 text-white" strokeWidth={2.5} />
                      </button>
                    ) : (
                      <button
                        onClick={handleStartQuickCaptureRecording}
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

      {/* Quick Capture Confirmation Modal */}
      {showQuickCaptureConfirm && (
        <div className="fixed inset-0 z-50 flex items-end justify-center">
          {/* Backdrop */}
          <div 
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={handleCancelAiParsed}
          />
          
          {/* Modal - Half-screen popup */}
          <div 
            className="relative w-full max-w-md bg-white rounded-t-[24px] shadow-2xl animate-slide-up"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="px-5 pt-5 pb-4 flex items-center justify-between border-b border-black/[0.06]">
              <h3 className="text-[17px] font-semibold text-[#1c1c1e]">AI understood this</h3>
              <button 
                onClick={handleCancelAiParsed}
                className="w-8 h-8 flex items-center justify-center text-[#8e8e93] hover:opacity-70 transition-opacity"
              >
                <X className="w-5 h-5" strokeWidth={2.5} />
              </button>
            </div>

            {/* Content - Scrollable */}
            <div className="px-5 pt-4 pb-6 max-h-[60vh] overflow-y-auto">
              
              {/* Original Text Section */}
              <div className="mb-5">
                <h4 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2.5">
                  Original text
                </h4>
                <button
                  onClick={handleSelectOriginal}
                  className={`w-full text-left p-4 rounded-[12px] transition-all ${
                    selectionMode === 'original'
                      ? 'border-2 border-[#007aff] bg-[#007aff]/[0.04]'
                      : 'border border-black/[0.08] bg-[#f9f9f9] hover:bg-[#f2f2f7]'
                  }`}
                >
                  <p className={`text-[15px] leading-[1.5] ${
                    selectionMode === 'original' ? 'text-[#1c1c1e]' : 'text-[#3c3c43]'
                  }`}>
                    {originalTranscript}
                  </p>
                </button>
              </div>

              {/* Divider */}
              <div className="h-[1px] bg-black/[0.06] my-5" />

              {/* Structured Suggestions Section */}
              <div>
                <h4 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2.5">
                  Structured suggestions
                </h4>
                <div
                  className={`p-4 rounded-[12px] transition-all ${
                    selectionMode === 'structured'
                      ? 'border-2 border-[#007aff] bg-[#007aff]/[0.04]'
                      : 'border border-black/[0.08] bg-[#f9f9f9] hover:bg-[#f2f2f7] cursor-pointer'
                  }`}
                >
                  {/* Todo items */}
                  {aiParsedTodos.map((todo, index) => (
                    <div 
                      key={`todo-${todo.id}`}
                      className={`flex items-start gap-3 py-2.5 ${
                        index < aiParsedTodos.length + aiParsedMemos.length - 1 ? 'border-b border-black/[0.06]' : ''
                      }`}
                    >
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          if (selectionMode !== 'structured') {
                            handleSelectStructured();
                          } else {
                            toggleAiTodoSelection(todo.id);
                          }
                        }}
                        className="flex-shrink-0 mt-0.5 w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all cursor-pointer"
                        style={{
                          borderColor: todo.selected && selectionMode === 'structured' ? '#007aff' : '#d1d1d6',
                          backgroundColor: todo.selected && selectionMode === 'structured' ? '#007aff' : 'transparent'
                        }}
                      >
                        {todo.selected && selectionMode === 'structured' && (
                          <Check className="w-3.5 h-3.5 text-white" strokeWidth={3} />
                        )}
                      </button>
                      <div 
                        className="flex-1 cursor-pointer"
                        onClick={() => {
                          if (selectionMode !== 'structured') {
                            handleSelectStructured();
                          } else {
                            toggleAiTodoSelection(todo.id);
                          }
                        }}
                      >
                        <p className={`text-[15px] leading-[1.5] transition-opacity ${
                          selectionMode === 'structured' && todo.selected ? 'text-[#1c1c1e]' : 'text-[#8e8e93]'
                        }`}>
                          <span className="font-medium">Todo:</span> {todo.text}
                        </p>
                      </div>
                    </div>
                  ))}

                  {/* Memo items */}
                  {aiParsedMemos.map((memo, index) => (
                    <div 
                      key={`memo-${memo.id}`}
                      className={`flex items-start gap-3 py-2.5 ${
                        index < aiParsedMemos.length - 1 ? 'border-b border-black/[0.06]' : ''
                      }`}
                    >
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          if (selectionMode !== 'structured') {
                            handleSelectStructured();
                          } else {
                            toggleAiMemoSelection(memo.id);
                          }
                        }}
                        className="flex-shrink-0 mt-0.5 w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all cursor-pointer"
                        style={{
                          borderColor: memo.selected && selectionMode === 'structured' ? '#007aff' : '#d1d1d6',
                          backgroundColor: memo.selected && selectionMode === 'structured' ? '#007aff' : 'transparent'
                        }}
                      >
                        {memo.selected && selectionMode === 'structured' && (
                          <Check className="w-3.5 h-3.5 text-white" strokeWidth={3} />
                        )}
                      </button>
                      <div 
                        className="flex-1 cursor-pointer"
                        onClick={() => {
                          if (selectionMode !== 'structured') {
                            handleSelectStructured();
                          } else {
                            toggleAiMemoSelection(memo.id);
                          }
                        }}
                      >
                        <p className={`text-[15px] leading-[1.5] transition-opacity ${
                          selectionMode === 'structured' && memo.selected ? 'text-[#1c1c1e]' : 'text-[#8e8e93]'
                        }`}>
                          <span className="font-medium">Memo:</span> {memo.text}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Bottom buttons */}
            <div className="px-5 pb-6 pt-4 border-t border-black/[0.06] flex gap-3">
              <button
                onClick={handleCancelAiParsed}
                className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmAiParsed}
                className="flex-1 py-3 bg-[#007aff] rounded-[12px] text-white font-semibold hover:bg-[#0051d5] transition-colors"
              >
                Confirm
              </button>
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
          `}</style>
        </div>
      )}

      {/* Microphone Permission Modal */}
      <MicrophonePermissionModal
        isOpen={showMicPermissionModal}
        onContinue={handlePermissionContinue}
        onNotNow={handlePermissionNotNow}
      />

      {/* Microphone Permission Denied Modal */}
      <MicrophonePermissionDeniedModal
        isOpen={showMicPermissionDeniedModal}
        onClose={() => setShowMicPermissionDeniedModal(false)}
        onOpenSettings={handleOpenSettings}
      />
    </>
  );
}