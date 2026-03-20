
import 'package:flutter/material.dart';


///图片工具类
class OmiImageLoader {

  static Image localImg(
      String name,
      {
        double? scale,
        double? width,
        double? height,
        BoxFit? fit ,
        Alignment alignment = Alignment.center,
        Color? color,
      }
      ) {
    return Image.asset(
      name,
      height: height,
      width: width,
      fit: fit,
      alignment: alignment,
      scale: scale,
      color: color,
    );
  }
}

