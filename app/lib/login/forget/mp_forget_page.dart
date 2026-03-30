import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/login/forget/mp_forget_cubit.dart';
import 'package:omi/login/forget/mp_forget_success_page.dart';
import 'package:omi/login/forget/mp_forget_state.dart';
import 'package:omi/login/legal/mp_legal_document_page.dart';
import 'package:omi/utils/omi_color_utils.dart';

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
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: mainTextColor,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Enter your email and we'll send you a link to\nreset your password.",
                  style: TextStyle(
                    fontSize: 17,
                    color: secondTextColor,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(color: lineColor, height: 1),
                const SizedBox(height: 28),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 31,
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
                  style: const TextStyle(
                    fontSize: 15,
                    color: mainTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: const TextStyle(
                      color: secondTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
                  Text(emailErr, style: const TextStyle(fontSize: 14, color: redColor)),
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
                    child: const Text(
                      'Send Reset Link',
                      style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: -0.4),
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
