import 'package:flutter/material.dart';

const Map<String, Color> beatColorMap = {
  "1/1": Colors.red,
  "1/2": Colors.cyan,
  "1/3": Colors.green,
  "1/4": Colors.purple,
  "1/6": Colors.green,
  "1/8": Colors.yellow,
  "1/12": Colors.green,
  "1/16": Colors.yellow,
  "1/24": Colors.green,
  "1/32": Colors.yellow,
};

const Color rainNoteColor = Colors.cyan;

String getBeatString(int xDiv) {
  switch (xDiv) {
    case 1:
      return "1/1";
    case 2:
      return "1/2";
    case 3:
      return "1/3";
    case 4:
      return "1/4";
    case 6:
      return "1/6";
    case 8:
      return "1/8";
    case 12:
      return "1/12";
    case 16:
      return "1/16";
    case 24:
      return "1/24";
    case 32:
      return "1/32";
    default:
      return "1/$xDiv";
  }
}

Color getColorForBeat(String beat) => beatColorMap[beat] ?? Colors.purple;