import { ChevronLeft, MessageCircle, User, Brain } from 'lucide-react';
import { useState, useEffect } from 'react';
import { ConfirmDialog } from './ConfirmDialog';

interface AIPersonalizationPageProps {
  onBack: () => void;
}

interface AIPersonalizationSettings {
  responseLength: 'short' | 'medium' | 'detailed';
  selectedTone: 'professional' | 'friendly' | 'casual' | 'direct';
  customStyle: string;
  userName: string;
  userRole: string;
  personalContext: string;
}

const STORAGE_KEY = 'ai_personalization_settings';

const getDefaultSettings = (): AIPersonalizationSettings => ({
  responseLength: 'medium',
  selectedTone: 'professional',
  customStyle: '',
  userName: '',
  userRole: '',
  personalContext: '',
});

const loadSettings = (): AIPersonalizationSettings => {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      return JSON.parse(saved);
    }
  } catch (error) {
    console.error('Failed to load settings:', error);
  }
  return getDefaultSettings();
};

const saveSettings = (settings: AIPersonalizationSettings) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
  } catch (error) {
    console.error('Failed to save settings:', error);
  }
};

export function AIPersonalizationPage({ onBack }: AIPersonalizationPageProps) {
  // Load initial settings from localStorage
  const [initialSettings] = useState<AIPersonalizationSettings>(loadSettings);
  
  const [responseLength, setResponseLength] = useState<'short' | 'medium' | 'detailed'>(initialSettings.responseLength);
  const [selectedTone, setSelectedTone] = useState<'professional' | 'friendly' | 'casual' | 'direct'>(initialSettings.selectedTone);
  const [customStyle, setCustomStyle] = useState(initialSettings.customStyle);
  const [userName, setUserName] = useState(initialSettings.userName);
  const [userRole, setUserRole] = useState(initialSettings.userRole);
  const [personalContext, setPersonalContext] = useState(initialSettings.personalContext);
  
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);

  const toneOptions = [
    { value: 'professional', label: 'Professional', description: 'Structured & formal' },
    { value: 'friendly', label: 'Friendly', description: 'Natural & supportive' },
    { value: 'casual', label: 'Casual', description: 'Relaxed & conversational' },
    { value: 'direct', label: 'Direct', description: 'Concise & to the point' }
  ];

  // Check if current settings differ from initial settings
  useEffect(() => {
    const hasChanges = 
      responseLength !== initialSettings.responseLength ||
      selectedTone !== initialSettings.selectedTone ||
      customStyle !== initialSettings.customStyle ||
      userName !== initialSettings.userName ||
      userRole !== initialSettings.userRole ||
      personalContext !== initialSettings.personalContext;
    
    setHasUnsavedChanges(hasChanges);
  }, [responseLength, selectedTone, customStyle, userName, userRole, personalContext, initialSettings]);

  const getCurrentSettings = (): AIPersonalizationSettings => ({
    responseLength,
    selectedTone,
    customStyle,
    userName,
    userRole,
    personalContext,
  });

  const handleSave = () => {
    const currentSettings = getCurrentSettings();
    saveSettings(currentSettings);
    setHasUnsavedChanges(false);
    // Update initial settings to current settings
    Object.assign(initialSettings, currentSettings);
  };

  const handleBack = () => {
    if (hasUnsavedChanges) {
      setShowConfirmDialog(true);
    } else {
      onBack();
    }
  };

  const handleDiscard = () => {
    setShowConfirmDialog(false);
    onBack();
  };

  const handleSaveAndExit = () => {
    handleSave();
    setShowConfirmDialog(false);
    onBack();
  };

  const handleCancel = () => {
    setShowConfirmDialog(false);
  };
  
  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-5 pb-4 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
        <button 
          onClick={handleBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          AI Personalization
        </h1>
        <button 
          onClick={handleSave}
          disabled={!hasUnsavedChanges}
          className={`text-[17px] font-semibold transition-opacity ${
            hasUnsavedChanges 
              ? 'text-[#007aff] hover:opacity-70' 
              : 'text-[#007aff]/40 cursor-not-allowed'
          }`}
        >
          Save
        </button>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto px-5 pb-8">
        {/* Page Description */}
        <div className="pt-5 pb-4">
          <h2 className="text-[22px] font-bold text-[#1c1c1e] mb-2">
            Make MemoPin work better for you.
          </h2>
        </div>

        {/* Communication Style Section */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <MessageCircle className="w-4.5 h-4.5 text-[#6366f1]" strokeWidth={2} />
            <h3 className="text-[13px] font-semibold text-[#6366f1] uppercase tracking-wide">
              Communication Style
            </h3>
          </div>

          <div className="bg-gradient-to-br from-[#eef2ff] to-[#e0e7ff] rounded-[14px] p-4 shadow-sm border border-[#c7d2fe]/30">
            {/* Response Length */}
            <div className="mb-4">
              <label className="text-[15px] font-semibold text-[#1c1c1e] mb-2.5 block">
                Response length
              </label>
              <div className="flex gap-2">
                <button
                  onClick={() => setResponseLength('short')}
                  className={`flex-1 py-2.5 px-3 rounded-[10px] text-[14px] font-medium transition-all ${
                    responseLength === 'short'
                      ? 'bg-[#007aff] text-white shadow-sm'
                      : 'bg-white text-[#1c1c1e] hover:bg-gray-50 shadow-sm'
                  }`}
                >
                  Short
                </button>
                <button
                  onClick={() => setResponseLength('medium')}
                  className={`flex-1 py-2.5 px-3 rounded-[10px] text-[14px] font-medium transition-all ${
                    responseLength === 'medium'
                      ? 'bg-[#007aff] text-white shadow-sm'
                      : 'bg-white text-[#1c1c1e] hover:bg-gray-50 shadow-sm'
                  }`}
                >
                  Medium
                </button>
                <button
                  onClick={() => setResponseLength('detailed')}
                  className={`flex-1 py-2.5 px-3 rounded-[10px] text-[14px] font-medium transition-all ${
                    responseLength === 'detailed'
                      ? 'bg-[#007aff] text-white shadow-sm'
                      : 'bg-white text-[#1c1c1e] hover:bg-gray-50 shadow-sm'
                  }`}
                >
                  Detailed
                </button>
              </div>
            </div>

            {/* Tone */}
            <div className="mb-4">
              <label className="text-[15px] font-semibold text-[#1c1c1e] mb-2.5 block">
                Tone
              </label>
              <div className="grid grid-cols-2 gap-2">
                {toneOptions.map((tone) => (
                  <button
                    key={tone.value}
                    onClick={() => setSelectedTone(tone.value as 'professional' | 'friendly' | 'casual' | 'direct')}
                    className={`py-2.5 px-3 rounded-[10px] text-left transition-all ${
                      selectedTone === tone.value
                        ? 'bg-[#007aff] text-white shadow-sm'
                        : 'bg-white text-[#1c1c1e] hover:bg-gray-50 shadow-sm'
                    }`}
                  >
                    <div className="flex flex-col gap-0.5">
                      <span className="text-[13px] font-semibold">{tone.label}</span>
                      <span className={`text-[11px] leading-tight ${
                        selectedTone === tone.value ? 'text-white/75' : 'text-[#8e8e93]'
                      }`}>
                        {tone.description}
                      </span>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {/* Custom Style */}
            <div>
              <label className="text-[15px] font-semibold text-[#1c1c1e] mb-2 block">
                Custom style <span className="text-[#8e8e93] font-normal">(optional)</span>
              </label>
              <p className="text-[13px] text-[#8e8e93] mb-2">
                Describe how you'd like MemoPin to respond...
              </p>
              <textarea
                value={customStyle}
                onChange={(e) => setCustomStyle(e.target.value)}
                placeholder="e.g., Use bullet points, keep it casual, focus on action items..."
                className="w-full px-3.5 py-2.5 bg-white border border-black/[0.06] rounded-[10px] text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:border-[#007aff] focus:ring-1 focus:ring-[#007aff] transition-all resize-none shadow-sm"
                rows={3}
              />
            </div>
          </div>
        </div>

        {/* About You Section */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <User className="w-4.5 h-4.5 text-[#f97316]" strokeWidth={2} />
            <h3 className="text-[13px] font-semibold text-[#f97316] uppercase tracking-wide">
              About You
            </h3>
          </div>

          <div className="bg-gradient-to-br from-[#fff7ed] to-[#ffedd5] rounded-[14px] p-4 shadow-sm border border-[#fed7aa]/30">
            {/* What should MemoPin call you */}
            <div className="mb-4">
              <label className="text-[15px] font-semibold text-[#1c1c1e] mb-2 block">
                What should MemoPin call you?
              </label>
              <input
                type="text"
                value={userName}
                onChange={(e) => setUserName(e.target.value)}
                placeholder="Enter your name or nickname"
                className="w-full px-3.5 py-2.5 bg-white border border-black/[0.06] rounded-[10px] text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:border-[#007aff] focus:ring-1 focus:ring-[#007aff] transition-all shadow-sm"
              />
            </div>

            {/* What do you do */}
            <div>
              <label className="text-[15px] font-semibold text-[#1c1c1e] mb-2 block">
                What do you do?
              </label>
              <input
                type="text"
                value={userRole}
                onChange={(e) => setUserRole(e.target.value)}
                placeholder="Founder, student, designer, etc."
                className="w-full px-3.5 py-2.5 bg-white border border-black/[0.06] rounded-[10px] text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:border-[#007aff] focus:ring-1 focus:ring-[#007aff] transition-all shadow-sm"
              />
            </div>
          </div>
        </div>

        {/* Personal Context Section */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <Brain className="w-4.5 h-4.5 text-[#10b981]" strokeWidth={2} />
            <h3 className="text-[13px] font-semibold text-[#10b981] uppercase tracking-wide">
              Personal Context
            </h3>
          </div>

          <div className="bg-gradient-to-br from-[#ecfdf5] to-[#d1fae5] rounded-[14px] p-4 shadow-sm border border-[#a7f3d0]/30">
            <label className="text-[15px] font-semibold text-[#1c1c1e] mb-2 block">
              Anything MemoPin should know to better support you?
            </label>
            
            {/* Examples */}
            <div className="mb-3 px-3 py-2.5 bg-white/60 rounded-[10px] shadow-sm">
              <p className="text-[13px] text-[#8e8e93] font-medium mb-1.5">Examples:</p>
              <ul className="space-y-1">
                <li className="text-[13px] text-[#8e8e93] flex items-start gap-1.5">
                  <span className="text-[#007aff] flex-shrink-0">•</span>
                  <span>I get overwhelmed easily</span>
                </li>
                <li className="text-[13px] text-[#8e8e93] flex items-start gap-1.5">
                  <span className="text-[#007aff] flex-shrink-0">•</span>
                  <span>Help me prioritize decisions</span>
                </li>
                <li className="text-[13px] text-[#8e8e93] flex items-start gap-1.5">
                  <span className="text-[#007aff] flex-shrink-0">•</span>
                  <span>Keep answers short and clear</span>
                </li>
              </ul>
            </div>

            <textarea
              value={personalContext}
              onChange={(e) => setPersonalContext(e.target.value)}
              placeholder="Share any context that helps AI understand your needs..."
              className="w-full px-3.5 py-2.5 bg-white border border-black/[0.06] rounded-[10px] text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:border-[#007aff] focus:ring-1 focus:ring-[#007aff] transition-all resize-none shadow-sm"
              rows={5}
            />
          </div>
        </div>

        {/* Footer Message */}
        <div className="pt-2 pb-4">
          <div className="h-px bg-black/[0.1] mb-4"></div>
          <p className="text-[13px] text-[#8e8e93] text-center leading-relaxed">
            MemoPin uses this information to improve responses and insights.
          </p>
        </div>
      </div>

      {/* Confirm Dialog */}
      {showConfirmDialog && (
        <ConfirmDialog
          title="Unsaved Changes"
          message="You have unsaved changes. Do you want to save them before leaving?"
          onConfirm={handleSaveAndExit}
          onCancel={handleCancel}
          onDiscard={handleDiscard}
        />
      )}
    </div>
  );
}