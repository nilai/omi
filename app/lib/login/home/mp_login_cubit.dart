import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/login/home/mp_login_state.dart';
import 'package:memo_pin/login/mp_user.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

import '../../app/mp_app_session_bootstrap.dart';
import '../../cache/mp_hive_util.dart';
import '../../http/api/mp_login.dart';
import '../../http/schema/mp_login.dart';
import '../../tab/omi_main_tab_page.dart';
import '../../utils/mp_uuid_util.dart';
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
    emit(state.copyWith(mode: next, emailError: null, passwordError: null, isSubmitting: false));
  }

  /// 提交校验（按钮仅在邮箱、密码非空时可点）。
  Future<void> submit() async {
    if (state.isSubmitting) {
      return;
    }
    final String email = state.email.trim();
    final String password = state.password;

    String? emailErr;
    if (email.isEmpty) {
      emailErr = 'Please enter a valid email address.';
    }

    String? passwordErr;
    if (password.isEmpty) {
      passwordErr = 'Please enter a valid password.';
    }

    if (emailErr != null || passwordErr != null) {
      emit(state.copyWith(emailError: emailErr, passwordError: passwordErr));
      return;
    }
    emit(state.copyWith(isSubmitting: true));
    try {
      if (state.mode == MPLoginMode.login) {
        await _login(email, password);
      } else {
        await _register(email, password);
      }
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isSubmitting: false));
      }
    }
  }

  /// 登录
  Future<void> _login(String email, String password) async {
    final deviceId = await MPUuidUtil.instance.uuid;
    final req = MPLoginRequest(email: email, password: password, deviceId: deviceId);
    final response = await login(req);
    if (response != null && response.baseResp.code == 0) {
      await MPUser.instance.setAccessToken(response.accessToken);
      await MPUser.instance.setUserId(response.userId);
      await MPUser.instance.setRefreshToken(response.refreshToken);
      await MPUser.instance.setTokenExpiresTime(response.expiresIn);
      await MPUser.instance.setEmail(email);
      await MPAppSessionBootstrap.run(fromLoginSuccess: true);
      await Navigator.of(_context!).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => const MainTabPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      MPToastUtils.showMessage(response?.baseResp.message ?? 'Login failed');
    }
  }

  /// 注册
  Future<void> _register(String email, String password) async {
    /// 发送验证码
    final req = MPSendCodeRequest(email: email, password: password);
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
