import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../http/api/mp_user.dart';
import '../../utils/mp_time_utils.dart';
import '../../http/schema/mp_user.dart';
import '../../login/mp_login_util.dart';
import '../../login/mp_user.dart';
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
    emit(state.copyWith(profileStatus: MPAccountProfileStatus.loading, clearErrorMessage: true));

    final MPGetUserProfileResponse? response = await getUserProfile(MPGetUserProfileRequest());

    if (response == null) {
      _emitProfileFallback(profileStatus: MPAccountProfileStatus.error, message: 'Failed to load profile');
      return;
    }

    if (response.baseResp.code != 0) {
      _emitProfileFallback(
        profileStatus: MPAccountProfileStatus.error,
        message: response.baseResp.message.isNotEmpty ? response.baseResp.message : 'Failed to load profile',
      );
      return;
    }

    final String name = response.user.userName.trim();
    final String email = response.user.email.trim();
    await MPUser.instance.setName(name.isNotEmpty ? name : null);
    await MPUser.instance.setEmail(email.isNotEmpty ? email : null);
    await MPUser.instance.setAvatar(response.user.avatar.trim().isNotEmpty ? response.user.avatar.trim() : null);
    await MPUser.instance.setPhone(response.user.phone.trim().isNotEmpty ? response.user.phone.trim() : null);
    await MPUser.instance.setBrithday(response.user.birthday.trim().isNotEmpty ? response.user.birthday.trim() : null);
    final String memberSinceLabel = _memberSinceLabelFromCreateAt(response.user.createAt);
    emit(
      state.copyWith(
        profileStatus: MPAccountProfileStatus.loaded,
        displayName: name.isNotEmpty ? name : _defaultDisplayName,
        displayEmail: email.isNotEmpty ? email : await _fallbackEmail(),
        memberSinceLabel: memberSinceLabel,
        clearErrorMessage: true,
      ),
    );
  }

  /// `Member since January 2024`；无效 [createAt] 返回空字符串。
  static String _memberSinceLabelFromCreateAt(int? createAt) {
    final DateTime? dt = MPTimeUtils.dateTimeFromUnixEpoch(createAt);
    if (dt == null) {
      return '';
    }
    return 'Member since ${DateFormat('MMMM yyyy').format(dt)}';
  }

  void _emitProfileFallback({required MPAccountProfileStatus profileStatus, required String message}) async {
    MPToastUtils.showMessage(message);
    final String email = await _fallbackEmail();
    emit(
      state.copyWith(
        profileStatus: profileStatus,
        displayName: _fallbackName(),
        displayEmail: email,
        memberSinceLabel: '',
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
    final String n = MPUser.instance.name.trim();
    if (n.isNotEmpty) {
      return n;
    }
    return _defaultDisplayName;
  }

  static Future<String> _fallbackEmailStatic() async {
    final String e = MPUser.instance.email;
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
      await MPLoginUtil.signOut(context: context);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(signOutInProgress: false));
      }
    }
  }
}
