import 'package:flutter/material.dart';
import 'package:omi/backend/schema/schema.dart';

/// 录音卡片组件（预留）
///
/// 用于在列表中显示单个录音记录
/// 目前为占位实现，未来可扩展为完整的录音卡片
class AudioRecordCard extends StatelessWidget {
  final AudioRecord audioRecord;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AudioRecordCard({
    super.key,
    required this.audioRecord,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.audio_file,
          color: audioRecord.isSuccess ? Colors.blue : Colors.grey,
        ),
        title: Text(
          audioRecord.audioRecordId,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '时间: ${audioRecord.recordTime.toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '状态: ${audioRecord.statusMessage}',
              style: TextStyle(
                fontSize: 12,
                color: audioRecord.isSuccess ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (audioRecord.isSuccess)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: onDelete,
                color: Colors.red,
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
