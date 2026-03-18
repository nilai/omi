// AI-generated START - 首页刷新事件服务
import 'dart:async';

/// 首页刷新事件类型
enum MPHomeRefreshEventType {
  /// 需要刷新首页
  refresh,
}

/// 首页刷新事件
class MPHomeRefreshEvent {
  /// 事件类型
  final MPHomeRefreshEventType type;

  /// 事件数据（可选）
  final Map<String, dynamic>? data;

  MPHomeRefreshEvent({
    required this.type,
    this.data,
  });
}

/// 首页刷新事件服务
/// 用于发送和监听首页刷新相关的事件
/// 其他页面可以通过此服务通知首页刷新
class MPHomeRefreshEventService {
  // 单例模式
  static final MPHomeRefreshEventService _instance = MPHomeRefreshEventService._internal();
  factory MPHomeRefreshEventService() => _instance;
  MPHomeRefreshEventService._internal();

  // 事件流控制器
  final _eventController = StreamController<MPHomeRefreshEvent>.broadcast();

  /// 获取事件流
  Stream<MPHomeRefreshEvent> get events => _eventController.stream;

  /// 发送事件
  /// @param event 事件对象
  void emit(MPHomeRefreshEvent event) {
    _eventController.add(event);
  }

  /// 发送首页刷新事件
  /// @param data 可选的事件数据
  void emitRefresh({Map<String, dynamic>? data}) {
    emit(MPHomeRefreshEvent(
      type: MPHomeRefreshEventType.refresh,
      data: data,
    ));
  }

  /// 释放资源
  void dispose() {
    _eventController.close();
  }
}
// AI-generated END - mp_home_refresh_event_service.dart
