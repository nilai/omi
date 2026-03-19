import 'package:flutter/material.dart';
import '../utils/omi_color_utils.dart';

class OmiHomePage extends StatefulWidget {
 const OmiHomePage({super.key});
 @override
 createState() => _OmiHomePageState();
}

class _OmiHomePageState extends State<OmiHomePage> {
 @override
 Widget build(BuildContext context) {
  return Scaffold(
   appBar: AppBar(
    title: Text('omi'),
   ),
   body: Center(
    child: Text('omi', style: TextStyle(color: mainTextColor)),
   ),
  );
 }
}