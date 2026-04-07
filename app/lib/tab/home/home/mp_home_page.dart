import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/blu/mp_bluetooth_connection_helper.dart';
import 'package:memo_pin/common/mp_system_ui_region.dart';
import 'package:memo_pin/tab/home/connect_device/mp_connect_device_page.dart';
import 'package:memo_pin/tab/home/home/mp_home_cubit.dart';
import 'package:memo_pin/tab/home/insights/mp_home_insights_list_page.dart';
import 'package:memo_pin/tab/home/todayFocus/mp_today_focus_page.dart';
import 'package:memo_pin/tab/home/home/widgets/mp_home_audio_status_bar.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';

import '../../../audio/record/mp_audio_record_popup.dart';
import '../../../http/schema/mp_home.dart';

/// MemoPin 首页（对齐 react `HomeTab` 主视图区）
class MPHomePage extends StatefulWidget {
  const MPHomePage({super.key, this.onViewAllMemories});

  /// 点击 Recent Memory「查看全部」时切换到底部 Memory Tab
  final VoidCallback? onViewAllMemories;

  @override
  State<MPHomePage> createState() => _MPHomePageState();
}

class _MPHomePageState extends State<MPHomePage> {
  late final MPHomeCubit _cubit = MPHomeCubit()..start();
  bool _isBleConnected = false;

  @override
  void initState() {
    super.initState();
    _refreshBleConnectionState();
  }

