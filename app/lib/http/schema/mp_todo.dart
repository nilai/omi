import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_todo.g.dart';

/// 与后端 `TodoListSectionType` 对齐：1 Today，2 近 7 天，3 更远未来，4 逾期。
enum TodoListSectionType {
  @JsonValue(1)
  today,

  @JsonValue(2)
  upcomingSevenDays,

  @JsonValue(3)
  future,

  @JsonValue(4)
  overdue,
}

// Get Todo List Request
@JsonSerializable()
class GetTodoGroupedListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'page_no')
  final int pageno;

  GetTodoGroupedListRequest({
    required this.pageSize,
    required this.pageno,
  });

  factory GetTodoGroupedListRequest.fromJson(Map<String, dynamic> json) => _$GetTodoGroupedListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetTodoGroupedListRequestToJson(this);
}

// Create Todo Request
@JsonSerializable()
class MPCreateTodoRequest {
  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'priority')
  final String priority;

  @JsonKey(name: 'deadline')
  final String deadline;

  MPCreateTodoRequest({
    required this.title,
    required this.priority,
    required this.deadline,
  });

  factory MPCreateTodoRequest.fromJson(Map<String, dynamic> json) => _$MPCreateTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateTodoRequestToJson(this);
}

// Done Todo Request
@JsonSerializable()
class MPDoneTodoRequest {
  @JsonKey(name: 'todo_id')
  final String todoId;

  MPDoneTodoRequest({
    required this.todoId,
  });

  factory MPDoneTodoRequest.fromJson(Map<String, dynamic> json) => _$MPDoneTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDoneTodoRequestToJson(this);
}

// Delete Todo Request
@JsonSerializable()
class MPDeleteTodoRequest {
  @JsonKey(name: 'todo_id')
  final String todoId;

  MPDeleteTodoRequest({
    required this.todoId,
  });

  factory MPDeleteTodoRequest.fromJson(Map<String, dynamic> json) => _$MPDeleteTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteTodoRequestToJson(this);
}

// Update Todo Request
@JsonSerializable()
class MPUpdateTodoRequest {
  @JsonKey(name: 'todo_id')
  final String todoId;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'priority')
  final String priority;

  @JsonKey(name: 'deadline')
  final String deadline;

  @JsonKey(name: 'is_completed')
  final bool isCompleted;

  MPUpdateTodoRequest({
    required this.todoId,
    required this.title,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
  });

  factory MPUpdateTodoRequest.fromJson(Map<String, dynamic> json) => _$MPUpdateTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateTodoRequestToJson(this);
}

// Get Todo List Response
@JsonSerializable()
class GetTodoGroupedListResponse {
  @JsonKey(name: 'focus_items')
  final List<MPTodoStruct>? focusItems;

  @JsonKey(name: 'sections')
  final List<TodoListSectionStruct>? sections;

  @JsonKey(name: 'total_count')
  final int? totalCount;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  @JsonKey(name: 'incomplete_count')
  final int? incompleteCount;

  GetTodoGroupedListResponse({
    this.focusItems,
    this.sections,
    this.totalCount,
    required this.baseResp,
    this.incompleteCount,
  });

  factory GetTodoGroupedListResponse.fromJson(Map<String, dynamic> json) => _$GetTodoGroupedListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetTodoGroupedListResponseToJson(this);
}

@JsonSerializable()
class TodoListSectionStruct {

  @JsonKey(name: 'section_type')
  final TodoListSectionType sectionType;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'todos')
  final List<MPTodoStruct> todos;

  @JsonKey(name: 'total_count')
  final int? totalCount;

  TodoListSectionStruct({
    required this.sectionType,
    required this.title,
    required this.todos,
    this.totalCount,
  });

  factory TodoListSectionStruct.fromJson(Map<String, dynamic> json) =>
      _$TodoListSectionStructFromJson(json);

  Map<String, dynamic> toJson() => _$TodoListSectionStructToJson(this);
}

// Create Todo Response
@JsonSerializable()
class MPCreateTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateTodoResponse({
    required this.baseResp,
  });

  factory MPCreateTodoResponse.fromJson(Map<String, dynamic> json) => _$MPCreateTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateTodoResponseToJson(this);
}



// Done Todo Response
@JsonSerializable()
class MPDoneTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPDoneTodoResponse({
    required this.baseResp,
  });

  factory MPDoneTodoResponse.fromJson(Map<String, dynamic> json) => _$MPDoneTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPDoneTodoResponseToJson(this);
}


// Delete Todo Response
@JsonSerializable()
class MPDeleteTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPDeleteTodoResponse({
    required this.baseResp,
  });

  factory MPDeleteTodoResponse.fromJson(Map<String, dynamic> json) => _$MPDeleteTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteTodoResponseToJson(this);
}


// Update Todo Response
@JsonSerializable()
class MPUpdateTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPUpdateTodoResponse({
    required this.baseResp,
  });

  factory MPUpdateTodoResponse.fromJson(Map<String, dynamic> json) => _$MPUpdateTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateTodoResponseToJson(this);
}
