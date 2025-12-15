import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D1D1F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '麦克风增益',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // 设备图片
            _buildDeviceImage(),
            const SizedBox(height: 40),
            // 增益值显示
            _buildGainDisplay(),
            const SizedBox(height: 40),
            // 滑块控制
            _buildSliderControl(),
            const SizedBox(height: 30),
            // 加减按钮控制
            _buildButtonControls(),
          ],
        ),
      ),
    );
  }

  /// 构建设备图片
  Widget _buildDeviceImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A4A4A),
                Color(0xFF2C2C2C),
              ],
            ),
            borderRadius: BorderRadius.circular(80),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE5E5EA),
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建增益值显示
  Widget _buildGainDisplay() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(50),
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
    );
  }

  /// 构建滑块控制
  Widget _buildSliderControl() {
    return Column(
      children: [
        Slider(
          value: _gainValue.toDouble(),
          min: _minGain.toDouble(),
          max: _maxGain.toDouble(),
          divisions: _maxGain - _minGain, // 整数步进
          activeColor: const Color(0xFF007AFF),
          inactiveColor: const Color(0xFFE5E5EA),
          onChanged: (value) {
            setState(() {
              _gainValue = value.toInt();
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_minGain',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0x991D1D1F),
              ),
            ),
            Text(
              '$_maxGain',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0x991D1D1F),
              ),
            ),
          ],
        ),
      ],
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.remove,
              color: Color(0xFF1D1D1F),
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 30),
        // 增益值文本
        Text(
          '$_gainValue',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(width: 30),
        // 增加按钮
        GestureDetector(
          onTap: _increaseGain,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.add,
              color: Color(0xFF1D1D1F),
              size: 24,
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
