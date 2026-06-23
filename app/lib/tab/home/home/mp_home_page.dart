import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:memo_pin/common/mp_route_observer.dart';
import 'package:memo_pin/common/mp_system_ui_region.dart';
import 'package:memo_pin/tab/home/connect_device/mp_connect_device_page.dart';
import 'package:memo_pin/tab/home/home/mp_home_cubit.dart';
import 'package:memo_pin/tab/home/insights/mp_home_insights_list_page.dart';
import 'package:memo_pin/tab/home/todayFocus/mp_today_focus_page.dart';
import 'package:memo_pin/tab/home/home/widgets/mp_home_audio_status_bar.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';

import '../../../audio/import/mp_audio_import_utils.dart';
import '../../../audio/record/mp_audio_record_popup.dart';
import '../../../blu/mp_ble_connection_helper.dart';
import '../../../audio/record/mp_global_recording_coordinator.dart';
import '../../../common/mp_date_utils.dart';
import '../../../common/mp_home_notification.dart';
import '../../../common/mp_todo_context_utile.dart';
import '../../../common/mp_dismissible_modal_backdrop.dart';
import '../../../common/omi_edit_todo_popup.dart';
import '../../../generated/assets.dart';
import '../../../http/schema/mp_home.dart';
import '../../../http/schema/mp_insight.dart';
import '../../memory/detail/mp_memory_detail_helper.dart';
import 'dialog/mp_quick_capture_dialog.dart';

/// MemoPin 首页（对齐 react `HomeTab` 主视图区）
class MPHomePage extends StatefulWidget {
  const MPHomePage({super.key, this.onViewAllMemories, this.isTabActive = true});

  /// 点击 Recent Memory「查看全部」时切换到底部 Memory Tab
  final VoidCallback? onViewAllMemories;

  /// 当前是否为底部导航选中的 Home Tab（与 [IndexedStack] 配合；从其它 Tab 切回时为 `true` 触发刷新）。
  final bool isTabActive;

  @override
  State<MPHomePage> createState() => _MPHomePageState();
}

class _MPHomePageState extends State<MPHomePage> with WidgetsBindingObserver, RouteAware {
  late final MPHomeCubit _cubit = MPHomeCubit()..start();

