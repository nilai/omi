import 'package:flutter/material.dart';
import 'package:omi/pages/memories/mp_memory_transition_page.dart';

import '../../backend/http/mp_api/mp_memory.dart';
import '../../backend/schema/mp/mp_data_model.dart';
import '../../backend/schema/mp/mp_memory.dart';
import '../mp_memory/conversation_detail/conversation_detail_page.dart';
import 'mp_memory_playback_page.dart';

class MPMemoryPageClient {
  static bool isOpening = false;

  static Future<void> navigateToDetailPage(BuildContext context, MPMemoryStruct memory) async {
    if (isOpening) {
      return;
    }
    isOpening = true;
    // ConversationDetailPage
    if (memory.type == MPMemoryType.onlyRecord) {
      isOpening = false;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MPMemoryPlaybackPage(
            memory: memory,
          ),
        ),
      );
      return;
    }
    final req = MPGetSummaryStatusRequest(memoryId: memory.id);
    final res = await getSummaryStatus(req);
    final status = res?.status ?? 0;
    isOpening = false;
    if (status == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => MPMemoryTransitionPage(memory: memory)));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationDetailPage(memory: memory)));
  }
}
