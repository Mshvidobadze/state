import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/constants/regions.dart';

class RegionPickerBottomSheet extends StatelessWidget {
  final String currentRegion;
  final ValueChanged<String> onRegionChanged;

  const RegionPickerBottomSheet({
    super.key,
    required this.currentRegion,
    required this.onRegionChanged,
  });

  static Future<String?> show(
    BuildContext context, {
    required String currentRegion,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => RegionPickerBottomSheet(
            currentRegion: currentRegion,
            onRegionChanged: (region) {
              Navigator.pop(context, region);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Region',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          // Regions list
          ...kRegions.map(
            (region) => InkWell(
              onTap: () => onRegionChanged(region),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      currentRegion == region
                          ? Icons.check_circle
                          : Icons.public,
                      color:
                          currentRegion == region
                              ? Colors.black87
                              : Colors.black54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        region,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight:
                              currentRegion == region
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
