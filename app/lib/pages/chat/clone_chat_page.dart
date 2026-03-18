/// 克隆聊天页面
///
/// 用于创建和管理用户个人化聊天克隆（Persona）
/// 该页面会：
/// - 加载用户的个人化应用（Persona）
/// - 设置应用列表和选中的应用
/// - 初始化聊天消息
/// - 显示聊天界面
///
/// 兼容 iOS 和 Android 平台
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/app.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/chat/page.dart';
import 'package:omi/pages/home/widgets/chat_apps_dropdown_widget.dart';
import 'package:omi/pages/persona/persona_profile.dart';
import 'package:omi/pages/persona/persona_provider.dart';
import 'package:omi/providers/app_provider.dart';
import 'package:omi/providers/connectivity_provider.dart';
import 'package:omi/providers/message_provider.dart';
import 'package:omi/utils/other/temp.dart';
import 'package:provider/provider.dart';

/// 克隆聊天页面组件
///
/// 用于展示和管理用户的个人化聊天克隆
class CloneChatPage extends StatefulWidget {
  const CloneChatPage({
    super.key,
  });

  @override
  State<CloneChatPage> createState() => CloneChatPageState();
}

/// 克隆聊天页面状态管理类
///
/// 管理克隆聊天页面的初始化逻辑和状态
class CloneChatPageState extends State<CloneChatPage> {
  @override
  void initState() {
    // 在框架构建完成后执行初始化逻辑
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // 获取用户的个人化应用（Persona）
      final provider = Provider.of<PersonaProvider>(context, listen: false);
      await provider.getVerifiedUserPersona();
      if (provider.userPersona != null) {
        App selectedApp = provider.userPersona!;

        if (!mounted) {
          return;
        }

        // 设置应用列表和选中的应用
        var appProvider = Provider.of<AppProvider>(context, listen: false);
        SharedPreferencesUtil().appsList = [selectedApp];
        appProvider.setApps();
        // Set to null to chat with MemoPin by default
        appProvider.setSelectedChatAppId(null);

        // 如果应用未启用，则启用它
        if (!selectedApp.enabled) {
          await appProvider.toggleApp(selectedApp.id, true, null);
        }

        // 刷新消息列表并获取聊天应用
        var messageProvider = Provider.of<MessageProvider>(context, listen: false);
        await messageProvider.refreshMessages();
        // Fetch enabled chat apps
        messageProvider.fetchChatApps();

        // 如果消息列表为空，发送应用的初始消息
        if (messageProvider.messages.isEmpty) {
          messageProvider.sendInitialAppMessage(selectedApp);
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<MessageProvider, ConnectivityProvider, PersonaProvider>(
      builder: (context, provider, connectivityProvider, personaProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 44),
                personaProvider.isLoading || personaProvider.userPersona == null
                    ? const SizedBox(width: 44)
                    : ChatAppsDropdownWidget(mode: ChatMode.chat_clone),
                IconButton(
                  padding: const EdgeInsets.all(8.0),
                  icon: SvgPicture.asset(
                    Assets.images.icPersonaProfile,
                    width: 28,
                    height: 28,
                  ),
                  onPressed: () {
                    personaProvider.setRouting(PersonaProfileRouting.no_device);
                    routeToPage(context, const PersonaProfilePage(), replace: true);
                  },
                ),
              ],
            ),
          ),
          body: personaProvider.isLoading || personaProvider.userPersona == null
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    // Hide keyboard when tapping outside
                    FocusScope.of(context).unfocus();
                  },
                  child: const ChatPage(isPivotBottom: true),
                ),
        );
      },
    );
  }
}
