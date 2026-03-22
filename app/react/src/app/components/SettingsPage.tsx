import { useState, useEffect } from 'react';
import { ChevronLeft, ChevronRight, Brain, Bell, Mic2 } from 'lucide-react';
import { LanguageSelector } from './LanguageSelector';
import { DailyInsightTimePicker } from './DailyInsightTimePicker';
import { WeeklyInsightTimePicker } from './WeeklyInsightTimePicker';
import { SilentHoursPicker } from './SilentHoursPicker';
import { ThreeOptionSelector } from './ThreeOptionSelector';
import { ConfirmDialog } from './ConfirmDialog';

interface SettingsPageProps {
  onBack: () => void;
}

const SETTINGS_STORAGE_KEY = 'memopin_settings';

interface SettingsData {
  transcribeAfterRecording: boolean;
  transcriptionLanguage: string;
  pushNotifications: boolean;
  dailyInsightTime: string;
  weeklyInsightTime: string;
  silentHours: string;
  recordingGain: 'Low' | 'Medium' | 'High';
  indicatorBrightness: 'Low' | 'Medium' | 'High';
}

const defaultSettings: SettingsData = {
  transcribeAfterRecording: true,
  transcriptionLanguage: 'English',
  pushNotifications: true,
  dailyInsightTime: '11:00 PM',
  weeklyInsightTime: 'Sun 10:00 AM',
  silentHours: '11:00 PM – 6:00 AM',
  recordingGain: 'Medium',
  indicatorBrightness: 'Medium'
};

const loadSettings = (): SettingsData => {
  try {
    const saved = localStorage.getItem(SETTINGS_STORAGE_KEY);
    if (saved) {
      return { ...defaultSettings, ...JSON.parse(saved) };
    }
  } catch (error) {
    console.error('Failed to load settings:', error);
  }
  return defaultSettings;
};

const saveSettings = (settings: SettingsData) => {
  try {
    localStorage.setItem(SETTINGS_STORAGE_KEY, JSON.stringify(settings));
  } catch (error) {
    console.error('Failed to save settings:', error);
  }
};

