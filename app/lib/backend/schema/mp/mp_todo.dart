import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_todo.g.dart';

// Get Todo List Request
@JsonSerializable()
class MPGetTodoListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'cursor')
  final String cursor;

  MPGetTodoListRequest({
    required this.pageSize,
    required this.cursor,
  });

  factory MPGetTodoListRequest.fromJson(Map<String, dynamic> json) => _$MPGetTodoListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetTodoListRequestToJson(this);
}

// Create Todo Request
@JsonSerializable()
class MPCreateTodoRequest {
  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'owner_id')
  final String ownerId;

  @JsonKey(name: 'priority')
  final String priority;

  @JsonKey(name: 'deadline')
  final String deadline;

  MPCreateTodoRequest({
    required this.title,
    required this.ownerId,
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

// ========== Response Classes ==========

// Get Todo List Response
@JsonSerializable()
class MPGetTodoListResponse {
  @JsonKey(name: 'todos')
  final List<MPTodoStruct> todos;

  @JsonKey(name: 'has_more')
  final bool hasMore;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPGetTodoListResponse({
    required this.todos,
    required this.hasMore,
    required this.baseResp,
  });

  factory MPGetTodoListResponse.fromJson(Map<String, dynamic> json) => _$MPGetTodoListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPGetTodoListResponseToJson(this);
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