  StreamSubscription<MPBleMemopinRecordingStateChangedPayload>? _bleRecordingStateSub;
  bool? _lastBleDeviceRecording;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bleRecordingStateSub = MPHomeNotification.listenBleMemopinRecordingState(
      (MPBleMemopinRecordingStateChangedPayload payload) {
        if (!mounted) {
          return;
        }
        final bool now = payload.isRecording;
        if (now && _lastBleDeviceRecording != true) {
          unawaited(MPGlobalRecordingCoordinator.instance.notifyBleDeviceRecordingStarted());
        }
        _lastBleDeviceRecording = now;
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      mpRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _bleRecordingStateSub?.cancel();
    mpRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  /// 自首页 push 的全屏 / 二级路由 pop 后恢复展示时刷新（与 [isTabActive] 无关，故单独判断）。
  @override
  void didPopNext() {
    if (widget.isTabActive) {
      _cubit.loadData();
      unawaited(_cubit.refreshBleConnectionState());
    }
  }

  @override
  void didUpdateWidget(MPHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive && !oldWidget.isTabActive) {
      _cubit.loadData();
    }
  }

  /// 应用回到前台：检测待传本地音频；当前展示 Home Tab 时再刷新列表。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.onAppResumed(shouldRefreshHomeData: widget.isTabActive);
    }
  }

  Future<void> _importFromFileWithProgress() async {
    await MPAudioImportUtils.pickFromFileWithProgress(
      onProgress: ({required int fileIndex, required int fileTotal, required int progressPercent}) {},
    );
  }

  Future<void> _onRefresh() async {
    _cubit.loadData();
  }

  Future<void> _onTapHomeTodo(MPHomeTodoItem item) async {
    if (!mounted) {
      return;
    }
    final MPTodoContextStruct todoContext = await MPTodoContextUtile.getTodoContext(
      memoryId: item.memoryId,
      insightId: item.insightId,
    );

    if (!mounted) {
      return;
    }
    await showOmiEditTodoPopup(
      context,
      params: OmiEditTodoPopupParams(
        title: item.title,
        contextMemoryLabel: todoContext.label,
        contextMemoryTitle: todoContext.title,
        contextMetaLine: todoContext.metaLine,
        notes: item.description ?? '',
        whenLabel: 'Today',
        timeLabel: (item.time == null || item.time!.isEmpty) ? '--:--' : item.time!,
        todoId: item.id,
        memoryId: item.memoryId,
        memoryType: todoContext.memoryType,
        insightId: item.insightId,
        insightType: todoContext.insightType,
        deadlineUnixSec: MPDateUtils.normalizeTodoDeadline(item.deadlineUnixSec),
      ),
      onDelete: () async {
        await _cubit.loadData();
        return true;
      },
    );
  }

  void _openAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return MPDismissibleModalBackdrop(
          child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.paddingOf(ctx).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        _OptionTile(
                          icon: Icons.mic_none_outlined,
                          iconGradient: const LinearGradient(colors: <Color>[Color(0xFF007AFF), Color(0xFF0051D5)]),
                          title: 'Start Recording',
                          subtitle: 'Record a new audio memory',
                          onTap: () async {
                            Navigator.pop(ctx);
                            if (!context.mounted) {
                              return;
                            }
                            if (await MPBleConnectionHelper.showBlockMessageIfMemoPinDeviceIsRecording(
                              context: context,
                            )) {
                              return;
                            }
                            if (!context.mounted) {
                              return;
                            }
                            await showMPAudioRecordPopup(context);
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: const Color(0xFFF2F2F7),
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx),
                              customBorder: const CircleBorder(),
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(Icons.close, color: Color(0xFF3C3C43), size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    _OptionTile(
                      icon: Icons.edit_note_outlined,
                      iconGradient: const LinearGradient(colors: <Color>[Color(0xFFFF9F40), Color(0xFFFF8C00)]),
                      title: 'Quick Capture',
                      subtitle: 'Type or speak a quick note',
                      onTap: () async {
                        Navigator.pop(ctx);
                        await MPQuickCaptureDialog.show(context);
                      },
                    ),
                    const Divider(height: 1),
                    _OptionTile(
                      icon: Icons.upload_file_outlined,
                      iconGradient: const LinearGradient(colors: <Color>[Color(0xFF34C759), Color(0xFF28A745)]),
                      title: 'Import Audio',
                      subtitle: 'Choose an audio file from your device',
                      onTap: () {
                        Navigator.pop(ctx);
                        _importFromFileWithProgress();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                                Navigator.of(context)
                                    .push(MaterialPageRoute<void>(builder: (_) => const MPConnectDevicePage()))
                                    .then((_) => _cubit.refreshBleConnectionState());
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
                                child: state.isBleConnected
                                    ? const _MPHomeNavConnectedIcon()
                                    : const _MPHomeNavBullseye(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'MemoPin',
                            style: TextStyle(
                              fontSize: OmiFontSize.t8_17,
                              fontWeight: OmiFontWeight.medium,
                              color: omiSecondaryBodyText,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => MPToastUtils.showFeatureComingSoon(message: 'Calendar'),
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
                  if (state.audioStatus != null) MPHomeAudioStatusBar(status: state.audioStatus!),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      triggerMode: RefreshIndicatorTriggerMode.anywhere,
                      notificationPredicate: (ScrollNotification notification) => notification.depth == 0,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                        children: <Widget>[
                          _TodayFocusCard(
                            todos: state.upNextTodos,
                            onViewAll: () {
                              Navigator.of(
                                context,
                              ).push(MaterialPageRoute<void>(builder: (_) => const MPTodayFocusPage()));
                            },
                            onTodoTap: _onTapHomeTodo,
                          ),
                          const SizedBox(height: 16),
                          _RecentMemoryCard(
                            memories: state.recentMemories,
                            onViewAll: widget.onViewAllMemories,
                            onMemoryTap: (MPHomeMemoryItem m) => MPMemoryDetailPageHelper.navigateToDetailPage(
                              context,
                              m.id,
                              m.type,
                              createAt: m.createAt,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InsightsCard(
                            insightOverview: state.insightOverview,
                            onTap: () => Navigator.of(
                              context,
                            ).push(MaterialPageRoute<void>(builder: (_) => const MPHomeInsightsListPage())),
                          ),
                          if (state.transcriptionBanner.showBanner) ...<Widget>[
                            const SizedBox(height: 16),
                            _TranscriptionUsageCard(
                              banner: state.transcriptionBanner,
                              onClose: () => _cubit.closeTranscriptionBanner(),
                            ),
                          ],
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
      child: CustomPaint(painter: _MPHomeBullseyePainter(color: _kMarkColor)),
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
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE9F8EE)),
      child: const Center(
        child: SizedBox(width: 11, height: 11, child: CustomPaint(painter: _MPHomeConnectedDotPainter())),
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
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
                    style: TextStyle(
                      fontSize: OmiFontSize.t8_17,
                      fontWeight: OmiFontWeight.bold,
                      color: omiMainBodyText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: OmiFontSize.t4_13, color: omiAuxiliaryText),
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
  const _TodayFocusCard({required this.todos, required this.onViewAll, required this.onTodoTap});

  final List<MPHomeTodoItem> todos;
  final VoidCallback onViewAll;
  final void Function(MPHomeTodoItem) onTodoTap;

  @override
  Widget build(BuildContext context) {
    final List<MPHomeTodoItem> shown = todos.take(3).toList();
    final bool showAddMoreCard = shown.isNotEmpty && shown.length < 3;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
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
                    fontSize: OmiFontSize.t8_17,
                    fontWeight: OmiFontWeight.bold,
                    color: omiMainBodyText,
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
                        color: omiEmphasisGreen,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        height: 1.1,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: omiEmphasisGreen),
                  ],
                ),
              ),
            ],
          ),
          if (shown.isEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: OmiFontSize.t6_15,
                fontWeight: OmiFontWeight.medium,
                color: omiMainBodyText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your upcoming tasks from recordings will appear here.',
              style: TextStyle(
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
                color: omiAuxiliaryText,
                height: 1.4,
              ),
            ),
          ],
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
                          height: 1.5,
                          color: omiSecondaryBodyText,
                          fontWeight: OmiFontWeight.medium,
                          decoration: todo.completed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Text(
                      todo.time ?? 'No deadline',
                      style: TextStyle(
                        fontSize: OmiFontSize.t4_13,
                        color: omiAuxiliaryText,
                        fontWeight: OmiFontWeight.medium,
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
                    color: omiAuxiliaryText,
                    fontWeight: OmiFontWeight.regular,
                    height: 1.2,
                  ),
                ),
              ),
          ],
          if (showAddMoreCard) ...<Widget>[
            SizedBox(height: shown.isNotEmpty ? 8 : 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FFFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDF5EA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Add more tasks to Today\'s Focus to stay productive',
                    style: TextStyle(
                      fontSize: OmiFontSize.t5_14,
                      color: omiSecondaryBodyText,
                      fontWeight: OmiFontWeight.regular,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onViewAll,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: omiEmphasisGreen,
                        foregroundColor: omiWhiteText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: TextStyle(
                          fontSize: OmiFontSize.t5_14,
                          fontWeight: OmiFontWeight.medium,
                          height: 1.2,
                          color: omiWhiteText,
                        ),
                      ),
                      child: const Text('Add to Today\'s Focus'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentMemoryCard extends StatelessWidget {
  const _RecentMemoryCard({required this.memories, required this.onViewAll, required this.onMemoryTap});

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
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
                    fontSize: OmiFontSize.t8_17,
                    fontWeight: OmiFontWeight.bold,
                    color: omiMainBodyText,
                    height: 1.25,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll ?? () => MPToastUtils.showFeatureComingSoon(message: 'Memory list'),
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
                        color: omiEmphasisOrange,
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.medium,
                        height: 1.1,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: omiEmphasisOrange),
                  ],
                ),
              ),
            ],
          ),
          if (shown.isEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'No memories yet',
              style: TextStyle(
                fontSize: OmiFontSize.t6_15,
                fontWeight: OmiFontWeight.medium,
                color: omiMainBodyText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Voice memos you capture will show up here.',
              style: TextStyle(
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
                color: omiAuxiliaryText,
                height: 1.4,
              ),
            ),
          ],
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
                          fontSize: OmiFontSize.t6_15,
                          color: omiSecondaryBodyText,
                          height: 1.5,
                          fontWeight: OmiFontWeight.medium,
                        ),
                      ),
                    ),
                    Text(
                      m.timeLabel,
                      style: TextStyle(
                        fontSize: OmiFontSize.t4_13,
                        color: omiAuxiliaryText,
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
  const _InsightsCard({required this.insightOverview, required this.onTap});

  final MPHomeInsightOverviewStruct insightOverview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String titleLine = insightOverview.title.trim().isEmpty ? 'Insights' : insightOverview.title.trim();
    final String sub = insightOverview.subTitle.trim();
    final String body = insightOverview.content.trim();
    final bool hasBody = body.isNotEmpty;

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
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
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
                            gradient: LinearGradient(colors: <Color>[Color(0xFFA855F7), Color(0xFFC084FC)]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      titleLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: OmiFontSize.t8_17,
                                        fontWeight: OmiFontWeight.bold,
                                        color: omiMainBodyText,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (sub.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 2),
                                Text(
                                  sub,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: OmiFontSize.t5_14,
                                    color: omiAuxiliaryText,
                                    fontWeight: OmiFontWeight.medium,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (hasBody)
                      Text(
                        body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: OmiFontSize.t5_14,
                          height: 1.4,
                          color: omiMainBodyText,
                          fontWeight: OmiFontWeight.medium,
                        ),
                      )
                    else
                      Text(
                        'No insights yet',
                        style: TextStyle(
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.medium,
                          color: omiMainBodyText,
                          height: 1.5,
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
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.center,
                    child: Text(
                      '${insightOverview.newInsightCount}',
                      style: TextStyle(
                        fontSize: OmiFontSize.t2_11,
                        fontWeight: OmiFontWeight.bold,
                        color: Colors.white,
                      ),
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

class _TranscriptionUsageCard extends StatelessWidget {
  const _TranscriptionUsageCard({required this.banner, required this.onClose});

  final MPTranscriptionBannerStruct banner;
  final VoidCallback onClose;

  /// 构建转录用量提示文案。
  String _buildContent() {
    final NumberFormat formatter = NumberFormat('#,###');
    final String used = formatter.format(banner.quotaMinutesUsed);
    final String total = formatter.format(banner.currentMinutes);
    return "You're halfway through your test transcription credits. $used / $total min used.";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 40, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: <Color>[Color(0xFF007AFF), Color(0xFF0051D5)]),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(Assets.mpClock, width: 8, height: 8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Transcription usage',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.bold,
                          color: omiMainBodyText,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildContent(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: OmiFontSize.t4_13,
                          color: omiAuxiliaryText,
                          fontWeight: OmiFontWeight.regular,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: Icon(Icons.close, color: Color(0xFFC7C7CC), size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
