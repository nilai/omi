// Note File List Provider
// Manages file list state, download progress, and BLE log entries

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:omi/backend/schema/bt_device/note_device.dart';
import 'package:omi/pages/note_debug/models/ble_log_entry.dart';
import 'package:omi/services/devices/note_connection.dart';
import 'package:path_provider/path_provider.dart';
import 'base_provider.dart';

/// Provider for Note device file list management
class NoteFileListProvider extends BaseProvider {
  /// Device connection reference
  NoteDeviceConnection? _connection;

  /// Response stream subscription
  StreamSubscription<List<int>>? _responseSubscription;

  /// File data stream subscription
  StreamSubscription? _fileDataSubscription;

  /// File list
  List<NoteFileInfo> _files = [];

  /// Currently downloading file name
  String? _downloadingFileName;

  /// Downloaded bytes count
  int _downloadedBytes = 0;

  /// Estimated total bytes based on duration
  int _estimatedTotalBytes = 0;

  /// File data buffer for saving
  final List<int> _fileDataBuffer = [];

  /// Downloaded file path (after completion)
  String? _lastDownloadedFilePath;

  /// BLE log entries (newest first)
  final List<BleLogEntry> _logEntries = [];

  /// Maximum log entries to keep
  static const int _maxLogEntries = 500;

  /// Drawer visibility state
  bool _isDrawerOpen = false;

  /// Last error message
  String? _lastError;

  /// Whether refreshing file list
  bool _isRefreshing = false;

  /// Whether a file operation is in progress
  bool _isOperating = false;

  /// Bytes per second for progress estimation (16kHz, 16bit PCM = 32KB/s)
  static const int _bytesPerSecond = 32000;

  /// Download directory name
  static const String _downloadDirName = 'NoteDownloads';

  // ============ Getters ============

  /// Get file list (unmodifiable)
  List<NoteFileInfo> get files => List.unmodifiable(_files);

  /// Whether currently downloading
  bool get isDownloading => _downloadingFileName != null;

  /// Download progress (0.0 - 1.0)
  double get downloadProgress => _estimatedTotalBytes > 0
      ? (_downloadedBytes / _estimatedTotalBytes).clamp(0.0, 1.0)
      : 0.0;

  /// Currently downloading file name
  String? get downloadingFileName => _downloadingFileName;

  /// Downloaded bytes
  int get downloadedBytes => _downloadedBytes;

  /// Estimated total bytes
  int get estimatedTotalBytes => _estimatedTotalBytes;

  /// Last downloaded file path
  String? get lastDownloadedFilePath => _lastDownloadedFilePath;

  /// Get log entries (unmodifiable)
  List<BleLogEntry> get logEntries => List.unmodifiable(_logEntries);

  /// Whether the drawer is open
  bool get isDrawerOpen => _isDrawerOpen;

  /// Last error message
  String? get lastError => _lastError;

  /// Whether refreshing file list
  bool get isRefreshing => _isRefreshing;

  /// Whether a file operation is in progress
  bool get isOperating => _isOperating;

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

  // ============ Storage Path ============