export function SettingsPage({ onBack }: SettingsPageProps) {
  const [settings, setSettings] = useState<SettingsData>(loadSettings);
  
  const [transcribeAfterRecording, setTranscribeAfterRecording] = useState(settings.transcribeAfterRecording);
  const [transcriptionLanguage, setTranscriptionLanguage] = useState(settings.transcriptionLanguage);
  const [pushNotifications, setPushNotifications] = useState(settings.pushNotifications);
  const [dailyInsightTime, setDailyInsightTime] = useState(settings.dailyInsightTime);
  const [weeklyInsightTime, setWeeklyInsightTime] = useState(settings.weeklyInsightTime);
  const [silentHours, setSilentHours] = useState(settings.silentHours);
  const [recordingGain, setRecordingGain] = useState<'Low' | 'Medium' | 'High'>(settings.recordingGain);
  const [indicatorBrightness, setIndicatorBrightness] = useState<'Low' | 'Medium' | 'High'>(settings.indicatorBrightness);

  // Modal states
  const [showLanguageSelector, setShowLanguageSelector] = useState(false);
  const [showDailyTimePicker, setShowDailyTimePicker] = useState(false);
  const [showWeeklyTimePicker, setShowWeeklyTimePicker] = useState(false);
  const [showSilentHoursPicker, setShowSilentHoursPicker] = useState(false);
  const [showRecordingGainSelector, setShowRecordingGainSelector] = useState(false);
  const [showBrightnessSelector, setShowBrightnessSelector] = useState(false);
  const [showTranscribeConfirmDialog, setShowTranscribeConfirmDialog] = useState(false);

  // Handler for transcribe toggle
  const handleTranscribeToggle = () => {
    if (!transcribeAfterRecording) {
      // Trying to turn ON, show confirmation dialog
      setShowTranscribeConfirmDialog(true);
    } else {
      // Turning OFF, just toggle directly
      setTranscribeAfterRecording(false);
    }
  };

  const handleEnableTranscribe = () => {
    setTranscribeAfterRecording(true);
    setShowTranscribeConfirmDialog(false);
  };

  // Auto-save whenever any setting changes
  useEffect(() => {
    const currentSettings: SettingsData = {
      transcribeAfterRecording,
      transcriptionLanguage,
      pushNotifications,
      dailyInsightTime,
      weeklyInsightTime,
      silentHours,
      recordingGain,
      indicatorBrightness
    };
    saveSettings(currentSettings);
  }, [
    transcribeAfterRecording,
    transcriptionLanguage,
    pushNotifications,
    dailyInsightTime,
    weeklyInsightTime,
    silentHours,
    recordingGain,
    indicatorBrightness
  ]);

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
          Settings
        </h1>
        <div className="w-5" />
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto px-5 pb-8">
        
        {/* AI Behavior Section */}
        <div className="mt-6 mb-6">
          <div className="flex items-center gap-2 mb-3">
            <Brain className="w-4.5 h-4.5 text-[#6366f1]" strokeWidth={2} />
            <h3 className="text-[13px] font-semibold text-[#6366f1] uppercase tracking-wide">
              AI Behavior
            </h3>
          </div>
          
          <div className="mb-2">
            <p className="text-[13px] text-[#8e8e93] leading-relaxed">
              Control how recordings are processed.
            </p>
          </div>

          <div className="bg-gradient-to-br from-[#eef2ff] to-[#e0e7ff] rounded-[14px] shadow-sm border border-[#c7d2fe]/30 overflow-hidden">
            <div className="bg-white/80 rounded-[14px] overflow-hidden backdrop-blur-sm">
              {/* Transcribe after recording */}
              <button
                onClick={handleTranscribeToggle}
                className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-white/60 active:bg-white/40 transition-colors border-b border-black/[0.06]"
              >
                <span className="text-[15px] text-[#1c1c1e]">Auto transcribe after recording</span>
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#8e8e93]">
                    {transcribeAfterRecording ? 'On' : 'Off'}
                  </span>
                  <ChevronRight className="w-4.5 h-4.5 text-[#c7c7cc]" strokeWidth={2.5} />
                </div>
              </button>

              {/* Transcription language */}
              <button
                onClick={() => setShowLanguageSelector(true)}
                className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-white/60 active:bg-white/40 transition-colors"
              >
                <span className="text-[15px] text-[#1c1c1e]">Transcription language</span>
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#8e8e93]">{transcriptionLanguage}</span>
                  <ChevronRight className="w-4.5 h-4.5 text-[#c7c7cc]" strokeWidth={2.5} />
                </div>
              </button>
            </div>
          </div>
        </div>

        {/* Notifications Section */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <Bell className="w-4.5 h-4.5 text-[#f97316]" strokeWidth={2} />
            <h3 className="text-[13px] font-semibold text-[#f97316] uppercase tracking-wide">
              Notifications
            </h3>
          </div>
          
          <div className="mb-2">
            <p className="text-[13px] text-[#8e8e93] leading-relaxed">
              Manage when MemoPin notifies you.
            </p>
          </div>

          <div className="bg-gradient-to-br from-[#fff7ed] to-[#ffedd5] rounded-[14px] shadow-sm border border-[#fed7aa]/30 overflow-hidden">
            <div className="bg-white/80 rounded-[14px] overflow-hidden backdrop-blur-sm">
              {/* Push notifications */}
              <button
                onClick={() => setPushNotifications(!pushNotifications)}
                className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-white/60 active:bg-white/40 transition-colors border-b border-black/[0.06]"
              >
                <span className="text-[15px] text-[#1c1c1e]">Push notifications</span>
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#8e8e93]">
                    {pushNotifications ? 'On' : 'Off'}
                  </span>
                  <ChevronRight className="w-4.5 h-4.5 text-[#c7c7cc]" strokeWidth={2.5} />
                </div>
              </button>

              {/* Daily Insight push time */}
              <button
                onClick={() => setShowDailyTimePicker(true)}
                className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-white/60 active:bg-white/40 transition-colors border-b border-black/[0.06]"
              >
                <span className="text-[15px] text-[#1c1c1e]">Daily Insight push time</span>
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#8e8e93]">{dailyInsightTime}</span>
                  <ChevronRight className="w-4.5 h-4.5 text-[#c7c7cc]" strokeWidth={2.5} />
                </div>
              </button>

              {/* Weekly Insight push time */}
              <button
                onClick={() => setShowWeeklyTimePicker(true)}
                className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-white/60 active:bg-white/40 transition-colors border-b border-black/[0.06]"
              >
                <span className="text-[15px] text-[#1c1c1e]">Weekly Insight push time</span>
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#8e8e93]">{weeklyInsightTime}</span>
                  <ChevronRight className="w-4.5 h-4.5 text-[#c7c7cc]" strokeWidth={2.5} />
                </div>
              </button>

              {/* Silent hours */}
              <button
                onClick={() => setShowSilentHoursPicker(true)}
                className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-white/60 active:bg-white/40 transition-colors"
              >
                <span className="text-[15px] text-[#1c1c1e]">Silent hours</span>
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#8e8e93]">{silentHours}</span>
                  <ChevronRight className="w-4.5 h-4.5 text-[#c7c7cc]" strokeWidth={2.5} />
                </div>
              </button>
            </div>
          </div>
        </div>

        {/* Device Settings Section */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-3">
            <Mic2 className="w-4.5 h-4.5 text-[#10b981]" strokeWidth={2} />
            <h3 className="text-[13px] font-semibold text-[#10b981] uppercase tracking-wide">
              Device Settings
            </h3>
          </div>
          
          <div className="mb-2">
            <p className="text-[13px] text-[#8e8e93] leading-relaxed">
              Adjust MemoPin hardware behavior.
            </p>
          </div>

          <div className="bg-gradient-to-br from-[#ecfdf5] to-[#d1fae5] rounded-[14px] shadow-sm border border-[#a7f3d0]/30 overflow-hidden">
            <div className="bg-white/80 rounded-[14px] overflow-hidden backdrop-blur-sm">
              {/* Recording gain */}
              <button
                onClick={() => setShowRecordingGainSelector(true)}
                className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-white/60 active:bg-white/40 transition-colors border-b border-black/[0.06]"
              >
                <span className="text-[15px] text-[#1c1c1e]">Recording gain</span>
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#8e8e93]">{recordingGain}</span>
                  <ChevronRight className="w-4.5 h-4.5 text-[#c7c7cc]" strokeWidth={2.5} />
                </div>
              </button>

              {/* Indicator light brightness */}
              <button
                onClick={() => setShowBrightnessSelector(true)}
                className="w-full px-4 py-3.5 flex items-center justify-between hover:bg-white/60 active:bg-white/40 transition-colors"
              >
                <span className="text-[15px] text-[#1c1c1e]">Indicator light brightness</span>
                <div className="flex items-center gap-2">
                  <span className="text-[15px] text-[#8e8e93]">{indicatorBrightness}</span>
                  <ChevronRight className="w-4.5 h-4.5 text-[#c7c7cc]" strokeWidth={2.5} />
                </div>
              </button>
            </div>
          </div>
        </div>

        {/* Bottom spacing for safe area */}
        <div className="h-4" />
      </div>

      {/* Modals */}
      {showLanguageSelector && (
        <LanguageSelector
          currentLanguage={transcriptionLanguage}
          onSelect={setTranscriptionLanguage}
          onClose={() => setShowLanguageSelector(false)}
        />
      )}

      {showDailyTimePicker && (
        <DailyInsightTimePicker
          currentTime={dailyInsightTime}
          onSelect={setDailyInsightTime}
          onClose={() => setShowDailyTimePicker(false)}
        />
      )}

      {showWeeklyTimePicker && (
        <WeeklyInsightTimePicker
          currentTime={weeklyInsightTime}
          onSelect={setWeeklyInsightTime}
          onClose={() => setShowWeeklyTimePicker(false)}
        />
      )}

      {showSilentHoursPicker && (
        <SilentHoursPicker
          currentRange={silentHours}
          onSelect={setSilentHours}
          onClose={() => setShowSilentHoursPicker(false)}
        />
      )}

      {showRecordingGainSelector && (
        <ThreeOptionSelector
          title="Recording Gain"
          description="Adjust the audio input sensitivity for recording"
          currentValue={recordingGain}
          onSelect={setRecordingGain}
          onClose={() => setShowRecordingGainSelector(false)}
        />
      )}

      {showBrightnessSelector && (
        <ThreeOptionSelector
          title="Indicator Light Brightness"
          description="Control how bright the device indicator light appears"
          currentValue={indicatorBrightness}
          onSelect={setIndicatorBrightness}
          onClose={() => setShowBrightnessSelector(false)}
        />
      )}

      {showTranscribeConfirmDialog && (
        <ConfirmDialog
          isOpen={showTranscribeConfirmDialog}
          title="Auto transcribe all recordings?"
          message="All recordings will be transcribed automatically and count toward your monthly transcription time."
          confirmText="Enable"
          cancelText="Cancel"
          onConfirm={handleEnableTranscribe}
          onCancel={() => setShowTranscribeConfirmDialog(false)}
        />
      )}
    </div>
  );
}