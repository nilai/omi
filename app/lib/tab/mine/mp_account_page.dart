import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/tab/mine/mp_account_cubit.dart';
import 'package:memo_pin/tab/mine/mp_account_state.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';

import '../../generated/assets.dart';

/// Account & Data：账户资料、订阅、数据管理、帮助与支持
class MPAccountPage extends StatelessWidget {
  const MPAccountPage({super.key});

  /// 功能未完善提示（项目约定）
  static void _comingSoon(BuildContext context) {
    MPToastUtils.showFeatureComingSoon(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPAccountCubit>(create: (_) => MPAccountCubit()..loadProfile(), child: const _MPAccountView());
  }
}

class _MPAccountView extends StatelessWidget {
  const _MPAccountView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 8),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: blueTextColor, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Account & Data',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: mainTextColor),
        ),
      ),
      body: BlocBuilder<MPAccountCubit, MPAccountState>(
        builder: (BuildContext context, MPAccountState state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileCard(
                  context,
                  state: state,
                  onSignOut: () => context.read<MPAccountCubit>().signOut(context),
                ),
                const SizedBox(height: 18),
                _buildSectionTitle('SUBSCRIPTION'),
                const SizedBox(height: 16),
                _buildSubscriptionCard(context),
                const SizedBox(height: 18),
                _buildSectionTitle('DATA MANAGEMENT'),
                const SizedBox(height: 16),
                _buildDataManagementCard(context),
                const SizedBox(height: 18),
                _buildSectionTitle('HELP & SUPPORT'),
                const SizedBox(height: 16),
                _buildHelpSupportCard(context),
                const SizedBox(height: 18),
                Text(
                  'MemoPin v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: secondTextColor.withValues(alpha: 0.85)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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

  /// 顶部：头像、用户信息、退出登录
  Widget _buildProfileCard(BuildContext context, {required MPAccountState state, required VoidCallback onSignOut}) {
    final bool loading = state.profileStatus == MPAccountProfileStatus.loading;
    return _whiteCard(
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: blueTextColor, shape: BoxShape.circle),
                  child: Center(
                    child: OmiImageLoader.localImg(
                      Assets.mpMineUser,
                      width: 36,
                      height: 36,
                      color: Colors.white,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.displayName,
                              style: TextStyle(
                                fontSize: OmiFontSize.t7_16,
                                fontWeight: OmiFontWeight.medium,
                                color: mainTextColor,
                              ),
                            ),
                          ),
                          if (loading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: blueTextColor),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.displayEmail,
                        style: TextStyle(
                          fontSize: OmiFontSize.t4_13,
                          fontWeight: OmiFontWeight.regular,
                          color: secondTextColor.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member since January 2024',
                        style: TextStyle(
                          fontSize: OmiFontSize.t4_13,
                          fontWeight: OmiFontWeight.regular,
                          color: secondTextColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Material(
              color: const Color(0xFFF0F1F3),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: state.signOutInProgress ? null : onSignOut,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.signOutInProgress)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: redColor),
                        )
                      else
                        const Icon(Icons.logout_rounded, color: redColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: redColor.withValues(alpha: state.signOutInProgress ? 0.5 : 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 订阅：Basic Plan
  Widget _buildSubscriptionCard(BuildContext context) {
    return _whiteCard(
      radius: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => MPAccountPage._comingSoon(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(color: Color(0xFFFFC940), shape: BoxShape.circle),
                  child: Center(
                    child: OmiImageLoader.localImg(
                      Assets.mpMineCrown,
                      width: 24,
                      height: 24,
                      color: Colors.white,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Plan',
                        style: TextStyle(
                          fontSize: OmiFontSize.t7_16,
                          fontWeight: OmiFontWeight.medium,
                          color: mainTextColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Upgrade for more features',
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
          ),
        ),
      ),
    );
  }

  /// 数据管理：存储、清理缓存、注销账号
  Widget _buildDataManagementCard(BuildContext context) {
    return _whiteCard(
      radius: 16,
      child: Column(
        children: [
          _buildDataRow(
            context,
            circleColor: greenTextColor,
            icon: Assets.mpMineDatabase,
            title: 'Storage',
            subtitle: '2.3 GB used',
            showChevron: false,
            titleColor: mainTextColor,
          ),
          Divider(height: 1, thickness: 1, color: lineColor, indent: 0, endIndent: 0),
          _buildDataRow(
            context,
            circleColor: const Color(0xFFFF9500),
            icon: Assets.mpMineTrash,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            showChevron: true,
            titleColor: mainTextColor,
          ),
          Divider(height: 1, thickness: 1, color: lineColor, indent: 0, endIndent: 0),
          _buildDataRow(
            context,
            circleColor: redColor,
            icon: Assets.mpMineTrash,
            title: 'Delete Account',
            subtitle: 'Permanently remove your data',
            showChevron: true,
            titleColor: redColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context, {
    required Color circleColor,
    required String icon,
    required String title,
    required String subtitle,
    required bool showChevron,
    required Color titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => MPAccountPage._comingSoon(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: Center(
                  child: OmiImageLoader.localImg(icon, width: 24, height: 24, color: Colors.white, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: OmiFontSize.t7_16,
                        fontWeight: OmiFontWeight.medium,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              if (showChevron)
                Icon(Icons.chevron_right_rounded, color: secondTextColor.withValues(alpha: 0.45), size: 26),
            ],
          ),
        ),
      ),
    );
  }

  /// 帮助与支持（含第二张图全部入口）
  Widget _buildHelpSupportCard(BuildContext context) {
    return _whiteCard(
      radius: 16,
      child: Column(
        children: [
          _buildHelpRow(context, circleColor: const Color(0xFFFF9500), icon: Icons.help_outline_rounded, title: 'FAQ'),
          Divider(height: 1, thickness: 1, color: lineColor, indent: 0, endIndent: 0),
          _buildHelpRow(
            context,
            circleColor: const Color(0xFF8D6EF9),
            assetIcon: Assets.mpMineBook,
            title: 'User Guide',
          ),
          Divider(height: 1, thickness: 1, color: lineColor, indent: 0, endIndent: 0),
          _buildHelpRow(
            context,
            circleColor: blueTextColor,
            assetIcon: Assets.mpMineMessageCircle,
            title: 'Contact Support',
          ),
          Divider(height: 1, thickness: 1, color: lineColor, indent: 0, endIndent: 0),
          _buildHelpRow(
            context,
            circleColor: const Color(0xFF6B7280),
            assetIcon: Assets.mpMineFileText,
            title: 'Terms & Privacy',
          ),
          Divider(height: 1, thickness: 1, color: lineColor, indent: 0, endIndent: 0),
          _buildHelpRow(
            context,
            circleColor: const Color(0xFF007AFF),
            assetIcon: Assets.mpMineUpload,
            title: 'Submit Diagnostic Logs',
          ),
        ],
      ),
    );
  }

  /// [assetIcon] 非空且非空字符串时圆形区内优先显示该资源，否则使用 [icon]。
  Widget _buildHelpRow(
    BuildContext context, {
    required Color circleColor,
    IconData? icon,
    String? assetIcon,
    required String title,
  }) {
    late final Widget circleChild;
    if (assetIcon != null && assetIcon.isNotEmpty) {
      circleChild = OmiImageLoader.localImg(assetIcon, width: 24, height: 24, color: Colors.white, fit: BoxFit.contain);
    } else {
      circleChild = Icon(icon, color: Colors.white, size: 21);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => MPAccountPage._comingSoon(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: Center(child: circleChild),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: OmiFontSize.t7_16, fontWeight: OmiFontWeight.medium, color: mainTextColor),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: secondTextColor.withValues(alpha: 0.45), size: 26),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whiteCard({required double radius, required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}
