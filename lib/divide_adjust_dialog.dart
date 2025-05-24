import 'package:flutter/material.dart';

Future<int?> showDivideAdjustDialog(BuildContext context, int currentDivide) async {
  int? selectedDivide = currentDivide;
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('调整分度'),
      content: DropdownButton<int>(
        value: selectedDivide,
        items: [1,2,3,4,6,8,12,16,24,32].map((d) =>
          DropdownMenuItem(value: d, child: Text('1/$d'))
        ).toList(),
        onChanged: (d) => selectedDivide = d,
      ),
      actions: [
        TextButton(child: const Text('确定'), onPressed: () => Navigator.of(ctx).pop(selectedDivide)),
      ],
    ),
  );
}