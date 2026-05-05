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
import 'utils/mp_uuid_util.dart';
import 'utils/platform/platform_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await OmiServerCache().initialize();
  Env.init();
  PlatformManager.initializeServices();
  await MPUuidUtil.instance.uuid;
  await MPPreferences.init();
  if (ApiTools.hasAccessToken()) {
    await MPAppSessionBootstrap.run(fromLoginSuccess: false);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
