import { X } from 'lucide-react';
import { useState, useEffect } from 'react';

interface SuggestedTodo {
  id: string;
  text: string;
  checked: boolean;
}

interface AnalyzeActionsModalProps {
  isOpen: boolean;
  onClose: () => void;
  memoContent: string;
  memoTitle?: string;
  memoId?: number;
  onConfirm: (selectedTodos: string[]) => void;
}

export function AnalyzeActionsModal({ isOpen, onClose, memoContent, memoTitle, memoId, onConfirm }: AnalyzeActionsModalProps) {
  const [isAnalyzing, setIsAnalyzing] = useState(true);
  const [suggestedTodos, setSuggestedTodos] = useState<SuggestedTodo[]>([]);

  // Simulate AI extraction of todos from memo content
  const extractTodosFromMemo = (content: string, title: string = '', id?: number): SuggestedTodo[] => {
    // Special case for the first memo (id: 1) - use design mockup examples
    if (id === 1) {
      return [
        {
          id: 'todo-1',
          text: 'Design ADHD-friendly onboarding',
          checked: true
        },
        {
          id: 'todo-2',
          text: 'Research progressive disclosure patterns',
          checked: true
        },
        {
          id: 'todo-3',
          text: 'Interview ADHD users about onboarding',
          checked: true
        }
      ];
    }

    // Simple AI simulation: look for action-oriented keywords and sentences
    const sentences = content.split(/[.!?]+/).filter(s => s.trim().length > 0);
    const todos: SuggestedTodo[] = [];
    
    // Keywords that suggest actionable items
    const actionKeywords = ['need', 'should', 'could', 'must', 'have to', 'want to', 'plan to', 'consider', 'explore', 'research', 'design', 'create', 'build', 'implement', 'add', 'improve', 'fix', 'update', 'review', 'interview', 'contact', 'schedule', 'prepare', 'write', 'develop'];
    
    sentences.forEach((sentence, index) => {
      const lowerSentence = sentence.toLowerCase();
      const hasActionKeyword = actionKeywords.some(keyword => lowerSentence.includes(keyword));
      
      if (hasActionKeyword && sentence.trim().length > 15) {
        // Clean up the sentence to make it todo-like
        let todoText = sentence.trim();
        
        // Remove common prefixes
        todoText = todoText.replace(/^(maybe|perhaps|i think|we should|we could|need to|have to|want to|should|could|might)\s+/i, '');
        
        // Capitalize first letter
        todoText = todoText.charAt(0).toUpperCase() + todoText.slice(1);
        
        // Limit length
        if (todoText.length > 80) {
          todoText = todoText.substring(0, 77) + '...';
        }
        
        todos.push({
          id: `todo-${index}`,
          text: todoText,
          checked: true // Default all checked
        });
      }
    });
    
    // If no todos found, create generic ones based on content
    if (todos.length === 0) {
      const words = content.trim().split(/\s+/);
      if (words.length > 5) {
        todos.push({
          id: 'todo-1',
          text: 'Follow up on: ' + content.substring(0, 50) + (content.length > 50 ? '...' : ''),
          checked: true
        });
      }
    }
    
    // Limit to 5 todos max
    return todos.slice(0, 5);
  };

  // Simulate AI analysis with delay
  useEffect(() => {
    if (isOpen) {
      setIsAnalyzing(true);
      setSuggestedTodos([]);
      
      // Simulate 2.5 second AI analysis
      const timer = setTimeout(() => {
        const todos = extractTodosFromMemo(memoContent, memoTitle || '', memoId);
        setSuggestedTodos(todos);
        setIsAnalyzing(false);
      }, 2500);

      return () => clearTimeout(timer);
    }
  }, [isOpen, memoContent, memoTitle, memoId]);

  const toggleTodo = (id: string) => {
    setSuggestedTodos(todos => 
      todos.map(todo => 
        todo.id === id ? { ...todo, checked: !todo.checked } : todo
      )
    );
  };

  const handleConfirm = () => {
    const selectedTodos = suggestedTodos
      .filter(todo => todo.checked)
      .map(todo => todo.text);
    onConfirm(selectedTodos);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal */}
      <div 
        className="relative w-full max-w-md bg-white rounded-t-[24px] shadow-2xl animate-slide-up"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="px-5 pt-5 pb-4 border-b border-black/[0.06]">
          <div className="flex items-center justify-between mb-1">
            <h2 className="text-[22px] text-[#1c1c1e] font-semibold">
              Suggested tasks
            </h2>
            <button 
              onClick={onClose}
              className="w-7 h-7 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
            >
              <X className="w-5 h-5" strokeWidth={2} />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="px-5 py-6 max-h-[60vh] overflow-y-auto">
          {isAnalyzing ? (
            /* Analyzing State */
            <div className="flex flex-col items-center justify-center py-16">
              {/* Animated dots */}
              <div className="flex items-center gap-2 mb-4">
                <div className="w-2.5 h-2.5 bg-[#007aff] rounded-full animate-pulse" />
                <div className="w-2.5 h-2.5 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.2s' }} />
                <div className="w-2.5 h-2.5 bg-[#007aff] rounded-full animate-pulse" style={{ animationDelay: '0.4s' }} />
              </div>
              
              {/* Analyzing text */}
              <p className="text-[15px] text-[#8e8e93] font-medium">
                Analyzing your memo...
              </p>
            </div>
          ) : (
            /* Results State */
            <>
              {/* Original Text Section */}
              <div className="mb-6">
                <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-3">
                  From your memo
                </h3>
                <div className="p-4 rounded-[12px] bg-[#f9f9fb] border border-black/[0.04]">
                  <p className="text-[15px] text-[#3c3c43] leading-[1.5]">
                    {memoContent}
                  </p>
                </div>
              </div>

              {/* Suggested Todos Section */}
              <div>
                <h3 className="text-[11px] text-[#8e8e93] font-semibold uppercase tracking-wide mb-3">
                  Suggestions
                </h3>
                <div className="p-4 rounded-[16px] bg-gradient-to-br from-[#f0f7ff] to-[#f5f9ff] border-2 border-[#007aff]/20 shadow-sm">
                  <div className="space-y-3">
                    {suggestedTodos.map((todo) => (
                      <label
                        key={todo.id}
                        className="flex items-start gap-3 p-3 rounded-[12px] bg-white/80 hover:bg-white transition-all cursor-pointer group shadow-sm hover:shadow"
                      >
                        <div className="relative flex items-center justify-center mt-0.5">
                          <input
                            type="checkbox"
                            checked={todo.checked}
                            onChange={() => toggleTodo(todo.id)}
                            className="appearance-none w-[22px] h-[22px] rounded-full border-2 border-[#007aff] cursor-pointer transition-all checked:bg-[#007aff] checked:border-[#007aff] hover:border-[#0051d5] focus:outline-none focus:ring-2 focus:ring-[#007aff]/30 focus:ring-offset-1"
                          />
                          {todo.checked && (
                            <svg 
                              className="absolute w-[14px] h-[14px] text-white pointer-events-none"
                              viewBox="0 0 24 24" 
                              fill="none" 
                              stroke="currentColor" 
                              strokeWidth="3.5" 
                              strokeLinecap="round" 
                              strokeLinejoin="round"
                            >
                              <polyline points="20 6 9 17 4 12" />
                            </svg>
                          )}
                        </div>
                        <span className="flex-1 text-[15px] text-[#1c1c1e] leading-[1.45] font-normal">
                          {todo.text}
                        </span>
                      </label>
                    ))}
                  </div>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Footer Actions */}
        {!isAnalyzing && (
          <div className="px-5 py-4 border-t border-black/[0.06] flex gap-3">
            <button
              onClick={onClose}
              className="flex-1 h-[50px] rounded-[14px] bg-[#f2f2f7] text-[#1c1c1e] text-[17px] font-medium hover:bg-[#e5e5ea] transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleConfirm}
              disabled={isAnalyzing || !suggestedTodos.some(t => t.checked)}
              className="flex-1 h-[50px] rounded-[14px] bg-[#007aff] text-white text-[17px] font-semibold hover:bg-[#0051d5] transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
              Create tasks
            </button>
          </div>
        )}
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
  );
}