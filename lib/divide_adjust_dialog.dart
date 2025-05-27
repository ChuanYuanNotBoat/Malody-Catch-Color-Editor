import 'package:flutter/material.dart';

class DivideAdjustDialog extends StatefulWidget {
  final int initialDivision;
  final ValueChanged<int> onDivisionChanged;
  const DivideAdjustDialog({super.key, required this.initialDivision, required this.onDivisionChanged});

  @override
  State<DivideAdjustDialog> createState() => _DivideAdjustDialogState();
}

class _DivideAdjustDialogState extends State<DivideAdjustDialog> {
  int division = 4;
  final List<int> divisions = [4, 8, 12, 16, 24, 32];

  @override
  void initState() {
    super.initState();
    division = widget.initialDivision;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Time Division'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: division,
            items: divisions.map((d) => DropdownMenuItem(
              value: d, child: Text('1/$d'),
            )).toList(),
            onChanged: (v) {
              setState(() { division = v!; });
              widget.onDivisionChanged(division);
            },
          ),
          Slider(
            min: 4,
            max: 32,
            divisions: 7,
            label: "1/$division",
            value: division.toDouble(),
            onChanged: (v) {
              setState(() { division = v.round(); });
              widget.onDivisionChanged(division);
            },
          ),
        ]
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(division),
          child: Text('OK'),
        ),
      ],
    );
  }
}