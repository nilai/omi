import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:omi/providers/onboarding_provider.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/widgets/dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'found_devices.dart';

class FindDevicesPage extends StatefulWidget {
  final bool isFromOnboarding;
  final VoidCallback goNext;
  final VoidCallback? onSkip;
  final bool includeSkip;

  const FindDevicesPage(
      {super.key, required this.goNext, this.includeSkip = true, this.isFromOnboarding = false, this.onSkip});

  @override
  State<FindDevicesPage> createState() => _FindDevicesPageState();
}

class _FindDevicesPageState extends State<FindDevicesPage> {
  OnboardingProvider? _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<OnboardingProvider>(context, listen: false);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.isFromOnboarding) {
        context.read<HomeProvider>().setupHasSpeakerProfile();
      }
      _scanDevices();
    });
  }

  @override
  dispose() {
    _provider = null;

    super.dispose();
  }

  Future<void> _scanDevices() async {
    _provider?.scanDevices(
      onShowDialog: () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => getDialog(
              context,
              () {
                Navigator.of(context).pop();
              },
              () {},
              'Enable Bluetooth',
              'Omi needs Bluetooth to connect to your wearable. Please enable Bluetooth and try again.',
              singleButton: true,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF1D1D1F),
                          size: 20,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          '连接设备',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => launchUrl(Uri.parse('mailto:team@basedhardware.com')),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF1D1D1F),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FoundDevices(
                      goNext: widget.goNext,
                      isFromOnboarding: widget.isFromOnboarding,
                    ),
                  ),
                  if (provider.deviceList.isEmpty && provider.enableInstructions) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse('mailto:team@basedhardware.com')),
                      child: const Text(
                        '遇到问题？联系支持',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4361EE),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  if (widget.includeSkip) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.isFromOnboarding) {
                            widget.onSkip!();
                          } else {
                            widget.goNext();
                          }
                          MixpanelManager().useWithoutDeviceOnboardingFindDevices();
                        },
                        child: const Text(
                          '稍后连接',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
