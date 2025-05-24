import 'package:flutter/material.dart';
import 'beat_color_util.dart';

class DividePreviewBar extends StatelessWidget {
  final int beatsPerBar;
  final int divide;

  const DividePreviewBar({required this.beatsPerBar, required this.divide, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(beatsPerBar * divide, (i) {
        final color = getNoteColorByDivide(divide);
        return Expanded(
          child: Container(
            height: 8,
            color: color.withOpacity(i % divide == 0 ? 0.95 : 0.6),
          ),
        );
      }),
    );
  }
}