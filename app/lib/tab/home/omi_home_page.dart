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
        data: MPTristatePageData(
          onButtonPressed: () {
            setState(() {
              if (_type == MPTristateType.noNetwork) {
                _type = MPTristateType.empty;
              } else if (_type == MPTristateType.empty) {
                _type = MPTristateType.noNetwork;
              } else if (_type == MPTristateType.error) {
                _type = MPTristateType.noNetwork;
              }
            });
          },
        ),
      ),
  );
 }
}