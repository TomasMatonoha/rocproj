import 'dart:ui';
import 'package:dev1/camera/camera_screen.dart';
import 'package:dev1/gallery/export_loading.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:typed_data';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => GalleryScreenState();
}

class GalleryScreenState extends State<GalleryScreen>
    with TickerProviderStateMixin {
  List<File> images = [];
  List<Uint8List>? lowResImages = [];
  Set<int> selectedIndices = {};
  bool isSelectionMode = false;
  bool allSelected = false;

  late AnimationController animationController;
  @override
  void initState(){
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    loadImages();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Future<String?> _getUserInputForOutputPath() async {
    String? outputPath;
    var result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output directory',
    );
    result != null ? outputPath = result : null;
    return outputPath;
  }

  Future<String?> _fileTypeSelectionDialog(BuildContext context) async {
    String? fileType;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Center(child: Text('Select File Type')),
              content: Center(
                heightFactor: 1.5,
                child: DropdownMenu<String>(
                  dropdownMenuEntries: <String>[
                    'PDF',
                    'EPUB',
                  ].map<DropdownMenuEntry<String>>((String value) {
                    return DropdownMenuEntry<String>(
                      value: value,
                      label: value,
                    );
                  }).toList(),
                  onSelected: (String? newValue) {
                    setState(() {
                      fileType = newValue;
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    fileType = null;
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: fileType == null 
                    ? null 
                    : () => Navigator.pop(context),
                  child: const Text('Confirm'),
                ),
              ],
            );
          }
        );
      },
    );
    return fileType;
  }

  Future<void> loadImages() async {
    final tempdir = await getTemporaryDirectory();
    final List<FileSystemEntity> files = tempdir.listSync();
    final List<File> tempImages = files
        .where((file) => file.path.endsWith('.png'))
        .map((file) => File(file.path))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final List<Uint8List> tempLowResImages = [];
    for (final image in tempImages) {
      final bytes = await image.readAsBytes();
      final codec = await instantiateImageCodec(bytes,
          targetWidth: 100, targetHeight: 100);
      final frame = await codec.getNextFrame();
      final lowResBytes =
          (await frame.image.toByteData(format: ImageByteFormat.png))!
              .buffer
              .asUint8List();
      tempLowResImages.add(lowResBytes);
    }

    setState(() {
      images = tempImages;
      lowResImages = tempLowResImages;
    });

    List loggerList = [];
    for (int i = 0; i < images.length; i++) {
      loggerList.add('${i + 1} ${images[i]}');
    }
  }

  void deleteSelected() async {
    // Delete files
    if (selectedIndices.isEmpty) return;
    for (int i in selectedIndices) {
      await images[i].delete();
      setState(() {
        isSelectionMode = false;
      });
    }

    // Remove from list
    setState(() {
      List<File> remainingImages = [];
      for (int i = 0; i < images.length; i++) {
        if (!selectedIndices.contains(i)) {
          remainingImages.add(images[i]);
        }
      }
      images = remainingImages;
      selectedIndices.clear();
      loadImages();
    });
  }

  void showFullScreenImage(File image, BuildContext context) {
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
        title: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'lib/icons/icon.png',
            height: 35,
          ),
        ),
        backgroundColor: Colors.grey[200],
        actions: [
          AnimatedOpacity(
            opacity: (isSelectionMode && selectedIndices.isNotEmpty) ? 1 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: Icon(Icons.delete),
              onPressed: deleteSelected,
            ),
          ),
          AnimatedOpacity(
            opacity: images.isEmpty ? 0.5 : 1,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  if (images.isEmpty) return;
                  isSelectionMode = true;
                  allSelected = selectedIndices.length != images.length;
                  for (int i = 0; i < images.length; i++) {
                    allSelected
                        ? selectedIndices.add(i)
                        : selectedIndices.remove(i);
                  }
                });
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          if (details.delta.dx > 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CameraScreen()),
            ).then((_){
              loadImages();
            });
          }
        },
        child: images.isEmpty
            ? Center(
                child: Opacity(
                    opacity: 0.5,
                    child: Center(
                        child: Text(
                            'Add images or take pictures by swiping.'))),
              )
            : PopScope(
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
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (isSelectionMode) {
                          setState(() {
                            if (selectedIndices.contains(index)) {
                              selectedIndices.remove(index);
                            } else {
                              selectedIndices.add(index);
                            }
                          });
                        } else {
                          showFullScreenImage(images[index], context);
                        }
                      },
                      onLongPress: () {
                        setState(() {
                          if (!isSelectionMode) {
                            isSelectionMode = true;
                            selectedIndices.add(index);
                          } else {
                            showFullScreenImage(images[index], context);
                          }
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            margin: isSelectionMode
                                ? const EdgeInsets.all(2)
                                : EdgeInsets.zero,
                            child: Image.memory(
                              lowResImages![index],
                              filterQuality: FilterQuality.none,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (isSelectionMode)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              top: 8,
                              right: 8,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: selectedIndices.contains(index)
                                      ? Theme.of(context).primaryColor
                                      : Colors.white,
                                  border: Border.all(
                                    color: selectedIndices.contains(index)
                                        ? Colors.transparent
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: selectedIndices.contains(index)
                                        ? FittedBox(
                                            key: ValueKey('number_$index'),
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '${selectedIndices.toList().indexOf(index) + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        : Icon(
                                            Icons.check,
                                            key: ValueKey('check_$index'),
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (isSelectionMode && selectedIndices.isNotEmpty) {
            final selectedPhotos =
                selectedIndices.map((index) => images[index]).toList();
            final outputPath = await _getUserInputForOutputPath();
            if(outputPath != null && context.mounted) {
              final filetype = await _fileTypeSelectionDialog(context);
              if (filetype != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExportLoadingScreen(
                      selectedPhotos: selectedPhotos,
                      outputPath: outputPath,
                      fileType: filetype,
                    ),
                  ),
                ).then((_) {
                  setState(() {
                    isSelectionMode = false;
                    selectedIndices.clear();
                  });
                });
              }
            }
          } else {
            final pickedFiles = await ImagePicker().pickMultiImage();
            if (pickedFiles.isNotEmpty) {
              final directory = await getTemporaryDirectory();
              int i = 0;
              for (final xFile in pickedFiles) {
                final newPath = join(directory.path,
                    'imgPick-${DateTime.now().millisecondsSinceEpoch}$i.png');
                await File(xFile.path).copy(newPath);
                i++;
              }
              setState(() {
                loadImages();
              });
            }
          }
        },
        child: Icon(isSelectionMode && selectedIndices.isNotEmpty
            ? Icons.save
            : Icons.add),
      ),
    );
  }
}
