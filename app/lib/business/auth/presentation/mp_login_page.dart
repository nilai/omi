import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icon, Icons;
import 'package:omi/business/auth/presentation/mp_legal_document_page.dart';
import 'package:omi/business/shared/state/mp_business_controller.dart';

/// 与 React `LoginModal` 对齐：Apple/Google、邮箱密码、注册切换、忘记密码、条款与隐私。
class MPLoginPage extends StatefulWidget {
  const MPLoginPage({
    super.key,
    required this.controller,
    this.initialSignUp = false,
  });

  final MPBusinessController controller;

  /// 对应 React `initialMode === 'signup'`
  final bool initialSignUp;

  @override
  State<MPLoginPage> createState() => _MPLoginPageState();
}

class _MPLoginPageState extends State<MPLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();

  bool _isSignUp = false;
  bool _isForgotPassword = false;
  bool _resetEmailSent = false;
  bool _showPassword = false;
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  void _handleBackToLogin() {
    setState(() {
      _isForgotPassword = false;
      _resetEmailSent = false;
      _resetEmailController.clear();
      _error = '';
    });
  }

  Future<void> _submitEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = '请输入邮箱和密码');
      return;
    }
    setState(() {
      _error = '';
      _isLoading = true;
    });
    try {
      await widget.controller.loginWithEmailPassword(
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      setState(() => _error = 'Invalid email or password');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitForgotPassword() async {
    final email = _resetEmailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '请输入邮箱');
      return;
    }
    setState(() {
      _error = '';
      _isLoading = true;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) {
        return;
      }
      setState(() {
        _resetEmailSent = true;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = '发送失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  Future<void> _onProvider(String provider) async {
    setState(() {
      _error = '';
      _isLoading = true;
    });
    try {
      await widget.controller.loginWithProvider(provider);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      setState(
        () => _error =
            '无法使用 ${provider == 'apple' ? 'Apple' : 'Google'} 登录',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _headerTitle() {
    if (_isForgotPassword) {
      return _resetEmailSent ? 'Check Your Email' : 'Reset Password';
    }
    return _isSignUp ? 'Create Account' : 'Welcome to MemoPin';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: _isForgotPassword && !_resetEmailSent
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isLoading ? null : _handleBackToLogin,
                child: const Icon(CupertinoIcons.back),
              )
            : null,
        middle: Text(_headerTitle()),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (!_isForgotPassword) ...[
              if (!_isSignUp)
                const Text(
                  'Sign in to continue capturing and organizing your memories.',
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.systemGrey,
                    height: 1.35,
                  ),
                ),
              if (_isSignUp)
                const Text(
                  'Start capturing and organizing your memories.',
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.systemGrey,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 20),
              _buildSocialButtons(),
              const SizedBox(height: 20),
              _buildOrDivider(),
              const SizedBox(height: 20),
              _buildEmailForm(),
              const SizedBox(height: 16),
              _buildToggleSignMode(),
            ] else if (!_resetEmailSent) ...[
              const Text(
                'Enter your email and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.systemGrey,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _buildResetForm(),
            ] else ...[
              _buildResetSuccess(),
            ],
            const SizedBox(height: 24),
            _buildFooterLegal(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
          onPressed: _isLoading ? null : () => _onProvider('apple'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apple, color: CupertinoColors.white, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Continue with Apple',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          onPressed: _isLoading ? null : () => _onProvider('google'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA), width: 2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleMark(),
                const SizedBox(width: 10),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMark() {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4285F4),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0x1A000000))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0x1A000000))),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          placeholder: 'your@email.com',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              CupertinoIcons.mail,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (!_isSignUp)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                          _isForgotPassword = true;
                          _error = '';
                        }),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          placeholder: 'Enter your password',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              CupertinoIcons.lock,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ),
          suffix: CupertinoButton(
            padding: const EdgeInsets.only(right: 4),
            minimumSize: Size.zero,
            onPressed: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1AFF3B30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33FF3B30)),
            ),
            child: Text(
              _error,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        CupertinoButton.filled(
          onPressed: _isLoading ? null : _submitEmailLogin,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: _isLoading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(_isSignUp ? 'Create Account' : 'Sign In'),
        ),
      ],
    );
  }

  Widget _buildToggleSignMode() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isLoading
          ? null
          : () => setState(() {
                _isSignUp = !_isSignUp;
                _error = '';
              }),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 15, color: CupertinoColors.activeBlue),
          children: [
            TextSpan(
              text: _isSignUp
                  ? 'Already have an account? '
                  : 'Don\'t have an account? ',
            ),
            TextSpan(
              text: _isSignUp ? 'Sign In' : 'Sign Up',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _resetEmailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          placeholder: 'your@email.com',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(
              CupertinoIcons.mail,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _error,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.destructiveRed,
            ),
          ),
        ],
        const SizedBox(height: 16),
        CupertinoButton.filled(
          onPressed: _isLoading ? null : _submitForgotPassword,
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: _isLoading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }

  Widget _buildResetSuccess() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF34C759), Color(0xFF28A745)],
            ),
          ),
          child: const Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: CupertinoColors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Reset Link Sent!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.systemGrey,
              height: 1.35,
            ),
            children: [
              const TextSpan(text: 'We\'ve sent a password reset link to\n'),
              TextSpan(
                text: _resetEmailController.text.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
                height: 1.35,
              ),
              children: [
                const TextSpan(text: 'Didn\'t receive the email? Check spam or '),
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _resetEmailSent = false;
                      _error = '';
                    }),
                    child: const Text(
                      'try again',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        CupertinoButton.filled(
          onPressed: _handleBackToLogin,
          borderRadius: BorderRadius.circular(14),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }

  Widget _buildFooterLegal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x0F000000)),
        ),
        color: Color(0xFFF9F9F9),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.systemGrey,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: 'By continuing, you agree to MemoPin\'s '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const MPLegalDocumentPage(
                        kind: MPLegalDocumentKind.terms,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const TextSpan(text: ' and '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const MPLegalDocumentPage(
                        kind: MPLegalDocumentKind.privacy,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
