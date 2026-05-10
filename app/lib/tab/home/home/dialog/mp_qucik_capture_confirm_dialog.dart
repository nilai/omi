import 'package:flutter/material.dart';

import '../../../../http/schema/mp_todo.dart';
import '../../../../utils/omi_color_utils.dart';
import '../../../../utils/omi_font_utils.dart';

/// Quick Capture 确认列表一行（由分析结果组装，不含选中状态）。
class MPQuickCaptureConfirmItem {
  /// Todo 行。
  factory MPQuickCaptureConfirmItem.todo(String title) {
    return MPQuickCaptureConfirmItem._(isTodo: true, text: title);
  }

  /// Memo 行。
  factory MPQuickCaptureConfirmItem.memo(String content) {
    return MPQuickCaptureConfirmItem._(isTodo: false, text: content);
  }

  MPQuickCaptureConfirmItem._({required this.isTodo, required this.text});

  final bool isTodo;

  /// Todo 标题或 Memo 正文（不含 `Todo:` / `Memo:` 前缀）。
  final String text;
}

/// Quick Capture 确认弹窗返回结果。
class MPQuickCaptureConfirmResult {
  /// 构造函数。
  const MPQuickCaptureConfirmResult({
    required this.confirmed,
    required this.todos,
    required this.memos,
  });

  /// 是否点击确认。
  final bool confirmed;

  /// 用户勾选且编辑后的 Todo（仅 [confirmed] 为 true 时有意义）。
  final List<MPBatchCreateTodoItem> todos;

  /// 用户勾选且编辑后的 Memo（仅 [confirmed] 为 true 时有意义）。
  final List<MPBatchCreateMemoItem> memos;
}

/// Quick Capture 结构化确认弹窗。
class MPQucikCaptureConfirmDialog extends StatefulWidget {
  /// 构造函数。
  const MPQucikCaptureConfirmDialog({
    super.key,
    required this.originalText,
    required this.items,
  });

  /// 原始文本（支持多行）。
  final String originalText;

  /// 结构化建议行（顺序与展示一致）。
  final List<MPQuickCaptureConfirmItem> items;

  /// 展示弹窗，最大高度为屏幕的 3/4。
  static Future<MPQuickCaptureConfirmResult?> show(
    BuildContext context, {
    required String originalText,
    required List<MPQuickCaptureConfirmItem> items,
  }) {
    return showModalBottomSheet<MPQuickCaptureConfirmResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return MPQucikCaptureConfirmDialog(
          originalText: originalText,
          items: items,
        );
      },
    );
  }

  @override
  State<MPQucikCaptureConfirmDialog> createState() =>
      _MPQucikCaptureConfirmDialogState();
}

class _ConfirmRow {
  _ConfirmRow({required this.isTodo, required this.text});

  final bool isTodo;
  String text;

  /// 默认全选，点击行切换。
  bool selected = true;
}

