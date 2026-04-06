// POST /api/v1/speaker/add
import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../env/env.dart';
import '../schema/mp_speaker.dart';
import '../shared.dart';

Future<MPAddSpeakerResponse?> addSpeaker(MPAddSpeakerRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/speaker/add',
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

// POST /api/v1/speaker/update
Future<MPUpdateSpeakerResponse?> updateSpeaker(MPUpdateSpeakerRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/speaker/update',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('updateSpeaker response: ${response.body}');
  if (response.statusCode == 200) {
    return MPUpdateSpeakerResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}

// POST /api/v1/speaker/delete
Future<MPDeleteSpeakerResponse?> deleteSpeaker(MPDeleteSpeakerRequest req) async {
  var response = await makeApiCall(
    url: '${Env.apiBaseUrl}api/v1/speaker/delete',
    headers: {},
    method: 'POST',
    body: jsonEncode(req.toJson()),
  );
  if (response == null) return null;
  debugPrint('deleteSpeaker response: ${response.body}');
  if (response.statusCode == 200) {
    return MPDeleteSpeakerResponse.fromJson(jsonDecode(response.body));
  }
  return null;
}