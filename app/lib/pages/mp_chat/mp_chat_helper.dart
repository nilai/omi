import '../../backend/schema/mp/mp_data_model.dart';

/// 聊天助手工具类
///
/// 提供聊天相关的辅助功能
/// 单例模式，通过 instance 获取实例
class MPChatHelper {
  /// 私有构造函数
  MPChatHelper._();

  /// 单例实例
  static final MPChatHelper instance = MPChatHelper._();

  // 在这里添加你的方法和属性

  MPMemoryStruct? memory;
}
