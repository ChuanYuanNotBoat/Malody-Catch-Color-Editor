import 'package:flutter/material.dart';
import 'editor_canvas.dart';

class SidePanel extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onPlayPause;
  final bool isPlaying;
  final double playProgress; // 0~1
  final List<Note> notes;
  final double totalHeight;
  final double scrollOffset;
  final double zoomScale;
  final Function(double) onSeek;
  final int maxBarCount;

  const SidePanel({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onPlayPause,
    required this.isPlaying,
    required this.playProgress,
    required this.notes,
    required this.totalHeight,
    required this.scrollOffset,
    required this.zoomScale,
    required this.onSeek,
    this.maxBarCount = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onZoomIn,
                  tooltip: "放大时间轴"),
              IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: onZoomOut,
                  tooltip: "缩小时间轴"),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 36),
              onPressed: onPlayPause,
              tooltip: isPlaying ? "暂停" : "播放",
            ),
          ),
          const SizedBox(height: 8),
          // 谱面缩略预览
          Expanded(
            child: ChartMiniPreview(
              notes: notes,
              totalHeight: totalHeight,
              scrollOffset: scrollOffset,
              zoomScale: zoomScale,
              playProgress: playProgress,
              onSeek: onSeek,
            ),
          ),
          // 密度预览
          DensityPreview(
            notes: notes,
            totalHeight: totalHeight,
            barCount: maxBarCount,
            onSeek: onSeek,
            playProgress: playProgress,
          ),
        ],
      ),
    );
  }
}

class ChartMiniPreview extends StatelessWidget {
  final List<Note> notes;
  final double totalHeight;
  final double scrollOffset;
  final double zoomScale;
  final double playProgress;
  final Function(double) onSeek;

  const ChartMiniPreview({
    super.key,
    required this.notes,
    required this.totalHeight,
    required this.scrollOffset,
    required this.zoomScale,
    required this.playProgress,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (detail) {
        final box = context.findRenderObject() as RenderBox;
        final y = detail.localPosition.dy;
        final pos = (y / box.size.height) * totalHeight;
        onSeek(pos);
      },
      child: CustomPaint(
        painter: _MiniChartPainter(
            notes: notes,
            totalHeight: totalHeight,
            scrollOffset: scrollOffset,
            zoomScale: zoomScale,
            playProgress: playProgress),
        size: Size(100, double.infinity),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<Note> notes;
  final double totalHeight;
  final double scrollOffset;
  final double zoomScale;
  final double playProgress;

  _MiniChartPainter({
    required this.notes,
    required this.totalHeight,
    required this.scrollOffset,
    required this.zoomScale,
    required this.playProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制分度线（只显示到/4）
    final Paint beatPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 0.5;
    final Paint barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    double previewHeight = size.height;

    // 假设每小节1280单位长度，/1加粗
    for (double barY = 0; barY < totalHeight; barY += 1280) {
      double py = barY / totalHeight * previewHeight;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), barPaint);
    }
    for (double beatY = 0; beatY < totalHeight; beatY += 320) {
      if (beatY % 1280 == 0) continue;
      double py = beatY / totalHeight * previewHeight;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), beatPaint);
    }

    // 绘制note点
    for (final n in notes) {
      double nx = n.x / 512.0 * size.width;
      double ny = n.y / totalHeight * previewHeight;
      canvas.drawCircle(Offset(nx, ny), 2.2, Paint()..color = Colors.deepPurple);
    }

    // 当前播放线
    double playY = playProgress * previewHeight;
    canvas.drawLine(
        Offset(0, playY),
        Offset(size.width, playY),
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 3);

    // 标注拍数
    int currentBar = (playProgress * totalHeight / 1280).floor() + 1;
    TextPainter tp = TextPainter(
        text: TextSpan(
            text: '第${currentBar}小节',
            style: const TextStyle(color: Colors.blue, fontSize: 10)),
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(4, playY - 14));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DensityPreview extends StatelessWidget {
  final List<Note> notes;
  final double totalHeight;
  final int barCount;
  final Function(double) onSeek;
  final double playProgress;

  const DensityPreview({
    super.key,
    required this.notes,
    required this.totalHeight,
    this.barCount = 100,
    required this.onSeek,
    required this.playProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: GestureDetector(
        onTapDown: (detail) {
          final box = context.findRenderObject() as RenderBox;
          final x = detail.localPosition.dx;
          final pos = (x / box.size.width) * totalHeight;
          onSeek(pos);
        },
        child: CustomPaint(
          size: Size(double.infinity, 36),
          painter: _DensityBarPainter(
              notes: notes,
              totalHeight: totalHeight,
              barCount: barCount,
              playProgress: playProgress),
        ),
      ),
    );
  }
}

class _DensityBarPainter extends CustomPainter {
  final List<Note> notes;
  final double totalHeight;
  final int barCount;
  final double playProgress;

  _DensityBarPainter({
    required this.notes,
    required this.totalHeight,
    required this.barCount,
    required this.playProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    List<int> density = List.filled(barCount, 0);
    for (final n in notes) {
      int idx = (n.y / totalHeight * barCount).clamp(0, barCount - 1).toInt();
      density[idx]++;
    }
    int maxDen = density.reduce((a, b) => a > b ? a : b);

    double barW = size.width / barCount;
    for (int i = 0; i < barCount; ++i) {
      double h = (density[i] / (maxDen == 0 ? 1 : maxDen)) * size.height;
      canvas.drawRect(
          Rect.fromLTWH(i * barW, size.height - h, barW - 1, h),
          Paint()
            ..color = Colors.purple.withOpacity(0.6)
            ..style = PaintingStyle.fill);
    }

    // 当前进度线
    double px = playProgress * size.width;
    canvas.drawLine(Offset(px, 0), Offset(px, size.height),
        Paint()..color = Colors.blue..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}