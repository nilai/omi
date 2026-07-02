import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/login/forget/mp_forget_page.dart';
import 'package:memo_pin/login/home/mp_login_cubit.dart';
import 'package:memo_pin/login/home/mp_login_state.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';

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

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void initState() {
    super.initState();
    final MPLoginState s = context.read<MPLoginCubit>().state;
    _emailController = TextEditingController(text: s.email);
    _passwordController = TextEditingController(text: s.password);
  }

  @override
  void dispose() {
    _dismissKeyboard();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _dismissKeyboard();
    super.deactivate();
  }

  Future<void> _openForgetPasswordPage() async {
    _dismissKeyboard();
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const MPForgetPage()));
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dismissKeyboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MPLoginCubit, MPLoginState>(
      listenWhen: (MPLoginState p, MPLoginState c) => p.mode != c.mode,
      listener: (BuildContext context, MPLoginState state) {
        // _emailController.clear();
        // _passwordController.clear();
      },
      child: BlocBuilder<MPLoginCubit, MPLoginState>(
        builder: (BuildContext context, MPLoginState state) {
          final MPLoginCubit cubit = context.read<MPLoginCubit>();
          cubit.setContext(context);
          final String? emailErr = MPLoginState.normalizeError(state.emailError);
          final String? passwordErr = MPLoginState.normalizeError(state.passwordError);

          /// 使用 [HitTestBehavior.deferToChild]，避免点击「邮箱 → 密码」等输入框切换时
          /// 父级抢先 `unfocus` 导致键盘先收起再弹起。
          return GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: _dismissKeyboard,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 8),
                  Text(
                    state.mode == MPLoginMode.login ? 'Welcome to MemoPin' : 'Create Account',
                    style: TextStyle(
                      fontSize: OmiFontSize.t16_25,
                      fontWeight: OmiFontWeight.bold,
                      color: mainTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.mode == MPLoginMode.login
                        ? 'Sign in to continue capturing and organizing your memories.'
                        : 'Start capturing and organizing your memories.',
                    style: TextStyle(
                      fontSize: OmiFontSize.t6_15,
                      color: secondTextColor,
                      height: 1.35,
                      fontWeight: OmiFontWeight.regular,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Email',
                    style: TextStyle(color: mainTextColor, fontSize: OmiFontSize.t6_15, fontWeight: OmiFontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _AuthTextField(
                    controller: _emailController,
                    hintText: 'your@email.com',
                    prefixIcon: const Icon(Icons.mail_outline, color: secondTextColor, size: 20),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    onChanged: cubit.setEmail,
                  ),
                  if (emailErr != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      emailErr,
                      style: TextStyle(fontSize: OmiFontSize.t4_13, color: redColor, fontWeight: OmiFontWeight.regular),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Password',
                        style: TextStyle(
                          color: mainTextColor,
                          fontSize: OmiFontSize.t6_15,
                          fontWeight: OmiFontWeight.bold,
                        ),
                      ),
                      if (state.mode == MPLoginMode.login) ...<Widget>[
                        const Spacer(),
                        GestureDetector(
                          onTap: _openForgetPasswordPage,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: blueTextColor,
                              fontSize: OmiFontSize.t5_14,
                              fontWeight: OmiFontWeight.medium,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AuthTextField(
                    controller: _passwordController,
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline, color: secondTextColor, size: 20),
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
                    Text(
                      passwordErr,
                      style: TextStyle(fontSize: OmiFontSize.t4_13, color: redColor, fontWeight: OmiFontWeight.regular),
                    ),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (state.isSubmitting) ...<Widget>[
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            state.mode == MPLoginMode.login ? 'Sign In' : 'Create Account',
                            style: TextStyle(fontSize: OmiFontSize.t8_17, fontWeight: OmiFontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: cubit.toggleAuthMode,
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(color: blueTextColor, fontWeight: OmiFontWeight.bold),
                          children: <InlineSpan>[
                            TextSpan(
                              text: state.mode == MPLoginMode.login
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: TextStyle(fontWeight: OmiFontWeight.medium),
                            ),
                            TextSpan(
                              text: state.mode == MPLoginMode.login ? 'Sign Up' : 'Sign In',
                              style: TextStyle(color: blueTextColor, fontWeight: OmiFontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
            ),
          );
        },
      ),
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
      style: TextStyle(fontSize: OmiFontSize.t7_16, color: mainTextColor, fontWeight: OmiFontWeight.regular),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: secondTextColor, fontSize: OmiFontSize.t7_16, fontWeight: OmiFontWeight.regular),
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
        style: TextStyle(
          fontSize: OmiFontSize.t3_12,
          color: secondTextColor,
          height: 1.4,
          fontWeight: OmiFontWeight.regular,
        ),
        children: <InlineSpan>[
          const TextSpan(text: "By continuing, you agree to MemoPin's "),
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(color: blueTextColor, fontWeight: OmiFontWeight.bold),
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(color: blueTextColor, fontWeight: OmiFontWeight.bold),
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
