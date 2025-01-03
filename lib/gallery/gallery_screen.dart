import 'package:dev1/gallery/type_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<File>? images = [];
  Set<int> selectedIndices = {};
  final Logger logger = Logger();
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final directory = await getTemporaryDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    final List<File> tempImages = files
        .where((file) => file.path.endsWith('.png'))
        .map((file) => File(file.path))
        .toList();
    setState(() {
      images = tempImages;
    });
  }

  void _deleteSelected() async {
    // Delete files
    for (int index in selectedIndices) {
      await images![index].delete();
      logger.d('Deleted ${images![index].path}');
    }

    // Remove from list
    setState(() {
      List<File> remainingImages = [];
      for (int i = 0; i < images!.length; i++) {
        if (!selectedIndices.contains(i)) {
          remainingImages.add(images![i]);
        }
      }
      images = remainingImages;
      selectedIndices.clear();
    });
  }

  void _showFullScreenImage(File image, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(image),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isSelectionMode = false;
                  selectedIndices.clear();
                });
              },
            ),
          if (selectedIndices.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: PopScope(
        canPop: !isSelectionMode,
        onPopInvokedWithResult: (didPop, dynamic result) {
          if (!didPop) {
            setState(() {
              isSelectionMode = false;
              selectedIndices.clear();
            });
          }
        },
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: images!.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                if (isSelectionMode) {
                  setState(() {
                    if (selectedIndices.contains(index)) {
                      selectedIndices.remove(index);
                      // Exit selection mode if no images are selected
                      if (selectedIndices.isEmpty) {
                        isSelectionMode = false;
                      }
                    } else {
                      selectedIndices.add(index);
                    }
                  });
                } else {
                  _showFullScreenImage(images![index], context);
                }
              },
              onLongPress: () {
                setState(() {
                  if (!isSelectionMode) {
                    isSelectionMode = true;
                    selectedIndices.add(index);
                  }
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    images![index],
                    fit: BoxFit.cover,
                  ),
                  if (selectedIndices.contains(index))
                    Container(
                      color: Colors.blue.withOpacity(0.2),
                      child: Text(
                        '${selectedIndices.toList().indexOf(index) + 1}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (isSelectionMode) {
            final selectedPhotos =
                selectedIndices.map((index) => images![index]).toList();

            // Navigate or process selected images
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TypeSelectScreen(selectedPhotos: selectedPhotos,), // Create this screen
              ),
            );
          } else {
            final pickedFile =
                await ImagePicker().pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              final directory = await getTemporaryDirectory();
              final newPath = join(directory.path,
                  '${DateTime.now().millisecondsSinceEpoch}.png');
              final newFile = await File(pickedFile.path).copy(newPath);
              setState(() {
                images!.add(newFile);
              });
            }
          }
        },
        child: Icon(isSelectionMode ? Icons.save : Icons.add),
      ),
    );
  }
}
