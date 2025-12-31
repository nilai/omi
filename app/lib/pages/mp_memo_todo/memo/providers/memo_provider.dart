// AI-generated START - Memo 状态管理Provider
import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_memo.dart' as mp_memo_api;
import 'package:omi/backend/schema/mp/mp_data_model.dart';
import 'package:omi/backend/schema/mp/mp_memo.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';

/// Memo 任务数据模型
class MemoTaskItem {
  // AI-generated START - 构造函数
  const MemoTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.tags = const [],
  });
  // AI-generated END - 构造函数

  /// 任务ID
  final String id;

  /// 任务标题
  final String title;

  /// 任务描述
  final String description;

  /// 任务日期（格式：YYYY-MM-DD）
  final String date;

  /// 标签列表
  final List<String> tags;
}

/// Memo 状态管理Provider
/// 管理 Memo 任务列表数据
class MemoProvider with ChangeNotifier {
  // AI-generated START - Memo 任务列表
  List<MemoTaskItem> _memos = [];
  // AI-generated END - _memos

  // AI-generated START - 是否正在加载
  bool _isLoading = false;
  // AI-generated END - _isLoading

  // AI-generated START - 是否正在获取更多数据
  bool _isFetching = false;
  // AI-generated END - _isFetching

  // AI-generated START - 是否还有更多数据
  bool _hasMore = true;
  // AI-generated END - _hasMore

  // AI-generated START - 分页游标
  String _cursor = '';
  // AI-generated END - _cursor

  // AI-generated START - 错误信息
  String? _error;
  // AI-generated END - _error

  // AI-generated START - 搜索关键词
  String _searchQuery = '';
  // AI-generated END - _searchQuery

  // AI-generated START - 获取 Memo 任务列表
  List<MemoTaskItem> get memos => _memos;
  // AI-generated END - memos

  // AI-generated START - 获取是否正在加载
  bool get isLoading => _isLoading;
  // AI-generated END - isLoading

  // AI-generated START - 获取是否正在获取更多数据
  bool get isFetching => _isFetching;
  // AI-generated END - isFetching

  // AI-generated START - 获取是否还有更多数据
  bool get hasMore => _hasMore;
  // AI-generated END - hasMore

  // AI-generated START - 获取错误信息
  String? get error => _error;
  // AI-generated END - error

  // AI-generated START - 获取搜索关键词
  String get searchQuery => _searchQuery;
  // AI-generated END - searchQuery

  // AI-generated START - 获取过滤后的 Memo 任务列表
  List<MemoTaskItem> get filteredMemos {
    // 搜索功能暂时不实现，直接返回所有数据
    return _memos;
  }
  // AI-generated END - filteredMemos

  // AI-generated START - 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  // AI-generated END - setLoading

  // AI-generated START - 设置搜索关键词（暂时空实现）
  void setSearchQuery(String query) {
    _searchQuery = query;
    // 搜索功能暂时不实现
    notifyListeners();
  }
  // AI-generated END - setSearchQuery

  // AI-generated START - 加载 Memo 任务列表
  Future<void> loadMemos() async {
    setLoading(true);
    _cursor = ''; // 重置游标
    // 调用 API 获取 Memo 列表
    final request = MPGetMemoListRequest(
      pageSize: 20, // 每页数量
      cursor: _cursor, // 分页游标，首次加载为空字符串
    );

    final response = await mp_memo_api.getMemoList(request);

    if (response != null) {
      // 将 API 返回的数据转换为 MemoTaskItem
      _memos = response.memos.map((memo) => _convertToMemoTaskItem(memo)).toList();
      _hasMore = response.hasMore;
      // 更新游标（如果 API 返回了新的游标，需要从响应中获取）
      // 注意：如果 API 没有返回 cursor，可能需要使用最后一个 memo 的 id 作为 cursor
      if (_memos.isNotEmpty) {
        _cursor = _memos.last.id; // 使用最后一个 memo 的 id 作为下次请求的 cursor
      }
    }
    _isLoading = false;
    notifyListeners();
  }
  // AI-generated END - loadMemos

  // AI-generated START - 加载更多 Memo 任务
  Future<void> loadMoreMemos() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;

    // 调用 API 加载更多 Memo 数据
    final request = MPGetMemoListRequest(
      pageSize: 20, // 每页数量
      cursor: _cursor, // 使用当前游标
    );

    final response = await mp_memo_api.getMemoList(request);

    if (response != null) {
      // 将 API 返回的数据转换为 MemoTaskItem 并追加到列表
      final moreMemos = response.memos.map((memo) => _convertToMemoTaskItem(memo)).toList();
      _memos.addAll(moreMemos);
      _hasMore = response.hasMore;
      // 更新游标
      if (moreMemos.isNotEmpty) {
        _cursor = moreMemos.last.id; // 使用最后一个 memo 的 id 作为下次请求的 cursor
      }
    }

