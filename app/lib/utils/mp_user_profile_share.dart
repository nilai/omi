import 'package:omi/backend/http/mp_api/mp_user.dart' as api;
import 'package:omi/backend/schema/mp/mp_user.dart';

/// 用户资料共享工具类
///
/// 提供用户资料的单例访问和缓存功能
/// 单例模式，通过 instance 获取实例
class MPUserProfileShare {
  /// 私有构造函数
  MPUserProfileShare._();

  /// 单例实例
  static final MPUserProfileShare instance = MPUserProfileShare._();

  /// 缓存的用户资料响应
  MPGetUserProfileResponse? _userProfile;

  /// 获取用户资料
  ///
  /// 如果缓存中有值，直接返回缓存的值
  /// 如果缓存为空，调用API获取用户资料，缓存后返回
  ///
  /// 返回 [MPGetUserProfileResponse] 如果成功，否则返回 null
  Future<MPGetUserProfileResponse?> getUserProfile() async {
    // 如果属性有值，返回属性
    if (_userProfile != null) {
      return _userProfile;
    }

    // 如果属性为空，调用API获取result
    final request = MPGetUserProfileRequest();
    final result = await api.getUserProfile(request);

    // 赋值给属性后，再返回
    if (result != null) {
      _userProfile = result;
    }

    return result;
  }
}

