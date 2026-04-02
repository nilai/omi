import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/http/schema/mp_login.dart';
import 'package:omi/login/verify/mp_verify_state.dart';

import '../../http/api/mp_login.dart';
import '../../tab/omi_main_tab_page.dart';
import '../../utils/mp_preferences.dart';
import '../../utils/mp_toast_utils.dart';

/// 验证码页面 Cubit：输入管理与提交校验。
class MPVerifyCubit extends Cubit<MPVerifyState> {
  MPVerifyCubit() : super(const MPVerifyState());

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
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
      await SharedPreferencesUtil().setAccessToken(response.accessToken);
      await SharedPreferencesUtil().setRefreshToken(response.refreshToken);
      await SharedPreferencesUtil().setTokenExpiresTime(response.expiresIn);
      SharedPreferencesUtil().setEmail(email);
      await Navigator.of(_context!).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => const MainTabPage()),
        (Route<dynamic> route) => false,
      );
    }else {
      MPToastUtils.showMessage(response?.baseResp.message ?? 'Register failed');
    }
  }
}
