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
          enableAudio: false,
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
      final directory = await getTemporaryDirectory();
      final path = join(directory.path,
          'appCam-${DateTime.now().millisecond}-${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.png');
      final XFile picture = await controller!.takePicture();
      await picture.saveTo(path);
      logger.d('Picture saved to $path');
    } catch (e) {
      logger.e('Error taking picture: $e');
    }
  }

  @override
  Widget build(context) {
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
      body: Center(
        child: CameraPreview(controller!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await takePicture();
        },
        child: Icon(Icons.camera),
      ),
    );
  }
}
