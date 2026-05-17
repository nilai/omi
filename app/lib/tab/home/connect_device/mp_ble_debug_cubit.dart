import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/blu/mp_ble_connection_helper.dart';
import 'package:memo_pin/blu/mp_ble_file_util.dart';
import 'package:memo_pin/blu/mp_ble_transport.dart';
import 'package:memo_pin/blu/note_device.dart';
import 'package:memo_pin/utils/mp_toast_utils.dart';

/// BLE 调试页加载阶段。
enum MPBleDebugLoadPhase {
  initial,
  loading,
  loaded,
  disconnected,
  error,
}

/// BLE 调试页状态。
class MPBleDebugState {
  /// 创建状态。
  const MPBleDebugState({
    this.phase = MPBleDebugLoadPhase.initial,
    this.files = const <NoteFileInfo>[],
    this.deletingFileNames = const <String>{},
    this.isDeletingAll = false,
    this.errorMessage,
  });

  final MPBleDebugLoadPhase phase;
  final List<NoteFileInfo> files;
  final Set<String> deletingFileNames;
  final bool isDeletingAll;
  final String? errorMessage;

  bool get isBusy => isDeletingAll || deletingFileNames.isNotEmpty;

  MPBleDebugState copyWith({
    MPBleDebugLoadPhase? phase,
    List<NoteFileInfo>? files,
    Set<String>? deletingFileNames,
    bool? isDeletingAll,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return MPBleDebugState(
      phase: phase ?? this.phase,
      files: files ?? this.files,
      deletingFileNames: deletingFileNames ?? this.deletingFileNames,
      isDeletingAll: isDeletingAll ?? this.isDeletingAll,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// BLE 设备文件调试 Cubit。
class MPBleDebugCubit extends Cubit<MPBleDebugState> {
  MPBleDebugCubit() : super(const MPBleDebugState());

  /// 进入页面后拉取设备文件列表。
  Future<void> initData() => loadFiles();

  /// 重新拉取文件列表。
  Future<void> loadFiles() async {
    emit(
      state.copyWith(
        phase: MPBleDebugLoadPhase.loading,
        clearErrorMessage: true,
      ),
    );

    final BleTransport? transport = await _resolveConnectedTransport();
    if (transport == null) {
      emit(
        state.copyWith(
          phase: MPBleDebugLoadPhase.disconnected,
          files: const <NoteFileInfo>[],
        ),
      );
      return;
    }

    try {
      final List<NoteFileInfo> list = await MPBleConnectionHelper.fetchMemoPinFileList(transport);
      emit(
        state.copyWith(
          phase: MPBleDebugLoadPhase.loaded,
          files: list,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          phase: MPBleDebugLoadPhase.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// 从蓝牙设备删除单个文件。
  Future<void> deleteFile(String fileName) async {
    if (state.deletingFileNames.contains(fileName) || state.isDeletingAll) {
      return;
    }

    final BleTransport? transport = await _resolveConnectedTransport();
    if (transport == null) {
      MPToastUtils.showMessage('Device not connected');
      return;
    }

    emit(
      state.copyWith(
        deletingFileNames: <String>{...state.deletingFileNames, fileName},
      ),
    );

    final bool ok = await MPBleFileUtil.deleteDeviceRecordingFile(transport, fileName);
    if (isClosed) {
      return;
    }

    final Set<String> nextDeleting = <String>{...state.deletingFileNames}..remove(fileName);
    if (ok) {
      emit(
        state.copyWith(
          deletingFileNames: nextDeleting,
          files: state.files.where((NoteFileInfo f) => f.name != fileName).toList(growable: false),
        ),
      );
      MPToastUtils.showMessage('Deleted: $fileName');
    } else {
      emit(state.copyWith(deletingFileNames: nextDeleting));
      MPToastUtils.showMessage('Failed to delete: $fileName');
    }
  }

  /// 删除设备上全部文件。
  Future<void> deleteAllFiles() async {
    if (state.isBusy || state.files.isEmpty) {
      return;
    }

    final BleTransport? transport = await _resolveConnectedTransport();
    if (transport == null) {
      MPToastUtils.showMessage('Device not connected');
      return;
    }

    emit(state.copyWith(isDeletingAll: true));

    final List<NoteFileInfo> snapshot = List<NoteFileInfo>.from(state.files);
    int successCount = 0;
    for (final NoteFileInfo file in snapshot) {
      if (isClosed) {
        return;
      }
      final bool ok = await MPBleFileUtil.deleteDeviceRecordingFile(transport, file.name);
      if (ok) {
        successCount++;
      }
    }

    if (isClosed) {
      return;
    }

    await loadFiles();
    if (isClosed) {
      return;
    }

    emit(state.copyWith(isDeletingAll: false));
    MPToastUtils.showMessage('Deleted $successCount / ${snapshot.length} files');
  }

  Future<BleTransport?> _resolveConnectedTransport() async {
    if (!await MPBleConnectionHelper.ensureBackgroundTransportReady()) {
      return null;
    }
    return MPBleConnectionHelper.activeBleTransport;
  }
}
