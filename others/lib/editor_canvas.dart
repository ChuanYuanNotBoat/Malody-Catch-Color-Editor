import 'package:flutter/material.dart';
import 'dart:math';

enum NoteType { normal, rain }

class Note {
  double x;
  double y;
  double? endY;
  NoteType type;
  dynamic beat;
  bool selected;

  Note({
    required this.x,
    required this.y,
    this.endY,
    required this.type,
    required this.beat,
    this.selected = false,
  });

  Note clone() => Note(
    x: x,
    y: y,
    endY: endY,
    type: type,
    beat: beat,
    selected: selected,
  );
}

class EditorCanvas extends StatelessWidget {
  final List<Note> notes;
  final int division;
  final double editorWidth;
  final double scrollOffset;
  final double canvasHeight;
  final double totalHeight;
  final double maxXValue; // 新增：最大 x 值，用于映射

  const EditorCanvas({
    super.key,
    required this.notes,
    required this.division,
    required this.editorWidth,
    required this.scrollOffset,
    required this.canvasHeight,
    required this.totalHeight,
    required this.maxXValue, // 新增参数
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(editorWidth, canvasHeight),
      painter: _EditorPainter(
        notes: notes,
        division: division,
        canvasSize: Size(editorWidth, canvasHeight),
        scrollOffset: scrollOffset,
        maxXValue: maxXValue, // 传递最大 x 值
      ),
    );
  }
}

class _EditorPainter extends CustomPainter {
  final List<Note> notes;
  final int division;
  final Size canvasSize;
  final double scrollOffset;
  final double maxXValue;

  _EditorPainter({
    required this.notes,
    required this.division,
    required this.canvasSize,
    required this.scrollOffset,
    required this.maxXValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 绘制网格
    for (int i = 0; i <= division; i++) {
      double x = (i / division) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 绘制音符
    for (final note in notes) {
      final double mappedX = (note.x / maxXValue) * size.width;
      final double mappedY = note.y - scrollOffset;
      canvas.drawCircle(Offset(mappedX, mappedY), 5, Paint()..color = Colors.blue);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}