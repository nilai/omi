import { ChevronLeft, Check } from 'lucide-react';
import { useState } from 'react';

interface CreateSummaryStylePageProps {
  onClose: () => void;
  onAddStyle: (style: any) => void;
  editingStyle?: any;
}

export function CreateSummaryStylePage({ onClose, onAddStyle, editingStyle }: CreateSummaryStylePageProps) {
  const [name, setName] = useState(editingStyle?.title || '');
  const [aiRole, setAiRole] = useState(editingStyle?.config?.aiRole || '');
  const [customRole, setCustomRole] = useState('');
  const [focusAreas, setFocusAreas] = useState<string[]>(editingStyle?.config?.focusAreas || []);
  const [usagePurpose, setUsagePurpose] = useState<string[]>(editingStyle?.config?.usagePurpose || []);
  const [detailLevel, setDetailLevel] = useState(editingStyle?.config?.detailLevel || 'balanced');
  const [tone, setTone] = useState(editingStyle?.config?.tone || 'professional');
  const [extraInstruction, setExtraInstruction] = useState(editingStyle?.config?.extraInstruction || '');

  const aiRoleOptions = [
    { id: 'meeting-secretary', label: 'Meeting Secretary' },
    { id: 'project-manager', label: 'Project Manager' },
    { id: 'founder-advisor', label: 'Founder Advisor' },
    { id: 'sales-assistant', label: 'Sales Assistant' },
    { id: 'learning-coach', label: 'Learning Coach' },
    { id: 'custom', label: 'Custom role' },
  ];

  const focusAreasOptions = [
    { id: 'decisions', label: 'Decisions made' },
    { id: 'next-steps', label: 'Next steps' },
    { id: 'risks-blockers', label: 'Risks / blockers' },
    { id: 'key-insights', label: 'Key insights' },
    { id: 'progress-updates', label: 'Progress updates' },
    { id: 'open-questions', label: 'Open questions' },
    { id: 'learning-points', label: 'Learning points' },
    { id: 'key-quotes', label: 'Key quotes' },
    { id: 'timeline-milestones', label: 'Timeline & milestones' },
    { id: 'opportunities', label: 'Opportunities' },
  ];

  const usagePurposeOptions = [
    { id: 'follow-up', label: 'Follow-up & execution' },
    { id: 'decision-support', label: 'Decision support' },
    { id: 'client-update', label: 'Client update' },
    { id: 'learning-notes', label: 'Learning notes' },
    { id: 'personal-reflection', label: 'Personal reflection' },
  ];

  const detailLevelOptions = [
    { id: 'concise', label: 'Concise' },
    { id: 'balanced', label: 'Balanced' },
    { id: 'detailed', label: 'Detailed' },
  ];

  const toneOptions = [
    { id: 'professional', label: 'Professional' },
    { id: 'friendly', label: 'Friendly' },
    { id: 'direct', label: 'Direct' },
    { id: 'casual', label: 'Casual' },
  ];

  const toggleFocusArea = (id: string) => {
    if (focusAreas.includes(id)) {
      setFocusAreas(focusAreas.filter((a) => a !== id));
    } else if (focusAreas.length < 3) {
      setFocusAreas([...focusAreas, id]);
    }
  };

  const toggleUsagePurpose = (id: string) => {
    if (usagePurpose.includes(id)) {
      setUsagePurpose(usagePurpose.filter((p) => p !== id));
    } else if (usagePurpose.length < 2) {
      setUsagePurpose([...usagePurpose, id]);
    }
  };

  const handleSave = () => {
    if (!name.trim() || !aiRole) {
      return;
    }

    const styleData = {
      id: editingStyle?.id || `custom-${Date.now()}`,
      title: name,
      description: 'Custom style',
      isCustom: true,
      config: {
        aiRole: aiRole === 'custom' ? customRole : aiRole,
        focusAreas,
        usagePurpose,
        detailLevel,
        tone,
        extraInstruction,
      },
    };

    onAddStyle(styleData);
  };

  const canSave = name.trim() && (aiRole !== 'custom' || customRole.trim());

  return (
    <div className="fixed inset-0 bg-[#f2f2f7] z-50 flex flex-col">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-white border-b border-black/[0.06]">
        <button
          onClick={onClose}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          Create Summary Style
        </h1>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto">
        <div className="px-5 py-4 space-y-6">
          {/* Name Input */}
          <div>
            <label className="block text-[13px] font-semibold text-[#1c1c1e] mb-2">
              Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder='e.g. "Founder weekly sync"'
              className="w-full bg-white rounded-xl px-4 py-3 text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] border-2 border-transparent focus:border-[#007aff] outline-none transition-colors"
            />
          </div>

          {/* AI Role Section */}
          <div>
            <div className="mb-3">
              <h3 className="text-[13px] font-semibold text-[#1c1c1e] mb-1">
                1) AI Role <span className="text-[#ff3b30]">(required)</span>
              </h3>
              <p className="text-[13px] text-[#8e8e93]">
                Choose how AI should behave.
              </p>
            </div>
            <div className="bg-white rounded-2xl overflow-hidden">
              {aiRoleOptions.map((option, index) => (
                <div key={option.id}>
                  <button
                    onClick={() => setAiRole(option.id)}
                    className="w-full flex items-center gap-3 px-4 py-3.5 active:bg-[#f2f2f7] transition-colors"
                  >
                    <div
                      className="flex-shrink-0 w-5 h-5 rounded-full border-2 flex items-center justify-center"
                      style={{
                        borderColor: aiRole === option.id ? '#007aff' : '#c7c7cc',
                      }}
                    >
                      {aiRole === option.id && (
                        <div className="w-2.5 h-2.5 rounded-full bg-[#007aff]" />
                      )}
                    </div>
                    <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
                      {option.label}
                    </span>
                  </button>
                  {option.id === 'custom' && aiRole === 'custom' && (
                    <div className="px-4 pb-3.5">
                      <input
                        type="text"
                        value={customRole}
                        onChange={(e) => setCustomRole(e.target.value)}
                        placeholder='e.g. "Investor analyst for pitch prep"'
                        className="w-full bg-[#f2f2f7] rounded-xl px-4 py-2.5 text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] border-2 border-transparent focus:border-[#007aff] outline-none transition-colors"
                      />
                    </div>
                  )}
                  {index < aiRoleOptions.length - 1 && (
                    <div className="border-b border-[#e5e5ea]" />
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Focus Areas Section */}
          <div>
            <div className="mb-3">
              <h3 className="text-[13px] font-semibold text-[#1c1c1e] mb-1">
                2) Focus areas <span className="text-[#8e8e93]">(choose up to 3)</span>
              </h3>
              <p className="text-[12px] text-[#8e8e93]">
                {focusAreas.length} / 3 selected
              </p>
            </div>
            <div className="bg-white rounded-2xl overflow-hidden">
              {focusAreasOptions.map((option, index) => (
                <div key={option.id}>
                  <button
                    onClick={() => toggleFocusArea(option.id)}
                    disabled={!focusAreas.includes(option.id) && focusAreas.length >= 3}
                    className="w-full flex items-center gap-3 px-4 py-3.5 active:bg-[#f2f2f7] transition-colors disabled:opacity-40"
                  >
                    <div
                      className={`flex-shrink-0 w-5 h-5 rounded-sm flex items-center justify-center border-2 transition-colors ${
                        focusAreas.includes(option.id)
                          ? 'bg-[#007aff] border-[#007aff]'
                          : 'border-[#c7c7cc]'
                      }`}
                    >
                      {focusAreas.includes(option.id) && (
                        <svg width="12" height="10" viewBox="0 0 12 10" fill="none">
                          <path
                            d="M1 5L4.5 8.5L11 1.5"
                            stroke="white"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        </svg>
                      )}
                    </div>
                    <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
                      {option.label}
                    </span>
                  </button>
                  {index < focusAreasOptions.length - 1 && (
                    <div className="border-b border-[#e5e5ea]" />
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Usage Purpose Section */}
          <div>
            <div className="mb-3">
              <h3 className="text-[13px] font-semibold text-[#1c1c1e] mb-1">
                3) Usage purpose <span className="text-[#8e8e93]">(choose up to 2)</span>
              </h3>
              <p className="text-[12px] text-[#8e8e93]">
                {usagePurpose.length} / 2 selected
              </p>
            </div>
            <div className="bg-white rounded-2xl overflow-hidden">
              {usagePurposeOptions.map((option, index) => (
                <div key={option.id}>
                  <button
                    onClick={() => toggleUsagePurpose(option.id)}
                    disabled={!usagePurpose.includes(option.id) && usagePurpose.length >= 2}
                    className="w-full flex items-center gap-3 px-4 py-3.5 active:bg-[#f2f2f7] transition-colors disabled:opacity-40"
                  >
                    <div
                      className={`flex-shrink-0 w-5 h-5 rounded-sm flex items-center justify-center border-2 transition-colors ${
                        usagePurpose.includes(option.id)
                          ? 'bg-[#007aff] border-[#007aff]'
                          : 'border-[#c7c7cc]'
                      }`}
                    >
                      {usagePurpose.includes(option.id) && (
                        <svg width="12" height="10" viewBox="0 0 12 10" fill="none">
                          <path
                            d="M1 5L4.5 8.5L11 1.5"
                            stroke="white"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        </svg>
                      )}
                    </div>
                    <span className="flex-1 text-left text-[15px] text-[#1c1c1e]">
                      {option.label}
                    </span>
                  </button>
                  {index < usagePurposeOptions.length - 1 && (
                    <div className="border-b border-[#e5e5ea]" />
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Detail Level Section */}
          <div>
            <div className="mb-3">
              <h3 className="text-[13px] font-semibold text-[#1c1c1e]">4) Detail level</h3>
            </div>
            <div className="bg-white rounded-2xl overflow-hidden flex">
              {detailLevelOptions.map((option, index) => (
                <button
                  key={option.id}
                  onClick={() => setDetailLevel(option.id)}
                  className={`flex-1 py-3 text-[15px] font-medium transition-colors ${
                    detailLevel === option.id
                      ? 'bg-[#007aff] text-white'
                      : 'bg-white text-[#1c1c1e] active:bg-[#f2f2f7]'
                  } ${index === 0 ? 'rounded-l-2xl' : ''} ${
                    index === detailLevelOptions.length - 1 ? 'rounded-r-2xl' : ''
                  } ${index > 0 ? 'border-l border-[#e5e5ea]' : ''}`}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>

          {/* Tone Section */}
          <div>
            <div className="mb-3">
              <h3 className="text-[13px] font-semibold text-[#1c1c1e]">5) Tone</h3>
            </div>
            <div className="bg-white rounded-2xl overflow-hidden grid grid-cols-2 gap-px">
              {toneOptions.map((option) => (
                <button
                  key={option.id}
                  onClick={() => setTone(option.id)}
                  className={`py-3 text-[15px] font-medium transition-colors ${
                    tone === option.id
                      ? 'bg-[#007aff] text-white'
                      : 'bg-white text-[#1c1c1e] active:bg-[#f2f2f7]'
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>

          {/* Extra Instruction Section */}
          <div>
            <div className="mb-3">
              <h3 className="text-[13px] font-semibold text-[#1c1c1e]">
                Extra instruction <span className="text-[#8e8e93]">(optional)</span>
              </h3>
            </div>
            <textarea
              value={extraInstruction}
              onChange={(e) => setExtraInstruction(e.target.value)}
              placeholder='"Use short bullets. Highlight trade-offs."'
              rows={4}
              className="w-full bg-white rounded-xl px-4 py-3 text-[15px] text-[#1c1c1e] placeholder:text-[#8e8e93] border-2 border-transparent focus:border-[#007aff] outline-none resize-none transition-colors"
            />
          </div>

          {/* Save Button */}
          <div className="pb-4">
            <button
              onClick={handleSave}
              disabled={!canSave}
              className="w-full bg-[#007aff] text-white text-[17px] font-semibold py-3.5 rounded-xl shadow-sm active:opacity-80 transition-opacity disabled:opacity-40 disabled:active:opacity-40"
            >
              Save style
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}