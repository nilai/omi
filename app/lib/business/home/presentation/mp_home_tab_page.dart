import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:permission_manager/permission_manager.dart';
import 'package:omi/business/home/presentation/pages/mp_all_insights_list_page.dart';
import 'package:omi/business/home/presentation/pages/mp_calendar_page.dart';
import 'package:omi/business/home/presentation/pages/mp_device_connection_page.dart';
import 'package:omi/business/home/presentation/pages/mp_todo_list_page.dart';
import 'package:omi/business/recording/presentation/mp_recording_permission_page.dart';
import 'package:omi/business/shared/models/mp_business_models.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';
import 'package:omi/permission/omi_permission_service.dart';

class MPHomeTabPage extends StatefulWidget {
  const MPHomeTabPage({
    super.key,
    required this.controller,
  });

  final MPBusinessController controller;

  @override
  State<MPHomeTabPage> createState() => _MPHomeTabPageState();
}

/// Quick Capture 与 React 一致：输入 → transcribing → analyzing → 二段确认
enum _QuickCapturePhase { input, transcribing, analyzing, confirm }

class _MPHomeTabPageState extends State<MPHomeTabPage> {
  final TextEditingController _quickCaptureController = TextEditingController();
  Timer? _recordingTimer;
  bool _showRecordingModal = false;
  bool _recordingMinimized = false;
  bool _isRecording = false;
  bool _hasStartedRecording = false;
  int _recordingSeconds = 0;
  bool _showQuickCaptureModal = false;
  _QuickCapturePhase _quickCapturePhase = _QuickCapturePhase.input;
  bool _showQuickCaptureConfirm = false;
  bool _quickCaptureStructuredMode = true;
  List<_ParsedItem> _parsedTodos = <_ParsedItem>[];
  List<_ParsedItem> _parsedMemos = <_ParsedItem>[];
  String _originalQuickCaptureText = '';
  String? _selectedTodoId;

  /// 递增以作废正在进行的 Quick Capture 管道（transcribing / analyzing）
  int _quickCaptureGeneration = 0;

  void _invalidateQuickCapturePipeline() {
    _quickCaptureGeneration++;
  }

  @override
  void dispose() {
    _invalidateQuickCapturePipeline();
    _recordingTimer?.cancel();
    _quickCaptureController.dispose();
    super.dispose();
  }

