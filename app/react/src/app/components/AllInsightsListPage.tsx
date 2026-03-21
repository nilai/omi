import { ChevronLeft, ChevronRight, Moon, BarChart3, Calendar, Brain } from 'lucide-react';
import { EmptyState } from './EmptyState';
import { ErrorState } from './ErrorState';
import { useDevMode } from '../contexts/DevModeContext';

interface AllInsightsListPageProps {
  onBack: () => void;
  onDailyInsightClick: (insight: any) => void;
  onWeeklyInsightClick: (insight: any) => void;
  onMonthlyInsightClick: (insight: any) => void;
  onPatternInsightClick: (insight: any) => void;
  viewedPatternInsightIds?: Set<string>;
}

export function AllInsightsListPage({ onBack, onDailyInsightClick, onWeeklyInsightClick, onMonthlyInsightClick, onPatternInsightClick, viewedPatternInsightIds = new Set() }: AllInsightsListPageProps) {
  const { devMode } = useDevMode();
  // Combined list of daily, weekly, and monthly insights, sorted by creation time (newest first)
  const allInsights = [
    // Pattern Insight - Feb 2 (Most recent)
    {
      type: 'pattern',
      id: 'pattern-feb-2',
      date: 'Feb 2',
      dateSubtitle: 'Cross-memory insight · Emerging pattern',
      title: 'API migration blockers resurfacing across multiple conversations.',
      stats: [
        'Appeared in 4 discussions this week',
        'Issue still unresolved',
        'Ownership remains unclear'
      ]
    },
    // Monthly - Jan 31
    {
      type: 'monthly',
      id: 'monthly-jan-31',
      date: 'Jan 31',
      dateSubtitle: 'January 2026',
      summary: 'Execution momentum improved compared to December, but several strategic decisions continued to stall progress. Hiring capacity, API ownership, and pricing direction resurfaced throughout the month.',
      customStats: [
        'Focus concentrated on product & delivery',
        '3 long-running threads still unresolved',
        'Momentum improving, but decisions lagging'
      ]
    },
    // Daily - Jan 28
    {
      type: 'daily',
      id: 'daily-jan-28',
      date: 'Jan 28',
      dateSubtitle: 'End-of-day reflection',
      summary: 'You spent most of today thinking about product direction and execution trade-offs, with several follow-ups emerging around API migration and team bandwidth.',
      decisionsCount: 2,
      followUpsCount: 3,
      risksCount: 1
    },
    // Daily - Jan 27
    {
      type: 'daily',
      id: 'daily-jan-27',
      date: 'Jan 27',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Your focus shifted between client meetings and internal planning. Key themes included resource allocation and Q1 priorities alignment.',
      decisionsCount: 1,
      followUpsCount: 2,
      risksCount: 0
    },
    // Weekly - Jan 25
    {
      type: 'weekly',
      id: 'weekly-jan-25',
      date: 'Jan 25',
      dateSubtitle: 'Week of Jan 19-25',
      summary: 'A productive week with strong momentum on the product roadmap. You balanced strategic planning with hands-on execution, completing 8 major tasks while identifying 3 key priorities for next week.',
      completedCount: 8,
      pendingCount: 5,
      recommendationsCount: 3
    },
    // Daily - Jan 21
    {
      type: 'daily',
      id: 'daily-jan-21',
      date: 'Jan 21',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Deep work day with minimal meetings. Made progress on technical architecture decisions and documentation for the new authentication flow.',
      decisionsCount: 3,
      followUpsCount: 1,
      risksCount: 2
    },
    // Daily - Jan 20
    {
      type: 'daily',
      id: 'daily-jan-20',
      date: 'Jan 20',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Collaborative day with design team on user experience improvements. Several open questions remain about mobile navigation patterns.',
      decisionsCount: 1,
      followUpsCount: 4,
      risksCount: 1
    },
    // Weekly - Jan 18
    {
      type: 'weekly',
      id: 'weekly-jan-18',
      date: 'Jan 18',
      dateSubtitle: 'Week of Jan 12-18',
      summary: 'Intense week focused on sprint delivery. The team shipped 2 major features while managing technical debt. Need to balance velocity with code quality going forward.',
      completedCount: 12,
      pendingCount: 3,
      recommendationsCount: 2
    },
    // Daily - Jan 18
    {
      type: 'daily',
      id: 'daily-jan-18',
      date: 'Jan 18',
      dateSubtitle: 'End-of-day reflection',
      summary: 'Quiet Saturday spent reviewing documentation and catching up on industry trends. Some interesting ideas emerged for future features.',
      decisionsCount: 0,
      followUpsCount: 1,
      risksCount: 0
    }
  ];

  // Handle Empty State
  if (devMode === 'empty') {
    return (
      <div className="flex flex-col h-full bg-white">
        <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06] relative">
          <button
            onClick={onBack}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-6 h-6" strokeWidth={2} />
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            AI Insights
          </h1>
          <div className="w-6" />
        </div>
        <EmptyState
          icon={<BarChart3 className="w-16 h-16 text-[#007aff]" strokeWidth={1.5} />}
          title="No insights yet"
          description="Record more memories and AI will generate insights for you."
          actionLabel="Start Recording"
          onAction={() => {
            onBack();
            console.log('Start recording clicked');
          }}
        />
      </div>
    );
  }

  // Handle Error State
  if (devMode === 'error') {
    return (
      <div className="flex flex-col h-full bg-white">
        <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06] relative">
          <button
            onClick={onBack}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-6 h-6" strokeWidth={2} />
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            AI Insights
          </h1>
          <div className="w-6" />
        </div>
        <ErrorState
          title="Unable to load insights"
          description="Please try again later."
          onRetry={() => {
            console.log('Retry clicked');
          }}
        />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full bg-white">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between border-b border-black/[0.06] relative">
        <button
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-6 h-6" strokeWidth={2} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          AI Insights
        </h1>
        <div className="w-6" />
      </div>

      {/* Insights List */}
      <div className="flex-1 overflow-y-auto bg-[#f2f2f7] px-5 pt-5 pb-20">
        <div className="space-y-3">
          {allInsights.map((insight, index) => {
            const isDaily = insight.type === 'daily';
            const isWeekly = insight.type === 'weekly';
            const isMonthly = insight.type === 'monthly';
            const isPattern = insight.type === 'pattern';
            const isUnreadPattern = isPattern && !viewedPatternInsightIds.has(insight.id);
            
            return (
              <div key={insight.id} className="relative">
                {/* Left indicator bar for new pattern insights */}
                {isUnreadPattern && (
                  <div className="absolute left-0 top-0 bottom-0 w-1 bg-[#ff9800] rounded-l-[16px] z-10" />
                )}
                
                <button
                  onClick={() => isDaily ? onDailyInsightClick(insight) : isWeekly ? onWeeklyInsightClick(insight) : isMonthly ? onMonthlyInsightClick(insight) : onPatternInsightClick(insight)}
                  className={`w-full rounded-[16px] p-4 text-left transition-all hover:scale-[1.01] active:scale-[0.99] border group ${
                    isDaily
                      ? 'bg-gradient-to-br from-[#f5f3ff] to-[#ede9fe] shadow-[0_2px_8px_rgba(124,58,237,0.12)] border-[#e9d5ff]/50'
                      : isWeekly
                        ? 'bg-gradient-to-br from-[#fff7ed] to-[#fed7aa] shadow-[0_2px_8px_rgba(251,146,60,0.15)] border-[#fdba74]/50'
                        : isMonthly
                          ? 'bg-gradient-to-br from-[#f0f9ff] to-[#e0f7fa] shadow-[0_2px_8px_rgba(3,169,244,0.15)] border-[#4fc3f7]/50'
                          : 'bg-gradient-to-br from-[#fff3e0] to-[#ffe082] shadow-[0_2px_8px_rgba(255,152,0,0.15)] border-[#ff9800]/50'
                  }`}
                >
                  {/* Header */}
                  <div className="flex items-start gap-2 mb-3">
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${
                      isDaily
                        ? 'bg-gradient-to-br from-[#7c3aed] to-[#9333ea]'
                        : isWeekly
                          ? 'bg-gradient-to-br from-[#ea580c] to-[#fb923c]'
                          : isMonthly
                            ? 'bg-gradient-to-br from-[#03a9f4] to-[#4fc3f7]'
                            : 'bg-gradient-to-br from-[#ff9800] to-[#ffb74d]'
                    }`}>
                      {isDaily ? (
                        <Moon className="w-4 h-4 text-white" strokeWidth={2.5} />
                      ) : isWeekly ? (
                        <BarChart3 className="w-4 h-4 text-white" strokeWidth={2.5} />
                      ) : isMonthly ? (
                        <Calendar className="w-4 h-4 text-white" strokeWidth={2.5} />
                      ) : (
                        <Brain className="w-4 h-4 text-white" strokeWidth={2.5} />
                      )}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="text-[15px] font-semibold text-[#1c1c1e]">
                          {insight.date}
                        </h3>
                        <span className="text-[13px] text-[#8e8e93]">·</span>
                        <span className="text-[13px] text-[#8e8e93]">
                          {isDaily ? 'Daily' : isWeekly ? 'Weekly' : isMonthly ? 'Monthly' : 'Pattern'}
                        </span>
                      </div>
                      <p className="text-[13px] text-[#8e8e93]">
                        {insight.dateSubtitle} · {isDaily ? '11:00 PM' : '10:00 AM'}
                      </p>
                    </div>
                    <ChevronRight className={`w-5 h-5 opacity-60 group-hover:opacity-100 group-hover:translate-x-0.5 transition-all ${
                      isDaily ? 'text-[#7c3aed]' : isWeekly ? 'text-[#ea580c]' : isMonthly ? 'text-[#03a9f4]' : 'text-[#ff9800]'
                    }`} strokeWidth={2.5} />
                  </div>

                  {/* Summary text */}
                  <p className="text-[14px] text-[#3c3c43] leading-[1.4] mb-3">
                    {isPattern ? (insight as any).title : insight.summary}
                  </p>

                  {/* Stats */}
                  {isDaily ? (
                    <div className="space-y-1.5">
                      <div className="flex items-center gap-2 text-[13px]">
                        <span className="text-[#7c3aed]">•</span>
                        <span className="text-[#3c3c43]">
                          {(insight as any).decisionsCount} decision{(insight as any).decisionsCount !== 1 ? 's' : ''} made
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-[13px]">
                        <span className="text-[#7c3aed]">•</span>
                        <span className="text-[#3c3c43]">
                          {(insight as any).followUpsCount} follow-up{(insight as any).followUpsCount !== 1 ? 's' : ''} pending
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-[13px]">
                        <span className="text-[#7c3aed]">•</span>
                        <span className="text-[#3c3c43]">
                          {(insight as any).risksCount} risk{(insight as any).risksCount !== 1 ? 's' : ''} to watch
                        </span>
                      </div>
                    </div>
                  ) : isWeekly ? (
                    <div className="space-y-1.5">
                      <div className="flex items-center gap-2 text-[13px]">
                        <span className="text-[#ea580c]">•</span>
                        <span className="text-[#3c3c43]">
                          {(insight as any).completedCount} task{(insight as any).completedCount !== 1 ? 's' : ''} completed
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-[13px]">
                        <span className="text-[#ea580c]">•</span>
                        <span className="text-[#3c3c43]">
                          {(insight as any).pendingCount} pending for next week
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-[13px]">
                        <span className="text-[#ea580c]">•</span>
                        <span className="text-[#3c3c43]">
                          {(insight as any).recommendationsCount} recommendation{(insight as any).recommendationsCount !== 1 ? 's' : ''}
                        </span>
                      </div>
                    </div>
                  ) : isMonthly ? (
                    <div className="space-y-1.5">
                      {(insight as any).customStats?.map((stat: string, index: number) => (
                        <div key={index} className="flex items-center gap-2 text-[13px]">
                          <span className="text-[#03a9f4]">•</span>
                          <span className="text-[#3c3c43]">
                            {stat}
                          </span>
                        </div>
                      ))}
                    </div>
                  ) : isPattern ? (
                    <div className="space-y-1.5">
                      {(insight as any).stats?.map((stat: string, index: number) => (
                        <div key={index} className="flex items-center gap-2 text-[13px]">
                          <span className="text-[#ff9800]">•</span>
                          <span className="text-[#3c3c43]">
                            {stat}
                          </span>
                        </div>
                      ))}
                    </div>
                  ) : null}
                </button>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}