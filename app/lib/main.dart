import 'package:flutter/material.dart';
import 'login/mp_login_page.dart';
import 'login/mp_user.dart';
import 'package:omi/cache/omi_server_cache.dart';
import 'package:omi/tab/omi_main_tab_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OmiServerCache().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'omi',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: _buildHomePage(context),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    if (MPUser.isLoggedIn) {
      return const MainTabPage();
    }
    return const MPLoginPage();
  }
}
