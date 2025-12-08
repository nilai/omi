// Note BLE Debug Provider
// Manages BLE debug state: log entries, drawer visibility, command execution

import 'dart:async';
import 'package:omi/pages/note_debug/models/ble_log_entry.dart';
import 'package:omi/services/devices/note_commands.dart';
import 'package:omi/services/devices/note_connection.dart';
import 'base_provider.dart';

/// Provider for BLE debug functionality
class NoteBleDebugProvider extends BaseProvider {
  /// Device connection reference
  NoteDeviceConnection? _connection;

  /// Response stream subscription
  StreamSubscription<List<int>>? _responseSubscription;

  /// Log entries list (newest first)
  final List<BleLogEntry> _logEntries = [];

  /// Maximum log entries to keep
  static const int _maxLogEntries = 500;

  /// Drawer visibility state
  bool _isDrawerOpen = false;

  /// Last error message
  String? _lastError;

  /// Whether a command is being executed
  bool _isExecuting = false;

  // ============ Getters ============

  /// Get log entries (unmodifiable)
  List<BleLogEntry> get logEntries => List.unmodifiable(_logEntries);

  /// Whether the drawer is open
  bool get isDrawerOpen => _isDrawerOpen;

  /// Last error message
  String? get lastError => _lastError;

  /// Whether a command is being executed
  bool get isExecuting => _isExecuting;

  /// Whether connected to a device
  bool get isConnected => _connection != null;

  // ============ Connection Management ============

  /// Set the device connection
  void setConnection(NoteDeviceConnection? connection) {
    _connection = connection;
    _setupResponseListener();
    notifyListeners();
  }

  /// Setup response stream listener
  void _setupResponseListener() {
    _responseSubscription?.cancel();
    if (_connection != null) {
      _responseSubscription = _connection!.bleTransport.responseStream.listen(
        (data) => _addLogEntry(BleLogDirection.received, data),
      );
    }
  }

  // ============ Log Management ============

  /// Add a log entry
  void _addLogEntry(BleLogDirection direction, List<int> data, {String? name}) {
    _logEntries.insert(
      0,
      BleLogEntry(
        timestamp: DateTime.now(),
        direction: direction,
        data: List<int>.from(data),
        commandName: name,
      ),
    );

    // Keep max entries
    if (_logEntries.length > _maxLogEntries) {
      _logEntries.removeLast();
    }

    notifyListeners();
  }

  /// Clear all log entries
  void clearLogs() {
    _logEntries.clear();
    notifyListeners();
  }

  // ============ Drawer Control ============

  /// Toggle drawer visibility
  void toggleDrawer() {
    _isDrawerOpen = !_isDrawerOpen;
    notifyListeners();
  }

  /// Open the drawer
  void openDrawer() {
    _isDrawerOpen = true;
    notifyListeners();
  }

  /// Close the drawer
  void closeDrawer() {
    _isDrawerOpen = false;
    notifyListeners();
  }

  // ============ Command Execution ============

  /// Execute a command and log it
  Future<void> executeCommand(List<int> command, String commandName) async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isExecuting = true;
    _lastError = null;
    notifyListeners();

    try {
      // Log the sent command
      _addLogEntry(BleLogDirection.sent, command, name: commandName);

      // Send command and wait for response
      await _connection!.sendCommandWithResponse(command);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  // ============ Recording Commands ============

  /// Send start recording command (0x01)
  Future<void> sendStartRecording() async {
    await executeCommand([NoteCommands.startRecording], 'Start Recording');
  }

  /// Send stop recording command (0x02)
  Future<void> sendStopRecording() async {
    await executeCommand([NoteCommands.stopRecording], 'Stop Recording');
  }

  /// Send set recording mode command (0x0D + mode)
  Future<void> sendSetRecordingMode(NoteRecordingMode mode) async {
    await executeCommand(
      [NoteCommands.setRecordingMode, mode.value],
      'Set Mode: ${mode.description}',
    );
  }

  // ============ Device Info Commands ============

  /// Send query battery command (0xE1)
  Future<void> sendQueryBattery() async {
    await executeCommand([NoteCommands.queryBattery], 'Query Battery');
  }

  /// Send query version command (0xE3)
  Future<void> sendQueryVersion() async {
    await executeCommand([NoteCommands.queryVersion], 'Query Version');
  }

  /// Send query storage command (0xE8)
  Future<void> sendQueryStorage() async {
    await executeCommand([NoteCommands.queryStorage], 'Query Storage');
  }

  // ============ File Management Commands ============

  /// Send get file list command (0x03)
  Future<void> sendGetFileList() async {
    await executeCommand([NoteCommands.getFileList], 'Get File List');
  }

  // ============ Device Control Commands ============

  /// Send sync RTC command (0xE5 + timestamp)
  Future<void> sendSyncRTC() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await executeCommand(
      [
        NoteCommands.syncRTC,
        (timestamp >> 24) & 0xFF,
        (timestamp >> 16) & 0xFF,
        (timestamp >> 8) & 0xFF,
        timestamp & 0xFF,
      ],
      'Sync RTC',
    );
  }

  /// Send bind device command (0x0B 0x01)
  Future<void> sendBindDevice() async {
    await executeCommand([NoteCommands.bindDevice, 0x01], 'Bind Device');
  }

  /// Send unbind device command (0x0B 0x00)
  Future<void> sendUnbindDevice() async {
    await executeCommand([NoteCommands.bindDevice, 0x00], 'Unbind Device');
  }

  /// Send USB mode command (0xE4 + enabled)
  Future<void> sendSetUsbMode(bool enabled) async {
    await executeCommand(
      [NoteCommands.usbMode, enabled ? 0x01 : 0x00],
      'USB Mode: ${enabled ? "ON" : "OFF"}',
    );
  }

  /// Send reboot command (0x09)
  Future<void> sendReboot() async {
    await executeCommand([NoteCommands.reboot], 'Reboot');
  }

  /// Send factory reset command (0xE9 + param)
  Future<void> sendFactoryReset(bool keepRecordings) async {
    await executeCommand(
      [NoteCommands.factoryReset, keepRecordings ? 0x00 : 0xFF],
      'Factory Reset (keep=$keepRecordings)',
    );
  }

  // ============ OTA Commands ============

  /// Send enter OTA command (0xE6 + module)
  Future<void> sendOtaEnter(NoteOtaModule module) async {
    await executeCommand(
      [NoteCommands.otaEnter, module.value],
      'Enter OTA: ${module.moduleName}',
    );
  }

  // ============ Custom Command ============

  /// Send custom hex command
  Future<void> sendCustomCommand(String hexString) async {
    try {
      final bytes = hexString
          .split(RegExp(r'[\s,]+'))
          .where((s) => s.isNotEmpty)
          .map((s) {
            // Support both "0xFF" and "FF" formats
            final cleaned = s.startsWith('0x') || s.startsWith('0X')
                ? s.substring(2)
                : s;
            return int.parse(cleaned, radix: 16);
          })
          .toList();

      if (bytes.isEmpty) {
        _lastError = 'Invalid hex string';
        notifyListeners();
        return;
      }

      await executeCommand(bytes, 'Custom: $hexString');
    } catch (e) {
      _lastError = 'Parse error: $e';
      notifyListeners();
    }
  }

  // ============ Lifecycle ============

  @override
  void dispose() {
    _responseSubscription?.cancel();
    super.dispose();
  }
}
