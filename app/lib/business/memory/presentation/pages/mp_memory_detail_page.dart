import 'package:flutter/cupertino.dart';
import 'package:omi/business/shared/models/mp_business_models.dart';

class MPMemoryDetailPage extends StatelessWidget {
  const MPMemoryDetailPage({
    super.key,
    required this.memory,
  });

  final MPMemory memory;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Memory Detail'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memory.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(memory.dateLabel),
              const SizedBox(height: 12),
              Text(memory.summary),
              const SizedBox(height: 12),
              Text(memory.hasAudio ? '包含音频记录' : '文本记录'),
            ],
          ),
        ),
      ),
    );
  }
}
