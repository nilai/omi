import 'package:flutter/material.dart';
import '../models/ble_log_entry.dart';

/// Bottom drawer widget for displaying BLE log entries
/// Supports dragging to expand/collapse between half and full screen
class BleLogDrawer extends StatefulWidget {
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
  State<BleLogDrawer> createState() => _BleLogDrawerState();
}

class _BleLogDrawerState extends State<BleLogDrawer> {
  // Height ratio: 0.0 = collapsed, 0.5 = half, 1.0 = full screen
  double _heightRatio = 0.5;

  // Minimum and maximum height ratios
  static const double _minRatio = 0.3;
  static const double _maxRatio = 0.95;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            // Dragging up = negative delta = increase height
            _heightRatio -= details.delta.dy / screenHeight;
            _heightRatio = _heightRatio.clamp(_minRatio, _maxRatio);
          });
        },
        onVerticalDragEnd: (details) {
          // Snap to nearest position: half or full
          setState(() {
            if (_heightRatio > 0.75) {
              _heightRatio = _maxRatio;
            } else if (_heightRatio < 0.4) {
              _heightRatio = _minRatio;
            } else {
              _heightRatio = 0.5;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: screenHeight * _heightRatio,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: _heightRatio >= _maxRatio
                ? null
                : const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar (drag indicator)
              Container(
                margin: EdgeInsets.only(
                  top: _heightRatio >= _maxRatio ? topPadding + 8 : 8,
                ),
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
                      '(${widget.entries.length})',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onClear,
                      child: const Text('Clear'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF35343B)),
              // Log entries
              Expanded(
                child: widget.entries.isEmpty
                    ? Center(
                        child: Text(
                          'No log entries yet',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.entries.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFF35343B),
                        ),
                        itemBuilder: (context, index) {
                          final entry = widget.entries[index];
                          return _buildLogEntry(entry);
                        },
                      ),
              ),
            ],
          ),
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
