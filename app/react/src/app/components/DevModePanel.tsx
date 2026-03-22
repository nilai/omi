import { X, Code2 } from 'lucide-react';
import { useDevMode } from '../contexts/DevModeContext';

interface DevModePanelProps {
  onClose: () => void;
}

export function DevModePanel({ onClose }: DevModePanelProps) {
  const { devMode, setDevMode } = useDevMode();

  return (
    <div 
      className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" 
      onClick={onClose}
    >
      <div 
        className="bg-white rounded-[24px] p-6 w-full max-w-sm shadow-2xl relative" 
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
        >
          <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
        </button>

        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#5ac8fa] to-[#007aff] flex items-center justify-center mb-4">
            <Code2 className="w-8 h-8 text-white" strokeWidth={2} />
          </div>
          <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">Developer Mode</h3>
          <p className="text-[14px] text-[#8e8e93]">
            Switch between normal, empty, and error states for development and testing
          </p>
        </div>

        <div className="space-y-2 mb-6">
          {/* Normal State */}
          <button
            onClick={() => {
              setDevMode('normal');
              onClose();
            }}
            className={`w-full p-4 rounded-[16px] text-left transition-all border-2 ${
              devMode === 'normal'
                ? 'bg-[#007aff]/10 border-[#007aff]'
                : 'bg-[#f2f2f7] border-transparent hover:bg-[#e5e5ea]'
            }`}
          >
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">Normal Mode</h4>
                <p className="text-[13px] text-[#8e8e93]">Show all demo data</p>
              </div>
              {devMode === 'normal' && (
                <div className="w-6 h-6 rounded-full bg-[#007aff] flex items-center justify-center">
                  <div className="w-2.5 h-2.5 rounded-full bg-white"></div>
                </div>
              )}
            </div>
          </button>

          {/* Empty State */}
          <button
            onClick={() => {
              setDevMode('empty');
              onClose();
            }}
            className={`w-full p-4 rounded-[16px] text-left transition-all border-2 ${
              devMode === 'empty'
                ? 'bg-[#ff9500]/10 border-[#ff9500]'
                : 'bg-[#f2f2f7] border-transparent hover:bg-[#e5e5ea]'
            }`}
          >
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">Empty State</h4>
                <p className="text-[13px] text-[#8e8e93]">Show empty state for all pages</p>
              </div>
              {devMode === 'empty' && (
                <div className="w-6 h-6 rounded-full bg-[#ff9500] flex items-center justify-center">
                  <div className="w-2.5 h-2.5 rounded-full bg-white"></div>
                </div>
              )}
            </div>
          </button>

          {/* Error State */}
          <button
            onClick={() => {
              setDevMode('error');
              onClose();
            }}
            className={`w-full p-4 rounded-[16px] text-left transition-all border-2 ${
              devMode === 'error'
                ? 'bg-[#ff3b30]/10 border-[#ff3b30]'
                : 'bg-[#f2f2f7] border-transparent hover:bg-[#e5e5ea]'
            }`}
          >
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">Error State</h4>
                <p className="text-[13px] text-[#8e8e93]">Show error state for all pages</p>
              </div>
              {devMode === 'error' && (
                <div className="w-6 h-6 rounded-full bg-[#ff3b30] flex items-center justify-center">
                  <div className="w-2.5 h-2.5 rounded-full bg-white"></div>
                </div>
              )}
            </div>
          </button>
        </div>

        <div className="pt-4 border-t border-black/[0.06]">
          <p className="text-[12px] text-[#8e8e93] text-center">
            Current mode: <span className="font-semibold text-[#1c1c1e]">{devMode}</span>
          </p>
        </div>
      </div>
    </div>
  );
}
