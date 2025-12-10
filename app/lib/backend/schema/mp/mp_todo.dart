import 'package:json_annotation/json_annotation.dart';

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

  factory MPGetTodoListRequest.fromJson(Map<String, dynamic> json) =>
      _$MPGetTodoListRequestFromJson(json);

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

  factory MPCreateTodoRequest.fromJson(Map<String, dynamic> json) =>
      _$MPCreateTodoRequestFromJson(json);

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

  factory MPDoneTodoRequest.fromJson(Map<String, dynamic> json) =>
      _$MPDoneTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDoneTodoRequestToJson(this);
}

