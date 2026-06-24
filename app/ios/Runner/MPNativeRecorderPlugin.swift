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
      result(recorder?.isRecording ?? false)
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
      eventSink?(["type": "interruptionBegan"])
    case .ended:
      _ = MPRecordingSessionPlugin.applyMixRecordingSession()
      _ = resumeRecording()
      eventSink?(["type": "interruptionEnded"])
    @unknown default:
      break
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
    if let existing = recorder, currentPath == path, !existing.isRecording {
      return resumeRecording()
    }
    stopRecorderOnly()
    let url = URL(fileURLWithPath: path)
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
      return true
    } catch {
      NSLog("%@ start error: %@ path=%@", Self.logTag, error.localizedDescription, path)
      return false
    }
  }

  /// 暂停整段录音（不 stop，保留同一 AVAudioRecorder 实例）。
  private func pauseRecording() -> String? {
    guard let path = currentPath, let rec = recorder else { return nil }
    if rec.isRecording {
      rec.pause()
    }
    return path
  }

  /// 在同文件上继续录音（响应 App UI 或系统打断结束）。
  @discardableResult
  private func resumeRecording() -> Bool {
    guard let rec = recorder, currentPath != nil else { return false }
    if rec.isRecording {
      return true
    }
    if mixWithOthers {
      _ = MPRecordingSessionPlugin.applyMixRecordingSession()
    }
    guard rec.record() else {
      NSLog("%@ resume record() failed path=%@", Self.logTag, currentPath ?? "")
      return false
    }
    return true
  }

  private func stopRecorderOnly() {
    recorder?.stop()
    recorder = nil
  }

  /// 停止整段录音并返回最终文件路径。
  private func finish(outputPath: String) -> String? {
    if recorder?.isRecording == true {
      recorder?.stop()
    }
    recorder = nil
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
  }
}