  String _formatRecordingTime() {
    final mins = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _openRecordingModal() {
    setState(() {
      _showRecordingModal = true;
      _recordingMinimized = false;
      _isRecording = false;
      _hasStartedRecording = false;
      _recordingSeconds = 0;
    });
  }

  void _minimizeRecording() {
    setState(() {
      _showRecordingModal = false;
      _recordingMinimized = true;
    });
  }

  void _expandRecordingFromBar() {
    setState(() {
      _showRecordingModal = true;
      _recordingMinimized = false;
    });
  }

  void _startRecording() {
    setState(() {
      _hasStartedRecording = true;
      _isRecording = true;
    });
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordingSeconds += 1;
      });
    });
  }

  /// 录音开始前校验麦克风；未授权时引导至 [MPRecordingPermissionPage] 或系统设置
  Future<void> _maybeStartRecording() async {
    final already = await OmiPermissionService.hasMicrophonePermission();
    if (!mounted) {
      return;
    }
    if (already) {
      _startRecording();
      return;
    }
    final status = await OmiPermissionService.requestMicrophonePermissionStatus();
    if (!mounted) {
      return;
    }
    if (status == PermissionManagerStatus.granted) {
      _startRecording();
      return;
    }
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('需要麦克风权限'),
          content: Text(
            status == PermissionManagerStatus.permanentlyDenied
                ? '麦克风权限已被拒绝且无法再次弹窗，请到「去设置」或「权限说明」中开启。'
                : '需要麦克风权限才能录音。可前往权限说明页申请，或在系统设置中开启。',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => const MPRecordingPermissionPage(),
                  ),
                );
              },
              child: const Text('权限说明'),
            ),
            if (status == PermissionManagerStatus.permanentlyDenied)
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await PermissionManager.openAppSettings();
                },
                child: const Text('去设置'),
              ),
          ],
        );
      },
    );
  }

  void _pauseRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  void _closeRecording() {
    if (_hasStartedRecording) {
      showCupertinoDialog<void>(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Cancel Recording'),
            content: const Text('确定取消当前录音吗？'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('继续录音'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  _recordingTimer?.cancel();
                  setState(() {
                    _showRecordingModal = false;
                    _recordingMinimized = false;
                    _isRecording = false;
                    _hasStartedRecording = false;
                    _recordingSeconds = 0;
                  });
                },
                isDestructiveAction: true,
                child: const Text('取消录音'),
              ),
            ],
          );
        },
      );
      return;
    }
    setState(() {
      _showRecordingModal = false;
      _recordingMinimized = false;
    });
  }

  void _saveRecording() {
    _recordingTimer?.cancel();
    widget.controller.addMemoryFromRecording(
      title: '录音记忆 ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );
    setState(() {
      _showRecordingModal = false;
      _recordingMinimized = false;
      _isRecording = false;
      _hasStartedRecording = false;
      _recordingSeconds = 0;
    });
  }

  void _openQuickCaptureModal() {
    _invalidateQuickCapturePipeline();
    setState(() {
      _showQuickCaptureModal = true;
      _quickCapturePhase = _QuickCapturePhase.input;
      _showQuickCaptureConfirm = false;
      _quickCaptureStructuredMode = true;
      _parsedTodos = <_ParsedItem>[];
      _parsedMemos = <_ParsedItem>[];
      _quickCaptureController.clear();
      _originalQuickCaptureText = '';
    });
  }

  Future<void> _runQuickCapturePipeline() async {
    final raw = _quickCaptureController.text.trim();
    if (raw.isEmpty) {
      return;
    }
    final gen = _quickCaptureGeneration;
    setState(() => _quickCapturePhase = _QuickCapturePhase.transcribing);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted || gen != _quickCaptureGeneration) {
      return;
    }
    setState(() => _quickCapturePhase = _QuickCapturePhase.analyzing);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted || gen != _quickCaptureGeneration) {
      return;
    }
    final segments = raw
        .split(RegExp(r'[，,。.；;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final todoItems = <_ParsedItem>[];
    final memoItems = <_ParsedItem>[];
    for (var i = 0; i < segments.length; i++) {
      final id = DateTime.now().millisecondsSinceEpoch + i;
      if (i.isEven) {
        todoItems.add(_ParsedItem(id: id, text: segments[i], selected: true));
      } else {
        memoItems.add(_ParsedItem(id: id, text: segments[i], selected: true));
      }
    }
    if (todoItems.isEmpty) {
      todoItems.add(
        _ParsedItem(
          id: DateTime.now().millisecondsSinceEpoch,
          text: raw,
          selected: true,
        ),
      );
    }
    if (!mounted || gen != _quickCaptureGeneration) {
      return;
    }
    setState(() {
      _originalQuickCaptureText = raw;
      _parsedTodos = todoItems;
      _parsedMemos = memoItems;
      _quickCapturePhase = _QuickCapturePhase.confirm;
      _showQuickCaptureConfirm = true;
    });
  }

  /// 关闭 Quick Capture 并中断 transcribing / analyzing 中的 Future
  void _cancelQuickCapture() {
    _invalidateQuickCapturePipeline();
    setState(() {
      _showQuickCaptureModal = false;
      _showQuickCaptureConfirm = false;
      _quickCapturePhase = _QuickCapturePhase.input;
    });
  }

  void _confirmQuickCapture() {
    if (_quickCaptureStructuredMode) {
      for (final item in _parsedTodos.where((it) => it.selected)) {
        widget.controller.addTodoOnly(item.text);
      }
      for (final item in _parsedMemos.where((it) => it.selected)) {
        widget.controller.addMemoOnly(item.text);
      }
    } else {
      widget.controller.addQuickCapture(text: _originalQuickCaptureText);
    }
    setState(() {
      _showQuickCaptureModal = false;
      _showQuickCaptureConfirm = false;
      _quickCapturePhase = _QuickCapturePhase.input;
    });
  }

  void _openTodoDetail(MPTodo todo) {
    setState(() {
      _selectedTodoId = todo.id;
    });
  }

  void _linkTodoToMemory(String todoId, String memoryId) {
    widget.controller.linkTodoToMemory(todoId: todoId, memoryId: memoryId);
    setState(() {
      _selectedTodoId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMain(),
        if (_recordingMinimized) Align(alignment: Alignment.bottomCenter, child: _buildRecordingMinimizedBar()),
        Align(alignment: Alignment.bottomCenter, child: _buildRecordingModal()),
        Align(alignment: Alignment.bottomCenter, child: _buildQuickCaptureModal()),
        Align(alignment: Alignment.bottomCenter, child: _buildTodoDetailModal()),
      ],
    );
  }

  Widget _buildRecordingMinimizedBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: CupertinoColors.systemGrey5,
          onPressed: _expandRecordingFromBar,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRecording ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
                size: 18,
                color: _isRecording ? CupertinoColors.systemRed : CupertinoColors.label,
              ),
              const SizedBox(width: 8),
              Text(
                '录音中 ${_formatRecordingTime()}',
                style: const TextStyle(color: CupertinoColors.label),
              ),
              const SizedBox(width: 8),
              const Text('展开', style: TextStyle(color: CupertinoColors.activeBlue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMain() {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final user = widget.controller.user;
        final todos = widget.controller.todos;
        final todayActive = todos.where((t) => t.category == 'Today' && !t.completed).toList();
        final upNextActive = todos.where((t) => t.category == 'Up Next' && !t.completed).toList();
        final memories = widget.controller.memories;
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Home'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openQuickCaptureModal,
              child: const Text('Quick'),
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Hi, ${user.name}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => MPTodoListPage(controller: widget.controller),
                      ),
                    );
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('查看全部 Todo'),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _openRecordingModal,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Start Recording'),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _openQuickCaptureModal,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Quick Capture'),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(builder: (_) => const MPCalendarPage()),
                    );
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('打开日历视图'),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => MPAllInsightsListPage(controller: widget.controller),
                      ),
                    );
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('查看全部 Insights'),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(builder: (_) => const MPDeviceConnectionPage()),
                    );
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('设备连接'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '今日待办',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Today / Up Next（不含已完成）',
                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                ),
                const SizedBox(height: 8),
                if (todayActive.isEmpty && upNextActive.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '暂无未完成待办',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  ),
                ...todayActive.map((todo) {
                  final linkedMemory = todo.linkedMemoryId == null
                      ? null
                      : widget.controller.getMemoryById(todo.linkedMemoryId!);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _openTodoDetail(todo),
                      child: _MPInfoCard(
                        title: todo.title,
                        subtitle: linkedMemory == null
                            ? '${todo.category} · ${todo.dueLabel ?? '无截止'}'
                            : '${todo.category} · 关联: ${linkedMemory.title}',
                        trailing: 'Todo',
                      ),
                    ),
                  );
                }),
                ...upNextActive.map((todo) {
                  final linkedMemory = todo.linkedMemoryId == null
                      ? null
                      : widget.controller.getMemoryById(todo.linkedMemoryId!);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _openTodoDetail(todo),
                      child: _MPInfoCard(
                        title: todo.title,
                        subtitle: linkedMemory == null
                            ? '${todo.category} · ${todo.dueLabel ?? '无截止'}'
                            : '${todo.category} · 关联: ${linkedMemory.title}',
                        trailing: 'Todo',
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const Text(
                  '最近记忆',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...memories.map((memory) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MPInfoCard(
                      title: memory.title,
                      subtitle: memory.summary,
                      trailing: memory.dateLabel,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordingModal() {
    if (!_showRecordingModal) {
      return const SizedBox.shrink();
    }
    return CupertinoPopupSurface(
      child: Container(
        width: double.infinity,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (_hasStartedRecording)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _minimizeRecording,
                    child: const Text('最小化'),
                  ),
                const Spacer(),
                const Text('Record Audio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                const SizedBox(width: 56),
              ],
            ),
            const SizedBox(height: 8),
            Text(_formatRecordingTime(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: CupertinoButton(onPressed: _closeRecording, child: const Text('关闭'))),
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: !_hasStartedRecording
                        ? _maybeStartRecording
                        : (_isRecording ? _pauseRecording : _startRecording),
                    child: Text(!_hasStartedRecording ? '开始' : (_isRecording ? '暂停' : '继续')),
                  ),
                ),
                Expanded(
                  child: CupertinoButton(
                    onPressed: _hasStartedRecording ? _saveRecording : null,
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCaptureModal() {
    if (!_showQuickCaptureModal) {
      return const SizedBox.shrink();
    }
    return CupertinoPopupSurface(
      child: Container(
        width: double.infinity,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quick Capture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (_quickCapturePhase == _QuickCapturePhase.transcribing ||
                _quickCapturePhase == _QuickCapturePhase.analyzing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const CupertinoActivityIndicator(radius: 14),
                    const SizedBox(height: 12),
                    Text(
                      _quickCapturePhase == _QuickCapturePhase.transcribing
                          ? 'Transcribing…'
                          : 'Analyzing…',
                      style: const TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: _cancelQuickCapture,
                      child: const Text('取消'),
                    ),
                  ],
                ),
              )
            else if (!_showQuickCaptureConfirm) ...[
              CupertinoTextField(
                controller: _quickCaptureController,
                maxLines: 4,
                placeholder: '输入想法或任务，下一步进入 AI 二段确认',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: _cancelQuickCapture,
                      child: const Text('取消'),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _quickCapturePhase == _QuickCapturePhase.input ? _runQuickCapturePipeline : null,
                      child: const Text('下一步'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: _quickCaptureStructuredMode,
                children: const <bool, Widget>{true: Text('Structured'), false: Text('Original')},
                onValueChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _quickCaptureStructuredMode = value);
                },
              ),
              const SizedBox(height: 10),
              if (_quickCaptureStructuredMode) ...[
                ..._parsedTodos.map((item) => _buildParsedRow(item, true)),
                ..._parsedMemos.map((item) => _buildParsedRow(item, false)),
              ] else
                Text(_originalQuickCaptureText),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: () => setState(() {
                        _showQuickCaptureConfirm = false;
                        _quickCapturePhase = _QuickCapturePhase.input;
                      }),
                      child: const Text('返回'),
                    ),
                  ),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _confirmQuickCapture,
                      child: const Text('确认'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParsedRow(_ParsedItem item, bool isTodo) {
    return GestureDetector(
      onTap: () {
        setState(() {
          final list = isTodo ? _parsedTodos : _parsedMemos;
          final index = list.indexWhere((it) => it.id == item.id);
          if (index >= 0) {
            list[index] = list[index].copyWith(selected: !list[index].selected);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              item.selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
              size: 18,
              color: item.selected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('${isTodo ? 'Todo' : 'Memo'}: ${item.text}')),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoDetailModal() {
    final id = _selectedTodoId;
    if (id == null) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final todo = widget.controller.getTodoById(id);
        if (todo == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedTodoId = null);
            }
          });
          return const SizedBox.shrink();
        }
        final linked = todo.linkedMemoryId == null
            ? null
            : widget.controller.getMemoryById(todo.linkedMemoryId!);
        return CupertinoPopupSurface(
          child: Container(
            width: double.infinity,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(todo.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('分类: ${todo.category}'),
                Text('状态: ${todo.completed ? '已完成' : '待处理'}'),
                Text('截止: ${todo.dueLabel ?? '未设置'}'),
                Text('关联记忆: ${linked?.title ?? '未关联'}'),
                const SizedBox(height: 12),
                CupertinoButton.filled(
                  onPressed: () {
                    widget.controller.markTodoDone(todo.id);
                    setState(() => _selectedTodoId = null);
                  },
                  child: const Text('Mark done'),
                ),
                CupertinoButton(
                  onPressed: () {
                    widget.controller.moveTodoToToday(todo.id);
                    setState(() => _selectedTodoId = null);
                  },
                  child: const Text('Not now（移到 Today）'),
                ),
                CupertinoButton(
                  onPressed: () {
                    showCupertinoDialog<void>(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: const Text('删除 Todo'),
                        content: const Text('确定删除？此操作不可撤销。'),
                        actions: [
                          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () {
                              Navigator.pop(ctx);
                              widget.controller.deleteTodo(todo.id);
                              setState(() => _selectedTodoId = null);
                            },
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Delete', style: TextStyle(color: CupertinoColors.destructiveRed)),
                ),
                CupertinoButton(
                  onPressed: () {
                    showCupertinoModalPopup<void>(
                      context: context,
                      builder: (_) {
                        final memories = widget.controller.memories;
                        return CupertinoActionSheet(
                          title: const Text('选择关联 Memory'),
                          actions: memories
                              .map(
                                (memory) => CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _linkTodoToMemory(todo.id, memory.id);
                                  },
                                  child: Text(memory.title),
                                ),
                              )
                              .toList(),
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('关联 Memory'),
                ),
                CupertinoButton(
                  onPressed: () => setState(() => _selectedTodoId = null),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ParsedItem {
  const _ParsedItem({
    required this.id,
    required this.text,
    required this.selected,
  });

  final int id;
  final String text;
  final bool selected;

  _ParsedItem copyWith({
    int? id,
    String? text,
    bool? selected,
  }) {
    return _ParsedItem(
      id: id ?? this.id,
      text: text ?? this.text,
      selected: selected ?? this.selected,
    );
  }
}

class _MPInfoCard extends StatelessWidget {
  const _MPInfoCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
