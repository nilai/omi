import { ChevronLeft, Sparkles, Users, Phone, Clipboard, BookOpen, Brain, Lightbulb, Mic, Compass, Heart, Plus, MoreVertical, Edit, Trash2 } from 'lucide-react';
import { useState, useEffect } from 'react';
import { TemplateDetailModal } from './TemplateDetailModal';
import { CreateSummaryStylePage } from './CreateSummaryStylePage';

interface AISummaryStylePageProps {
  onBack: () => void;
  currentStyle?: string;
  onSelectStyle?: (style: string) => void;
  fromAudioMemory?: boolean; // Flag to indicate it's from Audio Memory detail
}

export function AISummaryStylePage({ onBack, currentStyle, onSelectStyle, fromAudioMemory }: AISummaryStylePageProps) {
  const [showTemplateDetail, setShowTemplateDetail] = useState(false);
  const [selectedTemplateForDetail, setSelectedTemplateForDetail] = useState<string>('autopilot');
  const [selectedStyleId, setSelectedStyleId] = useState<string>(currentStyle || 'autopilot');
  const [favoriteStyles, setFavoriteStyles] = useState<string[]>([]);
  const [showCreatePage, setShowCreatePage] = useState(false);
  const [customStyles, setCustomStyles] = useState<any[]>([]);
  const [showMenu, setShowMenu] = useState<string | null>(null);
  const [editingStyle, setEditingStyle] = useState<any>(null);
  
  // Load favorites and custom styles on mount
  useEffect(() => {
    const favorites = JSON.parse(localStorage.getItem('favoriteSummaryStyles') || '[]');
    setFavoriteStyles(favorites);
    
    const customs = JSON.parse(localStorage.getItem('customSummaryStyles') || '[]');
    setCustomStyles(customs);
    
    // Listen for storage changes
    const handleStorageChange = () => {
      const updatedFavorites = JSON.parse(localStorage.getItem('favoriteSummaryStyles') || '[]');
      setFavoriteStyles(updatedFavorites);
      
      const updatedCustoms = JSON.parse(localStorage.getItem('customSummaryStyles') || '[]');
      setCustomStyles(updatedCustoms);
    };
    
    window.addEventListener('storage', handleStorageChange);
    return () => window.removeEventListener('storage', handleStorageChange);
  }, []);
  
  const handleSelectStyle = (styleId: string) => {
    setSelectedStyleId(styleId);
    onSelectStyle && onSelectStyle(styleId);
  };

  // Get icon component based on style ID
  const getStyleIcon = (styleId: string) => {
    const iconProps = { className: "w-6 h-6 text-[#007aff]", strokeWidth: 2 };
    
    switch (styleId) {
      case 'autopilot':
        return <Sparkles {...iconProps} />;
      case 'meeting-secretary':
        return <Users {...iconProps} />;
      case 'sales-followup':
        return <Phone {...iconProps} />;
      case 'project-sync':
        return <Clipboard {...iconProps} />;
      case 'learning-notes':
        return <BookOpen {...iconProps} />;
      case 'adhd-friendly':
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

  const styles = {
    default: [
      {
        id: 'autopilot',
        emoji: '🤖',
        title: 'Autopilot',
        description: 'AI adapts to each memory',
      },
    ],
    structured: [
      {
        id: 'meeting-secretary',
        emoji: '🧑‍💼',
        title: 'Meeting secretary',
        description: 'Structure, decisions, actions',
      },
      {
        id: 'sales-followup',
        emoji: '📞',
        title: 'Sales follow-up',
        description: 'Needs, objections, next steps',
      },
      {
        id: 'project-sync',
        emoji: '📋',
        title: 'Project sync',
        description: 'Progress, blockers, timelines',
      },
      {
        id: 'learning-notes',
        emoji: '📚',
        title: 'Learning notes',
        description: 'Concepts and understanding',
      },
    ],
    thinking: [
      {
        id: 'adhd-friendly',
        emoji: '🧠',
        title: 'ADHD-friendly',
        description: 'Extra structure, clear priorities',
      },
      {
        id: 'reflection-insights',
        emoji: '💡',
        title: 'Reflection',
        description: 'Patterns and insights',
      },
      {
        id: 'interview-research',
        emoji: '🎙',
        title: 'Interview',
        description: 'Key points and quotes',
      },
      {
        id: 'investor-review',
        emoji: '🧭',
        title: 'Decision review',
        description: 'Arguments and questions',
      },
    ],
  };

  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
        <button 
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          AI Summary Style
        </h1>
        <div className="w-5" />
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Default Style Section */}
        <div className="pt-4 pb-3 px-5">
          <div className="mb-3">
            <h2 className="text-[11px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              Default (Recommended)
            </h2>
          </div>
          
          {styles.default.map((style) => (
            <button
              key={style.id}
              onClick={() => {
                setSelectedTemplateForDetail(style.id);
                setShowTemplateDetail(true);
              }}
              className={`w-full bg-gradient-to-br from-[#f0f9ff] to-[#e0f2fe] rounded-[14px] p-3 shadow-[0_2px_8px_rgba(0,122,255,0.12)] border-2 text-left hover:shadow-[0_4px_12px_rgba(0,122,255,0.18)] transition-all relative ${
                currentStyle === style.id ? 'border-[#007aff]' : 'border-[#007aff]/10'
              }`}
            >
              {/* No favorite icon for autopilot */}
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full bg-white flex items-center justify-center flex-shrink-0">
                    {getStyleIcon(style.id)}
                  </div>
                  <div>
                    <h3 className="text-[15px] font-semibold text-[#1c1c1e]">{style.title}</h3>
                    <p className="text-[13px] text-[#007aff]">{style.description}</p>
                  </div>
                </div>
              </div>
            </button>
          ))}
        </div>

        {/* Structured Styles Section - 2 columns */}
        <div className="pb-3 px-5">
          <div className="mb-3">
            <h2 className="text-[11px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              Structured styles
            </h2>
          </div>
          
          <div className="grid grid-cols-2 gap-2.5">
            {styles.structured.map((style) => {
              const isFavorited = favoriteStyles.includes(style.id);
              return (
                <button
                  key={style.id}
                  onClick={() => {
                    setSelectedTemplateForDetail(style.id);
                    setShowTemplateDetail(true);
                  }}
                  className={`relative bg-white rounded-[14px] p-3 shadow-[0_2px_8px_rgba(0,0,0,0.06)] border-2 text-left hover:shadow-[0_4px_12px_rgba(0,0,0,0.1)] transition-all ${
                    currentStyle === style.id ? 'border-[#007aff]' : 'border-transparent'
                  }`}
                >
                  {/* Favorite button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      const updatedFavorites = isFavorited
                        ? favoriteStyles.filter((id) => id !== style.id)
                        : [...favoriteStyles, style.id];
                      setFavoriteStyles(updatedFavorites);
                      localStorage.setItem('favoriteSummaryStyles', JSON.stringify(updatedFavorites));
                    }}
                    className="absolute top-2 right-2 w-6 h-6 flex items-center justify-center hover:scale-110 active:scale-95 transition-transform"
                  >
                    <Heart 
                      className={`w-4 h-4 ${isFavorited ? 'text-[#ff3b30]' : 'text-[#d1d1d6]'}`}
                      fill={isFavorited ? 'currentColor' : 'none'}
                      strokeWidth={2}
                    />
                  </button>
                  {/* Icon and Title in one row */}
                  <div className="flex items-center gap-2 mb-1.5">
                    <div className="w-7 h-7 rounded-full bg-[#f0f9ff] flex items-center justify-center flex-shrink-0">
                      {getStyleIcon(style.id)}
                    </div>
                    <h3 className="text-[15px] font-semibold text-[#1c1c1e] leading-tight pr-4">{style.title}</h3>
                  </div>
                  <p className="text-[12px] text-[#8e8e93] leading-[1.3] pl-9">
                    {style.description}
                  </p>
                </button>
              );
            })}
          </div>
        </div>

        {/* Thinking & Specialized Styles Section - 2 columns */}
        <div className="pb-3 px-5">
          <div className="mb-3">
            <h2 className="text-[11px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              Thinking & specialized
            </h2>
          </div>
          
          <div className="grid grid-cols-2 gap-2.5">
            {styles.thinking.map((style) => {
              const isFavorited = favoriteStyles.includes(style.id);
              return (
                <button
                  key={style.id}
                  onClick={() => {
                    setSelectedTemplateForDetail(style.id);
                    setShowTemplateDetail(true);
                  }}
                  className={`relative bg-white rounded-[14px] p-3 shadow-[0_2px_8px_rgba(0,0,0,0.06)] border-2 text-left hover:shadow-[0_4px_12px_rgba(0,0,0,0.1)] transition-all ${
                    currentStyle === style.id ? 'border-[#007aff]' : 'border-transparent'
                  }`}
                >
                  {/* Favorite button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      const updatedFavorites = isFavorited
                        ? favoriteStyles.filter((id) => id !== style.id)
                        : [...favoriteStyles, style.id];
                      setFavoriteStyles(updatedFavorites);
                      localStorage.setItem('favoriteSummaryStyles', JSON.stringify(updatedFavorites));
                    }}
                    className="absolute top-2 right-2 w-6 h-6 flex items-center justify-center hover:scale-110 active:scale-95 transition-transform"
                  >
                    <Heart 
                      className={`w-4 h-4 ${isFavorited ? 'text-[#ff3b30]' : 'text-[#d1d1d6]'}`}
                      fill={isFavorited ? 'currentColor' : 'none'}
                      strokeWidth={2}
                    />
                  </button>
                  {/* Icon and Title in one row */}
                  <div className="flex items-center gap-2 mb-1.5">
                    <div className="w-7 h-7 rounded-full bg-[#f0f9ff] flex items-center justify-center flex-shrink-0">
                      {getStyleIcon(style.id)}
                    </div>
                    <h3 className="text-[15px] font-semibold text-[#1c1c1e] leading-tight pr-4">{style.title}</h3>
                  </div>
                  <p className="text-[12px] text-[#8e8e93] leading-[1.3] pl-9">
                    {style.description}
                  </p>
                </button>
              );
            })}
          </div>
        </div>

        {/* Custom Styles Section - 2 columns */}
        <div className="pb-3 px-5">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-[11px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              MY STYLES
            </h2>
            <button
              onClick={() => setShowCreatePage(true)}
              className="flex items-center gap-1.5 text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <Plus className="w-4 h-4" strokeWidth={2.5} />
              <span className="text-[13px] font-medium">Create new style</span>
            </button>
          </div>
          
          {customStyles.length === 0 ? (
            <div className="bg-white rounded-2xl p-6 text-center">
              <p className="text-[13px] text-[#8e8e93] mb-3">
                No custom styles yet
              </p>
              <p className="text-[12px] text-[#8e8e93]">
                You can override style per memory when generating a summary.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-2.5">
              {customStyles.map((style) => {
                const isFavorited = favoriteStyles.includes(style.id);
                return (
                  <div key={style.id} className="relative">
                    <button
                      onClick={() => {
                        setSelectedTemplateForDetail(style.id);
                        setShowTemplateDetail(true);
                      }}
                      className={`w-full relative bg-white rounded-[14px] p-3 shadow-[0_2px_8px_rgba(0,0,0,0.06)] border-2 text-left hover:shadow-[0_4px_12px_rgba(0,0,0,0.1)] transition-all ${
                        currentStyle === style.id ? 'border-[#007aff]' : 'border-transparent'
                      }`}
                    >
                      {/* Three dots menu button */}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setShowMenu(showMenu === style.id ? null : style.id);
                        }}
                        className="absolute top-2 right-2 w-6 h-6 flex items-center justify-center hover:bg-[#f2f2f7] rounded-full active:scale-95 transition-all"
                      >
                        <MoreVertical className="w-4 h-4 text-[#8e8e93]" strokeWidth={2} />
                      </button>
                      {/* Icon and Title in one row */}
                      <div className="flex items-center gap-2 mb-1.5">
                        <div className="w-7 h-7 rounded-full bg-[#f0f9ff] flex items-center justify-center flex-shrink-0">
                          <Sparkles className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
                        </div>
                        <h3 className="text-[15px] font-semibold text-[#1c1c1e] leading-tight pr-6">{style.title}</h3>
                      </div>
                      <p className="text-[12px] text-[#8e8e93] leading-[1.3] pl-9">
                        Custom style
                      </p>
                    </button>

                    {/* Dropdown Menu */}
                    {showMenu === style.id && (
                      <>
                        {/* Backdrop to close menu */}
                        <div
                          className="fixed inset-0 z-40"
                          onClick={() => setShowMenu(null)}
                        />
                        {/* Menu */}
                        <div className="absolute top-8 right-0 z-50 bg-white rounded-xl shadow-[0_8px_24px_rgba(0,0,0,0.15)] overflow-hidden min-w-[160px] border border-black/[0.08]">
                          <button
                            onClick={() => {
                              const updatedFavorites = isFavorited
                                ? favoriteStyles.filter((id) => id !== style.id)
                                : [...favoriteStyles, style.id];
                              setFavoriteStyles(updatedFavorites);
                              localStorage.setItem('favoriteSummaryStyles', JSON.stringify(updatedFavorites));
                              setShowMenu(null);
                            }}
                            className="w-full flex items-center gap-3 px-4 py-3 hover:bg-[#f2f2f7] active:bg-[#e5e5ea] transition-colors"
                          >
                            <Heart
                              className={`w-4 h-4 ${isFavorited ? 'text-[#ff3b30]' : 'text-[#8e8e93]'}`}
                              fill={isFavorited ? 'currentColor' : 'none'}
                              strokeWidth={2}
                            />
                            <span className="text-[15px] text-[#1c1c1e]">
                              {isFavorited ? 'Unfavorite' : 'Favorite'}
                            </span>
                          </button>
                          <div className="border-t border-[#e5e5ea]" />
                          <button
                            onClick={() => {
                              setEditingStyle(style);
                              setShowCreatePage(true);
                              setShowMenu(null);
                            }}
                            className="w-full flex items-center gap-3 px-4 py-3 hover:bg-[#f2f2f7] active:bg-[#e5e5ea] transition-colors"
                          >
                            <Edit className="w-4 h-4 text-[#8e8e93]" strokeWidth={2} />
                            <span className="text-[15px] text-[#1c1c1e]">Edit style</span>
                          </button>
                          <div className="border-t border-[#e5e5ea]" />
                          <button
                            onClick={() => {
                              const updatedStyles = customStyles.filter((s) => s.id !== style.id);
                              setCustomStyles(updatedStyles);
                              localStorage.setItem('customSummaryStyles', JSON.stringify(updatedStyles));
                              // Also remove from favorites if present
                              const updatedFavorites = favoriteStyles.filter((id) => id !== style.id);
                              setFavoriteStyles(updatedFavorites);
                              localStorage.setItem('favoriteSummaryStyles', JSON.stringify(updatedFavorites));
                              setShowMenu(null);
                            }}
                            className="w-full flex items-center gap-3 px-4 py-3 hover:bg-[#fff5f5] active:bg-[#ffe5e5] transition-colors"
                          >
                            <Trash2 className="w-4 h-4 text-[#ff3b30]" strokeWidth={2} />
                            <span className="text-[15px] text-[#ff3b30]">Delete</span>
                          </button>
                        </div>
                      </>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* About Section - More compact */}
        <div className="pb-4 px-5">
          {/* Content removed */}
        </div>

        {/* Bottom spacing for safe area */}
        <div className="h-4" />
      </div>

      {/* Template Detail Modal */}
      {showTemplateDetail && (
        <TemplateDetailModal
          templateId={selectedTemplateForDetail}
          onClose={() => setShowTemplateDetail(false)}
          onUseStyle={(styleId) => {
            // Save as last used style
            localStorage.setItem('lastUsedSummaryStyle', styleId);
            onSelectStyle && onSelectStyle(styleId);
            setShowTemplateDetail(false);
            // Stay on the AI Summary Style page - don't call onBack()
          }}
          fromStylePage={true}
        />
      )}

      {/* Create Summary Style Page */}
      {showCreatePage && (
        <CreateSummaryStylePage
          onClose={() => {
            setShowCreatePage(false);
            setEditingStyle(null);
          }}
          onAddStyle={(styleData) => {
            if (editingStyle) {
              // Update existing style
              const updatedStyles = customStyles.map((s) =>
                s.id === styleData.id ? styleData : s
              );
              setCustomStyles(updatedStyles);
              localStorage.setItem('customSummaryStyles', JSON.stringify(updatedStyles));
            } else {
              // Add new style
              setCustomStyles([...customStyles, styleData]);
              localStorage.setItem('customSummaryStyles', JSON.stringify([...customStyles, styleData]));
            }
            setShowCreatePage(false);
            setEditingStyle(null);
          }}
          editingStyle={editingStyle}
        />
      )}
    </div>
  );
}