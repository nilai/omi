import { X } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { useState } from 'react';

interface CreateProjectModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCreate: (name: string) => void;
}

export function CreateProjectModal({
  isOpen,
  onClose,
  onCreate,
}: CreateProjectModalProps) {
  const [projectName, setProjectName] = useState('');

  const handleCreate = () => {
    if (projectName.trim()) {
      onCreate(projectName.trim());
      setProjectName('');
      onClose();
    }
  };

  const handleClose = () => {
    setProjectName('');
    onClose();
  };

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
            onClick={handleClose}
            className="fixed inset-0 bg-black/40 z-[60]"
          />

          {/* Modal */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed inset-x-4 top-1/2 -translate-y-1/2 bg-white rounded-3xl z-[60] max-w-md mx-auto shadow-2xl"
          >
            {/* Header */}
            <div className="flex items-center justify-between px-5 pt-5 pb-4 border-b border-gray-100">
              <h2 className="text-[20px] font-semibold text-[#1c1c1e]">
                Create Project
              </h2>
              <button
                onClick={handleClose}
                className="w-8 h-8 flex items-center justify-center rounded-full bg-gray-100 active:opacity-60 transition-opacity"
              >
                <X className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2.5} />
              </button>
            </div>

            {/* Content */}
            <div className="px-5 py-6">
              <label className="block mb-2">
                <span className="text-[15px] font-medium text-[#1c1c1e]">
                  Name
                </span>
              </label>
              <input
                type="text"
                value={projectName}
                onChange={(e) => setProjectName(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && projectName.trim()) {
                    handleCreate();
                  }
                }}
                placeholder="Enter project name"
                autoFocus
                className="w-full px-4 py-3 text-[17px] text-[#1c1c1e] bg-[#f2f2f7] border border-transparent rounded-xl focus:outline-none focus:border-[#007aff] transition-colors"
              />
            </div>

            {/* Divider */}
            <div className="border-t border-gray-100" />

            {/* Footer Buttons */}
            <div className="flex gap-3 px-5 py-4">
              <button
                onClick={handleClose}
                className="flex-1 py-3 rounded-xl bg-gray-100 text-[#1c1c1e] text-[17px] font-semibold active:opacity-60 transition-opacity"
              >
                Cancel
              </button>
              <button
                onClick={handleCreate}
                disabled={!projectName.trim()}
                className={`flex-1 py-3 rounded-xl text-white text-[17px] font-semibold transition-all ${
                  projectName.trim()
                    ? 'bg-[#007aff] active:opacity-60'
                    : 'bg-[#007aff]/40 cursor-not-allowed'
                }`}
              >
                Create
              </button>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}