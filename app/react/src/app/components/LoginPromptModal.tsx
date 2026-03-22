import { Shield, Cloud, Smartphone } from 'lucide-react';

interface LoginPromptModalProps {
  isOpen: boolean;
  onClose: () => void;
  onLogin: () => void;
  title?: string;
  message?: string;
  trigger?: 'memory' | 'askAI' | 'backup' | 'limit';
}

export function LoginPromptModal({ 
  isOpen, 
  onClose, 
  onLogin,
  title = 'Save your memories',
  message = 'Sign in to keep your memories safe and access them across devices.',
  trigger = 'memory'
}: LoginPromptModalProps) {
  if (!isOpen) return null;

  const getTriggerContent = () => {
    switch (trigger) {
      case 'memory':
        return {
          title: 'Save your memories',
          message: 'Sign in to keep your memories safe and access them across devices.',
          features: [
            { icon: Shield, text: 'Never lose your memories' },
            { icon: Cloud, text: 'Automatic cloud backup' },
            { icon: Smartphone, text: 'Access from any device' }
          ]
        };
      case 'askAI':
        return {
          title: 'Unlock AI Search',
          message: 'Sign in to search across all your memories with AI.',
          features: [
            { icon: Shield, text: 'Unlimited AI queries' },
            { icon: Cloud, text: 'Search across all memories' },
            { icon: Smartphone, text: 'Sync on all devices' }
          ]
        };
      case 'backup':
        return {
          title: 'Protect your data',
          message: 'Your memories are currently stored only on this device. Sign in to back them up.',
          features: [
            { icon: Shield, text: 'Secure cloud storage' },
            { icon: Cloud, text: 'Automatic backups' },
            { icon: Smartphone, text: 'Never lose your data' }
          ]
        };
      case 'limit':
        return {
          title: 'Continue using MemoPin',
          message: 'Create an account to keep recording and organizing your memories.',
          features: [
            { icon: Shield, text: 'Unlimited memories' },
            { icon: Cloud, text: 'Unlimited AI queries' },
            { icon: Smartphone, text: 'All features unlocked' }
          ]
        };
    }
  };

  const content = getTriggerContent();

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="relative w-full max-w-[380px] bg-white rounded-[24px] shadow-2xl overflow-hidden">
        {/* Gradient Header */}
        <div className="px-6 pt-8 pb-6 bg-gradient-to-br from-[#007aff] to-[#5856d6] text-white">
          <div className="w-16 h-16 mb-4 bg-white/20 backdrop-blur-sm rounded-[18px] flex items-center justify-center">
            <Shield className="w-8 h-8" strokeWidth={2} />
          </div>
          <h2 className="text-[24px] font-bold mb-2">
            {content.title}
          </h2>
          <p className="text-[15px] text-white/90 leading-relaxed">
            {content.message}
          </p>
        </div>

        {/* Features */}
        <div className="px-6 py-5 space-y-3.5">
          {content.features.map((feature, index) => (
            <div key={index} className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#f2f2f7] flex items-center justify-center flex-shrink-0">
                <feature.icon className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
              </div>
              <span className="text-[15px] text-[#1c1c1e]">{feature.text}</span>
            </div>
          ))}
        </div>

        {/* Actions */}
        <div className="px-6 pb-6 space-y-3">
          <button
            onClick={onLogin}
            className="w-full py-3.5 bg-[#007aff] text-white rounded-[14px] font-semibold hover:bg-[#0051d5] transition-colors"
          >
            Sign In
          </button>
          <button
            onClick={onClose}
            className="w-full py-3.5 bg-[#f2f2f7] text-[#1c1c1e] rounded-[14px] font-medium hover:bg-[#e5e5ea] transition-colors"
          >
            Not Now
          </button>
        </div>
      </div>
    </div>
  );
}
