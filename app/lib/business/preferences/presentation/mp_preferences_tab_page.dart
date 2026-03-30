import 'package:flutter/cupertino.dart';
import 'package:omi/business/auth/presentation/mp_login_page.dart';
import 'package:omi/business/preferences/presentation/pages/mp_ai_personalization_page.dart';
import 'package:omi/business/preferences/presentation/pages/mp_ai_summary_style_page.dart';
import 'package:omi/business/preferences/presentation/pages/mp_expert_models_page.dart';
import 'package:omi/business/preferences/presentation/pages/mp_settings_page.dart';
import 'package:omi/business/preferences/presentation/pages/mp_subscription_page.dart';
import 'package:omi/business/preferences/presentation/pages/mp_user_settings_page.dart';
import 'package:omi/business/preferences/presentation/pages/mp_voiceprint_recognition_page.dart';
import 'package:omi/business/recording/presentation/mp_recording_permission_page.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

class MPPreferencesTabPage extends StatelessWidget {
  const MPPreferencesTabPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;
 
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Preferences'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection.insetGrouped(
              header: const Text('通用'),
              children: [
                CupertinoListTile(
                  title: const Text('设置'),
                  onTap: () => _push(context, const MPSettingsPage()),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return CupertinoListSection.insetGrouped(
                  header: const Text('账号'),
                  children: [
                    if (controller.isLoggedIn) ...[
                      CupertinoListTile(
                        title: Text(controller.user.email ?? controller.user.name),
                        subtitle: const Text('已登录'),
                      ),
                      CupertinoListTile(
                        title: const Text('退出登录'),
                        trailing: const Icon(CupertinoIcons.forward),
                        onTap: () => _confirmLogout(context),
                      ),
                    ] else
                      CupertinoListTile(
                        title: const Text('登录 / 注册'),
                        subtitle: const Text('邮箱、Apple、Google'),
                        trailing: const Icon(CupertinoIcons.forward),
                        onTap: () => _push(
                          context,
                          MPLoginPage(controller: controller),
                        ),
                      ),
                    CupertinoListTile(
                      title: const Text('用户设置'),
                      onTap: () => _push(context, const MPUserSettingsPage()),
                    ),
                    CupertinoListTile(
                      title: const Text('订阅与账单'),
                      onTap: () => _push(context, const MPSubscriptionPage()),
                    ),
                  ],
                );
              },
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('AI'),
              children: [
                CupertinoListTile(
                  title: const Text('总结风格'),
                  onTap: () => _push(context, const MPAiSummaryStylePage()),
                ),
                CupertinoListTile(
                  title: const Text('专家模型'),
                  onTap: () => _push(context, const MPExpertModelsPage()),
                ),
                CupertinoListTile(
                  title: const Text('个性化'),
                  onTap: () => _push(context, const MPAiPersonalizationPage()),
                ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('权限'),
              children: [
                CupertinoListTile(
                  title: const Text('麦克风权限'),
                  onTap: () => _push(context, const MPRecordingPermissionPage()),
                ),
                CupertinoListTile(
                  title: const Text('声纹识别'),
                  onTap: () =>
                      _push(context, const MPVoiceprintRecognitionPage()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => page),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      controller.logout();
    }
  }
}
