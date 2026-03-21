import 'package:flutter/foundation.dart';
import 'package:omi/business/shared/data/mp_business_repository.dart';
import 'package:omi/business/shared/models/mp_business_models.dart';

class MPBusinessController extends ChangeNotifier {
  MPBusinessController({
    required MPBusinessRepository repository,
  })  : _user = repository.getCurrentUser(),
        _guestDeviceId = repository.getCurrentUser().deviceId ?? repository.getCurrentUser().id,
        _todos = List<MPTodo>.from(repository.getTodos()),
        _memories = List<MPMemory>.from(repository.getMemories()),
        _memos = List<MPMemo>.from(repository.getMemos()),
        _insights = List<MPInsight>.from(repository.getInsights()),
        _projects = List<MPProject>.from(repository.getProjects()),
        _conversations = List<MPConversation>.from(repository.getConversations());

  MPUser _user;
  final String _guestDeviceId;
  final List<MPTodo> _todos;
  final List<MPMemory> _memories;
  final List<MPMemo> _memos;
  final List<MPInsight> _insights;
  final List<MPProject> _projects;
  final List<MPConversation> _conversations;

  MPUser get user => _user;

  /// 与 React `isLoggedIn` 一致
  bool get isLoggedIn => _user.isLoggedIn;

  List<MPTodo> get todos => List.unmodifiable(_todos);
  List<MPMemory> get memories => List.unmodifiable(_memories);
  List<MPMemo> get memos => List.unmodifiable(_memos);
  List<MPInsight> get insights => List.unmodifiable(_insights);
  List<MPProject> get projects => List.unmodifiable(_projects);
  List<MPConversation> get conversations => List.unmodifiable(_conversations);

  void addQuickCapture({
    required String text,
  }) {
    if (text.trim().isEmpty) {
      return;
    }
    final nowId = DateTime.now().millisecondsSinceEpoch;
    _memos.insert(
      0,
      MPMemo(
        id: 'memo_$nowId',
        title: text.trim(),
        content: text.trim(),
        timeLabel: '刚刚',
      ),
    );
    _todos.insert(
      0,
      MPTodo(
        id: 't_$nowId',
        title: text.trim(),
        completed: false,
        dueLabel: '今天',
        linkedMemoryId: null,
        category: 'Today',
      ),
    );
    notifyListeners();
  }

  /// 仅新增 Memo（结构化 Quick Capture 的 Memo 行）
  void addMemoOnly(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    final nowId = DateTime.now().millisecondsSinceEpoch;
    _memos.insert(
      0,
      MPMemo(
        id: 'memo_$nowId',
        title: text.trim().length > 40 ? '${text.trim().substring(0, 40)}…' : text.trim(),
        content: text.trim(),
        timeLabel: '刚刚',
      ),
    );
    notifyListeners();
  }

  /// 仅新增 Todo（结构化 Quick Capture 的 Todo 行）
  void addTodoOnly(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    final nowId = DateTime.now().millisecondsSinceEpoch;
    _todos.insert(
      0,
      MPTodo(
        id: 't_$nowId',
        title: text.trim(),
        completed: false,
        dueLabel: '今天',
        linkedMemoryId: null,
        category: 'Today',
      ),
    );
    notifyListeners();
  }

  void toggleTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) {
      return;
    }
    final old = _todos[index];
    _todos[index] = old.copyWith(completed: !old.completed);
    notifyListeners();
  }

  void addMemoryFromRecording({
    required String title,
  }) {
    final nowId = DateTime.now().millisecondsSinceEpoch;
    _memories.insert(
      0,
      MPMemory(
        id: 'm_$nowId',
        title: title,
        summary: '通过录音新增的记忆，后续可接入转写与摘要。',
        dateLabel: '刚刚',
        hasAudio: true,
      ),
    );
    notifyListeners();
  }

  void addConversationDraft(String prompt) {
    final nowId = DateTime.now().millisecondsSinceEpoch;
    _conversations.insert(
      0,
      MPConversation(
        id: 'c_$nowId',
        title: '新对话',
        preview: prompt.isEmpty ? '你可以直接输入问题，我会结合记忆回答。' : prompt,
        updatedAtLabel: '刚刚',
      ),
    );
    notifyListeners();
  }

  void linkTodoToMemory({
    required String todoId,
    required String memoryId,
  }) {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index < 0) {
      return;
    }
    _todos[index] = _todos[index].copyWith(linkedMemoryId: memoryId);
    notifyListeners();
  }

  MPMemory? getMemoryById(String memoryId) {
    final index = _memories.indexWhere((memory) => memory.id == memoryId);
    if (index < 0) {
      return null;
    }
    return _memories[index];
  }

  MPTodo? getTodoById(String todoId) {
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index < 0) {
      return null;
    }
    return _todos[index];
  }

  /// React: Mark done → Completed
  void markTodoDone(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index < 0) {
      return;
    }
    _todos[index] = _todos[index].copyWith(
      completed: true,
      category: 'Completed',
      dueLabel: '已完成',
    );
    notifyListeners();
  }

  /// React: Not now → Today
  void moveTodoToToday(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index < 0) {
      return;
    }
    _todos[index] = _todos[index].copyWith(
      category: 'Today',
      dueLabel: '今天',
    );
    notifyListeners();
  }

  void deleteTodo(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// 邮箱密码登录（Mock，与 React `login` 一致，后续可换真实 API）
  Future<void> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    final accountId = 'account_${DateTime.now().millisecondsSinceEpoch}';
    final localName = email.split('@').first;
    _user = MPUser(
      id: accountId,
      name: localName,
      userType: 'account',
      accountId: accountId,
      email: email,
      deviceId: _guestDeviceId,
    );
    notifyListeners();
    await syncLocalDataToCloud();
  }

  /// Apple / Google 登录（Mock OAuth）
  Future<void> loginWithProvider(String provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    final accountId = 'account_${provider}_${DateTime.now().millisecondsSinceEpoch}';
    final email = 'user@$provider.local';
    final displayName = provider == 'apple' ? 'Apple User' : 'Google User';
    _user = MPUser(
      id: accountId,
      name: displayName,
      userType: 'account',
      accountId: accountId,
      email: email,
      deviceId: _guestDeviceId,
    );
    notifyListeners();
    await syncLocalDataToCloud();
  }

  /// 登出并恢复访客身份（与 React `logout` 一致）
  void logout() {
    _user = MPUser(
      id: _guestDeviceId,
      name: 'Omi User',
      userType: 'guest',
      deviceId: _guestDeviceId,
    );
    notifyListeners();
  }

  /// 登录后同步本地数据到云端（Mock）
  Future<void> syncLocalDataToCloud() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
  }
}
