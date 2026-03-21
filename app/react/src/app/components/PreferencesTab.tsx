import { Settings, User, ChevronRight, Check, X, Crown, Database, ChevronLeft, Sparkles, Users, Mic, UserCircle } from 'lucide-react';
import { useState } from 'react';
import { AISummaryStylePage } from './AISummaryStylePage';
import { ExpertModelsPage } from './ExpertModelsPage';
import { UserSettingsPage } from './UserSettingsPage';
import { VoiceprintRecognitionPage } from './VoiceprintRecognitionPage';
import { AIPersonalizationPage } from './AIPersonalizationPage';
import { SettingsPage } from './SettingsPage';
import { LoginModal } from './LoginModal';
import { LoginPromptModal } from './LoginPromptModal';

export function PreferencesTab() {
  const [showAISummaryStyle, setShowAISummaryStyle] = useState(false);
  const [showExpertModels, setShowExpertModels] = useState(false);
  const [showUserSettings, setShowUserSettings] = useState(false);
  const [showSubscriptionPage, setShowSubscriptionPage] = useState(false);
  const [showVoiceprintPage, setShowVoiceprintPage] = useState(false);
  const [showAIPersonalizationPage, setShowAIPersonalizationPage] = useState(false);
  const [showSettingsPage, setShowSettingsPage] = useState(false);
  const [currentSummaryStyle, setCurrentSummaryStyle] = useState('meeting-secretary');
  const [currentPlan, setCurrentPlan] = useState<'free' | 'pro' | 'premium' | 'ultra'>('free');
  
  // Preview states for login modals
  const [showPreviewLoginModal, setShowPreviewLoginModal] = useState(false);
  const [showPreviewPromptModal, setShowPreviewPromptModal] = useState(false);

  // Integration status with icons
  const integrations = [
    { name: 'Slack', connected: true, color: '#4A154B' },
    { name: 'Calendar', connected: false, color: '#EA4335' },
    { name: 'Notes', connected: true, color: '#FFD60A' },
  ];

  // If showing AI Summary Style page, render that instead
  if (showAISummaryStyle) {
    return (
      <AISummaryStylePage
        onBack={() => setShowAISummaryStyle(false)}
        currentStyle={currentSummaryStyle}
        onSelectStyle={(style) => {
          setCurrentSummaryStyle(style);
          // Optionally auto-close after selection
          // setShowAISummaryStyle(false);
        }}
      />
    );
  }

  // If showing Expert Models page, render that instead
  if (showExpertModels) {
    return (
      <ExpertModelsPage
        onBack={() => setShowExpertModels(false)}
      />
    );
  }

  // If showing User Settings page, render that instead
  if (showUserSettings) {
    return (
      <UserSettingsPage
        onBack={() => setShowUserSettings(false)}
      />
    );
  }

  // If showing Voiceprint Recognition page, render that instead
  if (showVoiceprintPage) {
    return (
      <VoiceprintRecognitionPage
        onBack={() => setShowVoiceprintPage(false)}
      />
    );
  }

  // If showing AIPersonalization page, render that instead
  if (showAIPersonalizationPage) {
    return (
      <AIPersonalizationPage
        onBack={() => setShowAIPersonalizationPage(false)}
      />
    );
  }

  // If showing Settings page, render that instead
  if (showSettingsPage) {
    return (
      <SettingsPage
        onBack={() => setShowSettingsPage(false)}
      />
    );
  }

  // If showing Subscription page, render that instead
  if (showSubscriptionPage) {
    return (
      <div className="h-full flex flex-col bg-[#f2f2f7]">
        {/* Header */}
        <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
          <button 
            onClick={() => setShowSubscriptionPage(false)}
            className="flex items-center gap-2 text-[#007aff] hover:opacity-70 transition-opacity"
          >
            <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
            <span className="text-[17px] font-medium">Back</span>
          </button>
          <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
            Subscription
          </h1>
        </div>

        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto px-5 pb-8">
          {/* Page Title */}
          <div className="pt-3 pb-3 text-center">
            <h3 className="text-[22px] font-bold text-[#1c1c1e] mb-1">Choose your MemoPin plan</h3>
            <p className="text-[14px] text-[#8e8e93]">Start simple. Upgrade anytime.</p>
          </div>

          {/* Current Plan Section */}
          <div className="mb-4">
            <div className="flex items-center justify-center mb-3">
              <div className="h-px bg-black/[0.1] flex-1"></div>
              <span className="px-4 text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">Current Plan</span>
              <div className="h-px bg-black/[0.1] flex-1"></div>
            </div>

            <div className="bg-white rounded-[16px] p-5 shadow-sm border border-black/[0.06]">
              <div className="flex items-center justify-between mb-3">
                <div>
                  <h4 className="text-[17px] font-semibold text-[#1c1c1e]">Free Plan</h4>
                  <p className="text-[13px] text-[#8e8e93]">$0/month</p>
                </div>
              </div>

              <div className="mb-3">
                <p className="text-[15px] font-medium text-[#1c1c1e] mb-1">300 Credits / month</p>
                
                {/* Progress Bar */}
                <div className="w-full h-2.5 bg-[#f2f2f7] rounded-full overflow-hidden mb-2">
                  <div 
                    className="h-full bg-gradient-to-r from-[#34c759] to-[#28a745] rounded-full transition-all duration-300"
                    style={{ width: '40%' }}
                  />
                </div>
                
                <div className="flex items-baseline justify-between">
                  <span className="text-[13px] text-[#8e8e93]">120 credits used this month</span>
                </div>
              </div>

              <p className="text-[12px] text-[#8e8e93] text-center">
                Credits reset monthly
              </p>

              <div className="mt-3 pt-3 border-t border-black/[0.06]">
                <p className="text-[13px] text-[#8e8e93] text-center">
                  Typical usage: 500–4000 credits/month
                </p>
              </div>
            </div>
          </div>

          {/* Plans Section */}
          <div className="mb-4">
            <div className="flex items-center justify-center mb-3">
              <div className="h-px bg-black/[0.1] flex-1"></div>
              <span className="px-4 text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">Plans</span>
              <div className="h-px bg-black/[0.1] flex-1"></div>
            </div>

            <div className="space-y-4">
              {/* FREE Plan */}
              <div className="bg-white rounded-[20px] p-5 shadow-sm border-2 border-[#34c759]">
                {/* Plan Header */}
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h4 className="text-[22px] font-bold text-[#1c1c1e]">FREE</h4>
                    <p className="text-[13px] text-[#8e8e93] mt-0.5">Get started with MemoPin</p>
                  </div>
                  <div className="text-right">
                    <span className="text-[26px] font-bold text-[#1c1c1e]">$0</span>
                    <span className="text-[15px] text-[#8e8e93]">/month</span>
                  </div>
                </div>

                {/* Credits */}
                <div className="mb-4 pb-4 border-b border-black/[0.06]">
                  <p className="text-[15px] font-semibold text-[#1c1c1e]">300 Credits / month</p>
                </div>

                {/* Features */}
                <ul className="space-y-2.5 mb-4">
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#34c759] mt-0.5 text-[17px]">✓</span>
                    <span>Recording</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#34c759] mt-0.5 text-[17px]">✓</span>
                    <span>AI Summary</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#34c759] mt-0.5 text-[17px]">✓</span>
                    <span>Ask AI</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#34c759] mt-0.5 text-[17px]">✓</span>
                    <span>Daily Insight</span>
                  </li>
                </ul>

                {/* Current Plan Button */}
                <div className="px-4 py-3 bg-[#f2f2f7] text-[#8e8e93] text-[16px] font-semibold rounded-[12px] text-center">
                  Current Plan
                </div>
              </div>

              {/* PRO Plan */}
              <div className="bg-white rounded-[20px] p-5 shadow-sm border border-black/[0.06]">
                {/* Plan Header */}
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h4 className="text-[22px] font-bold text-[#1c1c1e]">PRO</h4>
                    <p className="text-[13px] text-[#8e8e93] mt-0.5">For regular users</p>
                  </div>
                  <div className="text-right">
                    <span className="text-[26px] font-bold text-[#1c1c1e]">$10</span>
                    <span className="text-[15px] text-[#8e8e93]">/month</span>
                  </div>
                </div>

                {/* Credits */}
                <div className="mb-4 pb-4 border-b border-black/[0.06]">
                  <p className="text-[15px] font-semibold text-[#1c1c1e]">2000 Credits / month</p>
                </div>

                {/* Features */}
                <ul className="space-y-2.5 mb-4">
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#007aff] mt-0.5 text-[17px]">✓</span>
                    <span>Recording</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#007aff] mt-0.5 text-[17px]">✓</span>
                    <span>AI Summary</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#007aff] mt-0.5 text-[17px]">✓</span>
                    <span>Ask AI</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#007aff] mt-0.5 text-[17px]">✓</span>
                    <span>Daily Insight</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#007aff] mt-0.5 text-[17px]">✓</span>
                    <span>Weekly Insight</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#007aff] mt-0.5 text-[17px]">✓</span>
                    <span>Monthly Insight</span>
                  </li>
                </ul>

                {/* Upgrade Button */}
                <button
                  onClick={() => {
                    setCurrentPlan('pro');
                    setShowSubscriptionPage(false);
                  }}
                  className="w-full px-4 py-3.5 bg-[#007aff] text-white text-[17px] font-bold rounded-[13px] hover:bg-[#0051d5] transition-all shadow-md hover:shadow-lg hover:scale-[1.02] active:scale-[0.98]"
                >
                  Upgrade to Pro
                </button>
              </div>

              {/* PREMIUM Plan - Most Popular */}
              <div className="bg-white rounded-[20px] pt-8 px-5 pb-5 shadow-lg border-2 border-[#af52de] relative overflow-visible">
                {/* Most Popular Badge */}
                <div className="absolute -top-3.5 left-1/2 transform -translate-x-1/2 z-10">
                  <div className="px-4 py-1.5 bg-gradient-to-r from-[#ff6b35] via-[#ff8c42] to-[#ffa94d] rounded-full shadow-lg flex items-center justify-center">
                    <span className="text-[11px] font-bold text-white uppercase tracking-wide">Most Popular</span>
                  </div>
                </div>

                {/* Animated gradient background overlay */}
                <div className="absolute inset-0 bg-gradient-to-br from-[#af52de]/5 via-transparent to-[#ff6b35]/5 pointer-events-none rounded-[20px]"></div>
                
                {/* Glow effect */}
                <div className="absolute inset-0 rounded-[20px] bg-gradient-to-r from-[#af52de]/20 to-[#ff6b35]/20 blur-xl -z-10"></div>

                {/* Plan Header */}
                <div className="flex items-center justify-between mb-4 relative z-10">
                  <div>
                    <h4 className="text-[22px] font-bold text-[#1c1c1e]">PREMIUM</h4>
                    <p className="text-[13px] text-[#8e8e93] mt-0.5">Most users stay within this plan</p>
                  </div>
                  <div className="flex items-baseline gap-0.5">
                    <span className="text-[30px] font-bold text-[#1c1c1e] bg-gradient-to-r from-[#af52de] to-[#9b3fce] bg-clip-text text-transparent">$20</span>
                    <span className="text-[15px] text-[#8e8e93]">/month</span>
                  </div>
                </div>

                {/* Credits */}
                <div className="mb-4 pb-4 border-b border-black/[0.06]">
                  <p className="text-[15px] font-semibold text-[#1c1c1e]">6000 Credits / month</p>
                </div>

                {/* Features */}
                <ul className="space-y-2.5 mb-4">
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#af52de] mt-0.5 text-[17px]">✓</span>
                    <span>Recording</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#af52de] mt-0.5 text-[17px]">✓</span>
                    <span>AI Summary</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#af52de] mt-0.5 text-[17px]">✓</span>
                    <span>Ask AI</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#af52de] mt-0.5 text-[17px]">✓</span>
                    <span>Daily Insight</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#af52de] mt-0.5 text-[17px]">✓</span>
                    <span>Weekly Insight</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#af52de] mt-0.5 text-[17px]">✓</span>
                    <span>Monthly Insight</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#af52de] mt-0.5 text-[17px]">✓</span>
                    <span>Cross-memory Pattern Insights</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#af52de] mt-0.5 text-[17px]">✓</span>
                    <span>Expert AI Insights</span>
                  </li>
                </ul>

                {/* Upgrade Button */}
                <button
                  onClick={() => {
                    setCurrentPlan('premium');
                    setShowSubscriptionPage(false);
                  }}
                  className="w-full px-4 py-3.5 bg-gradient-to-r from-[#af52de] via-[#c86dd7] to-[#af52de] bg-[length:200%_100%] text-white text-[17px] font-bold rounded-[13px] hover:bg-right transition-all duration-500 shadow-lg hover:shadow-xl hover:scale-[1.02] active:scale-[0.98]"
                >
                  Upgrade to Premium
                </button>
              </div>

              {/* ULTRA Plan */}
              <div className="bg-white rounded-[20px] p-5 shadow-sm border border-black/[0.06]">
                {/* Plan Header */}
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h4 className="text-[22px] font-bold text-[#1c1c1e]">ULTRA</h4>
                    <p className="text-[13px] text-[#8e8e93] mt-0.5">For heavy daily users</p>
                  </div>
                  <div className="text-right">
                    <span className="text-[26px] font-bold text-[#1c1c1e]">$30</span>
                    <span className="text-[15px] text-[#8e8e93]">/month</span>
                  </div>
                </div>

                {/* Credits */}
                <div className="mb-4 pb-4 border-b border-black/[0.06]">
                  <p className="text-[15px] font-semibold text-[#1c1c1e]">9000 Credits / month</p>
                </div>

                {/* Features */}
                <ul className="space-y-2.5 mb-4">
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#ff9500] mt-0.5 text-[17px]">✓</span>
                    <span>Everything in Premium</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#ff9500] mt-0.5 text-[17px]">✓</span>
                    <span>Priority AI Processing</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#ff9500] mt-0.5 text-[17px]">✓</span>
                    <span>Fastest AI Responses</span>
                  </li>
                  <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                    <span className="text-[#ff9500] mt-0.5 text-[17px]">✓</span>
                    <span>Best Insight Generation</span>
                  </li>
                </ul>

                {/* Upgrade Button */}
                <button
                  onClick={() => {
                    setCurrentPlan('ultra');
                    setShowSubscriptionPage(false);
                  }}
                  className="w-full px-4 py-3.5 bg-[#ff9500] text-white text-[17px] font-bold rounded-[13px] hover:bg-[#e08600] transition-all shadow-md hover:shadow-lg hover:scale-[1.02] active:scale-[0.98]"
                >
                  Upgrade to Ultra
                </button>
              </div>
            </div>
          </div>

          {/* No surprises pricing section */}
          <div className="mb-4">
            <div className="bg-white rounded-[16px] p-5 shadow-sm border border-black/[0.06]">
              <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-3 text-center">No surprises pricing</h4>
              
              <ul className="space-y-2.5">
                <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                  <span className="text-[#34c759] mt-0.5 text-[17px]">•</span>
                  <span>Credits reset monthly</span>
                </li>
                <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                  <span className="text-[#34c759] mt-0.5 text-[17px]">•</span>
                  <span>Most users never hit limits</span>
                </li>
                <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                  <span className="text-[#34c759] mt-0.5 text-[17px]">•</span>
                  <span>Upgrade anytime</span>
                </li>
                <li className="text-[15px] text-[#3c3c43] flex items-start gap-3">
                  <span className="text-[#34c759] mt-0.5 text-[17px]">•</span>
                  <span>No hidden fees</span>
                </li>
              </ul>

              <button className="w-full mt-4 text-[#007aff] text-[15px] font-medium hover:opacity-70 transition-opacity">
                How credits work →
              </button>
            </div>
          </div>

          {/* Bottom Message */}
          <div className="pt-2 pb-2 text-center">
            <div className="h-px bg-black/[0.1] mb-4"></div>
            <p className="text-[14px] text-[#8e8e93] leading-relaxed">
              <span className="block">Recording captures the past.</span>
              <span className="block font-semibold text-[#1c1c1e] mt-1">Understanding shapes what happens next.</span>
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-3 pb-2 bg-white border-b border-black/[0.06]">
        <div className="flex items-center justify-between mb-2">
          <h1 className="text-[28px] font-bold tracking-tight">Preferences</h1>
          <div className="flex items-center gap-2.5">
            <button 
              onClick={() => setShowSettingsPage(true)}
              className="w-7 h-7 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
            >
              <Settings className="w-4.5 h-4.5" strokeWidth={2} />
            </button>
            <button 
              onClick={() => setShowUserSettings(true)}
              className="w-7 h-7 flex items-center justify-center text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
            >
              <User className="w-4.5 h-4.5" strokeWidth={2} />
            </button>
          </div>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Preview Login Buttons - For Development/Testing */}
        <div className="hidden px-5 pt-4 pb-3 bg-gradient-to-br from-[#f9f9f9] to-white border-b border-black/[0.06]">
          <div className="mb-2">
            <h2 className="text-[12px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              🎨 Login Preview (Dev)
            </h2>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setShowPreviewLoginModal(true)}
              className="flex-1 px-4 py-2.5 bg-gradient-to-r from-[#007aff] to-[#0051d5] text-white text-[13px] font-semibold rounded-[12px] hover:opacity-90 transition-opacity shadow-sm"
            >
              Login Modal
            </button>
            <button
              onClick={() => setShowPreviewPromptModal(true)}
              className="flex-1 px-4 py-2.5 bg-gradient-to-r from-[#5856d6] to-[#4841c4] text-white text-[13px] font-semibold rounded-[12px] hover:opacity-90 transition-opacity shadow-sm"
            >
              Prompt Modal
            </button>
          </div>
        </div>

        {/* Subscription Card - Most prominent */}
        <div className="px-5 pt-4 pb-3">
          <button
            onClick={() => setShowSubscriptionPage(true)}
            className="w-full bg-white rounded-[16px] p-4 shadow-sm border border-black/[0.06] hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors"
          >
            <div className="flex items-center gap-4">
              <div className="w-11 h-11 rounded-full bg-gradient-to-br from-[#ffd700] to-[#ffb700] flex items-center justify-center flex-shrink-0 shadow-sm">
                <Crown className="w-5.5 h-5.5 text-white" strokeWidth={2.5} />
              </div>
              <div className="flex-1 text-left">
                <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">
                  {currentPlan === 'free' && 'Basic Plan'}
                  {currentPlan === 'pro' && 'Pro Plan'}
                  {currentPlan === 'premium' && 'Premium Plan'}
                </h3>
                <p className="text-[14px] text-[#8e8e93]">
                  {currentPlan === 'free' && 'Upgrade for more features'}
                  {currentPlan === 'pro' && 'Unlock premium features'}
                  {currentPlan === 'premium' && 'All features unlocked'}
                </p>
              </div>
              <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
            </div>
          </button>
        </div>

        {/* AI Configuration Section */}
        <div className="pt-1 pb-3 px-5">
          <div className="mb-2.5">
            <h2 className="text-[12px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              AI Configuration
            </h2>
          </div>
          
          {/* AI Summary Style */}
          <button 
            onClick={() => setShowAISummaryStyle(true)}
            className="w-full bg-white rounded-[14px] p-3.5 mb-2 shadow-sm border border-black/[0.06] text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-all group"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#af52de] to-[#9b3fce] flex items-center justify-center flex-shrink-0 shadow-sm">
                <Sparkles className="w-5 h-5 text-white" strokeWidth={2.5} />
              </div>
              <div className="flex-1">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-0.5">AI Summary Style</h3>
                <p className="text-[13px] text-[#8e8e93]">Meeting secretary · Autopilot</p>
              </div>
              <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0 group-hover:translate-x-0.5 transition-transform" strokeWidth={2.5} />
            </div>
          </button>

          {/* Expert Models */}
          <button 
            onClick={() => setShowExpertModels(true)}
            className="w-full bg-white rounded-[14px] p-3.5 mb-2 shadow-sm border border-black/[0.06] text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-all group"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#007aff] to-[#0051d5] flex items-center justify-center flex-shrink-0 shadow-sm">
                <Users className="w-5 h-5 text-white" strokeWidth={2.5} />
              </div>
              <div className="flex-1">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-0.5">Expert Models</h3>
                <p className="text-[13px] text-[#8e8e93]">Specialized assistants</p>
              </div>
              <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0 group-hover:translate-x-0.5 transition-transform" strokeWidth={2.5} />
            </div>
          </button>

          {/* Voiceprint Recognition */}
          <button 
            onClick={() => setShowVoiceprintPage(true)}
            className="w-full bg-white rounded-[14px] p-3.5 mb-2 shadow-sm border border-black/[0.06] text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-all group"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#34c759] to-[#28a745] flex items-center justify-center flex-shrink-0 shadow-sm">
                <Mic className="w-5 h-5 text-white" strokeWidth={2.5} />
              </div>
              <div className="flex-1">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-0.5">Voiceprint Recognition</h3>
                <p className="text-[13px] text-[#8e8e93]">Speaker identification</p>
              </div>
              <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0 group-hover:translate-x-0.5 transition-transform" strokeWidth={2.5} />
            </div>
          </button>

          {/* AI Personalization */}
          <button 
            onClick={() => setShowAIPersonalizationPage(true)}
            className="w-full bg-white rounded-[14px] p-3.5 shadow-sm border border-black/[0.06] text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-all group"
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#af52de] to-[#9b3fce] flex items-center justify-center flex-shrink-0 shadow-sm">
                <UserCircle className="w-5 h-5 text-white" strokeWidth={2.5} />
              </div>
              <div className="flex-1">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-0.5">AI Personalization</h3>
                <p className="text-[13px] text-[#8e8e93]">Tailored AI experience</p>
              </div>
              <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0 group-hover:translate-x-0.5 transition-transform" strokeWidth={2.5} />
            </div>
          </button>
        </div>

        {/* Integrations Section - Enhanced grid layout */}
        <div className="pb-3 px-5">
          <div className="mb-2">
            <h2 className="text-[12px] font-semibold text-[#8e8e93] uppercase tracking-wide">
              Integrations
            </h2>
          </div>
          
          {/* Integration Cards Grid */}
          <div className="bg-gradient-to-br from-white to-[#fafafa] rounded-[14px] p-2.5 shadow-[0_1px_6px_rgba(0,0,0,0.05)] border border-black/[0.05]">
            <div className="flex items-end justify-between">
              <div className="grid grid-cols-3 gap-1.5 flex-1">
                {/* Google Calendar */}
                <button className="flex flex-col items-center gap-1 p-1.5 rounded-xl hover:bg-white/80 transition-all group">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[#4285f4] to-[#3367d6] flex items-center justify-center shadow-sm group-hover:shadow-md transition-shadow">
                    <span className="text-[14px]">📅</span>
                  </div>
                  <p className="text-[10px] font-medium text-[#1c1c1e]">Calendar</p>
                </button>

                {/* Notion */}
                <button className="flex flex-col items-center gap-1 p-1.5 rounded-xl hover:bg-white/80 transition-all group">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[#000000] to-[#2c2c2c] flex items-center justify-center shadow-sm group-hover:shadow-md transition-shadow">
                    <span className="text-[14px]">📝</span>
                  </div>
                  <p className="text-[10px] font-medium text-[#1c1c1e]">Notion</p>
                </button>

                {/* Tasks */}
                <button className="flex flex-col items-center gap-1 p-1.5 rounded-xl hover:bg-white/80 transition-all group">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[#ff9500] to-[#ff6b00] flex items-center justify-center shadow-sm group-hover:shadow-md transition-shadow">
                    <span className="text-[14px]">✓</span>
                  </div>
                  <p className="text-[10px] font-medium text-[#1c1c1e]">Tasks</p>
                </button>
              </div>

              {/* Manage integrations - Right corner */}
              <button className="flex items-center gap-1 px-2 py-1 text-[12px] font-medium text-[#007aff] hover:bg-white/80 rounded-lg transition-all ml-2 mb-1">
                <span>Manage</span>
                <ChevronRight className="w-3 h-3" strokeWidth={2.5} />
              </button>
            </div>
          </div>
        </div>

        {/* Footer Message - Compressed */}
        <div className="px-5 pb-6 pt-1">
          <div className="text-center border-t border-black/[0.06] pt-4">
            <p className="text-[12px] text-[#8e8e93] leading-relaxed">
              MemoPin helps you turn memory into meaning,
              <br />
              and meaning into action.
            </p>
          </div>
        </div>

        {/* Bottom spacing for safe area */}
        <div className="h-4" />
      </div>

      {/* Preview Modals */}
      <LoginModal
        isOpen={showPreviewLoginModal}
        onClose={() => setShowPreviewLoginModal(false)}
        promptMessage="Sign in to keep your memories safe and access them across devices."
      />

      <LoginPromptModal
        isOpen={showPreviewPromptModal}
        onClose={() => setShowPreviewPromptModal(false)}
        onLogin={() => {
          setShowPreviewPromptModal(false);
          setShowPreviewLoginModal(true);
        }}
        trigger="memory"
      />
    </div>
  );
}