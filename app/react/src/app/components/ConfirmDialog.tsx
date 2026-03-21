interface ConfirmDialogProps {
  isOpen?: boolean;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  discardText?: string;
  onConfirm: () => void;
  onCancel: () => void;
  onDiscard?: () => void;
}

export function ConfirmDialog({
  isOpen = true,
  title,
  message,
  confirmText = 'Save',
  cancelText = "Don't Save",
  discardText,
  onConfirm,
  onCancel,
  onDiscard,
}: ConfirmDialogProps) {
  if (!isOpen) return null;

  // Three-button layout when onDiscard is provided
  const hasThreeButtons = !!onDiscard;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onCancel} />
      
      {/* Dialog - iOS Alert Style */}
      <div className="relative w-full max-w-[320px] bg-white/95 backdrop-blur-2xl rounded-[16px] shadow-2xl overflow-hidden">
        {/* Content */}
        <div className="px-5 pt-4 pb-3.5 text-center">
          <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">
            {title}
          </h3>
          <p className="text-[13px] text-[#1c1c1e]/70 leading-[1.35]">
            {message}
          </p>
        </div>
        
        {/* Buttons */}
        {hasThreeButtons ? (
          // Three buttons - Vertical Stack
          <div className="flex flex-col border-t border-black/[0.15]">
            <button
              onClick={onDiscard}
              className="py-2.5 text-[17px] font-medium text-[#ff3b30] hover:bg-black/[0.04] active:bg-black/[0.08] transition-colors border-b border-black/[0.15]"
            >
              {discardText || 'Discard'}
            </button>
            <button
              onClick={onConfirm}
              className="py-2.5 text-[17px] font-semibold text-[#007aff] hover:bg-black/[0.04] active:bg-black/[0.08] transition-colors border-b border-black/[0.15]"
            >
              {confirmText}
            </button>
            <button
              onClick={onCancel}
              className="py-2.5 text-[17px] font-medium text-[#007aff] hover:bg-black/[0.04] active:bg-black/[0.08] transition-colors"
            >
              Cancel
            </button>
          </div>
        ) : (
          // Two buttons - Horizontal Layout
          <div className="flex border-t border-black/[0.15]">
            <button
              onClick={onCancel}
              className="flex-1 py-2.5 text-[17px] font-medium text-[#007aff] hover:bg-black/[0.04] active:bg-black/[0.08] transition-colors border-r border-black/[0.15]"
            >
              {cancelText}
            </button>
            <button
              onClick={onConfirm}
              className="flex-1 py-2.5 text-[17px] font-semibold text-[#007aff] hover:bg-black/[0.04] active:bg-black/[0.08] transition-colors"
            >
              {confirmText}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}