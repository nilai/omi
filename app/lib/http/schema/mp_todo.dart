import 'package:json_annotation/json_annotation.dart';

import 'mp_data_model.dart';

part 'mp_todo.g.dart';

/// 与后端 `TodoListSectionType` 对齐：1 Today，2 近 7 天，3 更远未来，4 逾期，5 已完成，6 无截止日期且已过期（Unscheduled）。
///
/// 未在枚举中登记的数字会反序列化为 [unmapped]（见 [TodoListSectionStruct.sectionType] 的 [JsonKey.unknownEnumValue]），避免解析崩溃。
enum TodoListSectionType {
  @JsonValue(1)
  today,

  @JsonValue(2)
  upcomingSevenDays,

  @JsonValue(3)
  future,

  @JsonValue(4)
  overdue,

  @JsonValue(5)
  completed,

  @JsonValue(6)
  unscheduled,

  /// 仅 JSON 反序列化兜底：服务端新增 type 且客户端未升级时落到此值，UI 侧应忽略该 section。
  @JsonValue(-1)
  unmapped,
}

// Get Todo List Request
@JsonSerializable()
class GetTodoGroupedListRequest {
  @JsonKey(name: 'page_size')
  final int pageSize;

  @JsonKey(name: 'page_no')
  final int pageno;

  GetTodoGroupedListRequest({required this.pageSize, required this.pageno});

  factory GetTodoGroupedListRequest.fromJson(Map<String, dynamic> json) => _$GetTodoGroupedListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetTodoGroupedListRequestToJson(this);
}

// Create Todo Request
@JsonSerializable()
class MPCreateTodoRequest {
  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'memory_id')
  final String? memoryId;

  @JsonKey(name: 'insight_id')
  final String? insightId;

  @JsonKey(name: 'priority')
  final String priority;

  @JsonKey(name: 'deadline')
  final int? deadline;

  @JsonKey(name: 'feed_card_id')
  final String? feedCardId;

  @JsonKey(name: 'description')
  final String? description;

  MPCreateTodoRequest({
    required this.title,
    this.memoryId,
    this.insightId,
    required this.priority,
    required this.deadline,
    this.feedCardId,
    this.description,
  });

  factory MPCreateTodoRequest.fromJson(Map<String, dynamic> json) => _$MPCreateTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateTodoRequestToJson(this);
}

// Done Todo Request
@JsonSerializable()
class MPDoneTodoRequest {
  @JsonKey(name: 'todo_id')
  final String todoId;

  MPDoneTodoRequest({required this.todoId});

  factory MPDoneTodoRequest.fromJson(Map<String, dynamic> json) => _$MPDoneTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPDoneTodoRequestToJson(this);
}

// Done Todo Batch Request
@JsonSerializable()
class DoneTodoBatchRequest {
  @JsonKey(name: 'todo_ids')
  final List<String> todoIds;

  DoneTodoBatchRequest({required this.todoIds});

  factory DoneTodoBatchRequest.fromJson(Map<String, dynamic> json) =>
      _$DoneTodoBatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DoneTodoBatchRequestToJson(this);
}

// Clear Todo Request
@JsonSerializable()
class MPClearTodoRequest {
  @JsonKey(name: 'todo_ids')
  final List<String> todoIds;

  MPClearTodoRequest({required this.todoIds});

  factory MPClearTodoRequest.fromJson(Map<String, dynamic> json) => _$MPClearTodoRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPClearTodoRequestToJson(this);
}

// Delete Todo Request
@JsonSerializable()
class MPDeleteTodoRequest {
  @JsonKey(name: 'todo_id')
  final String todoId;

  MPDeleteTodoRequest({required this.todoId});

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
  final int deadline;

  @JsonKey(name: 'is_completed')
  final bool isCompleted;

  @JsonKey(name: 'pre_create_status')
  final int? preCreateStatus;

  @JsonKey(name: 'feed_card_id')
  final String? feedCardId;

  @JsonKey(name: 'source')
  final String? source;

  @JsonKey(name: 'description')
  final String? description;

