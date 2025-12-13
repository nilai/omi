// AI-generated START - 单态图加载组件
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 单态图加载组件
/// 用于显示加载状态的占位符效果
class MPSkeletonWidget extends StatelessWidget {
  /// 宽度，如果为 null 则占满父容器
  final double? width;

  /// 高度
  final double height;

  /// 圆角半径
  final double borderRadius;

  /// 基础颜色
  final Color baseColor;

  /// 高亮颜色
  final Color highlightColor;

  /// 外边距
  final EdgeInsets? margin;

  /// 内边距
  final EdgeInsets? padding;

  const MPSkeletonWidget({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.baseColor = const Color(0xFFE5E7EB),
    this.highlightColor = const Color(0xFFF3F4F6),
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}

/// 单态图列表组件
/// 用于显示多个单态图项
class MPSkeletonList extends StatelessWidget {
  /// 单态图数量
  final int itemCount;

  /// 每个单态图的高度
  final double itemHeight;

  /// 单态图之间的间距
  final double spacing;

  /// 外边距
  final EdgeInsets? margin;

  /// 圆角半径
  final double borderRadius;

  /// 基础颜色
  final Color baseColor;

  /// 高亮颜色
  final Color highlightColor;

  const MPSkeletonList({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80.0,
    this.spacing = 8.0,
    this.margin,
    this.borderRadius = 8.0,
    this.baseColor = const Color(0xFFE5E7EB),
    this.highlightColor = const Color(0xFFF3F4F6),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(
            bottom: index < itemCount - 1 ? spacing : 0,
          ),
          child: MPSkeletonWidget(
            height: itemHeight,
            borderRadius: borderRadius,
            baseColor: baseColor,
            highlightColor: highlightColor,
            margin: margin,
          ),
        ),
      ),
    );
  }
}
// AI-generated END - mp_skeleton_widget.dart
