import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:omi/providers/device_provider.dart';

/// MemoPin设置页面
/// 显示设备详细信息、固件更新、数据同步和蓝牙调试等功能
class MemoPinSettingPage extends StatelessWidget {
  const MemoPinSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D1D1F)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MemoPin设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // 设备图片
                _buildDeviceImage(),
                const SizedBox(height: 24),
                // 状态指示器行
                _buildStatusRow(deviceProvider),
                const SizedBox(height: 24),
                // 固件更新提示
                _buildFirmwareUpdateCard(context, deviceProvider),
                const SizedBox(height: 16),
                // 设备信息卡片
                _buildDeviceInfoCard(deviceProvider),
                const SizedBox(height: 16),
                // Data Sync 部分
                _buildDataSyncCard(),
                const SizedBox(height: 16),
                // 蓝牙调试
                _buildMicrophoneGainCard(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建设备图片
  Widget _buildDeviceImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
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
    );
  }

  /// 构建状态指示器行
  Widget _buildStatusRow(DeviceProvider deviceProvider) {
    final battery = deviceProvider.batteryLevel;
    final firmwareVersion = deviceProvider.currentFirmwareVersion;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusBadge(
          icon: Icons.battery_charging_full,
          text: battery > 0 ? '$battery%' : '93%',
          color: const Color(0xFF34C759),
        ),
        const SizedBox(width: 16),
        _buildStatusBadge(
          icon: Icons.bluetooth_connected,
          text: '',
          color: const Color(0xFF007AFF),
        ),
        const SizedBox(width: 16),
        _buildStatusBadge(
          icon: Icons.signal_cellular_alt,
          text: '',
          color: const Color(0xFF34C759),
        ),
        const SizedBox(width: 16),
        Text(
          firmwareVersion != 'Unknown' ? 'v$firmwareVersion' : 'v1.1.11',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }

  /// 构建状态徽章
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

  /// 构建固件更新卡片
  Widget _buildFirmwareUpdateCard(BuildContext context, DeviceProvider deviceProvider) {
    // For testing, always show the card
    // final hasUpdate = deviceProvider.havingNewFirmware;
    final hasUpdate = true; // Always show for testing
    final latestVersion = deviceProvider.latestFirmwareVersion.isNotEmpty 
        ? deviceProvider.latestFirmwareVersion 
        : '1.1.20'; // Default version for testing
    
    if (!hasUpdate) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: () {
        deviceProvider.showFirmwareUpdateDialog(context);
      },
      child: Container(
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
                  const Text(
                    'Update available',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pendant firmware $latestVersion',
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
    );
  }

  /// 构建设备信息卡片
  Widget _buildDeviceInfoCard(DeviceProvider deviceProvider) {
    final deviceName = deviceProvider.connectedDevice?.name ?? 'MemoPin';
    final deviceId = deviceProvider.connectedDevice?.id ?? '';
    final serialNumber = deviceId.length >= 4
        ? 'MP202400${deviceId.substring(deviceId.length - 4)}'
        : 'MP2024001234';
    
    return Container(
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
          _buildInfoRow('名称', deviceName),
          const Divider(height: 24, color: Color(0xFFE5E5EA)),
          _buildInfoRow('序列号', serialNumber),
        ],
      ),
    );
  }

  /// 构建数据同步卡片
  Widget _buildDataSyncCard() {
    return Container(
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
              const Text(
                '0 KB',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0x991D1D1F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建麦克风增益卡片
  Widget _buildMicrophoneGainCard() {
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
