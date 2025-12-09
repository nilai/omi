import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/providers/note_file_list_provider.dart';
import 'package:omi/services/devices/note_connection.dart';
import 'package:omi/services/services.dart';
import 'widgets/ble_log_drawer.dart';
import 'widgets/file_list_item.dart';

/// File list page for Note devices
/// Displays files on device with download/delete operations
class NoteFileListPage extends StatefulWidget {
  const NoteFileListPage({super.key});

  @override
  State<NoteFileListPage> createState() => _NoteFileListPageState();
}

class _NoteFileListPageState extends State<NoteFileListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get connection from DeviceProvider via ServiceManager
      final deviceProvider = context.read<DeviceProvider>();
      final fileListProvider = context.read<NoteFileListProvider>();

      if (deviceProvider.connectedDevice != null) {
        final connection = await ServiceManager.instance()
            .device
            .ensureConnection(deviceProvider.connectedDevice!.id);
        if (connection is NoteDeviceConnection) {
          fileListProvider.setConnection(connection);
          // Auto refresh file list on page load
          fileListProvider.refreshFileList();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteFileListProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: AppBar(
            title: const Text('Device Files'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [
              // Refresh button
              IconButton(
                icon: provider.isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed:
                    provider.isRefreshing ? null : provider.refreshFileList,
              ),
              // Log drawer toggle button with badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      provider.isDrawerOpen ? Icons.receipt : Icons.receipt_long,
                    ),
                    onPressed: provider.toggleDrawer,
                  ),
                  if (provider.logEntries.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          provider.logEntries.length > 99
                              ? '99+'
                              : '${provider.logEntries.length}',
                          style:
                              const TextStyle(fontSize: 9, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              // Main content - file list
              _buildFileList(provider),

              // Bottom drawer for logs
              if (provider.isDrawerOpen)
                BleLogDrawer(
                  entries: provider.logEntries,
                  onClose: provider.closeDrawer,
                  onClear: provider.clearLogs,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileList(NoteFileListProvider provider) {
    return Column(
      children: [
        // Connection status
        _buildConnectionStatus(provider),

        // Error message
        if (provider.lastError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildErrorCard(provider.lastError!),
          ),

        // File count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Files',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF35343B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${provider.files.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // File list
        Expanded(
          child: provider.isRefreshing && provider.files.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : provider.files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No files on device',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: provider.isConnected
                                ? provider.refreshFileList
                                : null,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.files.length,
                      itemBuilder: (context, index) {
                        final file = provider.files[index];
                        final isThisFileDownloading =
                            provider.downloadingFileName == file.name;

                        return FileListItem(
                          file: file,
                          isDownloading: isThisFileDownloading,
                          downloadProgress: isThisFileDownloading
                              ? provider.downloadProgress
                              : 0.0,
                          downloadedBytes: isThisFileDownloading
                              ? provider.downloadedBytes
                              : 0,
                          isOperating: provider.isOperating,
                          onDownload: () => provider.downloadFile(file),
                          onDelete: isThisFileDownloading
                              ? () => provider.cancelDownload()
                              : () => _confirmDelete(provider, file),
                        );
                      },
                    ),
        ),

        // Bottom padding for drawer
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildConnectionStatus(NoteFileListProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: provider.isConnected
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: provider.isConnected
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: provider.isConnected ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              provider.isConnected ? 'Connected' : 'Not Connected',
              style: TextStyle(
                color: provider.isConnected ? Colors.green : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade300, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    NoteFileListProvider provider,
    dynamic file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F25),
        title: const Text(
          'Delete File',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${file.name}"?\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deleteFile(file);
    }
  }
}
