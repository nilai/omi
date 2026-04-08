import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/login/forget/mp_forget_success_cubit.dart';
import 'package:memo_pin/login/forget/mp_forget_success_state.dart';
import 'package:memo_pin/login/home/mp_login_page.dart';
import 'package:memo_pin/login/legal/mp_legal_document_page.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';

/// 忘记密码发送成功页。
class MPForgetSuccessPage extends StatelessWidget {
  const MPForgetSuccessPage({super.key, required this.email});

  /// 发送重置链接的目标邮箱。
  final String email;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPForgetSuccessCubit>(
      create: (_) => MPForgetSuccessCubit(email: email),
      child: const _MPForgetSuccessView(),
    );
  }
}

class _MPForgetSuccessView extends StatelessWidget {
  const _MPForgetSuccessView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: OmiFontSize.t16_25,
                  fontWeight: OmiFontWeight.bold,
                  color: mainTextColor,
                  height: 1.05,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const Divider(height: 1, color: lineColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints viewportConstraints) {
                    return BlocBuilder<MPForgetSuccessCubit, MPForgetSuccessState>(
                      builder: (BuildContext context, MPForgetSuccessState state) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const _SuccessIcon(),
                                const SizedBox(height: 24),
                                Text(
                                  'Reset Link Sent!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: OmiFontSize.t11_20,
                                    fontWeight: OmiFontWeight.medium,
                                    color: mainTextColor,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "We've sent a password reset link to",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: OmiFontSize.t6_15,
                                    color: secondTextColor,
                                    height: 1.4,
                                    fontWeight: OmiFontWeight.regular,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.email,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: OmiFontSize.t8_17,
                                    color: mainTextColor,
                                    fontWeight: OmiFontWeight.regular,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6FA),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: _ResendHintParagraph(
                                    resendInProgress: state.resendInProgress,
                                    onTryAgain: () => context.read<MPForgetSuccessCubit>().tryResendCode(),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 56,
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute<void>(builder: (_) => const MPLoginPage()),
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: blueTextColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: Text(
                                      'Back to Sign In',
                                      style: TextStyle(
                                        fontSize: OmiFontSize.t7_16,
                                        fontWeight: OmiFontWeight.bold,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1, color: lineColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: _LegalFooter(
                onTermsTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const MPLegalDocumentPage(kind: MPLegalDocumentKind.terms)),
                ),
                onPrivacyTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(builder: (_) => const MPLegalDocumentPage(kind: MPLegalDocumentKind.privacy)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 带可点击「try again」的说明文案；正确 dispose [TapGestureRecognizer]。
class _ResendHintParagraph extends StatefulWidget {
  const _ResendHintParagraph({required this.resendInProgress, required this.onTryAgain});

  final bool resendInProgress;
  final VoidCallback onTryAgain;

  @override
  State<_ResendHintParagraph> createState() => _ResendHintParagraphState();
}

class _ResendHintParagraphState extends State<_ResendHintParagraph> {
  late final TapGestureRecognizer _tryAgainRecognizer;

  @override
  void initState() {
    super.initState();
    _tryAgainRecognizer = TapGestureRecognizer()..onTap = _handleTryAgain;
  }

  @override
  void didUpdateWidget(covariant _ResendHintParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tryAgainRecognizer.onTap = _handleTryAgain;
  }

  void _handleTryAgain() {
    if (widget.resendInProgress) {
      return;
    }
    widget.onTryAgain();
  }

  @override
  void dispose() {
    _tryAgainRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color linkColor = widget.resendInProgress ? secondTextColor.withValues(alpha: 0.45) : blueTextColor;

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: OmiFontSize.t6_15,
          color: secondTextColor,
          height: 1.5,
          fontWeight: OmiFontWeight.medium,
        ),
        children: <InlineSpan>[
          TextSpan(
            text: "Didn't receive the email? Check your spam folder or ",
            style: TextStyle(fontWeight: OmiFontWeight.regular),
          ),
          TextSpan(
            text: 'try again',
            recognizer: _tryAgainRecognizer,
            style: TextStyle(color: linkColor, fontWeight: OmiFontWeight.bold),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(color: Color(0xFF2FCB4D), shape: BoxShape.circle),
      child: const Center(child: Icon(Icons.check_rounded, size: 56, color: Colors.white)),
    );
  }
}

class _LegalFooter extends StatefulWidget {
  const _LegalFooter({required this.onTermsTap, required this.onPrivacyTap});

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_LegalFooter> createState() => _LegalFooterState();
}

class _LegalFooterState extends State<_LegalFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: OmiFontSize.t3_12,
          color: secondTextColor,
          height: 1.5,
          fontWeight: OmiFontWeight.medium,
        ),
        children: <InlineSpan>[
          const TextSpan(text: "By continuing, you agree to MemoPin's "),
          TextSpan(
            text: 'Terms of Service',
            recognizer: _termsRecognizer,
            style: TextStyle(color: blueTextColor, fontWeight: OmiFontWeight.bold),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            recognizer: _privacyRecognizer,
            style: TextStyle(color: blueTextColor, fontWeight: OmiFontWeight.bold),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
