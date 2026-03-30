import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:omi/login/home/mp_login_page.dart';
import 'package:omi/login/legal/mp_legal_document_page.dart';
import 'package:omi/utils/mp_toast_utils.dart';
import 'package:omi/utils/omi_color_utils.dart';

/// 忘记密码发送成功页。
class MPForgetSuccessPage extends StatelessWidget {
  const MPForgetSuccessPage({
    super.key,
    required this.email,
  });

  /// 发送重置链接的目标邮箱。
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _SuccessIcon(),
                    const SizedBox(height: 24),
                    const Text(
                      'Reset Link Sent!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: mainTextColor,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "We've sent a password reset link to",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: secondTextColor,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: mainTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 15,
                            color: secondTextColor,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          children: <InlineSpan>[
                            const TextSpan(text: "Didn't receive the email? Check your spam folder or "),
                            TextSpan(
                              text: 'try again',
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  MPToastUtils.showFeatureComingSoon(message: '重新发送');
                                },
                              style: const TextStyle(
                                color: blueTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(builder: (_) => const MPLoginPage()),
                            (route) => false,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: blueTextColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Back to Sign In',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: lineColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: _LegalFooter(
                onTermsTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const MPLegalDocumentPage(kind: MPLegalDocumentKind.terms),
                  ),
                ),
                onPrivacyTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const MPLegalDocumentPage(kind: MPLegalDocumentKind.privacy),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      decoration: const BoxDecoration(
        color: Color(0xFF2FCB4D),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.check_rounded,
          size: 56,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LegalFooter extends StatefulWidget {
  const _LegalFooter({
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

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
        style: const TextStyle(
          fontSize: 12,
          color: secondTextColor,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        children: <InlineSpan>[
          const TextSpan(text: "By continuing, you agree to MemoPin's "),
          TextSpan(
            text: 'Terms of Service',
            recognizer: _termsRecognizer,
            style: const TextStyle(color: blueTextColor, fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            recognizer: _privacyRecognizer,
            style: const TextStyle(color: blueTextColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
