// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPCreateTodoRequest _$MPCreateTodoRequestFromJson(Map<String, dynamic> json) =>
    MPCreateTodoRequest(
      title: json['title'] as String,
      ownerId: json['owner_id'] as String,
      priority: json['priority'] as String,
      deadline: json['deadline'] as String,
    );

Map<String, dynamic> _$MPCreateTodoRequestToJson(
  MPCreateTodoRequest instance,
) => <String, dynamic>{
  'title': instance.title,
  'owner_id': instance.ownerId,
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
