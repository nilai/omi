import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_completed_todo_action_popup.dart';
import 'package:memo_pin/common/mp_todo_manager.dart';
import 'package:memo_pin/common/mp_todo_voice_input.dart';
import 'package:memo_pin/common/mp_custom_nav_bar.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/common/omi_edit_todo_popup.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';

import '../../../common/mp_date_utils.dart';
import '../../../common/mp_home_notification.dart';
import '../../../http/schema/mp_memory.dart';
import 'cards/mp_all_todos_input_card.dart';
import 'cards/mp_today_focus_add_card.dart';
import 'cards/mp_today_focus_card.dart';
import 'cards/mp_today_focus_todo_grouped_list.dart';
import 'mp_today_focus_cubit.dart';
import 'mp_today_focus_full_sheet.dart';

/// Today Focus：Today's Focus + ALL TO DOS 输入 + 分组待办列表（三态 + 下拉刷新）
class MPTodayFocusPage extends StatefulWidget {
  const MPTodayFocusPage({super.key});

  @override
  State<MPTodayFocusPage> createState() => _MPTodayFocusPageState();
}

class _MPTodayFocusPageState extends State<MPTodayFocusPage> {
  late final MPTodayFocusCubit _cubit = MPTodayFocusCubit()..initData();

  StreamSubscription<MPHomeTodoDeletedPayload>? _todoDeletedSub;

  /// 本次进入页面内关闭 AI 推荐卡后不再展示；离开页面再进入会重置。
  bool _aiAddCardDismissedThisSession = false;

  bool _addingAiFocus = false;

  @override
  void initState() {
    super.initState();
    _todoDeletedSub = MPHomeNotification.listenTodoDeleted((MPHomeTodoDeletedPayload _) {
      if (!mounted) {
        return;
      }
      unawaited(_cubit.refreshGroupedTodoLists());
    });
  }

