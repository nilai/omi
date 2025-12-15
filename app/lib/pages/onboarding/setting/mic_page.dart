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
      body: Column(
        children: [
          // 设备图片区域
          Container(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
            child: _buildDeviceImage(),
          ),
          // 描述文字
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              '调整麦克风的灵敏度以获得最佳录音效果',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // 滑块控制区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 增益值显示
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_gainValue',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 滑块标签
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '低',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      Text(
                        '麦克风增益',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '高',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 滑块
                  SliderTheme(
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
                  const SizedBox(height: 8),
                  // 范围标签
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
                  const SizedBox(height: 40),
                  // 加减按钮控制
                  _buildButtonControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设备图片
  Widget _buildDeviceImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(
          color: const Color(0xFF2C2C2E),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Microphone head
            Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF8E8E93),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            // Microphone body
            Container(
              width: 20,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5A5A5E),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            // Microphone base
            Container(
              width: 30,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3C),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加减按钮控制
  Widget _buildButtonControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 减少按钮
        GestureDetector(
          onTap: _decreaseGain,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF2C2C2E),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.remove,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 30),
        // 增益值文本
        Text(
          '$_gainValue',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 30),
        // 增加按钮
        GestureDetector(
          onTap: _increaseGain,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF2C2C2E),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
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
