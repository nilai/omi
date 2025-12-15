// BLE Log Entry Model
// Used to track sent and received BLE commands for debugging

/// Direction of the BLE data
enum BleLogDirection { sent, received }

/// A single log entry representing BLE data transfer
class BleLogEntry {
  final DateTime timestamp;
  final BleLogDirection direction;
  final List<int> data;
  final String? commandName;

  BleLogEntry({
    required this.timestamp,
    required this.direction,
    required this.data,
    this.commandName,
  });

  /// Format data as uppercase hex string with spaces
  String get hexString => data
      .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  /// Format timestamp as HH:MM:SS.mmm
  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}.'
      '${timestamp.millisecond.toString().padLeft(3, '0')}';

  /// Whether this is a sent command
  bool get isSent => direction == BleLogDirection.sent;

  /// Whether this is a received response
  bool get isReceived => direction == BleLogDirection.received;
}