  MPUpdateTodoRequest({
    required this.todoId,
    required this.title,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
    this.preCreateStatus,
    this.feedCardId,
    this.source,
    this.description,
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

/// Thrift `GetTodoListResponse`（如 `/api/v2/todo/focus/candidates`）：扁平 `todos` + 分页元数据。
@JsonSerializable(explicitToJson: true)
class GetTodoListResponse {
  @JsonKey(name: 'todos')
  final List<MPTodoStruct>? todos;

  @JsonKey(name: 'has_more')
  final bool? hasMore;

  @JsonKey(name: 'total_count')
  final int? totalCount;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  GetTodoListResponse({
    this.todos,
    this.hasMore,
    this.totalCount,
    required this.baseResp,
  });

  factory GetTodoListResponse.fromJson(Map<String, dynamic> json) => _$GetTodoListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetTodoListResponseToJson(this);
}

@JsonSerializable()
class TodoListSectionStruct {
  @JsonKey(name: 'section_type', unknownEnumValue: TodoListSectionType.unmapped)
  final TodoListSectionType sectionType;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'todos')
  final List<MPTodoStruct> todos;

  @JsonKey(name: 'total_count')
  final int? totalCount;

  TodoListSectionStruct({required this.sectionType, required this.title, required this.todos, this.totalCount});

  factory TodoListSectionStruct.fromJson(Map<String, dynamic> json) => _$TodoListSectionStructFromJson(json);

  Map<String, dynamic> toJson() => _$TodoListSectionStructToJson(this);
}

// Create Todo Response
@JsonSerializable()
class MPCreateTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPCreateTodoResponse({required this.baseResp});

  factory MPCreateTodoResponse.fromJson(Map<String, dynamic> json) => _$MPCreateTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPCreateTodoResponseToJson(this);
}

// Done Todo Response
@JsonSerializable()
class MPDoneTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPDoneTodoResponse({required this.baseResp});

  factory MPDoneTodoResponse.fromJson(Map<String, dynamic> json) => _$MPDoneTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPDoneTodoResponseToJson(this);
}

// Done Todo Batch Response
@JsonSerializable()
class DoneTodoBatchResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  DoneTodoBatchResponse({required this.baseResp});

  factory DoneTodoBatchResponse.fromJson(Map<String, dynamic> json) =>
      _$DoneTodoBatchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DoneTodoBatchResponseToJson(this);
}

// Clear Todo Response
@JsonSerializable()
class MPClearTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPClearTodoResponse({required this.baseResp});

  factory MPClearTodoResponse.fromJson(Map<String, dynamic> json) => _$MPClearTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPClearTodoResponseToJson(this);
}

// Delete Todo Response
@JsonSerializable()
class MPDeleteTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPDeleteTodoResponse({required this.baseResp});

  factory MPDeleteTodoResponse.fromJson(Map<String, dynamic> json) => _$MPDeleteTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPDeleteTodoResponseToJson(this);
}

// Update Todo Response
@JsonSerializable()
class MPUpdateTodoResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPUpdateTodoResponse({required this.baseResp});

  factory MPUpdateTodoResponse.fromJson(Map<String, dynamic> json) => _$MPUpdateTodoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPUpdateTodoResponseToJson(this);
}

/// 批量创建中的单条 Todo（与后端 `BatchCreateTodoItem` 对齐）。
@JsonSerializable()
class MPBatchCreateTodoItem {
  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'priority')
  final String priority;

  @JsonKey(name: 'deadline')
  final int? deadline;

  @JsonKey(name: 'memory_id')
  final String? memoryId;

  @JsonKey(name: 'description')
  final String? description;

  MPBatchCreateTodoItem({required this.title, required this.priority, required this.deadline, this.memoryId, this.description});

  factory MPBatchCreateTodoItem.fromJson(Map<String, dynamic> json) => _$MPBatchCreateTodoItemFromJson(json);

  Map<String, dynamic> toJson() => _$MPBatchCreateTodoItemToJson(this);
}

/// 批量创建中的单条 Memo（与后端 `BatchCreateMemoItem` 对齐）。
@JsonSerializable()
class MPBatchCreateMemoItem {
  @JsonKey(name: 'content')
  final String content;

  @JsonKey(name: 'create_at')
  final int createAt;

