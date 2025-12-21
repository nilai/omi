import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_todo.dart';
import 'package:omi/env/env.dart';

// GET /api/v1/todo/get_list
Future<MPGetTodoListResponse?> getTodoList(MPGetTodoListRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/todo/get_list?page_size=${req.pageSize}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getTodoList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetTodoListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/todo/create
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
