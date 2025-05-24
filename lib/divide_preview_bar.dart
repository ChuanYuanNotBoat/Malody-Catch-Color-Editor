import 'package:flutter/material.dart';

class DividePreviewBar extends StatelessWidget {
  final int xDivisions;
  final List<double>? customDivides;
  final String beatStr;
  final Function(List<double>) onCustomDividesChanged;

  const DividePreviewBar({
    super.key,
    required this.xDivisions,
    required this.customDivides,
    required this.beatStr,
    required this.onCustomDividesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> divides = customDivides ??
        List.generate(xDivisions + 1, (i) => 512.0 * i / xDivisions);
    return Container(
      height: 24,
      color: Colors.grey[200],
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('分度预览:', style: TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 20),
                  painter: _DivideBarPainter(divides: divides),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DivideBarPainter extends CustomPainter {
  final List<double> divides;

  _DivideBarPainter({required this.divides});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;
    for (final x in divides) {
      double dx = (x / 512.0) * size.width;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}