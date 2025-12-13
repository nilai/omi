// Note File List Provider
// Manages file list state, download progress, and BLE log entries

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:omi/backend/schema/bt_device/note_device.dart';
import 'package:omi/pages/note_debug/models/ble_log_entry.dart';
import 'package:omi/services/devices/note_connection.dart';
import 'package:omi/utils/audio_converter_utils.dart';
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

  /// Write buffer size (32KB)
  static const int _writeBufferSize = 32 * 1024;

  /// Current download file IOSink for incremental writing
  IOSink? _fileSink;

  /// Current download file path
  String? _currentFilePath;

  // ============ MP3 Conversion State ============

  /// Audio converter utility instance
  final AudioConverterUtils _audioConverter = AudioConverterUtils();

  /// Whether currently converting a file
  bool _isConverting = false;

  /// Currently converting file name
  String? _convertingFileName;

  /// Conversion progress (0.0 - 1.0)
  double _conversionProgress = 0.0;

  /// Last converted MP3 file path
  String? _lastConvertedMp3Path;

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

  /// Whether currently converting
  bool get isConverting => _isConverting;

  /// Converting file name
  String? get convertingFileName => _convertingFileName;

  /// Conversion progress (0.0 - 1.0)
  double get conversionProgress => _conversionProgress;

  /// Last converted MP3 file path
  String? get lastConvertedMp3Path => _lastConvertedMp3Path;

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
  /// Uses incremental writing to avoid memory issues with large files
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
      // Create download directory and file
      final downloadPath = await getDownloadPath();
      _currentFilePath = '$downloadPath/${file.name}';
      final outputFile = File(_currentFilePath!);
      _fileSink = outputFile.openWrite();
      print('[NoteFileListProvider] Opened file for writing: $_currentFilePath');

      // Setup completion listener to detect 0x04 0x02 signal
      _setupCompletionListener();

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
      await _fileSink?.close();
      _fileSink = null;
      _currentFilePath = null;
      _downloadingFileName = null;
      _fileDataBuffer.clear();
      _isOperating = false;
      print('[NoteFileListProvider] Error starting download: $e');
    }

    notifyListeners();
  }

  /// Handle received file data
  /// Writes data incrementally to file when buffer is full
  void _onFileDataReceived(List<int> data) {
    if (_downloadingFileName == null || _fileSink == null) return;

    // Add data to buffer
    _fileDataBuffer.addAll(data);
    _downloadedBytes += data.length;

    // Log the received data (truncate if too long)
    _addLogEntry(
      BleLogDirection.received,
      data.length > 64 ? data.sublist(0, 64) : data,
      name: 'File Data: ${data.length} bytes (total: $_downloadedBytes)',
    );

    // Flush buffer to file when full
    if (_fileDataBuffer.length >= _writeBufferSize) {
      _flushBuffer();
    }

    notifyListeners();
  }

  /// Flush buffer data to file
  void _flushBuffer() {
    if (_fileDataBuffer.isEmpty || _fileSink == null) return;

    _fileSink!.add(Uint8List.fromList(_fileDataBuffer));
    print('[NoteFileListProvider] Flushed ${_fileDataBuffer.length} bytes to file');
    _fileDataBuffer.clear();
  }

  /// Setup completion listener to detect 0x04 0x02 signal from responseStream
  void _setupCompletionListener() {
    _responseSubscription?.cancel();
    if (_connection == null) return;

    _responseSubscription = _connection!.bleTransport.responseStream.listen(
      (data) {
        // Log the response
        _addLogEntry(BleLogDirection.received, data);

        // Detect file upload completion signal: 0x04 0x02
        if (data.length >= 2 && data[0] == 0x04 && data[1] == 0x02) {
          print('[NoteFileListProvider] Received file transfer completion signal');
          _completeDownload();
        }
      },
    );
  }

  /// Complete the download and save file
  /// Flushes remaining buffer and closes the file sink
  Future<void> _completeDownload() async {
    final fileName = _downloadingFileName;
    if (fileName == null) return;

    print('[NoteFileListProvider] Download completed: $fileName, '
        'received $_downloadedBytes bytes');

    // Cancel subscriptions
    _fileDataSubscription?.cancel();
    _fileDataSubscription = null;
    _responseSubscription?.cancel();
    _responseSubscription = null;

    try {
      // Flush remaining buffer data
      _flushBuffer();

      // Close file sink
      await _fileSink?.flush();
      await _fileSink?.close();

      _lastDownloadedFilePath = _currentFilePath;
      print('[NoteFileListProvider] File saved to: $_currentFilePath');

      // Add success log entry
      _addLogEntry(
        BleLogDirection.received,
        [],
        name: 'File saved: $_currentFilePath ($_downloadedBytes bytes)',
      );
    } catch (e) {
      _lastError = 'Failed to save file: $e';
      print('[NoteFileListProvider] Error saving file: $e');
    } finally {
      _cleanupDownloadState();
    }
  }

  /// Clean up download state
  void _cleanupDownloadState() {
    _downloadingFileName = null;
    _fileDataBuffer.clear();
    _fileSink = null;
    _currentFilePath = null;
    _isOperating = false;
    notifyListeners();
  }

  /// Cancel current download
  /// Closes file sink and deletes the incomplete file
  Future<void> cancelDownload() async {
    if (_downloadingFileName != null) {
      print('[NoteFileListProvider] Download cancelled: $_downloadingFileName');

      // Cancel subscriptions
      _fileDataSubscription?.cancel();
      _fileDataSubscription = null;
      _responseSubscription?.cancel();
      _responseSubscription = null;

      // Close file sink
      await _fileSink?.close();

      // Delete incomplete file
      if (_currentFilePath != null) {
        try {
          final file = File(_currentFilePath!);
          if (await file.exists()) {
            await file.delete();
            print('[NoteFileListProvider] Deleted incomplete file: $_currentFilePath');
          }
        } catch (e) {
          print('[NoteFileListProvider] Error deleting incomplete file: $e');
        }
      }

      // Clean up state
      _downloadedBytes = 0;
      _estimatedTotalBytes = 0;
      _cleanupDownloadState();
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

  // ============ MP3 Conversion ============

  /// Convert downloaded opus file to MP3
  /// [opusFilePath] - Path to the opus file to convert
  /// Uses default 16000 Hz sample rate and 1 channel (mono)
  Future<void> convertToMp3(String opusFilePath) async {
    if (_isConverting) {
      _lastError = 'Another conversion is in progress';
      notifyListeners();
      return;
    }

    final file = File(opusFilePath);
    if (!file.existsSync()) {
      _lastError = 'File not found: $opusFilePath';
      notifyListeners();
      return;
    }

    _isConverting = true;
    _convertingFileName = opusFilePath.split('/').last;
    _conversionProgress = 0.0;
    _lastConvertedMp3Path = null;
    _lastError = null;
    notifyListeners();

    try {
      print('[NoteFileListProvider] Starting conversion: $_convertingFileName');

      final mp3Path = await _audioConverter.convertOpusToMp3(
        opusFilePath: opusFilePath,
        sampleRate: 16000,
        channels: 1,  // Note device uses mono
        onProgress: (progress) {
          _conversionProgress = progress;
          notifyListeners();
        },
      );

      _lastConvertedMp3Path = mp3Path;
      print('[NoteFileListProvider] Conversion completed: $mp3Path');

      // Add success log entry
      _addLogEntry(
        BleLogDirection.received,
        [],
        name: 'MP3 conversion completed: ${mp3Path.split('/').last}',
      );
    } catch (e) {
      _lastError = 'Conversion failed: $e';
      print('[NoteFileListProvider] Conversion error: $e');
    } finally {
      _isConverting = false;
      _convertingFileName = null;
      notifyListeners();
    }
  }

  /// Convert the last downloaded file to MP3
  Future<void> convertLastDownloadedToMp3() async {
    if (_lastDownloadedFilePath == null) {
      _lastError = 'No downloaded file available';
      notifyListeners();
      return;
    }
    await convertToMp3(_lastDownloadedFilePath!);
  }

  /// Check if a file has already been converted to MP3
  Future<bool> hasConvertedMp3(String opusFilePath) async {
    final mp3Path = _getExpectedMp3Path(opusFilePath);
    return File(mp3Path).existsSync();
  }

  /// Get the expected MP3 path for an opus file
  String _getExpectedMp3Path(String opusFilePath) {
    final lastDot = opusFilePath.lastIndexOf('.');
    if (lastDot > 0) {
      return '${opusFilePath.substring(0, lastDot)}.mp3';
    }
    return '$opusFilePath.mp3';
  }

  /// Get MP3 path if already converted, null otherwise
  Future<String?> getConvertedMp3Path(String opusFilePath) async {
    final mp3Path = _getExpectedMp3Path(opusFilePath);
    if (File(mp3Path).existsSync()) {
      return mp3Path;
    }
    return null;
  }

  // ============ Lifecycle ============

  @override
  void dispose() {
    _responseSubscription?.cancel();
    _fileDataSubscription?.cancel();
    _fileSink?.close();
    super.dispose();
  }
}
