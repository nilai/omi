import { AlertTriangle } from 'lucide-react';

interface ErrorStateProps {
  title: string;
  description: string;
  onRetry: () => void;
}

export function ErrorState({ title, description, onRetry }: ErrorStateProps) {
  return (
    <div className="flex-1 flex items-center justify-center p-8">
      <div className="flex flex-col items-center text-center max-w-sm">
        <div className="w-20 h-20 rounded-full bg-[#ff3b30]/10 flex items-center justify-center mb-4">
          <AlertTriangle className="w-10 h-10 text-[#ff3b30]" strokeWidth={2} />
        </div>
        <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">
          {title}
        </h2>
        <p className="text-[15px] text-[#8e8e93] mb-6 leading-relaxed">
          {description}
        </p>
        <button
          onClick={onRetry}
          className="px-6 py-3 bg-[#007aff] text-white text-[17px] font-semibold rounded-[12px] hover:bg-[#0051d5] transition-colors"
        >
          Retry
        </button>
      </div>
    </div>
  );
}
