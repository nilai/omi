import 'package:flutter/material.dart';

import '../../common/mp_navigation_bar.dart';
import '../../utils/omi_font_utils.dart';
import 'mp_account_page.dart';
import '../../utils/mp_toast_utils.dart';
import '../../utils/omi_color_utils.dart';

class OmiMinePage extends StatefulWidget {
  const OmiMinePage({super.key});

  @override
  createState() => _OmiMinePageState();
}

class _OmiMinePageState extends State<OmiMinePage> {
  /// 统一「功能未完善」Toast（项目约定）
  void _showComingSoon() {
    MPToastUtils.showFeatureComingSoon(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPNavigationBar.preferredSizeOf(context),
        child: MPNavigationBar(
          backgroundColor: Colors.white,
          variant: MPNavigationBarVariant.preferences,
          onPrimaryActionTap: _showComingSoon,
          onSecondaryActionTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const MPAccountPage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubscriptionCard(),
            const SizedBox(height: 18),
            _buildSectionTitle('AI CONFIGURATION'),
            const SizedBox(height: 16),
            _buildAiConfigCard(
              circleColor: const Color(0xFF8D6EF9),
              icon: Icons.auto_awesome,
              title: 'AI Summary Style',
              subtitle: 'Meeting secretary · Autopilot',
            ),
            const SizedBox(height: 10),
            _buildAiConfigCard(
              circleColor: blueTextColor,
              icon: Icons.groups_outlined,
              title: 'Expert Models',
              subtitle: 'Specialized assistants',
            ),
            const SizedBox(height: 10),
            _buildAiConfigCard(
              circleColor: greenTextColor,
              icon: Icons.mic_none_rounded,
              title: 'Voiceprint Recognition',
              subtitle: 'Speaker identification',
            ),
            const SizedBox(height: 10),
            _buildAiConfigCard(
              circleColor: const Color(0xFFAB7FD7),
              icon: Icons.account_circle_outlined,
              title: 'AI Personalization',
              subtitle: 'Tailored AI experience',
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('INTEGRATIONS'),
            const SizedBox(height: 16),
            _buildIntegrationsCard(),
            const SizedBox(height: 18),
            const Divider(height: 1, color: lineColor),
            const SizedBox(height: 18),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// 区块小标题（全大写、灰色）
  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: secondTextColor.withValues(alpha: 0.85),
      ),
    );
  }

  /// 底部说明文案
  Widget _buildFooter() {
    return Text(
      'MemoPin helps you turn memory into meaning, and meaning into action.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        height: 1.45,
        color: secondTextColor.withValues(alpha: 0.9),
      ),
    );
  }

  /// 顶部订阅卡片
  Widget _buildSubscriptionCard() {
    return _buildTappableCard(
      onTap: _showComingSoon,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFCC00),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 16,
                child: CustomPaint(painter: _MPPlanCrownPainter()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Plan',
                  style: TextStyle(
                    fontSize: OmiFontSize.t6_15,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upgrade for more features',
                  style: TextStyle(
                    fontSize: OmiFontSize.t3_12,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: secondTextColor.withValues(alpha: 0.45), size: 26),
        ],
      ),
    );
  }

  /// AI 配置单行
  Widget _buildAiConfigCard({
    required Color circleColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return _buildTappableCard(
      onTap: _showComingSoon,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: OmiFontSize.t6_15,
                    fontWeight: OmiFontWeight.medium,
                    color: mainTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: OmiFontSize.t3_12,
                    fontWeight: OmiFontWeight.regular,
                    color: secondTextColor.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: secondTextColor.withValues(alpha: 0.45), size: 26),
        ],
      ),
    );
  }

  /// 集成：日历 / Notion / 任务 + Manage
  Widget _buildIntegrationsCard() {
    return _buildTappableCard(
      onTap: _showComingSoon,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _integrationShortcut(
                  onTap: _showComingSoon,
                  child: _calendarGlyph(),
                  label: 'Calendar',
                ),
                _integrationShortcut(
                  onTap: _showComingSoon,
                  child: _notionGlyph(),
                  label: 'Notion',
                ),
                _integrationShortcut(
                  onTap: _showComingSoon,
                  child: _tasksGlyph(),
                  label: 'Tasks',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: _showComingSoon,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Manage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: blueTextColor,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: blueTextColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _integrationShortcut({
    required VoidCallback onTap,
    required Widget child,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mainTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendarGlyph() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: blueTextColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '17',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _notionGlyph() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _tasksGlyph() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFFF9500),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
    );
  }

  /// 白底圆角卡片 + 轻阴影
  Widget _buildTappableCard({
    required VoidCallback onTap,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
  }) {
    final BorderRadius radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _MPPlanCrownPainter extends CustomPainter {
  const _MPPlanCrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const Color crownColor = Colors.white;
    final Paint stroke = Paint()
      ..color = crownColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final Paint dot = Paint()
      ..color = crownColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    final double left = w * 0.1;
    final double right = w * 0.9;
    final double baseTop = h * 0.62;
    final double baseBottom = h * 0.84;

    final Path crown = Path()
      ..moveTo(left, baseTop)
      ..lineTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.42, h * 0.58)
      ..lineTo(w * 0.5, h * 0.3)
      ..lineTo(w * 0.58, h * 0.58)
      ..lineTo(w * 0.76, h * 0.42)
      ..lineTo(right, baseTop)
      ..lineTo(right - 0.6, baseBottom)
      ..lineTo(left + 0.6, baseBottom)
      ..close();

    canvas.drawPath(crown, stroke);

    final double dotRadius = w * 0.055;
    canvas.drawCircle(Offset(w * 0.24, h * 0.32), dotRadius, dot);
    canvas.drawCircle(Offset(w * 0.5, h * 0.2), dotRadius, dot);
    canvas.drawCircle(Offset(w * 0.76, h * 0.32), dotRadius, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
