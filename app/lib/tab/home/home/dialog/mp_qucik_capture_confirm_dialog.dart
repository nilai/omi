import 'package:flutter/material.dart';

import '../../../../http/schema/mp_todo.dart';
import '../../../../utils/mp_time_utils.dart';
import '../../../../utils/mp_toast_utils.dart';
import '../../../../utils/omi_color_utils.dart';
import '../../../../utils/omi_font_utils.dart';

/// Quick Capture 确认列表一行（由分析结果组装，不含选中状态）。
class MPQuickCaptureConfirmItem {
  /// Todo 行。
  factory MPQuickCaptureConfirmItem.todo(String title, int? deadline) {
    return MPQuickCaptureConfirmItem._(isTodo: true, text: title, deadline: deadline, type: 0);
  }

  /// Memo 行。
  factory MPQuickCaptureConfirmItem.memo(String content, int type) {
    return MPQuickCaptureConfirmItem._(isTodo: false, text: content, deadline: null, type: type);
  }

  MPQuickCaptureConfirmItem._({required this.isTodo, required this.text, required this.deadline, required this.type});

  final bool isTodo;

  /// Todo 标题或 Memo 正文（不含 `Todo:` / `Memo:` 前缀）。
  final String text;

  final int? deadline;

  final int type;
}

/// Quick Capture 确认弹窗返回结果。
class MPQuickCaptureConfirmResult {
  /// 构造函数。
  const MPQuickCaptureConfirmResult({
    required this.confirmed,
    this.originalText,
    required this.todos,
    required this.memos,
  });

  /// 是否点击确认。
  final bool confirmed;

  /// 用户选中 ORIGINAL TEXT 区域并确认时，为原始文案；选中 STRUCTURED SUGGESTIONS 时为 `null`。
  final String? originalText;

  /// 用户勾选且编辑后的 Todo（仅 [confirmed] 为 true 时有意义）。
  final List<MPBatchCreateTodoItem> todos;

  /// 用户勾选且编辑后的 Memo（仅 [confirmed] 为 true 时有意义）。
  final List<MPBatchCreateMemoItem> memos;
}

/// 点击 Confirm 后提交；返回 `true` 时弹窗关闭，失败则保持弹窗并允许重试。
typedef MPQuickCaptureConfirmSubmit = Future<bool> Function(
  MPQuickCaptureConfirmResult result,
);

/// 互斥选中区域：原始文案 / 结构化建议列表。
enum _MPConfirmSelectionRegion { originalText, items }

/// Quick Capture 结构化确认弹窗。
class MPQucikCaptureConfirmDialog extends StatefulWidget {
  /// 构造函数。
  const MPQucikCaptureConfirmDialog({
    super.key,
    required this.originalText,
    required this.items,
    required this.onConfirmSubmit,
  });

  /// 原始文本（支持多行）。
  final String originalText;

  /// 结构化建议行（顺序与展示一致）。
  final List<MPQuickCaptureConfirmItem> items;

  /// Confirm 提交回调；仅在其返回 `true` 时关闭弹窗。
  final MPQuickCaptureConfirmSubmit onConfirmSubmit;

  /// 展示弹窗，最大高度为屏幕的 3/4。
  static Future<MPQuickCaptureConfirmResult?> show(
    BuildContext context, {
    required String originalText,
    required List<MPQuickCaptureConfirmItem> items,
    required MPQuickCaptureConfirmSubmit onConfirmSubmit,
  }) {
    return showModalBottomSheet<MPQuickCaptureConfirmResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext sheetContext) {
        return MPQucikCaptureConfirmDialog(
          originalText: originalText,
          items: items,
          onConfirmSubmit: onConfirmSubmit,
        );
      },
    );
  }

  @override
  State<MPQucikCaptureConfirmDialog> createState() => _MPQucikCaptureConfirmDialogState();
}

class _ConfirmRow {
  _ConfirmRow({required this.isTodo, required this.text, required this.deadline, required this.type});

  final bool isTodo;
  String text;

  final int? deadline;

  /// 默认全选，点击行切换。
  bool selected = true;

  final int type;
}

class _MPQucikCaptureConfirmDialogState extends State<MPQucikCaptureConfirmDialog> {
  static const Color _kBlue = Color(0xFF2F7BFF);

  late String _originalText = widget.originalText;

  late final List<_ConfirmRow> _rows = widget.items
      .map(
        (MPQuickCaptureConfirmItem e) =>
            _ConfirmRow(isTodo: e.isTodo, text: e.text.trim(), deadline: e.deadline, type: e.type),
      )
      .where((_ConfirmRow r) => r.text.isNotEmpty)
      .toList(growable: true);

  /// 默认选中 items 区域且全部 item 已勾选（见 [_ConfirmRow.selected]）。
  _MPConfirmSelectionRegion _activeRegion = _MPConfirmSelectionRegion.items;

