import { ChevronLeft, ChevronRight, Briefcase, Palette, Wrench, Heart } from 'lucide-react';
import { useState } from 'react';
import { ExpertDetailPage } from './ExpertDetailPage';

interface ExpertModelsPageProps {
  onBack: () => void;
}

interface Expert {
  id: string;
  name: string;
  icon: any;
  description: string;
  enabled: boolean;
  iconBg: string;
  iconColor: string;
  enabledBg: string;
}

export function ExpertModelsPage({ onBack }: ExpertModelsPageProps) {
  const [experts, setExperts] = useState<Expert[]>([
    {
      id: 'business',
      name: 'Business',
      icon: Briefcase,
      description: 'Strategy, priorities, decisions',
      enabled: true,
      iconBg: 'bg-gradient-to-br from-blue-500 to-blue-600',
      iconColor: 'text-white',
      enabledBg: 'bg-gradient-to-br from-blue-50/80 to-white'
    },
    {
      id: 'creative',
      name: 'Creative',
      icon: Palette,
      description: 'Ideas, exploration, possibilities',
      enabled: false,
      iconBg: 'bg-gradient-to-br from-purple-500 to-purple-600',
      iconColor: 'text-white',
      enabledBg: 'bg-gradient-to-br from-purple-50/80 to-white'
    },
    {
      id: 'execution',
      name: 'Execution',
      icon: Wrench,
      description: 'Systems, delivery, dependencies',
      enabled: true,
      iconBg: 'bg-gradient-to-br from-green-500 to-green-600',
      iconColor: 'text-white',
      enabledBg: 'bg-gradient-to-br from-green-50/80 to-white'
    },
    {
      id: 'wellness',
      name: 'Wellness',
      icon: Heart,
      description: 'Energy, workload, sustainability',
      enabled: false,
      iconBg: 'bg-gradient-to-br from-pink-500 to-pink-600',
      iconColor: 'text-white',
      enabledBg: 'bg-gradient-to-br from-pink-50/80 to-white'
    }
  ]);

  const [selectedExpert, setSelectedExpert] = useState<Expert | null>(null);

  const toggleExpert = (id: string) => {
    setExperts(experts.map(expert => 
      expert.id === id ? { ...expert, enabled: !expert.enabled } : expert
    ));
  };

  // If viewing an expert detail page, render that instead
  if (selectedExpert) {
    return (
      <ExpertDetailPage
        expertId={selectedExpert.id}
        expertName={selectedExpert.name}
        enabled={selectedExpert.enabled}
        onBack={() => setSelectedExpert(null)}
        onToggle={() => {
          toggleExpert(selectedExpert.id);
          setSelectedExpert({
            ...selectedExpert,
            enabled: !selectedExpert.enabled
          });
        }}
      />
    );
  }

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] z-50 flex flex-col">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06] relative">
        <button 
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          Expert Models
        </h1>
        <div className="w-5" />
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Description */}
        <div className="px-5 pt-4 pb-3">
          <p className="text-[14px] text-[#3c3c43] leading-[1.4]">
            Choose how AI analyzes your memories and provides feedback.
          </p>
          <p className="text-[14px] text-[#3c3c43] leading-[1.4] mt-1">
            You can enable multiple experts.
          </p>
        </div>

        {/* Divider */}
        <div className="h-px bg-gradient-to-r from-transparent via-black/[0.08] to-transparent" />

        {/* Available Experts Section */}
        <div className="px-5 pt-4 pb-3">
          <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3">
            Available Experts
          </h2>

          <div className="space-y-2.5">
            {experts.map((expert) => {
              const Icon = expert.icon;
              return (
                <div
                  key={expert.id}
                  className={`rounded-xl border transition-all ${
                    expert.enabled
                      ? `${expert.enabledBg} border-black/[0.08] shadow-sm`
                      : 'bg-white border-black/[0.06]'
                  }`}
                >
                  <div className="p-3.5">
                    {/* Top row: Icon, Title, Description */}
                    <div className="flex items-start gap-2.5 mb-2.5">
                      <div className={`w-9 h-9 rounded-lg ${expert.iconBg} flex items-center justify-center shadow-md flex-shrink-0`}>
                        <Icon className={`w-5 h-5 ${expert.iconColor}`} strokeWidth={2} />
                      </div>
                      <div className="flex-1">
                        <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-0.5">
                          {expert.name}
                        </h3>
                        <p className="text-[13px] text-[#6c6c70] leading-[1.3]">
                          {expert.description}
                        </p>
                      </div>
                    </div>

                    {/* Bottom row: Status toggle and detail arrow */}
                    <div className="flex items-center justify-between pl-[44px]">
                      <button
                        onClick={() => toggleExpert(expert.id)}
                        className="flex items-center gap-1.5 hover:opacity-70 transition-opacity"
                      >
                        <span className={`text-[13px] font-medium ${expert.enabled ? 'text-[#34c759]' : 'text-[#8e8e93]'}`}>
                          {expert.enabled ? 'Enabled' : 'Disabled'}
                        </span>
                        {expert.enabled && (
                          <div className="w-3.5 h-3.5 rounded-full bg-[#34c759] flex items-center justify-center">
                            <svg width="8" height="6" viewBox="0 0 8 6" fill="none">
                              <path d="M1 3L2.5 4.5L7 0.5" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                            </svg>
                          </div>
                        )}
                      </button>

                      <button
                        className="p-0.5 hover:opacity-70 transition-opacity"
                        onClick={() => setSelectedExpert(expert)}
                      >
                        <ChevronRight className="w-5 h-5 text-[#8e8e93]" strokeWidth={2} />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Divider */}
        <div className="h-px bg-gradient-to-r from-transparent via-black/[0.08] to-transparent" />

        {/* Tip Section */}
        <div className="px-5 pt-4 pb-5">
          <div className="flex items-start gap-2.5 bg-blue-50/50 rounded-xl p-3.5 border border-blue-100/50">
            <div className="w-4 h-4 rounded-full bg-blue-500/10 flex items-center justify-center flex-shrink-0 mt-0.5">
              <span className="text-[11px] text-blue-600 font-semibold">i</span>
            </div>
            <div>
              <h4 className="text-[13px] font-semibold text-[#1c1c1e] mb-0.5">Tip</h4>
              <p className="text-[13px] text-[#3c3c43] leading-[1.4]">
                Experts change how insights are generated, not what gets recorded.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}