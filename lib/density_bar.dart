import 'package:flutter/material.dart';

class DensityBar extends StatelessWidget {
  final List<int> densityList;
  final double currentTime;
  final double songDuration;
  final Function(double) onSeek;

  const DensityBar({
    super.key,
    required this.densityList,
    required this.currentTime,
    required this.songDuration,
    required this.onSeek,
  });

  String formatDuration(double seconds) {
    int min = seconds ~/ 60;
    double sec = seconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toStringAsFixed(2).padLeft(5, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        double barHeight = constraints.maxHeight;
        return GestureDetector(
          onTapDown: (detail) {
            final y = detail.localPosition.dy;
            final percent = y / barHeight;
            final seekTime = songDuration * percent;
            onSeek(seekTime);
          },
          onVerticalDragUpdate: (detail) {
            final y = detail.localPosition.dy;
            final percent = y / barHeight;
            final seekTime = songDuration * percent;
            onSeek(seekTime);
          },
          child: Column(
            children: [
              Text(formatDuration(songDuration), style: TextStyle(fontSize: 12)),
              Expanded(
                child: CustomPaint(
                  painter: _DensityBarPainter(
                    densityList: densityList,
                    currentTime: currentTime,
                    songDuration: songDuration,
                  ),
                ),
              ),
              Text(formatDuration(currentTime), style: TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _DensityBarPainter extends CustomPainter {
  final List<int> densityList;
  final double currentTime;
  final double songDuration;

  _DensityBarPainter({
    required this.densityList,
    required this.currentTime,
    required this.songDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int barCount = densityList.length;
    for (int i = 0; i < barCount; ++i) {
      double x = 0;
      double y = i * size.height / barCount;
      double barW = size.width;
      double barH = size.height / barCount;
      int density = densityList[i];
      Paint p = Paint()
        ..color = Color.lerp(Colors.grey[200], Colors.deepPurple, (density / 10.0).clamp(0, 1)) ?? Colors.grey
        ..strokeWidth = barW;
      canvas.drawRect(
          Rect.fromLTWH(x, y, barW, barH), p);
    }
    // 当前播放位置线
    double percent = songDuration == 0 ? 0 : currentTime / songDuration;
    double currentY = percent * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, currentY - 2, size.width, 4),
      Paint()..color = Colors.blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}