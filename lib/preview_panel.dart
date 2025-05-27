import 'package:flutter/material.dart';
import 'editor_canvas.dart';

class PreviewPanel extends StatelessWidget {
  final List<Note> notes;
  final int currentBar;
  final int previewRangeBars;
  final int barCount;
  final double width;
  final double height;

  const PreviewPanel({
    super.key,
    required this.notes,
    required this.currentBar,
    required this.previewRangeBars,
    required this.barCount,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black12,
      child: CustomPaint(
        painter: _PreviewPainter(
          notes: notes,
          currentBar: currentBar,
          previewRangeBars: previewRangeBars,
          barCount: barCount,
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final List<Note> notes;
  final int currentBar;
  final int previewRangeBars;
  final int barCount;

  _PreviewPainter({
    required this.notes,
    required this.currentBar,
    required this.previewRangeBars,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double totalHeight = size.height;
    final double barHeight = totalHeight / barCount;
    Paint barPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < barCount; ++i) {
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, i * barHeight, size.width, barHeight),
          barPaint,
        );
      }
    }
    // highlight current preview bars
    Paint curPaint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    for (int i = currentBar; i < currentBar + previewRangeBars && i < barCount; ++i) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * barHeight, size.width, barHeight),
        curPaint,
      );
    }
    // notes
    for (final note in notes) {
      double y = (note.y / (1280.0 * barCount)) * totalHeight;
      double x = (note.x / 512.0) * size.width;
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = getColorForBeatDenom(note.beat),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}