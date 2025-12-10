import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_provider_utilities/flutter_provider_utilities.dart';
import 'package:omi/backend/schema/bt_device/bt_device.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/providers/onboarding_provider.dart';
import 'package:omi/pages/onboarding/apple_watch_permission_page.dart';
import 'package:omi/widgets/apple_watch_setup_bottom_sheet.dart';
import 'package:omi/widgets/confirmation_dialog.dart';
import 'package:omi/services/devices/apple_watch_connection.dart';
import 'package:omi/services/services.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/gen/flutter_communicator.g.dart';
import 'package:omi/utils/device.dart';
import 'package:provider/provider.dart';

class FoundDevices extends StatefulWidget {
  final bool isFromOnboarding;
  final VoidCallback goNext;

  const FoundDevices({
    super.key,
    required this.goNext,
    required this.isFromOnboarding,
  });

  @override
  State<FoundDevices> createState() => _FoundDevicesState();
}

class _FoundDevicesState extends State<FoundDevices> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<DeviceProvider>().periodicConnect('coming from FoundDevices');
      }
    });
  }

  Future<void> _handleAppleWatchOnboarding(BtDevice device, OnboardingProvider provider) async {
    try {
      // First check if the watch is reachable
      final hostAPI = WatchRecorderHostAPI();
      final bool isReachable = await hostAPI.isWatchReachable();

      if (!isReachable) {
        // Watch is not reachable - show bottom sheet to install/open app
        await _showWatchNotReachableBottomSheet(device.id);
        return;
      }

      // Watch is reachable - connect and check permissions
      await ServiceManager.instance().device.ensureConnection(device.id, force: true);
      final connection = await ServiceManager.instance().device.ensureConnection(device.id);

      if (connection is! AppleWatchDeviceConnection) {
        debugPrint('Device is not an Apple Watch connection');
        return;
      }

      // Check permission and try to start recording immediately
      final bool recordingStarted = await connection.checkPermissionAndStartRecording();

      if (!recordingStarted) {
        await _showMicrophonePermissionPage(connection);
      } else {
        await _completeAppleWatchOnboarding(device, provider);
      }
    } catch (e) {
      debugPrint('Error handling Apple Watch onboarding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to Apple Watch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show bottom sheet when Apple Watch is not reachable
  Future<void> _showWatchNotReachableBottomSheet(String deviceId) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AppleWatchSetupBottomSheet(
        deviceId: deviceId,
        onConnected: () async {
          // Retry the connection flow when user says they've connected
          final device =
              Provider.of<OnboardingProvider>(context, listen: false).deviceList.firstWhere((d) => d.id == deviceId);
          final provider = Provider.of<OnboardingProvider>(context, listen: false);
          await _handleAppleWatchOnboarding(device, provider);
        },
      ),
    );
  }

  Future<void> _showMicrophonePermissionPage(AppleWatchDeviceConnection connection) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppleWatchPermissionPage(
          connection: connection,
          onPermissionGranted: () async {
            final provider = Provider.of<OnboardingProvider>(context, listen: false);
            final device = provider.deviceList.firstWhere((d) => d.id == connection.device.id);
            await _completeAppleWatchOnboarding(device, provider);
          },
        ),
      ),
    );
  }

  Future<void> _completeAppleWatchOnboarding(BtDevice device, OnboardingProvider provider) async {
    try {
      provider.deviceId = device.id;
      provider.deviceName = device.name;
      provider.isConnected = true;
      provider.isClicked = false;
      provider.connectingToDeviceId = null;

      await provider.deviceProvider?.scanAndConnectToDevice();

      // Show firmware warning if needed
      await _showFirmwareWarningIfNeeded(device);

      if (widget.isFromOnboarding) {
        widget.goNext();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error completing Apple Watch onboarding: $e');
    }
  }

  Future<void> _showFirmwareWarningIfNeeded(BtDevice device) async {
    final warningMessage = device.getFirmwareWarningMessage();
    if (warningMessage.isEmpty) {
      return; // No warning needed for this device type
    }

    // Check if user has already acknowledged this device type
    final prefKey = 'firmware_warning_acknowledged_${device.type.toString()}';
    final alreadyAcknowledged = SharedPreferencesUtil().getBool(prefKey) ?? false;

    if (alreadyAcknowledged) {
      return; // User already acknowledged this warning
    }

    bool dontShowAgain = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // Must click button
      builder: (context) => ConfirmationDialog(
        title: device.getFirmwareWarningTitle(),
        description: warningMessage,
        checkboxText: "Don't show it again",
        checkboxValue: false,
        onCheckboxChanged: (value) {
          dontShowAgain = value;
        },
        confirmText: "I Understand",
        onConfirm: () {
          if (dontShowAgain) {
            SharedPreferencesUtil().saveBool(prefKey, true);
          }
          Navigator.of(context).pop();
        },
        onCancel: () {
          // Not used, but required by ConfirmationDialog
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, provider, child) {
      return MessageListener<OnboardingProvider>(
        showError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ));
        },
        showInfo: (info) {
          if (info == "DEVICE_CONNECTED") {
            // Navigator.of(context).pushAndRemoveUntil(
            //   MaterialPageRoute(
            //     builder: (context) => const HomePageWrapper(),
            //   ),
            //   (route) => false,
            // );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(info),
              backgroundColor: Colors.green,
            ));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: provider.isConnected
                  ? _buildConnected(provider)
                  : provider.deviceList.isEmpty
                      ? _buildSearching(context)
                      : _buildFoundList(provider),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSearching(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Assets.images.omiWithRope.image(
              width: 188,
              height: 188,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x144361EE),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.bluetooth,
                color: Color(0xFF4361EE),
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: MPAnimatedDotsText(
              baseText: '正在搜索设备',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '请确保设备已开启并在附近',
              style: TextStyle(
                fontSize: 14,
                color: Color(0x991D1D1F),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTipsCard(context),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF4361EE)),
              SizedBox(width: 8),
              Text(
                '连接提示',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _MPTipRow(index: 1, text: '确保设备电量充足'),
          const SizedBox(height: 8),
          const _MPTipRow(index: 2, text: '将设备靠近手机'),
          const SizedBox(height: 8),
          const _MPTipRow(index: 3, text: '首次连接需要在设备上确认配对'),
        ],
      ),
    );
  }

  Widget _buildFoundList(OnboardingProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '发现附近的设备',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${provider.deviceList.length} 个设备可用',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0x991D1D1F),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: provider.deviceList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final device = provider.deviceList[index];
              final isConnecting = provider.connectingToDeviceId == device.id;
              return GestureDetector(
                onTap: !provider.isClicked
                    ? () async {
                        if (device.type == DeviceType.appleWatch) {
                          await _handleAppleWatchOnboarding(device, provider);
                        } else {
                          await provider.handleTap(
                            device: device,
                            isFromOnboarding: widget.isFromOnboarding,
                            goNext: widget.goNext,
                          );

                          if (provider.isConnected) {
                            await _showFirmwareWarningIfNeeded(device);
                          }
                        }
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0x1A4361EE),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x0F4361EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            DeviceUtils.getDeviceImagePath(
                              deviceType: device.type,
                              modelNumber: device.modelNumber,
                              deviceName: device.name,
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1D1F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${device.getShortId()}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0x991D1D1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isConnecting)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFF4361EE)),
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF1D1D1F),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnected(OnboardingProvider provider) {
    final battery = provider.batteryPercentage;
    final batteryColor = battery <= 25
        ? Colors.red
        : battery > 25 && battery <= 50
            ? Colors.orange
            : Colors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          color: Color(0xFF4BB543),
          size: 44,
        ),
        const SizedBox(height: 12),
        const Text(
          '配对成功',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${provider.deviceName} (${BtDevice.shortId(provider.deviceId)})',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xCC1D1D1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '电量 $battery%',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: batteryColor,
          ),
        ),
      ],
    );
  }
}

class MPAnimatedDotsText extends StatefulWidget {
  final String baseText;
  final TextStyle style;

  const MPAnimatedDotsText({super.key, required this.baseText, required this.style});

  @override
  State<MPAnimatedDotsText> createState() => _MPAnimatedDotsTextState();
}

class _MPAnimatedDotsTextState extends State<MPAnimatedDotsText> {
  static const int _maxDots = 3;
  static const Duration _tick = Duration(milliseconds: 500);

  late Timer _timer;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {
        _dotCount = (_dotCount + 1) % (_maxDots + 1);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.baseText}${'.' * _dotCount}',
      style: widget.style,
    );
  }
}

class _MPTipRow extends StatelessWidget {
  final int index;
  final String text;

  const _MPTipRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0x0F4361EE),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4361EE),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ),
      ],
    );
  }
}
