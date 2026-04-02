import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/login/forget/mp_forget_cubit.dart';
import 'package:omi/login/forget/mp_forget_success_page.dart';
import 'package:omi/login/forget/mp_forget_state.dart';
import 'package:omi/login/legal/mp_legal_document_page.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';

/// 忘记密码页面。
class MPForgetPage extends StatelessWidget {
  const MPForgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MPForgetCubit(),
      child: const _MPForgetScaffold(),
    );
  }
}

class _MPForgetScaffold extends StatelessWidget {
  const _MPForgetScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const SafeArea(child: _MPForgetBody()),
    );
  }
}

class _MPForgetBody extends StatefulWidget {
  const _MPForgetBody();

  @override
  State<_MPForgetBody> createState() => _MPForgetBodyState();
}

class _MPForgetBodyState extends State<_MPForgetBody> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: context.read<MPForgetCubit>().state.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MPForgetCubit, MPForgetState>(
      listenWhen: (previous, current) =>
          previous.isSubmitted != current.isSubmitted && current.isSubmitted,
      listener: (context, state) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => MPForgetSuccessPage(email: state.email.trim()),
          ),
        );
      },
      child: BlocBuilder<MPForgetCubit, MPForgetState>(
        builder: (context, state) {
          final MPForgetCubit cubit = context.read<MPForgetCubit>();
          final String? emailErr = MPForgetState.normalizeError(state.emailError);
          cubit.setContext(context);
          
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
                  'Reset Password',
                  style: TextStyle(
                    fontSize: OmiFontSize.t16_25,
                    color: mainTextColor,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter your email and we'll send you a link to\nreset your password.",
                  style: TextStyle(
                    fontSize: OmiFontSize.t6_15,
                    color: secondTextColor,
                    height: 1.45,
                    fontWeight: OmiFontWeight.medium,
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(color: lineColor, height: 1),
                const SizedBox(height: 28),
                Text(
                  'Email',
                  style: TextStyle(
                    fontWeight: OmiFontWeight.bold,
                    fontSize: OmiFontSize.t6_15,
                    color: mainTextColor,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: cubit.setEmail,
                  style: TextStyle(
                    fontSize: OmiFontSize.t6_15,
                    color: mainTextColor,
                    fontWeight: OmiFontWeight.medium,
                  ),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: TextStyle(
                      color: secondTextColor,
                      fontSize: OmiFontSize.t6_15,
                      fontWeight: OmiFontWeight.medium,
                    ),
                    prefixIcon: const Icon(Icons.mail_outline, color: secondTextColor, size: 30),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
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
                if (emailErr != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    emailErr,
                    style: TextStyle(
                      fontSize: OmiFontSize.t5_14,
                      color: redColor,
                      fontWeight: OmiFontWeight.regular,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: state.isPrimaryButtonEnabled ? cubit.submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: state.isPrimaryButtonEnabled ? blueTextColor : const Color(0xFFD1D1D6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontSize: OmiFontSize.t8_17,
                        fontWeight: OmiFontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(color: lineColor, height: 1),
                const SizedBox(height: 20),
                _LegalFooter(
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
              ],
            ),
          );
        },
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
