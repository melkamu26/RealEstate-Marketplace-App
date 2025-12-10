import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  final List<String> images;

  const GalleryScreen({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Gallery")),
        body: const Center(child: Text("No images available")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Gallery")),
      body: PageView.builder(
        itemCount: images.length,
        itemBuilder: (_, index) {
          return Image.network(
            images[index],
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}