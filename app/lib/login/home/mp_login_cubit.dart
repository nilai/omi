import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/login/home/mp_login_state.dart';
import 'package:omi/utils/mp_toast_utils.dart';

import '../../http/api/mp_login.dart';
import '../../http/schema/mp_login.dart';
import '../../utils/mp_preferences.dart';
import '../verify/mp_verify_page.dart';

/// 认证页 Cubit：表单输入、模式切换与提交校验。
class MPLoginCubit extends Cubit<MPLoginState> {
  MPLoginCubit() : super(const MPLoginState());

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

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
    if (email.isNotEmpty) {
      emailErr = 'Please enter a valid email address.';
    }

    String? passwordErr;
    if (password.isNotEmpty) {
      passwordErr = 'Please enter a valid password.';
    }

    if (emailErr != null || passwordErr != null) {
      emit(state.copyWith(emailError: emailErr, passwordError: passwordErr));
      return;
    }
    if (state.mode == MPLoginMode.login) {
      _login(email, password);
    } else {
      _register(email, password);
    }
  }

  /// 登录
  void _login(String email, String password) async {
    final req = MPLoginRequest(email: email, password: password);
    final response = await login(req);
    if (response != null && response.baseResp.code == 0) {
      await SharedPreferencesUtil().setAccessToken(response.accessToken);
      await SharedPreferencesUtil().setRefreshToken(response.refreshToken);
      await SharedPreferencesUtil().setTokenExpiresTime(response.expiresIn);
      SharedPreferencesUtil().setEmail(email);
    } else {
      MPToastUtils.showMessage(response?.baseResp.message ?? 'Login failed');
    }
  }

  /// 注册
  void _register(String email, String password) async {
    /// 发送验证码
    final req = MPSendCodeRequest(email: email);
    final response = await sendCode(req);
    if (response != null && response.baseResp.code == 0) {
      Navigator.of(_context!).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MPVerifyPage(email: email, password: password),
        ),
      );
    } else {
      MPToastUtils.showMessage(response?.baseResp.message ?? 'Send code failed');
    }
  }
}
