import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_completed_todo_action_popup.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/common/omi_edit_todo_popup.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_image_loader.dart';

import '../../../generated/assets.dart';
import 'cards/mp_all_todos_input_card.dart';
import 'cards/mp_today_focus_add_card.dart';
import 'cards/mp_today_focus_card.dart';
import 'cards/mp_today_focus_todo_grouped_list.dart';
import 'mp_today_focus_cubit.dart';

/// Today Focus：Today's Focus + ALL TO DOS 输入 + 分组待办列表（三态 + 下拉刷新）
class MPTodayFocusPage extends StatefulWidget {
  const MPTodayFocusPage({super.key});

  @override
  State<MPTodayFocusPage> createState() => _MPTodayFocusPageState();
}

class _MPTodayFocusPageState extends State<MPTodayFocusPage> {
  late final MPTodayFocusCubit _cubit = MPTodayFocusCubit()..initData();

  /// 本次进入页面内关闭 AI 推荐卡后不再展示；离开页面再进入会重置。
  bool _aiAddCardDismissedThisSession = false;

  bool _addingAiFocus = false;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _onRefresh() => _cubit.initData();

  void _onTapAddAiFocus() {
    if (_addingAiFocus) {
      return;
    }
    setState(() => _addingAiFocus = true);
    _cubit.addCurrentAiSuggestionToFocus().then((bool ok) {
      if (!mounted) {
        return;
      }
      setState(() => _addingAiFocus = false);
      if (!ok) {
        MPToastUtils.showMessage('添加失败');
      }
    });
  }

  Future<void> _onTapFocusItem(int index, MPTodayFocusCardItem item) async {
    if (!mounted) {
      return;
    }
    await showOmiEditTodoPopup(
      context,
      params: OmiEditTodoPopupParams(
        title: item.title,
        notes: item.subtext,
        whenLabel: 'Today',
        timeLabel: item.timeLabel,
        todoId: item.todoId,
      ),
      onDelete: () => _cubit.removeFocusItemAt(index),
    );
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
    await showOmiEditTodoPopup(
      context,
      params: OmiEditTodoPopupParams(
        title: row.title,
        notes: '',
        whenLabel: whenLabel,
        timeLabel: timeLabel,
        todoId: row.todoId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPTodayFocusCubit>.value(
      value: _cubit,
      child: Scaffold(
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
                return ColoredBox(
                  color: pageColor,
                  child: const Material(
                    color: Colors.transparent,
                    child: MPTristatePage(type: MPTristateType.loading),
                  ),
                );
              case MPTodayFocusPhase.empty:
                return ColoredBox(
                  color: pageColor,
                  child: MPTristatePage(
                    type: MPTristateType.empty,
                    data: MPTristatePageData(
                      icon: OmiImageLoader.localImg(
                        Assets.omiBrain,
                        width: 60,
                        height: 60,
                        color: blueTextColor,
                        fit: BoxFit.cover,
                      ),
                      title: 'Nothing for today yet',
                      description:
                          'Pull to refresh or add a task below when data loads.',
                      buttonText: 'Retry',
                      onButtonPressed: () {
                        context.read<MPTodayFocusCubit>().retry();
                      },
                    ),
                  ),
                );
              case MPTodayFocusPhase.error:
                return ColoredBox(
                  color: pageColor,
                  child: MPTristatePage(
                    type: MPTristateType.error,
                    data: MPTristatePageData(
                      title: 'Unable to load Today Focus',
                      description: state.errorMessage ?? '请稍后重试',
                      buttonText: 'Retry',
                      onButtonPressed: () {
                        context.read<MPTodayFocusCubit>().retry();
                      },
                    ),
                  ),
                );
              case MPTodayFocusPhase.loaded:
                // 单轴滚动：SingleChildScrollView + 一个 Column(min)。
                // ListView 多子项各自受「纵向无限高」约束，易与内层 Column/TextField 冲突导致空白。
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
                          MPTodayFocusCard(
                            data: state.focusCard,
                            onItemDeleted: (int i) async {
                              await _cubit.removeFocusItemAt(i);
                            },
                            onItemTap: _onTapFocusItem,
                          ),
                          if (state.focusCard.items.length < 3 &&
                              !_aiAddCardDismissedThisSession &&
                              state.currentAiFocusSuggestion != null) ...<Widget>[
                            const SizedBox(height: 16),
                            MPTodayFocusAddCard(
                              title: state.currentAiFocusSuggestion!.title,
                              scheduledTimeLabel: state
                                  .currentAiFocusSuggestion!.scheduledTimeLabel,
                              addButtonText: _addingAiFocus
                                  ? 'Adding…'
                                  : 'Add to Focus',
                              onDismiss: () {
                                setState(() {
                                  _aiAddCardDismissedThisSession = true;
                                });
                              },
                              onAddToFocus:
                                  _addingAiFocus ? null : _onTapAddAiFocus,
                            ),
                          ],
                          const SizedBox(height: 20),
                          MPAllTodosInputCard(
                            onSubmitted: (r) =>
                                _cubit.addTodoFromInput(r.text),
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
                            onItemTap: (MPTodayFocusTodoSection section, int index) {
                              _onTapTodoItem(state, section, index);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
