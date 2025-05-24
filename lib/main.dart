import 'package:flutter/material.dart';
import 'editor_page.dart';

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