    _isFetching = false;
    notifyListeners();
  }
  // AI-generated END - loadMoreMemos

  // AI-generated START - 添加 Memo 任务
  void addMemo(MemoTaskItem memo) {
    _memos.insert(0, memo);
    notifyListeners();
  }
  // AI-generated END - addMemo

  // AI-generated START - 通过文本创建 Memo
  /// 通过 API 使用文本内容创建 Memo
  /// [content] Memo 的文本内容
  /// [createAt] 创建时间戳（秒级），如果为 null 则使用当前时间
  /// 返回 true 表示创建成功，false 表示创建失败
  Future<void> createMemoWithText({
    required String content,
    int? createAt,
  }) async {
    try {
      // 如果没有提供创建时间，使用当前时间戳（秒级）
      final timestamp = createAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 创建请求
      final request = MPCreateMemoWithTextRequest(
        content: content,
        createAt: timestamp,
      );

      // 调用 API
      final response = await mp_memo_api.createMemoWithText(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          MPToastUtils.showMessage('Memo 创建成功');
          // 创建成功后，刷新列表
          await loadMemos();
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
        }
      } else {
        MPToastUtils.showMessage('创建 Memo 失败: 响应为空');
      }
    } catch (e) {
      MPToastUtils.showMessage('创建 Memo 异常: $e');
    }
  }
  // AI-generated END - createMemoWithText

  // AI-generated START - 通过文本更新 Memo
  /// 通过 API 使用文本内容更新 Memo
  /// [memoId] Memo 的 ID
  /// [content] Memo 的文本内容
  /// 返回 true 表示更新成功，false 表示更新失败
  Future<void> updateMemoWithText({
    required String memoId,
    required String content,
  }) async {
    try {
      // 创建请求
      final request = MPUpdateMemoRequest(
        memoId: memoId,
        content: content,
      );

      // 调用 API
      final response = await mp_memo_api.updateMemo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          MPToastUtils.showMessage('Memo 更新成功');
          // 更新成功后，直接更新本地卡片，不重新加载整个列表
          final index = _memos.indexWhere((m) => m.id == memoId);
          if (index != -1) {
            final existingMemo = _memos[index];
            // 更新本地 memo 项，保留其他字段，只更新 description (content)
            _memos[index] = MemoTaskItem(
              id: existingMemo.id,
              title: existingMemo.title,
              description: content, // 更新内容
              date: existingMemo.date,
              tags: existingMemo.tags,
            );
            notifyListeners();
          }
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
        }
      } else {
        MPToastUtils.showMessage('更新 Memo 失败: 响应为空');
      }
    } catch (e) {
      MPToastUtils.showMessage('更新 Memo 异常: $e');
    }
  }
  // AI-generated END - updateMemoWithText

  // AI-generated START - 更新 Memo 任务
  void updateMemo(String id, MemoTaskItem updatedMemo) {
    final index = _memos.indexWhere((m) => m.id == id);
    if (index != -1) {
      _memos[index] = updatedMemo;
      notifyListeners();
    }
  }
  // AI-generated END - updateMemo

  // AI-generated START - 删除 Memo 任务
  /// 通过 API 删除 Memo 任务
  /// [id] Memo 的 ID
  /// 返回 true 表示删除成功，false 表示删除失败
  Future<void> deleteMemo(String id) async {
    try {
      // 创建删除请求
      final request = MPDeleteMemoRequest(memoId: id);

      // 调用 API
      final response = await mp_memo_api.deleteMemo(request);

      if (response != null) {
        // 检查响应状态
        if (response.baseResp.code == 0) {
          MPToastUtils.showMessage('Memo 删除成功');
          // 从本地列表中删除
          _memos.removeWhere((m) => m.id == id);
          notifyListeners();
        } else {
          MPToastUtils.showMessage(response.baseResp.message);
        }
      } else {
        MPToastUtils.showMessage('删除 Memo 失败: 响应为空');
      }
    } catch (e) {
      MPToastUtils.showMessage('删除 Memo 异常: $e');
    }
  }
  // AI-generated END - deleteMemo

  // AI-generated START - 清空 Memo 列表
  void clearMemos() {
    _memos.clear();
    notifyListeners();
  }
  // AI-generated END - clearMemos

  // AI-generated START - 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  // AI-generated END - _formatDate

  // AI-generated START - 将 MPMemoStruct 转换为 MemoTaskItem
  MemoTaskItem _convertToMemoTaskItem(MPMemoStruct memo) {
    // 解析 createAt 时间戳（秒级）
    DateTime createDate;
    if (memo.createAt != null) {
      try {
        createDate = DateTime.fromMillisecondsSinceEpoch(memo.createAt! * 1000).toLocal();
      } catch (e) {
        // 如果解析失败，使用当前日期
        debugPrint('解析 createAt 失败: ${memo.createAt}, 使用当前日期');
        createDate = DateTime.now();
      }
    } else {
      // 如果 createAt 为 null，使用当前日期
      createDate = DateTime.now();
    }

    // 使用 content 作为 description，如果 content 太长则截取前50个字符作为 title
    String title = memo.title;
    String description = memo.content;

    return MemoTaskItem(
      id: memo.id,
      title: title,
      description: description,
      date: _formatDate(createDate),
      tags: memo.tags ?? [],
    );
  }
  // AI-generated END - _convertToMemoTaskItem
}
// AI-generated END - memo_provider.dart
