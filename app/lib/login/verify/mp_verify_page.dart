import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../login/legal/mp_legal_document_page.dart';
import '../../utils/mp_toast_utils.dart';
import '../../utils/omi_color_utils.dart';
import '../../utils/omi_font_utils.dart';
import 'mp_verify_cubit.dart';
import 'mp_verify_state.dart';

/// 邮箱验证码页面。
class MPVerifyPage extends StatelessWidget {
  const MPVerifyPage({super.key, required this.email, required this.password});

  /// 待验证邮箱。
  final String email;

  /// 待验证密码。
  final String password;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MPVerifyCubit(),
      child: _MPVerifyScaffold(email: email, password: password),
    );
  }
}

class _MPVerifyScaffold extends StatelessWidget {
  const _MPVerifyScaffold({required this.email, required this.password});

  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _MPVerifyBody(email: email, password: password),
      ),
    );
  }
}

class _MPVerifyBody extends StatefulWidget {
  const _MPVerifyBody({required this.email, required this.password});

  final String email;
  final String password;
  @override
  State<_MPVerifyBody> createState() => _MPVerifyBodyState();
}

class _MPVerifyBodyState extends State<_MPVerifyBody> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MPVerifyCubit, MPVerifyState>(
      listenWhen: (p, c) => p.isPrimaryButtonEnabled != c.isPrimaryButtonEnabled,
      listener: (context, state) {},
      child: BlocBuilder<MPVerifyCubit, MPVerifyState>(
        builder: (context, state) {
          final MPVerifyCubit cubit = context.read<MPVerifyCubit>();
          cubit.setContext(context);
          final String? codeErr = MPVerifyState.normalizeError(state.codeError);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: OmiFontSize.t16_25,
                    fontWeight: OmiFontWeight.bold,
                    color: mainTextColor,
                    height: 1.05,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "We've sent a verification code to",
                  style: TextStyle(
                    fontSize: OmiFontSize.t6_15,
                    color: secondTextColor,
                    height: 1.45,
                    fontWeight: OmiFontWeight.medium,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: OmiFontSize.t11_20,
                    fontWeight: OmiFontWeight.bold,
                    color: mainTextColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(color: lineColor, height: 1),
                const SizedBox(height: 28),
                Text(
                  'Verification Code',
                  style: TextStyle(
                    fontWeight: OmiFontWeight.bold,
                    fontSize: OmiFontSize.t6_15,
                    color: mainTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (String value) => setState(() {
                    _codeController.text = value;
                    cubit.emit(state.copyWith(code: value));
                  }),
                  style: TextStyle(
                    fontSize: OmiFontSize.t8_17,
                    color: mainTextColor,
                    fontWeight: OmiFontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter 4-digit code',
                    hintStyle: TextStyle(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t8_17,
                      fontWeight: OmiFontWeight.medium,
                      letterSpacing: 6,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: blueTextColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                ),
                if (codeErr != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    codeErr,
                    style: TextStyle(fontSize: OmiFontSize.t5_14, color: redColor, fontWeight: OmiFontWeight.regular),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: state.isPrimaryButtonEnabled
                        ? () => cubit.submit(widget.email, widget.password, _codeController.text.trim())
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: state.isPrimaryButtonEnabled ? blueTextColor : const Color(0xFFA1CCFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Verify Code',
                      style: TextStyle(
                        fontSize: OmiFontSize.t8_17,
                        fontWeight: OmiFontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => MPToastUtils.showFeatureComingSoon(message: '重新发送验证码'),
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: "Didn't receive the code? ",
                            style: TextStyle(
                              fontSize: OmiFontSize.t5_14,
                              color: blueTextColor,
                              fontWeight: OmiFontWeight.medium,
                            ),
                          ),
                          TextSpan(
                            text: 'Resend',
                            style: TextStyle(
                              fontSize: OmiFontSize.t5_14,
                              color: blueTextColor,
                              fontWeight: OmiFontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(color: lineColor, height: 1),
                const SizedBox(height: 20),
                _LegalFooter(
                  onTermsTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (_) => const MPLegalDocumentPage(kind: MPLegalDocumentKind.terms)),
                  ),
                  onPrivacyTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const MPLegalDocumentPage(kind: MPLegalDocumentKind.privacy),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
