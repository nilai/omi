import { useState } from 'react';
import { Plus, Briefcase, Code, Lightbulb, Heart } from 'lucide-react';

export type ExpertType = 'business' | 'execution' | 'creative' | 'wellness';

interface ExpertInsightCardProps {
  expertType: ExpertType;
  timestamp: string;
  mainContent: string;
  riskSection: {
    title: string;
    items: string[];
  };
  suggestion: string;
  hasTodoAdded?: boolean;
  onAddTodo: () => void;
}

const expertConfig = {
  business: {
    icon: Briefcase,
    title: 'Business Insight',
    bgGradient: 'from-[#fef3e2] to-[#fde8c0]',
    iconBg: 'bg-[#f59e0b]/20',
    iconColor: 'text-[#f59e0b]',
    textColor: 'text-[#ea580c]',
    border: 'border-[#fbbf24]/40'
  },
  execution: {
    icon: Code,
    title: 'Execution Insight',
    bgGradient: 'from-[#e0f2fe] to-[#bae6fd]',
    iconBg: 'bg-[#0ea5e9]/20',
    iconColor: 'text-[#0ea5e9]',
    textColor: 'text-[#0284c7]',
    border: 'border-[#38bdf8]/40'
  },
  creative: {
    icon: Lightbulb,
    title: 'Creative Insight',
    bgGradient: 'from-[#fce7f3] to-[#fbcfe8]',
    iconBg: 'bg-[#ec4899]/20',
    iconColor: 'text-[#ec4899]',
    textColor: 'text-[#db2777]',
    border: 'border-[#f9a8d4]/40'
  },
  wellness: {
    icon: Heart,
    title: 'Wellness Insight',
    bgGradient: 'from-[#d1fae5] to-[#a7f3d0]',
    iconBg: 'bg-[#10b981]/20',
    iconColor: 'text-[#10b981]',
    textColor: 'text-[#059669]',
    border: 'border-[#6ee7b7]/40'
  }
};

export function ExpertInsightCard({
  expertType,
  timestamp,
  mainContent,
  riskSection,
  suggestion,
  hasTodoAdded,
  onAddTodo
}: ExpertInsightCardProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const config = expertConfig[expertType];
  const Icon = config.icon;
  
  // Check if content is long enough to need Read more
  const contentLines = mainContent.split('\n');
  const hasMultipleParagraphs = contentLines.length > 1;
  const shouldShowReadMore = hasMultipleParagraphs || mainContent.length > 150;
  
  return (
    <div className={`bg-gradient-to-br ${config.bgGradient} rounded-2xl p-5 shadow-sm border ${config.border}`}>
      {/* Header */}
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-2">
          <div className={`w-7 h-7 rounded-full ${config.iconBg} flex items-center justify-center`}>
            <Icon className={`w-4 h-4 ${config.iconColor}`} strokeWidth={2} />
          </div>
          <h3 className={`text-[13px] font-semibold uppercase tracking-wide ${config.textColor}`}>
            {config.title}
          </h3>
        </div>
        <span className="text-[12px] text-[#8e8e93]">{timestamp}</span>
      </div>

      {/* Main content */}
      <div className="text-[15px] text-[#1c1c1e] leading-[1.5] mb-3 whitespace-pre-line">
        {isExpanded ? (
          mainContent
        ) : (
          contentLines[0]
        )}
      </div>

      {/* Read more button - only show when collapsed and content needs it */}
      {!isExpanded && shouldShowReadMore && (
        <button 
          onClick={() => setIsExpanded(true)}
          className={`text-[14px] ${config.textColor} font-medium hover:opacity-70 transition-opacity mb-3`}
        >
          Read more
        </button>
      )}

      {/* Risk/Opportunity/Pattern section - only show when expanded */}
      {isExpanded && (
        <>
          <div className="mb-3 space-y-1">
            {/* For Wellness insight, show first 3 items before the Pattern section */}
            {expertType === 'wellness' ? (
              riskSection.items.slice(0, 3).map((item, index) => (
                <div key={index} className="flex items-start gap-2 text-[14px] text-[#3c3c43]">
                  <span className={config.textColor}>•</span>
                  <span className="flex-1">{item}</span>
                </div>
              ))
            ) : expertType === 'creative' ? (
              // For Creative insight, show first 3 items
              riskSection.items.slice(0, 3).map((item, index) => (
                <div key={index} className="flex items-start gap-2 text-[14px] text-[#3c3c43]">
                  <span className={config.textColor}>•</span>
                  <span className="flex-1">{item}</span>
                </div>
              ))
            ) : (
              // For other insights, show all items
              riskSection.items.map((item, index) => (
                <div key={index} className="flex items-start gap-2 text-[14px] text-[#3c3c43]">
                  <span className={config.textColor}>•</span>
                  <span className="flex-1">{item}</span>
                </div>
              ))
            )}
          </div>

          <div className="mb-3">
            <p className={`text-[14px] font-semibold ${config.textColor}`}>
              {riskSection.title}
            </p>
          </div>

          {/* Additional context line */}
          {expertType === 'creative' && riskSection.items.length > 3 && (
            <p className="text-[14px] text-[#3c3c43] mb-3">
              {riskSection.items[3]}
            </p>
          )}

          {/* For Wellness insight, show the 4th item (last item) after Pattern title */}
          {expertType === 'wellness' && riskSection.items.length > 3 && (
            <p className="text-[14px] text-[#3c3c43] mb-3">
              {riskSection.items[3]}
            </p>
          )}

          {/* Suggestion */}
          <div className="mb-3">
            <p className={`text-[14px] font-semibold ${config.textColor} mb-1`}>
              Suggestion:
            </p>
            <p className="text-[14px] text-[#3c3c43]">
              {suggestion}
            </p>
          </div>

          {/* Show less button */}
          <button 
            onClick={() => setIsExpanded(false)}
            className={`text-[14px] ${config.textColor} font-medium hover:opacity-70 transition-opacity mb-3`}
          >
            Show less
          </button>
        </>
      )}

      {/* Add follow-up todo button */}
      <button
        onClick={onAddTodo}
        disabled={hasTodoAdded}
        className={`w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl text-[14px] font-medium transition-all ${
          hasTodoAdded 
            ? 'bg-[#8e8e93]/20 text-[#8e8e93] cursor-not-allowed' 
            : `${config.iconBg} ${config.textColor} hover:opacity-80`
        }`}
      >
        {hasTodoAdded ? (
          <span>Follow-up todo added</span>
        ) : (
          <>
            <Plus className="w-4 h-4" strokeWidth={2.5} />
            <span>Add follow-up todo</span>
          </>
        )}
      </button>
    </div>
  );
}