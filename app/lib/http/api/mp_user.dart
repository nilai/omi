import 'dart:convert';
import 'package:flutter/material.dart';
import '../../env/env.dart';
import '../schema/mp_user.dart';
import '../shared.dart';

// GET /api/v1/user/get_profile
Future<MPGetUserProfileResponse?> getUserProfile(MPGetUserProfileRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/user/get_profile',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getUserProfile response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetUserProfileResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/user/update_profile
Future<MPUpdateUserProfileResponse?> updateUserProfile(MPUpdateUserProfileRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/user/update_profile',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('updateUserProfile response: ${response.body}');
  if (response.statusCode == 200) {
    return MPUpdateUserProfileResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
  return null;
}
