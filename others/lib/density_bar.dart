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
      onTapDown: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        double dy = details.localPosition.dy;
        double seekTime = (songDuration * (1 - dy / box.size.height));
        onSeek(seekTime);
      },
      child: CustomPaint(
        size: Size(48, 500), // 固定宽度，高度为 500
        painter: DensityBarPainter(densityList, currentTime, songDuration),
      ),
    );
  }
}

class DensityBarPainter extends CustomPainter {
  final List<int> densityList;
  final double currentTime;
  final double songDuration;

  DensityBarPainter(this.densityList, this.currentTime, this.songDuration);

  @override
  void paint(Canvas canvas, Size size) {
    double barHeight = size.height / densityList.length;
    for (int i = 0; i < densityList.length; i++) {
      double y = size.height - (i + 1) * barHeight; // 从下往上绘制
      double width = size.width * (densityList[i] / 100); // 假设密度值范围为 0-100
      Paint paint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, y, width, barHeight), paint);
    }

    // 绘制当前时间指示线
    double currentTimeY = size.height * (1 - currentTime / songDuration);
    Paint linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, currentTimeY), Offset(size.width, currentTimeY), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}