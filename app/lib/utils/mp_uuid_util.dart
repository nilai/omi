import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'mp_preferences.dart';

/**
 * 设备 UUID 工具类。
 *
 * 设计目标：
 * - 优先使用平台稳定标识（iOS: identifierForVendor, Android: Android ID）
 * - 同时持久化到 Keychain/KeyStore，提升重装后稳定性
 * - 仅保留当前版本 key，不做新老版本 key 迁移
 */
class MPUuidUtil {
  MPUuidUtil._();

  static final MPUuidUtil instance = MPUuidUtil._();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const Uuid _uuidGenerator = Uuid();

  static const String _uuidStorageKey = 'mp_device_uuid';

  String? _uuid;

  /**
   * 获取设备 UUID（懒加载）。
   */
  Future<String> get uuid async {
    if (_uuid != null && _uuid!.isNotEmpty) {
      return _uuid!;
    }

    // 1) 先读 SharedPreferences 缓存。
    final String cachedUuid = MPPreferences().getString(_uuidStorageKey);
    if (cachedUuid.isNotEmpty && cachedUuid != 'unknown') {
      _uuid = cachedUuid;
      return _uuid!;
    }

    // 2) 再读 Keychain/KeyStore（iOS 重装后更可能保留）。
    try {
      final secureUuid = await _secureStorage.read(key: _uuidStorageKey);
      if (secureUuid != null && secureUuid.isNotEmpty && secureUuid != 'unknown') {
        _uuid = secureUuid;
        await MPPreferences().saveString(_uuidStorageKey, _uuid!);
        return _uuid!;
      }
    } catch (e) {
      debugPrint('MPUuidUtil read secure storage failed: $e');
    }

    // 3) 根据平台获取稳定标识。
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final androidId = androidInfo.id;
        if (androidId.isNotEmpty && androidId != '9774d56d682e549c') {
          _uuid = androidId;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final identifierForVendor = iosInfo.identifierForVendor;
        if (identifierForVendor != null && identifierForVendor.isNotEmpty) {
          _uuid = identifierForVendor;
        }
      }
    } catch (e) {
      debugPrint('MPUuidUtil read platform identifier failed: $e');
    }

    // 4) 平台标识不可用则降级为随机 UUID。
    _uuid ??= _uuidGenerator.v4();

    // 5) 写回双存储。
    try {
      await _secureStorage.write(key: _uuidStorageKey, value: _uuid!);
      await MPPreferences().saveString(_uuidStorageKey, _uuid!);
    } catch (e) {
      debugPrint('MPUuidUtil persist uuid failed: $e');
    }

    return _uuid!;
  }
}