  /// Get download directory path
  /// Android: External storage directory / NoteDownloads
  /// iOS: Application Documents Directory / NoteDownloads
  Future<String> getDownloadPath() async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Use parent path for more accessible location
        directory = directory.parent;
      }
    }

    // Fallback to documents directory for iOS or if external storage unavailable
    directory ??= await getApplicationDocumentsDirectory();

    final downloadDir = Directory('${directory.path}/$_downloadDirName');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return downloadDir.path;
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

  // ============ File List Operations ============

  /// Refresh file list from device
  Future<void> refreshFileList() async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isRefreshing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Log the command
      _addLogEntry(
        BleLogDirection.sent,
        [0x03],
        name: 'Get File List',
      );

      // Get file list from device
      final files = await _connection!.getFileList();
      _files = files;
      print('[NoteFileListProvider] Got ${files.length} files');
    } catch (e) {
      _lastError = e.toString();
      print('[NoteFileListProvider] Error refreshing file list: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // ============ File Download ============

  /// Download a file from device and save to storage
  Future<void> downloadFile(NoteFileInfo file) async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    if (_downloadingFileName != null) {
      _lastError = 'Another download is in progress';
      notifyListeners();
      return;
    }

    _downloadingFileName = file.name;
    _downloadedBytes = 0;
    _estimatedTotalBytes = file.durationSeconds * _bytesPerSecond;
    _fileDataBuffer.clear();
    _lastDownloadedFilePath = null;
    _lastError = null;
    _isOperating = true;
    notifyListeners();

    try {
      // Setup file data listener
      _fileDataSubscription?.cancel();
      _fileDataSubscription = await _connection!.getFileDataListener(
        onFileDataReceived: _onFileDataReceived,
      );

      // Log the command
      final fileNameBytes = file.name.codeUnits;
      _addLogEntry(
        BleLogDirection.sent,
        [0x04, fileNameBytes.length, ...fileNameBytes],
        name: 'Upload File: ${file.name}',
      );

      // Request file upload from device
      await _connection!.uploadFile(file.name);

      print('[NoteFileListProvider] Started downloading: ${file.name}');
    } catch (e) {
      _lastError = e.toString();
      _downloadingFileName = null;
      _fileDataBuffer.clear();
      _isOperating = false;
      print('[NoteFileListProvider] Error starting download: $e');
    }

    notifyListeners();
  }

  /// Handle received file data
  void _onFileDataReceived(List<int> data) {
    if (_downloadingFileName == null) return;

    // Add data to buffer
    _fileDataBuffer.addAll(data);
    _downloadedBytes += data.length;

    // Log the received data (truncate if too long)
    _addLogEntry(
      BleLogDirection.received,
      data.length > 64 ? data.sublist(0, 64) : data,
      name: 'File Data: ${data.length} bytes',
    );

    notifyListeners();

    // Check if download completed (based on estimated size)
    if (_downloadedBytes >= _estimatedTotalBytes) {
      _completeDownload();
    }
  }

  /// Complete the download and save file
  Future<void> _completeDownload() async {
    final fileName = _downloadingFileName;
    if (fileName == null) return;

    print('[NoteFileListProvider] Download completed: $fileName, '
        'received $_downloadedBytes bytes');

    _fileDataSubscription?.cancel();
    _fileDataSubscription = null;

    try {
      // Save file to storage
      final downloadPath = await getDownloadPath();
      final filePath = '$downloadPath/$fileName';
      final file = File(filePath);

      // Write buffer to file
      await file.writeAsBytes(Uint8List.fromList(_fileDataBuffer));

      _lastDownloadedFilePath = filePath;
      print('[NoteFileListProvider] File saved to: $filePath');

      // Add success log entry
      _addLogEntry(
        BleLogDirection.received,
        [],
        name: 'File saved: $filePath',
      );
    } catch (e) {
      _lastError = 'Failed to save file: $e';
      print('[NoteFileListProvider] Error saving file: $e');
    } finally {
      _downloadingFileName = null;
      _fileDataBuffer.clear();
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Cancel current download
  void cancelDownload() {
    if (_downloadingFileName != null) {
      print('[NoteFileListProvider] Download cancelled: $_downloadingFileName');
      _fileDataSubscription?.cancel();
      _fileDataSubscription = null;
      _downloadingFileName = null;
      _downloadedBytes = 0;
      _estimatedTotalBytes = 0;
      _fileDataBuffer.clear();
      _isOperating = false;
      notifyListeners();
    }
  }

  // ============ File Delete ============

  /// Delete a file from device
  Future<void> deleteFile(NoteFileInfo file) async {
    if (_connection == null) {
      _lastError = 'Device not connected';
      notifyListeners();
      return;
    }

    _isOperating = true;
    _lastError = null;
    notifyListeners();

    try {
      // Log the command
      final fileNameBytes = file.name.codeUnits;
      _addLogEntry(
        BleLogDirection.sent,
        [0x05, fileNameBytes.length, ...fileNameBytes],
        name: 'Delete File: ${file.name}',
      );

      // Delete file on device
      await _connection!.deleteFile(file.name);

      // Remove from local list
      _files.removeWhere((f) => f.name == file.name);

      print('[NoteFileListProvider] File deleted: ${file.name}');
    } catch (e) {
      _lastError = e.toString();
      print('[NoteFileListProvider] Error deleting file: $e');
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ============ Lifecycle ============

  @override
  void dispose() {
    _responseSubscription?.cancel();
    _fileDataSubscription?.cancel();
    super.dispose();
  }
}
