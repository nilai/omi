import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/mp/mp_speaker.dart';
import 'package:omi/env/env.dart';

// POST /api/v1/spearker/add
Future<MPAddSpeakerResponse?> addSpeaker(MPAddSpeakerRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/spearker/add',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('addSpeaker response: ${response.body}');
  if (response.statusCode == 200) {
    return MPAddSpeakerResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/spearker/mark
Future<MPMarkSpeakerResponse?> markSpeaker(MPMarkSpeakerRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/spearker/mark',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('markSpeaker response: ${response.body}');
  if (response.statusCode == 200) {
    return MPMarkSpeakerResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/spearker/get_list
Future<MPGetSpeakerListResponse?> getSpeakerList(MPGetSpeakerListRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/spearker/get_list?page_size=${req.pageSize}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getSpeakerList response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetSpeakerListResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/spearker/get_list_with_detail
Future<MPGetSpeakerListWithDetailResponse?> getSpeakerListWithDetail(MPGetSpeakerListWithDetailRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/spearker/get_list_with_detail?page_size=${req.pageSize}&cursor=${req.cursor}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getSpeakerListWithDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetSpeakerListWithDetailResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// GET /api/v1/spearker/get_detail
Future<MPGetSpeakerDetailResponse?> getSpeakerDetail(MPGetSpeakerDetailRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/spearker/get_detail?speaker_id=${req.speakerId}',
    headers: {},
    method: 'GET',
    body: '',
  );
  if (response == null) return null;
  debugPrint('getSpeakerDetail response: ${response.body}');
  if (response.statusCode == 200) {
    return MPGetSpeakerDetailResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

