import { ChevronLeft, Sparkles, Check } from 'lucide-react';

interface ExpertDetailPageProps {
  expertId: string;
  expertName: string;
  enabled: boolean;
  onBack: () => void;
  onToggle: () => void;
}

const expertData: Record<string, {
  title: string;
  focus: string[];
  bestFor: string[];
  examples: string[];
}> = {
  business: {
    title: 'Business Lens',
    focus: [
      'Strategic direction',
      'Decision impact',
      'Priority alignment',
      'Resource trade-offs'
    ],
    bestFor: [
      'Founder decisions',
      'Product planning',
      'Business trade-offs',
      'Roadmap discussions'
    ],
    examples: [
      'This decision reduces short-term risk but slows expansion.',
      'Pricing uncertainty appears in multiple recent discussions.',
      'Team capacity conflicts with roadmap.'
    ]
  },
  creative: {
    title: 'Creative Lens',
    focus: [
      'Emerging ideas',
      'Concept connections',
      'Exploration directions',
      'Opportunity signals'
    ],
    bestFor: [
      'Brainstorming sessions',
      'Product ideation',
      'Innovation discussions',
      'Early-stage concepts'
    ],
    examples: [
      'Several conversations hint at onboarding simplification opportunities.',
      'Gamification appears as a recurring idea.',
      'Users repeatedly struggle with setup.'
    ]
  },
  execution: {
    title: 'Execution Lens',
    focus: [
      'Delivery progress',
      'Dependencies & blockers',
      'Execution risks',
      'Operational friction'
    ],
    bestFor: [
      'Project updates',
      'Delivery reviews',
      'Cross-team coordination',
      'Launch preparation'
    ],
    examples: [
      'Authentication dependency blocks rollout.',
      'Delivery delays tied to cross-team coordination.',
      'Execution timeline repeatedly slips.'
    ]
  },
  wellness: {
    title: 'Wellness Lens',
    focus: [
      'Energy patterns',
      'Stress signals',
      'Workload sustainability',
      'Burnout risks'
    ],
    bestFor: [
      'Founder workload balance',
      'Long-term productivity',
      'Team pressure detection',
      'Preventing overload'
    ],
    examples: [
      'Repeated concern about team overload.',
      'Late-night meetings increased recently.',
      'Delivery pressure appears frequently.'
    ]
  }
};

export function ExpertDetailPage({ expertId, expertName, enabled, onBack, onToggle }: ExpertDetailPageProps) {
  const data = expertData[expertId];

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] z-50 flex flex-col">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
        <button 
          onClick={onBack}
          className="text-[#7c3aed] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-7 h-7" strokeWidth={2} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          {expertName}
        </h1>
        <div className="w-7" />
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto pb-5">
        {/* Main Title */}
        <div className="px-5 pt-4 pb-4">
          <h2 className="text-[20px] font-bold text-[#1c1c1e] leading-[1.3]">
            How this expert analyzes your memories.
          </h2>
        </div>

        {/* Focus Section */}
        <div className="px-5 pb-3">
          <div className="bg-white rounded-xl p-4 border border-black/[0.06]">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2.5">
              Focus
            </h3>
            <div className="space-y-1.5">
              {data.focus.map((item, index) => (
                <div key={index} className="flex items-start gap-2">
                  <span className="text-[14px] text-[#6c6c70] mt-0.5">•</span>
                  <span className="text-[14px] text-[#1c1c1e] leading-[1.4]">{item}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Best for Section */}
        <div className="px-5 pb-3">
          <div className="bg-white rounded-xl p-4 border border-black/[0.06]">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2.5">
              Best for
            </h3>
            <div className="space-y-1.5">
              {data.bestFor.map((item, index) => (
                <div key={index} className="flex items-start gap-2">
                  <span className="text-[14px] text-[#6c6c70] mt-0.5">•</span>
                  <span className="text-[14px] text-[#1c1c1e] leading-[1.4]">{item}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Example insights Section */}
        <div className="px-5 pb-3">
          <div className="bg-white rounded-xl p-4 border border-black/[0.06]">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2.5">
              Example insights
            </h3>
            <div className="space-y-2">
              {data.examples.map((item, index) => (
                <div key={index} className="flex items-start gap-2">
                  <span className="text-[14px] text-[#6c6c70] mt-0.5">•</span>
                  <span className="text-[14px] text-[#1c1c1e] leading-[1.5]">{item}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Status and Action Section */}
        <div className="px-5 pt-1">
          {enabled ? (
            <>
              {/* Enabled Status */}
              <div className="flex items-start gap-2 mb-3 bg-green-50/50 rounded-xl p-3.5 border border-green-100/50">
                <Check className="w-5 h-5 text-[#34c759] flex-shrink-0 mt-0.5" strokeWidth={2.5} />
                <div>
                  <h4 className="text-[14px] font-semibold text-[#1c1c1e] mb-0.5">
                    Expert enabled
                  </h4>
                  <p className="text-[13px] text-[#6c6c70] leading-[1.4]">
                    This expert is currently analyzing your memories.
                  </p>
                </div>
              </div>

              {/* Disable Button */}
              <button
                onClick={onToggle}
                className="w-full py-3.5 rounded-xl bg-white border border-black/[0.08] text-[15px] font-medium text-[#ff3b30] hover:bg-[#ff3b30]/5 transition-colors"
              >
                Disable expert
              </button>
            </>
          ) : (
            /* Enable Button */
            <button
              onClick={onToggle}
              className="w-full py-3.5 rounded-xl bg-gradient-to-r from-[#7c3aed] to-[#6d28d9] text-white text-[15px] font-semibold hover:opacity-90 transition-opacity flex items-center justify-center gap-2 shadow-lg"
            >
              <Sparkles className="w-5 h-5" strokeWidth={2} />
              Use this expert
            </button>
          )}
        </div>
      </div>
    </div>
  );
}