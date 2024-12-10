import 'package:flutter/material.dart';
import 'homepage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _clearTempDirectory();
  runApp(MyApp());
}

Future<void> _clearTempDirectory() async {
  final directory = await getTemporaryDirectory();
  final List<FileSystemEntity> files = directory.listSync();
  for (var file in files) {
    if (file is File) {
      await file.delete();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Gallery App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}