import AVFoundation
import Flutter

/// 首页长录音：原生 AVAudioRecorder 整段写入单文件；混音模式支持系统打断后自动续录。
final class MPNativeRecorderPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static let logTag = "[MemoPin/NativeRecorder]"
  private static let channelName = "mp_native_recorder"
  private static let eventChannelName = "mp_native_recorder/events"

  private var mixWithOthers = false
  private var recorder: AVAudioRecorder?
  private var currentPath: String?
  private var eventSink: FlutterEventSink?
  private var interruptionObserver: NSObjectProtocol?
  /// 系统音频打断（来电、独占麦克风 App 等）进行中。
  private var interruptionActive = false
  /// 用户或系统打断后处于暂停态（与 [AVAudioRecorder.isRecording] 解耦）。
  private var isPaused = false
  /// 已写入时长（毫秒）；暂停/中断时从 [AVAudioRecorder.currentTime] 同步，避免 UI 回退。
  private var trackedDurationMs: Double = 0

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MPNativeRecorderPlugin()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(instance)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "open":
      let args = call.arguments as? [String: Any]
      mixWithOthers = args?["mixWithOthers"] as? Bool ?? false
      if mixWithOthers {
        _ = MPRecordingSessionPlugin.applyMixRecordingSession()
        registerInterruptionObserverIfNeeded()
      } else {
        unregisterInterruptionObserver()
      }
      result(true)
    case "close":
      closeRecorder(deleteFiles: false)
      mixWithOthers = false
      unregisterInterruptionObserver()
      result(nil)
    case "start":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(false)
        return
      }
      result(startRecording(path: path))
    case "resumeSegment":
      result(resumeRecording())
    case "pauseSegment":
      result(pauseRecording())
    case "finish":
      guard let args = call.arguments as? [String: Any],
            let outputPath = args["outputPath"] as? String else {
        result(nil)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        let out = self?.finish(outputPath: outputPath)
        DispatchQueue.main.async {
          result(out)
        }
      }
    case "isRecording":
      result(isActivelyCapturing())
    case "currentPath":
      result(currentPath)
    case "fileSize":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(0)
        return
      }
      result(fileSize(path: path))
    case "segmentPaths":
      if let currentPath {
        result([currentPath])
      } else {
        result([String]())
      }
    case "currentDurationMs":
      result(currentRecordingDurationMs())
    case "isMicrophoneCaptureBlocked":
      result(isMicrophoneCaptureBlocked())
    case "prepareForRecordingResume":
      result(prepareForRecordingResume())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func registerInterruptionObserverIfNeeded() {
    guard interruptionObserver == nil else { return }
    interruptionObserver = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance(),
      queue: .main
    ) { [weak self] notification in
      self?.handleAudioSessionInterruption(notification)
    }
  }

  private func unregisterInterruptionObserver() {
    if let observer = interruptionObserver {
      NotificationCenter.default.removeObserver(observer)
      interruptionObserver = nil
    }
  }

  private func handleAudioSessionInterruption(_ notification: Notification) {
    guard mixWithOthers else { return }
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }
    switch type {
    case .began:
      interruptionActive = true
      _ = pauseRecording()
      eventSink?(["type": "interruptionBegan"])
    case .ended:
      interruptionActive = false
      _ = MPRecordingSessionPlugin.applyMixRecordingSession()
      eventSink?(["type": "interruptionEnded"])
    @unknown default:
      break
    }
  }

  /// 是否正在向文件写入（非暂停态）。
  private func isActivelyCapturing() -> Bool {
    guard let rec = recorder, !isPaused else { return false }
    return rec.isRecording
  }

  /// 将 [AVAudioRecorder.currentTime] 合并进 [trackedDurationMs]。
  private func syncDurationFromRecorder() {
    guard let rec = recorder else { return }
    trackedDurationMs = max(trackedDurationMs, rec.currentTime * 1000.0)
  }

  private func resetDurationTracking() {
    trackedDurationMs = 0
    isPaused = false
  }

  /// 当前录音文件已写入时长（毫秒）；无录音时为 0。
  private func currentRecordingDurationMs() -> Int {
    var tracked = trackedDurationMs
    if let rec = recorder, rec.isRecording {
      tracked = max(tracked, rec.currentTime * 1000.0)
    }
    if let path = currentPath {
      tracked = max(tracked, Double(readFileDurationMs(path: path)))
    }
    return max(0, Int(tracked))
  }

  private func readFileDurationMs(path: String) -> Int {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else { return 0 }
    let asset = AVURLAsset(url: url)
    let seconds = CMTimeGetSeconds(asset.duration)
    guard seconds.isFinite, seconds > 0 else { return 0 }
    return Int(seconds * 1000.0)
  }

  /// 来电或独占麦克风场景下不可 start/resume。
  private func isMicrophoneCaptureBlocked() -> Bool {
    refreshMicrophoneCaptureBlockedState()
    let session = AVAudioSession.sharedInstance()
    if !session.isInputAvailable {
      return true
    }
    return interruptionActive
  }

  /// 根据当前 AudioSession 刷新打断标记，避免后台未收到 interruptionEnded 时永久 blocked。
  private func refreshMicrophoneCaptureBlockedState() {
    let session = AVAudioSession.sharedInstance()
    if session.isInputAvailable {
      interruptionActive = false
    }
  }

  /// resume 前重新激活会话并刷新占用状态。
  @discardableResult
  private func prepareForRecordingResume() -> Bool {
    refreshMicrophoneCaptureBlockedState()
    if mixWithOthers {
      return MPRecordingSessionPlugin.applyMixRecordingSession()
    }
    do {
      try AVAudioSession.sharedInstance().setActive(true)
      return true
    } catch {
      NSLog("%@ prepareForRecordingResume failed: %@", Self.logTag, error.localizedDescription)
      return false
    }
  }

  private func recorderSettings() -> [String: Any] {
    [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVSampleRateKey: 8000,
      AVNumberOfChannelsKey: 1,
      AVEncoderBitRateKey: 8000,
      AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue,
    ]
  }

  @discardableResult
  private func startRecording(path: String) -> Bool {
    if mixWithOthers {
      _ = MPRecordingSessionPlugin.applyMixRecordingSession()
    }
    if currentPath == path, recorder != nil {
      return resumeRecording()
    }
    if currentPath != nil {
      stopRecorderOnly()
      resetDurationTracking()
    }
    let url = URL(fileURLWithPath: path)
    if FileManager.default.fileExists(atPath: path) {
      NSLog("%@ start refused: file already exists path=%@", Self.logTag, path)
      return false
    }
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    do {
      let newRecorder = try AVAudioRecorder(url: url, settings: recorderSettings())
      newRecorder.isMeteringEnabled = false
      guard newRecorder.prepareToRecord(), newRecorder.record() else {
        NSLog("%@ start failed prepare/record path=%@", Self.logTag, path)
        return false
      }
      recorder = newRecorder
      currentPath = path
      isPaused = false
      trackedDurationMs = 0
      return true
    } catch {
      NSLog("%@ start error: %@ path=%@", Self.logTag, error.localizedDescription, path)
      return false
    }
  }

  /// 暂停整段录音（不 stop，保留同一 AVAudioRecorder 实例）。
  private func pauseRecording() -> String? {
    guard let path = currentPath else { return nil }
    if let rec = recorder {
      syncDurationFromRecorder()
      if rec.isRecording {
        rec.pause()
      }
    }
    isPaused = true
    return path
  }

  /// 在同文件上继续录音（仅 [record]，禁止 [prepareToRecord] 以免覆盖已有内容）。
  @discardableResult
  private func resumeRecording() -> Bool {
    guard let rec = recorder, currentPath != nil else { return false }
    if rec.isRecording, !isPaused {
      return true
    }
    if isMicrophoneCaptureBlocked() {
      return false
    }
    guard prepareForRecordingResume() else { return false }
    if isMicrophoneCaptureBlocked() {
      return false
    }
    guard rec.record() else {
      NSLog("%@ resume record() failed path=%@ trackedMs=%.0f", Self.logTag, currentPath ?? "", trackedDurationMs)
      return false
    }
    isPaused = false
    return true
  }

  private func stopRecorderOnly() {
    syncDurationFromRecorder()
    recorder?.stop()
    recorder = nil
  }

  /// 停止整段录音并返回最终文件路径。
  private func finish(outputPath: String) -> String? {
    syncDurationFromRecorder()
    if let rec = recorder {
      if rec.isRecording {
        rec.stop()
      } else {
        rec.stop()
      }
    }
    recorder = nil
    isPaused = false
    guard let path = currentPath else { return nil }
    currentPath = nil
    if path == outputPath {
      return path
    }
    try? FileManager.default.removeItem(atPath: outputPath)
    do {
      try FileManager.default.copyItem(atPath: path, toPath: outputPath)
      return outputPath
    } catch {
      NSLog("%@ finish copy failed: %@, returning original path=%@", Self.logTag, error.localizedDescription, path)
      return path
    }
  }

  private func fileSize(path: String) -> Int {
    let attrs = try? FileManager.default.attributesOfItem(atPath: path)
    return attrs?[.size] as? Int ?? 0
  }

  private func closeRecorder(deleteFiles: Bool) {
    stopRecorderOnly()
    if deleteFiles, let path = currentPath {
      try? FileManager.default.removeItem(atPath: path)
    }
    currentPath = nil
    resetDurationTracking()
  }
}
