import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'gallery_screen.dart';
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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Gallery App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraScreen()),
                );
              },
              child: Text('Camera'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GalleryScreen()),
                );
              },
              child: Text('Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}