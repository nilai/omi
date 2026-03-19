
import 'package:flutter/material.dart';

import '../utils/omi_color_utils.dart';
import '../utils/omi_font_utils.dart';
import '../utils/omi_textstyle.dart';


enum OmiButtonIconAlignment {
  /// icon居左
  left,

  /// icon居右
  right,
}


class OmiButton extends StatefulWidget {
  const OmiButton({
    super.key,
    this.isHighLight = true,
    this.bgColor,
    this.bgHighlightedColor,
    this.bgDisableColor,
    this.borderColor,
    this.borderHighlightedColor,
    this.textColor,
    required this.text,
    this.textFontSize,
    this.textFontWeight,
    this.iconData,
    this.iconColor,
    this.icon,
    this.iconAlignment = OmiButtonIconAlignment.left,
    this.borderRadius,
    this.width,
    this.height = 36,
    this.iconSize = 16.0,
    this.onPressed,
  });


  /// 按钮是否有点击效果， status=disable的时候不生效
  final bool isHighLight;

  /// 背景颜色
  final Color? bgColor;

  /// 背景点击高亮颜色
  final Color? bgHighlightedColor;

  /// 背景禁用颜色
  final Color? bgDisableColor;

  /// 描边颜色
  final Color? borderColor;

  /// 描边点击高亮颜色
  final Color? borderHighlightedColor;

  /// 文字颜色
  final Color? textColor;

  /// 文字
  final String text;

  /// 文字大小
  final double? textFontSize;

  /// 文字粗细
  final FontWeight? textFontWeight;

  /// 图标
  final IconData? iconData;

  /// 图标颜色（iconFont时生效）
  final Color? iconColor;

  /// 图标
  final Image? icon;

  /// 图标对齐方式
  final OmiButtonIconAlignment iconAlignment;

  /// 按钮圆角
  final BorderRadius? borderRadius;

  /// 宽度 设置成double.infinity时，跟父视图最大宽度一样
  final double? width;

  final double? height;
  /// 点击事件
  final VoidCallback? onPressed;

 final double? iconSize;

  @override
  createState() => _OmiButtonState();
}

class _OmiButtonState extends State<OmiButton> {
  bool _highlighted = false;

  @override
  void initState() {
    super.initState();
    _highlighted = false;
  }

  void handleTapDown(TapDownDetails details) {

      setState(() {
        _highlighted = true;
      });

  }

  void handleTapUp(TapUpDetails details) {
      setState(() {
        _highlighted = false;
      });
  }

  void handleTapCancel() {
      setState(() {
        _highlighted = false;
      });

  }

  void handleTap() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _buildChildWidget(),
    );
  }

  Widget _buildChildWidget() {
    if (widget.width != null) {
      if (widget.width == double.infinity) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: _buildCustomButton(),
            );
          },
        );
      } else {
        return SizedBox(
          width: widget.width!,
          child: _buildCustomButton(),
        );
      }
    }
    return _buildCustomButton();
  }

  Widget _buildCustomButton() {
    double buttonHeight = widget.height ?? 40;
    return GestureDetector(
        onTap: handleTap,
        onTapCancel: handleTapCancel,
        onTapDown: handleTapDown,
        onTapUp: handleTapUp,
        child: SizedBox(
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: null,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(widget.bgColor),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shadowColor: WidgetStateProperty.all(Colors.transparent),
              elevation: WidgetStateProperty.all(0),
              minimumSize: WidgetStateProperty.all(
                  Size(kButtonLeftRightPadding * 2, buttonHeight)),
              maximumSize: WidgetStateProperty.all(
                  Size(widget.width ?? double.infinity, buttonHeight)),
              iconSize: WidgetStateProperty.all(widget.iconSize),
              padding: WidgetStateProperty.all(
                  EdgeInsets.only(
                      left: kButtonLeftRightPadding, right: kButtonLeftRightPadding)),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(10), // 设置圆角半径
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: (widget.iconData == null && widget.icon == null)
                  ? [_buildText()]
                  : (widget.iconAlignment == OmiButtonIconAlignment.left
                  ? [
                _buildIcon(),
                _buildSizeBox(),
                _buildText(),
              ]
                  : [
                _buildText(),
                _buildSizeBox(),
                _buildIcon(),
              ]),
            ),
          ),
        )
    );
  }


  Widget _buildIcon() {
    if (widget.iconData != null) {
      return Icon(
        widget.iconData,
        color: widget.iconColor ?? widget.textColor,
        size: widget.iconSize,
      );
    }
    return SizedBox(
      width: widget.iconSize,
      height: widget.iconSize,
      child: widget.icon!,
    );
  }

  Widget _buildSizeBox() {
    return SizedBox(
      width: 4,
    );
  }

  Widget _buildText() {
    return Flexible(
      child: Text(
        textAlign: TextAlign.center,
        widget.text,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        style: OmiTextStyle.create(
            color: widget.textColor ?? mainTextColor,
            fontSize: widget.textFontSize ?? OmiFontSize.mainTextFontSize,
            fontWeight: widget.textFontWeight ?? OmiFontWeight.medium,
            leadingDistribution: TextLeadingDistribution.even
        ),
      ),
    );
  }

  static double kButtonLeftRightPadding = 16.0;
}
