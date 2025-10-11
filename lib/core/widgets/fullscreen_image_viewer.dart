import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  static void show(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) =>
                FullscreenImageViewer(imageUrl: imageUrl, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Zoomable image
          Center(
            child:
                heroTag != null
                    ? Hero(
                      tag: heroTag!,
                      child: PhotoView(
                        imageProvider: NetworkImage(imageUrl),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 3,
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.black,
                        ),
                      ),
                    )
                    : PhotoView(
                      imageProvider: NetworkImage(imageUrl),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 3,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                    ),
          ),

          // Close button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
