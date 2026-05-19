import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:memo_pin/common/mp_route_observer.dart';
import 'package:memo_pin/http/shared.dart';
import 'app/mp_app_session_bootstrap.dart';
import 'login/home/mp_login_page.dart';
import 'package:memo_pin/cache/omi_server_cache.dart';
import 'package:memo_pin/tab/omi_main_tab_page.dart';
import 'env/env.dart';
import 'utils/mp_preferences.dart';
import 'utils/mp_time_utils.dart';
import 'utils/mp_uuid_util.dart';
import 'utils/platform/platform_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  // 必须先初始化 SharedPreferences，[MPUser.userId] 才能读到正确值；
  // 否则 [OmiServerCache] 会用空 userId 打开错误的 Hive box，且只 initialize 一次，
  // 内存里的 _store 永远是错的，[OmiCacheManager.getMemoryFirstPage] 等读缓存会失效。
  await MPPreferences.init();
  await MPTimeUtils.ensureInitialized();
  await MPTimeUtils.refreshTimeZone();
  await OmiServerCache().initialize();
  Env.init();
  PlatformManager.initializeServices();
  await MPUuidUtil.instance.uuid;
  if (ApiTools.hasAccessToken()) {
    await MPAppSessionBootstrap.run(fromLoginSuccess: false);
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 热启动回到前台时刷新时区（用户可能已切换系统时区或跨区旅行）。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(MPTimeUtils.refreshTimeZone());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      navigatorObservers: <NavigatorObserver>[mpRouteObserver],
      title: 'omi',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: _buildHomePage(context),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    if (ApiTools.hasAccessToken()) {
      return const MainTabPage();
    }
    return const MPLoginPage();
  }
}
