import { ChevronRight } from 'lucide-react';

interface DailyInsightCardProps {
  insight: {
    id: number;
    date: string;
    dateSubtitle: string;
    summary: string;
    decisionsCount: number;
    followUpsCount: number;
    risksCount: number;
  };
  onClick: () => void;
}

export function DailyInsightCard({ insight, onClick }: DailyInsightCardProps) {
  return (
    <button
      onClick={onClick}
      className="w-full bg-gradient-to-br from-[#f5f3ff] to-[#ede9fe] rounded-[16px] p-4 text-left transition-all hover:shadow-md border border-[#e9d5ff]/40 group"
    >
      {/* Header */}
      <div className="flex items-start gap-2 mb-3">
        <span className="text-[18px] leading-none">🌙</span>
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-[15px] font-semibold text-[#1c1c1e]">
              Daily Insights
            </h3>
            <span className="text-[13px] text-[#8e8e93]">·</span>
            <span className="text-[13px] text-[#8e8e93]">Today</span>
          </div>
          <p className="text-[13px] text-[#8e8e93]">
            {insight.dateSubtitle} · 11:00 PM
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
          <span className="text-[#7c3aed]">•</span>
          <span className="text-[#3c3c43]">
            {insight.decisionsCount} decision{insight.decisionsCount !== 1 ? 's' : ''} made
          </span>
        </div>
        <div className="flex items-center gap-2 text-[13px]">
          <span className="text-[#7c3aed]">•</span>
          <span className="text-[#3c3c43]">
            {insight.followUpsCount} follow-up{insight.followUpsCount !== 1 ? 's' : ''} pending
          </span>
        </div>
        <div className="flex items-center gap-2 text-[13px]">
          <span className="text-[#7c3aed]">•</span>
          <span className="text-[#3c3c43]">
            {insight.risksCount} risk{insight.risksCount !== 1 ? 's' : ''} to watch
          </span>
        </div>
      </div>

      {/* View link */}
      <div className="flex items-center gap-1 text-[#7c3aed] group-hover:gap-2 transition-all">
        <span className="text-[14px] font-medium">View daily insights</span>
        <ChevronRight className="w-4 h-4" strokeWidth={2.5} />
      </div>
    </button>
  );
}