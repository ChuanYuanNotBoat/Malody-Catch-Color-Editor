import 'editor_canvas.dart';

// 解析 Malody note（数组或对象格式兼容）
List<Note> parseMalodyNotes(List<dynamic> notesJson) {
  List<Note> notes = [];
  for (var n in notesJson) {
    if (n is List) {
      // 旧数组格式 [bar, beat, denom, x, type, length]
      int bar = n[0] ?? 0;
      int beatNum = n[1] ?? 0;
      int denom = n[2] ?? 1;
      double x = (n[3] as num).toDouble();
      int typeInt = n.length > 4 ? n[4] ?? 0 : 0;
      NoteType type = typeInt == 3 ? NoteType.rain : NoteType.normal;
      int? length = n.length > 5 ? n[5] : null;
      int? endBar, endBeatNum, endDenom;
      if (type == NoteType.rain && length != null) {
        // rain的长度为“拍数”
        int totalBeats = beatNum + length;
        endBar = bar + (totalBeats ~/ denom);
        endBeatNum = (totalBeats % denom).toInt();
        endDenom = denom;
      }
      notes.add(Note(
        x: x,
        bar: bar,
        beatNum: beatNum,
        denom: denom,
        type: type,
        endBar: endBar,
        endBeatNum: endBeatNum,
        endDenom: endDenom,
      ));
    } else if (n is Map) {
      // 新对象格式
      List b = n['beat'] as List? ?? [0, 0, 1];
      int bar = b[0] ?? 0;
      int beatNum = b[1] ?? 0;
      int denom = b[2] ?? 1;
      double x = (n['x'] as num?)?.toDouble() ?? 256.0;
      NoteType type = (n['type'] == 3) ? NoteType.rain : NoteType.normal;
      int? endBar, endBeatNum, endDenom;
      if (type == NoteType.rain && n['endbeat'] is List) {
        List eb = n['endbeat'];
        endBar = eb[0] ?? 0;
        endBeatNum = eb[1] ?? 0;
        endDenom = eb[2] ?? 1;
      }
      notes.add(Note(
        x: x,
        bar: bar,
        beatNum: beatNum,
        denom: denom,
        type: type,
        endBar: endBar,
        endBeatNum: endBeatNum,
        endDenom: endDenom,
      ));
    }
  }
  return notes;
}