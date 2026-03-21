import { useState, useEffect } from 'react';
import { X, Mail, Lock, Eye, EyeOff, Loader2, Apple, CheckCircle, ArrowLeft } from 'lucide-react';
import { useUser } from '../contexts/UserContext';

interface LoginModalProps {
  isOpen: boolean;
  onClose: () => void;
  promptMessage?: string;
  initialMode?: 'signin' | 'signup';
}

export function LoginModal({ isOpen, onClose, promptMessage, initialMode = 'signin' }: LoginModalProps) {
  const { login, loginWithProvider } = useUser();
  const [isSignUp, setIsSignUp] = useState(initialMode === 'signup');
  const [isForgotPassword, setIsForgotPassword] = useState(false);
  const [resetEmailSent, setResetEmailSent] = useState(false);
  const [email, setEmail] = useState('');
  const [resetEmail, setResetEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [showTerms, setShowTerms] = useState(false);
  const [showPrivacy, setShowPrivacy] = useState(false);

  // Reset isSignUp when initialMode changes
  useEffect(() => {
    setIsSignUp(initialMode === 'signup');
  }, [initialMode]);

  if (!isOpen) return null;

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      // Simulate API call delay
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Call the UserContext login method
      await login(email, password);
      
      // Close modal on success
      onClose();
    } catch (err) {
      setError('Invalid email or password');
    } finally {
      setIsLoading(false);
    }
  };

  const handleProviderLogin = async (provider: 'apple' | 'google') => {
    setError('');
    setIsLoading(true);

    try {
      await loginWithProvider(provider);
      
      // Close modal on success
      onClose();
    } catch (err) {
      setError(`Failed to sign in with ${provider === 'apple' ? 'Apple' : 'Google'}`);
    } finally {
      setIsLoading(false);
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
      // Simulate password reset email
      await new Promise(resolve => setTimeout(resolve, 1500));
      setResetEmailSent(true);
    } catch (err) {
      setError('Failed to send reset email. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleBackToLogin = () => {
    setIsForgotPassword(false);
    setResetEmailSent(false);
    setResetEmail('');
    setError('');
  };

  const handleOpenForgotPassword = () => {
    setIsForgotPassword(true);
    setError('');
  };

  return (
    <div className="fixed inset-0 z-50 bg-white">
      {/* Header */}
      <div className="px-6 pt-16 pb-6 border-b border-black/[0.06] bg-white">
        {/* Back button for forgot password view */}
        {isForgotPassword && !resetEmailSent && (
          <button
            onClick={handleBackToLogin}
            className="absolute top-16 left-6 w-10 h-10 flex items-center justify-center rounded-full bg-[#f2f2f7] hover:bg-[#e5e5ea] transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2} />
          </button>
        )}
        
        <div className="max-w-md mx-auto">
          <h2 className="text-[34px] font-bold text-[#1c1c1e] mb-2">
            {isForgotPassword 
              ? (resetEmailSent ? 'Check Your Email' : 'Reset Password')
              : (isSignUp ? 'Create Account' : 'Welcome to MemoPin')
            }
          </h2>
          
          {!isForgotPassword && !isSignUp && (
            <p className="text-[17px] text-[#8e8e93] leading-relaxed">
              Sign in to continue capturing and organizing your memories.
            </p>
          )}
          
          {!isForgotPassword && isSignUp && promptMessage && (
            <p className="text-[17px] text-[#8e8e93] leading-relaxed">
              Start capturing and organizing your memories.
            </p>
          )}
          
          {isForgotPassword && !resetEmailSent && (
            <p className="text-[17px] text-[#8e8e93] leading-relaxed">
              Enter your email and we'll send you a link to reset your password.
            </p>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-6 py-8">
        <div className="max-w-md mx-auto">
          {isForgotPassword ? (
            // Forgot Password View
            resetEmailSent ? (
              // Success State
              <div className="text-center py-8">
                <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-[#34c759] to-[#28a745] rounded-full flex items-center justify-center">
                  <CheckCircle className="w-9 h-9 text-white" strokeWidth={2.5} />
                </div>
                
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-2">
                  Reset Link Sent!
                </h3>
                
                <p className="text-[15px] text-[#8e8e93] leading-relaxed mb-6">
                  We've sent a password reset link to<br />
                  <span className="font-semibold text-[#1c1c1e]">{resetEmail}</span>
                </p>
                
                <div className="bg-[#f2f2f7] rounded-[14px] p-4 mb-6">
                  <p className="text-[13px] text-[#8e8e93] leading-relaxed">
                    Didn't receive the email? Check your spam folder or{' '}
                    <button
                      onClick={() => {
                        setResetEmailSent(false);
                        setError('');
                      }}
                      className="text-[#007aff] font-semibold hover:opacity-70 transition-opacity"
                    >
                      try again
                    </button>
                  </p>
                </div>
                
                <button
                  onClick={handleBackToLogin}
                  className="w-full py-3.5 bg-[#007aff] text-white rounded-[14px] font-semibold hover:bg-[#0051d5] transition-colors"
                >
                  Back to Sign In
                </button>
              </div>
            ) : (
              // Reset Form
              <form onSubmit={handleForgotPassword} className="space-y-4">
                <div>
                  <label className="block text-[15px] font-semibold text-[#1c1c1e] mb-2">
                    Email
                  </label>
                  <div className="relative">
                    <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
                    <input
                      type="email"
                      value={resetEmail}
                      onChange={(e) => setResetEmail(e.target.value)}
                      placeholder="your@email.com"
                      required
                      className="w-full pl-11 pr-4 py-3 bg-[#f2f2f7] border border-transparent rounded-[12px] text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:bg-white focus:border-[#007aff] transition-all"
                    />
                  </div>
                </div>

                {error && (
                  <div className="px-4 py-3 bg-[#ff3b30]/10 border border-[#ff3b30]/20 rounded-[12px]">
                    <p className="text-[13px] text-[#ff3b30]">{error}</p>
                  </div>
                )}

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-3.5 bg-[#007aff] text-white rounded-[14px] font-semibold hover:bg-[#0051d5] transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      <span>Sending Link...</span>
                    </>
                  ) : (
                    <span>Send Reset Link</span>
                  )}
                </button>
              </form>
            )
          ) : (
            // Login/Sign Up View
            <>
              {/* Social Login Buttons */}
              <div className="space-y-3 mb-6">
                <button
                  onClick={() => handleProviderLogin('apple')}
                  disabled={isLoading}
                  className="w-full flex items-center justify-center gap-3 px-4 py-3.5 bg-[#1c1c1e] text-white rounded-[14px] font-semibold hover:bg-[#2c2c2e] transition-colors disabled:opacity-50"
                >
                  <Apple className="w-5 h-5" fill="currentColor" strokeWidth={0} />
                  <span>Continue with Apple</span>
                </button>

                <button
                  onClick={() => handleProviderLogin('google')}
                  disabled={isLoading}
                  className="w-full flex items-center justify-center gap-3 px-4 py-3.5 bg-white border-2 border-[#e5e5ea] text-[#1c1c1e] rounded-[14px] font-semibold hover:bg-[#f9f9f9] transition-colors disabled:opacity-50"
                >
                  <svg className="w-5 h-5" viewBox="0 0 24 24">
                    <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                    <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                    <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                    <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                  </svg>
                  <span>Continue with Google</span>
                </button>
              </div>

              {/* Divider */}
              <div className="relative mb-6">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-black/[0.1]"></div>
                </div>
                <div className="relative flex justify-center text-[13px]">
                  <span className="px-3 bg-white text-[#8e8e93]">or</span>
                </div>
              </div>

              {/* Email Form */}
              <form onSubmit={handleEmailLogin} className="space-y-4">
                <div>
                  <label className="block text-[15px] font-semibold text-[#1c1c1e] mb-2">
                    Email
                  </label>
                  <div className="relative">
                    <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="your@email.com"
                      required
                      className="w-full pl-11 pr-4 py-3 bg-[#f2f2f7] border border-transparent rounded-[12px] text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:bg-white focus:border-[#007aff] transition-all"
                    />
                  </div>
                </div>

                <div>
                  <div className="flex items-center justify-between mb-2">
                    <label className="text-[15px] font-semibold text-[#1c1c1e]">
                      Password
                    </label>
                    {!isSignUp && (
                      <button
                        type="button"
                        onClick={handleOpenForgotPassword}
                        className="text-[13px] text-[#007aff] hover:opacity-70 transition-opacity font-medium"
                      >
                        Forgot Password?
                      </button>
                    )}
                  </div>
                  <div className="relative">
                    <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
                    <input
                      type={showPassword ? 'text' : 'password'}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Enter your password"
                      required
                      className="w-full pl-11 pr-11 py-3 bg-[#f2f2f7] border border-transparent rounded-[12px] text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] focus:outline-none focus:bg-white focus:border-[#007aff] transition-all"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#8e8e93] hover:text-[#1c1c1e] transition-colors"
                    >
                      {showPassword ? (
                        <EyeOff className="w-5 h-5" strokeWidth={2} />
                      ) : (
                        <Eye className="w-5 h-5" strokeWidth={2} />
                      )}
                    </button>
                  </div>
                </div>

                {error && (
                  <div className="px-4 py-3 bg-[#ff3b30]/10 border border-[#ff3b30]/20 rounded-[12px]">
                    <p className="text-[13px] text-[#ff3b30]">{error}</p>
                  </div>
                )}

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-3.5 bg-[#007aff] text-white rounded-[14px] font-semibold hover:bg-[#0051d5] transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {isLoading ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      <span>{isSignUp ? 'Creating Account...' : 'Signing In...'}</span>
                    </>
                  ) : (
                    <span>{isSignUp ? 'Create Account' : 'Sign In'}</span>
                  )}
                </button>
              </form>

              {/* Toggle Sign Up / Sign In */}
              <div className="mt-6 text-center">
                <button
                  onClick={() => setIsSignUp(!isSignUp)}
                  className="text-[15px] text-[#007aff] hover:opacity-70 transition-opacity"
                >
                  {isSignUp ? (
                    <>Already have an account? <span className="font-semibold">Sign In</span></>
                  ) : (
                    <>Don't have an account? <span className="font-semibold">Sign Up</span></>
                  )}
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {/* Footer */}
      <div className="px-6 py-4 border-t border-black/[0.06] bg-[#f9f9f9]">
        <p className="text-[11px] text-center text-[#8e8e93] leading-relaxed">
          By continuing, you agree to MemoPin's{' '}
          <button
            onClick={() => setShowTerms(true)}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            Terms of Service
          </button>
          {' '}and{' '}
          <button
            onClick={() => setShowPrivacy(true)}
            className="text-[#007aff] hover:opacity-70 transition-opacity"
          >
            Privacy Policy
          </button>
        </p>
      </div>

      {/* Terms of Service Modal */}
      {showTerms && (
        <div className="fixed inset-0 z-[60] bg-white flex flex-col">
          {/* Header */}
          <div className="px-6 pt-16 pb-6 border-b border-black/[0.06] bg-white">
            <button
              onClick={() => setShowTerms(false)}
              className="absolute top-16 right-6 w-10 h-10 flex items-center justify-center rounded-full bg-[#f2f2f7] hover:bg-[#e5e5ea] transition-colors"
            >
              <X className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2} />
            </button>
            
            <div className="max-w-2xl mx-auto">
              <h2 className="text-[34px] font-bold text-[#1c1c1e] mb-2">
                MemoPin Terms of Service
              </h2>
              <p className="text-[15px] text-[#8e8e93]">
                Last updated: Jan 19 2026
              </p>
            </div>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-y-auto px-6 py-8">
            <div className="max-w-2xl mx-auto space-y-6">
              <div>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  Welcome to MemoPin. These Terms of Service ("Terms") govern your use of the MemoPin mobile application, devices, and related services (collectively, the "Service"), provided by MeetSummer Technology Limited ("we", "our", or "us").
                </p>
              </div>

              <div>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  By accessing or using MemoPin, you agree to these Terms. If you do not agree, please do not use the Service.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  1. Description of the Service
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  MemoPin is an AI-powered memory companion that helps users capture, organize, and recall conversations and thoughts. The Service may include audio recording, transcription, summarization, AI-generated insights, and cloud-based synchronization features.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  2. Eligibility
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  You must be at least 13 years old (or the minimum legal age in your jurisdiction) to use MemoPin. By using the Service, you represent that you meet this requirement.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  3. User Responsibilities
                </h3>
                
                <div className="mb-4">
                  <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">
                    3.1 Lawful Use & Recording Consent
                  </h4>
                  <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                    You are solely responsible for how you use MemoPin.
                  </p>
                  <ul className="list-disc pl-5 space-y-1.5">
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      You must comply with all applicable laws and regulations when recording audio.
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      In many jurisdictions, recording conversations requires the consent of one or more participants.
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      MemoPin does not guarantee that your use of the Service complies with local recording laws.
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      You are responsible for obtaining any required consent before recording.
                    </li>
                  </ul>
                </div>

                <div>
                  <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">
                    3.2 Account Security
                  </h4>
                  <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.
                  </p>
                </div>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  4. AI-Generated Content Disclaimer
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  MemoPin may provide AI-generated transcripts, summaries, action items, or insights.
                </p>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    AI-generated content may be incomplete, inaccurate, or incorrect.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Such content is provided for informational and organizational purposes only.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    MemoPin does not provide legal, medical, financial, or professional advice.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    You remain solely responsible for decisions made based on AI-generated content.
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  5. Data & Privacy
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  Your use of the Service is subject to our Privacy Policy, which explains how we collect, use, and protect your data.
                </p>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  You retain ownership of your content. We process your data only to provide and improve the Service.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  6. Devices, Availability & Changes
                </h3>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    MemoPin devices, software, and services may evolve over time.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Features may be added, modified, or removed.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    The Service may be temporarily unavailable due to maintenance, updates, or technical issues.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    We do not guarantee uninterrupted or error-free operation of the Service.
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  7. Beta & Experimental Features
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  Some features may be labeled as beta or experimental.
                </p>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    These features are provided "as is"
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    They may contain bugs or inaccuracies
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    They may change or be discontinued at any time
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  8. Limitation of Liability
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  To the maximum extent permitted by law:
                </p>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    MemoPin shall not be liable for any indirect, incidental, or consequential damages
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    MemoPin shall not be responsible for loss of data, recordings, or AI-generated content
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    MemoPin's total liability shall not exceed the amount you paid to use the Service (if any)
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  9. Termination
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  We may suspend or terminate your access to the Service if you violate these Terms or misuse the Service.
                </p>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  You may stop using MemoPin at any time and request deletion of your account and data in accordance with our Privacy Policy.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  10. Governing Law
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  These Terms shall be governed by and construed in accordance with the laws of [Jurisdiction to be specified], without regard to conflict of law principles.
                </p>
              </div>

              <div className="bg-[#f2f2f7] rounded-[14px] p-4">
                <h3 className="text-[17px] font-bold text-[#1c1c1e] mb-3">
                  11. Contact Us
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  If you have questions about these Terms, please contact us:
                </p>
                <div className="space-y-1">
                  <p className="text-[15px] text-[#1c1c1e]">
                    <span className="font-semibold">Company:</span> MeetSummer Technology Limited
                  </p>
                  <p className="text-[15px] text-[#1c1c1e]">
                    <span className="font-semibold">Product:</span> MemoPin
                  </p>
                  <p className="text-[15px] text-[#1c1c1e]">
                    <span className="font-semibold">Email:</span>{' '}
                    <a href="mailto:support@memopin.ai" className="text-[#007aff] hover:opacity-70 transition-opacity">
                      support@memopin.ai
                    </a>
                  </p>
                  <p className="text-[15px] text-[#1c1c1e]">
                    <span className="font-semibold">Website:</span>{' '}
                    <a href="https://www.memopin.ai" target="_blank" rel="noopener noreferrer" className="text-[#007aff] hover:opacity-70 transition-opacity">
                      https://www.memopin.ai
                    </a>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Privacy Policy Modal */}
      {showPrivacy && (
        <div className="fixed inset-0 z-[60] bg-white flex flex-col">
          {/* Header */}
          <div className="px-6 pt-16 pb-6 border-b border-black/[0.06] bg-white">
            <button
              onClick={() => setShowPrivacy(false)}
              className="absolute top-16 right-6 w-10 h-10 flex items-center justify-center rounded-full bg-[#f2f2f7] hover:bg-[#e5e5ea] transition-colors"
            >
              <X className="w-5 h-5 text-[#1c1c1e]" strokeWidth={2} />
            </button>
            
            <div className="max-w-2xl mx-auto">
              <h2 className="text-[34px] font-bold text-[#1c1c1e] mb-2">
                MemoPin Privacy Policy
              </h2>
              <p className="text-[15px] text-[#8e8e93]">
                Last updated: Jan 19 2026
              </p>
            </div>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-y-auto px-6 py-8">
            <div className="max-w-2xl mx-auto space-y-6">
              <div>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  MemoPin ("we", "our", or "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how the MemoPin mobile application and related services (the "Service") collect, use, and safeguard information.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  1. What MemoPin Is
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  MemoPin is an AI-powered memory companion designed to help users capture, organize, and recall important conversations and thoughts. The Service may include audio recording, transcription, summarization, and personal knowledge organization features.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  2. Information We Collect
                </h3>
                
                <div className="mb-4">
                  <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">
                    2.1 Audio Data (User-Initiated)
                  </h4>
                  <ul className="list-disc pl-5 space-y-1.5">
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      Audio recordings are collected only when you explicitly choose to record.
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      MemoPin does not record audio secretly or continuously without user awareness.
                    </li>
                  </ul>
                </div>

                <div className="mb-4">
                  <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">
                    2.2 Transcripts & AI-Generated Content
                  </h4>
                  <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                    Audio recordings may be transcribed and processed by AI to generate:
                  </p>
                  <ul className="list-disc pl-5 space-y-1.5">
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      Text transcripts
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      Summaries
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      Action items
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      Insights
                    </li>
                  </ul>
                  <p className="text-[15px] text-[#1c1c1e] leading-relaxed mt-2">
                    These outputs are associated with your account.
                  </p>
                </div>

                <div>
                  <h4 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">
                    2.3 Account & Basic Usage Information
                  </h4>
                  <ul className="list-disc pl-5 space-y-1.5">
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      Email address or login identifier
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      Device and app version information
                    </li>
                    <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                      Basic usage logs (e.g., feature usage, error logs)
                    </li>
                  </ul>
                  <p className="text-[15px] text-[#1c1c1e] leading-relaxed mt-2">
                    We do not collect contact lists, message content, photos, or unrelated personal files.
                  </p>
                </div>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  3. How We Use Your Information
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  We use your information solely to:
                </p>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Provide core MemoPin features (recording, transcription, summaries)
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Improve accuracy and performance of AI features
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Sync your data across your authorized devices
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Provide customer support and troubleshooting
                  </li>
                </ul>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mt-2">
                  We do not sell your personal data.
                </p>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  We do not use your data for advertising.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  4. Audio Recording & Consent
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  MemoPin is designed to respect local laws and social norms regarding recording:
                </p>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    You are responsible for ensuring appropriate consent from participants when recording conversations.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    MemoPin provides visible and intentional recording controls to prevent accidental recording.
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  5. Data Storage & Security
                </h3>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Your data may be stored securely on cloud servers to enable syncing and AI processing.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    We use industry-standard security practices, including encryption in transit and at rest where applicable.
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Access to user data is strictly limited and monitored.
                  </li>
                </ul>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  6. Data Ownership & Control
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  You own your data.
                </p>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  You can:
                </p>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    View, export, or delete your recordings and transcripts
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Delete your account and associated data at any time
                  </li>
                </ul>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mt-2">
                  Upon deletion, your data will be permanently removed from our systems within a reasonable timeframe, unless retention is required by law.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  7. Third-Party Services
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  To provide the Service, MemoPin may rely on trusted third-party providers for:
                </p>
                <ul className="list-disc pl-5 space-y-1.5">
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Cloud infrastructure
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    Speech-to-text processing
                  </li>
                  <li className="text-[15px] text-[#1c1c1e] leading-relaxed">
                    AI analysis
                  </li>
                </ul>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mt-2">
                  These providers are bound by contractual obligations to protect your data and may not use it for their own purposes.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  8. Children's Privacy
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  MemoPin is not intended for children under 13 (or the minimum age required by local law).
                </p>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  We do not knowingly collect personal data from children.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  9. International Users
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  Your data may be processed in countries outside your place of residence.
                </p>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  We take steps to ensure appropriate safeguards are in place for cross-border data transfers.
                </p>
              </div>

              <div>
                <h3 className="text-[20px] font-bold text-[#1c1c1e] mb-3">
                  10. Changes to This Policy
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  We may update this Privacy Policy from time to time.
                </p>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed">
                  If changes are material, we will notify you through the app or by other appropriate means.
                </p>
              </div>

              <div className="bg-[#f2f2f7] rounded-[14px] p-4">
                <h3 className="text-[17px] font-bold text-[#1c1c1e] mb-3">
                  11. Contact Us
                </h3>
                <p className="text-[15px] text-[#1c1c1e] leading-relaxed mb-2">
                  If you have any questions about this Privacy Policy or your data, please contact us:
                </p>
                <div className="space-y-1">
                  <p className="text-[15px] text-[#1c1c1e]">
                    <span className="font-semibold">Company:</span> MeetSummer Technology Limited
                  </p>
                  <p className="text-[15px] text-[#1c1c1e]">
                    <span className="font-semibold">Product:</span> MemoPin
                  </p>
                  <p className="text-[15px] text-[#1c1c1e]">
                    <span className="font-semibold">Email:</span>{' '}
                    <a href="mailto:support@memopin.ai" className="text-[#007aff] hover:opacity-70 transition-opacity">
                      support@memopin.ai
                    </a>
                  </p>
                  <p className="text-[15px] text-[#1c1c1e]">
                    <span className="font-semibold">Website:</span>{' '}
                    <a href="https://www.memopin.ai" target="_blank" rel="noopener noreferrer" className="text-[#007aff] hover:opacity-70 transition-opacity">
                      https://www.memopin.ai
                    </a>
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}