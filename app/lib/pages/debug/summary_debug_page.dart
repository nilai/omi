import 'package:flutter/material.dart';
import 'package:omi/providers/summary_provider.dart';
import 'package:provider/provider.dart';

/// 转写功能调试页面
///
/// 用于测试音频转写和轮询功能
class SummaryDebugPage extends StatefulWidget {
  const SummaryDebugPage({super.key});

  @override
  State<SummaryDebugPage> createState() => _SummaryDebugPageState();
}

class _SummaryDebugPageState extends State<SummaryDebugPage> {
  final TextEditingController _audioRecordIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化时重置Provider状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SummaryProvider>(context, listen: false).reset();
    });
  }

  @override
  void dispose() {
    _audioRecordIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('转写调试'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<SummaryProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 说明文本
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '输入录音ID测试转写功能',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 输入框
                  TextField(
                    controller: _audioRecordIdController,
                    decoration: InputDecoration(
                      labelText: 'Audio Record ID',
                      hintText: '例如: 1690979656844-00006695-00007167',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.audiotrack),
                    ),
                    enabled: provider.status == SummaryTaskStatus.idle,
                  ),
                  const SizedBox(height: 20),

                  // 开始按钮
                  if (provider.status == SummaryTaskStatus.idle)
                    ElevatedButton.icon(
                      onPressed: _audioRecordIdController.text.isEmpty
                          ? null
                          : () => _startSummaryTask(context, provider),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始转写'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  // 停止按钮
                  if (provider.status == SummaryTaskStatus.polling)
                    ElevatedButton.icon(
                      onPressed: () => _stopPolling(context, provider),
                      icon: const Icon(Icons.stop),
                      label: const Text('停止轮询'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  // 重置按钮
                  if (provider.status != SummaryTaskStatus.idle &&
                      provider.status != SummaryTaskStatus.polling)
                    ElevatedButton.icon(
                      onPressed: () => _reset(context, provider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重置'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 状态显示卡片
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '当前状态',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatusRow(context, provider),
                          const Divider(height: 24),
                          _buildDetailInfo(context, provider),
                        ],
                      ),
                    ),
                  ),

                  // 错误信息
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.errorMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, SummaryProvider provider) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (provider.status) {
      case SummaryTaskStatus.idle:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
        statusText = '空闲';
        break;
      case SummaryTaskStatus.generating:
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        statusText = '生成中';
        break;
      case SummaryTaskStatus.polling:
        statusColor = Colors.orange;
        statusIcon = Icons.refresh;
        statusText = '轮询中';
        break;
      case SummaryTaskStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '已完成';
        break;
      case SummaryTaskStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = '失败';
        break;
      case SummaryTaskStatus.timeout:
        statusColor = Colors.deepOrange;
        statusIcon = Icons.timer_off;
        statusText = '超时';
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 32),
        const SizedBox(width: 12),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailInfo(BuildContext context, SummaryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.currentAudioRecordId != null) ...[
          Text(
            'Record ID:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.currentAudioRecordId!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (provider.status == SummaryTaskStatus.polling) ...[
          Text(
            '轮询进度:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.pollingCount} / ${provider.maxPollingCount} 次',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: provider.pollingCount / provider.maxPollingCount,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            '剩余时间: 约 ${provider.remainingSeconds} 秒',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        if (provider.result != null) ...[
          Text(
            '任务状态:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.result!.summaryStatus,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  void _startSummaryTask(BuildContext context, SummaryProvider provider) async {
    final audioRecordId = _audioRecordIdController.text.trim();
    if (audioRecordId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 Audio Record ID')),
      );
      return;
    }

    final success = await provider.startSummaryTask(audioRecordId);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? '启动任务失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopPolling(BuildContext context, SummaryProvider provider) {
    provider.stopPolling();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已停止轮询')),
    );
  }

  void _reset(BuildContext context, SummaryProvider provider) {
    provider.reset();
    _audioRecordIdController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已重置')),
    );
  }
}
