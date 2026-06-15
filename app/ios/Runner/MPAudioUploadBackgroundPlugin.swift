import Flutter
import UIKit

/// S3 上传期间申请/续期 iOS 后台执行时间，降低退后台后 Dart [HttpClient] 被立刻中断的概率。
final class MPAudioUploadBackgroundPlugin: NSObject, FlutterPlugin {
  private static let logTag = "[MemoPin/UploadBackground]"
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
  private var isActive = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "mp_audio_upload_background",
      binaryMessenger: registrar.messenger()
    )
    let instance = MPAudioUploadBackgroundPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "beginBackgroundExecution":
      result(beginBackgroundExecution())
    case "endBackgroundExecution":
      endBackgroundExecution()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @discardableResult
  private func beginBackgroundExecution() -> Bool {
    if isActive, backgroundTaskId != .invalid {
      return true
    }
    endBackgroundExecution()
    isActive = true
    backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "MPAudioUpload") { [weak self] in
      guard let self else { return }
      NSLog("%@ background task expiring, attempting renewal", Self.logTag)
      self.renewBackgroundTask()
    }
    let ok = backgroundTaskId != .invalid
    NSLog("%@ beginBackgroundExecution ok=%@", Self.logTag, ok ? "true" : "false")
    return ok
  }

  private func renewBackgroundTask() {
    guard isActive else {
      endBackgroundExecution()
      return
    }
    if backgroundTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTaskId)
      backgroundTaskId = .invalid
    }
    backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "MPAudioUpload") { [weak self] in
      self?.renewBackgroundTask()
    }
  }

  private func endBackgroundExecution() {
    isActive = false
    if backgroundTaskId != .invalid {
      UIApplication.shared.endBackgroundTask(backgroundTaskId)
      backgroundTaskId = .invalid
    }
  }
}
