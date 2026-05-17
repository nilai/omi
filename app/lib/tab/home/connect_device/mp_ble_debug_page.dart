import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/blu/note_device.dart';
import 'package:memo_pin/common/mp_confirm_delete_dialog.dart';
import 'package:memo_pin/common/mp_custom_nav_bar.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import 'mp_ble_debug_cubit.dart';

/// BLE 设备文件调试页（仅 debug 入口进入）。
class MPBleDebugPage extends StatefulWidget {
  const MPBleDebugPage({super.key});

  @override
  State<MPBleDebugPage> createState() => _MPBleDebugPageState();
}

class _MPBleDebugPageState extends State<MPBleDebugPage> {
  late final MPBleDebugCubit _cubit = MPBleDebugCubit();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.initData();
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _onDeleteAllTap() async {
    final MPBleDebugState state = _cubit.state;
    if (state.files.isEmpty || state.isBusy) {
      return;
    }
    final bool ok = await showMPConfirmDeleteDialog(
      context,
      params: MPConfirmDeleteDialogParams(
        title: 'Delete All Files',
        messageLine1: 'Delete all ${state.files.length} files on the device?',
        messageLine2: 'This action cannot be undone.',
        cancelText: 'Cancel',
        confirmText: 'Delete All',
      ),
    );
    if (!ok || !mounted) {
      return;
    }
    await _cubit.deleteAllFiles();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPBleDebugCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: pageColor,
        appBar: PreferredSize(
          preferredSize: MPCustomNavBar.preferredSizeOf(context),
          child: MPCustomNavBar(
            title: 'BLE Debug',
            backgroundColor: pageColor,
            onBack: () => Navigator.of(context).maybePop(),
            actions: <Widget>[
              BlocBuilder<MPBleDebugCubit, MPBleDebugState>(
                builder: (BuildContext context, MPBleDebugState state) {
                  final bool disabled = state.phase == MPBleDebugLoadPhase.loading || state.isBusy;
                  return TextButton(
                    onPressed: disabled ? null : _cubit.loadFiles,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: Text(
                      'Refresh',
                      style: OmiTextStyle.create(
                        color: disabled ? const Color(0xFF9A9AA3) : blueTextColor,
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.medium,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: BlocBuilder<MPBleDebugCubit, MPBleDebugState>(
          builder: (BuildContext context, MPBleDebugState state) {
            return SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _MPBleDebugToolbar(
                      fileCount: state.files.length,
                      isBusy: state.isBusy,
                      isDeletingAll: state.isDeletingAll,
                      onDeleteAll: _onDeleteAllTap,
                    ),
                  ),
                  Expanded(child: _buildBody(state)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(MPBleDebugState state) {
    switch (state.phase) {
      case MPBleDebugLoadPhase.initial:
      case MPBleDebugLoadPhase.loading:
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      case MPBleDebugLoadPhase.disconnected:
        return _MPBleDebugMessage(
          text: 'No connected BLE device.\nConnect a MemoPin first.',
          onRetry: _cubit.loadFiles,
        );
      case MPBleDebugLoadPhase.error:
        return _MPBleDebugMessage(
          text: state.errorMessage ?? 'Failed to load files',
          onRetry: _cubit.loadFiles,
        );
      case MPBleDebugLoadPhase.loaded:
        if (state.files.isEmpty) {
          return _MPBleDebugMessage(
            text: 'No files on device',
            onRetry: _cubit.loadFiles,
          );
        }
        return RefreshIndicator(
          onRefresh: _cubit.loadFiles,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: _MPBleDebugMasonryGrid(
              files: state.files,
              deletingFileNames: state.deletingFileNames,
              isDeletingAll: state.isDeletingAll,
              onDelete: _cubit.deleteFile,
            ),
          ),
        );
    }
  }
}

class _MPBleDebugToolbar extends StatelessWidget {
  const _MPBleDebugToolbar({
    required this.fileCount,
    required this.isBusy,
    required this.isDeletingAll,
    required this.onDeleteAll,
  });

  final int fileCount;
  final bool isBusy;
  final bool isDeletingAll;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '$fileCount file${fileCount == 1 ? '' : 's'} on device',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t6_15,
              fontWeight: OmiFontWeight.medium,
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: fileCount == 0 || isBusy ? null : onDeleteAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: const Color(0xFFFFF0F0),
            foregroundColor: const Color(0xFFF44336),
            splashFactory: NoSplash.splashFactory,
          ),
          child: isDeletingAll
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF44336)),
                )
              : Text(
                  'Delete All',
                  style: OmiTextStyle.create(
                    color: const Color(0xFFF44336),
                    fontSize: OmiFontSize.t5_14,
                    fontWeight: OmiFontWeight.medium,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MPBleDebugMessage extends StatelessWidget {
  const _MPBleDebugMessage({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              text,
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                color: const Color(0xFF666A79),
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                'Retry',
                style: OmiTextStyle.create(
                  color: blueTextColor,
                  fontSize: OmiFontSize.t6_15,
                  fontWeight: OmiFontWeight.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 双列瀑布流：按预估卡片高度分配到较短的一列。
class _MPBleDebugMasonryGrid extends StatelessWidget {
  const _MPBleDebugMasonryGrid({
    required this.files,
    required this.deletingFileNames,
    required this.isDeletingAll,
    required this.onDelete,
  });

  final List<NoteFileInfo> files;
  final Set<String> deletingFileNames;
  final bool isDeletingAll;
  final void Function(String fileName) onDelete;

  static int _estimateCardHeight(String name) {
    final int lines = (name.length / 18).ceil().clamp(1, 4);
    return 72 + (lines - 1) * 18;
  }

  @override
  Widget build(BuildContext context) {
    final List<NoteFileInfo> leftColumn = <NoteFileInfo>[];
    final List<NoteFileInfo> rightColumn = <NoteFileInfo>[];
    int leftHeight = 0;
    int rightHeight = 0;

    for (final NoteFileInfo file in files) {
      final int h = _estimateCardHeight(file.name);
      if (leftHeight <= rightHeight) {
        leftColumn.add(file);
        leftHeight += h + 10;
      } else {
        rightColumn.add(file);
        rightHeight += h + 10;
      }
    }

    Widget buildColumn(List<NoteFileInfo> columnFiles) {
      return Column(
        children: <Widget>[
          for (int i = 0; i < columnFiles.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            _MPBleDebugFileCard(
              file: columnFiles[i],
              isDeleting: deletingFileNames.contains(columnFiles[i].name),
              deleteEnabled: !isDeletingAll && !deletingFileNames.contains(columnFiles[i].name),
              onDelete: () => onDelete(columnFiles[i].name),
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: buildColumn(leftColumn)),
        const SizedBox(width: 10),
        Expanded(child: buildColumn(rightColumn)),
      ],
    );
  }
}

class _MPBleDebugFileCard extends StatelessWidget {
  const _MPBleDebugFileCard({
    required this.file,
    required this.isDeleting,
    required this.deleteEnabled,
    required this.onDelete,
  });

  final NoteFileInfo file;
  final bool isDeleting;
  final bool deleteEnabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            file.name,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: OmiTextStyle.create(
              color: mainTextColor,
              fontSize: OmiFontSize.t5_14,
              fontWeight: OmiFontWeight.medium,
              height: 1.35,
            ),
          ),
          if (file.durationSeconds > 0) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              file.shortDuration,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OmiTextStyle.create(
                color: const Color(0xFF9A9AA3),
                fontSize: OmiFontSize.t3_12,
                fontWeight: OmiFontWeight.regular,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: deleteEnabled && !isDeleting ? onDelete : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: const Color(0xFFFFF0F0),
                foregroundColor: const Color(0xFFF44336),
                splashFactory: NoSplash.splashFactory,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF44336)),
                    )
                  : Text(
                      'Delete',
                      style: OmiTextStyle.create(
                        color: const Color(0xFFF44336),
                        fontSize: OmiFontSize.t4_13,
                        fontWeight: OmiFontWeight.medium,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
