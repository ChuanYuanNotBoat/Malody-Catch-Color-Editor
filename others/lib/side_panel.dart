import 'package:flutter/material.dart';
import 'preview_panel.dart';
import 'density_bar.dart';

class SidePanel extends StatelessWidget {
  final List notes;
  final int currentBar;
  final int previewRangeBars;
  final int barCount;
  final double width;
  final double height;
  final List<int> densityList;
  final double currentTime;
  final double songDuration;
  final void Function(double) onSeek;

  const SidePanel({
    super.key,
    required this.notes,
    required this.currentBar,
    required this.previewRangeBars,
    required this.barCount,
    required this.width,
    required this.height,
    required this.densityList,
    required this.currentTime,
    required this.songDuration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: PreviewPanel(
            notes: notes,
            currentBar: currentBar,
            previewRangeBars: previewRangeBars,
            barCount: barCount,
            width: width,
            height: height,
          ),
        ),
        Expanded(
          flex: 1,
          child: DensityBar(
            densityList: densityList,
            currentTime: currentTime,
            songDuration: songDuration,
            onSeek: onSeek,
          ),
        ),
      ],
    );
  }
}