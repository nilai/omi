import { X, Sparkles, Heart, Users, Phone, Clipboard, BookOpen, Brain, Lightbulb, Mic, Compass } from 'lucide-react';
import { useState, useEffect } from 'react';

interface TemplateDetailModalProps {
  templateId: string;
  onClose: () => void;
  onUseStyle: (templateId: string) => void;
  fromStylePage?: boolean; // Flag to indicate it's from AI Summary Style page
}

export function TemplateDetailModal({ templateId, onClose, onUseStyle, fromStylePage }: TemplateDetailModalProps) {
  const [isFavorited, setIsFavorited] = useState(false);
  const [customStyle, setCustomStyle] = useState<any>(null);

  // Load favorite status and custom style from localStorage
  useEffect(() => {
    const favorites = JSON.parse(localStorage.getItem('favoriteSummaryStyles') || '[]');
    setIsFavorited(favorites.includes(templateId));

    // Check if this is a custom style
    if (templateId.startsWith('custom-')) {
      const customStyles = JSON.parse(localStorage.getItem('customSummaryStyles') || '[]');
      const style = customStyles.find((s: any) => s.id === templateId);
      setCustomStyle(style);
    }
  }, [templateId]);

  // Toggle favorite status
  const toggleFavorite = () => {
    const favorites = JSON.parse(localStorage.getItem('favoriteSummaryStyles') || '[]');
    let updatedFavorites;
    
    if (favorites.includes(templateId)) {
      updatedFavorites = favorites.filter((id: string) => id !== templateId);
    } else {
      updatedFavorites = [...favorites, templateId];
    }
    
    localStorage.setItem('favoriteSummaryStyles', JSON.stringify(updatedFavorites));
    setIsFavorited(!isFavorited);
    
    // Trigger a storage event to notify other components
    window.dispatchEvent(new Event('storage'));
  };

  const templateDetails: Record<string, {
    emoji: string;
    title: string;
    subtitle: string;
    focuses: string[];
    youllGet: string[];
    goodFor: string[];
    bestWhen: string;
  }> = {
    autopilot: {
      emoji: '🤖',
      title: 'Autopilot',
      subtitle: 'AI adapts to each memory',
      focuses: [
        'Understanding the content before deciding what matters',
        'Avoiding unnecessary structure or forced output',
        'Adapting summary depth to signal strength',
      ],
      youllGet: [
        'Overview only when useful',
        'Action items only if they truly exist',
        'Insights only when there\'s real signal',
        'No filler, no over-summarizing',
      ],
      goodFor: [
        'Everyday recordings',
        'Mixed or unstructured conversations',
        'Moments when you don\'t want to think about how to summarize',
      ],
      bestWhen: 'You want the AI to decide what\'s worth your attention, without being told how.',
    },
    'meeting-secretary': {
      emoji: '🧑‍💼',
      title: 'Meeting secretary',
      subtitle: 'Clear structure, decisions, actions',
      focuses: [
        'Clarifying what was discussed',
        'Capturing decisions and agreements',
        'Turning conversations into clear next steps',
      ],
      youllGet: [
        'Discussion topics, clearly organized',
        'Decisions made and agreements reached',
        'Action items with ownership',
        'Organized sections for easy scanning',
      ],
      goodFor: [
        'Team meetings',
        'Client calls',
        'Any structured conversation',
      ],
      bestWhen: 'You want a clear record of what was said, decided, and what happens next.',
    },
    'sales-followup': {
      emoji: '📞',
      title: 'Sales follow-up',
      subtitle: 'Needs, objections, next steps',
      focuses: [
        'Understanding customer needs and pain points',
        'Identifying objections or hesitations',
        'Tracking commitments and follow-ups',
      ],
      youllGet: [
        'Customer needs and priorities',
        'Objections or concerns raised',
        'Agreed next steps and timelines',
        'Key quotes worth remembering',
      ],
      goodFor: [
        'Sales calls',
        'Customer discovery',
        'Partnership discussions',
      ],
      bestWhen: 'You want to follow up effectively and close deals faster.',
    },
    'learning-notes': {
      emoji: '📚',
      title: 'Learning notes',
      subtitle: 'Concepts, examples, personal takeaways',
      focuses: [
        'Extracting key concepts and ideas',
        'Preserving examples and illustrations',
        'Connecting new knowledge to what you already know',
      ],
      youllGet: [
        'Core concepts explained simply',
        'Examples and real-world applications',
        'Personal insights and connections',
        'Questions to explore further',
      ],
      goodFor: [
        'Lectures and workshops',
        'Podcast episodes',
        'Interviews with experts',
      ],
      bestWhen: 'You want to retain and apply what you\'re learning.',
    },
    'adhd-friendly': {
      emoji: '🧠',
      title: 'ADHD-friendly',
      subtitle: 'Extra structure, clear priorities',
      focuses: [
        'Reducing cognitive overload',
        'Making priorities explicit',
        'Supporting follow-through',
      ],
      youllGet: [
        'Highly structured sections',
        'Clear separation between ideas, decisions, and actions',
        'Explicit priorities and next steps',
        'Minimal noise, maximum clarity',
      ],
      goodFor: [
        'Complex or fast-moving discussions',
        'People who struggle with organization or initiation',
        'Moments when you feel overwhelmed by raw notes',
      ],
      bestWhen: 'You want the AI to do the organizing for you, so you can focus on acting.',
    },
    'project-sync': {
      emoji: '📋',
      title: 'Project sync',
      subtitle: 'Progress, blockers, timelines',
      focuses: [
        'Project progress and current status',
        'Blockers, risks, and dependencies',
        'What\'s next and who\'s responsible',
      ],
      youllGet: [
        'Clear progress summary',
        'Identified blockers and open risks',
        'Upcoming milestones and next steps',
        'Reduced discussion noise',
      ],
      goodFor: [
        'Team syncs and standups',
        'Ongoing projects',
        'Cross-functional updates',
      ],
      bestWhen: 'You want to quickly understand where things stand and what needs to move next.',
    },
    'reflection-insights': {
      emoji: '💡',
      title: 'Reflection',
      subtitle: 'Patterns and insights',
      focuses: [
        'Underlying patterns and themes',
        'Assumptions, tensions, or blind spots',
        'What might not be obvious at first glance',
      ],
      youllGet: [
        'Key insights beyond surface-level summary',
        'Highlighted risks or opportunities',
        'Thought-provoking questions',
      ],
      goodFor: [
        'Strategy discussions',
        'Retrospectives',
        'Personal thinking and sense-making',
      ],
      bestWhen: 'You want the AI to help you think deeper, not just remember.',
    },
    'interview-research': {
      emoji: '🎙',
      title: 'Interview',
      subtitle: 'Key points and quotes',
      focuses: [
        'Extracting signal from Q&A-style conversations',
        'Preserving important wording and quotes',
        'Organizing responses by topic',
      ],
      youllGet: [
        'Main topics discussed',
        'Notable quotes and phrasing',
        'Clean, structured takeaways',
      ],
      goodFor: [
        'User or customer interviews',
        'Research conversations',
        'Media or internal interviews',
      ],
      bestWhen: 'You want to capture what was said accurately, without over-analysis.',
    },
    'investor-review': {
      emoji: '🧭',
      title: 'Decision review',
      subtitle: 'Arguments and questions',
      focuses: [
        'Decisions made, deferred, or avoided',
        'Arguments for and against options',
        'Open questions and uncertainties',
      ],
      youllGet: [
        'Clear list of decisions and their status',
        'Key reasoning and trade-offs',
        'Unresolved questions to follow up',
      ],
      goodFor: [
        'Decision-heavy meetings',
        'Leadership discussions',
        'Complex or high-stakes choices',
      ],
      bestWhen: 'You want clarity around why a decision was made — or why it wasn\'t.',
    },
    // Legacy ID mappings for backward compatibility
    meeting: {
      emoji: '🧑‍💼',
      title: 'Meeting secretary',
      subtitle: 'Clear structure, decisions, actions',
      focuses: [
        'Clarifying what was discussed',
        'Capturing decisions and agreements',
        'Turning conversations into clear next steps',
      ],
      youllGet: [
        'Discussion topics, clearly organized',
        'Decisions made and agreements reached',
        'Action items with ownership',
        'Organized sections for easy scanning',
      ],
      goodFor: [
        'Team meetings',
        'Client calls',
        'Any structured conversation',
      ],
      bestWhen: 'You want a clear record of what was said, decided, and what happens next.',
    },
    sales: {
      emoji: '📞',
      title: 'Sales follow-up',
      subtitle: 'Needs, objections, next steps',
      focuses: [
        'Understanding customer needs and pain points',
        'Identifying objections or hesitations',
        'Tracking commitments and follow-ups',
      ],
      youllGet: [
        'Customer needs and priorities',
        'Objections or concerns raised',
        'Agreed next steps and timelines',
        'Key quotes worth remembering',
      ],
      goodFor: [
        'Sales calls',
        'Customer discovery',
        'Partnership discussions',
      ],
      bestWhen: 'You want to follow up effectively and close deals faster.',
    },
    learning: {
      emoji: '📚',
      title: 'Learning notes',
      subtitle: 'Concepts, examples, personal takeaways',
      focuses: [
        'Extracting key concepts and ideas',
        'Preserving examples and illustrations',
        'Connecting new knowledge to what you already know',
      ],
      youllGet: [
        'Core concepts explained simply',
        'Examples and real-world applications',
        'Personal insights and connections',
        'Questions to explore further',
      ],
      goodFor: [
        'Lectures and workshops',
        'Podcast episodes',
        'Interviews with experts',
      ],
      bestWhen: 'You want to retain and apply what you\'re learning.',
    },
    adhd: {
      emoji: '🧠',
      title: 'ADHD-friendly',
      subtitle: 'Extra structure, clear priorities',
      focuses: [
        'Reducing cognitive overload',
        'Making priorities explicit',
        'Supporting follow-through',
      ],
      youllGet: [
        'Highly structured sections',
        'Clear separation between ideas, decisions, and actions',
        'Explicit priorities and next steps',
        'Minimal noise, maximum clarity',
      ],
      goodFor: [
        'Complex or fast-moving discussions',
        'People who struggle with organization or initiation',
        'Moments when you feel overwhelmed by raw notes',
      ],
      bestWhen: 'You want the AI to do the organizing for you, so you can focus on acting.',
    },
  };

  const template = templateId.startsWith('custom-') ? customStyle : templateDetails[templateId];

  if (!template) return null;

  // Helper function to get icon component based on templateId
  const getTemplateIcon = () => {
    const iconProps = { className: "w-8 h-8 text-[#007aff]", strokeWidth: 2 };
    
    switch (templateId) {
      case 'autopilot':
        return <Sparkles {...iconProps} />;
      case 'meeting-secretary':
      case 'meeting':
        return <Users {...iconProps} />;
      case 'sales-followup':
      case 'sales':
        return <Phone {...iconProps} />;
      case 'project-sync':
        return <Clipboard {...iconProps} />;
      case 'learning-notes':
      case 'learning':
        return <BookOpen {...iconProps} />;
      case 'adhd-friendly':
      case 'adhd':
        return <Brain {...iconProps} />;
      case 'reflection-insights':
        return <Lightbulb {...iconProps} />;
      case 'interview-research':
        return <Mic {...iconProps} />;
      case 'investor-review':
        return <Compass {...iconProps} />;
      default:
        return <Sparkles {...iconProps} />;
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-[200] flex items-end sm:items-center justify-center animate-fade-in">
      <div 
        className="absolute inset-0" 
        onClick={onClose}
      />
      
      <div className="bg-white w-full sm:max-w-lg sm:mx-4 rounded-t-[28px] sm:rounded-[28px] px-5 pt-4 pb-6 relative animate-slide-up max-h-[85vh] flex flex-col shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-full bg-[#f0f9ff] flex items-center justify-center flex-shrink-0">
              {getTemplateIcon()}
            </div>
            <div>
              <h2 className="text-[20px] font-bold text-[#1c1c1e]">{template.title}</h2>
              <p className="text-[14px] text-[#8e8e93]">
                {templateId.startsWith('custom-') ? 'Custom style' : template.subtitle}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] transition-colors flex-shrink-0"
          >
            <X className="w-5 h-5" strokeWidth={2.5} />
          </button>
        </div>

        {/* Scrollable content */}
        <div className="flex-1 overflow-y-auto -mx-5 px-5 mb-4">
          {templateId.startsWith('custom-') ? (
            // Custom style - show loading animation
            <div className="flex flex-col items-center justify-center py-12">
              <div className="relative w-16 h-16 mb-6">
                {/* Animated circles */}
                <div className="absolute inset-0 rounded-full border-4 border-[#007aff]/20"></div>
                <div className="absolute inset-0 rounded-full border-4 border-transparent border-t-[#007aff] animate-spin"></div>
                <div className="absolute inset-2 rounded-full bg-gradient-to-br from-[#007aff]/10 to-[#5856d6]/10 flex items-center justify-center">
                  <Sparkles className="w-6 h-6 text-[#007aff] animate-pulse" strokeWidth={2} />
                </div>
              </div>
              <p className="text-[15px] font-medium text-[#007aff] mb-1">AI generating</p>
              <p className="text-[13px] text-[#8e8e93] text-center max-w-[240px]">
                Analyzing your custom style configuration...
              </p>
            </div>
          ) : (
            <>
              {/* What this style focuses on */}
              <div className="mb-5">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-2">
                  What this style focuses on
                </h3>
                <ul className="space-y-1.5">
                  {template.focuses.map((item, index) => (
                    <li key={index} className="text-[14px] text-[#3c3c43] leading-[1.4] flex items-start gap-2">
                      <span className="text-[#007aff] mt-0.5">•</span>
                      <span className="flex-1">{item}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* You'll get */}
              <div className="mb-5">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-2">
                  You'll get
                </h3>
                <ul className="space-y-1.5">
                  {template.youllGet.map((item, index) => (
                    <li key={index} className="text-[14px] text-[#3c3c43] leading-[1.4] flex items-start gap-2">
                      <span className="text-[#007aff] mt-0.5">•</span>
                      <span className="flex-1">{item}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Good for */}
              <div className="mb-5">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-2">
                  Good for
                </h3>
                <ul className="space-y-1.5">
                  {template.goodFor.map((item, index) => (
                    <li key={index} className="text-[14px] text-[#3c3c43] leading-[1.4] flex items-start gap-2">
                      <span className="text-[#007aff] mt-0.5">•</span>
                      <span className="flex-1">{item}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Best when */}
              <div className="bg-[#f9f9f9] rounded-[14px] p-4">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-2">
                  Best when
                </h3>
                <p className="text-[14px] text-[#3c3c43] leading-[1.5]">
                  {template.bestWhen}
                </p>
              </div>
            </>
          )}
        </div>

        {/* Bottom CTA */}
        <div className="flex items-center gap-2.5">
          {/* Favorite button - hide for autopilot */}
          {templateId !== 'autopilot' && (
            <button
              onClick={toggleFavorite}
              className={`w-12 h-12 flex items-center justify-center rounded-[14px] border-2 transition-all ${
                isFavorited 
                  ? 'bg-[#ff3b30] border-[#ff3b30] text-white' 
                  : 'bg-white border-[#e5e5ea] text-[#8e8e93] hover:border-[#ff3b30] hover:text-[#ff3b30]'
              }`}
            >
              <Heart 
                className="w-5 h-5" 
                fill={isFavorited ? 'currentColor' : 'none'}
                strokeWidth={2}
              />
            </button>
          )}

          {/* Use this style button */}
          <button
            onClick={() => {
              onUseStyle(templateId);
              onClose();
            }}
            className="flex-1 bg-gradient-to-br from-[#007aff] to-[#5856d6] text-white text-[15px] font-semibold py-3 rounded-[14px] hover:opacity-90 transition-opacity flex items-center justify-center gap-2 shadow-lg"
          >
            <Sparkles className="w-4 h-4" />
            <span>{fromStylePage ? 'Use next time' : 'Use this style'}</span>
          </button>
        </div>
      </div>
    </div>
  );
}