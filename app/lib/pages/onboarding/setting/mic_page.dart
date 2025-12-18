import 'package:flutter/material.dart';

/// 麦克风增益调节页面
class MicGainPage extends StatefulWidget {
  const MicGainPage({super.key});

  @override
  State<MicGainPage> createState() => _MicGainPageState();
}

class _MicGainPageState extends State<MicGainPage> {
  // 增益值，范围 0-30，默认值 18
  int _gainValue = 18;

  // 增益值范围
  static const int _minGain = 0;
  static const int _maxGain = 30;
  static const int _stepValue = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '麦克风增益',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前增益值显示
              Center(
                child: Text(
                  '$_gainValue dB',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 滑块控制区域
              _buildSliderSection(),

              const SizedBox(height: 20),

              // 环境适用说明
              _buildEnvironmentLabels(),

              const SizedBox(height: 30),

              // 详细说明文字
              _buildDescriptionText(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建滑块控制区域
  Widget _buildSliderSection() {
    return Column(
      children: [
        // 刻度数值
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final value = index * 5;
              return Text(
                '$value',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8E8E93),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        // 滑块控制行（减号、滑块、加号）
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 减号按钮
            GestureDetector(
              onTap: _decreaseGain,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.remove,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 滑块区域（包含颜色轨道和滑块）
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 颜色渐变轨道背景
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF34C759), // 绿色 0-10
                          Color(0xFF34C759), // 绿色到10
                          Color(0xFFFF3B30), // 红色 10-20
                          Color(0xFFFF3B30), // 红色到20
                          Color(0xFF8E8E93), // 灰色 20-30
                          Color(0xFF8E8E93), // 灰色到30
                        ],
                        stops: [0.0, 0.33, 0.33, 0.67, 0.67, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  // 滑块（透明轨道，只显示thumb）
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.transparent,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.black,
                      overlayColor: Colors.black.withOpacity(0.1),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
                      trackHeight: 0,
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
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 加号按钮
            GestureDetector(
              onTap: _increaseGain,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建环境适用标签
  Widget _buildEnvironmentLabels() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔊',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 4),
            Text(
              '适用于噪音较大的环境',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '👥',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 4),
            Text(
              '适用于较安静的环境',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建说明文字
  Widget _buildDescriptionText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '麦克风增益指的是麦克风在采集音频信号时对声音的放大程度。它可以让你控制麦克风的灵敏度,以适应更轻微或更响亮的声音录制。',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
            height: 1.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '增加增益会增加麦克风的灵敏度,能够捕捉到更轻微的声音;而降低增益会降低灵敏度,可以避免录制大声音时出现失真问题。',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
            height: 1.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '调节范围为:0~30dB。对于大部分会议场景建议设置范围:20-25。',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
            height: 1.5,
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
