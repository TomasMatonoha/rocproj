import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  final Logger logger = Logger();
  bool _cameraError = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (cameras!.isNotEmpty) {
        controller = CameraController(
          cameras![0],
          ResolutionPreset.high,
          enableAudio: false, // No audio access
        );
        controller!.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        }).catchError((e) {
          logger.e('Error initializing camera: $e');
          setState(() {
            _cameraError = true;
          });
        });
      } else {
        setState(() {
          _cameraError = true;
        });
      }
    }).catchError((e) {
      logger.e('Error fetching cameras: $e');
      setState(() {
        _cameraError = true;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) {
      logger.e('Camera controller is not initialized');
      return;
    }
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      // Create file path
      final path = join(directory.path, '${DateTime.now().millisecondsSinceEpoch}.png');
      // Take picture
      final XFile picture = await controller!.takePicture();
      // Save the picture to path
      await picture.saveTo(path);
      // Log the picture path
      logger.i('Picture saved to $path');
    } catch (e) {
      // Log arrors
      logger.e('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Take a Picture'),
        ),
        body: Center(
          child: Text('No cameras available'),
        ),
      );
    }
    if (controller == null || !controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Take a Picture'),
      ),
      body: CameraPreview(controller!),
      floatingActionButton: FloatingActionButton(
        onPressed: takePicture,
        child: Icon(Icons.camera),
      ),
    );
  }
}