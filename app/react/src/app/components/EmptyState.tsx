import { ReactNode } from 'react';

interface EmptyStateProps {
  icon: ReactNode;
  title: string;
  description: string;
  actionLabel: string;
  onAction: () => void;
}

export function EmptyState({ icon, title, description, actionLabel, onAction }: EmptyStateProps) {
  return (
    <div className="flex-1 flex items-center justify-center p-8">
      <div className="flex flex-col items-center text-center max-w-sm">
        <div className="text-[64px] mb-4">
          {icon}
        </div>
        <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">
          {title}
        </h2>
        <p className="text-[15px] text-[#8e8e93] mb-6 leading-relaxed">
          {description}
        </p>
        <button
          onClick={onAction}
          className="px-6 py-3 bg-[#007aff] text-white text-[17px] font-semibold rounded-[12px] hover:bg-[#0051d5] transition-colors"
        >
          {actionLabel}
        </button>
      </div>
    </div>
  );
}
