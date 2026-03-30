import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/login/verify/mp_verify_state.dart';

/// 验证码页面 Cubit：输入管理与提交校验。
class MPVerifyCubit extends Cubit<MPVerifyState> {
  MPVerifyCubit() : super(const MPVerifyState());

  /// 更新验证码，只保留数字且最大 4 位。
  void setCode(String value) {
    final String next = value.replaceAll(RegExp(r'[^0-9]'), '');
    final String trimmed = next.length > 4 ? next.substring(0, 4) : next;
    emit(state.copyWith(code: trimmed, codeError: null, isSubmitted: false));
  }

  /// 提交校验。
  void submit() {
    String? error;
    if (state.code.length != 4) {
      error = 'Please enter a valid 4-digit code.';
    }
    emit(state.copyWith(codeError: error, isSubmitted: error == null));
  }
}
