import 'package:flutter/material.dart';

class DividePreviewBar extends StatelessWidget {
  final int division;
  final ValueChanged<int> onDivisionChanged;
  const DividePreviewBar({super.key, required this.division, required this.onDivisionChanged});

  @override
  Widget build(BuildContext context) {
    final divisions = [4, 8, 12, 16, 24, 32];
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          Text("分度:"),
          SizedBox(width: 8),
          DropdownButton<int>(
            value: division,
            items: divisions.map((d) => DropdownMenuItem(
              value: d, child: Text('1/$d'),
            )).toList(),
            onChanged: (v) {
              if (v != null) onDivisionChanged(v);
            },
          ),
        ],
      ),
    );
  }
}