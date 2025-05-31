import 'package:flutter/material.dart';
import 'editor_canvas.dart';

class DensityBar extends StatelessWidget {
  final List<Note> notes;
  final int barCount;
  final double width;
  final double height;

  const DensityBar({
    super.key,
    required this.notes,
    required this.barCount,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _DensityBarPainter(notes: notes, barCount: barCount),
      ),
    );
  }
}

class _DensityBarPainter extends CustomPainter {
  final List<Note> notes;
  final int barCount;

  _DensityBarPainter({required this.notes, required this.barCount});

  @override
  void paint(Canvas canvas, Size size) {
    double barHeight = size.height / barCount;
    List<int> density = List.filled(barCount, 0);
    for (final n in notes) {
      if (n.bar < barCount && n.bar >= 0) density[n.bar]++;
    }
    int maxDensity = density.fold(1, (a, b) => a > b ? a : b);

    for (int i = 0; i < barCount; i++) {
      double y = size.height - (i + 1) * barHeight;
      double barW = size.width * density[i] / (maxDensity == 0 ? 1 : maxDensity);
      final paint = Paint()..color = Colors.orange;
      canvas.drawRect(Rect.fromLTWH(0, y, barW, barHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}