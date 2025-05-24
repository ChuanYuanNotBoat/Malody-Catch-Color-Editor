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
  double totalHeight = 1280.0 * 32;
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

  void _onPositionChanged(Duration d) {
    setState(() {
      currentTime = d.inMilliseconds / 1000.0;
      scrollOffset = (currentTime / (songDuration == 0 ? 1 : songDuration)) * (totalHeight - canvasHeight);
    });
  }

  void _onPlayerState(PlayerState state) {
    if (state.processingState == ProcessingState.completed) {
      setState(() {
        isPlaying = false;
      });
      _audioPlayer.seek(Duration.zero);
    }
  }

  void onSeek(double time) async {
    setState(() {
      currentTime = time.clamp(0, songDuration);
      scrollOffset = (currentTime / (songDuration == 0 ? 1 : songDuration)) * (totalHeight - canvasHeight);
    });
    await _audioPlayer.seek(Duration(milliseconds: (currentTime * 1000).toInt()));
  }

  void onPlayPressed() async {
    if (currentTime >= songDuration) {
      await _audioPlayer.seek(Duration.zero);
      setState(() {
        currentTime = 0.0;
      });
    }
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  List<int> get densityList {
    int densityBars = 100;
    List<int> list = List.filled(densityBars, 0);
    for (var n in notes) {
      int idx = (n.y / totalHeight * densityBars).toInt().clamp(0, densityBars - 1);
      list[idx]++;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    int currentBar = ((scrollOffset + canvasHeight / 2) / 1280).floor();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malody Catch Editor'),
        actions: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: onPlayPressed,
          ),
        ],
      ),
      body: Row(
        children: [
          // 左侧面板
          Column(
            children: [
              PreviewPanel(
                notes: notes,
                currentBar: currentBar,
                previewRangeBars: 4,
                barCount: 32,
                width: 40,
                height: 300,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DensityBar(
                  densityList: densityList,
                  currentTime: currentTime,
                  songDuration: songDuration,
                  onSeek: onSeek,
                ),
              ),
            ],
          ),
          // 主编辑画布
          Expanded(
            child: EditorCanvas(
              notes: notes,
              scrollOffset: scrollOffset,
              canvasHeight: canvasHeight,
              totalHeight: totalHeight,
              isPlaying: isPlaying,
            ),
          ),
        ],
      ),
    );
  }
}

String formatDuration(double seconds) {
  int min = seconds ~/ 60;
  double sec = seconds % 60;
  return "${min.toString().padLeft(2, '0')}:${sec.toStringAsFixed(2).padLeft(5, '0')}";
}