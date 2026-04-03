import 'package:flutter_bloc/flutter_bloc.dart';

import '../../http/api/mp_login.dart';
import '../../http/schema/mp_login.dart';
import '../../utils/mp_toast_utils.dart';
import 'mp_forget_success_state.dart';

/// 忘记密码发送成功页：重新发送重置验证码/链接。
class MPForgetSuccessCubit extends Cubit<MPForgetSuccessState> {
  /// [email] 为当前页展示的收件邮箱，与首次发送一致。
  MPForgetSuccessCubit({required String email})
      : super(MPForgetSuccessState(email: email));

  /// 再次调用重置流程的发送验证码接口（与忘记密码页首次发送相同）。
  Future<void> tryResendCode() async {
    if (state.resendInProgress) {
      return;
    }
    final String trimmed = state.email.trim();
    if (trimmed.isEmpty) {
      MPToastUtils.showMessage('Invalid email');
      return;
    }

    emit(state.copyWith(resendInProgress: true));

    final MPSendCodeRequest req = MPSendCodeRequest(email: trimmed);
    final MPSendCodeResponse? response = await resetSendCode(req);

    if (!isClosed) {
      emit(state.copyWith(resendInProgress: false));
    }

    if (response != null && response.baseResp.code == 0) {
      MPToastUtils.showMessage('Reset link sent again.');
    } else {
      MPToastUtils.showMessage(response?.baseResp.message ?? 'Send code failed');
    }
  }
}
