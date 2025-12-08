import 'package:flutter/material.dart';
import '../models/ble_log_entry.dart';

/// Bottom drawer widget for displaying BLE log entries
class BleLogDrawer extends StatelessWidget {
  final List<BleLogEntry> entries;
  final VoidCallback onClose;
  final VoidCallback onClear;

  const BleLogDrawer({
    super.key,
    required this.entries,
    required this.onClose,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'BLE Log',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${entries.length})',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onClear,
                    child: const Text('Clear'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF35343B)),
            // Log entries
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        'No log entries yet',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0xFF35343B),
                      ),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _buildLogEntry(entry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(BleLogEntry entry) {
    final isSent = entry.isSent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSent ? Icons.arrow_upward : Icons.arrow_downward,
                color: isSent ? Colors.blue : Colors.green,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                isSent ? 'SENT' : 'RECV',
                style: TextStyle(
                  color: isSent ? Colors.blue : Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.formattedTime,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              if (entry.commandName != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.commandName!,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            entry.hexString,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
