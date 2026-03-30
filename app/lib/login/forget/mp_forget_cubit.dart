import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/login/forget/mp_forget_state.dart';

/// 忘记密码页 Cubit：处理邮箱输入与提交校验。
class MPForgetCubit extends Cubit<MPForgetState> {
  MPForgetCubit() : super(const MPForgetState());

  /// 更新邮箱输入，并清除历史错误。
  void setEmail(String value) {
    emit(state.copyWith(email: value, emailError: null, isSubmitted: false));
  }

  /// 提交前校验邮箱格式。
  void submit() {
    final String email = state.email.trim();

    String? emailErr;
    if (!_isValidEmail(email)) {
      emailErr = 'Please enter a valid email address.';
    }

    emit(
      state.copyWith(
        emailError: emailErr,
        isSubmitted: emailErr == null,
      ),
    );
  }

  static bool _isValidEmail(String email) {
    final RegExp re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(email);
  }
}
