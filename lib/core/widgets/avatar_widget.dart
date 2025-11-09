import 'dart:io';
import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final File? localImageFile; // For optimistic UI
  final double size;
  final String? displayName;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.localImageFile,
    required this.size,
    this.displayName,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ?? Colors.grey[200];

    // Priority: local file > network URL > fallback
    Widget avatarContent;
    
    if (localImageFile != null) {
      // Show local file immediately (optimistic UI)
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: defaultBackgroundColor,
        ),
        child: ClipOval(
          child: Image.file(
            localImageFile!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildLogoFallback();
            },
          ),
        ),
      );
    } else if (imageUrl != null) {
      // Show network image
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: defaultBackgroundColor,
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // This will be handled by the errorBuilder in Image.network
            },
          ),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLogoFallback();
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildLogoFallback();
            },
          ),
        ),
      );
    } else {
      // Show fallback icon
      avatarContent = Container(
        width: size,
        height: size,
        child: _buildLogoFallback(),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarContent);
    }

    return avatarContent;
  }

  Widget _buildLogoFallback() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey[200],
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: iconColor ?? Colors.grey[600],
        ),
      ),
    );
  }
}
