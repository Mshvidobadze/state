import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final Color textColor;

  const ErrorState({super.key, required this.message, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: GoogleFonts.beVietnamPro(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.beVietnamPro(
              color: textColor.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
