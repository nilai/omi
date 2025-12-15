import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Uncomment if adding haptic feedback

/// 麦克风增益调节页面
/// 实现可拖拽滑块和加减按钮控制增益值
class MicGainPage extends StatefulWidget {
  const MicGainPage({super.key});

  @override
  State<MicGainPage> createState() => _MicGainPageState();
}

class _MicGainPageState extends State<MicGainPage> {
  // 增益值，范围 0-30，默认值 15
  int _gainValue = 15;
  
  // 增益值范围
  static const int _minGain = 0;
  static const int _maxGain = 30;
  static const int _stepValue = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '麦克风增益',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF2C2C2E),
                        width: 1,
                      ),
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
                      inactiveTrackColor: const Color(0xFF2C2C2E),
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
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF2C2C2E),
                        width: 1,
                      ),
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
        // 可以在这里添加震动反馈或其他提示
        // HapticFeedback.lightImpact();
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
        // 可以在这里添加震动反馈或其他提示
        // HapticFeedback.lightImpact();
      }
    });
  }
}
