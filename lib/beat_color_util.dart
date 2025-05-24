import 'package:flutter/material.dart';

Color getNoteColorByDivide(int divide) {
  switch (divide) {
    case 1:
      return Colors.red;
    case 2:
      return Colors.cyan;
    case 3:
    case 6:
    case 12:
    case 24:
      return Colors.green;
    case 4:
      return Colors.purple;
    case 8:
      return Colors.yellow;
    case 16:
    case 32:
      return Colors.yellow;
    default:
      // 其它分度可自定义，默认紫色
      return Colors.purple;
  }
}