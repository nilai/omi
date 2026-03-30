import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/login/home/mp_login_state.dart';

/// 认证页 Cubit：表单输入、模式切换与提交校验。
class MPLoginCubit extends Cubit<MPLoginState> {
  MPLoginCubit() : super(const MPLoginState());

  /// 更新邮箱；编辑时清除邮箱错误（空输入时错误保持为 `null`）。
  void setEmail(String value) {
    emit(state.copyWith(email: value, emailError: null));
  }

  /// 更新密码；编辑时清除密码错误。
  void setPassword(String value) {
    emit(state.copyWith(password: value, passwordError: null));
  }

  void togglePasswordVisible() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  /// 登录 ↔ 注册：清空输入与错误。
  void toggleAuthMode() {
    final MPLoginMode next = state.mode == MPLoginMode.login ? MPLoginMode.signup : MPLoginMode.login;
    emit(MPLoginState(mode: next, obscurePassword: state.obscurePassword));
  }

  /// 提交校验（按钮仅在邮箱、密码非空时可点）。
  void submit() {
    final String email = state.email.trim();
    final String password = state.password;

    String? emailErr;
    if (email.isNotEmpty && !_isValidEmail(email)) {
      emailErr = 'Please enter a valid email address.';
    }

    String? passwordErr;
    if (password.isNotEmpty && !_isValidPassword(password)) {
      passwordErr = 'Use at least 12 characters, including letters, numbers, and symbols.';
    }

    emit(state.copyWith(emailError: emailErr, passwordError: passwordErr));
  }

  static bool _isValidEmail(String email) {
    final RegExp re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(email);
  }

  static bool _isValidPassword(String password) {
    if (password.length < 12) return false;
    final bool hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final bool hasDigit = RegExp(r'\d').hasMatch(password);
    final bool hasSymbol = RegExp(r'[^\w\s]').hasMatch(password);
    return hasLetter && hasDigit && hasSymbol;
  }
}
