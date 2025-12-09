import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/features/home/domain/report_reason.dart';

class ReportConfirmationDialog extends StatelessWidget {
  const ReportConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Report Post',
        style: GoogleFonts.beVietnamPro(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You can report posts for the following reasons:',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...ReportReason.allReasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ReportReason.labels[reason]!,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Moderation actions are performed manually within 24 hours.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Do you want to report this post?',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: GoogleFonts.beVietnamPro(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Report',
            style: GoogleFonts.beVietnamPro(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
