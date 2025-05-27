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

  const EditorCanvas({
    super.key,
    required this.notes,
    required this.division,
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
        division: division,
        canvasSize: Size(editorWidth, canvasHeight),
        scrollOffset: scrollOffset,
      ),
    );
  }
}

/// 假设 beat 格式为 [measure, offset, division] 或 "1/4" 字符串
double beatToY(dynamic beat, int division, double pxPerBeat) {
  if (beat is List && beat.length == 3) {
    // Malody格式：[小节, 分子, 分母]
    int bar = beat[0] is int ? beat[0] : int.tryParse(beat[0].toString()) ?? 0;
    int num = beat[1] is int ? beat[1] : int.tryParse(beat[1].toString()) ?? 0;
    int denom = beat[2] is int ? beat[2] : int.tryParse(beat[2].toString()) ?? division;
    double beatInBar = num / denom;
    double totalBeats = bar * 4 + beatInBar * 4; // 一小节4拍
    return totalBeats * pxPerBeat;
  } else if (beat is String && beat.contains('/')) {
    int denom = int.tryParse(beat.split('/').last) ?? division;
    double totalBeats = 4.0 * (1.0 / denom);
    return totalBeats * pxPerBeat;
  }
  return 0;
}

Color getColorForBeatDenom(dynamic beat) {
  int denom = 4;
  if (beat is List && beat.length == 3) {
    denom = beat[2] is int ? beat[2] : int.tryParse(beat[2].toString()) ?? 4;
  } else if (beat is String && beat.contains('/')) {
    denom = int.tryParse(beat.split('/').last) ?? 4;
  }
  switch (denom) {
    case 1: return const Color(0xFFFF0000);
    case 2: return const Color(0xFF00BFFF);
    case 3:
    case 6:
    case 12:
    case 24: return const Color(0xFF00CC66);
    case 4: return const Color(0xFFA020F0);
    case 8:
    case 16:
    case 32: return const Color(0xFFFFD700);
    default: return const Color(0xFFA020F0);
  }
}

class _EditorPainter extends CustomPainter {
  final List<Note> notes;
  final int division;
  final Size canvasSize;
  final double scrollOffset;
  _EditorPainter({
    required this.notes,
    required this.division,
    required this.canvasSize,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double pxPerBeat = 50.0;

    // 画布原点设顶端
    canvas.save();
    canvas.translate(0, 0);

    // 画分度线
    for (int i = 0; i < 256; ++i) {
      double y = i * pxPerBeat - scrollOffset;
      if (y < 0 || y > canvasSize.height) continue;
      canvas.drawLine(
        Offset(0, y),
        Offset(canvasSize.width, y),
        Paint()..color = Colors.grey.withOpacity(0.3),
      );
    }

    for (final note in notes) {
      double x = note.x / 512.0 * canvasSize.width;
      double y = beatToY(note.beat, division, pxPerBeat) - scrollOffset;
      if (note.type == NoteType.rain && note.endY != null) {
        double y2 = beatToY(note.endY, division, pxPerBeat) - scrollOffset;
        final rect = Rect.fromLTRB(0, min(y, y2), canvasSize.width, max(y, y2));
        canvas.drawRect(rect, Paint()..color = const Color(0x8842A5F5));
      } else {
        canvas.drawCircle(Offset(x, y), 10, Paint()..color = getColorForBeatDenom(note.beat));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}