class _MPQucikCaptureConfirmDialogState
    extends State<MPQucikCaptureConfirmDialog> {
  static const Color _kBlue = Color(0xFF2F7BFF);

  late final List<_ConfirmRow> _rows = widget.items
      .map(
        (MPQuickCaptureConfirmItem e) => _ConfirmRow(
          isTodo: e.isTodo,
          text: e.text.trim(),
        ),
      )
      .where((_ConfirmRow r) => r.text.isNotEmpty)
      .toList(growable: true);

  int? _editingIndex;
  TextEditingController? _editingController;
  final FocusNode _editingFocusNode = FocusNode();

  @override
  void dispose() {
    _editingController?.dispose();
    _editingFocusNode.dispose();
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
      out.add(MPBatchCreateTodoItem(title: t, priority: '', deadline: 0));
    }
    return out;
  }

  List<MPBatchCreateMemoItem> _selectedMemos() {
    final List<MPBatchCreateMemoItem> out = <MPBatchCreateMemoItem>[];
    for (final _ConfirmRow r in _rows) {
      if (!r.selected || r.isTodo) {
        continue;
      }
      final String t = r.text.trim();
      if (t.isEmpty) {
        continue;
      }
      out.add(MPBatchCreateMemoItem(content: t, createAt: 0));
    }
    return out;
  }

  /// 开始编辑指定问题。
  void _startEdit(int index) {
    if (index < 0 || index >= _rows.length) {
      return;
    }
    _editingController?.dispose();
    _editingController = TextEditingController(text: _rows[index].text);
    setState(() => _editingIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editingFocusNode.requestFocus();
      }
    });
  }

  /// 保存当前编辑内容并返回普通列表态。
  void _saveEdit() {
    final int? index = _editingIndex;
    if (index == null ||
        _editingController == null ||
        index < 0 ||
        index >= _rows.length) {
      return;
    }
    final String next = _editingController!.text.trim();
    if (next.isNotEmpty) {
      _rows[index].text = next;
    }
    _editingController?.dispose();
    _editingController = null;
    _editingFocusNode.unfocus();
    setState(() => _editingIndex = null);
  }

  void _toggleSelected(int index) {
    if (index < 0 || index >= _rows.length) {
      return;
    }
    setState(() => _rows[index].selected = !_rows[index].selected);
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
            'AI understood this',
            style: TextStyle(
              fontSize: OmiFontSize.t9_18,
              fontWeight: OmiFontWeight.bold,
              color: mainTextColor,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(
              MPQuickCaptureConfirmResult(
                confirmed: false,
                todos: const <MPBatchCreateTodoItem>[],
                memos: const <MPBatchCreateMemoItem>[],
              ),
            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lineColor.withValues(alpha: 0.9)),
      ),
      child: Text(
        widget.originalText,
        style: TextStyle(
          fontSize: OmiFontSize.t8_17,
          fontWeight: OmiFontWeight.medium,
          color: mainTextColor,
          height: 1.35,
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
        border: Border.all(
          color: selected ? _kBlue : lineColor.withValues(alpha: 0.95),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _buildIssueTile(int index) {
    final bool editing = _editingIndex == index;
    final _ConfirmRow row = _rows[index];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: index == _rows.length - 1
            ? null
            : Border(
                bottom: BorderSide(
                  color: lineColor.withValues(alpha: 0.9),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: editing ? null : () => _toggleSelected(index),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _buildSelectionLeading(row.selected),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: editing
                            ? TextField(
                                controller: _editingController,
                                focusNode: _editingFocusNode,
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
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
          InkWell(
            onTap: editing ? _saveEdit : () => _startEdit(index),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                editing ? Icons.check_rounded : Icons.edit_outlined,
                color: editing ? _kBlue : secondTextColor,
                size: editing ? 20 : 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue, width: 2),
      ),
      child: Column(
        children: List<Widget>.generate(_rows.length, _buildIssueTile),
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
                onPressed: () => Navigator.of(context).pop(
                  MPQuickCaptureConfirmResult(
                    confirmed: false,
                    todos: const <MPBatchCreateTodoItem>[],
                    memos: const <MPBatchCreateMemoItem>[],
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F9),
                  foregroundColor: mainTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(
                  MPQuickCaptureConfirmResult(
                    confirmed: true,
                    todos: _selectedTodos(),
                    memos: _selectedMemos(),
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
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
                    _buildHeader(),
                    Container(height: 1, color: lineColor.withValues(alpha: 0.8)),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _buildSectionTitle('ORIGINAL TEXT'),
                            const SizedBox(height: 10),
                            _buildOriginalTextCard(),
                            if (_rows.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                color: lineColor.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 16),
                              _buildSectionTitle('STRUCTURED SUGGESTIONS'),
                              const SizedBox(height: 10),
                              _buildIssuesCard(),
                            ],
                          ],
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
      ),
    );
  }
}
