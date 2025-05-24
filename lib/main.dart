import 'package:flutter/material.dart';
import 'side_panel.dart';
import 'editor_canvas.dart';
// ...其余import...

class _EditorPageState extends State<EditorPage> {
  List<Note> notes = [];
  double _zoomScale = 1.0;
  double _playOffset = 0.0;
  bool _isPlaying = false;
  static const double totalHeight = 1280.0 * 32; // 32小节

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidePanel(
            onZoomIn: () => setState(() => _zoomScale *= 1.2),
            onZoomOut: () => setState(() => _zoomScale /= 1.2),
            onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
            isPlaying: _isPlaying,
            playProgress: _playOffset / totalHeight,
            notes: notes,
            totalHeight: totalHeight,
            scrollOffset: _playOffset,
            zoomScale: _zoomScale,
            onSeek: (pos) => setState(() => _playOffset = pos),
          ),
          Expanded(
            child: EditorCanvas(
              notes: notes,
              selectedType: NoteType.normal,
              xDivisions: 4,
              snapToXDivision: true,
              customDivides: null,
              beatStr: '1/4',
              onAddNote: (n) => setState(() => notes.add(n)),
              onNotesChanged: (n) => setState(() => notes = n),
              onSelectNotes: (_) {},
              onRegisterDeleteHandler: (_) {},
              zoomScale: _zoomScale,
              playOffset: _playOffset,
              isPlaying: _isPlaying,
              onScroll: (offset) => setState(() => _playOffset = offset),
              totalHeight: totalHeight,
            ),
          ),
          // ...右侧栏...
        ],
      ),
    );
  }
}