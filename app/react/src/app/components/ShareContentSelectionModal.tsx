import React from 'react';
import { CheckSquare, FileText, Briefcase, Code, Lightbulb, Heart, Mic, MessageSquare, ChevronRight } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { getTemplateDisplayName } from '../helper_template';

interface SummaryVersion {
  id: number | string; // Support 'original' for original summary
  styleId: string;
  timestamp: string;
  isLatest: boolean;
  isOriginal?: boolean;
}

interface ExpertInsight {
  type: 'business' | 'execution' | 'creative' | 'wellness';
  available: boolean;
}

interface ShareContentSelectionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onContinue: (selectedSummaryId: number | string, selectedContent: {
    includeExpertInsights: {
      business: boolean;
      execution: boolean;
      creative: boolean;
      wellness: boolean;
    };
    includeTodos: boolean;
    includeMemos: boolean;
    includeTranscript: boolean;
    includeAudio: boolean;
  }) => void;
  summaryVersions: SummaryVersion[];
  expertInsights: ExpertInsight[];
  showTodos?: boolean;
  showMemos?: boolean;
}

const expertConfig = {
  business: {
    icon: Briefcase,
    title: 'Business Insight',
    iconColor: 'text-[#f59e0b]'
  },
  execution: {
    icon: Code,
    title: 'Execution Insight',
    iconColor: 'text-[#0ea5e9]'
  },
  creative: {
    icon: Lightbulb,
    title: 'Creative Insight',
    iconColor: 'text-[#ec4899]'
  },
  wellness: {
    icon: Heart,
    title: 'Wellness Insight',
    iconColor: 'text-[#10b981]'
  }
};