  @JsonKey(name: 'memory_id')
  final String? memoryId;

  @JsonKey(name: 'source')
  final String source;

  @JsonKey(name: 'description')
  final String? description;

  MPBatchCreateMemoItem({required this.content, required this.createAt, this.memoryId, this.source = 'text', this.description});

  factory MPBatchCreateMemoItem.fromJson(Map<String, dynamic> json) => _$MPBatchCreateMemoItemFromJson(json);

  Map<String, dynamic> toJson() => _$MPBatchCreateMemoItemToJson(this);
}

/// POST `/api/v1/batch/create` 请求体（与后端 `BatchCreateRequest` 对齐）。
@JsonSerializable()
class MPBatchCreateRequest {
  @JsonKey(name: 'todos')
  final List<MPBatchCreateTodoItem>? todos;

  @JsonKey(name: 'memos')
  final List<MPBatchCreateMemoItem>? memos;

  MPBatchCreateRequest({this.todos, this.memos});

  factory MPBatchCreateRequest.fromJson(Map<String, dynamic> json) => _$MPBatchCreateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPBatchCreateRequestToJson(this);
}

/// POST `/api/v1/batch/create` 响应（与后端 `BatchCreateResponse` 对齐）。
@JsonSerializable()
class MPBatchCreateResponse {
  @JsonKey(name: 'todo_count')
  final int todoCount;

  @JsonKey(name: 'memo_count')
  final int memoCount;

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPBatchCreateResponse({required this.todoCount, required this.memoCount, required this.baseResp});

  factory MPBatchCreateResponse.fromJson(Map<String, dynamic> json) => _$MPBatchCreateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPBatchCreateResponseToJson(this);
}

/// POST `/api/v2/todo/focus/replace` 请求体（与后端「替换 / 占用 Today's Focus 槽位」对齐）。
@JsonSerializable()
class MPReplaceTodayFocusRequest {
  @JsonKey(name: 'slot')
  final int? slot;

  @JsonKey(name: 'todo_id')
  final String? todoId;

  MPReplaceTodayFocusRequest({this.slot, this.todoId});

  factory MPReplaceTodayFocusRequest.fromJson(Map<String, dynamic> json) => _$MPReplaceTodayFocusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPReplaceTodayFocusRequestToJson(this);
}

/// POST `/api/v2/todo/focus/replace` 响应。
@JsonSerializable()
class MPReplaceTodayFocusResponse {

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPReplaceTodayFocusResponse({required this.baseResp});

  factory MPReplaceTodayFocusResponse.fromJson(Map<String, dynamic> json) => _$MPReplaceTodayFocusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPReplaceTodayFocusResponseToJson(this);
}

@JsonSerializable()
class MPRemoveTodayFocusRequest {
  @JsonKey(name: 'slot')
  int? slot;

  MPRemoveTodayFocusRequest({this.slot});

  factory MPRemoveTodayFocusRequest.fromJson(Map<String, dynamic> json) => _$MPRemoveTodayFocusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MPRemoveTodayFocusRequestToJson(this);
}

/// POST `/api/v2/todo/focus/remove` 响应。
@JsonSerializable()
class MPRemoveTodayFocusResponse {

  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  MPRemoveTodayFocusResponse({required this.baseResp});

  factory MPRemoveTodayFocusResponse.fromJson(Map<String, dynamic> json) => _$MPRemoveTodayFocusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MPRemoveTodayFocusResponseToJson(this);
}

@JsonSerializable()
class AddTodayFocusRequest {

  @JsonKey(name: 'todo_id')
  String? todoId;

  AddTodayFocusRequest({this.todoId});

  factory AddTodayFocusRequest.fromJson(Map<String, dynamic> json) => _$AddTodayFocusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddTodayFocusRequestToJson(this);
}

@JsonSerializable()
class AddTodayFocusResponse {
  @JsonKey(name: 'base_resp')
  final MPBaseResp baseResp;

  AddTodayFocusResponse({required this.baseResp});

  factory AddTodayFocusResponse.fromJson(Map<String, dynamic> json) => _$AddTodayFocusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddTodayFocusResponseToJson(this);
}