import 'dart:async';

import 'package:flutter/material.dart';

import '../../../common/mp_route_observer.dart';

/// 详情页路由重新可见时触发 [onRefresh]：
/// - 自本页 push 的上层路由 [RouteAware.didPopNext] 返回；
/// - 应用回到前台且 [ModalRoute.isCurrent] 为本页。
///
/// 不包含首次 [RouteAware.didPush]，避免与 Bloc `initData` 重复请求；
/// 生命周期刷新在首帧之后才开始生效，减轻冷启动 `resumed` 误触发。
class MPDetailVisibilityRefresh extends StatefulWidget {
  const MPDetailVisibilityRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;

  final Widget child;

  @override
  State<MPDetailVisibilityRefresh> createState() =>
      _MPDetailVisibilityRefreshState();
}

class _MPDetailVisibilityRefreshState extends State<MPDetailVisibilityRefresh>
    with RouteAware, WidgetsBindingObserver {
  bool _allowLifecycleRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _allowLifecycleRefresh = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      mpRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    mpRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _runRefresh() async {
    if (!mounted) {
      return;
    }
    await widget.onRefresh();
  }

  @override
  void didPopNext() {
    unawaited(_runRefresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_allowLifecycleRefresh) {
      return;
    }
    if (!mounted) {
      return;
    }
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route?.isCurrent != true) {
      return;
    }
    unawaited(_runRefresh());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
