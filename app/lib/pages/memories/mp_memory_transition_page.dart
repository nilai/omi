import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omi/backend/schema/mp/mp_data_model.dart';
import 'package:provider/provider.dart';
import '../../services/mp_home_refresh_event_service.dart';
import '../mp_memory/conversation_detail/conversation_detail_page.dart';
import '../mp_newsetting/home/widgets/mp_common_app_bar.dart';
import 'provider/mp_memory_transition_provider.dart';

/// 记忆转换页面
/// 显示生成中的状态，包含动态的加载动画
class MPMemoryTransitionPage extends StatefulWidget {
  /// 记忆ID
  final MPMemoryStruct memory;

  const MPMemoryTransitionPage({
    super.key,
    required this.memory,
  });

  @override
  State<MPMemoryTransitionPage> createState() => _MPMemoryTransitionPageState();
}

class _MPMemoryTransitionPageState extends State<MPMemoryTransitionPage> {
  @override
  Widget build(BuildContext context) {
    // 如果没有Provider，创建一个
    return ChangeNotifierProvider(
      create: (_) {
        final provider = MPMemoryTransitionProvider(
          memoryId: widget.memory.id,
          completeCallback: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => ConversationDetailPage(memory: widget.memory)));
            MPHomeRefreshEventService().emitRefresh();
          },
        );
        // 创建后立即启动轮询
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.startPolling();
        });
        return provider;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const MPCommonAppBar(
          title: '总结中',
          showBackButton: true,
        ),
        body: Consumer<MPMemoryTransitionProvider>(
          builder: (context, provider, child) {
            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 时间戳
                            _buildTimestamp(),
                            const SizedBox(height: 24),
                            // 骨架屏占位符
                            _buildSkeletonPlaceholder(),
                            const SizedBox(height: 48),
                            // 生成中提示
                            _buildGeneratingMessage(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 底部渐变
                  _buildBottomGradient(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建时间戳显示
  Widget _buildTimestamp() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(widget.memory.createAt);
    final dateText = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);

    return Text(
      dateText,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  /// 构建骨架屏占位符
  Widget _buildSkeletonPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 第一个较短的占位符
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        // 三个较长的占位符
        ...List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )),
      ],
    );
  }

  /// 构建生成中消息
  Widget _buildGeneratingMessage() {
    return Center(
      child: Column(
        children: [
          // 生成中文字，带动态点
          _MPAnimatedDotsText(
            baseText: '生成中',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          // 说明文字
          const Text(
            '生成还需几分钟,离开页面不会影响进度。',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建底部渐变
  Widget _buildBottomGradient() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF9FAFB),
            Color(0xFFE0F2FE),
          ],
        ),
      ),
    );
  }
}

/// 带动态点的文本组件
class _MPAnimatedDotsText extends StatefulWidget {
  final String baseText;
  final TextStyle style;

  const _MPAnimatedDotsText({
    required this.baseText,
    required this.style,
  });

  @override
  State<_MPAnimatedDotsText> createState() => _MPAnimatedDotsTextState();
}

class _MPAnimatedDotsTextState extends State<_MPAnimatedDotsText> {
  static const int _maxDots = 3;
  static const Duration _tick = Duration(milliseconds: 500);

  late Timer _timer;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {
        _dotCount = (_dotCount + 1) % (_maxDots + 1);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.baseText}${'.' * _dotCount}',
      style: widget.style,
    );
  }
}
