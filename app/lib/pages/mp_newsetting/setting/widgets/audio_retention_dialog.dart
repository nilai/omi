// AI-generated START - 音频保留时间选择弹窗组件
import 'package:flutter/material.dart';

/// 音频保留时间选项
enum AudioRetentionPeriod {
  oneDay('1 day', '1 day'),
  oneWeek('1 week', '1 week'),
  oneMonth('1 month', '1 month'),
  oneYear('1 year', '1 year'),
  forever('Forever', 'Forever');

  final String value;
  final String displayName;

  const AudioRetentionPeriod(this.value, this.displayName);
}

/// 音频保留时间选择弹窗
class AudioRetentionDialog {
  /// 显示音频保留时间选择弹窗
  ///
  /// [context] - BuildContext
  /// [currentValue] - 当前选中的值，默认为 '1 month'
  /// [onRetentionSelected] - 保留时间选择回调，参数为选中的值
  static Future<void> show(
    BuildContext context, {
    String? currentValue,
    Function(String value)? onRetentionSelected,
  }) async {
    final selectedValue = currentValue ?? '1 month';
    final selectedPeriod = AudioRetentionPeriod.values.firstWhere(
      (period) => period.value == selectedValue,
      orElse: () => AudioRetentionPeriod.oneMonth,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      builder: (dialogContext) {
        return _AudioRetentionDialogContent(
          selectedPeriod: selectedPeriod,
          onRetentionSelected: (value) {
            Navigator.of(dialogContext).pop();
            if (onRetentionSelected != null) {
              onRetentionSelected(value);
            }
          },
        );
      },
    );
  }
}

class _AudioRetentionDialogContent extends StatefulWidget {
  final AudioRetentionPeriod selectedPeriod;
  final Function(String value) onRetentionSelected;

  const _AudioRetentionDialogContent({
    required this.selectedPeriod,
    required this.onRetentionSelected,
  });

  @override
  State<_AudioRetentionDialogContent> createState() => _AudioRetentionDialogContentState();
}

class _AudioRetentionDialogContentState extends State<_AudioRetentionDialogContent> {
  late AudioRetentionPeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.selectedPeriod;
  }

  void _selectPeriod(AudioRetentionPeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    widget.onRetentionSelected(period.value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI-generated START - 选项列表
            ...AudioRetentionPeriod.values.map((period) {
              final isSelected = _selectedPeriod == period;

              return InkWell(
                onTap: () => _selectPeriod(period),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.1) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          period.displayName,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF8B5CF6) : Colors.black87,
                            fontSize: 16.0,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          color: Color(0xFF8B5CF6),
                          size: 20.0,
                        ),
                    ],
                  ),
                ),
              );
            }),
            // AI-generated END - 选项列表
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
// AI-generated END - audio_retention_dialog.dart