  Future<void> _refreshBleConnectionState() async {
    final bool connected = await MPBluetoothConnectionHelper.hasConnectedBleDevice();
    if (!mounted) {
      return;
    }
    if (_isBleConnected != connected) {
      setState(() {
        _isBleConnected = connected;
      });
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _simulateSyncThreeFiles() async {
    Navigator.pop(context);
    const int total = 3;
    for (int file = 1; file <= total; file++) {
      for (int p = 0; p <= 100; p += 10) {
        _cubit.showSyncingStatus(currentFile: file, totalFiles: total, progress: p);
        await Future<void>.delayed(Duration(milliseconds: file == 1 ? 200 : 150));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    _cubit.clearAudioStatus();
  }

  Future<void> _simulateImport() async {
    Navigator.pop(context);
    for (int p = 0; p <= 100; p += 10) {
      _cubit.showImportingStatus(p);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _cubit.clearAudioStatus();
  }

  Future<void> _onRefresh() async {
    await _cubit.initData();
    await _refreshBleConnectionState();
  }

  void _openAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close, color: secondTextColor),
                      ),
                    ),
                    _OptionTile(
                      icon: Icons.mic_none_outlined,
                      iconGradient: const LinearGradient(
                        colors: <Color>[Color(0xFF007AFF), Color(0xFF0051D5)],
                      ),
                      title: 'Start Recording',
                      subtitle: 'Record a new audio memory',
                      onTap: () async {
                        Navigator.pop(ctx);
                        await showMPAudioRecordPopup(context);
                      },
                    ),
                    const Divider(height: 1),
                    _OptionTile(
                      icon: Icons.edit_note_outlined,
                      iconGradient: const LinearGradient(
                        colors: <Color>[Color(0xFFFF9F40), Color(0xFFFF8C00)],
                      ),
                      title: 'Quick Capture',
                      subtitle: 'Type or speak a quick note',
                      onTap: () {
                        Navigator.pop(ctx);
                        MPToastUtils.showFeatureComingSoon(message: '快速捕捉');
                      },
                    ),
                    const Divider(height: 1),
                    _OptionTile(
                      icon: Icons.upload_file_outlined,
                      iconGradient: const LinearGradient(
                        colors: <Color>[Color(0xFF34C759), Color(0xFF28A745)],
                      ),
                      title: 'Import Audio',
                      subtitle: 'Choose an audio file from your device',
                      onTap: _simulateImport,
                    ),
                    const Divider(height: 1),
                    _OptionTile(
                      icon: Icons.mic_none_outlined,
                      iconGradient: const LinearGradient(
                        colors: <Color>[Color(0xFFFF3B30), Color(0xFFD32F2F)],
                      ),
                      title: 'Demo: MemoPin recording',
                      subtitle: 'Show recording status bar (3s)',
                      onTap: () async {
                        Navigator.pop(ctx);
                        _cubit.showRecordingStatus();
                        await Future<void>.delayed(const Duration(seconds: 3));
                        _cubit.clearAudioStatus();
                      },
                    ),
                    _OptionTile(
                      icon: Icons.cloud_sync_outlined,
                      iconGradient: const LinearGradient(
                        colors: <Color>[Color(0xFF5856D6), Color(0xFF4B4ACF)],
                      ),
                      title: 'Demo: Sync 3 files',
                      subtitle: 'Progress & file index like web prototype',
                      onTap: _simulateSyncThreeFiles,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPHomeCubit>.value(
      value: _cubit,
      child: BlocBuilder<MPHomeCubit, MPHomeState>(
        builder: (BuildContext context, MPHomeState state) {
          return MPSystemUiRegion(
            topBarColor: const Color(0xFFF2F2F7),
            child: ColoredBox(
              color: const Color(0xFFF2F2F7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Row(
                        children: <Widget>[
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const MPConnectDevicePage(),
                                  ),
                                ).then((_) => _refreshBleConnectionState());
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                                ),
                                child: _isBleConnected
                                    ? const _MPHomeNavConnectedIcon()
                                    : const _MPHomeNavBullseye(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'MemoPin',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: secondTextColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => MPToastUtils.showFeatureComingSoon(message: '日历'),
                            icon: Icon(Icons.calendar_today_outlined, color: blueTextColor),
                          ),
                          const SizedBox(width: 4),
                          Material(
                            color: blueTextColor,
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              onTap: _openAddOptions,
                              borderRadius: BorderRadius.circular(999),
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.audioStatus != null)
                    MPHomeAudioStatusBar(status: state.audioStatus!),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                        children: <Widget>[
                          _TodayFocusCard(
                            todos: state.upNextTodos,
                            onViewAll: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(builder: (_) => const MPTodayFocusPage()),
                              );
                            },
                            onTodoTap: (MPHomeTodoItem t) =>
                                MPToastUtils.showFeatureComingSoon(message: '待办「${t.title}」详情'),
                          ),
                          const SizedBox(height: 16),
                          _RecentMemoryCard(
                            memories: state.recentMemories,
                            onViewAll: widget.onViewAllMemories,
                            onMemoryTap: (MPHomeMemoryItem m) =>
                                MPToastUtils.showFeatureComingSoon(message: 'Memory 详情'),
                          ),
                          const SizedBox(height: 16),
                          _InsightsCard(
                            insightOverview: state.insightOverview,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const MPHomeInsightsListPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 首页导航左侧标识：白底圆角块内的同心圆靶心（中心实心点 + 双层细环，浅灰蓝）。
class _MPHomeNavBullseye extends StatelessWidget {
  const _MPHomeNavBullseye();

  static const Color _kMarkColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _MPHomeBullseyePainter(color: _kMarkColor),
      ),
    );
  }
}

/// 首页导航左侧「已连接」图标：浅绿底 + 绿色同心圆点（贴合设计稿）。
class _MPHomeNavConnectedIcon extends StatelessWidget {
  const _MPHomeNavConnectedIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE9F8EE),
      ),
      child: const Center(
        child: SizedBox(
          width: 11,
          height: 11,
          child: CustomPaint(
            painter: _MPHomeConnectedDotPainter(),
          ),
        ),
      ),
    );
  }
}

class _MPHomeConnectedDotPainter extends CustomPainter {
  const _MPHomeConnectedDotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = (size.width < size.height ? size.width : size.height) / 2;

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF53C878)
      ..isAntiAlias = true;
    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF53C878)
      ..isAntiAlias = true;

