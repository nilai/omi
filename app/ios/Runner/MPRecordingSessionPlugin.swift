import AVFoundation
import Flutter

/// 首页混音录音：原生层强化 AVAudioSession，降低被微信等 App 抢占麦克风时的打断概率。
final class MPRecordingSessionPlugin: NSObject, FlutterPlugin {
  private static let logTag = "[MemoPin/RecordingSession]"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "mp_recording_session",
      binaryMessenger: registrar.messenger()
    )
    let instance = MPRecordingSessionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "applyMixRecordingSession":
      result(Self.applyMixRecordingSession())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 混音 + 测量模式；激活时不通知其它 App 停用，尽量与微信/系统录音并存。
  @discardableResult
  static func applyMixRecordingSession() -> Bool {
    let session = AVAudioSession.sharedInstance()
    do {
      var options: AVAudioSession.CategoryOptions = [
        .mixWithOthers,
        .duckOthers,
        .interruptSpokenAudioAndMixWithOthers,
        .allowBluetooth,
        .allowBluetoothA2DP,
        .defaultToSpeaker,
      ]
      if #available(iOS 17.0, *) {
        options.insert(.overrideMutedMicrophoneInterruption)
      }
      try session.setCategory(.playAndRecord, mode: .measurement, options: options)
      try session.setActive(true, options: [])
      NSLog("%@ mix session active category=%@ mode=%@", logTag, session.category.rawValue, session.mode.rawValue)
      return true
    } catch {
      NSLog("%@ applyMixRecordingSession failed: %@", logTag, error.localizedDescription)
      return false
    }
  }
}
