// POST /api/v1/todo/create
import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../env/env.dart';
import '../schema/mp_todo.dart';
import '../shared.dart';

// GET /api/v2/todo/get_grouped_list
Future<GetTodoGroupedListResponse?> getTodoList(GetTodoGroupedListRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/todo/get_grouped_list?page_size=${req.pageSize}&page_no=${req.pageno}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getTodoList response: ${response.body}');
  if (response.statusCode == 200) {
    return GetTodoGroupedListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

Future<MPCreateTodoResponse?> createTodo(MPCreateTodoRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/todo/create',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('createTodo response: ${response.body}');
  if (response.statusCode == 200) {
    return MPCreateTodoResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/todo/done
Future<MPDoneTodoResponse?> doneTodo(MPDoneTodoRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/todo/done',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('doneTodo response: ${response.body}');
  if (response.statusCode == 200) {
    return MPDoneTodoResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/todo/clear
Future<MPClearTodoResponse?> clearTodo(MPClearTodoRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/todo/clear',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('clearTodo response: ${response.body}');
  if (response.statusCode == 200) {
    return MPClearTodoResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/todo/delete
Future<MPDeleteTodoResponse?> deleteTodo(MPDeleteTodoRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/todo/delete',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('deleteTodo response: ${response.body}');
  if (response.statusCode == 200) {
    return MPDeleteTodoResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/todo/update
Future<MPUpdateTodoResponse?> updateTodo(MPUpdateTodoRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/todo/update',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('updateTodo response: ${response.body}');
  if (response.statusCode == 200) {
    return MPUpdateTodoResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/batch/create
Future<MPBatchCreateResponse?> batchCreate(MPBatchCreateRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/batch/create',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) {
    return null;
  }
  debugPrint('batchCreate response: ${response.body}');
  if (response.statusCode == 200) {
    return MPBatchCreateResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v2/todo/focus/replace
Future<MPReplaceTodayFocusResponse?> replaceTodayFocus(MPReplaceTodayFocusRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/todo/focus/replace',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) {
    return null;
  }
  debugPrint('replaceTodayFocus response: ${response.body}');
  if (response.statusCode == 200) {
    return MPReplaceTodayFocusResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<MPRemoveTodayFocusResponse?> removeTodayFocus(MPRemoveTodayFocusRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/todo/focus/remove',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) {
    return null;
  }
  debugPrint('removeTodayFocus response: ${response.body}');
  if (response.statusCode == 200) {
    return MPRemoveTodayFocusResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}

Future<AddTodayFocusResponse?> addTodayFocus(AddTodayFocusRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v2/todo/focus/add',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) {
    return null;
  }
  debugPrint('addTodayFocus response: ${response.body}');
  if (response.statusCode == 200) {
    return AddTodayFocusResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}