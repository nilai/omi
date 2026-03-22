import { ChevronLeft, Mic, Play, Trash2, X, Check, Plus, AlertCircle } from 'lucide-react';
import { useState, useEffect, useRef } from 'react';
import { useVoiceprints } from '../contexts/VoiceprintContext';

interface VoiceprintRecognitionPageProps {
  onBack: () => void;
}

export function VoiceprintRecognitionPage({ onBack }: VoiceprintRecognitionPageProps) {
  const { voiceprints, removeVoiceprint, addVoiceprint } = useVoiceprints();
  const [showRecordingModal, setShowRecordingModal] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const handleDeleteVoiceprint = (id: string) => {
    setDeleteId(id);
    setShowDeleteConfirm(true);
  };

  const confirmDelete = () => {
    if (deleteId) {
      removeVoiceprint(deleteId);
    }
    setShowDeleteConfirm(false);
    setDeleteId(null);
  };

  // Format date
  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
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
          Voiceprint Recognition
        </h1>
        <div className="w-5" />
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto px-5 pb-24">
        {/* Page Title */}
        <div className="pt-3 pb-3 text-center">
          <h3 className="text-[22px] font-bold text-[#1c1c1e] mb-1">Voice Profiles</h3>
          <p className="text-[14px] text-[#8e8e93]">Record 30-second samples to identify speakers</p>
        </div>

        {/* Info Card */}
        <div className="bg-gradient-to-br from-[#34c759]/10 to-[#28a745]/10 rounded-[16px] p-4 mb-4 border border-[#34c759]/20">
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#34c759] to-[#28a745] flex items-center justify-center flex-shrink-0 shadow-sm">
              <Mic className="w-5 h-5 text-white" strokeWidth={2.5} />
            </div>
            <div className="flex-1">
              <h4 className="text-[15px] font-semibold text-[#1c1c1e] mb-1">How it works</h4>
              <p className="text-[13px] text-[#3c3c43] leading-relaxed">
                Record a 30-second voice sample of each person. Our AI will use this to automatically identify speakers in your memories and populate the People section.
              </p>
            </div>
          </div>
        </div>

        {/* Add New Voiceprint Button */}
        <button
          onClick={() => setShowRecordingModal(true)}
          className="w-full bg-gradient-to-r from-[#34c759] to-[#28a745] rounded-[14px] p-4 mb-4 shadow-md hover:shadow-lg active:scale-[0.98] transition-all"
        >
          <div className="flex items-center justify-center gap-3">
            <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
              <Plus className="w-6 h-6 text-white" strokeWidth={2.5} />
            </div>
            <span className="text-[17px] font-bold text-white">Add New Voice Profile</span>
          </div>
        </button>

        {/* Voiceprints List */}
        {voiceprints.length > 0 ? (
          <div>
            <div className="mb-2.5 px-1">
              <h2 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">
                Saved Profiles ({voiceprints.length})
              </h2>
            </div>

            <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06]">
              {voiceprints.map((voiceprint, index) => (
                <div
                  key={voiceprint.id}
                  className={`px-5 py-4 ${index < voiceprints.length - 1 ? 'border-b border-black/[0.06]' : ''}`}
                >
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#34c759] to-[#28a745] flex items-center justify-center flex-shrink-0 shadow-sm">
                      <span className="text-[18px] text-white font-semibold">
                        {voiceprint.name.charAt(0).toUpperCase()}
                      </span>
                    </div>
                    <div className="flex-1">
                      <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-0.5">
                        {voiceprint.name}
                      </h3>
                      <p className="text-[13px] text-[#8e8e93]">
                        Recorded on {formatDate(new Date(voiceprint.createdAt))} · {voiceprint.duration}s
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        className="w-9 h-9 rounded-full bg-[#f2f2f7] hover:bg-[#e5e5ea] active:bg-[#d1d1d6] flex items-center justify-center transition-colors"
                      >
                        <Play className="w-4 h-4 text-[#34c759] ml-0.5" strokeWidth={2.5} fill="#34c759" />
                      </button>
                      <button
                        onClick={() => handleDeleteVoiceprint(voiceprint.id)}
                        className="w-9 h-9 rounded-full bg-[#ff3b30]/10 hover:bg-[#ff3b30]/20 active:bg-[#ff3b30]/30 flex items-center justify-center transition-colors"
                      >
                        <Trash2 className="w-4 h-4 text-[#ff3b30]" strokeWidth={2.5} />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div className="bg-white rounded-[16px] p-8 text-center shadow-sm border border-black/[0.06]">
            <div className="w-16 h-16 rounded-full bg-[#f2f2f7] flex items-center justify-center mx-auto mb-3">
              <Mic className="w-8 h-8 text-[#8e8e93]" strokeWidth={2} />
            </div>
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-1">No Voice Profiles Yet</h3>
            <p className="text-[14px] text-[#8e8e93]">
              Add your first profile to start identifying speakers
            </p>
          </div>
        )}
      </div>

      {/* Recording Modal */}
      {showRecordingModal && (
        <RecordingModal
          onClose={() => setShowRecordingModal(false)}
          onSave={(name: string) => {
            // This is already handled in MarkSpeakerModal, so this modal is just for manual recording
            // For now, we'll skip implementation as the main flow uses MarkSpeakerModal
            setShowRecordingModal(false);
          }}
        />
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={() => setShowDeleteConfirm(false)}>
          <div className="bg-white rounded-[24px] p-8 w-full max-w-sm shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
            <button
              onClick={() => setShowDeleteConfirm(false)}
              className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
            >
              <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
            </button>

            <div className="flex flex-col items-center text-center mb-6">
              <div className="w-16 h-16 rounded-full bg-[#ff3b30]/10 flex items-center justify-center mb-4">
                <Trash2 className="w-8 h-8 text-[#ff3b30]" strokeWidth={2} />
              </div>
              <h3 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">Delete Voice Profile?</h3>
              <p className="text-[15px] text-[#3c3c43]">
                This will remove the voice profile. Speaker identification for this person will no longer work.
              </p>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmDelete}
                className="flex-1 py-3 bg-[#ff3b30] rounded-[12px] text-white font-semibold hover:bg-[#ff4d42] transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Recording Modal Component
function RecordingModal({ onClose, onSave }: { onClose: () => void; onSave: (name: string) => void }) {
  const [recordingState, setRecordingState] = useState<'idle' | 'recording' | 'completed'>('idle');
  const [recordedTime, setRecordedTime] = useState(0);
  const [name, setName] = useState('');
  const [waveformBars, setWaveformBars] = useState<number[]>(Array(40).fill(0));
  const [warningMessage, setWarningMessage] = useState('');
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const waveformRef = useRef<NodeJS.Timeout | null>(null);
  const { addVoiceprint } = useVoiceprints();

  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      if (waveformRef.current) clearInterval(waveformRef.current);
    };
  }, []);

  const startRecording = () => {
    setRecordingState('recording');
    setRecordedTime(0);

    // Start counting up timer
    timerRef.current = setInterval(() => {
      setRecordedTime((prev) => prev + 1);
    }, 1000);

    // Start waveform animation
    waveformRef.current = setInterval(() => {
      setWaveformBars(Array(40).fill(0).map(() => Math.random()));
    }, 100);
  };

  const stopRecording = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    if (waveformRef.current) clearInterval(waveformRef.current);
    setRecordingState('completed');
    setWaveformBars(Array(40).fill(0.3));
  };

  const handleSave = () => {
    // Clear previous warning
    setWarningMessage('');
    
    // Validation 1: Check if name is filled
    if (!name.trim()) {
      setWarningMessage('name');
      return; // Block save
    }
    
    // Validation 2: Check if recording duration is at least 30 seconds
    const recordedDuration = recordedTime;
    if (recordedDuration < 30) {
      setWarningMessage('duration');
      return; // Block save
    }
    
    // All validations passed - save to voiceprint list
    addVoiceprint({
      name: name,
      duration: recordedDuration,
      sampleCount: 1,
      audioSegments: [{
        time: '00:00',
        text: `Recorded voice sample for ${name}`
      }]
    });
    
    // Close modal
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-5" onClick={onClose}>
      <div className="bg-white rounded-[24px] p-8 w-full max-w-md shadow-2xl relative" onClick={(e) => e.stopPropagation()}>
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-8 h-8 rounded-full bg-black/5 hover:bg-black/10 flex items-center justify-center transition-colors"
        >
          <X className="w-4 h-4 text-[#8e8e93]" strokeWidth={2.5} />
        </button>

        <div className="text-center mb-6">
          <h3 className="text-[22px] font-bold text-[#1c1c1e] mb-2">Record Voice Sample</h3>
          <p className="text-[14px] text-[#8e8e93]">
            {recordingState === 'idle' && 'Record 30 seconds of speech'}
            {recordingState === 'recording' && 'Recording in progress...'}
            {recordingState === 'completed' && 'Recording completed!'}
          </p>
        </div>

        {/* Shakespeare Passage - shown before and during recording */}
        {recordingState !== 'completed' && (
          <div className="mb-6 bg-gradient-to-br from-[#f2f2f7] to-[#e5e5ea] rounded-[16px] p-5 border border-black/[0.06]">
            <div className="flex items-center justify-between mb-3">
              <h4 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide">Read This Passage</h4>
              <span className="text-[11px] text-[#8e8e93] italic">As You Like It</span>
            </div>
            <p className="text-[15px] text-[#1c1c1e] leading-relaxed italic">
              All the world's a stage,<br />
              And all the men and women merely players;<br />
              They have their exits and their entrances,<br />
              And one man in his time plays many parts,<br />
              His acts being seven ages. At first, the infant,<br />
              Mewling and puking in the nurse's arms.<br />
              Then the whining schoolboy, with his satchel<br />
              And shining morning face, creeping like snail<br />
              Unwillingly to school.
            </p>
          </div>
        )}

        {/* Timer Display */}
        {recordingState !== 'idle' && (
          <div className="text-center mb-6">
            <div className={`inline-flex items-center justify-center w-24 h-24 rounded-full ${
              recordingState === 'recording' ? 'bg-[#ff3b30]/10 animate-pulse' : 'bg-[#34c759]/10'
            }`}>
              <span className={`text-[32px] font-bold ${
                recordingState === 'recording' ? 'text-[#ff3b30]' : 'text-[#34c759]'
              }`}>
                {recordedTime}s
              </span>
            </div>
          </div>
        )}

        {/* Waveform Visualization */}
        {recordingState !== 'idle' && (
          <div className="mb-6">
            <div className="h-24 bg-[#f2f2f7] rounded-[12px] p-3 flex items-center justify-center gap-1">
              {waveformBars.map((height, index) => (
                <div
                  key={index}
                  className={`w-1 rounded-full transition-all duration-100 ${
                    recordingState === 'recording' ? 'bg-[#34c759]' : 'bg-[#8e8e93]'
                  }`}
                  style={{ height: `${Math.max(20, height * 100)}%` }}
                />
              ))}
            </div>
          </div>
        )}

        {/* Name Input (shown when recording is complete) */}
        {recordingState === 'completed' && (
          <div className="mb-6">
            <label className="block text-[14px] font-medium text-[#1c1c1e] mb-2">
              Speaker Name
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                setWarningMessage(''); // Clear warning when user types
              }}
              placeholder="Enter speaker's name"
              className="w-full px-4 py-3 bg-[#f2f2f7] rounded-[12px] text-[15px] text-[#1c1c1e] placeholder-[#8e8e93] focus:outline-none focus:ring-2 focus:ring-[#34c759]"
              autoFocus
            />
          </div>
        )}

        {/* Action Buttons */}
        {recordingState === 'idle' && (
          <button
            onClick={startRecording}
            className="w-full py-4 bg-gradient-to-r from-[#34c759] to-[#28a745] rounded-[13px] text-white text-[17px] font-bold shadow-lg hover:shadow-xl hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-2"
          >
            <Mic className="w-5 h-5" strokeWidth={2.5} />
            Start Recording
          </button>
        )}

        {recordingState === 'recording' && (
          <button
            onClick={stopRecording}
            className="w-full py-4 bg-[#ff3b30] rounded-[13px] text-white text-[17px] font-bold shadow-lg hover:shadow-xl hover:scale-[1.02] active:scale-[0.98] transition-all"
          >
            Stop Recording
          </button>
        )}

        {recordingState === 'completed' && (
          <div className="flex gap-3">
            <button
              onClick={() => {
                setRecordingState('idle');
                setRecordedTime(0);
                setName('');
                setWarningMessage(''); // Clear warning when re-recording
              }}
              className="flex-1 py-3 bg-[#f2f2f7] rounded-[12px] text-[#1c1c1e] font-medium hover:bg-[#e5e5ea] transition-colors"
            >
              Re-record
            </button>
            <button
              onClick={handleSave}
              className="flex-1 py-3 rounded-[12px] font-semibold transition-all bg-[#34c759] text-white hover:bg-[#28a745]"
            >
              Save Profile
            </button>
          </div>
        )}

        {/* Instructions */}
        {recordingState === 'idle' && (
          <div className="mt-6 bg-[#007aff]/10 rounded-[12px] p-4 border border-[#007aff]/20">
            <p className="text-[13px] text-[#007aff] text-center leading-relaxed">
              💡 Read the passage above naturally. At least 30 seconds needed for accurate recognition.
            </p>
          </div>
        )}
        
        {/* Warning Messages */}
        {warningMessage === 'name' && (
          <div className="mt-4 bg-[#ff9500]/10 border border-[#ff9500]/30 rounded-[12px] p-4">
            <div className="flex items-start gap-3">
              <div className="w-6 h-6 rounded-full bg-[#ff9500]/20 flex items-center justify-center flex-shrink-0">
                <AlertCircle className="w-4 h-4 text-[#ff9500]" strokeWidth={2.5} />
              </div>
              <div className="flex-1">
                <h4 className="text-[14px] font-semibold text-[#ff9500] mb-1">Name Required</h4>
                <p className="text-[13px] text-[#3c3c43] leading-relaxed">
                  Please enter a name for the speaker to save this voice profile.
                </p>
              </div>
            </div>
          </div>
        )}
        {warningMessage === 'duration' && (
          <div className="mt-4 bg-[#ff9500]/10 border border-[#ff9500]/30 rounded-[12px] p-4">
            <div className="flex items-start gap-3">
              <div className="w-6 h-6 rounded-full bg-[#ff9500]/20 flex items-center justify-center flex-shrink-0">
                <AlertCircle className="w-4 h-4 text-[#ff9500]" strokeWidth={2.5} />
              </div>
              <div className="flex-1">
                <h4 className="text-[14px] font-semibold text-[#ff9500] mb-1">Insufficient Audio Duration</h4>
                <p className="text-[13px] text-[#3c3c43] leading-relaxed">
                  Recording is only {recordedTime} seconds. Please record the full 30 seconds to create an accurate voiceprint.
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}