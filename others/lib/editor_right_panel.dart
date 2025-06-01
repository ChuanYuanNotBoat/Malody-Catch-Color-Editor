import 'package:flutter/material.dart';
import 'editor_canvas.dart';

class EditorRightPanel extends StatelessWidget {
  final NoteType selectedType;
  final Function(NoteType) onTypeChanged;
  final int xDivisions;
  final bool snapToXDivision;
  final Function(int) onXDivChanged;
  final Function(bool) onSnapChanged;
  final int selectedCount;
  final VoidCallback onDeleteSelected;
  final Map<String, dynamic>? chartMeta;
  final List<double>? customDivides;
  final VoidCallback onCustomDivideDialog;

  const EditorRightPanel({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.xDivisions,
    required this.snapToXDivision,
    required this.onXDivChanged,
    required this.onSnapChanged,
    required this.selectedCount,
    required this.onDeleteSelected,
    required this.chartMeta,
    required this.customDivides,
    required this.onCustomDivideDialog,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "Note"),
              Tab(text: "分度"),
              Tab(text: "谱面信息"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _NotePanel(
                  selectedType: selectedType,
                  onTypeChanged: onTypeChanged,
                  selectedCount: selectedCount,
                  onDeleteSelected: onDeleteSelected,
                ),
                _DivisionPanel(
                  xDivisions: xDivisions,
                  snapToXDivision: snapToXDivision,
                  onXDivChanged: onXDivChanged,
                  onSnapChanged: onSnapChanged,
                  customDivides: customDivides,
                  onCustomDivideDialog: onCustomDivideDialog,
                ),
                _MetaPanel(meta: chartMeta),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotePanel extends StatelessWidget {
  final NoteType selectedType;
  final Function(NoteType) onTypeChanged;
  final int selectedCount;
  final VoidCallback onDeleteSelected;
  const _NotePanel({
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedCount,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ...NoteType.values.map((type) {
          return RadioListTile<NoteType>(
            title: Text(type.name),
            value: type,
            groupValue: selectedType,
            onChanged: (v) {
              if (v != null) onTypeChanged(v);
            },
          );
        }).toList(),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: selectedCount > 0 ? onDeleteSelected : null,
          icon: const Icon(Icons.delete),
          label: Text('删除选中音符 (${selectedCount})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _DivisionPanel extends StatelessWidget {
  final int xDivisions;
  final bool snapToXDivision;
  final Function(int) onXDivChanged;
  final Function(bool) onSnapChanged;
  final List<double>? customDivides;
  final VoidCallback onCustomDivideDialog;

  const _DivisionPanel({
    required this.xDivisions,
    required this.snapToXDivision,
    required this.onXDivChanged,
    required this.onSnapChanged,
    required this.customDivides,
    required this.onCustomDivideDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text("吸附X分度"),
            value: snapToXDivision,
            onChanged: onSnapChanged,
          ),
          Row(
            children: [
              const Text("X分度数: "),
              Expanded(
                child: Slider(
                  value: xDivisions.toDouble(),
                  min: 2,
                  max: 40,
                  divisions: 38,
                  label: "$xDivisions",
                  onChanged: (v) => onXDivChanged(v.round()),
                ),
              ),
              Text("$xDivisions"),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCustomDivideDialog,
            icon: const Icon(Icons.settings),
            label: const Text("自定义分度"),
          ),
          if (customDivides != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  "自定义分度: ${customDivides!.map((d) => d.toStringAsFixed(0)).join(', ')}",
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ),
        ],
      ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  final Map<String, dynamic>? meta;
  const _MetaPanel({this.meta});

  @override
  Widget build(BuildContext context) {
    if (meta == null) return const Text("暂无谱面信息");
    final song = meta!['song'] ?? {};
    return ListView(
      children: [
        ListTile(title: const Text("Title"), subtitle: Text(song['title']?.toString() ?? '')),
        ListTile(title: const Text("Artist"), subtitle: Text(song['artist']?.toString() ?? '')),
        ListTile(title: const Text("Creator"), subtitle: Text(meta!['creator']?.toString() ?? '')),
        ListTile(title: const Text("Version"), subtitle: Text(meta!['version']?.toString() ?? '')),
      ],
    );
  }
}