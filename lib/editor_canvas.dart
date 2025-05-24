import 'package:flutter/material.dart';
import 'beat_color_util.dart';
import 'package:flutter/gestures.dart';

enum NoteType { normal, rain }

class Note {
  double x;
  double y;
  NoteType type;
  String beat;
  bool selected;
  Note({
    required this.x,
    required this.y,
    required this.type,
    required this.beat,
    this.selected = false,
  });

  Note clone() => Note(
    x: x,
    y: y,
    type: type,
    beat: beat,
    selected: selected,
  );
}

class EditorCanvas extends StatefulWidget {
  final List<Note> notes;
  final NoteType selectedType;
  final int xDivisions;
  final bool snapToXDivision;
  final List<double>? customDivides;
  final String beatStr;
  final Function(Note) onAddNote;
  final Function(List<Note>) onNotesChanged;
  final Function(List<int>) onSelectNotes;
  final Function(void Function()) onRegisterDeleteHandler;
  final double zoomScale;
  final double playOffset;
  final bool isPlaying;
  final Function(double)? onScroll;
  final Function(double)? onSeek;
  final double totalHeight;

  const EditorCanvas({
    super.key,
    required this.notes,
    required this.selectedType,
    required this.xDivisions,
    required this.snapToXDivision,
    required this.customDivides,
    required this.beatStr,
    required this.onAddNote,
    required this.onNotesChanged,
    required this.onSelectNotes,
    required this.onRegisterDeleteHandler,
    this.zoomScale = 1.0,
    this.playOffset = 0.0,
    this.isPlaying = false,
    this.onScroll,
    this.onSeek,
    this.totalHeight = 40960,
  });

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late double _zoomScale;
  late double _lastPointerY;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.playOffset,
    );
    _zoomScale = widget.zoomScale;
    _scrollController.addListener(() {
      widget.onScroll?.call(_scrollController.offset);
    });
  }

  @override
  void didUpdateWidget(covariant EditorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.zoomScale != _zoomScale) {
      setState(() {
        _zoomScale = widget.zoomScale;
      });
    }
    if (widget.playOffset != _scrollController.offset) {
      _scrollController.jumpTo(widget.playOffset.clamp(0.0, widget.totalHeight));
    }
  }

  double _findNearestDivision(double offset) {
    double beat = 320 * _zoomScale;
    double div = (offset / beat).round() * beat;
    return div.clamp(0, widget.totalHeight - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          double next = (_scrollController.offset + e.scrollDelta.dy * 1.2).clamp(0, widget.totalHeight - 1);
          _scrollController.jumpTo(next);
          widget.onScroll?.call(next);
        }
      },
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
          _lastPointerY = details.localPosition.dy;
        },
        onPanUpdate: (details) {
          double delta = details.localPosition.dy - _lastPointerY;
          double next = (_scrollController.offset - delta).clamp(0, widget.totalHeight - 1);
          _scrollController.jumpTo(next);
          widget.onScroll?.call(next);
          _lastPointerY = details.localPosition.dy;
        },
        onPanEnd: (_) {
          _isDragging = false;
        },
        child: Scrollbar(
          controller: _scrollController,
          thickness: 8,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: double.infinity,
              height: widget.totalHeight * _zoomScale,
              child: CustomPaint(
                size: Size.infinite,
                painter: _ChartPainter(
                  notes: widget.notes,
                  color: getColorForBeat(widget.beatStr),
                  divides: widget.customDivides ??
                      List.generate(widget.xDivisions + 1, (i) => 512.0 * i / widget.xDivisions),
                  selectedIndices: const [],
                  selectionRect: null,
                  zoomScale: _zoomScale,
                  playOffset: _scrollController.offset,
                  totalHeight: widget.totalHeight * _zoomScale,
                  isPlaying: widget.isPlaying,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<Note> notes;
  final Color color;
  final List<double> divides;
  final List<int> selectedIndices;
  final Rect? selectionRect;
  final double zoomScale;
  final double playOffset;
  final double totalHeight;
  final bool isPlaying;

  _ChartPainter({
    required this.notes,
    required this.color,
    required this.divides,
    required this.selectedIndices,
    required this.selectionRect,
    required this.zoomScale,
    required this.playOffset,
    required this.totalHeight,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 分度线
    for (double y = 0; y < size.height; y += 320 * zoomScale) {
      bool isBar = ((y / (1280 * zoomScale)).abs() % 1) < 0.01;
      canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..color = isBar ? Colors.white : color.withOpacity(0.6)
            ..strokeWidth = isBar ? 3 : 1);
    }
    // 当前播放线
    if (isPlaying) {
      canvas.drawLine(
          Offset(0, playOffset),
          Offset(size.width, playOffset),
          Paint()
            ..color = Colors.blue
            ..strokeWidth = 4);
    }
    // notes
    for (final note in notes) {
      double x = note.x / 512.0 * size.width;
      double y = note.y * zoomScale;
      canvas.drawCircle(Offset(x, y), 10, Paint()..color = getNoteColor(note));
    }
    // 选区
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

Color getNoteColor(Note note) {
  switch (note.type) {
    case NoteType.normal:
      return Colors.deepPurple;
    case NoteType.rain:
      return Colors.blue;
    default:
      return Colors.grey;
  }
}