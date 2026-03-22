import 'package:flutter/cupertino.dart';

class MPDeviceConnectionPage extends StatelessWidget {
  const MPDeviceConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Device Connection'),
      ),
      child: SafeArea(
        child: Center(
          child: Text('设备连接页占位，可接入蓝牙/Wi-Fi 配网逻辑。'),
        ),
      ),
    );
  }
}
