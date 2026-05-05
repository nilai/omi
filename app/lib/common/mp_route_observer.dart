import 'package:flutter/widgets.dart';

/// 挂到根 [MaterialApp.navigatorObservers]，供首页等 [RouteAware] 在二级页面返回（pop）时感知。
final RouteObserver<PageRoute<dynamic>> mpRouteObserver = RouteObserver<PageRoute<dynamic>>();
