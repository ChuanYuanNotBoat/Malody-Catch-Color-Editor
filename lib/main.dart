import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'editor_canvas.dart';
import 'editor_right_panel.dart';
import 'malody_import_export.dart';
import 'divide_preview_bar.dart';
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
  String? musicFilePath;
  String? bgFilePath;
  Timer? _autoSaveTimer;
  late void Function() _deleteHandler;
  List<double>? customDivides;

  // 新增的getter方法
  String get currentBeat => getBeatString(xDivisions);

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
    final dir = p.dirname(chartFilePath!);
    final path = p.join(dir, "auto_save.mc");
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
    if (selectedNoteIndices.isEmpty) return;
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

  Future<void> importChart() async {
    final path = await pickMalodyFile();
    if (path == null) return;
    await _handleChartReplace(path);
  }

  Future<void> _autoAlignAssets(String chartPath, Map<String, dynamic> chart) async {
    final dir = p.dirname(chartPath);
    final assets = extractAssetsFromChart(chart);

    String? musicPath;
    if (assets.musicName != null) {
      final candidate = File(p.join(dir, assets.musicName!));
      if (await candidate.exists()) {
        musicPath = candidate.path;
      }
    }

    String? bgPath;
    if (assets.bgName != null) {
      final candidate = File(p.join(dir, assets.bgName!));
      if (await candidate.exists()) {
        bgPath = candidate.path;
      }
    }

    setState(() {
      musicFilePath = musicPath;
      bgFilePath = bgPath;
    });
  }

  Future<void> importChartFromPath(String path) async {
    try {
      final json = await importMalodyChart(path);
      setState(() {
        chartJson = json;
        chartFilePath = path;
        notes = [];
        if (json['notes'] is List) {
          notes = (json['notes'] as List)
              .map((n) => Note(
            x: (n['x'] as num).toDouble(),
            y: (n['y'] as num).toDouble(),
            type: NoteType.values.firstWhere(
                    (e) => e.name == (n['type'] ?? 'normal'),
                orElse: () => NoteType.normal),
          ))
              .toList();
        }
        selectedNoteIndices = [];
      });
      await _autoAlignAssets(path, json);
      _showMessage('导入成功: ${_fileName(path)}');
    } catch (e) {
      _showMessage('导入失败: $e');
    }
  }

  Future<void> exportChart({required bool asZip}) async {
    if (chartJson == null || chartFilePath == null) {
      _showMessage('当前无谱面数据');
      return;
    }
    final path = await pickMalodySavePath(zip: asZip);
    if (path == null) {
      _showMessage('未选择导出路径');
      return;
    }
    try {
      final outChart = {...chartJson!};
      outChart['notes'] = notes
          .map((n) => {
        'x': n.x,
        'y': n.y,
        'type': n.type.name,
      })
          .toList();

      if (asZip) {
        await exportMczFileWithOriginalNames(
          chart: outChart,
          chartFilePath: chartFilePath!,
          path: path,
          musicFilePath: musicFilePath,
          bgFilePath: bgFilePath,
        );
      } else {
        await exportMcFile(outChart, path);
      }
      _showMessage('导出成功: $path');
    } catch (e) {
      _showMessage('导出失败: $e');
    }
  }

  Future<void> _handleChartReplace(String newPath) async {
    if (chartJson != null && notes.isNotEmpty) {
      final result = await showDialog<FileChangeResult>(
        context: context,
        builder: (context) => _ChartChangeDialog(),
      );
      if (result == FileChangeResult.cancel) return;
      if (result == FileChangeResult.save) {
        await exportChart(asZip: newPath.endsWith('.mcz'));
      }
    }
    await importChartFromPath(newPath);
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fileName(String path) => path.split(RegExp(r'[\/\\]')).last;

  void _handleCustomDivideDialog() async {
    final List<double> initDivides = customDivides ??
        List.generate(xDivisions + 1, (i) => 512.0 * i / xDivisions);
    final result = await showDialog<List<double>>(
      context: context,
      builder: (ctx) => DivideAdjustDialog(initialDivides: initDivides),
    );
    if (result != null) {
      setState(() {
        customDivides = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Malody Catch 编辑器${chartFilePath != null ? ' - ${_fileName(chartFilePath!)}' : ''}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '导入',
            onPressed: importChart,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '导出为 .mc',
            onPressed: () => exportChart(asZip: false),
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: '导出为 .mcz',
            onPressed: () => exportChart(asZip: true),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (bgFilePath != null)
            Positioned.fill(
              child: Image.file(
                File(bgFilePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.black12),
              ),
            ),
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      color: Colors.grey[200],
                      child: Column(
                        children: const [
                          SizedBox(height: 20),
                          Text('轨道栏', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        child: EditorCanvas(
                          notes: notes,
                          selectedType: selectedType,
                          xDivisions: xDivisions,
                          snapToXDivision: snapToXDivision,
                          customDivides: customDivides,
                          // 新增的beatStr参数
                          beatStr: currentBeat,
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
                            customDivides = null;
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
                        customDivides: customDivides,
                        onCustomDivideDialog: _handleCustomDivideDialog,
                      ),
                    ),
                  ],
                ),
              ),
              DividePreviewBar(
                xDivisions: xDivisions,
                customDivides: customDivides,
                // 新增的beatStr参数
                beatStr: currentBeat,
                onCustomDividesChanged: (divides) {
                  setState(() {
                    customDivides = divides;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum FileChangeResult { save, dontSave, cancel }

class _ChartChangeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('谱面已更改'),
      content: const Text('当前谱面有更改，是否保存？\n\n选择“保存”将先保存当前谱面。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(FileChangeResult.cancel),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(FileChangeResult.dontSave),
          child: const Text('不保存'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(FileChangeResult.save),
          child: const Text('保存'),
        ),
      ],
    );
  }
}