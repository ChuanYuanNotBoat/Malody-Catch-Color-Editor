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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) {
        RenderBox box = context.findRenderObject() as RenderBox;
        double dy = d.localPosition.dy;
        double p = dy / box.size.height;
        onSeek(songDuration * p);
      },
      child: CustomPaint(
        size: Size(40, double.infinity),
        painter: _DensityBarPainter(
          densityList: densityList,
          currentTime: currentTime,
          songDuration: songDuration,
        ),
      ),
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
    int n = densityList.length;
    int maxValue = densityList.fold(1, (max, v) => v > max ? v : max);
    for (int i = 0; i < n; ++i) {
      double top = (i / n) * size.height;
      double h = (1 / n) * size.height;
      double w = (densityList[i] / maxValue) * size.width;
      canvas.drawRect(
        Rect.fromLTWH(size.width - w, top, w, h),
        Paint()..color = Colors.blueAccent.withOpacity(0.7),
      );
    }
    // 当前时间线
    double py = (currentTime / (songDuration == 0 ? 1 : songDuration)) * size.height;
    canvas.drawLine(
      Offset(0, py),
      Offset(size.width, py),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}