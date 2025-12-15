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
                '$_gainValue dB',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // 颜色区域和刻度线
            Container(
              height: 24,
              margin: const EdgeInsets.only(left: 60, right: 60),
              child: Stack(
                children: [
                  // 颜色区域
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF34C759), // 绿色
                          Color(0xFFFFCC00), // 黄色
                          Color(0xFFFF3B30), // 红色
                        ],
                        stops: [0.0, 0.5, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  // 刻度线和数值
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(7, (index) {
                      final value = index * 5;
                      return Column(
                        children: [
                          Container(
                            width: 1,
                            height: 8,
                            color: const Color(0xFF2C2C2E),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                      overlayColor: const Color(0xFF007AFF).withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
                      trackHeight: 6,
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      value: _gainValue.toDouble(),
                      min: _minGain.toDouble(),
                      max: _maxGain.toDouble(),
                      divisions: 6, // 0-30共6个刻度，每5一个
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            // 说明文字
            const Text(
              '调整麦克风增益以控制录音音量。建议根据环境噪音调整，过高可能导致声音失真。',
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
