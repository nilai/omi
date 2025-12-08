import 'package:flutter/material.dart';
import 'package:omi/providers/audio_record_provider.dart';
import 'package:provider/provider.dart';

import 'upload_widget.dart';

/// 录音管理页面
///
/// 提供音频文件上传和管理功能
class AudioRecordPage extends StatefulWidget {
  const AudioRecordPage({super.key});

  @override
  State<AudioRecordPage> createState() => _AudioRecordPageState();
}

class _AudioRecordPageState extends State<AudioRecordPage> {
  @override
  void initState() {
    super.initState();
    // 初始化时重置Provider状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioRecordProvider>(context, listen: false).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录音上传'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 主要内容区域
            const Expanded(
              child: AudioUploadWidget(),
            ),

            // 底部信息区域（预留用于显示历史记录）
            Consumer<AudioRecordProvider>(
              builder: (context, provider, child) {
                if (provider.audioRecords.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '已上传 ${provider.audioRecords.length} 个录音',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _showUploadedRecords(context, provider);
                        },
                        child: const Text('查看'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示已上传的录音列表对话框
  void _showUploadedRecords(BuildContext context, AudioRecordProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已上传录音'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.audioRecords.length,
            itemBuilder: (context, index) {
              final record = provider.audioRecords[index];
              return ListTile(
                leading: const Icon(Icons.audio_file),
                title: Text(record.audioRecordId),
                subtitle: Text(
                  '时间: ${record.recordTime.toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Icon(
                  record.isSuccess ? Icons.check_circle : Icons.error,
                  color: record.isSuccess ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
