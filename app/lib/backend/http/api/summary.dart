import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/schema/summary.dart';
import 'package:omi/env/env.dart';

/// Generate a summary task for the given audio record ID
/// POST /v3/summary/generate
Future<SummaryResponse?> generateSummary(String audioRecordId) async {
  var response = await makeApiCall(
    url: '${Env.noteBaseUrl}v3/summary/generate',
    headers: {},
    method: 'POST',
    body: json.encode({
      'audio_record_id': audioRecordId,
    }),
  );

  if (response == null) return null;
  debugPrint('generateSummary response: ${response.body}');

  if (response.statusCode == 200) {
    return SummaryResponse.fromJson(json.decode(response.body));
  }

  return null;
}

/// Get the summary result for the given audio record ID
/// GET /v3/summary/result
Future<SummaryResult?> getSummaryResult(String audioRecordId) async {
  var response = await makeApiCall(
    url: '${Env.noteBaseUrl}v3/summary/result?audio_record_id=$audioRecordId',
    headers: {},
    method: 'GET',
    body: '',
  );

  if (response == null) return null;
  debugPrint('getSummaryResult response: ${response.body}');

  if (response.statusCode == 200) {
    return SummaryResult.fromJson(json.decode(response.body));
  }

  return null;
}
