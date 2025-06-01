import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'editor_canvas.dart';
import 'preview_panel.dart';
import 'density_bar.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  List<Note> notes = [];
  double scrollOffset = 0;
  double canvasHeight = 720;
  double totalHeight = 1280.0 * 32; // 总高度
  double currentTime = 0;
  double songDuration = 0.0;
  bool isPlaying = false;

  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen(_onPlayerState);
    _audioPlayer.positionStream.listen(_onPositionChanged);
    _audioPlayer.durationStream.listen(_onDurationChanged);
    // 你可以在这里自动读取谱面并加载音频:
    // _loadAudio('your_audio_path.mp3');
    // _loadChart('your_chart_path.json');
  }

  Future<void> _loadAudio(String filePath) async {
    await _audioPlayer.setFilePath(filePath);
    setState(() {
      songDuration = _audioPlayer.duration?.inMilliseconds.toDouble() ?? 0.0;
    });
  }

  void _onDurationChanged(Duration? d) {
    if (d != null) {
      setState(() {
        songDuration = d.inMilliseconds / 1000.0;
      });
    }
  }

  void _onPositionChanged(Duration p) {
    setState(() {
      currentTime = p.inMilliseconds / 1000.0;
    });
  }

  void _onPlayerState(PlayerState state) {
    setState(() {
      isPlaying = state.playing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: EditorCanvas(
              notes: notes,
              division: 4,
              editorWidth: MediaQuery.of(context).size.width - 300, // 示例宽度
              scrollOffset: scrollOffset,
              canvasHeight: canvasHeight,
              totalHeight: totalHeight,
              maxXValue: totalHeight, // 添加缺失的参数
            ),
          ),
          Container(
            width: 300,
            color: Colors.grey[200],
            child: Column(
              children: [
                // 右侧面板内容
              ],
            ),
          ),
        ],
      ),
    );
  }
}