import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_user.dart';
import 'package:omi/env/env.dart';

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

