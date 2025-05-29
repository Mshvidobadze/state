import 'package:flutter/material.dart';

class PostDetailsTheme {
  final bool isLightMode;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color subtleColor;

  PostDetailsTheme._(
    this.isLightMode,
    this.backgroundColor,
    this.cardColor,
    this.textColor,
    this.subtleColor,
  );

  factory PostDetailsTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    return PostDetailsTheme._(
      isLightMode,
      isLightMode ? const Color(0xFFF8F9FA) : const Color(0xFF1A1A1A),
      isLightMode ? Colors.white : const Color(0xFF2D2D2D),
      isLightMode ? Colors.black87 : Colors.white,
      isLightMode ? Colors.black54 : Colors.white70,
    );
  }
}