export function ShareContentSelectionModal({
  isOpen,
  onClose,
  onContinue,
  summaryVersions,
  expertInsights,
  showTodos = true,
  showMemos = true
}: ShareContentSelectionModalProps) {
  const [selectedSummaryId, setSelectedSummaryId] = React.useState<number | string>(
    summaryVersions.find(v => v.isOriginal)?.id || summaryVersions.find(v => v.isLatest)?.id || summaryVersions[0]?.id || 0
  );
  
  const [includeBusinessInsight, setIncludeBusinessInsight] = React.useState(false);
  const [includeExecutionInsight, setIncludeExecutionInsight] = React.useState(false);
  const [includeCreativeInsight, setIncludeCreativeInsight] = React.useState(false);
  const [includeWellnessInsight, setIncludeWellnessInsight] = React.useState(false);
  const [includeTodos, setIncludeTodos] = React.useState(false);
  const [includeMemos, setIncludeMemos] = React.useState(false);
  const [includeTranscript, setIncludeTranscript] = React.useState(false);
  const [includeAudio, setIncludeAudio] = React.useState(false);

  const handleContinue = () => {
    onContinue(selectedSummaryId, {
      includeExpertInsights: {
        business: includeBusinessInsight,
        execution: includeExecutionInsight,
        creative: includeCreativeInsight,
        wellness: includeWellnessInsight
      },
      includeTodos,
      includeMemos,
      includeTranscript,
      includeAudio
    });
  };

  const toggleExpertInsight = (type: 'business' | 'execution' | 'creative' | 'wellness') => {
    switch (type) {
      case 'business':
        setIncludeBusinessInsight(!includeBusinessInsight);
        break;
      case 'execution':
        setIncludeExecutionInsight(!includeExecutionInsight);
        break;
      case 'creative':
        setIncludeCreativeInsight(!includeCreativeInsight);
        break;
      case 'wellness':
        setIncludeWellnessInsight(!includeWellnessInsight);
        break;
    }
  };

  const getExpertInsightState = (type: 'business' | 'execution' | 'creative' | 'wellness') => {
    switch (type) {
      case 'business':
        return includeBusinessInsight;
      case 'execution':
        return includeExecutionInsight;
      case 'creative':
        return includeCreativeInsight;
      case 'wellness':
        return includeWellnessInsight;
    }
  };

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/40 z-50"
          />

          {/* Bottom Sheet */}
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 30, stiffness: 300 }}
            className="fixed bottom-0 left-0 right-0 bg-[#f2f2f7] rounded-t-3xl z-50 max-h-[85vh] overflow-y-auto"
          >
            {/* Handle */}
            <div className="flex justify-center pt-3 pb-2">
              <div className="w-10 h-1 bg-[#c7c7cc] rounded-full" />
            </div>

            {/* Content */}
            <div className="px-5 pb-8">
              {/* Header */}
              <div className="text-center mb-6 pt-4">
                <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">
                  Choose content to share
                </h2>
                <p className="text-[15px] text-[#8e8e93]">
                  Select which summary and additional content to include
                </p>
              </div>

              {/* Summary Version Selection */}
              {summaryVersions.length > 0 && (
                <div className="mb-6">
                  <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3 px-1">
                    Summary version
                  </h3>
                  <div className="bg-white rounded-2xl overflow-hidden">
                    {summaryVersions.map((version, index) => (
                      <button
                        key={version.id}
                        onClick={() => setSelectedSummaryId(version.id)}
                        className={`w-full flex items-center gap-3 px-4 py-3.5 active:bg-[#f2f2f7] transition-colors ${
                          index !== summaryVersions.length - 1 ? 'border-b border-[#e5e5ea]' : ''
                        }`}
                      >
                        {/* Radio Button */}
                        <div className="flex-shrink-0 w-5 h-5 rounded-full border-2 flex items-center justify-center"
                          style={{
                            borderColor: selectedSummaryId === version.id ? '#007aff' : '#c7c7cc'
                          }}
                        >
                          {selectedSummaryId === version.id && (
                            <div className="w-2.5 h-2.5 rounded-full bg-[#007aff]" />
                          )}
                        </div>

                        {/* Template Name */}
                        <div className="flex-1 text-left">
                          <div className="flex items-center gap-2">
                            <span className="text-[15px] text-[#1c1c1e]">
                              {version.isOriginal ? 'Original Summary' : getTemplateDisplayName(version.styleId)}
                            </span>
                            {version.isOriginal && (
                              <span className="text-[11px] px-2 py-0.5 bg-[#5856d6]/10 text-[#5856d6] rounded-full font-medium">
                                Original
                              </span>
                            )}
                            {version.isLatest && !version.isOriginal && (
                              <span className="text-[11px] px-2 py-0.5 bg-[#34c759]/10 text-[#34c759] rounded-full font-medium">
                                Latest
                              </span>
                            )}
                          </div>
                          <span className="text-[13px] text-[#8e8e93]">
                            {version.timestamp}
                          </span>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Additional Content Selection */}
              <div className="mb-6">
                <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3 px-1">
                  Include additional content
                </h3>
                <div className="bg-white rounded-2xl overflow-hidden">
                  {/* Expert Insights */}
                  {expertInsights.map((insight, index) => {
                    const config = expertConfig[insight.type];
                    const Icon = config.icon;
                    const isChecked = getExpertInsightState(insight.type);
                    
                    if (!insight.available) return null;
                    
                    return (
                      <button
                        key={insight.type}
                        onClick={() => toggleExpertInsight(insight.type)}
                        className="w-full flex items-center gap-3 px-4 py-3.5 border-b border-[#e5e5ea] active:bg-[#f2f2f7] transition-colors"
                      >
                        <div className={`flex-shrink-0 w-5 h-5 rounded-sm flex items-center justify-center border-2 transition-colors ${
                          isChecked 
                            ? 'bg-[#007aff] border-[#007aff]' 
                            : 'border-[#c7c7cc]'
                        }`}>
                          {isChecked && (
                            <svg width="12" height="10" viewBox="0 0 12 10" fill="none">
                              <path d="M1 5L4.5 8.5L11 1.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                            </svg>
                          )}
                        </div>
                        <Icon className={`w-5 h-5 ${config.iconColor}`} strokeWidth={2} />
                        <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
                          {config.title}
                        </span>
                      </button>
                    );
                  })}

                  {/* Todos */}
                  {showTodos && (
                    <button
                      onClick={() => setIncludeTodos(!includeTodos)}
                      className="w-full flex items-center gap-3 px-4 py-3.5 border-b border-[#e5e5ea] active:bg-[#f2f2f7] transition-colors"
                    >
                      <div className={`flex-shrink-0 w-5 h-5 rounded-sm flex items-center justify-center border-2 transition-colors ${
                        includeTodos 
                          ? 'bg-[#007aff] border-[#007aff]' 
                          : 'border-[#c7c7cc]'
                      }`}>
                        {includeTodos && (
                          <svg width="12" height="10" viewBox="0 0 12 10" fill="none">
                            <path d="M1 5L4.5 8.5L11 1.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                          </svg>
                        )}
                      </div>
                      <CheckSquare className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
                      <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
                        Todos
                      </span>
                    </button>
                  )}

                  {/* Memos */}
                  {showMemos && (
                    <button
                      onClick={() => setIncludeMemos(!includeMemos)}
                      className="w-full flex items-center gap-3 px-4 py-3.5 border-b border-[#e5e5ea] active:bg-[#f2f2f7] transition-colors"
                    >
                      <div className={`flex-shrink-0 w-5 h-5 rounded-sm flex items-center justify-center border-2 transition-colors ${
                        includeMemos 
                          ? 'bg-[#007aff] border-[#007aff]' 
                          : 'border-[#c7c7cc]'
                      }`}>
                        {includeMemos && (
                          <svg width="12" height="10" viewBox="0 0 12 10" fill="none">
                            <path d="M1 5L4.5 8.5L11 1.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                          </svg>
                        )}
                      </div>
                      <FileText className="w-5 h-5 text-[#5856d6]" strokeWidth={2} />
                      <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
                        Memos
                      </span>
                    </button>
                  )}

                  {/* Transcript */}
                  <button
                    onClick={() => setIncludeTranscript(!includeTranscript)}
                    className="w-full flex items-center gap-3 px-4 py-3.5 border-b border-[#e5e5ea] active:bg-[#f2f2f7] transition-colors"
                  >
                    <div className={`flex-shrink-0 w-5 h-5 rounded-sm flex items-center justify-center border-2 transition-colors ${
                      includeTranscript 
                        ? 'bg-[#007aff] border-[#007aff]' 
                        : 'border-[#c7c7cc]'
                    }`}>
                      {includeTranscript && (
                        <svg width="12" height="10" viewBox="0 0 12 10" fill="none">
                          <path d="M1 5L4.5 8.5L11 1.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        </svg>
                      )}
                    </div>
                    <MessageSquare className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
                    <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
                      Transcript
                    </span>
                  </button>

                  {/* Audio Recording */}
                  <button
                    onClick={() => setIncludeAudio(!includeAudio)}
                    className="w-full flex items-center gap-3 px-4 py-3.5 active:bg-[#f2f2f7] transition-colors"
                  >
                    <div className={`flex-shrink-0 w-5 h-5 rounded-sm flex items-center justify-center border-2 transition-colors ${
                      includeAudio 
                        ? 'bg-[#007aff] border-[#007aff]' 
                        : 'border-[#c7c7cc]'
                    }`}>
                      {includeAudio && (
                        <svg width="12" height="10" viewBox="0 0 12 10" fill="none">
                          <path d="M1 5L4.5 8.5L11 1.5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                        </svg>
                      )}
                    </div>
                    <Mic className="w-5 h-5 text-[#ff3b30]" strokeWidth={2} />
                    <div className="flex-1 text-left">
                      <div className="text-[15px] text-[#1c1c1e]">
                        Audio recording
                      </div>
                      <div className="text-[13px] text-[#8e8e93]">
                        Shared as link
                      </div>
                    </div>
                  </button>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="space-y-3">
                {/* Continue Button */}
                <button
                  onClick={handleContinue}
                  className="w-full bg-[#007aff] text-white text-[17px] font-semibold py-3.5 rounded-xl shadow-sm active:opacity-80 transition-opacity flex items-center justify-center gap-2"
                >
                  Continue
                  <ChevronRight className="w-5 h-5" strokeWidth={2.5} />
                </button>

                {/* Cancel Button */}
                <button
                  onClick={onClose}
                  className="w-full bg-white text-[#007aff] text-[17px] font-semibold py-3.5 rounded-xl shadow-sm active:opacity-60 transition-opacity"
                >
                  Cancel
                </button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}