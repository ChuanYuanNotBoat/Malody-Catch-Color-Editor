import 'package:flutter/material.dart';
import 'beat_color_util.dart';
import 'divide_adjust_dialog.dart';

class DividePreviewBar extends StatelessWidget {
  final int xDivisions;
  final List<double>? customDivides;
  final double height;
  final Function(List<double>)? onCustomDividesChanged;
  final String beatStr;

  const DividePreviewBar({
    super.key,
    required this.xDivisions,
    this.customDivides,
    this.height = 32,
    this.onCustomDividesChanged,
    required this.beatStr,
  });

  @override
  Widget build(BuildContext context) {
    final divides = customDivides ??
        List.generate(xDivisions + 1, (i) => 512.0 * i / xDivisions);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: const Border(top: BorderSide(color: Colors.blueGrey)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final color = getColorForBeat(beatStr);
          return Stack(
            children: [
              ...divides.map((x) {
                final dx = (x / 512) * width;
                return Positioned(
                  left: dx - 1,
                  top: 0,
                  width: 2,
                  height: height,
                  child: Container(color: color.withOpacity(0.6)),
                );
              }).toList(),
              if (onCustomDividesChanged != null)
                Positioned(
                  right: 8,
                  top: 4,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    tooltip: "自定义分度",
                    onPressed: () async {
                      final result = await showDialog<List<double>>(
                        context: context,
                        builder: (ctx) => DivideAdjustDialog(
                          initialDivides: divides,
                        ),
                      );
                      if (result != null) {
                        onCustomDividesChanged!(result);
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}