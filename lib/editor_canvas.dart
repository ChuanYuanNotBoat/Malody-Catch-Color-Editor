import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'beat_color_util.dart';

enum NoteType { normal, rain }

class Note {
  double x; // 0-512
  double y; // 起始y
  double? endY; // rain音符才有
  NoteType type;
  String beat; // 如"1/4"
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

class EditorCanvas extends StatefulWidget {
  final List<Note> notes;
  final double editorWidth;
  final double scrollOffset;
  final double canvasHeight;
  final double totalHeight;
  final NoteType selectedType;
  final int xDivisions;
  final bool snapToXDivision;
  final List<double>? customDivides;
  final String beatStr;
  final Function(Note) onAddNote;
  final Function(List<Note>) onNotesChanged;
  final Function(List<int>) onSelectNotes;
  final Function(void Function()) onRegisterDeleteHandler;

  const EditorCanvas({
    super.key,
    required this.notes,
    required this.editorWidth,
    required this.scrollOffset,
    required this.canvasHeight,
    required this.totalHeight,
    required this.selectedType,
    required this.xDivisions,
    required this.snapToXDivision,
    required this.customDivides,
    required this.beatStr,
    required this.onAddNote,
    required this.onNotesChanged,
    required this.onSelectNotes,
    required this.onRegisterDeleteHandler,
  });

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  int? draggingIndex;
  Offset? dragOffset;
  Rect? selectionRect;
  List<int> selectedIndices = [];
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.onRegisterDeleteHandler(_handleDelete);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  double _screenToX(double dx, double width) => (dx / width) * 512.0;
  double _screenToY(double dy, double height) => dy + widget.scrollOffset;
  double _xToScreen(double x, double width) => (x / 512.0) * width;
  double _yToScreen(double y, double height) => y - widget.scrollOffset;

  double _snapX(double x) {
    if (widget.customDivides != null && widget.customDivides!.isNotEmpty) {
      return widget.customDivides!.reduce((a, b) => (x - a).abs() < (x - b).abs() ? a : b);
    }
    return ((x / (512 / widget.xDivisions)).round()) * (512 / widget.xDivisions);
  }

  void _handleDelete() {
    final newNotes = <Note>[];
    for (int i = 0; i < widget.notes.length; ++i) {
      if (!selectedIndices.contains(i)) newNotes.add(widget.notes[i].clone());
    }
    selectedIndices = [];
    widget.onNotesChanged(newNotes);
    widget.onSelectNotes(selectedIndices);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKey: (node, event) {
        if ((event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace) &&
            event is RawKeyDownEvent) {
          _handleDelete();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final divides = widget.customDivides ??
            List.generate(widget.xDivisions + 1, (i) => 512.0 * i / widget.xDivisions);

        final color = getColorForBeat(widget.beatStr);

        return GestureDetector(
          onTapDown: (detail) {
            final local = detail.localPosition;
            double x = _screenToX(local.dx, width);
            double y = _screenToY(local.dy, height);
            if (widget.snapToXDivision) x = _snapX(x);

            int? hitIdx;
            for (int i = 0; i < widget.notes.length; ++i) {
              final note = widget.notes[i];
              double noteX = _xToScreen(note.x, width);
              double noteY = _yToScreen(note.y, height);
              if (note.type == NoteType.rain && note.endY != null) {
                double noteY2 = _yToScreen(note.endY!, height);
                Rect rect = Rect.fromPoints(
                  Offset(noteX - 8, noteY),
                  Offset(noteX + 8, noteY2),
                );
                if (rect.contains(local)) {
                  hitIdx = i;
                  break;
                }
              } else {
                if ((Offset(noteX, noteY) - local).distance < 16) {
                  hitIdx = i;
                  break;
                }
              }
            }

            if (hitIdx != null) {
              selectedIndices = [hitIdx];
              widget.onSelectNotes(selectedIndices);
              setState(() {});
            } else {
              widget.onAddNote(Note(
                x: x,
                y: y,
                type: widget.selectedType,
                beat: widget.beatStr,
              ));
              selectedIndices = [];
              widget.onSelectNotes(selectedIndices);
              setState(() {});
            }
          },
          onPanStart: (detail) {
            final local = detail.localPosition;
            for (int i = 0; i < widget.notes.length; ++i) {
              final note = widget.notes[i];
              double noteX = _xToScreen(note.x, width);
              double noteY = _yToScreen(note.y, height);
              if (note.type == NoteType.rain && note.endY != null) {
                double noteY2 = _yToScreen(note.endY!, height);
                Rect rect = Rect.fromPoints(
                  Offset(noteX - 8, noteY),
                  Offset(noteX + 8, noteY2),
                );
                if (rect.contains(local)) {
                  draggingIndex = i;
                  dragOffset = local - Offset(noteX, noteY);
                  return;
                }
              } else {
                if ((Offset(noteX, noteY) - local).distance < 16) {
                  draggingIndex = i;
                  dragOffset = local - Offset(noteX, noteY);
                  return;
                }
              }
            }
            selectionRect = Rect.fromLTWH(local.dx, local.dy, 0, 0);
            setState(() {});
          },
          onPanUpdate: (detail) {
            final local = detail.localPosition;
            if (draggingIndex != null) {
              double x = _screenToX(local.dx - (dragOffset?.dx ?? 0), width);
              double y = _screenToY(local.dy - (dragOffset?.dy ?? 0), height);
              if (widget.snapToXDivision) x = _snapX(x);
              final notes = widget.notes.map((e) => e.clone()).toList();
              if (notes[draggingIndex!].type == NoteType.rain && notes[draggingIndex!].endY != null) {
                double deltaY = y - notes[draggingIndex!].y;
                double? oldEndY = notes[draggingIndex!].endY;
                notes[draggingIndex!] = notes[draggingIndex!]
                  ..x = x.clamp(0, 512)
                  ..y = y.clamp(0, height.toDouble())
                  ..endY = (oldEndY! + deltaY).clamp(0, height.toDouble());
              } else {
                notes[draggingIndex!] = notes[draggingIndex!]
                  ..x = x.clamp(0, 512)
                  ..y = y.clamp(0, height.toDouble());
              }
              widget.onNotesChanged(notes);
            } else if (selectionRect != null) {
              final start = Offset(selectionRect!.left, selectionRect!.top);
              final rect = Rect.fromPoints(start, local);
              selectionRect = rect;
              final hitIdxs = <int>[];
              for (int i = 0; i < widget.notes.length; ++i) {
                final note = widget.notes[i];
                double noteX = _xToScreen(note.x, width);
                double noteY = _yToScreen(note.y, height);
                if (note.type == NoteType.rain && note.endY != null) {
                  double noteY2 = _yToScreen(note.endY!, height);
                  Rect rectNote = Rect.fromPoints(
                    Offset(noteX - 8, noteY),
                    Offset(noteX + 8, noteY2),
                  );
                  if (rect.overlaps(rectNote)) hitIdxs.add(i);
                } else {
                  if (rect.contains(Offset(noteX, noteY))) hitIdxs.add(i);
                }
              }
              selectedIndices = hitIdxs;
              widget.onSelectNotes(selectedIndices);
              setState(() {});
            }
          },
          onPanEnd: (detail) {
            draggingIndex = null;
            dragOffset = null;
            selectionRect = null;
            setState(() {});
          },
          child: CustomPaint(
            size: Size(width, height),
            painter: _ChartPainter(
              notes: widget.notes,
              color: color,
              divides: divides,
              selectedIndices: selectedIndices,
              selectionRect: selectionRect,
              scrollOffset: widget.scrollOffset,
              canvasHeight: widget.canvasHeight,
              totalHeight: widget.totalHeight,
              editorWidth: widget.editorWidth,
            ),
          ),
        );
      }),
    );
  }
}

