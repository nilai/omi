
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 文本样式
class OmiTextStyle {
  /// Public
  /// 快速创建，
  /// height：行高
  /// fontWeight：默认 regular
  /// fontFamily：默认 iOS：PingFang SC， android以及鸿蒙：跟随系统
  static TextStyle create({
    required Color color,
    double? fontSize = 13,
    FontWeight? fontWeight,
    double? height,
    String? fontFamily,
    bool inherit = true,
    Color? backgroundColor,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    ui.TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    TextOverflow? overflow,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      fontFamily: fontFamily,
      inherit: inherit,
      backgroundColor: backgroundColor,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      leadingDistribution: leadingDistribution,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      overflow: overflow,
    );
  }
}