  /// ORIGINAL TEXT 编辑态。
  bool _isOriginalTextEditing = false;
  TextEditingController? _originalTextController;
  final FocusNode _originalTextFocusNode = FocusNode();
  String? _originalTextSnapshot;

  /// STRUCTURED SUGGESTIONS 中当前编辑的 item 下标（同模块内互斥）。
  int? _editingItemIndex;
  TextEditingController? _itemEditingController;
  final FocusNode _itemEditingFocusNode = FocusNode();
  String? _itemEditingSnapshot;

  bool _submitting = false;

  bool get _isOriginalTextRegionActive => _activeRegion == _MPConfirmSelectionRegion.originalText;

  bool get _isItemsRegionActive => _activeRegion == _MPConfirmSelectionRegion.items;

  BoxDecoration _buildRegionCardDecoration({required bool isActive}) {
    return BoxDecoration(
      color: isActive ? Colors.white : const Color(0xFFFAFAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: isActive ? _kBlue : lineColor.withValues(alpha: 0.9), width: isActive ? 2 : 1),
      boxShadow: isActive
          ? <BoxShadow>[BoxShadow(color: _kBlue.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))]
          : null,
    );
  }

  void _selectOriginalTextRegion() {
    setState(() {
      _activeRegion = _MPConfirmSelectionRegion.originalText;
      for (final _ConfirmRow r in _rows) {
        r.selected = false;
      }
    });
  }

  /// 仅切换至 items 区域高亮，不改变各行勾选状态。
  void _selectItemsRegion() {
    setState(() {
      _activeRegion = _MPConfirmSelectionRegion.items;
    });
  }

  MPQuickCaptureConfirmResult _buildPopResult({required bool confirmed}) {
    if (!confirmed) {
      return const MPQuickCaptureConfirmResult(
        confirmed: false,
        originalText: null,
        todos: <MPBatchCreateTodoItem>[],
        memos: <MPBatchCreateMemoItem>[],
      );
    }
    if (_isOriginalTextRegionActive) {
      return MPQuickCaptureConfirmResult(
        confirmed: true,
        originalText: _originalText.trim(),
        todos: const <MPBatchCreateTodoItem>[],
        memos: const <MPBatchCreateMemoItem>[],
      );
    }
    return MPQuickCaptureConfirmResult(
      confirmed: true,
      originalText: null,
      todos: _selectedTodos(),
      memos: _selectedMemos(),
    );
  }

  @override
  void dispose() {
    _originalTextController?.dispose();
    _originalTextController = null;
    _originalTextFocusNode.dispose();
    _itemEditingController?.dispose();
    _itemEditingController = null;
    _itemEditingFocusNode.dispose();
    super.dispose();
  }

  List<MPBatchCreateTodoItem> _selectedTodos() {
    final List<MPBatchCreateTodoItem> out = <MPBatchCreateTodoItem>[];
    for (final _ConfirmRow r in _rows) {
      if (!r.selected || !r.isTodo) {
        continue;
      }
      final String t = r.text.trim();
      if (t.isEmpty) {
        continue;
      }
      out.add(MPBatchCreateTodoItem(title: t, priority: '', deadline: r.deadline));
    }
    return out;
  }

  List<MPBatchCreateMemoItem> _selectedMemos() {
    final int memoCreateAt = MPTimeUtils.nowUnixSeconds();
    final List<MPBatchCreateMemoItem> out = <MPBatchCreateMemoItem>[];
    for (final _ConfirmRow r in _rows) {
      if (!r.selected || r.isTodo) {
        continue;
      }
      final String t = r.text.trim();
      if (t.isEmpty) {
        continue;
      }
      out.add(MPBatchCreateMemoItem(content: t, createAt: memoCreateAt, source: r.type == 1 ? 'record' : 'text'));
    }
    return out;
  }

  /// 延迟释放 [controller]，避免当前帧 [TextField] 仍在使用时触发 disposed 断言。
  void _releaseController(TextEditingController? controller) {
    if (controller == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
  }

  /// 将 ORIGINAL TEXT 编辑框内容同步到数据源。
  void _commitOriginalTextEdit() {
    if (!_isOriginalTextEditing || _originalTextController == null) {
      return;
    }
    final String next = _originalTextController!.text.trim();
    if (next.isNotEmpty) {
      _originalText = next;
    }
  }

  /// 将当前 item 编辑框内容同步到数据源。
  void _commitItemEdit() {
    final int? index = _editingItemIndex;
    if (index == null || _itemEditingController == null) {
      return;
    }
    final String next = _itemEditingController!.text.trim();
    if (next.isNotEmpty && index >= 0 && index < _rows.length) {
      _rows[index].text = next;
    }
  }

  /// 退出 ORIGINAL TEXT 编辑态；[applyChanges] 为 false 时恢复进入编辑前的文本。
  void _cancelOriginalTextEditing({bool applyChanges = false}) {
    if (!_isOriginalTextEditing) {
      return;
    }
    if (applyChanges) {
      _commitOriginalTextEdit();
    } else if (_originalTextSnapshot != null) {
      _originalText = _originalTextSnapshot!;
    }
    final TextEditingController? oldController = _originalTextController;
    _originalTextController = null;
    _originalTextFocusNode.unfocus();
    _isOriginalTextEditing = false;
    _originalTextSnapshot = null;
    _releaseController(oldController);
  }

  /// 退出 item 编辑态；[applyChanges] 为 false 时恢复进入编辑前的文本。
  void _cancelItemEditing({bool applyChanges = false}) {
    if (_editingItemIndex == null) {
      return;
    }
    if (applyChanges) {
      _commitItemEdit();
    } else {
      final int index = _editingItemIndex!;
      final String? snapshot = _itemEditingSnapshot;
      if (snapshot != null && index >= 0 && index < _rows.length) {
        _rows[index].text = snapshot;
      }
    }
    final TextEditingController? oldController = _itemEditingController;
    _itemEditingController = null;
    _itemEditingFocusNode.unfocus();
    _editingItemIndex = null;
    _itemEditingSnapshot = null;
    _releaseController(oldController);
  }

  /// 开始编辑 ORIGINAL TEXT（不影响 STRUCTURED SUGGESTIONS 的编辑态）。
  void _startEditOriginalText() {
    setState(() {
      _activeRegion = _MPConfirmSelectionRegion.originalText;
      for (final _ConfirmRow r in _rows) {
        r.selected = false;
      }
      _originalTextSnapshot = _originalText;
      _isOriginalTextEditing = true;
      _originalTextController = TextEditingController(text: _originalText);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _originalTextFocusNode.requestFocus();
      }
    });
  }

  /// 开始编辑指定 item（仅取消同模块内其它 item 的编辑态）。
  void _startEdit(int index) {
    if (index < 0 || index >= _rows.length) {
      return;
    }
    setState(() {
      _cancelItemEditing();
      _activeRegion = _MPConfirmSelectionRegion.items;
      _itemEditingSnapshot = _rows[index].text;
      _editingItemIndex = index;
      _itemEditingController = TextEditingController(text: _rows[index].text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _itemEditingFocusNode.requestFocus();
      }
    });
  }

  /// 保存 ORIGINAL TEXT 编辑内容。
  void _saveOriginalTextEdit() {
    if (!_isOriginalTextEditing) {
      return;
    }
    setState(() => _cancelOriginalTextEditing(applyChanges: true));
  }

  /// 保存当前 item 编辑内容。
  void _saveItemEdit() {
    if (_editingItemIndex == null) {
      return;
    }
    setState(() => _cancelItemEditing(applyChanges: true));
  }

  void _onConfirm() {
    if (_submitting) {
      return;
    }
    _cancelOriginalTextEditing(applyChanges: true);
    _cancelItemEditing(applyChanges: true);
    final MPQuickCaptureConfirmResult result = _buildPopResult(confirmed: true);
    if (!_canSubmitResult(result)) {
      MPToastUtils.showMessage('No suggestions selected.');
      return;
    }
    _submitConfirm(result);
  }

  /// 本地校验：至少选中 original text 或一条 suggestion。
  bool _canSubmitResult(MPQuickCaptureConfirmResult result) {
    final String? chosenOriginal = result.originalText?.trim();
    final bool useOriginalText =
        chosenOriginal != null && chosenOriginal.isNotEmpty;
    if (useOriginalText) {
      return true;
    }
    return result.todos.isNotEmpty || result.memos.isNotEmpty;
  }

  Future<void> _submitConfirm(MPQuickCaptureConfirmResult result) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitting = true);
    final bool success = await widget.onConfirmSubmit(result);
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() => _submitting = false);
  }

  /// 编辑态输入框（ORIGINAL TEXT 与 item 行共用样式）。
  Widget _buildEditTextField({
    required Key fieldKey,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      minLines: 1,
      maxLines: 4,
      style: TextStyle(
        fontSize: OmiFontSize.t9_18,
        fontWeight: OmiFontWeight.medium,
        color: mainTextColor,
        height: 1.3,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
      ),
    );
  }

  /// 编辑 / 保存按钮（与 item 行一致）。
  Widget _buildEditActionButton({
    required bool editing,
    required VoidCallback onTap,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Icon(
          editing ? Icons.check_rounded : Icons.edit_outlined,
          color: editing ? _kBlue : secondTextColor,
          size: editing ? 20 : 19,
        ),
      ),
    );
  }

  void _onItemSelectionTap(int index) {
    if (index < 0 || index >= _rows.length) {
      return;
    }
    // originalText 选中时：点击 item 行仅激活 items 区域，不勾选；再次点击 item 才 toggle。
    if (_isOriginalTextRegionActive) {
      _selectItemsRegion();
      return;
    }
    setState(() => _rows[index].selected = !_rows[index].selected);
  }

  /// Checkbox 始终可独立切换，包括当前 item 正在编辑时。
  void _onItemCheckboxTap(int index) {
    if (index < 0 || index >= _rows.length) {
      return;
    }
    setState(() {
      _activeRegion = _MPConfirmSelectionRegion.items;
      _rows[index].selected = !_rows[index].selected;
    });
  }

  String _displayLine(_ConfirmRow row) {
    final String prefix = row.isTodo ? 'Todo: ' : 'Memo: ';
    return '$prefix${row.text}';
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 14),
      child: Row(
        children: <Widget>[
          Text(
            'Review AI suggestions',
            style: TextStyle(fontSize: OmiFontSize.t9_18, fontWeight: OmiFontWeight.bold, color: mainTextColor),
          ),
          const Spacer(),
          IconButton(
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(_buildPopResult(confirmed: false)),
            icon: const Icon(Icons.close_rounded),
            color: secondTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: OmiFontSize.t5_14,
        fontWeight: OmiFontWeight.medium,
        color: secondTextColor.withValues(alpha: 0.9),
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _buildOriginalTextCard() {
    final bool editing = _isOriginalTextEditing;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: editing ? null : _selectOriginalTextRegion,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _buildRegionCardDecoration(isActive: _isOriginalTextRegionActive),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: editing && _originalTextController != null
                    ? _buildEditTextField(
                        fieldKey: const ValueKey<String>('confirm_original_text_edit'),
                        controller: _originalTextController!,
                        focusNode: _originalTextFocusNode,
                      )
                    : Text(
                        _originalText,
                        style: TextStyle(
                          fontSize: OmiFontSize.t8_17,
                          fontWeight: OmiFontWeight.medium,
                          color: mainTextColor,
                          height: 1.35,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              _buildEditActionButton(editing: editing, onTap: editing ? _saveOriginalTextEdit : _startEditOriginalText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionLeading(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? _kBlue : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? _kBlue : lineColor.withValues(alpha: 0.95), width: 2),
      ),
      child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
    );
  }

  Widget _buildIssueTile(int index) {
    final bool editing = _editingItemIndex == index;
    final _ConfirmRow row = _rows[index];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: index == _rows.length - 1 ? null : Border(bottom: BorderSide(color: lineColor.withValues(alpha: 0.9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: editing ? null : () => _onItemSelectionTap(index),
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onItemCheckboxTap(index),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 2, 4, 6),
                        child: _buildSelectionLeading(row.selected),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: editing && _itemEditingController != null
                          ? _buildEditTextField(
                              fieldKey: ValueKey<String>('confirm_item_edit_$index'),
                              controller: _itemEditingController!,
                              focusNode: _itemEditingFocusNode,
                            )
                          : Text(
                              _displayLine(row),
                              maxLines: 8,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: OmiFontSize.t7_16,
                                fontWeight: OmiFontWeight.medium,
                                color: mainTextColor,
                                height: 1.35,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildEditActionButton(
            editing: editing,
            onTap: editing ? _saveItemEdit : () => _startEdit(index),
            padding: const EdgeInsets.only(top: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesCard() {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: _selectItemsRegion,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: _buildRegionCardDecoration(isActive: _isItemsRegionActive),
          child: Column(children: List<Widget>.generate(_rows.length, _buildIssueTile)),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              height: 50,
              child: TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(_buildPopResult(confirmed: false)),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F9),
                  foregroundColor: mainTextColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: OmiFontSize.t7_16, fontWeight: OmiFontWeight.medium, color: mainTextColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 50,
              child: TextButton(
                onPressed: _submitting ? null : _onConfirm,
                style: TextButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: OmiFontSize.t7_16,
                          fontWeight: OmiFontWeight.medium,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double maxHeight = mq.size.height * 0.75;
    final double safeBottom = mq.viewPadding.bottom;
    final double keyboardInset = mq.viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: EdgeInsets.only(bottom: safeBottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AbsorbPointer(
                    absorbing: _submitting,
                    child: _buildHeader(),
                  ),
                  Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                  Flexible(
                    child: AbsorbPointer(
                      absorbing: _submitting,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (_rows.isNotEmpty) ...<Widget>[
                              _buildSectionTitle('Suggested items'),
                              const SizedBox(height: 10),
                              _buildIssuesCard(),
                              const SizedBox(height: 16),
                              Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                              const SizedBox(height: 16),
                            ],
                            _buildSectionTitle('What you said'),
                            const SizedBox(height: 10),
                            _buildOriginalTextCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
