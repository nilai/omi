
import 'dart:io';
import 'dart:ui';


/// 字体大小
class OmiFontSize {
  /// 规范字体
  static double get t1_10 => 10;
  static double get t2_11 => 11;
  static double get t3_12 => 12;
  static double get t4_13 => 13;
  static double get t5_14 => 14;
  static double get t6_15 => 15;
  static double get t7_16 => 16;
  static double get t8_17 => 17;
  static double get t9_18 => 18;
  static double get t11_20 => 20;
  static double get t13_22 => 22;
  static double get t16_25 => 25;
  static double get t21_30 => 30;
  static double get t33_42 => 42;

  /// 主标题字号
  static double mainTextFontSize = 16.0;
  ///次标题字号
  static double secondTextFontSize = 14.0;
  /// 小标题字号
  static double smallTextFontSize = 12.0;
}

class OmiFontWeight {
  static FontWeight regular = FontWeight.w400;
  static FontWeight get medium =>
      Platform.isIOS ? FontWeight.w500 : FontWeight.w600;
  static FontWeight get bold =>
      Platform.isIOS ? FontWeight.w600 : FontWeight.w700;
}