import 'dart:io';
import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentIndex + 1} / ${widget.imagePaths.length}',
            style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: onPageChanged,
        itemCount: widget.imagePaths.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.file(
              File(widget.imagePaths[index]),
              fit: BoxFit.contain, 
            ),
          );
        },
      ),
    );
  }
}
