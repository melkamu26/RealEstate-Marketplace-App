import 'package:flutter/material.dart';

class GalleryScreen extends StatefulWidget {
  final List<String> images;
  final int startIndex;

  const GalleryScreen({
    super.key,
    required this.images,
    this.startIndex = 0,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late PageController controller;
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.startIndex;
    controller = PageController(initialPage: index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text("${index + 1} / ${widget.images.length}"),
      ),
      body: PageView.builder(
        controller: controller,
        onPageChanged: (i) => setState(() => index = i),
        itemCount: widget.images.length,
        itemBuilder: (_, i) {
          return Center(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              child: Image.network(
                widget.images[i],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain, 
              ),
            ),
          );
        },
      ),
    );
  }
}