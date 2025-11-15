import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:omi/providers/audio_record_provider.dart';
import 'package:provider/provider.dart';

/// 音频上传组件
///
/// 提供文件选择和上传功能的UI组件
class AudioUploadWidget extends StatelessWidget {
  const AudioUploadWidget({super.key});

  /// 选择并上传音频文件
  Future<void> _pickAndUploadAudio(BuildContext context) async {
    final provider = Provider.of<AudioRecordProvider>(context, listen: false);

    try {
      // 使用 file_picker 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m4a', 'wav', 'mp3', 'aac'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        // 开始上传
        final success = await provider.uploadAudio(file);

        if (context.mounted) {
          if (success) {
            _showSuccessMessage(context);
          } else {
            _showErrorMessage(context, provider.errorMessage ?? '上传失败');
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (context.mounted) {
        _showErrorMessage(context, '选择文件时出错: ${e.toString()}');
      }
    }
  }

  /// 显示成功消息
  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('录音上传成功！'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 显示错误消息
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioRecordProvider>(
      builder: (context, provider, child) {
        if (provider.isUploading) {
          // 显示上传进度
          return _buildUploadingState(provider);
        }

        // 显示上传按钮
        return _buildIdleState(context);
      },
    );
  }

  /// 构建空闲状态UI（显示上传按钮）
  Widget _buildIdleState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.audio_file,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            '上传音频文件',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持格式: M4A, WAV, MP3, AAC',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _pickAndUploadAudio(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('选择文件'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建上传中状态UI（显示进度）
  Widget _buildUploadingState(AudioRecordProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            '上传中...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '步骤 ${provider.currentStep} / ${provider.totalSteps}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(
              value: provider.uploadProgress,
            ),
          ),
        ],
      ),
    );
  }
}
