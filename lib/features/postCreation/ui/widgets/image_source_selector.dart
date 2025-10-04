import 'package:flutter/material.dart';

/// Bottom sheet for selecting image source (camera or gallery)
///
/// Provides a modal bottom sheet with two options:
/// - Gallery: Select image from device gallery
/// - Camera: Capture image using device camera
///
/// Returns:
/// - `true` for camera selection
/// - `false` for gallery selection
/// - `null` if cancelled
class ImageSourceSelector extends StatelessWidget {
  const ImageSourceSelector({super.key});

  /// Show the image source selector bottom sheet
  ///
  /// Returns true for camera, false for gallery, null if cancelled
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool?>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const ImageSourceSelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Gallery option
              _buildOption(
                context: context,
                icon: Icons.photo_library,
                title: 'Gallery',
                onTap: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 8),

              // Camera option
              _buildOption(
                context: context,
                icon: Icons.camera_alt,
                title: 'Camera',
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an option tile for the bottom sheet
  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.grey.withValues(alpha: 0.1),
        highlightColor: Colors.grey.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: Colors.black87),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
