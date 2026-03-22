import { ChevronLeft, User, Crown, Database, HelpCircle, LogOut, ChevronRight, Mail, Shield, FileText, MessageCircle, Book, Trash2, Download, Lock, X, Check, Upload } from 'lucide-react';
import { useState } from 'react';
import { LoginModal } from './LoginModal';
import { useUser } from '../contexts/UserContext';
import { useDevMode } from '../contexts/DevModeContext';
import { DevModePanel } from './DevModePanel';

interface UserSettingsPageProps {
  onBack: () => void;
}

export function UserSettingsPage({ onBack }: UserSettingsPageProps) {
  const { user, isLoggedIn, logout } = useUser();
  const { isDevModeEnabled, setIsDevModeEnabled } = useDevMode();
  const [showLoginModal, setShowLoginModal] = useState(false);
  const [isSignUpMode, setIsSignUpMode] = useState(false);
  const [showSubscriptionPage, setShowSubscriptionPage] = useState(false);
  const [showDeleteAccountModal, setShowDeleteAccountModal] = useState(false);
  const [showClearCachePage, setShowClearCachePage] = useState(false);
  const [currentPlan, setCurrentPlan] = useState<'free' | 'pro' | 'premium' | 'ultra'>('free');
  const [showDevModePanel, setShowDevModePanel] = useState(false);
  const [versionClickCount, setVersionClickCount] = useState(0);
  const [showDiagnosticLogsModal, setShowDiagnosticLogsModal] = useState(false);
  const [isSubmittingLogs, setIsSubmittingLogs] = useState(false);
  const [showLogsSuccess, setShowLogsSuccess] = useState(false);

  // Mock user data
  const userData = {
    name: user.name || 'Alex Johnson',
    email: user.email || 'alex.johnson@email.com',
    memberSince: 'January 2024',
    storageUsed: '2.3 GB',
  };

  const handleLogin = () => {
    setShowLoginModal(false);
    setIsLoggedIn(true);
  };

  const handleSignUp = () => {
    setShowLoginModal(false);
    setIsLoggedIn(true);
  };

  const handleLogout = () => {
    logout();
  };

  const handleDeleteAccount = () => {
    setShowDeleteAccountModal(false);
    logout();
    // Additional cleanup logic would go here
  };

  const handleExportData = () => {
    // Export data logic
    console.log('Exporting user data...');
  };

  // If showing Clear Cache page, render that instead
  if (showClearCachePage) {
    return <ClearCachePage onBack={() => setShowClearCachePage(false)} />;
  }

  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {!showSubscriptionPage ? (
        <>
          {/* Header */}
          <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
            <button 
              onClick={onBack}
              className="text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
            </button>
            <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
              Account & Data
            </h1>
          </div>

          {/* Scrollable Content */}
          <div className="flex-1 overflow-y-auto px-5 pb-24">
            
            {/* User Account Section */}
            <div className="mt-4 mb-6">
              {isLoggedIn ? (
                // Logged In State
                <div className="bg-white rounded-[16px] p-5 shadow-sm border border-black/[0.06]">
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#007aff] to-[#0051d5] flex items-center justify-center shadow-md">
                      <User className="w-8 h-8 text-white" strokeWidth={2} />
                    </div>
                    <div className="flex-1">
                      <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-1">{userData.name}</h2>
                      <p className="text-[14px] text-[#8e8e93]">{userData.email}</p>
                      <p className="text-[13px] text-[#8e8e93] mt-0.5">Member since {userData.memberSince}</p>
                    </div>
                  </div>
                  <button
                    onClick={handleLogout}
                    className="w-full py-3 bg-[#f2f2f7] rounded-[12px] text-[#ff3b30] font-medium hover:bg-[#e5e5ea] transition-colors flex items-center justify-center gap-2"
                  >
                    <LogOut className="w-4 h-4" strokeWidth={2.5} />
                    Sign Out
                  </button>
                </div>
              ) : (
                // Not Logged In State
                <div className="bg-white rounded-[16px] p-6 shadow-sm border border-black/[0.06]">
                  <div className="flex flex-col items-center text-center mb-5">
                    <div className="w-16 h-16 rounded-full bg-[#f2f2f7] flex items-center justify-center mb-3">
                      <User className="w-8 h-8 text-[#8e8e93]" strokeWidth={2} />
                    </div>
                    <h2 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">Sign In to Your Account</h2>
                    <p className="text-[14px] text-[#8e8e93]">Access your data across all devices</p>
                  </div>
                  <div className="flex flex-col gap-3">
                    <button
                      onClick={() => {
                        setIsSignUpMode(false);
                        setShowLoginModal(true);
                      }}
                      className="w-full py-3 bg-[#007aff] rounded-[12px] text-white font-semibold hover:bg-[#0051d5] transition-colors"
                    >
                      Sign In
                    </button>
                    <button
                      onClick={() => {
                        setIsSignUpMode(true);
                        setShowLoginModal(true);
                      }}
                      className="w-full py-3 bg-[#f2f2f7] rounded-[12px] text-[#007aff] font-medium hover:bg-[#e5e5ea] transition-colors"
                    >
                      Create New Account
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Subscription Plan Section */}
            <div className="mb-4">
              <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Subscription</h3>
              <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06]">
                <button
                  onClick={() => setShowSubscriptionPage(true)}
                  className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors"
                >
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#ffd700] to-[#ffb700] flex items-center justify-center flex-shrink-0 shadow-sm">
                    <Crown className="w-5 h-5 text-white" strokeWidth={2.5} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">
                      {currentPlan === 'free' && 'Basic Plan'}
                      {currentPlan === 'pro' && 'Pro Plan'}
                      {currentPlan === 'premium' && 'Premium Plan'}
                      {currentPlan === 'ultra' && 'Ultra Plan'}
                    </h3>
                    <p className="text-[14px] text-[#8e8e93]">
                      {currentPlan === 'free' && 'Upgrade for more features'}
                      {currentPlan === 'pro' && 'Unlock premium features'}
                      {currentPlan === 'premium' && 'All features unlocked'}
                      {currentPlan === 'ultra' && 'Unlimited access to all features'}
                    </p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>
              </div>
            </div>

            {/* Data Management Section */}
            <div className="mb-4">
              <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Data Management</h3>
              <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06]">
                {/* Storage Usage */}
                <div className="px-5 py-4 border-b border-black/[0.06]">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#34c759] to-[#28a745] flex items-center justify-center flex-shrink-0 shadow-sm">
                      <Database className="w-5 h-5 text-white" strokeWidth={2.5} />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">Storage</h3>
                      <p className="text-[14px] text-[#8e8e93]">{userData.storageUsed} used</p>
                    </div>
                  </div>
                </div>

                {/* Clear Cache */}
                <button
                  onClick={() => setShowClearCachePage(true)}
                  className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                >
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#ff9500] to-[#ff8000] flex items-center justify-center flex-shrink-0 shadow-sm">
                    <Trash2 className="w-5 h-5 text-white" strokeWidth={2.5} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">Clear Cache</h3>
                    <p className="text-[14px] text-[#8e8e93]">Free up storage space</p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>

                {/* Delete Account */}
                <button
                  onClick={() => setShowDeleteAccountModal(true)}
                  className="w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors"
                >
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#ff3b30] to-[#d32f2f] flex items-center justify-center flex-shrink-0 shadow-sm">
                    <Trash2 className="w-5 h-5 text-white" strokeWidth={2.5} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[17px] font-semibold text-[#ff3b30] mb-0.5">Delete Account</h3>
                    <p className="text-[14px] text-[#8e8e93]">Permanently remove your data</p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>
              </div>
            </div>

            {/* Help Center Section */}
            <div className="mb-4">
              <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Help & Support</h3>
              <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06]">
                {/* FAQ */}
                <button
                  className="w-full px-5 py-3 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                >
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#ff9500] to-[#ff8000] flex items-center justify-center flex-shrink-0 shadow-sm">
                    <HelpCircle className="w-5 h-5 text-white" strokeWidth={2.5} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[17px] font-semibold text-[#1c1c1e]">FAQ</h3>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>

                {/* User Guide */}
                <button
                  className="w-full px-5 py-3 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                >
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#af52de] to-[#9b3fce] flex items-center justify-center flex-shrink-0 shadow-sm">
                    <Book className="w-5 h-5 text-white" strokeWidth={2.5} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[17px] font-semibold text-[#1c1c1e]">User Guide</h3>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>

                {/* Contact Support */}
                <button
                  className="w-full px-5 py-3 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                >
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#32ade6] to-[#1e96d4] flex items-center justify-center flex-shrink-0 shadow-sm">
                    <MessageCircle className="w-5 h-5 text-white" strokeWidth={2.5} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Contact Support</h3>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>

                {/* Terms & Privacy */}
                <button
                  className="w-full px-5 py-3 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors border-b border-black/[0.06]"
                >
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#8e8e93] to-[#636366] flex items-center justify-center flex-shrink-0 shadow-sm">
                    <FileText className="w-5 h-5 text-white" strokeWidth={2.5} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Terms & Privacy</h3>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>

                {/* Submit Diagnostic Logs */}
                <button
                  onClick={() => setShowDiagnosticLogsModal(true)}
                  className="w-full px-5 py-3 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors"
                >
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#5ac8fa] to-[#007aff] flex items-center justify-center flex-shrink-0 shadow-sm">
                    <Upload className="w-5 h-5 text-white" strokeWidth={2.5} />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-[17px] font-semibold text-[#1c1c1e]">Submit Diagnostic Logs</h3>
                  </div>
                  <ChevronRight className="w-5 h-5 text-[#c7c7cc] flex-shrink-0" strokeWidth={2.5} />
                </button>
              </div>
            </div>

            {/* App Version */}
            <div className="text-center py-4">
              <p
                className="text-[13px] text-[#8e8e93] cursor-pointer"
                onClick={() => {
                  const newCount = versionClickCount + 1;
                  setVersionClickCount(newCount);
                  if (newCount >= 5) {
                    setIsDevModeEnabled(true);
                    setShowDevModePanel(true);
                    setVersionClickCount(0); // Reset counter
                  }
                }}
              >
                MemoPin v1.0.0
              </p>
            </div>
          </div>

          {/* Login Modal */}
          {showLoginModal && (
            <LoginModal
              isOpen={showLoginModal}
              initialMode={isSignUpMode ? 'signup' : 'signin'}
              onClose={() => {
                setShowLoginModal(false);
                setIsSignUpMode(false);
              }}
            />
          )}

          {/* Delete Account Confirmation Modal */}
          {showDeleteAccountModal && (
            <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => setShowDeleteAccountModal(false)}>
              <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
                <button
                  onClick={() => setShowDeleteAccountModal(false)}
                  className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
                >
                  <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                </button>

                <div className="flex flex-col items-center text-center mb-6">
                  <div className="w-16 h-16 rounded-full bg-[#ff3b30]/10 flex items-center justify-center mb-4">
                    <Trash2 className="w-8 h-8 text-[#ff3b30]" strokeWidth={2} />
                  </div>
                  <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">Delete Account?</h3>
                  <p className="text-[15px] text-[#3c3c43]">
                    This action cannot be undone. All your memories, memos, and data will be permanently deleted.
                  </p>
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={() => setShowDeleteAccountModal(false)}
                    className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleDeleteAccount}
                    className="flex-1 py-3 bg-[#ff3b30] rounded-[12px] text-white font-semibold hover:bg-[#ff4d42] transition-colors"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Dev Mode Panel */}
          {showDevModePanel && (
            <DevModePanel
              onClose={() => setShowDevModePanel(false)}
            />
          )}

          {/* Diagnostic Logs Modal */}
          {showDiagnosticLogsModal && (
            <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => setShowDiagnosticLogsModal(false)}>
              <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
                <button
                  onClick={() => setShowDiagnosticLogsModal(false)}
                  className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
                >
                  <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
                </button>

                <div className="flex flex-col items-center text-center mb-6">
                  <div className="w-16 h-16 rounded-full bg-[#5ac8fa]/10 flex items-center justify-center mb-4">
                    <Upload className="w-8 h-8 text-[#5ac8fa]" strokeWidth={2} />
                  </div>
                  <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">Submit diagnostic logs?</h3>
                  <p className="text-[15px] text-[#3c3c43] leading-relaxed">
                    This will send technical logs from your device to help us investigate issues.
                  </p>
                  <p className="text-[15px] text-[#3c3c43] font-medium mt-2">
                    No recordings or memory content will be included.
                  </p>
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={() => setShowDiagnosticLogsModal(false)}
                    className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => {
                      setIsSubmittingLogs(true);
                      setShowDiagnosticLogsModal(false);
                      // Simulate log submission
                      setTimeout(() => {
                        setIsSubmittingLogs(false);
                        setShowLogsSuccess(true);
                        // Auto hide success message
                        setTimeout(() => {
                          setShowLogsSuccess(false);
                        }, 2000);
                      }, 1500);
                    }}
                    disabled={isSubmittingLogs}
                    className="flex-1 py-3 bg-[#007aff] rounded-[12px] text-white font-semibold hover:bg-[#0051d5] transition-colors disabled:opacity-50"
                  >
                    Submit
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Submitting Logs Overlay */}
          {isSubmittingLogs && (
            <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center">
              <div className="bg-white rounded-[24px] p-8 shadow-2xl flex flex-col items-center">
                <div className="w-16 h-16 rounded-full bg-[#5ac8fa]/10 flex items-center justify-center mb-4 animate-pulse">
                  <Upload className="w-8 h-8 text-[#5ac8fa]" strokeWidth={2.5} />
                </div>
                <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">Submitting logs...</h3>
                <p className="text-[14px] text-[#8e8e93]">Please wait</p>
              </div>
            </div>
          )}

          {/* Logs Success Toast */}
          {showLogsSuccess && (
            <div className="fixed bottom-24 left-0 right-0 flex items-center justify-center px-5 z-50 pointer-events-none">
              <div className="bg-[#34c759] text-white px-6 py-4 rounded-[16px] shadow-2xl flex items-center gap-3 animate-in slide-in-from-bottom-4 fade-in duration-300">
                <div className="w-6 h-6 rounded-full bg-white/20 flex items-center justify-center">
                  <Check className="w-4 h-4 text-white" strokeWidth={3} />
                </div>
                <span className="text-[15px] font-semibold">Logs submitted successfully!</span>
              </div>
            </div>
          )}
        </>
      ) : (
        /* Subscription Full Page */
        <>
          {/* Header */}
          <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
            <button 
              onClick={() => setShowSubscriptionPage(false)}
              className="text-[#007aff] hover:opacity-70 transition-opacity"
            >
              <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
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
                      <p className="text-[13px] text-[#8e8e93] mt-0.5">Try MemoPin risk-free</p>
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
        </>
      )}
    </div>
  );
}

