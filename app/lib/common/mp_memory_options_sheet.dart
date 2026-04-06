import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omi/common/mp_confirm_delete_dialog.dart';
import 'package:omi/http/api/mp_memory.dart';
import 'package:omi/http/schema/mp_memory.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

/// 「更多 / Options」弹窗每一项的类型。
enum MPMemoryOptionKind { manageProjects, editTitle, modifyDate, delete }

/// 单项配置。
class MPMemoryOptionItem {
  const MPMemoryOptionItem({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.titleColor,
  });

  final MPMemoryOptionKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color? titleColor;
}

/// 弹窗可配置项。
class MPMemoryOptionsSheetParams {
  const MPMemoryOptionsSheetParams({
    this.title = 'Memory Options',
    this.subtitle = 'Manage this memory',
    this.manageProjectsCount = 0,
    this.showManageProjects = true,
    this.showEditTitle = true,
    this.showModifyDate = true,
    this.showDelete = true,
    this.cancelText = 'Cancel',
    this.memoryId,
  });

  final String title;
  final String subtitle;

  /// `Manage Projects (N)` 的计数。
  final int manageProjectsCount;

  final bool showManageProjects;
  final bool showEditTitle;
  final bool showModifyDate;
  final bool showDelete;

  final String cancelText;

  /// 非空时，点「Delete」会先确认再调用 [deleteMemory]；为空则仅返回 [MPMemoryOptionKind.delete]。
  final String? memoryId;
}

/// 打开「Memory Options」弹窗。
///
/// - 返回用户点选的 [MPMemoryOptionKind]；点取消/关闭返回 `null`
/// - 最大高度为屏高的 0.6，超过后列表可滚动
Future<MPMemoryOptionKind?> showMPMemoryOptionsSheet(
  BuildContext context, {
  MPMemoryOptionsSheetParams params = const MPMemoryOptionsSheetParams(),
}) {
  return showModalBottomSheet<MPMemoryOptionKind>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext sheetContext) {
      return _MPMemoryOptionsSheet(params: params);
    },
  );
}

class _MPMemoryOptionsSheet extends StatelessWidget {
  const _MPMemoryOptionsSheet({required this.params});

  final MPMemoryOptionsSheetParams params;

  static const Color _kCardBg = Colors.white;
  static const Color _kSheetBg = Color(0xFFF2F2F7);

  List<MPMemoryOptionItem> _items() {
    final List<MPMemoryOptionItem> items = <MPMemoryOptionItem>[];

    if (params.showManageProjects) {
      final int n = math.max(0, params.manageProjectsCount);
      items.add(
        MPMemoryOptionItem(
          kind: MPMemoryOptionKind.manageProjects,
          title: 'Manage Projects${n > 0 ? ' ($n)' : ''}',
          subtitle: 'Organize this memory into projects',
          icon: Icons.folder_outlined,
          iconBg: const Color(0xFFEAF7EF),
          iconColor: const Color(0xFF34C759),
        ),
      );
    }
    if (params.showEditTitle) {
      items.add(
        const MPMemoryOptionItem(
          kind: MPMemoryOptionKind.editTitle,
          title: 'Edit Title',
          subtitle: 'Change the memory title',
          icon: Icons.edit_outlined,
          iconBg: Color(0xFFE8F4FF),
          iconColor: blueTextColor,
        ),
      );
    }
    if (params.showModifyDate) {
      items.add(
        const MPMemoryOptionItem(
          kind: MPMemoryOptionKind.modifyDate,
          title: 'Modify Date',
          subtitle: 'Change creation time',
          icon: Icons.access_time_rounded,
          iconBg: Color(0xFFFFF2E5),
          iconColor: Color(0xFFFF9500),
        ),
      );
    }
    if (params.showDelete) {
      items.add(
        const MPMemoryOptionItem(
          kind: MPMemoryOptionKind.delete,
          title: 'Delete',
          subtitle: 'Remove this memory',
          icon: Icons.delete_outline_rounded,
          iconBg: Color(0xFFFDEBEC),
          iconColor: redColor,
          titleColor: redColor,
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final List<MPMemoryOptionItem> items = _items();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: _kSheetBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomSafe),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      params.title,
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t9_18,
                        fontWeight: OmiFontWeight.bold,
                        color: mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      params.subtitle,
                      textAlign: TextAlign.center,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < items.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 12),
                      _MPMemoryOptionTile(
                        item: items[i],
                        sheetParams: params,
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: _kCardBg,
                          foregroundColor: blueTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          params.cancelText,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t8_17,
                            fontWeight: OmiFontWeight.medium,
                            color: blueTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MPMemoryOptionTile extends StatelessWidget {
  const _MPMemoryOptionTile({
    required this.item,
    required this.sheetParams,
  });

  final MPMemoryOptionItem item;
  final MPMemoryOptionsSheetParams sheetParams;

  Future<void> _onTap(BuildContext context) async {
    final String? id = sheetParams.memoryId?.trim();
    if (item.kind == MPMemoryOptionKind.delete &&
        id != null &&
        id.isNotEmpty) {
      final bool ok = await showMPConfirmDeleteDialog(
        context,
        params: const MPConfirmDeleteDialogParams(
          title: 'Delete Memory',
          messageLine1: 'Are you sure you want to delete this memory?',
          messageLine2: 'This action cannot be undone.',
          cancelText: 'No, Keep',
          confirmText: 'Yes, Delete',
        ),
      );
      if (!context.mounted) return;
      if (!ok) return;
      final MPDeleteMemoryResponse? resp = await deleteMemory(
        MPDeleteMemoryRequest(memoryId: id),
      );
      if (!context.mounted) return;
      if (resp == null || resp.baseResp.code != 0) {
        MPToastUtils.showMessage(
          resp?.baseResp.message ?? '删除失败，请稍后重试',
        );
        return;
      }
      Navigator.of(context).pop(MPMemoryOptionKind.delete);
      return;
    }
    Navigator.of(context).pop(item.kind);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(item.icon, size: 22, color: item.iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t7_16,
                        fontWeight: OmiFontWeight.bold,
                        color: item.titleColor ?? mainTextColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: OmiTextStyle.create(
                        fontSize: OmiFontSize.t5_14,
                        fontWeight: OmiFontWeight.regular,
                        color: secondTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
