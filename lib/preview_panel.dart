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
    this.previewRangeBars = 4,
    required this.barCount,
    this.width = 40,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    int startBar = (currentBar - previewRangeBars).clamp(0, barCount - 1);
    int endBar = (currentBar + previewRangeBars).clamp(0, barCount - 1);
    List<Note> showNotes = notes.where((n) {
      int nbar = (n.y ~/ 1280);
      return nbar >= startBar && nbar <= endBar;
    }).toList();

    return Container(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PreviewPainter(
          showNotes: showNotes,
          startBar: startBar,
          endBar: endBar,
          totalBar: barCount,
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final List<Note> showNotes;
  final int startBar;
  final int endBar;
  final int totalBar;

  _PreviewPainter({
    required this.showNotes,
    required this.startBar,
    required this.endBar,
    required this.totalBar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int barRange = endBar - startBar + 1;
    for (final note in showNotes) {
      int nbar = (note.y ~/ 1280);
      double y = size.height -
          ((nbar - startBar) / (barRange == 0 ? 1 : barRange)) * size.height;
      double x = note.x / 512.0 * size.width;
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = getNoteColor(note));
    }
    // 中心线
    double centerY = size.height - ((0.5) * size.height);
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}