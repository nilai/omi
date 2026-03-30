import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omi/login/forget/mp_forget_page.dart';
import 'package:omi/login/home/mp_login_cubit.dart';
import 'package:omi/login/home/mp_login_state.dart';
import 'package:omi/utils/omi_color_utils.dart';

import '../legal/mp_legal_document_page.dart';

/// MemoPin 登录 / 注册页（BlocProvider + [MPLoginCubit]）。
class MPLoginPage extends StatelessWidget {
  const MPLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => MPLoginCubit(), child: const _MPLoginScaffold());
  }
}

class _MPLoginScaffold extends StatelessWidget {
  const _MPLoginScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _MPLoginFormBody()),
    );
  }
}

class _MPLoginFormBody extends StatefulWidget {
  @override
  State<_MPLoginFormBody> createState() => _MPLoginFormBodyState();
}

class _MPLoginFormBodyState extends State<_MPLoginFormBody> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final MPLoginState s = context.read<MPLoginCubit>().state;
    _emailController = TextEditingController(text: s.email);
    _passwordController = TextEditingController(text: s.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MPLoginCubit, MPLoginState>(
      listenWhen: (MPLoginState p, MPLoginState c) => p.mode != c.mode,
      listener: (BuildContext context, MPLoginState state) {
        _emailController.clear();
        _passwordController.clear();
      },
      child: BlocBuilder<MPLoginCubit, MPLoginState>(
        builder: (BuildContext context, MPLoginState state) {
          final MPLoginCubit cubit = context.read<MPLoginCubit>();
          final String? emailErr = MPLoginState.normalizeError(state.emailError);
          final String? passwordErr = MPLoginState.normalizeError(state.passwordError);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                Text(
                  state.mode == MPLoginMode.login ? 'Welcome to MemoPin' : 'Create Account',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: mainTextColor),
                ),
                const SizedBox(height: 8),
                Text(
                  state.mode == MPLoginMode.login
                      ? 'Sign in to continue capturing and organizing your memories.'
                      : 'Start capturing and organizing your memories.',
                  style: const TextStyle(fontSize: 15, color: secondTextColor, height: 1.35),
                ),
                const SizedBox(height: 28),
                _SocialButton(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  icon: FaIcon(FontAwesomeIcons.apple, size: 20, color: Colors.white),
                  label: 'Continue with Apple',
                  onTap: () => _toast(context, 'Continue with Apple'),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  backgroundColor: Colors.white,
                  foregroundColor: mainTextColor,
                  borderColor: borderColor,
                  icon: FaIcon(FontAwesomeIcons.google, size: 18, color: const Color(0xFF4285F4)),
                  label: 'Continue with Google',
                  onTap: () => _toast(context, 'Continue with Google'),
                ),
                const SizedBox(height: 24),
                const _OrDivider(),
                const SizedBox(height: 24),
                const Text(
                  'Email',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: mainTextColor),
                ),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _emailController,
                  hintText: 'your@email.com',
                  prefixIcon: const Icon(Icons.mail_outline, color: secondTextColor),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: cubit.setEmail,
                ),
                if (emailErr != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(emailErr, style: const TextStyle(fontSize: 13, color: redColor)),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Password',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: mainTextColor),
                    ),
                    if (state.mode == MPLoginMode.login) ...<Widget>[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const MPForgetPage()),
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(fontSize: 14, color: blueTextColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _AuthTextField(
                  controller: _passwordController,
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline, color: secondTextColor),
                  obscureText: state.obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: cubit.togglePasswordVisible,
                    icon: Icon(
                      state.obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: secondTextColor,
                    ),
                  ),
                  onChanged: cubit.setPassword,
                ),
                if (passwordErr != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(passwordErr, style: const TextStyle(fontSize: 13, color: redColor)),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: state.isPrimaryButtonEnabled ? () => cubit.submit() : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: state.isPrimaryButtonEnabled ? blueTextColor : const Color(0xFFD1D1D6),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD1D1D6),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      state.mode == MPLoginMode.login ? 'Sign In' : 'Create Account',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: cubit.toggleAuthMode,
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(color: blueTextColor, fontWeight: FontWeight.w600),
                        children: <InlineSpan>[
                          TextSpan(
                            text: state.mode == MPLoginMode.login
                                ? "Don't have an account? "
                                : 'Already have an account? ',
                          ),
                          TextSpan(
                            text: state.mode == MPLoginMode.login ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(color: blueTextColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onTap,
    this.borderColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: foregroundColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: lineColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: TextStyle(fontSize: 14, color: secondTextColor.withValues(alpha: 0.8))),
        ),
        Expanded(child: Divider(color: lineColor, height: 1)),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: mainTextColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: secondTextColor),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blueTextColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
    _termsRecognizer = TapGestureRecognizer()..onTap = () => widget.onTermsTap();
    _privacyRecognizer = TapGestureRecognizer()..onTap = () => widget.onPrivacyTap();
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
        style: const TextStyle(fontSize: 12, color: secondTextColor, height: 1.4),
        children: <InlineSpan>[
          const TextSpan(text: "By continuing, you agree to MemoPin's "),
          TextSpan(
            text: 'Terms of Service',
            style: const TextStyle(color: blueTextColor, fontWeight: FontWeight.w600),
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(color: blueTextColor, fontWeight: FontWeight.w600),
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
