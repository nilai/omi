import 'package:flutter/material.dart';

/// 麦克风增益调节弹窗
/// 用于在设置中弹出调节麦克风增益的对话框
class MicGainDialog extends StatefulWidget {
  final int initialValue;
  final Function(int) onValueChanged;

  const MicGainDialog({
    super.key,
    this.initialValue = 15,
    required this.onValueChanged,
  });

  @override
  State<MicGainDialog> createState() => _MicGainDialogState();
}

class _MicGainDialogState extends State<MicGainDialog> {
  late int _gainValue;
  
  // 增益值范围
  static const int _minGain = 0;
  static const int _maxGain = 30;
  static const int _stepValue = 5;

  @override
  void initState() {
    super.initState();
    _gainValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Text(
              '麦克风增益',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // 当前滑块值显示
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                '$_gainValue',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 滑块区域
            // 减号 滑块 加号
            Row(
              children: [
                // 减号按钮
                GestureDetector(
                  onTap: _decreaseGain,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 滑块
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF007AFF),
                      inactiveTrackColor: const Color(0xFF3A3A3C),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF007AFF).withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _gainValue.toDouble(),
                      min: _minGain.toDouble(),
                      max: _maxGain.toDouble(),
                      divisions: _maxGain - _minGain, // 整数步进
                      onChanged: (value) {
                        setState(() {
                          _gainValue = value.toInt();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 加号按钮
                GestureDetector(
                  onTap: _increaseGain,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 0 ~ 30 区间
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_minGain',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                Text(
                  '$_maxGain',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 噪音、安静描述
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '噪音',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                Text(
                  '安静',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 说明文字
            const Text(
              '调整麦克风的灵敏度以获得最佳录音效果。在嘈杂环境中建议降低灵敏度，在安静环境中可以适当提高。',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            // 操作按钮
            Row(
              children: [
                // 取消按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 确定按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onValueChanged(_gainValue);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '确定',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 增加增益值
  void _increaseGain() {
    setState(() {
      if (_gainValue + _stepValue <= _maxGain) {
        _gainValue += _stepValue;
      } else {
        _gainValue = _maxGain;
      }
    });
  }

  /// 减少增益值
  void _decreaseGain() {
    setState(() {
      if (_gainValue - _stepValue >= _minGain) {
        _gainValue -= _stepValue;
      } else {
        _gainValue = _minGain;
      }
    });
  }
}