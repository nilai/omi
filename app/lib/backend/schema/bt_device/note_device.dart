/// Note 设备数据模型
/// 包含设备信息、存储状态、文件信息等

class NoteDevice {
  final String id;
  final String name;
  final String? snid;
  final bool isBound;
  final int batteryLevel;
  final String firmwareVersion;
  final NoteStorageInfo storage;

  NoteDevice({
    required this.id,
    required this.name,
    this.snid,
    this.isBound = false,
    this.batteryLevel = 0,
    this.firmwareVersion = 'Unknown',
    required this.storage,
  });

  NoteDevice copyWith({
    String? id,
    String? name,
    String? snid,
    bool? isBound,
    int? batteryLevel,
    String? firmwareVersion,
    NoteStorageInfo? storage,
  }) {
    return NoteDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      snid: snid ?? this.snid,
      isBound: isBound ?? this.isBound,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      storage: storage ?? this.storage,
    );
  }
}

/// 存储信息模型
class NoteStorageInfo {
  final int usedKB;
  final int totalKB;

  NoteStorageInfo({
    required this.usedKB,
    required this.totalKB,
  });

  /// 总容量(MB)
  int get totalMB => (totalKB / 1024).round();

  /// 已用容量(MB)
  double get usedMB => usedKB / 1024;

  /// 可用容量(KB)
  int get availableKB => totalKB - usedKB;

  /// 使用百分比 (0.0 - 1.0)
  double get usedPercentage => totalKB > 0 ? usedKB / totalKB : 0.0;

  /// 使用百分比 (0 - 100)
  int get usedPercentInt => (usedPercentage * 100).round();

  /// 格式化的存储信息字符串
  String get formattedString => '$usedKB KB已用 / $totalMB MB';

  NoteStorageInfo copyWith({
    int? usedKB,
    int? totalKB,
  }) {
    return NoteStorageInfo(
      usedKB: usedKB ?? this.usedKB,
      totalKB: totalKB ?? this.totalKB,
    );
  }
}

/// 文件信息模型
class NoteFileInfo {
  final int index;
  final String name;
  final int durationSeconds;

  NoteFileInfo({
    required this.index,
    required this.name,
    required this.durationSeconds,
  });

  /// 格式化的时长字符串 (HH:MM:SS)
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// 简短时长字符串 (MM:SS 或 HH:MM:SS)
  String get shortDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  NoteFileInfo copyWith({
    int? index,
    String? name,
    int? durationSeconds,
  }) {
    return NoteFileInfo(
      index: index ?? this.index,
      name: name ?? this.name,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}
