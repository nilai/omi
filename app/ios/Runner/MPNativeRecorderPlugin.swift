import AVFoundation
import Flutter
import UIKit

/// 首页长录音：原生 AVAudioRecorder，混音模式 + 系统打断自动续录。
final class MPNativeRecorderPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, AVAudioRecorderDelegate {
  private static let logTag = "[MemoPin/NativeRecorder]"
  private static let channelName = "mp_native_recorder"
  private static let eventChannelName = "mp_native_recorder/events"

  private var mixWithOthers = false
  private var recorder: AVAudioRecorder?
  private var currentPath: String?
  private var segmentPaths: [String] = []
  private var eventSink: FlutterEventSink?
  private var interruptionObserver: NSObjectProtocol?
  private var backgroundObserver: NSObjectProtocol?
  private var foregroundObserver: NSObjectProtocol?
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
  private var backgroundMonitorTimer: DispatchSourceTimer?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MPNativeRecorderPlugin()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
    let events = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
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
        registerAppLifecycleObserversIfNeeded()
      }
      result(true)
    case "close":
      closeRecorder(deleteFiles: false)
      unregisterInterruptionObserver()
      unregisterAppLifecycleObservers()
      endBackgroundTaskIfNeeded()
      stopBackgroundMonitor()
      mixWithOthers = false
      result(nil)
    case "start":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(false)
        return
      }
      result(startRecording(path: path))
    case "pauseSegment":
      result(pauseSegment())
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
      var paths = segmentPaths
      if let currentPath, !paths.contains(currentPath) {
        paths.append(currentPath)
      }
      result(paths)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func registerAppLifecycleObserversIfNeeded() {
    if backgroundObserver != nil {
      return
    }
    backgroundObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleAppEnteredBackground()
    }
    foregroundObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleAppWillEnterForeground()
    }
  }

  private func unregisterAppLifecycleObservers() {
    if let observer = backgroundObserver {
      NotificationCenter.default.removeObserver(observer)
      backgroundObserver = nil
    }
    if let observer = foregroundObserver {
      NotificationCenter.default.removeObserver(observer)
      foregroundObserver = nil
    }
  }

  private func handleAppEnteredBackground() {
    guard mixWithOthers else { return }
    beginBackgroundTaskIfNeeded()
    startBackgroundMonitor()
    _ = MPRecordingSessionPlugin.applyMixRecordingSession()
  }

  private func handleAppWillEnterForeground() {
    guard mixWithOthers else { return }
    _ = MPRecordingSessionPlugin.applyMixRecordingSession()
    resumeRecordingIfNeeded(reason: "willEnterForeground")
  }

  private func beginBackgroundTaskIfNeeded() {
    if backgroundTaskId != .invalid {
      return
    }
    backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "MemoPinRecording") { [weak self] in
      self?.endBackgroundTaskIfNeeded()
    }
  }

  private func endBackgroundTaskIfNeeded() {
    if backgroundTaskId == .invalid {
      return
    }
    UIApplication.shared.endBackgroundTask(backgroundTaskId)
    backgroundTaskId = .invalid
  }

  /// 退后台后在原生层低频检查录音是否被系统停掉，避免 Dart 轮询阻塞 UI。
  private func startBackgroundMonitor() {
    guard mixWithOthers else { return }
    stopBackgroundMonitor()
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
    timer.schedule(deadline: .now() + 3, repeating: 8)
    timer.setEventHandler { [weak self] in
      DispatchQueue.main.async {
        guard let self, self.mixWithOthers else { return }
        if self.recorder?.isRecording != true {
          self.resumeRecordingIfNeeded(reason: "backgroundMonitor")
        }
      }
    }
    timer.resume()
    backgroundMonitorTimer = timer
  }

  private func stopBackgroundMonitor() {
    backgroundMonitorTimer?.cancel()
    backgroundMonitorTimer = nil
  }

  private func registerInterruptionObserverIfNeeded() {
    if interruptionObserver != nil {
      return
    }
    interruptionObserver = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance(),
      queue: nil
    ) { [weak self] notification in
      self?.handleAudioInterruption(notification)
    }
  }

  private func unregisterInterruptionObserver() {
    if let observer = interruptionObserver {
      NotificationCenter.default.removeObserver(observer)
      interruptionObserver = nil
    }
  }

  private func handleAudioInterruption(_ notification: Notification) {
    guard mixWithOthers else { return }
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }
    switch type {
    case .began:
      // 混音模式：不主动 stop；视频播放等软打断不应暂停录音。
      if recorder?.isRecording != true {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
          self?.resumeRecordingIfNeeded(reason: "interruptionBegan")
        }
      }
    case .ended:
      _ = MPRecordingSessionPlugin.applyMixRecordingSession()
      resumeRecordingIfNeeded(reason: "interruptionEnded")
    @unknown default:
      break
    }
  }

  private func resumeRecordingIfNeeded(reason: String) {
    guard mixWithOthers else { return }
    if recorder?.isRecording == true {
      return
    }
    _ = MPRecordingSessionPlugin.applyMixRecordingSession()
    guard let dir = directoryForAutoSegment() else { return }
    let path = dir.appendingPathComponent(
      "omi_focus_\(Int(Date().timeIntervalSince1970 * 1000))_\(segmentPaths.count).m4a"
    ).path
    if startRecording(path: path) {
      NSLog("%@ auto segment (%@) path=%@", Self.logTag, reason, path)
      DispatchQueue.main.async { [weak self] in
        self?.eventSink?(["type": "segmentAutoStarted", "path": path])
      }
    }
  }

  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    guard mixWithOthers, !flag else { return }
    if let path = currentPath, !segmentPaths.contains(path) {
      segmentPaths.append(path)
    }
    currentPath = nil
    self.recorder = nil
    resumeRecordingIfNeeded(reason: "recorderFinished")
  }

  private func directoryForAutoSegment() -> URL? {
    if let currentPath {
      return URL(fileURLWithPath: currentPath).deletingLastPathComponent()
    }
    if let last = segmentPaths.last {
      return URL(fileURLWithPath: last).deletingLastPathComponent()
    }
    return FileManager.default.temporaryDirectory
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
    stopRecorderOnly()
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    do {
      let newRecorder = try AVAudioRecorder(url: url, settings: recorderSettings())
      newRecorder.delegate = self
      newRecorder.isMeteringEnabled = false
      guard newRecorder.prepareToRecord(), newRecorder.record() else {
        NSLog("%@ start failed prepare/record path=%@", Self.logTag, path)
        return false
      }
      recorder = newRecorder
      currentPath = path
      if mixWithOthers {
        beginBackgroundTaskIfNeeded()
        startBackgroundMonitor()
      }
      return true
    } catch {
      NSLog("%@ start error: %@ path=%@", Self.logTag, error.localizedDescription, path)
      return false
    }
  }

  private func stopRecorderOnly() {
    recorder?.delegate = nil
    recorder?.stop()
    recorder = nil
  }

  private func pauseSegment() -> String? {
    guard let path = currentPath else { return nil }
    stopRecorderOnly()
    if !segmentPaths.contains(path) {
      segmentPaths.append(path)
    }
    currentPath = nil
    return path
  }

  private func finish(outputPath: String) -> String? {
    if recorder?.isRecording == true, let path = currentPath {
      stopRecorderOnly()
      if !segmentPaths.contains(path) {
        segmentPaths.append(path)
      }
      currentPath = nil
    }
    let inputs = segmentPaths
    segmentPaths.removeAll()
    guard !inputs.isEmpty else { return nil }
    if inputs.count == 1 {
      let single = inputs[0]
      if single == outputPath {
        return single
      }
      try? FileManager.default.removeItem(atPath: outputPath)
      do {
        try FileManager.default.copyItem(atPath: single, toPath: outputPath)
        return outputPath
      } catch {
        return single
      }
    }
    if mergeM4aFiles(inputPaths: inputs, outputPath: outputPath) {
      for path in inputs where path != outputPath {
        try? FileManager.default.removeItem(atPath: path)
      }
      return outputPath
    }
    return inputs.last
  }

  private func mergeM4aFiles(inputPaths: [String], outputPath: String) -> Bool {
    let composition = AVMutableComposition()
    guard let compositionTrack = composition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid
    ) else {
      return false
    }
    var cursor = CMTime.zero
    for path in inputPaths {
      let url = URL(fileURLWithPath: path)
      let asset = AVURLAsset(url: url)
      guard let track = asset.tracks(withMediaType: .audio).first else { continue }
      let duration = asset.duration
      do {
        try compositionTrack.insertTimeRange(
          CMTimeRange(start: .zero, duration: duration),
          of: track,
          at: cursor
        )
        cursor = CMTimeAdd(cursor, duration)
      } catch {
        return false
      }
    }
    try? FileManager.default.removeItem(atPath: outputPath)
    guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
      return false
    }
    export.outputURL = URL(fileURLWithPath: outputPath)
    export.outputFileType = .m4a
    let semaphore = DispatchSemaphore(value: 0)
    var ok = false
    export.exportAsynchronously {
      ok = export.status == .completed
      semaphore.signal()
    }
    semaphore.wait()
    return ok
  }

  private func fileSize(path: String) -> Int {
    let attrs = try? FileManager.default.attributesOfItem(atPath: path)
    return attrs?[.size] as? Int ?? 0
  }

  private func closeRecorder(deleteFiles: Bool) {
    stopRecorderOnly()
    if deleteFiles {
      for path in segmentPaths {
        try? FileManager.default.removeItem(atPath: path)
      }
    }
    segmentPaths.removeAll()
    currentPath = nil
  }
}
