import 'package:flutter/material.dart';
import 'package:omi/backend/schema/bt_device/note_device.dart';

/// A list item widget for displaying file info with download/delete/convert actions
class FileListItem extends StatelessWidget {
  final NoteFileInfo file;
  final bool isDownloading;
  final double downloadProgress;
  final int downloadedBytes;
  final bool isOperating;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  /// Whether the file has been downloaded locally
  final bool isDownloaded;

  /// Whether currently converting to MP3
  final bool isConverting;

  /// Conversion progress (0.0 - 1.0)
  final double conversionProgress;

  /// Whether MP3 file already exists
  final bool hasMp3;

  /// Callback when convert button is pressed
  final VoidCallback? onConvert;

  const FileListItem({
    super.key,
    required this.file,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.downloadedBytes = 0,
    this.isOperating = false,
    this.onDownload,
    this.onDelete,
    this.isDownloaded = false,
    this.isConverting = false,
    this.conversionProgress = 0.0,
    this.hasMp3 = false,
    this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name and actions row
            Row(
              children: [
                // File icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.audio_file,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.grey.shade500,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            file.shortDuration,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF35343B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${file.index}',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons (hidden when downloading or converting)
                if (!isDownloading && !isConverting) ...[
                  // Convert to MP3 button (only shown if downloaded and not already converted)
                  if (isDownloaded && !hasMp3)
                    IconButton(
                      onPressed: isOperating ? null : onConvert,
                      icon: Icon(
                        Icons.transform,
                        color: isOperating
                            ? Colors.grey.shade700
                            : Colors.green,
                        size: 22,
                      ),
                      tooltip: 'Convert to MP3',
                    ),
                  // MP3 indicator (show if already converted)
                  if (isDownloaded && hasMp3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'MP3',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Download button
                  IconButton(
                    onPressed: isOperating ? null : onDownload,
                    icon: Icon(
                      Icons.download,
                      color: isOperating
                          ? Colors.grey.shade700
                          : Colors.blue,
                      size: 22,
                    ),
                    tooltip: 'Download',
                  ),
                  // Delete button
                  IconButton(
                    onPressed: isOperating ? null : onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: isOperating
                          ? Colors.grey.shade700
                          : Colors.red.shade400,
                      size: 22,
                    ),
                    tooltip: 'Delete',
                  ),
                ],
              ],
            ),
            // Progress bar (only when downloading)
            if (isDownloading) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: downloadProgress,
                            backgroundColor: Colors.grey[800],
                            color: Colors.blue,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatBytes(downloadedBytes),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${(downloadProgress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cancel button
                  IconButton(
                    onPressed: onDelete, // Repurpose onDelete as cancel
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
            ],
            // Conversion progress bar (only when converting)
            if (isConverting) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.transform,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Converting to MP3...',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(conversionProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: conversionProgress,
                      backgroundColor: Colors.grey[800],
                      color: Colors.green,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
