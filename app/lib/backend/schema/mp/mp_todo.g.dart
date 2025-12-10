// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mp_todo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MPGetTodoListRequest _$MPGetTodoListRequestFromJson(
        Map<String, dynamic> json) =>
    MPGetTodoListRequest(
      pageSize: (json['page_size'] as num).toInt(),
      cursor: json['cursor'] as String,
    );

Map<String, dynamic> _$MPGetTodoListRequestToJson(
        MPGetTodoListRequest instance) =>
    <String, dynamic>{
      'page_size': instance.pageSize,
      'cursor': instance.cursor,
    };

MPCreateTodoRequest _$MPCreateTodoRequestFromJson(Map<String, dynamic> json) =>
    MPCreateTodoRequest(
      title: json['title'] as String,
      ownerId: json['owner_id'] as String,
      priority: json['priority'] as String,
      deadline: json['deadline'] as String,
    );

Map<String, dynamic> _$MPCreateTodoRequestToJson(
        MPCreateTodoRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'owner_id': instance.ownerId,
      'priority': instance.priority,
      'deadline': instance.deadline,
    };

MPDoneTodoRequest _$MPDoneTodoRequestFromJson(Map<String, dynamic> json) =>
    MPDoneTodoRequest(
      todoId: json['todo_id'] as String,
    );

Map<String, dynamic> _$MPDoneTodoRequestToJson(MPDoneTodoRequest instance) =>
    <String, dynamic>{
      'todo_id': instance.todoId,
    };
