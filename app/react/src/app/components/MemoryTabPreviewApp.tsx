import { MemoryTabPreview } from './MemoryTabPreview';

export default function MemoryTabPreviewApp() {
  return (
    <div className="fixed inset-0 bg-[#f2f2f7]">
      <MemoryTabPreview />
      
      {/* Preview label */}
      <div className="fixed bottom-4 left-1/2 -translate-x-1/2 bg-[#007aff] text-white px-4 py-2 rounded-full text-[13px] font-medium shadow-lg z-50">
        📱 Memory Tab Preview - New Design Concept
      </div>
    </div>
  );
}
