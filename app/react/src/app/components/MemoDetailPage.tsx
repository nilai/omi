import { ChevronLeft, Trash2 } from 'lucide-react';

interface Memo {
  id: number;
  title?: string;
  content: string;
  timestamp?: Date;
  category?: 'Today' | 'Earlier' | 'Long ago';
  relatedMemories?: string[];
}

interface MemoDetailPageProps {
  memo: Memo;
  onBack: () => void;
  onDelete?: (memoId: number) => void;
  onCreateTodo?: (memoId: number) => void;
  onRelatedMemoryClick?: (memoryTitle: string) => void;
}

export function MemoDetailPage({ memo, onBack, onDelete, onCreateTodo, onRelatedMemoryClick }: MemoDetailPageProps) {
  const handleDelete = () => {
    onDelete?.(memo.id);
    onBack();
  };

  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
        <button 
          onClick={onBack}
          className="flex items-center gap-2 text-[#007aff] text-[17px] font-medium hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
          <span>Memo</span>
        </button>
        {onDelete && (
          <button 
            onClick={handleDelete}
            className="w-8 h-8 flex items-center justify-center text-[#ff3b30] hover:opacity-70 transition-opacity"
          >
            <Trash2 className="w-5 h-5" strokeWidth={2} />
          </button>
        )}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto px-5 pt-6 pb-8">
        {/* Memo 标题（如果有） */}
        {memo.title && (
          <div className="mb-6">
            <h2 className="text-[22px] text-[#1c1c1e] font-semibold leading-[1.3]">
              {memo.title}
            </h2>
          </div>
        )}

        {/* Divider */}
        {memo.title && (
          <div className="h-[1px] bg-black/[0.1] mb-6" />
        )}

        {/* Memo 内容 */}
        <div className="mb-8">
          <p className="text-[17px] text-[#1c1c1e] leading-[1.6] whitespace-pre-wrap">
            {memo.content}
          </p>
        </div>

        {/* Related Memory (optional) */}
        {memo.relatedMemories && memo.relatedMemories.length > 0 && (
          <>
            <div className="h-[1px] bg-black/[0.1] mb-6" />
            
            <div className="mb-8">
              <h3 className="text-[13px] text-[#8e8e93] font-medium mb-3">
                Related memory (optional)
              </h3>
              <div className="space-y-2">
                {memo.relatedMemories.map((related, index) => (
                  <button
                    key={index}
                    onClick={() => onRelatedMemoryClick?.(related)}
                    className="w-full text-left px-0 py-2 rounded-[8px] hover:bg-white/60 transition-colors group"
                  >
                    <p className="text-[15px] text-[#3c3c43] leading-[1.5] group-hover:text-[#007aff] transition-colors">
                      {related}
                    </p>
                  </button>
                ))}
              </div>
            </div>
          </>
        )}

        {/* Divider before Actions */}
        <div className="h-[1px] bg-black/[0.1] mb-6" />

        {/* Actions */}
        <div className="mb-2">
          <h3 className="text-[13px] text-[#8e8e93] font-medium mb-3">
            Actions
          </h3>
          <button
            onClick={() => {
              onCreateTodo?.(memo.id);
              onBack();
            }}
            className="text-[15px] text-[#007aff]/70 hover:text-[#007aff] transition-colors font-normal"
          >
            + Create Todo
          </button>
        </div>
      </div>
    </div>
  );
}
