import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blu/mp_bluetooth_connection_helper.dart';
import '../../cache/mp_hive_util.dart';
import '../../http/api/mp_login.dart';
import '../../http/api/mp_user.dart';
import '../../http/schema/mp_user.dart';
import '../../login/home/mp_login_page.dart';
import '../../login/mp_user.dart';
import '../../utils/mp_preferences.dart';
import '../../utils/mp_toast_utils.dart';
import 'mp_account_state.dart';

/// 账户页：拉取用户资料、退出登录。
class MPAccountCubit extends Cubit<MPAccountState> {
  MPAccountCubit() : super(_buildInitialState());

  static const String _defaultDisplayName = 'MemoPin User';
  static const String _defaultDisplayEmail = 'user@memopin.com';

  static MPAccountState _buildInitialState() {
    return MPAccountState(
      profileStatus: MPAccountProfileStatus.loading,
      displayName: _fallbackNameStatic(),
      displayEmail: _defaultDisplayEmail,
    );
  }

  /// 进入页面时拉取用户资料。
  Future<void> loadProfile() async {
    emit(
      state.copyWith(
        profileStatus: MPAccountProfileStatus.loading,
        clearErrorMessage: true,
      ),
    );

    final MPGetUserProfileResponse? response =
        await getUserProfile(MPGetUserProfileRequest());

    if (response == null) {
      _emitProfileFallback(
        profileStatus: MPAccountProfileStatus.error,
        message: 'Failed to load profile',
      );
      return;
    }

    if (response.baseResp.code != 0) {
      _emitProfileFallback(
        profileStatus: MPAccountProfileStatus.error,
        message: response.baseResp.message.isNotEmpty
            ? response.baseResp.message
            : 'Failed to load profile',
      );
      return;
    }

    final String name = response.user.userName.trim();
    final String email = response.user.email.trim();
    MPUser.instance.name = name.isNotEmpty ? name : null;
    MPUser.instance.email = email.isNotEmpty ? email : null;

    emit(
      state.copyWith(
        profileStatus: MPAccountProfileStatus.loaded,
        displayName: name.isNotEmpty ? name : _defaultDisplayName,
        displayEmail: email.isNotEmpty ? email : await _fallbackEmail(),
        clearErrorMessage: true,
      ),
    );
  }

  void _emitProfileFallback({
    required MPAccountProfileStatus profileStatus,
    required String message,
  }) async{
    MPToastUtils.showMessage(message);
    final String email = await _fallbackEmail();
    emit(
      state.copyWith(
        profileStatus: profileStatus,
        displayName: _fallbackName(),
        displayEmail: email,
        errorMessage: message,
      ),
    );
  }

  String _fallbackName() {
    return _fallbackNameStatic();
  }

  Future<String> _fallbackEmail() async {
    return _fallbackEmailStatic();
  }

  static String _fallbackNameStatic() {
    final String? n = MPUser.instance.name?.trim();
    if (n != null && n.isNotEmpty) {
      return n;
    }
    return _defaultDisplayName;
  }

  static Future<String> _fallbackEmailStatic() async {
    final String e = await SharedPreferencesUtil().email ?? '';
    if (e.isNotEmpty) {
      return e;
    }
    return _defaultDisplayEmail;
  }

  /// 调用退出登录接口并清理本地会话，跳转登录页。
  Future<void> signOut(BuildContext context) async {
    if (state.signOutInProgress) {
      return;
    }
    emit(state.copyWith(signOutInProgress: true));

    try {
      await logout();
    } catch (_) {
      // 仍执行本地清理与跳转，避免用户无法退出。
    }

    await SharedPreferencesUtil().setAccessToken(null);
    await SharedPreferencesUtil().setRefreshToken(null);
    await SharedPreferencesUtil().setEmail(null);
    await MPHiveUtil.instance.close();
    await SharedPreferencesUtil().clearTokenExpiresTime();
    await MPBluetoothConnectionHelper.disconnectAppBleForLogout();
    await SharedPreferencesUtil().clearLastConnectedBleDevice();
    MPUser.instance.clear();

    if (!context.mounted) {
      return;
    }
    emit(state.copyWith(signOutInProgress: false));
    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const MPLoginPage()),
      (Route<dynamic> route) => false,
    );
  }
}
