import 'package:flutter/material.dart';

enum NoteType { normal, rain }

class Note {
  final double x; // 0~512
  final int bar;
  final int beatNum;
  final int denom;
  final NoteType type;
  final int? endBar;
  final int? endBeatNum;
  final int? endDenom;

  Note({
    required this.x,
    required this.bar,
    required this.beatNum,
    required this.denom,
    required this.type,
    this.endBar,
    this.endBeatNum,
    this.endDenom,
  });

  double get y => (bar + beatNum / denom) * 1280.0;
  double? get endY => (endBar != null && endBeatNum != null && endDenom != null)
      ? (endBar! + endBeatNum! / endDenom!) * 1280.0
      : null;
  List<int> get beat => [bar, beatNum, denom];
}

class EditorCanvas extends StatelessWidget {
  final List<Note> notes;
  final double editorWidth;
  final double scrollOffset;
  final double canvasHeight;
  final double totalHeight;

  const EditorCanvas({
    super.key,
    required this.notes,
    required this.editorWidth,
    required this.scrollOffset,
    required this.canvasHeight,
    required this.totalHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(editorWidth, canvasHeight),
      painter: _EditorPainter(
        notes: notes,
        scrollOffset: scrollOffset,
        canvasWidth: editorWidth,
        canvasHeight: canvasHeight,
      ),
    );
  }
}

class _EditorPainter extends CustomPainter {
  final List<Note> notes;
  final double scrollOffset;
  final double canvasWidth;
  final double canvasHeight;

  _EditorPainter({
    required this.notes,
    required this.scrollOffset,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 绘制分割线（每1280像素为一个小节）
    final barLinePaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 2;
    for (double y = -scrollOffset % 1280; y < canvasHeight; y += 1280) {
      canvas.drawLine(Offset(0, y), Offset(canvasWidth, y), barLinePaint);
    }

    // 绘制音符
    for (final note in notes) {
      final double x = note.x / 512.0 * canvasWidth;
      final double y = note.y - scrollOffset;
      if (y < -100 || y > canvasHeight + 100) continue; // 可见区域外不渲染

      if (note.type == NoteType.normal) {
        // 普通音符
        canvas.drawCircle(Offset(x, y), 10, Paint()..color = Colors.blue);
      } else if (note.type == NoteType.rain && note.endY != null) {
        final double endY = note.endY! - scrollOffset;
        canvas.drawRect(
          Rect.fromLTRB(x - 8, y, x + 8, endY),
          Paint()..color = Colors.green.withOpacity(0.7),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}