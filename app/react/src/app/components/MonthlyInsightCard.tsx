import { ChevronRight } from 'lucide-react';

interface MonthlyInsightCardProps {
  insight: {
    id: string;
    date: string;
    dateSubtitle: string;
    summary: string;
    topicsCount: number;
    openThreadsCount: number;
    decisionsCount: number;
  };
  onClick: () => void;
}

export function MonthlyInsightCard({ insight, onClick }: MonthlyInsightCardProps) {
  return (
    <button
      onClick={onClick}
      className="w-full bg-gradient-to-br from-[#fef3c7] to-[#fde68a] rounded-[16px] p-4 text-left transition-all hover:shadow-md border border-[#fbbf24]/40 group"
    >
      {/* Header */}
      <div className="flex items-start gap-2 mb-3">
        <span className="text-[18px] leading-none">🧭</span>
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-[15px] font-semibold text-[#1c1c1e]">
              Monthly Insight
            </h3>
            <span className="text-[13px] text-[#8e8e93]">·</span>
            <span className="text-[13px] text-[#8e8e93]">{insight.date}</span>
          </div>
          <p className="text-[13px] text-[#8e8e93]">
            {insight.dateSubtitle} · 10:00 AM
          </p>
        </div>
      </div>

      {/* Summary text */}
      <p className="text-[14px] text-[#3c3c43] leading-[1.4] mb-3">
        {insight.summary}
      </p>

      {/* Stats */}
      <div className="space-y-1.5 mb-3">
        <div className="flex items-center gap-2 text-[13px]">
          <span className="text-[#d97706]">•</span>
          <span className="text-[#3c3c43]">
            {insight.topicsCount} recurring topic{insight.topicsCount !== 1 ? 's' : ''}
          </span>
        </div>
        <div className="flex items-center gap-2 text-[13px]">
          <span className="text-[#d97706]">•</span>
          <span className="text-[#3c3c43]">
            {insight.openThreadsCount} open thread{insight.openThreadsCount !== 1 ? 's' : ''}
          </span>
        </div>
        <div className="flex items-center gap-2 text-[13px]">
          <span className="text-[#d97706]">•</span>
          <span className="text-[#3c3c43]">
            {insight.decisionsCount} critical decision{insight.decisionsCount !== 1 ? 's' : ''}
          </span>
        </div>
      </div>

      {/* View link */}
      <div className="flex items-center gap-1 text-[#d97706] group-hover:gap-2 transition-all">
        <span className="text-[14px] font-medium">View monthly insight</span>
        <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
      </div>
    </button>
  );
}
