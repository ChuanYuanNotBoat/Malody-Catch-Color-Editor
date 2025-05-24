import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'editor_canvas.dart';
import 'editor_right_panel.dart';
import 'malody_import_export.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MalodyCatchEditorApp());
}

class MalodyCatchEditorApp extends StatelessWidget {
  const MalodyCatchEditorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malody Catch Editor',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EditorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});
  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  List<Note> notes = [];
  NoteType selectedType = NoteType.normal;
  int xDivisions = 20;
  bool snapToXDivision = true;
  List<int> selectedNoteIndices = [];
  Map<String, dynamic>? chartJson;
  String? chartFilePath;
  Timer? _autoSaveTimer;
  late void Function() _deleteHandler;

  @override
  void initState() {
    super.initState();
    _startAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (_) => _autoSave());
  }

  void _autoSave() async {
    if (chartFilePath == null) return;
    // 保存到同目录 auto_save.mc
    final dir = p.dirname(chartFilePath!);
    final path = p.join(dir, "auto_save.mc");
    // 自动保存当前notes到mc（假定转换逻辑，需根据你实际谱面格式调整）
    if (chartJson != null) {
      final mcJson = {...chartJson!};
      mcJson['notes'] = notes
          .map((n) => {
        'x': n.x,
        'y': n.y,
        'type': n.type.name,
      })
          .toList();
      await File(path).writeAsString(const JsonEncoder.withIndent('  ').convert(mcJson));
    }
  }

  void _handleNotesChanged(List<Note> newNotes) {
    setState(() {
      notes = newNotes;
    });
  }

  void _handleSelectNotes(List<int> idxs) {
    setState(() {
      selectedNoteIndices = idxs;
    });
  }

  void _handleDeleteSelected() {
    final toKeep = <Note>[];
    for (var i = 0; i < notes.length; ++i) {
      if (!selectedNoteIndices.contains(i)) toKeep.add(notes[i]);
    }
    setState(() {
      notes = toKeep;
      selectedNoteIndices = [];
    });
  }

  void _registerDeleteHandler(void Function() handler) {
    _deleteHandler = handler;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malody Catch 谱面编辑'),
      ),
      body: Row(
        children: [
          Container(width: 60, color: Colors.grey[200]),
          // 编辑区
          Expanded(
            child: Container(
              color: Colors.black,
              child: EditorCanvas(
                notes: notes,
                selectedType: selectedType,
                xDivisions: xDivisions,
                snapToXDivision: snapToXDivision,
                onAddNote: (note) {
                  setState(() {
                    notes.add(note);
                  });
                },
                onNotesChanged: _handleNotesChanged,
                onSelectNotes: _handleSelectNotes,
                onRegisterDeleteHandler: _registerDeleteHandler,
              ),
            ),
          ),
          // 右侧功能栏
          Container(
            width: 260,
            color: Colors.grey[100],
            child: EditorRightPanel(
              selectedType: selectedType,
              onTypeChanged: (type) {
                setState(() {
                  selectedType = type;
                });
              },
              xDivisions: xDivisions,
              snapToXDivision: snapToXDivision,
              onXDivChanged: (v) {
                setState(() {
                  xDivisions = v;
                });
              },
              onSnapChanged: (v) {
                setState(() {
                  snapToXDivision = v;
                });
              },
              selectedCount: selectedNoteIndices.length,
              onDeleteSelected: _handleDeleteSelected,
              chartMeta: chartJson?['meta'],
            ),
          ),
        ],
      ),
    );
  }
}