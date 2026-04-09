// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetTodoGroupedListRequest _$GetTodoGroupedListRequestFromJson(
  Map<String, dynamic> json,
) => GetTodoGroupedListRequest(
  pageSize: (json['page_size'] as num).toInt(),
  pageno: (json['page_no'] as num).toInt(),
);

Map<String, dynamic> _$GetTodoGroupedListRequestToJson(
  GetTodoGroupedListRequest instance,
) => <String, dynamic>{
  'page_size': instance.pageSize,
  'page_no': instance.pageno,
};

MPCreateTodoRequest _$MPCreateTodoRequestFromJson(Map<String, dynamic> json) =>
    MPCreateTodoRequest(
      title: json['title'] as String,
      priority: json['priority'] as String,
      deadline: json['deadline'] as int,
    );

Map<String, dynamic> _$MPCreateTodoRequestToJson(
  MPCreateTodoRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'priority': instance.priority,
  'deadline': instance.deadline,
};

MPDoneTodoRequest _$MPDoneTodoRequestFromJson(Map<String, dynamic> json) =>
    MPDoneTodoRequest(todoId: json['todo_id'] as String);

Map<String, dynamic> _$MPDoneTodoRequestToJson(MPDoneTodoRequest instance) =>
    <String, dynamic>{'todo_id': instance.todoId};

MPDeleteTodoRequest _$MPDeleteTodoRequestFromJson(Map<String, dynamic> json) =>
    MPDeleteTodoRequest(todoId: json['todo_id'] as String);

Map<String, dynamic> _$MPDeleteTodoRequestToJson(
  MPDeleteTodoRequest instance,
) => <String, dynamic>{'todo_id': instance.todoId};

MPUpdateTodoRequest _$MPUpdateTodoRequestFromJson(Map<String, dynamic> json) =>
    MPUpdateTodoRequest(
      todoId: json['todo_id'] as String,
      title: json['title'] as String,
      priority: json['priority'] as String,
      deadline: json['deadline'] as String,
      isCompleted: json['is_completed'] as bool,
    );

Map<String, dynamic> _$MPUpdateTodoRequestToJson(
  MPUpdateTodoRequest instance,
) => <String, dynamic>{
  'todo_id': instance.todoId,
  'title': instance.title,
  'priority': instance.priority,
  'deadline': instance.deadline,
  'is_completed': instance.isCompleted,
};

GetTodoGroupedListResponse _$GetTodoGroupedListResponseFromJson(
  Map<String, dynamic> json,
) => GetTodoGroupedListResponse(
  focusItems: (json['focus_items'] as List<dynamic>?)
      ?.map((e) => MPTodoStruct.fromJson(e as Map<String, dynamic>))
      .toList(),
  sections: (json['sections'] as List<dynamic>?)
      ?.map((e) => TodoListSectionStruct.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCount: (json['total_count'] as num?)?.toInt(),
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
  incompleteCount: (json['incomplete_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$GetTodoGroupedListResponseToJson(
  GetTodoGroupedListResponse instance,
) => <String, dynamic>{
  'focus_items': instance.focusItems,
  'sections': instance.sections,
  'total_count': instance.totalCount,
  'base_resp': instance.baseResp,
  'incomplete_count': instance.incompleteCount,
};

TodoListSectionStruct _$TodoListSectionStructFromJson(
  Map<String, dynamic> json,
) => TodoListSectionStruct(
  sectionType: $enumDecode(_$TodoListSectionTypeEnumMap, json['section_type']),
  title: json['title'] as String,
  todos: (json['todos'] as List<dynamic>)
      .map((e) => MPTodoStruct.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalCount: (json['total_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$TodoListSectionStructToJson(
  TodoListSectionStruct instance,
) => <String, dynamic>{
  'section_type': _$TodoListSectionTypeEnumMap[instance.sectionType]!,
  'title': instance.title,
  'todos': instance.todos,
  'total_count': instance.totalCount,
};

const _$TodoListSectionTypeEnumMap = {
  TodoListSectionType.today: 1,
  TodoListSectionType.upcomingSevenDays: 2,
  TodoListSectionType.future: 3,
  TodoListSectionType.overdue: 4,
};

MPCreateTodoResponse _$MPCreateTodoResponseFromJson(
  Map<String, dynamic> json,
) => MPCreateTodoResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPCreateTodoResponseToJson(
  MPCreateTodoResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPDoneTodoResponse _$MPDoneTodoResponseFromJson(Map<String, dynamic> json) =>
    MPDoneTodoResponse(
      baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MPDoneTodoResponseToJson(MPDoneTodoResponse instance) =>
    <String, dynamic>{'base_resp': instance.baseResp};

MPDeleteTodoResponse _$MPDeleteTodoResponseFromJson(
  Map<String, dynamic> json,
) => MPDeleteTodoResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPDeleteTodoResponseToJson(
  MPDeleteTodoResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};

MPUpdateTodoResponse _$MPUpdateTodoResponseFromJson(
  Map<String, dynamic> json,
) => MPUpdateTodoResponse(
  baseResp: MPBaseResp.fromJson(json['base_resp'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MPUpdateTodoResponseToJson(
  MPUpdateTodoResponse instance,
) => <String, dynamic>{'base_resp': instance.baseResp};