  @override
  void dispose() {
    _todoDeletedSub?.cancel();
    _cubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() => _cubit.initData();

  /// ALL TO DOS：文本提交（含语音转写回填后再提交）→ 直接 [MPTodoManager.createTodo]（与 Memory 详情快捷加 Todo 一致，无 analyze）。
  Future<bool> _onAllTodosInputSubmitted(MPTodoVoiceInputResult r) async {
    if (!mounted) {
      return false;
    }
    final String line = r.text.trim();
    if (line.isEmpty) {
      return false;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final bool ok = await MPTodoManager().createTodo(title: line);
    if (!mounted) {
      return false;
    }
    if (!ok) {
      MPToastUtils.showMessage('Couldn\'t create to-do. Please try again later.');
      return false;
    }
    await _cubit.refreshListsAfterMutation();
    return true;
  }

  /// 拉取关联 Memory 简要信息后弹出编辑 Todo（CONTEXT / memoryId / type 与首页一致）。
  /// 返回 `true` 表示弹层内因「Mark as done」等已触发需全量同步列表（与 [showOmiEditTodoPopup] 一致）。
  Future<bool> _showOmiEditTodoPopupWithMemoryContext({
    required int? memoryId,
    required String title,
    required String notes,
    required String whenLabel,
    required String timeLabel,
    required String todoId,
    Future<bool> Function()? onDelete,
  }) async {
    if (!mounted) {
      return false;
    }
    final MPGetMemoryV2SimpleInfoResponse? simpleMemory =
        await _cubit.loadMemorySimpleInfoNetworkOrHive(memoryId);
    if (!mounted) {
      return false;
    }
    final MPMemorySimpleInfoStruct? mi =
        (simpleMemory != null && simpleMemory.baseResp?.code == 0) ? simpleMemory.memoryInfo : null;
    final String contextMemoryTitle = mi?.title ?? '';
    final String contextMetaLine = mi != null
        ? MPDateUtils.buildMemorySimpleContextMetaLine(
            recordCreateAt: mi.recordCreateAt,
            duration: mi.duration,
            label: mi.label,
          )
        : '';
    final String contextMemoryLabel = mi != null ? 'From memory:' : '';
    final String resolvedTimeLabel = timeLabel.trim().isEmpty ? '--:--' : timeLabel;

    return showOmiEditTodoPopup(
      context,
      params: OmiEditTodoPopupParams(
        title: title,
        contextMemoryLabel: contextMemoryLabel,
        contextMemoryTitle: contextMemoryTitle,
        contextMetaLine: contextMetaLine,
        notes: notes,
        whenLabel: whenLabel,
        timeLabel: resolvedTimeLabel,
        todoId: todoId,
        memoryId: memoryId,
        memoryType: mi?.type,
      ),
      onDelete: onDelete,
    );
  }

  void _onTapAddAiFocus() {
    if (_addingAiFocus) {
      return;
    }
    final MPTodayFocusState s = _cubit.state;
    if (s.currentAiFocusSuggestion == null) {
      return;
    }

    Future<void> runAdd({int? replaceSlot}) async {
      setState(() => _addingAiFocus = true);
      final bool ok = await _cubit.addCurrentAiSuggestionToFocus(replaceSlot: replaceSlot);
      if (!mounted) {
        return;
      }
      setState(() => _addingAiFocus = false);
    }

    if (s.focusCard.items.length >= 3) {
      showMPTodayFocusFullSheet(
        context,
        items: s.focusCard.items.take(3).toList(),
        onSelect: (int replaceSlot, MPTodayFocusCardItem _) {
          unawaited(runAdd(replaceSlot: replaceSlot));
        },
      );
      return;
    }
    unawaited(runAdd());
  }

  Future<void> _onTapFocusItem(int index, MPTodayFocusCardItem item) async {
    final bool mutated = await _showOmiEditTodoPopupWithMemoryContext(
      memoryId: item.memoryId,
      title: item.title,
      notes: item.subtext,
      whenLabel: 'Today',
      timeLabel: item.timeLabel,
      todoId: item.todoId,
      onDelete: () async {
        final bool ok = await _cubit.removeFocusItemAt(index);
        return ok;
      },
    );
    if (!mounted) {
      return;
    }
    if (mutated) {
      await _cubit.refreshListsAfterMutation();
    }
  }

  Future<void> _onTapTodoItem(
    MPTodayFocusState state,
    MPTodayFocusTodoSection section,
    int index,
  ) async {
    List<MPTodayFocusTodoRowData> rows;
    String whenLabel = 'No deadline';
    String timeLabel = '';
    switch (section) {
      case MPTodayFocusTodoSection.today:
        rows = state.todayItems;
        whenLabel = 'Today';
        break;
      case MPTodayFocusTodoSection.upcomingWithinSevenDays:
        rows = state.upcomingItems;
        break;
      case MPTodayFocusTodoSection.futureBeyondSevenDays:
        rows = state.futureItems;
        break;
      case MPTodayFocusTodoSection.overdue:
        rows = state.overdueItems;
        break;
      case MPTodayFocusTodoSection.completed:
        rows = state.completedItems;
        break;
    }
    if (index < 0 || index >= rows.length || !mounted) {
      return;
    }
    final MPTodayFocusTodoRowData row = rows[index];
    if (section == MPTodayFocusTodoSection.today) {
      timeLabel = row.timeLabel;
    }
    if (section == MPTodayFocusTodoSection.completed) {
      await showMPCompletedTodoActionPopup(
        context,
        params: MPCompletedTodoActionPopupParams(title: row.title),
        onRestore: () => _cubit.restoreCompletedAt(index),
        onDelete: () => _cubit.deleteCompletedAt(index),
      );
      return;
    }
    final bool mutated = await _showOmiEditTodoPopupWithMemoryContext(
      memoryId: row.memoryId,
      title: row.title,
      notes: '',
      whenLabel: whenLabel,
      timeLabel: timeLabel,
      todoId: row.todoId,
    );
    if (!mounted) {
      return;
    }
    if (mutated) {
      await _cubit.refreshListsAfterMutation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPTodayFocusCubit>.value(
      value: _cubit,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Scaffold(
            backgroundColor: Color(0xFFF0F0F0),
            appBar: PreferredSize(
              preferredSize: MPCustomNavBar.preferredSizeOf(context),
              child: MPCustomNavBar(
                title: 'All To-Dos',
                backgroundColor: Colors.white,
                onBack: () {
                  Navigator.of(context, rootNavigator: true).maybePop();
                },
              ),
            ),
            body: BlocBuilder<MPTodayFocusCubit, MPTodayFocusState>(
              builder: (BuildContext context, MPTodayFocusState state) {
            switch (state.phase) {
              case MPTodayFocusPhase.loading:
                return const SafeArea(
                  top: false,
                  child: MPTristatePage(type: MPTristateType.loading),
                );
              case MPTodayFocusPhase.error:
                return SafeArea(
                  top: false,
                  child: MPTristatePage(
                    type: MPTristateType.error,
                    data: MPTristatePageData(
                      title: 'Couldn\'t load',
                      description: state.errorMessage ?? 'Please try again later.',
                      onButtonPressed: () => _cubit.retry(),
                    ),
                  ),
                );
              case MPTodayFocusPhase.loaded:
              case MPTodayFocusPhase.empty:
                break;
            }

            final bool showFocusCard = state.phase == MPTodayFocusPhase.loaded;
            final bool canAddAi = state.phase == MPTodayFocusPhase.loaded;
            final bool showListLoadingBar =
                state.isGroupedTodosRefreshing && !state.isBlockingGlobalLoading;

            return SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (showListLoadingBar) ...<Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: blueTextColor,
                            backgroundColor: lineColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (showFocusCard) ...<Widget>[
                        MPTodayFocusCard(
                          data: state.focusCard,
                          onItemDeleted: (int i) async {
                            await _cubit.removeFocusItemAt(i);
                          },
                          onItemTap: _onTapFocusItem,
                        ),
                      ],
                      if (!_aiAddCardDismissedThisSession &&
                          state.currentAiFocusSuggestion != null) ...<Widget>[
                        if (showFocusCard) const SizedBox(height: 16),
                        MPTodayFocusAddCard(
                          title: state.currentAiFocusSuggestion!.title,
                          scheduledTimeLabel:
                              state.currentAiFocusSuggestion!.scheduledTimeLabel,
                          addButtonText: _addingAiFocus ? 'Adding…' : 'Add to Focus',
                          onDismiss: () {
                            setState(() {
                              _aiAddCardDismissedThisSession = true;
                            });
                          },
                          onAddToFocus: (!canAddAi || _addingAiFocus)
                              ? null
                              : _onTapAddAiFocus,
                        ),
                      ],
                      const SizedBox(height: 20),
                      MPAllTodosInputCard(
                        onSubmitted: _onAllTodosInputSubmitted,
                      ),
                      const SizedBox(height: 24),
                      MPTodayFocusTodoGroupedList(
                        todayItems: state.todayItems,
                        upcomingItems: state.upcomingItems,
                        futureItems: state.futureItems,
                        overdueItems: state.overdueItems,
                        completedItems: state.completedItems,
                        initialFutureExpanded: true,
                        onOverdueClear: _cubit.clearOverdue,
                        onItemCheckChanged: _cubit.setTodoChecked,
                        onItemAddToFocus:
                            (MPTodayFocusTodoSection section, int index) {
                          if (section != MPTodayFocusTodoSection.today) {
                            return;
                          }
                          if (index < 0 || index >= state.todayItems.length) {
                            return;
                          }
                          final String todoId =
                              state.todayItems[index].todoId.trim();
                          if (todoId.isEmpty) {
                            MPToastUtils.showMessage('Task ID cannot be empty.');
                            return;
                          }
                          if (state.focusCard.items.length >= 3) {
                            showMPTodayFocusFullSheet(
                              context,
                              items: state.focusCard.items.take(3).toList(),
                              onSelect: (int slot, MPTodayFocusCardItem _) {
                                unawaited(() async {
                                  final bool ok = await _cubit.replaceTodayFocusSlot(
                                    slot: slot,
                                    todoId: todoId,
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                }());
                              },
                            );
                            return;
                          }
                              unawaited(() async {
                                  final bool ok = await _cubit.addTodayFocusSlot(
                                    todoId: todoId,
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                }());
                        },
                        onItemTap:
                            (MPTodayFocusTodoSection section, int index) {
                          _onTapTodoItem(state, section, index);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
              },
            ),
          ),
          BlocSelector<MPTodayFocusCubit, MPTodayFocusState, bool>(
            selector: (MPTodayFocusState s) => s.isBlockingGlobalLoading,
            builder: (BuildContext context, bool blocking) {
              if (!blocking) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.32),
                    child: const Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: blueTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
