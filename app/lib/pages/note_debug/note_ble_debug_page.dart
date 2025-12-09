import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/providers/note_ble_debug_provider.dart';
import 'package:omi/services/devices/note_commands.dart';
import 'package:omi/services/devices/note_connection.dart';
import 'package:omi/services/services.dart';
import 'widgets/command_button.dart';
import 'widgets/command_category_section.dart';
import 'widgets/ble_log_drawer.dart';
import 'note_file_list_page.dart';

/// BLE Debug Page for Note devices
/// Allows sending protocol commands and viewing hex data logs
class NoteBleDebugPage extends StatefulWidget {
  const NoteBleDebugPage({super.key});

  @override
  State<NoteBleDebugPage> createState() => _NoteBleDebugPageState();
}

class _NoteBleDebugPageState extends State<NoteBleDebugPage> {
  final TextEditingController _customCommandController = TextEditingController();
  NoteRecordingMode _selectedRecordingMode = NoteRecordingMode.recordOnly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get connection from DeviceProvider via ServiceManager
      final deviceProvider = context.read<DeviceProvider>();
      final debugProvider = context.read<NoteBleDebugProvider>();

      if (deviceProvider.connectedDevice != null) {
        final connection = await ServiceManager.instance()
            .device
            .ensureConnection(deviceProvider.connectedDevice!.id);
        if (connection is NoteDeviceConnection) {
          debugProvider.setConnection(connection);
        }
      }
    });
  }

  @override
  void dispose() {
    _customCommandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteBleDebugProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: AppBar(
            title: const Text('BLE Debug'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [
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
                          style: const TextStyle(fontSize: 9, color: Colors.white),
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
              // Main content - command buttons
              _buildCommandList(provider),

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

  Widget _buildCommandList(NoteBleDebugProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection status
        _buildConnectionStatus(provider),
        const SizedBox(height: 16),

        // Error message
        if (provider.lastError != null) ...[
          _buildErrorCard(provider.lastError!),
          const SizedBox(height: 16),
        ],

        // Recording Commands
        CommandCategorySection(
          title: 'Recording',
          icon: Icons.mic,
          children: [
            CommandButton(
              title: 'Start Recording',
              hexCode: '0x01',
              onPressed: provider.isConnected ? provider.sendStartRecording : null,
              isLoading: provider.isExecuting,
            ),
            CommandButton(
              title: 'Stop Recording',
              hexCode: '0x02',
              onPressed: provider.isConnected ? provider.sendStopRecording : null,
              isLoading: provider.isExecuting,
            ),
            _buildRecordingModeSelector(provider),
          ],
        ),

        // Device Info Commands
        CommandCategorySection(
          title: 'Device Info',
          icon: Icons.info_outline,
          children: [
            CommandButton(
              title: 'Query Battery',
              hexCode: '0xE1',
              onPressed: provider.isConnected ? provider.sendQueryBattery : null,
              isLoading: provider.isExecuting,
            ),
            CommandButton(
              title: 'Query Version',
              hexCode: '0xE3',
              onPressed: provider.isConnected ? provider.sendQueryVersion : null,
              isLoading: provider.isExecuting,
            ),
            CommandButton(
              title: 'Query Storage',
              hexCode: '0xE8',
              onPressed: provider.isConnected ? provider.sendQueryStorage : null,
              isLoading: provider.isExecuting,
            ),
          ],
        ),

        // File Management
        CommandCategorySection(
          title: 'File Management',
          icon: Icons.folder,
          children: [
            _buildFileManagerButton(provider),
          ],
        ),

        // Device Control
        CommandCategorySection(
          title: 'Device Control',
          icon: Icons.settings,
          children: [
            CommandButton(
              title: 'Sync RTC',
              hexCode: '0xE5 + timestamp',
              onPressed: provider.isConnected ? provider.sendSyncRTC : null,
              isLoading: provider.isExecuting,
            ),
            CommandButton(
              title: 'Bind Device',
              hexCode: '0x0B 0x01',
              onPressed: provider.isConnected ? provider.sendBindDevice : null,
              isLoading: provider.isExecuting,
            ),
            CommandButton(
              title: 'Unbind Device',
              hexCode: '0x0B 0x00',
              onPressed: provider.isConnected ? provider.sendUnbindDevice : null,
              isLoading: provider.isExecuting,
            ),
            CommandButton(
              title: 'USB Mode ON',
              hexCode: '0xE4 0x01',
              onPressed:
                  provider.isConnected ? () => provider.sendSetUsbMode(true) : null,
              isLoading: provider.isExecuting,
            ),
            CommandButton(
              title: 'USB Mode OFF',
              hexCode: '0xE4 0x00',
              onPressed:
                  provider.isConnected ? () => provider.sendSetUsbMode(false) : null,
              isLoading: provider.isExecuting,
            ),
            CommandButton(
              title: 'Reboot',
              hexCode: '0x09',
              onPressed: provider.isConnected ? provider.sendReboot : null,
              isLoading: provider.isExecuting,
              isDangerous: true,
            ),
            CommandButton(
              title: 'Factory Reset (Keep Files)',
              hexCode: '0xE9 0x00',
              onPressed:
                  provider.isConnected ? () => provider.sendFactoryReset(true) : null,
              isLoading: provider.isExecuting,
              isDangerous: true,
            ),
            CommandButton(
              title: 'Factory Reset (Delete All)',
              hexCode: '0xE9 0xFF',
              onPressed:
                  provider.isConnected ? () => provider.sendFactoryReset(false) : null,
              isLoading: provider.isExecuting,
              isDangerous: true,
            ),
          ],
        ),

        // OTA Commands
        CommandCategorySection(
          title: 'OTA',
          icon: Icons.system_update,
          children: [
            CommandButton(
              title: 'Enter OTA (8711)',
              hexCode: '0xE6 0x04',
              onPressed: provider.isConnected
                  ? () => provider.sendOtaEnter(NoteOtaModule.module8711)
                  : null,
              isLoading: provider.isExecuting,
              isDangerous: true,
            ),
            CommandButton(
              title: 'Enter OTA (3085)',
              hexCode: '0xE6 0x01',
              onPressed: provider.isConnected
                  ? () => provider.sendOtaEnter(NoteOtaModule.module3085)
                  : null,
              isLoading: provider.isExecuting,
              isDangerous: true,
            ),
          ],
        ),

        // Custom Command
        CommandCategorySection(
          title: 'Custom Command',
          icon: Icons.code,
          children: [
            _buildCustomCommandInput(provider),
          ],
        ),

        const SizedBox(height: 100), // Space for drawer
      ],
    );
  }

  Widget _buildConnectionStatus(NoteBleDebugProvider provider) {
    return Container(
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

  Widget _buildRecordingModeSelector(NoteBleDebugProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set Recording Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '0x0D ${_selectedRecordingMode.value.toRadixString(16).toUpperCase().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<NoteRecordingMode>(
            value: _selectedRecordingMode,
            dropdownColor: const Color(0xFF2A2A2E),
            underline: const SizedBox(),
            items: NoteRecordingMode.values.map((mode) {
              return DropdownMenuItem(
                value: mode,
                child: Text(
                  mode.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: provider.isConnected
                ? (mode) {
                    if (mode != null) {
                      setState(() => _selectedRecordingMode = mode);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, size: 18),
            color: provider.isConnected ? Colors.white54 : Colors.grey.shade700,
            onPressed: provider.isConnected
                ? () => provider.sendSetRecordingMode(_selectedRecordingMode)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFileManagerButton(NoteBleDebugProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: provider.isConnected
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NoteFileListPage(),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View, download, and delete files',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: provider.isConnected
                      ? Colors.white54
                      : Colors.grey.shade700,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCommandInput(NoteBleDebugProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter hex command (e.g., "E1" or "0xE1 0x00")',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCommandController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: 'E1 or 0xE1 0x00',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFF1F1F25),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  enabled: provider.isConnected,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: provider.isConnected
                    ? () {
                        final hex = _customCommandController.text.trim();
                        if (hex.isNotEmpty) {
                          provider.sendCustomCommand(hex);
                          _customCommandController.clear();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
