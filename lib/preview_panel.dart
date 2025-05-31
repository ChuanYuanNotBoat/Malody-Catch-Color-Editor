import 'package:flutter/material.dart';
import 'editor_canvas.dart';

// 预览面板，显示分度上色
class PreviewPanel extends StatelessWidget {
  final List<Note> notes;
  final int currentBar;
  final int previewRangeBars;
  final int barCount;
  final double width;
  final double height;

  const PreviewPanel({
    Key? key,
    required this.notes,
    required this.currentBar,
    required this.previewRangeBars,
    required this.barCount,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _PreviewPainter(
        notes: notes,
        currentBar: currentBar,
        previewRangeBars: previewRangeBars,
        barCount: barCount,
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

  Color getColorForBeatDenom(int bar, int beatNum, int denom) {
    // 跟editor_canvas.dart保持一致或更细分
    if (beatNum == 0) return Colors.red;
    if (denom == 2) return Colors.blue;
    if (denom == 4) return Colors.green;
    return Colors.grey;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double barHeight = size.height / barCount;
    for (var note in notes) {
      final bar = note.bar;
      // 仅显示当前预览范围
      if (bar < currentBar - previewRangeBars || bar > currentBar + previewRangeBars) continue;
      final y = (bar - currentBar + previewRangeBars) * barHeight;
      final color = getColorForBeatDenom(note.bar, note.beatNum, note.denom);
      canvas.drawCircle(Offset(size.width / 2, y), 5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}