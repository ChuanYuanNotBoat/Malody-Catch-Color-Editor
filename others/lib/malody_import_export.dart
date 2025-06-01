import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'editor_canvas.dart';

/// 选择 Malody 谱面文件（.mc 或 .mcz），返回文件路径
Future<String?> pickMalodyFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mc', 'mcz'],
  );
  return result?.files.single.path;
}

/// 解析 .mc 文件为 JSON
Future<Map<String, dynamic>> parseMcFile(String path) async {
  final text = await File(path).readAsString();
  return json.decode(text);
}

/// 解析 .mcz 文件为 JSON（只取第一个 .mc 文件内容）
Future<Map<String, dynamic>> parseMczFile(String path) async {
  final input = InputFileStream(path);
  final archive = ZipDecoder().decodeBuffer(input);
  Map<String, dynamic>? chartJson;
  for (final file in archive) {
    if (file.isFile && file.name.endsWith('.mc')) {
      final content = file.content as List<int>;
      chartJson = json.decode(utf8.decode(content));
      break;
    }
  }
  input.close();
  if (chartJson == null) throw Exception('未找到 .mc 谱面文件');
  return chartJson;
}

/// 自动识别 .mc/.mcz 并解析
Future<Map<String, dynamic>> importMalodyChart(String path) async {
  if (path.endsWith('.mc')) {
    return await parseMcFile(path);
  } else if (path.endsWith('.mcz')) {
    return await parseMczFile(path);
  } else {
    throw Exception('不支持的文件格式');
  }
}

/// 从谱面 JSON 里获取音频和背景文件名
class ChartAssets {
  final String? musicName;
  final String? bgName;
  ChartAssets({this.musicName, this.bgName});
}

/// 从 mc json 提取音频与背景名
ChartAssets extractAssetsFromChart(Map<String, dynamic> chartJson) {
  final meta = chartJson['meta'] ?? {};
  final song = meta['song'] ?? {};
  String? music = song['bgm'] ?? song['music'] ?? song['audio'];
  String? bg = song['cover'] ?? song['bg'] ?? song['background'];
  return ChartAssets(musicName: music, bgName: bg);
}

/// 导出为 .mc
Future<void> exportMcFile(Map<String, dynamic> chart, String path) async {
  final text = const JsonEncoder.withIndent('  ').convert(chart);
  try {
    await File(path).writeAsString(text, encoding: utf8);
  } catch (e) {
    print('写入失败: $e');
    rethrow;
  }
}

/// 导出为 .mcz （保持文件名原样，包括 .mc、音频、图片等）
Future<void> exportMczFileWithOriginalNames({
  required Map<String, dynamic> chart,
  required String chartFilePath, // .mc 源文件路径
  required String path, // 导出 .mcz 路径
  String? musicFilePath, // 音频文件路径
  String? bgFilePath, // 背景文件路径
}) async {
  final archive = Archive();

  // 添加谱面
  String mcName = p.basename(chartFilePath);
  archive.addFile(ArchiveFile(
    mcName,
    utf8.encode(json.encode(chart)).length,
    utf8.encode(json.encode(chart)),
  ));

  // 添加音频
  if (musicFilePath != null && await File(musicFilePath).exists()) {
    archive.addFile(ArchiveFile(
      p.basename(musicFilePath),
      await File(musicFilePath).length(),
      await File(musicFilePath).readAsBytes(),
    ));
  }

  // 添加背景
  if (bgFilePath != null && await File(bgFilePath).exists()) {
    archive.addFile(ArchiveFile(
      p.basename(bgFilePath),
      await File(bgFilePath).length(),
      await File(bgFilePath).readAsBytes(),
    ));
  }

  try {
    final zipData = ZipEncoder().encode(archive);
    await File(path).writeAsBytes(zipData!);
  } catch (e) {
    print('写入失败: $e');
    rethrow;
  }
}

// 选择导出文件路径
Future<String?> pickMalodySavePath({required bool zip}) async {
  return await FilePicker.platform.saveFile(
    dialogTitle: "选择导出位置",
    fileName: zip ? "chart.mcz" : "chart.mc",
    type: FileType.custom,
    allowedExtensions: zip ? ['mcz'] : ['mc'],
  );
}

// 解析 Malody Catch notes (兼容 rain 长条)
List<Note> parseMalodyNotes(List<dynamic> malodyNotes) {
  List<Note> result = [];
  for (var n in malodyNotes) {
    List beat = n['beat'] ?? [0,0,1];
    int bar = beat[0] ?? 0;
    int beatNum = beat[1] ?? 0;
    int denom = beat[2] ?? 1;
    double y = bar * 1280 + (beatNum / denom) * 1280;

    double x = (n['offset'] is num) ? (n['offset'] as num).toDouble() : 256.0;
    NoteType type = NoteType.normal;
    if (n['type'] == 3) type = NoteType.rain;

    String beatStr = "1/4";
    double? endY;
    if (type == NoteType.rain && n['endbeat'] is List) {
      List endbeat = n['endbeat'];
      int endBar = endbeat[0] ?? 0;
      int endBeatNum = endbeat[1] ?? 0;
      int endDenom = endbeat[2] ?? 1;
      endY = endBar * 1280 + (endBeatNum / endDenom) * 1280;
    }

    result.add(Note(
      x: x,
      y: y,
      endY: endY,
      type: type,
      beat: beatStr,
    ));
  }
  return result;
}

// Note -> Malody note (支持rain endbeat)
Map<String, dynamic> noteToMalodyMap(Note n) {
  int bar = (n.y ~/ 1280);
  double restY = n.y - bar * 1280;
  int beatNum = ((restY / 1280) * 4).round();

  Map<String, dynamic> map = {
    "beat": [bar, beatNum, 4],
    "offset": n.x,
    "type": n.type == NoteType.rain ? 3 : 1,
  };

  if (n.type == NoteType.rain && n.endY != null) {
    int endBar = (n.endY! ~/ 1280);
    double endRestY = n.endY! - endBar * 1280;
    int endBeatNum = ((endRestY / 1280) * 4).round();
    map["endbeat"] = [endBar, endBeatNum, 4];
  }
  return map;
}