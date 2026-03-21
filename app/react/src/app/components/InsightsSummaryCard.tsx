import { Sparkles } from 'lucide-react';

interface InsightsSummaryCardProps {
  onClick: () => void;
  unreadCount?: number;
}

export function InsightsSummaryCard({ onClick, unreadCount = 0 }: InsightsSummaryCardProps) {
  return (
    <button
      onClick={onClick}
      className="w-full bg-gradient-to-br from-[#faf9fc] via-[#fcfbfd] to-white rounded-[20px] p-6 text-left transition-all hover:shadow-md border border-black/[0.04] relative shadow-[0_2px_8px_rgba(0,0,0,0.04),0_1px_2px_rgba(0,0,0,0.02)] hover:opacity-90"
    >
      {/* Unread badge */}
      {unreadCount > 0 && (
        <div className="absolute top-4 right-4 w-5 h-5 rounded-full bg-[#f59e0b] flex items-center justify-center">
          <span className="text-[11px] font-semibold text-white">{unreadCount}</span>
        </div>
      )}
      
      {/* Header */}
      <div className="flex items-start gap-2 mb-3">
        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#a855f7] to-[#c084fc] flex items-center justify-center shrink-0">
          <Sparkles className="w-4 h-4 text-white" strokeWidth={2.5} />
        </div>
        <div className="flex-1">
          <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">
            Insights
          </h3>
          <p className="text-[13px] text-[#8e8e93]">
            AI insights & summaries over time
          </p>
        </div>
      </div>

      {/* New insight notification */}
      {unreadCount > 0 && (
        <p className="text-[15px] text-[#3c3c43]">
          You have {unreadCount} new insight{unreadCount > 1 ? 's' : ''} today
        </p>
      )}
    </button>
  );
}