    canvas.drawCircle(c, r * 0.88, stroke);
    canvas.drawCircle(c, r * 0.55, stroke);
    canvas.drawCircle(c, r * 0.2, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 绘制 MemoPin 导航栏小标：外环、内环（描边）与中心实心圆。
class _MPHomeBullseyePainter extends CustomPainter {
  const _MPHomeBullseyePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.5;
    final double r = (size.width < size.height ? size.width : size.height) * 0.5;

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(Offset(cx, cy), r * 0.88, stroke);
    canvas.drawCircle(Offset(cx, cy), r * 0.52, stroke);
    canvas.drawCircle(Offset(cx, cy), r * 0.18, fill);
  }

  @override
  bool shouldRepaint(covariant _MPHomeBullseyePainter oldDelegate) => oldDelegate.color != color;
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final LinearGradient iconGradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: iconGradient,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({
    required this.todos,
    required this.onViewAll,
    required this.onTodoTap,
  });

  final List<MPHomeTodoItem> todos;
  final VoidCallback onViewAll;
  final void Function(MPHomeTodoItem) onTodoTap;

  @override
  Widget build(BuildContext context) {
    final List<MPHomeTodoItem> shown = todos.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Today\'s Focus',
                  style: TextStyle(
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.medium,
                    color: Color(0xFF1A1A1A),
                    height: 1.25,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        height: 1.1,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ],
          ),
          if (shown.isNotEmpty) const SizedBox(height: 10),
          for (final MPHomeTodoItem todo in shown) ...<Widget>[
            InkWell(
              onTap: () => onTodoTap(todo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(Icons.star_border_rounded, size: 18, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        todo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: OmiFontSize.t6_15,
                          height: 1.42,
                          color: const Color(0xFF262631),
                          fontWeight: OmiFontWeight.medium,
                          decoration: todo.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (todo.time != null)
                      Text(
                        todo.time!,
                        style: TextStyle(
                          fontSize: OmiFontSize.t4_13,
                          color: Color(0xFF9A9CAA),
                          fontWeight: OmiFontWeight.regular,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (todo.reason != null)
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 6),
                child: Text(
                  '→ ${todo.reason}',
                  style: TextStyle(
                    fontSize: OmiFontSize.t4_13,
                    color: Color(0xFF9A9CAA),
                    fontWeight: OmiFontWeight.regular,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RecentMemoryCard extends StatelessWidget {
  const _RecentMemoryCard({
    required this.memories,
    required this.onViewAll,
    required this.onMemoryTap,
  });

  final List<MPHomeMemoryItem> memories;
  final VoidCallback? onViewAll;
  final void Function(MPHomeMemoryItem) onMemoryTap;

  @override
  Widget build(BuildContext context) {
    final List<MPHomeMemoryItem> shown = memories.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFCF5), Color(0xFFFFFEF9), Colors.white],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Recent Memory',
                  style: TextStyle(
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.medium,
                    color: const Color(0xFF1A1A1A),
                    height: 1.15,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll ?? () => MPToastUtils.showFeatureComingSoon(message: 'Memory 列表'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'View All',
                      style: TextStyle(
                        color: const Color(0xFFD97706),
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        height: 1.1,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFFD97706)),
                  ],
                ),
              ),
            ],
          ),
          if (shown.isNotEmpty) const SizedBox(height: 10),
          for (final MPHomeMemoryItem m in shown)
            InkWell(
              onTap: () => onMemoryTap(m),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        m.titleOrDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: OmiFontSize.t5_14,
                          color: const Color(0xFF262631),
                          height: 1.35,
                          fontWeight: OmiFontWeight.medium,
                        ),
                      ),
                    ),
                    Text(
                      m.timeLabel,
                      style: TextStyle(
                        fontSize: OmiFontSize.t4_13,
                        color: const Color(0xFF9A9CAA),
                        fontWeight: OmiFontWeight.regular,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.insightOverview,
    required this.onTap,
  });

  final MPHomeInsightOverviewStruct insightOverview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFFAF9FC), Color(0xFFFCFBFD), Colors.white],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[Color(0xFFA855F7), Color(0xFFC084FC)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                insightOverview.title,
                                style: TextStyle(
                                  fontSize: OmiFontSize.t7_16,
                                  fontWeight: OmiFontWeight.medium,
                                  color: const Color(0xFF1A1A1A),
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                insightOverview.subTitle,
                                style: TextStyle(
                                  fontSize: OmiFontSize.t4_13,
                                  color: const Color(0xFF9A9CAA),
                                  fontWeight: OmiFontWeight.regular,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      insightOverview.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: OmiFontSize.t5_14,
                        height: 1.35,
                        color: const Color(0xFF262631),
                        fontWeight: OmiFontWeight.regular,
                      ),
                    ),
                  ],
                ),
              ),
              if (insightOverview.newInsightCount > 0)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${insightOverview.newInsightCount}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