// Clear Cache Page Component
function ClearCachePage({ onBack }: { onBack: () => void }) {
  const [showClearConfirm, setShowClearConfirm] = useState(false);
  const [selectedItems, setSelectedItems] = useState<string[]>([]);
  const [isClearing, setIsClearing] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);

  // Cache items with mock data
  const cacheItems = [
    { id: 'audio', name: 'Audio Cache', size: '850 MB', icon: '🎵', color: 'from-[#ff6b35] to-[#ff8c42]' },
    { id: 'images', name: 'Image Cache', size: '320 MB', icon: '🖼️', color: 'from-[#007aff] to-[#0051d5]' },
    { id: 'temp', name: 'Temporary Files', size: '125 MB', icon: '📄', color: 'from-[#af52de] to-[#9b3fce]' },
    { id: 'logs', name: 'App Logs', size: '45 MB', icon: '📝', color: 'from-[#34c759] to-[#28a745]' },
  ];

  const totalSize = '1.34 GB';

  const toggleItem = (id: string) => {
    setSelectedItems(prev => 
      prev.includes(id) ? prev.filter(item => item !== id) : [...prev, id]
    );
  };

  const selectAll = () => {
    setSelectedItems(cacheItems.map(item => item.id));
  };

  const deselectAll = () => {
    setSelectedItems([]);
  };

  const handleClearCache = () => {
    if (selectedItems.length === 0) return;
    setShowClearConfirm(true);
  };

  const confirmClear = () => {
    setIsClearing(true);
    setShowClearConfirm(false);
    
    // Simulate clearing
    setTimeout(() => {
      setIsClearing(false);
      setShowSuccess(true);
      setSelectedItems([]);
      
      // Auto hide success message
      setTimeout(() => {
        setShowSuccess(false);
      }, 2000);
    }, 1500);
  };

  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
        <button 
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          Clear Cache
        </h1>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto px-5 pb-24">
        {/* Page Title */}
        <div className="pt-3 pb-3 text-center">
          <h3 className="text-[22px] font-bold text-[#1c1c1e] mb-1">Manage Cache</h3>
          <p className="text-[14px] text-[#8e8e93]">Free up space by clearing cached data</p>
        </div>

        {/* Total Cache Size Card */}
        <div className="bg-white rounded-[16px] p-5 mb-4 shadow-sm border border-black/[0.06]">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#ff9500] to-[#ff8000] flex items-center justify-center flex-shrink-0 shadow-md">
                <Database className="w-6 h-6 text-white" strokeWidth={2.5} />
              </div>
              <div>
                <h4 className="text-[17px] font-semibold text-[#1c1c1e]">Total Cache</h4>
                <p className="text-[22px] font-bold text-[#ff9500] mt-1">{totalSize}</p>
              </div>
            </div>
          </div>
          <p className="text-[13px] text-[#8e8e93] text-center">
            Clearing cache will not delete your memories or data
          </p>
        </div>

        {/* Select All / Deselect All */}
        <div className="flex items-center justify-between mb-3 px-1">
          <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
            Cache Types
          </h3>
          <button
            onClick={() => selectedItems.length === cacheItems.length ? deselectAll() : selectAll()}
            className="text-[14px] font-medium text-[#007aff] hover:opacity-70 transition-opacity"
          >
            {selectedItems.length === cacheItems.length ? 'Deselect All' : 'Select All'}
          </button>
        </div>

        {/* Cache Items List */}
        <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06] mb-4">
          {cacheItems.map((item, index) => (
            <button
              key={item.id}
              onClick={() => toggleItem(item.id)}
              className={`w-full px-5 py-4 flex items-center gap-4 text-left hover:bg-black/[0.02] active:bg-black/[0.04] transition-colors ${
                index < cacheItems.length - 1 ? 'border-b border-black/[0.06]' : ''
              }`}
            >
              <div className={`w-10 h-10 rounded-full bg-gradient-to-br ${item.color} flex items-center justify-center flex-shrink-0 shadow-sm`}>
                <span className="text-[18px]">{item.icon}</span>
              </div>
              <div className="flex-1">
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-0.5">{item.name}</h3>
                <p className="text-[13px] text-[#8e8e93]">{item.size}</p>
              </div>
              <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0 transition-all ${
                selectedItems.includes(item.id) 
                  ? 'bg-[#007aff] border-[#007aff]' 
                  : 'bg-white border-[#c7c7cc]'
              }`}>
                {selectedItems.includes(item.id) && (
                  <Check className="w-3 h-3 text-white" strokeWidth={3} />
                )}
              </div>
            </button>
          ))}
        </div>

        {/* Clear Cache Button */}
        <button
          onClick={handleClearCache}
          disabled={selectedItems.length === 0 || isClearing}
          className={`w-full px-4 py-3.5 rounded-[13px] text-[17px] font-bold shadow-lg transition-all ${
            selectedItems.length === 0 || isClearing
              ? 'bg-[#e5e5ea] text-[#8e8e93] cursor-not-allowed'
              : 'bg-gradient-to-r from-[#ff9500] via-[#ff8c42] to-[#ff9500] bg-[length:200%_100%] text-white hover:bg-right hover:shadow-xl hover:scale-[1.02] active:scale-[0.98]'
          } duration-500`}
        >
          {isClearing ? 'Clearing...' : `Clear Selected (${selectedItems.length})`}
        </button>

        {/* Info Message */}
        <div className="mt-4 bg-[#007aff]/10 rounded-[12px] p-4 border border-[#007aff]/20">
          <p className="text-[13px] text-[#007aff] text-center leading-relaxed">
            ℹ️ Cache will be rebuilt automatically as you use the app
          </p>
        </div>
      </div>

      {/* Clear Confirmation Modal */}
      {showClearConfirm && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => setShowClearConfirm(false)}>
          <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
            <button
              onClick={() => setShowClearConfirm(false)}
              className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
            >
              <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
            </button>

            <div className="flex flex-col items-center text-center mb-6">
              <div className="w-16 h-16 rounded-full bg-[#ff9500]/10 flex items-center justify-center mb-4">
                <Trash2 className="w-8 h-8 text-[#ff9500]" strokeWidth={2} />
              </div>
              <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">Clear Cache?</h3>
              <p className="text-[15px] text-[#3c3c43]">
                This will free up space by removing {selectedItems.length} cache {selectedItems.length === 1 ? 'type' : 'types'}. Your memories and data will not be affected.
              </p>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setShowClearConfirm(false)}
                className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmClear}
                className="flex-1 py-3 bg-[#ff9500] rounded-[12px] text-white font-semibold hover:bg-[#ff8c42] transition-colors"
              >
                Clear
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Success Toast */}
      {showSuccess && (
        <div className="fixed bottom-24 left-0 right-0 flex items-center justify-center px-5 z-50 pointer-events-none">
          <div className="bg-[#34c759] text-white px-6 py-4 rounded-[16px] shadow-2xl flex items-center gap-3 animate-in slide-in-from-bottom-4 fade-in duration-300">
            <div className="w-6 h-6 rounded-full bg-white/20 flex items-center justify-center">
              <Check className="w-4 h-4 text-white" strokeWidth={3} />
            </div>
            <span className="text-[15px] font-semibold">Cache cleared successfully!</span>
          </div>
        </div>
      )}

      {/* Clearing Overlay */}
      {isClearing && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center">
          <div className="bg-white rounded-[24px] p-8 shadow-2xl flex flex-col items-center">
            <div className="w-16 h-16 rounded-full bg-[#ff9500]/10 flex items-center justify-center mb-4 animate-pulse">
              <Database className="w-8 h-8 text-[#ff9500]" strokeWidth={2.5} />
            </div>
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">Clearing Cache...</h3>
            <p className="text-[14px] text-[#8e8e93]">Please wait</p>
          </div>
        </div>
      )}
    </div>
  );
}