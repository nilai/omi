import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/login/forget/mp_forget_state.dart';

import '../../http/api/mp_login.dart';
import '../../http/schema/mp_login.dart';
import '../../utils/mp_toast_utils.dart';
import 'mp_forget_success_page.dart';

/// 忘记密码页 Cubit：处理邮箱输入与提交校验。
class MPForgetCubit extends Cubit<MPForgetState> {
  MPForgetCubit() : super(const MPForgetState());

  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  /// 更新邮箱输入，并清除历史错误。
  void setEmail(String value) {
    emit(state.copyWith(email: value, emailError: null, isSubmitted: false));
  }

  /// 提交前校验邮箱格式。
  void submit() {
    final String email = state.email.trim();

    String? emailErr;
    if (email.isEmpty) {
      emailErr = 'Please enter a valid email address.';
    }

    if (emailErr != null) {
      emit(state.copyWith(emailError: emailErr, isSubmitted: false));
      return;
    }

    sendCode();
  }

  void sendCode() async {
    final String email = state.email.trim();
    final req = MPSendCodeRequest(email: email);
    final response = await resetSendCode(req);
    if (response != null && response.baseResp.code == 0) {
      Navigator.of(_context!).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => MPForgetSuccessPage(email: email),
        ),
      );
    } else {
      MPToastUtils.showMessage(response?.baseResp.message ?? 'Send code failed');
    }
  }
}
