import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/http/schema/mp_login.dart';
import 'package:memo_pin/login/mp_user.dart';
import 'package:memo_pin/login/verify/mp_verify_state.dart';

import '../../app/mp_app_session_bootstrap.dart';
import '../../cache/mp_hive_util.dart';
import '../../http/api/mp_login.dart';
import '../../tab/omi_main_tab_page.dart';
import '../../utils/mp_toast_utils.dart';

/// 验证码页面 Cubit：输入管理与提交校验。
class MPVerifyCubit extends Cubit<MPVerifyState> {
  MPVerifyCubit() : super(const MPVerifyState());

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  /// 重新发送邮箱验证码；仅调 [sendCode]，**不**进行页面跳转。
  Future<void> resendVerificationCode(String email) async {
    if (state.isResendInProgress) {
      return;
    }
    final String trimmed = email.trim();
    if (trimmed.isEmpty) {
      MPToastUtils.showMessage('Please enter a valid email address.');
      return;
    }
    emit(state.copyWith(isResendInProgress: true));
    try {
      final MPSendCodeRequest req = MPSendCodeRequest(email: trimmed);
      final response = await sendCode(req);
      if (response != null && response.baseResp.code == 0) {
        MPToastUtils.showMessage('Verification code sent');
      } else {
        MPToastUtils.showMessage(response?.baseResp.message ?? 'Send code failed');
      }
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isResendInProgress: false));
      }
    }
  }

  /// 提交校验。
  void submit(String email, String password, String code) async {
    String? error;
    if (code.isEmpty) {
      error = 'Please enter the verification code.';
    }
    if (error != null) {
      emit(state.copyWith(codeError: error));
      return;
    }
    final req = MPRegisterRequest(email: email, code: code, password: password);
    final response = await register(req);
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
      MPToastUtils.showMessage(response?.baseResp.message ?? 'Register failed');
    }
  }
}
