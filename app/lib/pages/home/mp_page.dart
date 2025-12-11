import 'package:flutter/material.dart';
import 'package:omi/pages/home/widgets/mp_home_card.dart';
import 'package:provider/provider.dart';

import 'widgets/mp_home_upload_widget.dart';

class MPPage extends StatelessWidget {
  const MPPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MPHomePageProvider(),
      child: const MPPageContent(),
    );
  }
}

class MPPageContent extends StatefulWidget {
  const MPPageContent({super.key});

  @override
  State<MPPageContent> createState() => _MPPageContentState();
}

class _MPPageContentState extends State<MPPageContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MPHomePageProvider>();
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
          provider.loadMore();
        }
      });
      provider.bootstrap();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Consumer<MPHomePageProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                _buildHeader(context, provider),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: MPHomeUploadWidget(
                    title: provider.uploadTitle,
                    transferredCount: provider.uploadedCount,
                    totalCount: provider.totalCount,
                    percent: provider.uploadPercent,
                    speedText: provider.speedText,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '记忆记录',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            '共',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showEditRecordCountDialog(context, provider),
                            child: Text(
                              '${provider.recordCount}',
                              style: const TextStyle(
                                color: Color(0xFF306CFF),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Text(
                            ' 条记录',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.refresh,
                    color: const Color(0xFF306CFF),
                    backgroundColor: Colors.white,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 60 &&
                            notification is ScrollUpdateNotification) {
                          provider.loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: provider.items.length + (provider.loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= provider.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final item = provider.items[index];
                          return MPHomeCard(
                            dateText: item.dateText,
                            tagText: item.tagText,
                            tagBackgroundColor: item.tagColor,
                            headerText: item.headerText,
                            timeText: item.timeText,
                            secondsText: item.secondsText,
                            description: item.description,
                            onMorePressed: () => provider.onCardMore(item),
                            onViewDetail: () => provider.onCardViewDetail(item),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MPHomePageProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: provider.onLeftWidgetTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(18, 0, 0, 0),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.drag_handle, color: Color(0xFF4A4A4A), size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _showEditTitleDialog(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(18, 0, 0, 0),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        provider.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit, size: 16, color: Color(0xFF6F6F6F)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildIconButton(
            icon: Icons.search,
            onTap: provider.onSearchTap,
          ),
          const SizedBox(width: 10),
          _buildIconButton(
            icon: Icons.add,
            onTap: provider.onAddTap,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(18, 0, 0, 0),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF4A4A4A), size: 18),
      ),
    );
  }

  Future<void> _showEditTitleDialog(BuildContext context, MPHomePageProvider provider) async {
    final controller = TextEditingController(text: provider.title);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改标题'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入新的标题',
            ),
            onSubmitted: (value) {
              provider.updateTitle(value);
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                provider.updateTitle(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditRecordCountDialog(BuildContext context, MPHomePageProvider provider) async {
    final controller = TextEditingController(text: provider.recordCount.toString());
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改记录数'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '请输入记录条数'),
            onSubmitted: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                provider.updateRecordCount(parsed);
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text);
                if (parsed != null) {
                  provider.updateRecordCount(parsed);
                }
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

class MPMemoryItem {
  MPMemoryItem({
    required this.dateText,
    required this.tagText,
    required this.tagColor,
    required this.headerText,
    required this.timeText,
    this.secondsText,
    this.description,
  });

  final String dateText;
  final String tagText;
  final Color tagColor;
  final String headerText;
  final String timeText;
  final String? secondsText;
  final String? description;
}

class MPHomePageProvider extends ChangeNotifier {
  String title = 'MemoPin 传输管理器';
  String uploadTitle = '正在从 MemoPin 传输录音至 APP...';
  int uploadedCount = 1;
  int totalCount = 1;
  double uploadPercent = 10;
  String speedText = '0.00KB/S';
  int recordCount = 7;
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  final List<MPMemoryItem> items = [];

  void bootstrap() {
    _seed();
  }

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 450));
    _seed();
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    items.addAll(_generateMockItems(start: items.length));
    recordCount = items.length;
    if (items.length >= 30) {
      hasMore = false;
    }
    loadingMore = false;
    notifyListeners();
  }

  void updateTitle(String newTitle) {
    if (newTitle.trim().isEmpty) return;
    title = newTitle.trim();
    notifyListeners();
  }

  void updateRecordCount(int value) {
    if (value < 0) return;
    recordCount = value;
    notifyListeners();
  }

  void onLeftWidgetTap() {
    debugPrint('Left widget tapped');
  }

  void onSearchTap() {
    debugPrint('Search tapped');
  }

  void onAddTap() {
    debugPrint('Add tapped');
  }

  void onCardMore(MPMemoryItem item) {
    debugPrint('More tapped for ${item.headerText}');
  }

  void onCardViewDetail(MPMemoryItem item) {
    debugPrint('View detail for ${item.headerText}');
  }

  void _seed() {
    items
      ..clear()
      ..addAll(_generateMockItems());
    recordCount = items.length;
    uploadPercent = 70;
    uploadedCount = 1;
    totalCount = 1;
  }

  List<MPMemoryItem> _generateMockItems({int start = 0}) {
    final base = [
      MPMemoryItem(
        dateText: '07-22',
        tagText: '任务提醒',
        tagColor: const Color(0xFFF4B95A),
        headerText: 'X头小鱼塘养殖🐟产品设计',
        timeText: '2023-07-22 14:42:10',
        secondsText: '11s',
        description: '产品经过了多次测试，确定了方向；系统自动生成产品文档并输出设计稿。',
      ),
      MPMemoryItem(
        dateText: '07-22',
        tagText: '待确认需求',
        tagColor: const Color(0xFFF57F17),
        headerText: '音视频会议里的 ToDo 话术要素补全',
        timeText: '2023-07-22 14:32:10',
        secondsText: '07s',
        description: '系统提取了会议中的遗漏信息，需确认关键要素并补全记录。',
      ),
      MPMemoryItem(
        dateText: '10-30',
        tagText: 'Daily Insight',
        tagColor: const Color(0xFF3E78F7),
        headerText: 'Daily Insight',
        timeText: '2023-09-30 09:30:20',
        secondsText: '10s',
        description: '今日重点回顾已生成，包含录音转写、摘要及关键行动项。',
      ),
      MPMemoryItem(
        dateText: '今天',
        tagText: '待确认需求',
        tagColor: const Color(0xFFEA4335),
        headerText: '工作会议纪要',
        timeText: '2023-10-30 08:30:00',
        description: '系统整理了会议要点和待办，涉及交付节奏、验收标准及风险。',
      ),
      MPMemoryItem(
        dateText: '某用户',
        tagText: '待确认需求',
        tagColor: const Color(0xFF27AE60),
        headerText: '收藏夹的需求澄清',
        timeText: '2023-10-29 20:00:00',
        secondsText: '10s',
        description: '需确定收藏夹的数据结构、同步逻辑以及跨端一致性方案。',
      ),
    ];

    return List.generate(5, (index) {
      final template = base[index % base.length];
      return MPMemoryItem(
        dateText: template.dateText,
        tagText: template.tagText,
        tagColor: template.tagColor,
        headerText: '${template.headerText} #${start + index + 1}',
        timeText: template.timeText,
        secondsText: template.secondsText,
        description: template.description,
      );
    });
  }
}
