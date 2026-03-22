import { ChevronRight, User, Mail, Shield, LogOut, AlertCircle } from 'lucide-react';
import { useUser } from '../contexts/UserContext';

interface AccountSectionProps {
  onLoginClick: () => void;
}

export function AccountSection({ onLoginClick }: AccountSectionProps) {
  const { user, isLoggedIn, logout } = useUser();

  if (!isLoggedIn) {
    // Guest User - Show login prompt
    return (
      <div className="mb-8">
        <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide px-5 mb-3">
          Account
        </h3>
        
        {/* Login Prompt Card */}
        <div className="mx-5 bg-gradient-to-br from-[#007aff]/5 to-[#5856d6]/5 rounded-[14px] p-4 border border-[#007aff]/10">
          <div className="flex items-start gap-3 mb-3">
            <div className="w-10 h-10 rounded-full bg-[#007aff]/10 flex items-center justify-center flex-shrink-0">
              <Shield className="w-5 h-5 text-[#007aff]" strokeWidth={2} />
            </div>
            <div className="flex-1">
              <h4 className="text-[15px] font-semibold text-[#1c1c1e] mb-1">
                Protect Your Memories
              </h4>
              <p className="text-[13px] text-[#8e8e93] leading-relaxed">
                Your memories are currently stored only on this device. Sign in to back them up.
              </p>
            </div>
          </div>
          
          {/* Usage Stats for Guest */}
          {user.memoryCount > 0 && (
            <div className="mb-3 px-3 py-2.5 bg-white/60 rounded-[10px]">
              <p className="text-[13px] text-[#8e8e93] mb-1.5">You have:</p>
              <ul className="space-y-1">
                <li className="text-[13px] text-[#1c1c1e] flex items-center gap-1.5">
                  <span className="text-[#007aff]">•</span>
                  <span className="font-medium">{user.memoryCount}</span> {user.memoryCount === 1 ? 'memory' : 'memories'} stored locally
                </li>
              </ul>
            </div>
          )}
          
          <button
            onClick={onLoginClick}
            className="w-full py-3 bg-[#007aff] text-white rounded-[12px] font-semibold hover:bg-[#0051d5] transition-colors"
          >
            Sign In to Back Up
          </button>
        </div>
      </div>
    );
  }

  // Account User - Show account details
  return (
    <div className="mb-8">
      <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide px-5 mb-3">
        Account
      </h3>
      
      <div className="bg-white mx-5 rounded-[14px] shadow-sm border border-black/[0.06] overflow-hidden">
        {/* User Profile */}
        <div className="px-4 py-4 border-b border-black/[0.06]">
          <div className="flex items-center gap-3">
            <div className="w-14 h-14 rounded-full bg-gradient-to-br from-[#007aff] to-[#5856d6] flex items-center justify-center text-white text-[20px] font-semibold">
              {user.name?.[0]?.toUpperCase() || user.email?.[0]?.toUpperCase() || 'U'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[17px] font-semibold text-[#1c1c1e] truncate">
                {user.name || 'User'}
              </p>
              <p className="text-[13px] text-[#8e8e93] truncate">
                {user.email || 'No email'}
              </p>
            </div>
          </div>
        </div>

        {/* Account Info Items */}
        <button className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors border-b border-black/[0.06]">
          <div className="w-8 h-8 rounded-full bg-[#007aff]/10 flex items-center justify-center">
            <User className="w-4 h-4 text-[#007aff]" strokeWidth={2} />
          </div>
          <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
            Edit Profile
          </span>
          <ChevronRight className="w-5 h-5 text-[#c7c7cc]" strokeWidth={2} />
        </button>

        <button className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors border-b border-black/[0.06]">
          <div className="w-8 h-8 rounded-full bg-[#10b981]/10 flex items-center justify-center">
            <Mail className="w-4 h-4 text-[#10b981]" strokeWidth={2} />
          </div>
          <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
            Email Settings
          </span>
          <ChevronRight className="w-5 h-5 text-[#c7c7cc]" strokeWidth={2} />
        </button>

        <button className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-[#f9f9f9] active:bg-[#f2f2f7] transition-colors">
          <div className="w-8 h-8 rounded-full bg-[#f97316]/10 flex items-center justify-center">
            <Shield className="w-4 h-4 text-[#f97316]" strokeWidth={2} />
          </div>
          <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
            Privacy & Security
          </span>
          <ChevronRight className="w-5 h-5 text-[#c7c7cc]" strokeWidth={2} />
        </button>
      </div>

      {/* Cloud Sync Status */}
      <div className="mx-5 mt-4 px-4 py-3 bg-[#ecfdf5] border border-[#10b981]/20 rounded-[12px]">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-[#10b981] animate-pulse"></div>
          <p className="text-[13px] text-[#059669] font-medium">
            All data synced to cloud
          </p>
        </div>
      </div>

      {/* Logout Button */}
      <div className="mx-5 mt-6">
        <button
          onClick={logout}
          className="w-full flex items-center justify-center gap-2 py-3 bg-white border border-[#ff3b30]/20 text-[#ff3b30] rounded-[12px] font-medium hover:bg-[#ff3b30]/5 transition-colors"
        >
          <LogOut className="w-4.5 h-4.5" strokeWidth={2} />
          <span>Sign Out</span>
        </button>
      </div>
    </div>
  );
}
