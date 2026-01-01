import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omi/providers/device_provider.dart';
import 'package:omi/providers/mp_device_finder_provider.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:provider/provider.dart';

import '../../../services/devices/note_connection.dart';
import '../../../services/services.dart';
import '../setting/mic_page.dart';

class MPFoundDevices extends StatefulWidget {
  final bool isFromOnboarding;
  final VoidCallback goNext;

  const MPFoundDevices({
    super.key,
    required this.goNext,
    required this.isFromOnboarding,
  });

  @override
  State<MPFoundDevices> createState() => _MPFoundDevicesState();
}

class _MPFoundDevicesState extends State<MPFoundDevices> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final deviceProvider = context.read<DeviceProvider>();
        final finderProvider = context.read<MPDeviceFinderProvider>();

        // 设置 Provider 依赖
        finderProvider.setProviders(
          deviceProvider: deviceProvider,
        );

        // 如果设备已连接，刷新设备信息
        if (deviceProvider.isConnected && deviceProvider.connectedDevice != null) {
          // Provider 已经在 setProviders 中初始化了连接状态
          // 这里只需要刷新设备信息
          try {
            final deviceId = deviceProvider.connectedDevice!.id;
            final connection =
                await ServiceManager.instance().device.ensureConnection(deviceId) as NoteDeviceConnection?;
            if (connection != null) {
              // 直接通过 finderProvider 查询设备信息
              await finderProvider.queryDeviceInfo(connection);
            } else {
              // 连接失败，使用上次的信息
              finderProvider.loadCachedDeviceInfo();
              finderProvider.syncFromDeviceProvider();
            }
          } catch (e) {
            debugPrint('Error refreshing device info, using cached: $e');
            // 获取失败，使用上次的信息
            finderProvider.loadCachedDeviceInfo();
            finderProvider.syncFromDeviceProvider();
          }
        } else {
          // 开始扫描并自动连接
          await finderProvider.startScanAndAutoConnect();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MPDeviceFinderProvider, DeviceProvider>(
      builder: (context, finderProvider, deviceProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: finderProvider.isConnected
                  ? _buildConnected(finderProvider, deviceProvider)
                  : _buildSearching(context, finderProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearching(BuildContext context, MPDeviceFinderProvider provider) {
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
          Center(
            child: MPAnimatedDotsText(
              baseText: provider.connectionStatusText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              provider.isConnecting ? '正在连接设备，请稍候...' : '请确保设备已开启并在附近',
              style: const TextStyle(
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          SizedBox(height: 12),
          _MPTipRow(index: 1, text: '确保设备电量充足'),
          SizedBox(height: 8),
          _MPTipRow(index: 2, text: '将设备靠近手机'),
          SizedBox(height: 8),
          _MPTipRow(index: 3, text: '首次连接需要在设备上确认配对'),
        ],
      ),
    );
  }

  Widget _buildConnected(MPDeviceFinderProvider finderProvider, DeviceProvider deviceProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // 设备图片
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4A4A4A),
                      Color(0xFF2C2C2C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(80),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 状态指示器行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusBadge(
                icon: Icons.battery_charging_full,
                text: finderProvider.batteryPercentage >= 0 ? '${finderProvider.batteryPercentage}%' : '--',
                color: const Color(0xFF34C759),
              ),
              const SizedBox(width: 16),
              _buildStatusBadge(
                icon: Icons.bluetooth_connected,
                text: '',
                color: const Color(0xFF007AFF),
              ),
              const SizedBox(width: 2),
              _buildStatusBadge(
                icon: Icons.signal_cellular_alt,
                text: '',
                color: const Color(0xFF34C759),
              ),
              const SizedBox(width: 16),
              Text(
                finderProvider.version,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 固件更新提示
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update available',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pendant firmware ${deviceProvider.latestFirmwareVersion.isNotEmpty ? deviceProvider.latestFirmwareVersion : (finderProvider.hardwareRevision.isNotEmpty ? finderProvider.hardwareRevision : '1.1.20')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0x991D1D1F),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0x991D1D1F),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 设备信息卡片
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow('名称', finderProvider.deviceName.isNotEmpty ? finderProvider.deviceName : 'MemoPin'),
                const Divider(height: 24, color: Color(0xFFE5E5EA)),
                _buildInfoRow(
                    '序列号',
                    finderProvider.deviceId.isNotEmpty
                        ? finderProvider.deviceId
                        : 'MP202400${finderProvider.deviceId}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Data Sync 部分
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Sync',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.mail_outline,
                        color: Color(0xFF1D1D1F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data ready for upload',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      finderProvider.noteUsedKBTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0x991D1D1F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildMicrophoneGainCard(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        if (text.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  /// 构建麦克风增益卡片
  Widget _buildMicrophoneGainCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '麦克风增益',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          // 增益调节行
          GestureDetector(
            onTap: () {
              // TODO: 实现增益调节功能
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MicGainPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Color(0xFF007AFF),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '增益调节',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0x991D1D1F),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行组件
  /// 显示标签和值的水平布局
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0x991D1D1F),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1D1F),
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
