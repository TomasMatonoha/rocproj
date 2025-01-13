

import 'package:Snap2Doc/gallery/gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _clearTempDirectory();
  runApp(MyApp());
}

Future<void> _clearTempDirectory() async {
  final directory = await getTemporaryDirectory();
  final items = directory.listSync();
  for (var item in items) {
       item.deleteSync(recursive: true);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap2Doc',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GalleryScreen(),
    );
  }
}