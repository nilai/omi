/// 与 React `UserData` / `UserContext` 对齐：`guest` | `device` | `account`
class MPUser {
  const MPUser({
    required this.id,
    required this.name,
    required this.userType,
    this.accountId,
    this.email,
    this.deviceId,
  });

  final String id;
  final String name;

  /// `guest` | `device` | `account`
  final String userType;
  final String? accountId;
  final String? email;

  /// 设备标识（访客阶段与登出后恢复）
  final String? deviceId;

  /// 已登录账号（含邮箱/第三方）
  bool get isLoggedIn =>
      userType == 'account' && accountId != null && accountId!.isNotEmpty;

  MPUser copyWith({
    String? id,
    String? name,
    String? userType,
    String? accountId,
    String? email,
    String? deviceId,
  }) {
    return MPUser(
      id: id ?? this.id,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      accountId: accountId ?? this.accountId,
      email: email ?? this.email,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

class MPTodo {
  const MPTodo({
    required this.id,
    required this.title,
    required this.completed,
    this.dueLabel,
    this.linkedMemoryId,
    this.category = 'Today',
  });

  final String id;
  final String title;
  final bool completed;
  final String? dueLabel;
  final String? linkedMemoryId;

  /// React: Up Next / Today / Completed 等
  final String category;

  MPTodo copyWith({
    String? id,
    String? title,
    bool? completed,
    String? dueLabel,
    String? linkedMemoryId,
    String? category,
  }) {
    return MPTodo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      dueLabel: dueLabel ?? this.dueLabel,
      linkedMemoryId: linkedMemoryId ?? this.linkedMemoryId,
      category: category ?? this.category,
    );
  }
}

class MPMemory {
  const MPMemory({
    required this.id,
    required this.title,
    required this.summary,
    required this.dateLabel,
    required this.hasAudio,
  });

  final String id;
  final String title;
  final String summary;
  final String dateLabel;
  final bool hasAudio;

  MPMemory copyWith({
    String? id,
    String? title,
    String? summary,
    String? dateLabel,
    bool? hasAudio,
  }) {
    return MPMemory(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      dateLabel: dateLabel ?? this.dateLabel,
      hasAudio: hasAudio ?? this.hasAudio,
    );
  }
}

class MPConversation {
  const MPConversation({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAtLabel,
  });

  final String id;
  final String title;
  final String preview;
  final String updatedAtLabel;

  MPConversation copyWith({
    String? id,
    String? title,
    String? preview,
    String? updatedAtLabel,
  }) {
    return MPConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      updatedAtLabel: updatedAtLabel ?? this.updatedAtLabel,
    );
  }
}

class MPMemo {
  const MPMemo({
    required this.id,
    required this.title,
    required this.content,
    required this.timeLabel,
  });

  final String id;
  final String title;
  final String content;
  final String timeLabel;

  MPMemo copyWith({
    String? id,
    String? title,
    String? content,
    String? timeLabel,
  }) {
    return MPMemo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timeLabel: timeLabel ?? this.timeLabel,
    );
  }
}

class MPInsight {
  const MPInsight({
    required this.id,
    required this.title,
    required this.type,
    required this.summary,
  });

  final String id;
  final String title;
  final String type;
  final String summary;
}

class MPProject {
  const MPProject({
    required this.id,
    required this.name,
    required this.overview,
  });

  final String id;
  final String name;
  final String overview;
}
