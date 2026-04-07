import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_custom_nav_bar.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import 'mp_connect_device_cubit.dart';

class MPConnectDevicePage extends StatefulWidget {
  const MPConnectDevicePage({super.key});

  @override
  State<MPConnectDevicePage> createState() => _MPConnectDevicePageState();
}

class _MPConnectDevicePageState extends State<MPConnectDevicePage>
    with SingleTickerProviderStateMixin {
  late final MPConnectDeviceCubit _cubit = MPConnectDeviceCubit();
  late final AnimationController _radarController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.initData();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPConnectDeviceCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: pageColor,
        appBar: PreferredSize(
          preferredSize: MPCustomNavBar.preferredSizeOf(context),
          child: MPCustomNavBar(
            title: 'Connect Device',
            backgroundColor: pageColor,
            onBack: () => Navigator.of(context, rootNavigator: true).maybePop(),
            actions: <Widget>[
              TextButton.icon(
                onPressed: _cubit.startScan,
                icon: const Icon(Icons.sync, size: 18, color: blueTextColor),
                label: Text(
                  'Scan',
                  style: OmiTextStyle.create(
                    color: blueTextColor,
                    fontSize: OmiFontSize.t7_16,
                    fontWeight: OmiFontWeight.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: BlocBuilder<MPConnectDeviceCubit, MPConnectDeviceState>(
          builder: (BuildContext context, MPConnectDeviceState state) {
            final MPConnectDeviceItem? connected = state.connectedDevice;
            final List<MPConnectDeviceItem> others = state.otherDevices;
            final bool showResultList = !state.isScanning;

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (state.isScanning) ...<Widget>[
                      const SizedBox(height: 6),
                      _MPScanHeader(radarController: _radarController),
                      const SizedBox(height: 14),
                    ],
                    if (connected != null) ...<Widget>[
                      _MPSectionTitle(text: 'CONNECTED DEVICE'),
                      const SizedBox(height: 10),
                      _MPDeviceCard(
                        item: connected,
                        showConnectedBadge: true,
                        actionText: 'Disconnect',
                        actionTextColor: const Color(0xFFF44336),
                        actionBackground: const Color(0xFFF2F2F6),
                        actionBorderColor: const Color(0xFFF2F2F6),
                        onActionPressed: () => _cubit.toggleConnection(connected.id),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showResultList) ...<Widget>[
                      _MPSectionTitle(text: connected == null ? 'AVAILABLE DEVICES' : 'OTHER DEVICES'),
                      const SizedBox(height: 10),
                      if (others.isNotEmpty)
                        _MPDeviceListCard(
                          items: others,
                          connectingDeviceId: state.connectingDeviceId,
                          onConnectTap: (String id) => _cubit.toggleConnection(id),
                        ),
                    ] else if (connected != null) ...<Widget>[
                      _MPSectionTitle(text: 'OTHER DEVICES'),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: lineColor),
                      const SizedBox(height: 6),
                    ],
                    if (showResultList) ...<Widget>[
                      const SizedBox(height: 18),
                      _MPSectionTitle(text: 'CONNECTION TIPS'),
                      const SizedBox(height: 10),
                      const _MPTips(),
                    ],
                    const SizedBox(height: 18),
                    const _MPHelpCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MPScanHeader extends StatelessWidget {
  const _MPScanHeader({required this.radarController});

  final Animation<double> radarController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 164,
          height: 164,
          child: AnimatedBuilder(
            animation: radarController,
            builder: (BuildContext context, Widget? child) {
              final double t = radarController.value;
              return CustomPaint(
                painter: _MPRadarPainter(progress: t),
                child: child,
              );
            },
            child: Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD9DEEA), width: 2),
                ),
                child: ClipOval(
                  child: OmiImageLoader.localImg(
                    'assets/images/3x/mp_connect_device.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Scanning for Devices',
          style: OmiTextStyle.create(
            color: mainTextColor,
            fontSize: OmiFontSize.t13_22,
            fontWeight: OmiFontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Make sure your MemoPin is turned on and within range',
          textAlign: TextAlign.center,
          style: OmiTextStyle.create(
            color: const Color(0xFF9A9AA3),
            fontSize: OmiFontSize.t7_16,
            fontWeight: OmiFontWeight.regular,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _MPRadarPainter extends CustomPainter {
  _MPRadarPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final Paint basePaint = Paint()..color = const Color(0xFFE9EDF7);
    canvas.drawCircle(c, 54, basePaint);

    final List<double> seeds = <double>[0.0, 0.45];
    for (final double seed in seeds) {
      final double wave = (progress + seed) % 1;
      final double radius = 38 + wave * 48;
      final int alpha = ((1 - wave) * 80).clamp(0, 80).toInt();
      final Paint wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color.fromARGB(alpha, 110, 160, 255);
      canvas.drawCircle(c, radius, wavePaint);
    }

    final Paint sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: const <Color>[
          Color(0x00007AFF),
          Color(0x33007AFF),
          Color(0x55007AFF),
          Color(0x00007AFF),
        ],
        stops: const <double>[0.0, 0.45, 0.65, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: c, radius: 58))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(c, 58, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _MPRadarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MPSectionTitle extends StatelessWidget {
  const _MPSectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: OmiTextStyle.create(
        color: const Color(0xFF8E8E93),
        fontSize: OmiFontSize.t4_13,
        fontWeight: OmiFontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MPDeviceListCard extends StatelessWidget {
  const _MPDeviceListCard({
    required this.items,
    required this.connectingDeviceId,
    required this.onConnectTap,
  });

  final List<MPConnectDeviceItem> items;
  final String? connectingDeviceId;
  final ValueChanged<String> onConnectTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List<Widget>.generate(items.length, (int index) {
          final MPConnectDeviceItem item = items[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: <Widget>[
                _MPDeviceCardHeader(item: item),
                const SizedBox(height: 10),
                _MPActionButton(
                  text: 'Connect',
                  textColor: Colors.white,
                  background: const Color(0xFF4C86F8),
                  borderColor: const Color(0xFF4C86F8),
                  showProgress: connectingDeviceId == item.id,
                  onPressed: connectingDeviceId != null
                      ? null
                      : () => onConnectTap(item.id),
                ),
                if (index < items.length - 1) ...<Widget>[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF0F1F5)),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MPDeviceCard extends StatelessWidget {
  const _MPDeviceCard({
    required this.item,
    required this.showConnectedBadge,
    required this.actionText,
    required this.actionTextColor,
    required this.actionBackground,
    required this.actionBorderColor,
    required this.onActionPressed,
  });

  final MPConnectDeviceItem item;
  final bool showConnectedBadge;
  final String actionText;
  final Color actionTextColor;
  final Color actionBackground;
  final Color actionBorderColor;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: <Widget>[
          _MPDeviceCardHeader(item: item, showConnectedBadge: showConnectedBadge),
          const SizedBox(height: 12),
          _MPActionButton(
            text: actionText,
            textColor: actionTextColor,
            background: actionBackground,
            borderColor: actionBorderColor,
            onPressed: onActionPressed,
          ),
        ],
      ),
    );
  }
}

class _MPDeviceCardHeader extends StatelessWidget {
  const _MPDeviceCardHeader({
    required this.item,
    this.showConnectedBadge = false,
  });

  final MPConnectDeviceItem item;
  final bool showConnectedBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEDEEF2),
                    border: Border.all(color: const Color(0xFFD8DAE2)),
                  ),
                  child: ClipOval(
                    child: OmiImageLoader.localImg(
                      'assets/images/3x/mp_connect_device.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              if (showConnectedBadge)
                Positioned(
                  right: -1,
                  top: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.link, color: Colors.white, size: 11),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.name,
                style: OmiTextStyle.create(
                  color: mainTextColor,
                  fontSize: OmiFontSize.t11_20,
                  fontWeight: OmiFontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              _MPSignalBar(
                value: item.isConnected ? item.batteryPercent : 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MPSignalBar extends StatelessWidget {
  const _MPSignalBar({required this.value});

  final int value;

  Color get _barColor {
    if (value >= 65) return const Color(0xFF4CC35E);
    if (value >= 25) return const Color(0xFFF0AA0B);
    return const Color(0xFFE74545);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.battery_1_bar_outlined, size: 13, color: Color(0xFF9A9AA2)),
        const SizedBox(width: 5),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: const Color(0xFFEDEEF2),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (value.clamp(0, 100)) / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: _barColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value%',
          style: OmiTextStyle.create(
            color: const Color(0xFF9A9AA3),
            fontSize: OmiFontSize.t6_15,
            fontWeight: OmiFontWeight.medium,
          ),
        ),
      ],
    );
  }
}

class _MPActionButton extends StatelessWidget {
  const _MPActionButton({
    required this.text,
    required this.textColor,
    required this.background,
    required this.borderColor,
    required this.onPressed,
    this.showProgress = false,
  });

  final String text;
  final Color textColor;
  final Color background;
  final Color borderColor;
  final VoidCallback? onPressed;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: showProgress ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: showProgress
            ? SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: textColor,
                ),
              )
            : Text(
                text,
                style: OmiTextStyle.create(
                  color: textColor,
                  fontSize: OmiFontSize.t9_18,
                  fontWeight: OmiFontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class _MPTips extends StatelessWidget {
  const _MPTips();

  @override
  Widget build(BuildContext context) {
    final List<String> tips = <String>[
      'Keep your device within 30 feet (10 meters) for optimal connection',
      'Ensure your MemoPin is fully charged for the best performance',
      'If you\'re having trouble connecting, try restarting your MemoPin',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
      child: Column(
        children: tips
            .map(
              (String tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(Icons.circle, size: 5, color: Color(0xFF7A7A82)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: OmiTextStyle.create(
                          color: const Color(0xFF4D4D57),
                          fontSize: OmiFontSize.t7_16,
                          fontWeight: OmiFontWeight.regular,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MPHelpCard extends StatelessWidget {
  const _MPHelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3F5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF4180F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Need Help?',
                      style: OmiTextStyle.create(
                        color: mainTextColor,
                        fontSize: OmiFontSize.t11_20,
                        fontWeight: OmiFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Visit our support page for detailed setup\ninstructions and troubleshooting guides.',
                      style: OmiTextStyle.create(
                        color: const Color(0xFF5F6270),
                        fontSize: OmiFontSize.t6_15,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: Text(
                'Open Support ->',
                style: OmiTextStyle.create(
                  color: blueTextColor,
                  fontSize: OmiFontSize.t9_18,
                  fontWeight: OmiFontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