Color getNoteColor(Note note) {
  if (note.type == NoteType.rain) {
    return rainNoteColor;
  }
  return getColorForBeat(note.beat);
}

class _ChartPainter extends CustomPainter {
  final List<Note> notes;
  final Color color;
  final List<double> divides;
  final List<int> selectedIndices;
  final Rect? selectionRect;
  final double scrollOffset;
  final double canvasHeight;
  final double totalHeight;
  final double editorWidth;
  _ChartPainter({
    required this.notes,
    required this.color,
    required this.divides,
    required this.selectedIndices,
    required this.selectionRect,
    required this.scrollOffset,
    required this.canvasHeight,
    required this.totalHeight,
    required this.editorWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // y轴分度线（主/副色）
    double barHeight = 1280.0;
    int barCount = (totalHeight ~/ barHeight);
    for (int i = 0; i <= barCount; ++i) {
      double y = i * barHeight - scrollOffset;
      if (y >= 0 && y <= canvasHeight) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = (i % 4 == 0)
                ? Colors.white
                : Colors.deepPurple.withOpacity(0.6)
            ..strokeWidth = (i % 4 == 0) ? 3 : 1,
        );
      }
    }
    // x轴分度线（灰色）
    for (final x in divides) {
      double dx = (x / 512.0) * size.width;
      canvas.drawLine(
        Offset(dx, 0),
        Offset(dx, canvasHeight),
        Paint()
          ..color = Colors.grey.withOpacity(0.4)
          ..strokeWidth = 1,
      );
    }
    // x=0, x=512加粗边框竖线
    Paint borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4;
    canvas.drawLine(Offset(0, 0), Offset(0, canvasHeight), borderPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, canvasHeight), borderPaint);

    for (int i = 0; i < notes.length; ++i) {
      final note = notes[i];
      final notePaint = Paint()
        ..color = getNoteColor(note)
        ..style = PaintingStyle.fill;
      final double x = (note.x / 512.0) * size.width;
      final double y = note.y - scrollOffset;
      if (note.type == NoteType.rain && note.endY != null) {
        final double y2 = note.endY! - scrollOffset;
        Rect rainRect = Rect.fromPoints(
          Offset(x - 6, y),
          Offset(x + 6, y2),
        );
        canvas.drawRect(rainRect, notePaint);
        if (selectedIndices.contains(i)) {
          canvas.drawRect(rainRect.inflate(2), Paint()..color = Colors.redAccent.withOpacity(0.2));
          canvas.drawRect(rainRect, Paint()
            ..color = Colors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
        }
      } else {
        if (selectedIndices.contains(i)) {
          canvas.drawCircle(Offset(x, y), 14, Paint()..color = Colors.redAccent.withOpacity(0.2));
          canvas.drawCircle(Offset(x, y), 10, notePaint..color = notePaint.color.withOpacity(1.0));
          canvas.drawCircle(Offset(x, y), 12, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth=2);
        } else {
          canvas.drawCircle(Offset(x, y), 10, notePaint);
        }
      }
    }

    if (selectionRect != null) {
      final rect = selectionRect!;
      canvas.drawRect(
        rect,
        Paint()..color = Colors.blue.withOpacity(0.1),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}