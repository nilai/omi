import { Globe, FileText, Image, FileType, Share2, X } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface ShareOptionsModalProps {
  isOpen: boolean;
  onClose: () => void;
  onShare: () => void;
  onCopyLink: () => void;
  onExportImage: () => void;
  onExportPDF: () => void;
  onExportWord: () => void;
  onExportMarkdown: () => void;
}

export function ShareOptionsModal({
  isOpen,
  onClose,
  onShare,
  onCopyLink,
  onExportImage,
  onExportPDF,
  onExportWord,
  onExportMarkdown
}: ShareOptionsModalProps) {
  if (!isOpen) return null;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/40 z-50"
          />

          {/* Bottom Sheet */}
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 30, stiffness: 300 }}
            className="fixed bottom-0 left-0 right-0 bg-[#f2f2f7] rounded-t-3xl z-50 max-h-[85vh] overflow-y-auto"
          >
            {/* Handle */}
            <div className="flex justify-center pt-3 pb-2">
              <div className="w-10 h-1 bg-[#c7c7cc] rounded-full" />
            </div>

            {/* Content */}
            <div className="px-5 pb-8">
              {/* Header */}
              <div className="text-center mb-6 pt-4">
                <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">
                  Share this Memory
                </h2>
                <p className="text-[15px] text-[#8e8e93]">
                  Export or send it in the format you prefer.
                </p>
              </div>

              {/* Export Options Grid */}
              <div className="grid grid-cols-4 gap-4 mb-6">
                {/* Copy Link */}
                <button
                  onClick={() => {
                    onCopyLink();
                    onClose();
                  }}
                  className="flex flex-col items-center gap-2 p-3 active:opacity-60 transition-opacity"
                >
                  <div className="w-14 h-14 bg-white rounded-2xl flex items-center justify-center shadow-sm">
                    <Globe className="w-6 h-6 text-[#007aff]" strokeWidth={2} />
                  </div>
                  <span className="text-[13px] text-[#1c1c1e]">Link</span>
                </button>

                {/* Export as Image */}
                <button
                  onClick={() => {
                    onExportImage();
                    onClose();
                  }}
                  className="flex flex-col items-center gap-2 p-3 active:opacity-60 transition-opacity"
                >
                  <div className="w-14 h-14 bg-white rounded-2xl flex items-center justify-center shadow-sm">
                    <Image className="w-6 h-6 text-[#007aff]" strokeWidth={2} />
                  </div>
                  <span className="text-[13px] text-[#1c1c1e]">Image</span>
                </button>

                {/* Export as PDF */}
                <button
                  onClick={() => {
                    onExportPDF();
                    onClose();
                  }}
                  className="flex flex-col items-center gap-2 p-3 active:opacity-60 transition-opacity"
                >
                  <div className="w-14 h-14 bg-white rounded-2xl flex items-center justify-center shadow-sm">
                    <FileType className="w-6 h-6 text-[#007aff]" strokeWidth={2} />
                  </div>
                  <span className="text-[13px] text-[#1c1c1e]">PDF</span>
                </button>

                {/* Export as Word */}
                <button
                  onClick={() => {
                    onExportWord();
                    onClose();
                  }}
                  className="flex flex-col items-center gap-2 p-3 active:opacity-60 transition-opacity"
                >
                  <div className="w-14 h-14 bg-white rounded-2xl flex items-center justify-center shadow-sm">
                    <FileText className="w-6 h-6 text-[#007aff]" strokeWidth={2} />
                  </div>
                  <span className="text-[13px] text-[#1c1c1e]">Word</span>
                </button>

                {/* Export as Markdown */}
                <button
                  onClick={() => {
                    onExportMarkdown();
                    onClose();
                  }}
                  className="flex flex-col items-center gap-2 p-3 active:opacity-60 transition-opacity"
                >
                  <div className="w-14 h-14 bg-white rounded-2xl flex items-center justify-center shadow-sm">
                    <FileText className="w-6 h-6 text-[#34c759]" strokeWidth={2} />
                  </div>
                  <span className="text-[13px] text-[#1c1c1e]">Markdown</span>
                </button>

                {/* System Share */}
                <button
                  onClick={() => {
                    onShare();
                    onClose();
                  }}
                  className="flex flex-col items-center gap-2 p-3 active:opacity-60 transition-opacity"
                >
                  <div className="w-14 h-14 bg-white rounded-2xl flex items-center justify-center shadow-sm">
                    <Share2 className="w-6 h-6 text-[#007aff]" strokeWidth={2} />
                  </div>
                  <span className="text-[13px] text-[#1c1c1e]">Share</span>
                </button>
              </div>

              {/* Cancel Button */}
              <button
                onClick={onClose}
                className="w-full bg-white text-[#007aff] text-[17px] font-semibold py-3.5 rounded-xl shadow-sm active:opacity-60 transition-opacity"
              >
                Cancel
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}