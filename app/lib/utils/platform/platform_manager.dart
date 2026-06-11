import 'dart:io';

import 'package:memo_pin/utils/analytics/intercom.dart';
import 'package:memo_pin/utils/analytics/mixpanel.dart';
import 'package:memo_pin/utils/debugging/crashlytics_manager.dart';
import 'package:memo_pin/utils/debugging/crash_reporter.dart';
import 'package:memo_pin/utils/platform/platform_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Centralized platform manager for all platform-specific services
/// This provides a single point of access for all platform services
class PlatformManager {
  static final PlatformManager _instance = PlatformManager._internal();
  late PackageInfo _packageInfo;

  factory PlatformManager() => _instance;
  PlatformManager._internal();

  static PlatformManager get instance => _instance;

  // Service instances
  // MixpanelManager get mixpanel => MixpanelManager();
  IntercomManager get intercom => IntercomManager.instance;
  CrashReporter get crashReporter => CrashlyticsManager.instance;

  static Future<void> initializeServices() async {
    _instance._packageInfo = await PackageInfo.fromPlatform();
    // await MixpanelManager.init();
    await IntercomManager.instance.initIntercom();
  }

  String get platform => Platform.operatingSystem;

  /// 用户可见版本号，对应 [pubspec.yaml] 的 version 名称部分（如 `1.0.1`）。
  String get appVersionName => _packageInfo.version;

  String get appVersion => '${_packageInfo.version}+${_packageInfo.buildNumber}';

  bool get isAnalyticsSupported => PlatformService.isAnalyticsSupported;
  bool get isDebuggingSupported => PlatformService.isCrashlyticsSupported;
  bool get isMacOS => PlatformService.isMacOS;
}
