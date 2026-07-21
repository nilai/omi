import 'package:flutter/material.dart';

import '../../../common/mp_memory_top_tabs.dart';
import '../../../common/mp_navigation_bar.dart';
import '../../../utils/omi_color_utils.dart';
import 'all/omi_all_page.dart';
import 'people/omi_people_page.dart';
import 'projects/omi_projects_page.dart';

/// Memory 根页：顶部导航 + All / People / Projects 分段内容
class OmiMemoryPage extends StatefulWidget {
  const OmiMemoryPage({
    super.key,
    this.isMemoryTabActive = true,
    this.onStartRecording,
  });

  /// 底部导航是否选中 Memory（与 [MainTabPage] 中 Memory 项下标一致，当前为 `1`）。
  final bool isMemoryTabActive;

  /// 从 Memory 空态发起录音时，由底部导航容器先切换到 Home，再执行录音流程。
  final Future<void> Function()? onStartRecording;

  @override
  State<OmiMemoryPage> createState() => _OmiMemoryPageState();
}

class _OmiMemoryPageState extends State<OmiMemoryPage> {
  int _tabIndex = 0;

  /// 递增后由 [OmiAllPage] 监听并调用 [OmiAllCubit.load]（避免 GlobalKey 穿透）。
  late final ValueNotifier<int> _allListRefreshNonce;

  @override
  void initState() {
    super.initState();
    _allListRefreshNonce = ValueNotifier<int>(0);
  }

  @override
  void didUpdateWidget(OmiMemoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 底部从其它 Tab 切回 Memory，且当前仍为 All 列表时刷新。
    if (widget.isMemoryTabActive &&
        !oldWidget.isMemoryTabActive &&
        _tabIndex == 0) {
      _requestAllListRefresh();
    }
  }

  @override
  void dispose() {
    _allListRefreshNonce.dispose();
    super.dispose();
  }

  void _requestAllListRefresh() {
    _allListRefreshNonce.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPNavigationBar.preferredSizeOf(context),
        child: const MPNavigationBar(
          variant: MPNavigationBarVariant.memory,
          backgroundColor: Colors.white,
          showPrimaryAction: false,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MPMemoryTopTabs(
            index: _tabIndex,
            onChanged: (int i) {
              final int prev = _tabIndex;
              setState(() => _tabIndex = i);
              // All 列表由隐藏变为可见（从 People / Projects 切回）时刷新。
              if (i == 0 && prev != 0) {
                _requestAllListRefresh();
              }
            },
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              sizing: StackFit.expand,
              children: <Widget>[
                OmiAllPage(
                  refreshListenable: _allListRefreshNonce,
                  onStartRecording: widget.onStartRecording,
                ),
                const OmiPeoplePage(),
                const OmiProjectsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
