import { Edit3, Clock, Trash2, X, Folder } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface MemoryOptionsModalProps {
  isOpen: boolean;
  onClose: () => void;
  onEditTitle: () => void;
  onModifyDate: () => void;
  onDelete: () => void;
  showEditTitle?: boolean;
  showModifyDate?: boolean;
  showGenerateResummary?: boolean;
  onGenerateResummary?: () => void;
  projectCount?: number;
  onManageProjects?: () => void;
}

export function MemoryOptionsModal({
  isOpen,
  onClose,
  onEditTitle,
  onModifyDate,
  onDelete,
  showEditTitle = true,
  showModifyDate = true,
  showGenerateResummary = false,
  onGenerateResummary,
  projectCount = 0,
  onManageProjects,
}: MemoryOptionsModalProps) {
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
                  Memory Options
                </h2>
                <p className="text-[15px] text-[#8e8e93]">
                  Manage this memory
                </p>
              </div>

              {/* Options List */}
              <div className="space-y-3 mb-6">
                {/* Manage Projects */}
                {onManageProjects && (
                  <button
                    onClick={() => {
                      onManageProjects();
                      onClose();
                    }}
                    className="w-full bg-white rounded-2xl p-4 flex items-center gap-4 shadow-sm active:opacity-60 transition-opacity"
                  >
                    <div className="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center">
                      <Folder className="w-5 h-5 text-[#34c759]" strokeWidth={2} />
                    </div>
                    <div className="flex-1 text-left">
                      <h3 className="text-[16px] font-semibold text-[#1c1c1e]">
                        Manage Projects {projectCount > 0 && `(${projectCount})`}
                      </h3>
                      <p className="text-[13px] text-[#8e8e93] mt-0.5">Organize this memory into projects</p>
                    </div>
                  </button>
                )}

                {/* Edit Title */}
                {showEditTitle && (
                  <button
                    onClick={() => {
                      onEditTitle();
                      onClose();
                    }}
                    className="w-full bg-white rounded-2xl p-4 flex items-center gap-4 shadow-sm active:opacity-60 transition-opacity"
                  >
                    <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center">
                      <Edit3 className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
                    </div>
                    <div className="flex-1 text-left">
                      <h3 className="text-[16px] font-semibold text-[#1c1c1e]">Edit Title</h3>
                      <p className="text-[13px] text-[#8e8e93] mt-0.5">Change the memory title</p>
                    </div>
                  </button>
                )}

                {/* Modify Date */}
                {showModifyDate && (
                  <button
                    onClick={() => {
                      onModifyDate();
                      onClose();
                    }}
                    className="w-full bg-white rounded-2xl p-4 flex items-center gap-4 shadow-sm active:opacity-60 transition-opacity"
                  >
                    <div className="w-12 h-12 bg-orange-50 rounded-xl flex items-center justify-center">
                      <Clock className="w-5 h-5 text-[#ff9500]" strokeWidth={2} />
                    </div>
                    <div className="flex-1 text-left">
                      <h3 className="text-[16px] font-semibold text-[#1c1c1e]">Modify Date</h3>
                      <p className="text-[13px] text-[#8e8e93] mt-0.5">Change creation time</p>
                    </div>
                  </button>
                )}

                {/* Generate Resummary */}
                {showGenerateResummary && (
                  <button
                    onClick={() => {
                      onGenerateResummary();
                      onClose();
                    }}
                    className="w-full bg-white rounded-2xl p-4 flex items-center gap-4 shadow-sm active:opacity-60 transition-opacity"
                  >
                    <div className="w-12 h-12 bg-purple-50 rounded-xl flex items-center justify-center">
                      <svg className="w-5 h-5 text-[#af52de]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                      </svg>
                    </div>
                    <div className="flex-1 text-left">
                      <h3 className="text-[16px] font-semibold text-[#1c1c1e]">Generate Resummary</h3>
                      <p className="text-[13px] text-[#8e8e93] mt-0.5">Create AI insights</p>
                    </div>
                  </button>
                )}

                {/* Delete */}
                <button
                  onClick={() => {
                    onDelete();
                    onClose();
                  }}
                  className="w-full bg-white rounded-2xl p-4 flex items-center gap-4 shadow-sm active:opacity-60 transition-opacity"
                >
                  <div className="w-12 h-12 bg-red-50 rounded-xl flex items-center justify-center">
                    <Trash2 className="w-5 h-5 text-[#ff3b30]" strokeWidth={2} />
                  </div>
                  <div className="flex-1 text-left">
                    <h3 className="text-[16px] font-semibold text-[#ff3b30]">Delete</h3>
                    <p className="text-[13px] text-[#8e8e93] mt-0.5">Remove this memory</p>
                  </div>
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