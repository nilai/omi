import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// SD 卡传输进度组件
/// 显示传输进度，包含圆形进度条、翻转动画和完成时的粒子效果
class SdCardTransferProgress extends StatefulWidget {
  /// 传输进度值，范围 0.0 到 1.0
  final double progress;

  /// 显示的百分比字符串（如 "50"）
  final String displayPercentage;

  /// 剩余时间（秒数，字符串格式，如 "120.5"）
  final String secondsRemaining;

  const SdCardTransferProgress({
    super.key,
    required this.progress,
    required this.displayPercentage,
    required this.secondsRemaining,
  });

  @override
  _SdCardTransferProgressState createState() => _SdCardTransferProgressState();
}

/// SD 卡传输进度组件的状态类
/// 管理传输完成状态和粒子动画控制器
class _SdCardTransferProgressState extends State<SdCardTransferProgress> with TickerProviderStateMixin {
  /// 传输是否完成的标志
  bool _transferComplete = false;

  /// 粒子动画控制器，用于控制传输完成时的粒子爆炸效果
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    // 初始化粒子动画控制器，动画时长为 1 秒
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(covariant SdCardTransferProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当进度达到 100% 且之前未完成时，触发完成状态和粒子动画
    if (widget.progress == 1.0 && !_transferComplete) {
      setState(() {
        _transferComplete = true;
      });
      // 从 0 开始播放粒子动画
      _particleController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    // 释放动画控制器资源
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 使用 Stack 叠加多个元素：进度条、翻转动画和粒子效果
        Stack(
          alignment: Alignment.center,
          children: [
            // 圆形进度条容器
            SizedBox(
              // 尺寸为屏幕高度的 34%
              width: MediaQuery.sizeOf(context).height * 0.34,
              height: MediaQuery.sizeOf(context).height * 0.34,
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                // 圆形进度指示器
                child: CircularProgressIndicator(
                  value: widget.progress, // 进度值（0.0 到 1.0）
                  strokeWidth: 10, // 进度条宽度
                  backgroundColor: Colors.grey[800], // 背景色（未完成部分）
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // 进度条颜色（已完成部分）
                ),
              ),
            ),
            // 翻转动画：从 SD 卡图标翻转到显示进度信息
            TweenAnimationBuilder(
              tween: Tween<double>(
                begin: 0.0,
                // 如果进度大于 0，则执行翻转动画（0.0 到 1.0），否则保持 0
                end: widget.progress > 0.0 ? 1.0 : 0.0,
              ),
              duration: const Duration(milliseconds: 800), // 动画时长 800 毫秒
              builder: (context, double value, child) {
                // 计算旋转角度：从 0 度旋转到 180 度（π 弧度）
                final angle = value * pi;
                return Transform(
                  alignment: Alignment.center,
                  // 绕 Y 轴旋转，实现 3D 翻转效果
                  transform: Matrix4.rotationY(angle),
                  child: value < 0.5
                      // 前半段（0-0.5）：显示 SD 卡图标
                      ? const Icon(
                          Icons.sd_card,
                          size: 68,
                          color: Colors.white,
                        )
                      // 后半段（0.5-1.0）：显示进度信息（翻转后）
                      : Transform.flip(
                          flipX: true, // 水平翻转，使文字正常显示
                          child: Column(
                            children: [
                              // 显示百分比
                              Text(
                                '${widget.displayPercentage}%',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // 显示剩余时间（人类可读格式）
                              Text(
                                secondsToHumanReadable(widget.secondsRemaining),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              // "Remaining" 标签
                              const Text('Remaining', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ],
                          ),
                        ),
                );
              },
            ),
            // 传输完成时显示粒子爆炸效果
            if (_transferComplete) ..._buildParticles(),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建粒子爆炸效果
  /// 生成 60 个随机大小和方向的白色圆形粒子，从中心向外扩散并逐渐消失
  List<Widget> _buildParticles() {
    return List.generate(60, (index) {
      final random = math.Random();
      // 随机粒子大小：5 到 15 像素
      final size = random.nextDouble() * 10 + 5;
      // 随机角度：0 到 2π（360 度），决定粒子的扩散方向
      final angle = random.nextDouble() * 2 * pi;
      // 初始半径：粒子从距离中心 100 像素的位置开始
      const radius = 100.0;

      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          // 动画进度值（0.0 到 1.0）
          final progress = _particleController.value;
          // 距离插值：从 0 到 30 像素，使用 easeOut 缓动曲线
          final tween = Tween(begin: 0.0, end: 30.0).chain(CurveTween(curve: Curves.easeOut));
          final distance = tween.evaluate(_particleController);

          // 计算粒子在 X 和 Y 方向的偏移量
          // 使用极坐标转直角坐标公式：x = r * cos(θ), y = r * sin(θ)
          final dx = (radius + distance) * cos(angle);
          final dy = (radius + distance) * sin(angle);

          // 计算透明度：随着动画进行，从 1.0 逐渐减少到 0.0
          final opacity = (1 - progress).clamp(0.0, 1.0);

          return Positioned(
            // 粒子位置：从中心点 (150, 150) 加上计算出的偏移量
            left: 150 + dx,
            top: 150 + dy,
            child: Transform.rotate(
              // 粒子自身旋转：随着动画进行旋转 360 度
              angle: progress * 2 * pi,
              child: Opacity(
                opacity: opacity, // 应用透明度
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle, // 圆形粒子
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

/// 将秒数字符串转换为人类可读的时间格式
/// 
/// 例如：
/// - "3661" -> "1h 1m 1s"
/// - "125" -> "2m 5s"
/// - "45" -> "45s"
/// 
/// [seconds] 秒数字符串，可能包含小数部分（如 "120.5"）
/// 返回格式化的时间字符串，如 "1h 2m 3s"
String secondsToHumanReadable(String seconds) {
  // 解析秒数，忽略小数部分（如果有）
  final intSeconds = int.parse(seconds.split('.')[0]);
  
  // 计算小时数：总秒数除以 3600
  final int hours = intSeconds ~/ 3600;
  // 计算分钟数：剩余秒数（总秒数对 3600 取模）除以 60
  final int minutes = (intSeconds % 3600) ~/ 60;
  // 计算剩余秒数：总秒数对 60 取模
  final int remainingSeconds = intSeconds % 60;

  // 构建时间部分列表
  final List<String> parts = [];
  
  // 如果有小时，添加小时部分
  if (hours > 0) {
    parts.add('${hours}h');
  }

  // 如果有分钟，添加分钟部分
  if (minutes > 0) {
    parts.add('${minutes}m');
  }

  // 如果有剩余秒数，添加秒数部分
  if (remainingSeconds > 0) {
    parts.add('${remainingSeconds}s');
  }

  // 用空格连接所有部分
  return parts.join(' ');
}
