import 'package:flutter/material.dart';
import 'package:omi/common/mp_tristate_page.dart';

class OmiHomePage extends StatefulWidget {
 const OmiHomePage({super.key});
 @override
 createState() => _OmiHomePageState();
}

class _OmiHomePageState extends State<OmiHomePage> {
  MPTristateType _type = MPTristateType.noNetwork;

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   appBar: AppBar(
    title: Text('omi'),
   ),
      body: MPTristatePage(
        type: _type,
        noNetworkData: MPTristatePageData(
          icon: const Icon(Icons.wifi_off_outlined, size: 48),
          title: '无网络',
          description: '请检查网络连接后重试',
          showButton: true,
          buttonText: '重试',
          onButtonPressed: () {
            setState(() {
              _type = MPTristateType.empty;
            });
          },
        ),
        emptyData: MPTristatePageData(
          icon: const Icon(Icons.inbox_outlined, size: 48),
          title: '暂无内容',
          description: '当前没有数据',
          showButton: true,
          buttonText: '返回',
          onButtonPressed: () {
            setState(() {
              _type = MPTristateType.noNetwork;
            });
          },
        ),
        errorData: MPTristatePageData(
          icon: const Icon(Icons.error_outline, size: 48),
          title: '出错了',
          description: '请稍后重试',
          showButton: true,
          buttonText: '再试一次',
          onButtonPressed: () {
            setState(() {
              _type = MPTristateType.noNetwork;
            });
          },
        ),
      ),
  );
 }
}