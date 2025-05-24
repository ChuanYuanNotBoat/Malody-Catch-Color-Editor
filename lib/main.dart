import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // for PointerScrollEvent
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'editor_canvas.dart';
import 'editor_right_panel.dart';
import 'malody_import_export.dart';
import 'divide_preview_bar.dart';
import 'divide_adjust_dialog.dart';
import 'beat_color_util.dart';
import 'preview_panel.dart';
import 'density_bar.dart';

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
  int xDivisions = 4;
  bool snapToXDivision = true;
  List<int> selectedNoteIndices = [];
  Map<String, dynamic>? chartJson;
  String? chartFilePath;
  String? musicFilePath;
  String? bgFilePath;
  Timer? _autoSaveTimer;
  late void Function() _deleteHandler;
  List<double>? customDivides;

  // 播放相关
  double currentTime = 0;
  double songDuration = 180.0;
  bool isPlaying = false;
  double scrollOffset = 0;
  double canvasHeight = 720;
  double totalHeight = 1280.0 * 32;

  // 可编辑区宽度
  final double editorWidth = 512;

  // 新增BPM、offset、速度、分度量
  double bpm = 120;
  double offset = 0;
  double scrollSpeed = 1.0; // px/ms
  double divisionBeat = 1.0; // 小节分度（1=每小节一线，0.5=半小节一线）

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
        'endY': n.endY,
        'type': n.type.name,
        'beat': n.beat,
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

  // 自动读取bpm/offset与分度
  Future<void> importChartFromPath(String path) async {
    try {
      final json = await importMalodyChart(path);
      double _bpm = 120;
      double _offset = 0;
      double _divisionBeat = 1.0; // 默认每小节一线
      if (json['time'] is List && json['time'].isNotEmpty && json['time'][0]['bpm'] != null) {
        _bpm = (json['time'][0]['bpm'] as num).toDouble();
      }
      // 通用offset查找
      if (json['meta'] != null && json['meta']['song'] != null && json['meta']['song']['offset'] != null) {
        _offset = (json['meta']['song']['offset'] as num).toDouble();
      } else if (json['meta'] != null && json['meta']['offset'] != null) {
        _offset = (json['meta']['offset'] as num).toDouble();
      }
      // 检查extra divide
      if (json['extra'] != null && json['extra']['test'] != null && json['extra']['test']['divide'] != null) {
        int d = json['extra']['test']['divide'];
        if (d > 0) _divisionBeat = 1.0 / d;
      }
      setState(() {
        chartJson = json;
        chartFilePath = path;
        notes = [];
        bpm = _bpm;
        offset = _offset;
        divisionBeat = _divisionBeat;
        // 每分钟bpm小节，1小节1280px，每秒bpm/60小节→每秒(px) = bpm/60*1280
        scrollSpeed = bpm / 60.0 * 1280.0;
        if (json['note'] is List) {
          notes = parseMalodyNotes(json['note']);
        } else if (json['notes'] is List) {
          notes = (json['notes'] as List)
              .map((n) => Note(
            x: (n['x'] as num).toDouble(),
            y: (n['y'] as num).toDouble(),
            endY: n['endY'] != null ? (n['endY'] as num).toDouble() : null,
            type: NoteType.values.firstWhere(
                    (e) => e.name == (n['type'] ?? 'normal'),
                orElse: () => NoteType.normal),
            beat: n['beat'] ?? getBeatString(xDivisions),
          ))
              .toList();
        }
        selectedNoteIndices = [];
      });
      await _autoAlignAssets(path, chartJson!);
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
      outChart['note'] = notes.map(noteToMalodyMap).toList();

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
        List.generate(xDivisions + 1, (i) => editorWidth * i / xDivisions);
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

  String get currentBeat => getBeatString(xDivisions);

  List<int> get densityList {
    int densityBars = 100;
    List<int> list = List.filled(densityBars, 0);
    for (var n in notes) {
      int idx = (n.y / totalHeight * densityBars).toInt().clamp(0, densityBars - 1);
      list[idx]++;
    }
    return list;
  }

  void _play() {
    setState(() {
      isPlaying = true;
    });
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isPlaying) {
        timer.cancel();
      } else if (currentTime >= songDuration) {
        setState(() {
          isPlaying = false;
        });
        timer.cancel();
      } else {
        setState(() {
          currentTime += 0.016;
          // 带offset，视觉时间
          double visualTime = currentTime + offset / 1000.0;
          scrollOffset = visualTime * scrollSpeed;
        });
      }
    });
  }

  void _pause() {
    setState(() {
      isPlaying = false;
    });
  }

  void _seek(double t) {
    setState(() {
      currentTime = t;
      double visualTime = currentTime + offset / 1000.0;
      scrollOffset = visualTime * scrollSpeed;
    });
  }

  // 分度量调节（如滑块）
  void _onDivisionBeatChanged(double v) {
    setState(() {
      divisionBeat = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentBar = ((scrollOffset + canvasHeight / 2) / 1280).floor();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Malody Catch 编辑器${chartFilePath != null ? ' - ${_fileName(chartFilePath!)}' : ''}',
        ),
        actions: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            tooltip: isPlaying ? '暂停' : '播放',
            onPressed: isPlaying ? _pause : _play,
          ),
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
      body: Row(
        children: [
          // 左侧预览/密度条
          Column(
            children: [
              PreviewPanel(
                notes: notes,
                currentBar: currentBar,
                previewRangeBars: 4,
                barCount: 32,
                width: 40,
                height: 300,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: DensityBar(
                  densityList: densityList,
                  currentTime: currentTime,
                  songDuration: songDuration,
                  onSeek: _seek,
                ),
              ),
            ],
          ),
          // 中间主编辑区
          Expanded(
            child: Center(
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    setState(() {
                      scrollOffset = (scrollOffset + event.scrollDelta.dy * 2).clamp(0, totalHeight - canvasHeight);
                    });
                  }
                },
                child: Container(
                  width: editorWidth,
                  color: Colors.transparent,
                  child: EditorCanvas(
                    notes: notes,
                    editorWidth: editorWidth,
                    scrollOffset: scrollOffset,
                    canvasHeight: canvasHeight,
                    totalHeight: totalHeight,
                    selectedType: selectedType,
                    xDivisions: xDivisions,
                    snapToXDivision: snapToXDivision,
                    customDivides: customDivides,
                    beatStr: currentBeat,
                    onAddNote: (note) {
                      setState(() {
                        notes.add(note);
                      });
                    },
                    onNotesChanged: _handleNotesChanged,
                    onSelectNotes: _handleSelectNotes,
                    onRegisterDeleteHandler: _registerDeleteHandler,
                    divisionBeat: divisionBeat,
                  ),
                ),
              ),
            ),
          ),
          // 右侧功能面板
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
      bottomNavigationBar: DividePreviewBar(
        xDivisions: xDivisions,
        customDivides: customDivides,
        beatStr: currentBeat,
        onCustomDividesChanged: (divides) {
          setState(() {
            customDivides = divides;
          });
        },
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