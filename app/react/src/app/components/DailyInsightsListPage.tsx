import { ChevronLeft, ChevronRight } from 'lucide-react';
import { DailyInsightCard } from './DailyInsightCard';

interface DailyInsightsListPageProps {
  onBack: () => void;
  onInsightClick: (insight: any) => void;
}

export function DailyInsightsListPage({ onBack, onInsightClick }: DailyInsightsListPageProps) {
  // 6 days of Daily Insights
  const insights = [
    {
      id: 'daily-jan-28',
      date: 'Jan 28',
      dateSubtitle: 'End-of-day reflection',
      summary: 'You spent most of today thinking about product direction and execution trade-offs, with several follow-ups emerging around API migration and team bandwidth.',
      decisionsCount: 2,
      followUpsCount: 3,
      risksCount: 1
    },
    {
      id: 'daily-jan-27',
      date: 'Jan 27',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Your focus shifted between client meetings and internal planning. Key themes included resource allocation and Q1 priorities alignment.',
      decisionsCount: 1,
      followUpsCount: 2,
      risksCount: 0
    },
    {
      id: 'daily-jan-21',
      date: 'Jan 21',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Deep work day with minimal meetings. Made progress on technical architecture decisions and documentation for the new authentication flow.',
      decisionsCount: 3,
      followUpsCount: 1,
      risksCount: 2
    },
    {
      id: 'daily-jan-20',
      date: 'Jan 20',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Collaborative day with design team on user experience improvements. Several open questions remain about mobile navigation patterns.',
      decisionsCount: 1,
      followUpsCount: 4,
      risksCount: 1
    },
    {
      id: 'daily-jan-19',
      date: 'Jan 19',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Weekly planning and retrospective with the team. Identified blockers in deployment pipeline that need immediate attention.',
      decisionsCount: 2,
      followUpsCount: 2,
      risksCount: 3
    },
    {
      id: 'daily-jan-18',
      date: 'Jan 18',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Quiet Saturday spent reviewing documentation and catching up on industry trends. Some interesting ideas emerged for future features.',
      decisionsCount: 0,
      followUpsCount: 1,
      risksCount: 0
    }
  ];

  return (
    <div className="flex flex-col h-full bg-white">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center gap-3 border-b border-black/[0.06]">
        <button
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-6 h-6" strokeWidth={2} />
        </button>
        <h1 className="text-[17px] font-semibold">Daily Insights</h1>
      </div>

      {/* Insights List */}
      <div className="flex-1 overflow-y-auto bg-[#f2f2f7] px-5 pt-5 pb-20">
        <div className="space-y-3">
          {insights.map((insight, index) => {
            // Alternate between different visual styles for better distinction
            const isEven = index % 2 === 1;
            
            return (
              <button
                key={insight.id}
                onClick={() => onInsightClick(insight)}
                className={`w-full rounded-[16px] p-4 text-left transition-all hover:scale-[1.01] active:scale-[0.99] border group ${
                  isEven
                    ? 'bg-gradient-to-br from-[#f8f6ff] to-[#f0edff] shadow-[0_2px_8px_rgba(124,58,237,0.12)] border-[#e9d5ff]/50'
                    : 'bg-gradient-to-br from-[#fafaf9] to-[#f5f3ff] shadow-[0_1px_4px_rgba(0,0,0,0.08)] border-[#e9d5ff]/30'
                }`}
              >
                {/* Header */}
                <div className="flex items-start gap-2 mb-3">
                  <span className="text-[18px] leading-none">🌙</span>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="text-[15px] font-semibold text-[#1c1c1e]">
                        {insight.date}
                      </h3>
                    </div>
                    <p className="text-[13px] text-[#8e8e93]">
                      {insight.dateSubtitle} · 11:00 PM
                    </p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#7c3aed] opacity-60 group-hover:opacity-100 group-hover:translate-x-0.5 transition-all" strokeWidth={2.5} />
                </div>

                {/* Summary text */}
                <p className="text-[14px] text-[#3c3c43] leading-[1.4] mb-3">
                  {insight.summary}
                </p>

                {/* Stats */}
                <div className="space-y-1.5">
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
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}