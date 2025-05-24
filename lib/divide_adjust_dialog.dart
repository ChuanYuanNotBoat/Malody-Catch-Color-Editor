import 'package:flutter/material.dart';

class DivideAdjustDialog extends StatefulWidget {
  final List<double> initialDivides;
  const DivideAdjustDialog({super.key, required this.initialDivides});

  @override
  State<DivideAdjustDialog> createState() => _DivideAdjustDialogState();
}

class _DivideAdjustDialogState extends State<DivideAdjustDialog> {
  late List<double> divides;

  @override
  void initState() {
    super.initState();
    divides = List<double>.from(widget.initialDivides);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("自定义X分度"),
      content: SizedBox(
        width: 400,
        height: 300,
        child: ReorderableListView(
          children: [
            for (int i = 0; i < divides.length; i++)
              ListTile(
                key: ValueKey(i),
                title: Text("分度 $i: ${divides[i].toStringAsFixed(2)}"),
                trailing: i == 0 || i == divides.length - 1
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => divides.removeAt(i));
                  },
                ),
                onTap: i == 0 || i == divides.length - 1
                    ? null
                    : () async {
                  double? v = await showDialog<double>(
                    context: context,
                    builder: (ctx) {
                      double temp = divides[i];
                      return AlertDialog(
                        title: Text("编辑分度 $i"),
                        content: TextField(
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                          controller: TextEditingController(
                            text: temp.toStringAsFixed(2),
                          ),
                          onChanged: (s) {
                            double? val = double.tryParse(s);
                            if (val != null) temp = val.clamp(0, 512);
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            child: const Text("取消"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, temp),
                            child: const Text("确定"),
                          ),
                        ],
                      );
                    },
                  );
                  if (v != null) setState(() => divides[i] = v.clamp(0, 512));
                },
              ),
          ],
          onReorder: (oldIdx, newIdx) {
            if (oldIdx == 0 ||
                oldIdx == divides.length - 1 ||
                newIdx == 0 ||
                newIdx == divides.length) return;
            setState(() {
              final x = divides.removeAt(oldIdx);
              divides.insert(newIdx > oldIdx ? newIdx - 1 : newIdx, x);
            });
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text("取消")),
        TextButton(
            onPressed: () => Navigator.pop(context, divides),
            child: const Text("保存")),
      ],
    );
  }
}