import { X } from 'lucide-react';

interface SystemShareModalProps {
  isOpen: boolean;
  onClose: () => void;
  shareUrl?: string;
  title?: string;
}

export function SystemShareModal({ isOpen, onClose, shareUrl = 'https://www.memopin.ai/memory/abc123', title = 'Share Memory' }: SystemShareModalProps) {
  if (!isOpen) return null;

  const shareOptions = [
    { id: 'copy', label: 'Copy', icon: '📋' },
    { id: 'messages', label: 'Messages', icon: '💬' },
    { id: 'mail', label: 'Mail', icon: '✉️' },
    { id: 'notes', label: 'Notes', icon: '📝' },
    { id: 'more', label: 'More', icon: '•••' }
  ];

  const handleShare = (optionId: string) => {
    if (optionId === 'copy') {
      // Copy to clipboard
      navigator.clipboard.writeText(shareUrl);
      console.log('Link copied to clipboard');
    } else {
      // In a real app, this would trigger native share functionality
      console.log(`Sharing via ${optionId}:`, shareUrl);
    }
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/40 flex items-end z-[100]">
      <div 
        className="absolute inset-0" 
        onClick={onClose}
      />
      <div className="bg-white w-full rounded-t-[28px] px-5 pt-4 pb-8 relative animate-slide-up">
        {/* Header with URL preview */}
        <div className="flex items-center justify-between mb-6 pb-4 border-b border-black/[0.06]">
          <div className="flex items-center gap-3 flex-1 min-w-0">
            <div className="w-10 h-10 rounded-full bg-[#f2f2f7] flex items-center justify-center flex-shrink-0">
              <span className="text-[18px]">🔗</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[13px] font-semibold text-[#1c1c1e] mb-0.5 truncate">
                {title}
              </p>
              <p className="text-[12px] text-[#8e8e93] truncate">
                {shareUrl}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-[#8e8e93] hover:text-[#1c1c1e] transition-colors ml-3 flex-shrink-0"
          >
            <X className="w-6 h-6" strokeWidth={2} />
          </button>
        </div>

        {/* Share options grid */}
        <div className="mb-6">
          <div className="grid grid-cols-4 gap-4">
            {shareOptions.map((option) => (
              <button
                key={option.id}
                onClick={() => handleShare(option.id)}
                className="flex flex-col items-center gap-2 hover:opacity-70 transition-opacity"
              >
                <div className="w-16 h-16 rounded-[18px] bg-[#f2f2f7] flex items-center justify-center">
                  <span className="text-[28px]">{option.icon}</span>
                </div>
                <span className="text-[12px] text-[#1c1c1e] font-medium">
                  {option.label}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Actions list */}
        <div className="space-y-0 rounded-[14px] overflow-hidden border border-black/[0.06]">
          <button
            onClick={() => handleShare('copy')}
            className="w-full px-4 py-3.5 text-left text-[15px] text-[#1c1c1e] hover:bg-[#f2f2f7] transition-colors bg-white border-b border-black/[0.06] flex items-center gap-3"
          >
            <span className="text-[20px]">📋</span>
            <span>Copy Link</span>
          </button>
          <button
            onClick={onClose}
            className="w-full px-4 py-3.5 text-left text-[15px] text-[#8e8e93] hover:bg-[#f2f2f7] transition-colors bg-white flex items-center gap-3"
          >
            <span className="text-[20px]">❌</span>
            <span>Cancel</span>
          </button>
        </div>
      </div>
    </div>
  );
}