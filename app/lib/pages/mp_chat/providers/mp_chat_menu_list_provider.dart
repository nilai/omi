import 'package:flutter/material.dart';

/// 聊天菜单项数据模型
class MPChatMenuItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? iconUrl;
  final Color? iconColor;
  final VoidCallback? onTap;

  MPChatMenuItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconUrl,
    this.iconColor,
    this.onTap,
  });
}

/// 聊天菜单列表Provider
class MPChatMenuListProvider extends ChangeNotifier {
  List<MPChatMenuItem> _recentConversations = [];
  bool _isLoading = false;

  List<MPChatMenuItem> get recentConversations => _recentConversations;
  bool get isLoading => _isLoading;

  MPChatMenuListProvider() {
    // 初始化时加载假数据
    _loadMockData();
  }

  /// 加载假数据
  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // 模拟网络请求延迟
    Future.delayed(const Duration(milliseconds: 500), () {
      _recentConversations = [
        MPChatMenuItem(
          id: '1',
          title: '星座大师',
          icon: Icons.camera_alt,
          iconColor: Colors.grey[800],
        ),
        MPChatMenuItem(
          id: '2',
          title: '英语外教 Owen',
          icon: Icons.person,
          iconColor: Colors.blue,
        ),
        MPChatMenuItem(
          id: '3',
          title: 'Translate "AI Product Entrepreneur"',
          icon: Icons.translate,
          iconColor: Colors.lightBlue,
        ),
        MPChatMenuItem(
          id: '4',
          title: '旅游行程规划',
          icon: Icons.flight,
          iconColor: Colors.purple,
        ),
        MPChatMenuItem(
          id: '5',
          title: 'AI 陪伴机器人公司及品牌',
          icon: Icons.smart_toy,
          iconColor: Colors.green,
        ),
        MPChatMenuItem(
          id: '6',
          title: '总结文档内容',
          icon: Icons.description,
          iconColor: Colors.orange,
        ),
        MPChatMenuItem(
          id: '7',
          title: '用产品模型生成视频',
          icon: Icons.play_circle,
          iconColor: Colors.red,
        ),
        MPChatMenuItem(
          id: '8',
          title: '介绍 Genspark',
          icon: Icons.info,
          iconColor: Colors.blue,
        ),
        MPChatMenuItem(
          id: '9',
          title: '闪念贝壳发展与融资',
          icon: Icons.business,
          iconColor: Colors.teal,
        ),
        MPChatMenuItem(
          id: '10',
          title: '文字提取与介绍',
          icon: Icons.text_fields,
          iconColor: Colors.yellow[700],
        ),
      ];
      _isLoading = false;
      notifyListeners();
    });
  }

  /// 刷新数据（未来可以替换为真实接口调用）
  Future<void> refreshConversations() async {
    _isLoading = true;
    notifyListeners();

    // 模拟网络请求
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 这里未来可以调用真实接口
    // final result = await fetchRecentConversations();
    // _recentConversations = result;
    
    _isLoading = false;
    notifyListeners();
  }

  /// 搜索对话
  void searchConversations(String query) {
    // 未来实现搜索逻辑
    notifyListeners();
  }
}

